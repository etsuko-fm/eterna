Engine_Symbiosis : CroneEngine {
  // Audio buses
  var lowpassBus, highpassBus, echoBus, bassMonoBus, compBus;

  // SynthDefs
  var voices, lpfSynth, hpfSynth, master, echoSynth, bassMono;

  // Control buses
  var ampBuses, envBuses, preCompControlBuses, postCompControlBuses, postGainBuses, masterOutControlBuses;
  var oscServer;
  var bufL, bufR, bufAmp;

  *new { arg context, doneCallback;
    ^super.new(context, doneCallback);
  }

/*
(
// parameters
var src, dest, factor = 16;

s.waitForBoot {
    // Load source buffer
    src = Buffer.read(s, Platform.resourceDir +/+ "sounds/a11wlk01.wav", action: {
        var destFrames = (src.numFrames / factor).floor;
        dest = Buffer.alloc(s, destFrames, 1);

        // Define synth to copy every `factor`th sample
        SynthDef(\downsampleBuffer, { |srcBuf, destBuf, factor = 16, doneAction = 2|
            var phasor = Phasor.ar(0, factor, 0, BufFrames.kr(srcBuf)); // read pointer
            var sig = BufRd.ar(1, srcBuf, phasor, loop: 0);
            RecordBuf.ar(sig, destBuf, loop: 0, doneAction: doneAction);
        }).add;

        s.sync;

        Synth(\downsampleBuffer, [
            \srcBuf, src,
            \destBuf, dest,
            \factor, factor
        ]);
    });
};
)
*/
  alloc {
    var s = Server.default;

    // For communicating to Lua whether user sample has been loaded
    var isLoaded = false;

    // For file loading
    var file, numChannels, f;

    // For normalizing user sample
    var peakL, peakR, normalizeFactor, maxAmp;
        
    // Bufnums for user sample
    var bufnumL = 0;
    var bufnumR = 1;

    // Buffer for collecting amplitude data for visualization
    var bufnumAmp = 2;

    var historyLength = 32;
    var amp_history_left = Int8Array.fill(historyLength, 0);
    var amp_history_right = Int8Array.fill(historyLength, 0);
    var voiceParams;

    var lpfParams = Dictionary.newFrom([\freq, 1000, \res, 0.1, \dry, 0]);
    var hpfParams = Dictionary.newFrom([\freq, 10000, \res, 0.1, \dry, 0]);

    // Map echo names to corresponding SynthDef
    var echoMap = (
      MIST: "MistEcho",
      DUST: "DustEcho",
      CLEAR: "ClearEcho"
    );
    var currentEcho;

    var echoParams = Dictionary.newFrom([\wet, 0.5, \feedback, 0.7, \time, 0.1]);
    
    // helper function for adding engine command for any float param of a voice
    var voiceCommands = [
      "attack",
      "decay",
      "pan",
      "loop_start",
      "loop_end",
      "level",
      "env_level",
      "env_curve",
      "rate",
      "lpg_freq",
    ];

    var getWaveform = { |samples, scale=1.0, numDisplayPoints = 64 |
      // scale can be used to normalize the waveform
      var waveform, chunkSize, maxPerChunk;
      // Number of samples to base waveform on (using all samples takes long)
      var resolution = 1024;
      if (samples.size > resolution) {
        var step = samples.size / resolution;
        samples = Array.fill(resolution, { |i| samples[(i * step).floor] });
      };
      // In each chunk, the maximum value will be used as waveform point
      chunkSize = (samples.size / numDisplayPoints).floor.max(1);
      maxPerChunk = samples.clump(chunkSize).collect { |chunk|
        chunk.maxItem
      };
      waveform = Int8Array.fill(numDisplayPoints, { |i|
        (maxPerChunk.at(i) * 127 * scale).abs.floor.asInteger
      });
      waveform
    };
    voices = Array.fill(6, {|i| nil});

    // For communicating to Lua (beyond the polling system)
    oscServer = NetAddr("localhost", 10111);

    // Buses for audio routing
    lowpassBus = Bus.audio(context.server, 2);
    highpassBus = Bus.audio(context.server, 2);
    echoBus = Bus.audio(context.server, 2);
    bassMonoBus = Bus.audio(context.server, 2);
    compBus = Bus.audio(context.server, 2);

    // Control bus for reporting voice amplitude
    ampBuses = Array.fill(6, { Bus.control(s, 1) });

    // Control bus for reporting voice envelope position
    envBuses = Array.fill(6, { Bus.control(s, 1) });

    // Control buses for reporting master amplitude (pre/post-comp)
    preCompControlBuses = Array.fill(2, { Bus.control(s, 1) });
    postGainBuses = Array.fill(2, { Bus.control(s, 1) });
    postCompControlBuses = Array.fill(2, { Bus.control(s, 1) });
    masterOutControlBuses = Array.fill(2, { Bus.control(s, 1) });

    voiceParams = Array.fill(6, { |i|
      Dictionary.newFrom(
      [
        \attack, 0.05,
        \decay, 4.0,
        \pan, 0.0,
        \loop_start, 0.0,
        \loop_end, 4.0,
        \level, 1.0,
        \env_level, 1.0,
        \env_curve, 0,
        \rate, 1.0,
        \lpg_freq, 20000,
        \numChannels, 1,
        \enable_lpg, 0,
        \ampBus, ampBuses[i].index,
        \envBus, envBuses[i].index,
        \out, lowpassBus,
        \bufnum, bufnumL, 
      ])
    });    

    // Ensure all buses have been created
    context.server.sync;
    "All audio and control buses created".postln;
    
    // Setup routing chain
    lpfSynth = Synth.new("SymSVF", target:context.xg, args: [\in, lowpassBus, \out, highpassBus, \filter_type, 1]);
    hpfSynth = Synth.after(lpfSynth, "SymSVF", args: [\in, highpassBus, \out, echoBus, \filter_type, 0]);
    echoSynth = Synth.after(hpfSynth, "ClearEcho", args: [\in, echoBus, \out, bassMonoBus]);
    bassMono = Synth.after(echoSynth, "BassMono", args: [\in, bassMonoBus, \out, compBus]);
    master = Synth.after(bassMono, "Master", args: [
      \in, compBus, 
      \ampbuf, bufAmp,
      \preControlBusL, preCompControlBuses[0].index, 
      \preControlBusR, preCompControlBuses[1].index, 
      \postCompControlBusL, postCompControlBuses[0].index, 
      \postCompControlBusR, postCompControlBuses[1].index, 
      \masterOutControlBusL, masterOutControlBuses[0].index,
      \masterOutControlBusR, masterOutControlBuses[1].index,
      \postGainBusL, postGainBuses[0].index, 
      \postGainBusR, postGainBuses[1].index, 
      \out, 0
    ]);

    context.server.sync;
    "Audio routing setup completed".postln;

    // Receive amplitude batches for visualization
    OSCFunc({ |msg|
        amp_history_left.pop;
        amp_history_right.pop;
        // Make value positive and between 0 and 255
        amp_history_left = amp_history_left.insert(0, (msg[3] * 127).round.asInteger);
        amp_history_right = amp_history_right.insert(0, (msg[4] * 127).round.asInteger);
    }, '/amp');

  	this.addCommand("load_file","s", {
      arg msg;
      var path, numFrames, step;
      var numDisplayPoints = 128;

      // Routine to allow server.sync
      var r = Routine {
        |inval|
        var left, right, waveform_left, waveform_right;
        bufL.free;
        bufL = nil;
        bufR.free;
        bufR = nil;
        isLoaded = false; 

        // Free voices
        voices.do { |voice, i| voice.free; };

        // Get file metadata
        f.free;
        f = SoundFile.new;
        path = msg[1].asString;
        f.openRead(path);
        ("file" + path + "has" + f.numChannels + "channels").postln;

        // Limit buffer read to 2^24 samples because of Phasor resolution
        numFrames = f.numFrames.min(48000*60);
        f.close;

        // // Wait until voices freed
        context.server.sync;

        ("Loading " ++ numFrames ++ " frames").postln;

        "Loading channel 1".postln;
        bufL = Buffer.readChannel(context.server, path, numFrames: numFrames, channels:[0], bufnum: bufnumL, action: {|b| 
          ("Channel 1 loaded to buffer " ++ bufnumL).postln;
          oscServer.sendBundle(0, ['/duration', b.duration]);
        });
        
        // Load buffers sequentially to prevent hanging
        context.server.sync;

        if (f.numChannels > 1) {
          "Loading channel 2".postln;
          bufR = Buffer.readChannel(context.server, path, numFrames: numFrames, channels:[1], bufnum: bufnumR, action: {|b| ("Channel 2 loaded to buffer " ++ bufnumR).postln;});
        };

        context.server.sync;

        if (f.numChannels > 1) {
          // Normalize based on loudest sample across channels
          "Starting normalization".postln;
          bufL.loadToFloatArray(action: { |array| 
            peakL = array.maxItem; 
            left = array;
          });
          bufR.loadToFloatArray(action: { |array| 
            peakR = array.maxItem; 
            right = array;
          });
          
          context.server.sync;

          ("Max of left/right channel: " ++ max(peakL, peakR)).postln;
          maxAmp = max(peakL, peakR);
          normalizeFactor = 1.0 / maxAmp;
          ("Normalize factor: " ++ normalizeFactor).postln;

          waveform_left = getWaveform.(left, normalizeFactor);
          waveform_right = getWaveform.(right, normalizeFactor);
          oscServer.sendBundle(0, ['/waveform', waveform_left, 0]);
          oscServer.sendBundle(0, ['/waveform', waveform_right, 1]);
          "waveforms sent".postln;

          bufL.normalize(newmax: peakL * normalizeFactor); 
          bufR.normalize(newmax: peakR * normalizeFactor); 
          context.server.sync;
          left.free;
          right.free;

          ("left and right buffer normalized by scaling both with factor " + normalizeFactor).postln;

          // Spread 2 channels over 6 voices
          voices.do { |voice, i|
              var n;
              if (voice.notNil) {
                n = if(i < voices.size.div(2)) { bufnumL } { bufnumR };
                voice.set(\bufnum, n);
                ("Voice " ++ i ++ " set to buffer " ++ n).postln;
              };
          };
          voiceParams.do{ |params, i|
              var n;
              n = if(i < voiceParams.size.div(2)) { bufnumL } { bufnumR };
              params.put(\bufnum, n);
              ("Voice " ++ i ++ " set to buffer " ++ n).postln;
          };
          
        } { 
          // if mono, also mark loading as finished
          bufL.normalize();
          ("mono buffer normalized").postln;

          // Wait until normalized
          context.server.sync;

          // Send waveform
          bufL.loadToFloatArray(action: { |array|
              var waveform = getWaveform.(array);
              oscServer.sendBundle(0, ['/waveform', waveform, 0]);
              "waveform sent".postln;
              array.free;
           });
          context.server.sync;

          // Let all voices use the left buffer
          voices.do {|voice, i| 
            if (voice.notNil) {
              voice.set(\bufnum, bufnumL);
              ("Voice " ++ i ++ " set to buffer " ++ bufnumL).postln;
            };
          };
          voiceParams.do { |params, i| 
            params.put(\bufnum, bufnumL);
            ("Voice " ++ i ++ " set to buffer " ++ bufnumL).postln;
          };
        };

        // Wait until normalization complete and voices loaded
        context.server.sync;
        isLoaded = true;
        "Normalizing completed".postln;
      }.play;
    });

    voiceCommands.do { |param| 
      this.addCommand("voice_"++param, "if", { |msg|
        var idx = msg[1].asInteger; // voice index
        var val = msg[2]; // float value
        if (voices[idx].isPlaying) {
          // if voice exists, set directly
          voices[idx].set(param.asSymbol, val);
        };
        // store value for when voice is recreated
        voiceParams[idx].put(param.asSymbol, val);
      });
    };

    this.addCommand("voice_enable_lpg", "ii", { |msg|
        var idx = msg[1].asInteger; // voice index
        var val = msg[2].asInteger; // 0 or 1
        if (voices[idx].isPlaying) {
          // if voice exists, set directly
          voices[idx].set(\enable_lpg, val);
        };
        // store value for when voice is recreated
        voiceParams[idx].put(\enable_lpg, val);
    });

    this.addCommand("voice_trigger", "i", { 
      arg msg;
      var idx = msg[1]; // voice index

      if (isLoaded) {
        if (voices[idx].isPlaying) {
          voices[idx].set(\t_trig, 1);
        } {
          // Create voice if doesn't exist
          voices[idx] = Synth.before(lpfSynth, "SampleVoice", voiceParams[idx].asPairs);
          voices[idx].onFree { 
              voices[idx] = nil;
          };
        };
      } { 
        // "new sample still loading, trigger skipped...".postln;
      };
    });

    // Commands for LPF
    lpfParams.keysDo({|key| 
      this.addCommand("lpf_" ++ key.asString, "f", { |msg|
        var val = msg[1];
        lpfSynth.set(key.asSymbol, val);
        lpfParams.put(key.asSymbol, val);
      });
    });

    // Commands for HPF
    hpfParams.keysDo({|key| 
      this.addCommand("hpf_" ++ key.asString, "f", { |msg|
        var val = msg[1];
        hpfSynth.set(key.asSymbol, val);
        hpfParams.put(key.asSymbol, val);
      });
    });

    // Commands for echo
    echoParams.keysDo({|key| 
      this.addCommand("echo_" ++ key.asString, "f", { |msg|
        var val = msg[1];
        echoSynth.set(key.asSymbol, val);
        echoParams.put(key.asSymbol, val);
      });
    });

    this.addCommand("echo_style", "s",    { arg msg; 
      var name = msg[1];
      if(currentEcho != name) {
        var synthDefName = echoMap[name];
        if (synthDefName.notNil) {
          echoSynth.free;
          currentEcho = name;
          echoSynth = Synth.after(hpfSynth, synthDefName, args: [\in, echoBus, \out, bassMonoBus, \t_trig, 1] ++ echoParams.asPairs);
          ("Switched to " ++ name ++ " echo").postln;
        };
      }
    });

    // Commands for bass mono
    this.addCommand("bass_mono_freq", "f", { arg msg; bassMono.set(\freq, msg[1]); });

    // Commands for master track
    this.addCommand("comp_drive", "f", { arg msg; master.set(\drive, msg[1].dbamp); }); // arrives in decibel, converted to linear
    this.addCommand("comp_ratio", "f", { arg msg; master.set(\ratio, msg[1]); });
    this.addCommand("comp_threshold", "f", { arg msg; master.set(\threshold, msg[1]); });
    this.addCommand("comp_out_level", "f", { arg msg; 
      // convert -60dB or lower to mute
      if (msg[1] <= -60) {master.set(\out_level, 0) } {master.set(\out_level, msg[1].dbamp)};
    }); // arrives in decibel, converted to linear

    // Commands for visualization
    this.addCommand("metering_rate", "i", {  arg msg; master.set(\metering_rate, msg[1])});

    this.addCommand("request_amp_history", "", { 
      arg msg; 
      oscServer.sendBundle(0, ['/amp_history_left', amp_history_left]);
      oscServer.sendBundle(0, ['/amp_history_right', amp_history_right]);
    });

    this.addPoll(\file_loaded, { isLoaded }, periodic:false);

    this.addPoll(\pre_comp_left, { preCompControlBuses[0].getSynchronous });
    this.addPoll(\pre_comp_right, { preCompControlBuses[1].getSynchronous });

    this.addPoll(\post_comp_left, { postCompControlBuses[0].getSynchronous });
    this.addPoll(\post_comp_right, { postCompControlBuses[1].getSynchronous });

    this.addPoll(\post_gain_left, { postGainBuses[0].getSynchronous });
    this.addPoll(\post_gain_right, { postGainBuses[1].getSynchronous });

    this.addPoll(\master_left, { masterOutControlBuses[0].getSynchronous });
    this.addPoll(\master_right, { masterOutControlBuses[1].getSynchronous });

    6.do { |idx|
        this.addPoll(("voice" ++ (idx+1) ++ "amp").asSymbol, { ampBuses[idx].getSynchronous });
        this.addPoll(("voice" ++ (idx+1) ++ "env").asSymbol, { envBuses[idx].getSynchronous });
    };
  }
  
  free {
    Buffer.freeAll;

    // Audio buses
    lowpassBus.free;
    highpassBus.free;
    bassMonoBus.free;
    compBus.free;
    echoBus.free;

    // SynthDefs
    voices.do(_.free);
    voices.free;
    lpfSynth.free;
    hpfSynth.free;
    echoSynth.free;
    bassMono.free;
    master.free;
    
    ampBuses.do(_.free);
    ampBuses.free;
    envBuses.do(_.free);
    envBuses.free;

    // Control buses
    preCompControlBuses.do(_.free);
    preCompControlBuses.free;
    postCompControlBuses.do(_.free);
    postCompControlBuses.free;
    postGainBuses.do(_.free);
    postGainBuses.free;
    masterOutControlBuses.do(_.free);
    masterOutControlBuses.free;
    
    oscServer.free;
  }
}