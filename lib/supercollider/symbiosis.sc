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

    var historyLength = 16;
    var amp_history = Array.fill(2, {|n| Int8Array.fill(historyLength, 0)});
    var voiceParams;

    var lpfParams = Dictionary.newFrom([\freq, 1000, \res, 0.1, \dry, 0]);
    var hpfParams = Dictionary.newFrom([\freq, 10000, \res, 0.1, \dry, 0]);

    // Map echo names to corresponding SynthDef
    var echoMap = (
      MIST: "MistEcho",
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
      "bufnum",
    ];

    voices = Array.fill(6, {|i| nil});
    buffers = Array.fill(6, {|i| nil});

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
        2.do { |n| 
          var val = msg[3+n]; // arg 3 & 4 are channel left/right samples
          amp_history[n].pop; // remove oldest value
          // Make value positive and between 0 and 127
          amp_history[n] = amp_history[n].insert(0, (val * 127).round.asInteger);
        };
    }, '/amp');
    
  	this.addCommand("load_channel_to_buffer","sii", {
      arg msg;
      var numFrames;
      var path = msg[1].asString;
      var channel = msg[2].asInteger;
      var index = msg[3].asInteger;

      var r = Routine {
        |in|
        var ready;
        var elapsed = 0;
        var timeout = 10;
        var exit = false;
        var file;
        var sampleRate;

        (path + ": channel" + channel + "-> buffer" + index).postln;

        isLoaded = false; 

        // Free buffer
        if (buffers[index].notNil) {
            buffers[index].free;
            buffers[index] = nil;
        };
        
        // Get file metadata
        file = SoundFile.new;
        file.openRead(path);
        numFrames = file.numFrames.min(2**24);
        file.close;
        file.free;
        ready = false;
        

        // Allocate buffer
        buffers[index] = Buffer.alloc(context.server, numFrames, numChannels: 1);
        ("Buffer" + index + "allocated with" + buffers[index].numFrames + "frames").postln;
        context.server.sync;

        buffers[index].readChannel(path, 0, numFrames, channels: [channel], action: {
          ("Loaded channel" + channel + "to buffer" + index).postln;
          oscServer.sendBundle(0, ['/duration', buffers[index].duration]);
          ready = true;
        });

        while {ready.not && exit.not} {
          (0.5).wait;
          elapsed = elapsed + 0.5;
          if (elapsed > timeout) {
            exit = true;
          } {
            ("Still loading buffer" + index + "..." + elapsed ++ "/" ++ timeout).postln;
          };
        };

        if (ready) {
          isLoaded = true;  
          oscServer.sendBundle(0, ['/file_load_result', true, path, channel, index]);
        } {
          ("Operation timed out for buffer" + index ++ ", channel" + channel).postln;
          oscServer.sendBundle(0, ['/file_load_result', false, path, channel, index]);
        };
      }.play;
    });

    this.addCommand("clear_buffer", "i", { |msg| 
      var index = msg[1].asInteger;
      if (buffers[index].notNil) {
        buffers[index].free;
        buffers[index] = nil;
        ("buffer" + index + "cleared").postln;
      } {
        ("buffer" + index + "requested to be cleared, but was already empty").postln;
      };
    });

  	this.addCommand("normalize", "i", { |msg|
      var index = msg[1].asInteger;
      var r = Routine {
        if (buffers[index].notNil) {
          buffers[index].normalize();
          context.server.sync;
          oscServer.sendBundle(0, ['/normalized', index]);
        };
      }.play;
    });

    this.addCommand("get_waveform", "ii", { |msg|
      var idx = msg[1].asInteger;
      var points = msg[2].asInteger; // number of waveform points
      var factor = buffers[idx].numFrames / points;
      var next;
      // 2D array with one waveform array per index
      var int8waveform = Int8Array.fill(points, {|i| 0});
      var waveform = Array.fill(points, {|i| 0.0});
      
      // Function to retrieve a single buffer sample and store it in waveform array
      var next_sample = { |buf, buf_idx, n, factor, total| 
        buf.getn(n*factor, 96, action: { |result|
          var rawval = result.maxItem; // take highest out of 96 samples at requested point (2ms)

          // Positive or negative is irrelevant for waveform
          waveform[n] = (rawval.abs*127).floor.asInteger;
          if (n < (total-1)) {
            next_sample.(buf, buf_idx, n+1, factor, total)
          } { 
            // waveform ready; scale so max is 127 
            //  (graphical choice, would not reflect a very silent waveform)
            //  TODO: leave this to lua
            waveform = waveform * (127 / waveform.maxItem);
            // remap to int8
            waveform.size.do { |i| int8waveform[i] = waveform[i].floor.asInteger};
            // send to client
            oscServer.sendBundle(0, ['/waveform', int8waveform, buf_idx]);
            "waveform sent".postln;
          };
        });
      };

      if (buffers[idx].notNil) {
        // Generate new buffer with only as many samples as the required
        // number of points in the waveform, by downsampling the original buffer
        ("Generating waveform of" + points + "points for buffer"+idx).postln;
        ("Factor:" + factor).postln;
        next_sample.(buffers[idx], idx, 0, factor, points);
      } {
        ("Skipped waveform for empty buffer" + idx).postln;
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
    this.addCommand("metering_rate", "i", {  arg msg; 
      master.set(\metering_rate, msg[1]);
      ("metering rate set to "++msg[1]).postln;
    });

    this.addCommand("request_amp_history", "", { 
      arg msg; 
      // TODO: could be a poll
      oscServer.sendBundle(0, ['/amp_history', amp_history[0], amp_history[1]]);
    });

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