Engine_Symbiosis : CroneEngine {  
  var voices;

  // Audio buses
  var filterBus, fxBus, bassMonoBus, compBus, maxBus;

  // Synths
  var filter, compressor, echo, bassMono, maximizer;

  // Control buses
  var ampBuses, envBuses, preCompControlBuses, postCompControlBuses, postGainBuses;
  
  var exampleArray;

  var oscServer;

  var bufValsLeft, bufValsRight;

  var n, r;

  var bufL, bufR, bufAmp;

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
    
    // For checking if voices have been allocated yet; TODO: might just check for nil
    var voicesEmpty = true;
    
    // Bufnums for user sample
    var bufnumL = 0;
    var bufnumR = 1;

    // Buffer for collecting amplitude data for visualization
    var bufnumAmp = 2;

    var historyLength = 32;
    var ampHistoryL = Int8Array.fill(historyLength, 0);
    var ampHistoryR = Int8Array.fill(historyLength, 0);

    // For communicating anything to Lua beyond than polling system
    oscServer = NetAddr("localhost", 10111);
    exampleArray = Int8Array.fill(8, { 12 });

    // Buses for audio routing
    filterBus = Bus.audio(context.server, 2);
    fxBus = Bus.audio(context.server, 2);
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

    // Ensure all buses have been created
    context.server.sync;
    "All audio and control buses created".postln;
    
    // Setup routing chain
    filter = Synth.new("BitsFilters", target:context.xg, args: [\in, filterBus, \out, fxBus]);    
    echo = Synth.after(filter, "BitsEcho", args: [\in, fxBus, \out, bassMonoBus]);
    bassMono = Synth.after(echo, "BassMono", args: [\in, bassMonoBus, \out, compBus]);
    compressor = Synth.after(bassMono, "GlueCompressor", args: [
      \in, compBus, 
      \ampbuf, bufAmp,
      \preControlBusL, preCompControlBuses[0].index, 
      \preControlBusR, preCompControlBuses[1].index, 
      \postCompControlBusL, postCompControlBuses[0].index, 
      \postCompControlBusR, postCompControlBuses[1].index, 
      \postGainBusL, postGainBuses[0].index, 
      \postGainBusR, postGainBuses[1].index, 
      \out, 0
    ]);

    context.server.sync;
    "Audio routing setup completed".postln;

    // Receive amplitude batches for visualization
    OSCFunc({ |msg|
        ampHistoryL.pop;
        ampHistoryR.pop;
        // Make value positive and between 0 and 255
        ampHistoryL = ampHistoryL.insert(0, (msg[3] * 127).round.asInteger);
        ampHistoryR = ampHistoryR.insert(0, (msg[4] * 127).round.asInteger);
    }, '/amp');

    // Commands for sample voices
    this.addCommand("set_buffer","si", { 
      arg msg;
      voices[msg[1]].set(\bufnum, msg[2]);
    });

  	this.addCommand("load_file","s", {
      arg msg;

      // Routine to allow server.sync
      r = Routine {
        |inval|
        bufL.free;
        bufR.free;
        isLoaded = false; 

        // Get file metadata 
        f = SoundFile.new;
        f.openRead(msg[1].asString);
        ("file" + msg[1].asString + "has" + f.numChannels + "channels").postln;
        f.close;

        // todo: limit buffer read to 2^24 samples because of Phasor resolution
        "Loading channel 1".postln;
        bufL = Buffer.readChannel(context.server, msg[1].asString, channels:[0], bufnum: bufnumL, action: {|b| ("Channel 1 loaded to buffer " ++ bufnumL).postln;});
        if (f.numChannels > 1) {
          // It may be quadraphonic or surround, but that's not supported right now
          "Loading channel 2".postln;
          bufR = Buffer.readChannel(context.server, msg[1].asString, channels:[1], bufnum: bufnumR, action: {|b| ("Channel 2 loaded to buffer " ++ bufnumR).postln;});
        };
        context.server.sync();
        isLoaded = true;

        // Instantiate voices
        // TODO: voices.do(_.free) first, to prevent warning that buf data not found?
        if (voicesEmpty) {
          voices = Array.fill(6, { |i|
            Synth.before(filter, "SampleVoice", [
            \out, filterBus,
            \bufnum, bufnumL, 
            \rate, 1.0,
            \loopStart, 0.0,
            \loopEnd, 4.0,
            \numChannels, 1,
            \decay, 4.0,
            \t_trig, 0,
            \enable_env, 0,
            \envLevel, 1.0,
            \ampBus, ampBuses[i].index,
            \envBus, envBuses[i].index,
            ])}
          );  
        };
        voicesEmpty = false;

        if (f.numChannels > 1) {
          // Normalize based on loudest sample across channels
          bufValsLeft = bufL.loadToFloatArray(action: { |array| peakL = array.maxItem; });
          bufValsRight = bufR.loadToFloatArray(action: { |array| peakR = array.maxItem; });
          context.server.sync();
          ("Max of left/right channel: " ++ max(peakL, peakR)).postln;
          maxAmp = max(peakL, peakR);
          normalizeFactor = 1.0 / maxAmp;
          ("Normalize factor: " ++ normalizeFactor).postln;
          bufL.normalize(peakL * normalizeFactor); 
          bufR.normalize(peakR * normalizeFactor); 
          ("left and right buffer normalized by scaling both with factor " + normalizeFactor).postln;

          // Spread 2 channels over 6 voices
          voices.do { |voice, i|
              "Spreading stereo buffer over 6 voices".postln;
              n = if(i < voices.size.div(2)) { bufnumL } { bufnumR };
              voice.set(\bufnum, n);
              ("Voice " ++ i ++ "set to buffer " ++ n).postln;
          };
        } { 
          // if mono, also mark loading as finished
          isLoaded = true;
          bufL.normalize();
          ("mono buffer normalized").postln;
          // Let all voices use the left buffer
          voices.do {|voice| voice.set(\bufnum, bufnumL)};
        };
      }.next(); // next() executes routine
    });

    this.addCommand("rate", "if", {
      arg msg;
      if (voicesEmpty.not) {
        voices[msg[1]].set(\rate, msg[2]);
      };
    });

    this.addCommand("trigger", "i", {
      arg msg;
      if (voicesEmpty.not) {
        voices[msg[1]].set(\t_trig, 1);
      };
    });

    this.addCommand("position", "if", {
      arg msg;
      if (voicesEmpty.not) {
        voices[msg[1]].set(\loopStart, msg[2]);
        voices[msg[1]].set(\t_trig, 1);
      };
    });

    this.addCommand("attack", "if", {
      arg msg;
      if (voicesEmpty.not) {
        voices[msg[1]].set(\attack, msg[2]);
      };
    });

    this.addCommand("decay", "if", {
      arg msg;
      if (voicesEmpty.not) {
        voices[msg[1]].set(\decay, msg[2]);
      };
    });

    this.addCommand("enable_lpg", "ii", {
      arg msg;
      if (voicesEmpty.not) {
        voices[msg[1]].set(\enableLpg, msg[2]);
      };
    });

    this.addCommand("lpg_freq", "if", {
      arg msg;
      if (voicesEmpty.not) {
        voices[msg[1]].set(\freq, msg[2]);
      };
    });

    this.addCommand("pan", "if", {
      arg msg;
      if (voicesEmpty.not) {
        voices[msg[1]].set(\pan, msg[2]);
      };
    });

    this.addCommand("loop_start", "if", {
      arg msg;
      if (voicesEmpty.not) {
        voices[msg[1]].set(\loopStart, msg[2]);
      };
    });

    this.addCommand("loop_end", "if", {
      arg msg;
      if (voicesEmpty.not) {
        voices[msg[1]].set(\loopEnd, msg[2]);
      };
    });

    this.addCommand("level", "if", {
      arg msg;
      if (voicesEmpty.not) {
        voices[msg[1]].set(\level, msg[2]);
      };
    });

    this.addCommand("env_level", "if", {
      arg msg;
      if (voicesEmpty.not) {
        voices[msg[1]].set(\envLevel, msg[2]);
      };
    });

    this.addCommand("env_curve", "if", {
      arg msg;
      if (voicesEmpty.not) {
        voices[msg[1]].set(\curve, msg[2]);
      };
    });

    this.addCommand("enable_env", "if", {
      arg msg;
      if (voicesEmpty.not) {
        voices[msg[1]].set(\enableEnv, msg[2]);
      };
    });

    // Commands for filter
    this.addCommand("set_filter_type", "s", { arg msg;
      switch(msg[1].asString)
      { "HP"} {
        filter.set(\filterType, 0);
      }
      { "LP" } {
        filter.set(\filterType, 1);
      }
      { "BP" } {
        filter.set(\filterType, 2);
      }
      { "SWIRL" } {
        filter.set(\filterType, 3);
      }
      { "NONE" } {
        filter.set(\filterType, 4);
      };
    });

    this.addCommand("freq", "f", { arg msg; filter.set(\freq, msg[1]); });
    this.addCommand("res", "f", { arg msg; filter.set(\res, msg[1]); });
    this.addCommand("filter_dry", "f", { arg msg; filter.set(\dry, msg[1]); });
    this.addCommand("filter_gain", "f", { arg msg; filter.set(\gain, msg[1]); });


    // Commands for echo
    this.addCommand("echo_feedback", "f", { arg msg; echo.set(\feedback, msg[1]); });
    this.addCommand("echo_time", "f",     { 
      arg msg; 
      echo.set(\delayTime, msg[1]); 
      echo.set(\t_trig, 1); 
      });
    this.addCommand("echo_wet", "f",      { arg msg; echo.set(\wetAmount, msg[1]); });
    this.addCommand("echo_style", "s",    { arg msg; 
      switch(msg[1].asString)
      { "NEUTRAL"} {
        echo.set(\style, 0);
      }
      { "DARK" } {
        echo.set(\style, 1);
      }
      { "BRIGHT" } {
        echo.set(\style, 2);
      };
     });


    // Commands for bass mono
    this.addCommand("bass_mono_freq", "f", { arg msg; bassMono.set(\freq, msg[1]); });
    this.addCommand("bass_mono_dry", "f", { arg msg; bassMono.set(\dry, msg[1]); });
    this.addCommand("bass_mono_enabled", "i", {arg msg; bassMono.set(\enabled, msg[1]); });

    // Commands for compressor
    this.addCommand("comp_gain", "f", { arg msg; compressor.set(\gain, msg[1]); });
    this.addCommand("comp_ratio", "f", { arg msg; compressor.set(\ratio, msg[1]); });
    this.addCommand("comp_threshold", "f", { arg msg; compressor.set(\threshold, msg[1]); });
    this.addCommand("comp_out_level", "f", { arg msg; compressor.set(\outLevel, msg[1]); });

    // Commands for visualization
    this.addCommand("request_waveform", "i", { 
      arg msg; 
      oscServer.sendBundle(0, ['/waveform', exampleArray]);
    });

    this.addCommand("set_metering_rate", "i", {  arg msg; compressor.set(\meteringRate, msg[1])});

    this.addCommand("request_amp_history", "", { 
      arg msg; 
      oscServer.sendBundle(0, ['/ampHistoryL', ampHistoryL]);
      oscServer.sendBundle(0, ['/ampHistoryR', ampHistoryR]);
    });

    this.addPoll(\file_loaded, { isLoaded }, periodic:false);

    this.addPoll(\pre_compL, { preCompControlBuses[0].getSynchronous });
    this.addPoll(\pre_compR, { preCompControlBuses[1].getSynchronous });

    this.addPoll(\post_compL, { postCompControlBuses[0].getSynchronous });
    this.addPoll(\post_compR, { postCompControlBuses[1].getSynchronous });

    this.addPoll(\post_gainL, { postGainBuses[0].getSynchronous });
    this.addPoll(\post_gainR, { postGainBuses[1].getSynchronous });

    this.addPoll(\array_example, { 3.1415 });

    6.do { |idx|
        this.addPoll(("voice" ++ (idx+1) ++ "amp").asSymbol, { ampBuses[idx].getSynchronous });
        this.addPoll(("voice" ++ (idx+1) ++ "env").asSymbol, { envBuses[idx].getSynchronous });
    };

  }
  
  free {
    Buffer.freeAll;
    filter.free;
    voices.do(_.free);
    filterBus.free;
    
    bassMonoBus.free;
    bassMono.free;

    fxBus.free;
    echo.free;

    compBus.free;
    compressor.free;
    
    maxBus.free;
    maximizer.free;

    ampBuses.do(_.free);
    ampBuses.free;
    envBuses.do(_.free);
    envBuses.free;

    preCompControlBuses.do(_.free);
    preCompControlBuses.free;
    postCompControlBuses.do(_.free);
    postCompControlBuses.free;
    postGainBuses.do(_.free);
    postGainBuses.free;
    
    exampleArray.free;
    oscServer.free;
  }
}