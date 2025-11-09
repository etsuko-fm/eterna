Engine_Symbiosis : CroneEngine {
  // Audio buses
  var lowpassBus, highpassBus, echoBus, bassMonoBus, compBus;

  // SynthDefs
  var voices, lpfSynth, hpfSynth, master, echoSynth, bassMono;

  // Control buses
  var ampBuses, envBuses, preCompControlBuses, postCompControlBuses, postGainBuses, masterOutControlBuses;
  var oscServer;

  // Buffers
  var bufAmp, waveformBufs, buffers;

  //
  var waveformSynths;

  *new { arg context, doneCallback;
    ^super.new(context, doneCallback);
  }

  alloc {
    var s = Server.default;

    // For communicating to Lua whether user sample has been loaded
    var isLoaded = false;

    // For file loading
    var file, numChannels, f;

    // For normalizing user sample
    var peakL, peakR, normalizeFactor, maxAmp;

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
    buffers = Array.fill(6, {|i| nil});
    waveformSynths = Array.fill(6, {|i| nil});

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
        \bufnum, nil, 
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
    OSCFunc({ |msg| 
      var channel = msg[3].asInteger;
      ("Preparing waveform for channel" + channel ++ "...").postln;
      ("bufnum for this waveform buffer:"+waveformBufs[channel].bufnum).postln;
      waveformBufs[channel].loadToFloatArray(action: {
        |array| 
        var waveform = Int8Array.fill(array.size, { |i| 
          array[i].postln;
          (array[i] * 127).abs.floor.asInteger.postln;
          (array[i] * 127).abs.floor.asInteger 
        });
        ("Length of this waveform array:"+array.size).postln;
        ("Length of resulting waveform :"+waveform.size).postln;
        ("value 0 is:" + waveform[0]).postln;
        ("value 32 is:" + waveform[32]).postln;
        oscServer.sendBundle(0, ['/waveform', waveform, channel]);
        ("Sent channel" + channel + "waveform").postln;
      });
    },'/waveformDone');

  	this.addCommand("load_file","s", {
      arg msg;
      var path, numFrames, step;
      var numDisplayPoints = 128;

      // Routine to allow server.sync
      var r = Routine {
        |in|
        var left, right, waveform_left, waveform_right;
        var numChannels;
        var ready;
        var elapsed = 0;
        var timeout = 15;
        var exit = false;
        var readNext;
        var file;

        isLoaded = false; 

        // Free voices
        voices.do { |voice, i| 
          if (voice.notNil) {
            voice.free; 
            voices[i] = nil;
          };
        };

        // Get file metadata
        file = SoundFile.new;
        path = msg[1].asString;
        file.openRead(path);
        ("file" + path + "has" + file.numChannels + "channels").postln;

        // True limit is 2^24 samples because of Phasor resolution; 
        // however encountering occassional freezes when numFrames > 2**22 
        // and reading a large file. 
        numFrames = file.numFrames.min(2**22);
        numChannels = file.numChannels.min(6); 
        file.close;
        file.free;
        
        // Array to keep track of loading status of each channel
        ready = Array.new(numChannels);

        buffers.size.do { |i| 
          if (buffers[i].notNil) {
            buffers[i].free;
            buffers[i] = nil;
          };
        };

        // Allocate buffers
        ("[1/3] Allocating buffers").postln;
        numChannels.do { |i| 
          buffers[i] = Buffer.alloc(context.server, numFrames, 1);
          ready.add(false);
          ("Buffer" + i + "allocated with" + buffers[i].numFrames + "frames").postln;
        };

        readNext = { |i|
            ("Reading channel" + i).postln;
            if (i < numChannels) {
                buffers[i].readChannel(path, 0, numFrames, channels: [i], action: {
                  ("Loaded channel " ++ i).postln;
                  if (i==0) {oscServer.sendBundle(0, ['/duration', buffers[i].duration])};
                  ready[i] = true;
                  readNext.(i + 1);
                });
            } {
                "All channels loaded.".postln;
            };
        };

        readNext.(0);

        while {ready.includes(false) && exit.not} {
          (0.5).wait;
          elapsed = elapsed + 0.5;
          if (elapsed > timeout) {
            exit = true;
          };
          "Still loading...".postln;
        };
        
        if (exit.not) {
          "[2/3] loading done, spreading over channels...".postln;
          voices.do { |voice, i|
              var channelIndex = i % numChannels; // wrap voices across channels
              voiceParams[i].put(\bufnum, buffers[channelIndex].bufnum);
              ("Voice " ++ i ++ " set to buffer " ++ channelIndex).postln;
          };
          "[3/3] spreading voices done".postln;
          isLoaded = true;  
          oscServer.sendBundle(0, ['/file_load_success', true, path]);
        } {
          "skipped steps 2 & 3, re-load should be attempted".postln;
          oscServer.sendBundle(0, ['/file_load_success', false, path]);
        };
      }.play;
    });

  	this.addCommand("normalize", "", {
      buffers.do { |b| 
        if (b.notNil) {b.normalize()};
      };
      oscServer.sendBundle(0, ['/normalized', true]);
    });

    this.addCommand("get_waveforms", "i", { |msg|
      var points = msg[1].asInteger; // number of waveform points
      var factor = buffers[0].numFrames / points;
      var next;
      // 2D array with one waveform array per index
      var waveforms = Array.fill(6, {
        Int8Array.fill(points, {|i| 0})
      });
      next = { |buf, channel, n, factor, total| 
        buf.get(n*factor, action: { |result|
          var rawval = result;
          var val = (result.abs*127).floor.asInteger;
          result.postln;
          val.postln;
          waveforms[channel][n] = val;
          if (n < (total-1)) {
            next.(buf, channel, n+1, factor, total)
          } { 
            // waveform ready
            oscServer.sendBundle(0, ['/waveform', waveforms[channel], channel]);
          };
        });
      };
      buffers.size.do {|i| 
        if (buffers[i].notNil) {
          // Generate new buffer with only as many samples as the required
          // number of points in the waveform, by downsampling the original buffer
          ("Generating waveform of" + points + "points for channel"+i).postln;
          ("Bufnum of src: " + buffers[i].bufnum).postln;
          ("Factor:" + factor).postln;
          next.(buffers[i], i, 0, factor, points);
        } {
          ("Skipped waveform for empty buffer" + i).postln;
        };
      };
    });

    this.addCommand("get_waveforms_synthdef", "i", { |msg|
      var points = msg[1].asInteger; // number of waveform points
      var factor = buffers[0].numFrames / points; // TODO: fail gracefully if no buffer loaded
      waveformBufs.do { |w| if (w.notNil) { w.free }};
      "Old waveforms freed".postln;
      waveformBufs = Array.fill(6, {|i| 
        if (buffers[i].notNil) {
          ("Allocating waveform buffer " + i).postln; 
          Buffer.alloc(context.server, points, 1)
        }
      });
      waveformSynths.do{|w| if(w.notNil) {w.free} };
      buffers.size.do {|i| 
        if (buffers[i].notNil) {
          // Generate new buffer with only as many samples as the required
          // number of points in the waveform, by downsampling the original buffer
          ("Generating waveform of" + points + "points for channel"+i).postln;
          ("Bufnum of src: " + buffers[i].bufnum).postln;
          ("Bufnum of dest: " + waveformBufs[i].bufnum).postln;
          ("Factor:" + factor).postln;
          waveformSynths[i] = Synth.new("Downsample", target:context.xg, args: [\srcBuf, buffers[i], \destBuf, waveformBufs[i], \factor, 256, \channel, i]);
        } {
          ("Skipped waveform for empty buffer" + i).postln;
        };
      };
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
          // Create voice if doesn't exist (on-load script, after sample change)
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
    buffers.free;

    

    // Audio buses
    lowpassBus.free;
    highpassBus.free;
    bassMonoBus.free;
    compBus.free;
    echoBus.free;

    // SynthDefs
    voices.do(_.free);
    waveformSynths.do(_.free);
    waveformSynths.free;
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