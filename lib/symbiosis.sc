Engine_Symbiosis : CroneEngine {  
  var voices;

  // Audio buses
  var filterBus, fxBus, bassMonoBus, compBus;

  // Synths
  var filter, compressor, echo, bassMono;

  // Control buses
  var ampBuses, envBuses, preCompControlBuses, postCompControlBuses;
  
  *new { arg context, doneCallback;
    ^super.new(context, doneCallback);
  }
  
  alloc {
    var s = Server.default;
    var isLoaded = false;
    var bufnumL = 0;
    var bufnumR = 1;
    var file, numChannels, buffL, buffR, f, peakL, peakR, normalizeFactor, maxAmp;
    var voicesEmpty = true;

    // Routing: buffers > filter > fx > bass mono > compressor > context.xg
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
    postCompControlBuses = Array.fill(2, { Bus.control(s, 1) });

    context.server.sync;
    
    // Routing: input > filter > echo > bass mono > output 
    filter = Synth.new("BitsFilters", target:context.xg, args: [\in, filterBus, \out, fxBus]);    
    echo = Synth.after(filter, "BitsEcho", args: [\in, fxBus, \out, bassMonoBus]);
    bassMono = Synth.after(echo, "BassMono", args: [\in, bassMonoBus, \out, compBus]);
    compressor = Synth.after(bassMono, "GlueCompressor", args: [
      \in, compBus, 
      \preControlBusL, preCompControlBuses[0].index, 
      \preControlBusR, preCompControlBuses[1].index, 
      \postControlBusL, postCompControlBuses[0].index, 
      \postControlBusR, postCompControlBuses[1].index, 
      \out, 0
    ]);
    
    //context.xg is the audio context's fx group

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

    this.addCommand("set_buffer","si", { 
      arg msg;
      voices[msg[1]].set(\bufnum, msg[2]);
    });

  	this.addCommand("load_file","s", { 
      arg msg;
      buffL.free;
      buffR.free;
      isLoaded = false; 

      // Get file metadata 
      f = SoundFile.new;
      f.openRead(msg[1].asString);
      ("file" + msg[1].asString + "has" + f.numChannels + "channels").postln;
      f.close;

      // todo: limit buffer read to 2^24 samples because of Phasor resolution
    	buffL = Buffer.readChannel(context.server, msg[1].asString, channels:[0], bufnum: bufnumL, action: { 
        |b|
        if (voicesEmpty) {
          voices = Array.fill(6, { |i|
            Synth.before(filter, "tapevoice", [
            \out, filterBus,
            \bufnum, 0, 
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

        // if file is stereo, load the right channel into buffR
        if (f.numChannels > 1) {
          "Loading second channel".postln;
          buffR = Buffer.readChannel(context.server, msg[1].asString, channels:[1], bufnum: bufnumR, action: {|b| isLoaded = true;});

          // normalize both 
          peakL = buffL.maxAbsValue;
          peakR = buffR.maxAbsValue;

          // compute overall max
          maxAmp = [peakL, peakR].maxItem;
          normalizeFactor = 1.0 / maxAmp;

          // apply scaling in place
          buffL.scale(normalizeFactor); 
          buffR.scale(normalizeFactor); 
          ("left and right buffer normalized by scaling both with factor " + normalizeFactor).postln;


          // Spread 2 channels over 6 voices
          voices.do { |voice, i|
              voice.set(\bufnum, if(i < (voices.size div: 2)) { bufnumL } { bufnumR });
          };
        } { 
          // if mono, also mark loading as finished
          isLoaded = true;
          buffL.normalize();
          ("mono buffer normalized").postln;

          // Let all voices use the left buffer
          voices.do {|voice| voice.set(\bufnum, bufnumL)};
        };
      });
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


    this.addCommand("bass_mono_freq", "f", { arg msg; bassMono.set(\freq, msg[1]); });
    this.addCommand("bass_mono_dry", "f", { arg msg; bassMono.set(\dry, msg[1]); });
    this.addCommand("comp_gain", "f", { arg msg; compressor.set(\gain, msg[1]); });

    this.addPoll(\file_loaded, { isLoaded }, periodic:false);

    this.addPoll(\pre_compL, { preCompControlBuses[0].getSynchronous });
    this.addPoll(\pre_compR, { preCompControlBuses[1].getSynchronous });

    this.addPoll(\post_compL, { postCompControlBuses[0].getSynchronous });
    this.addPoll(\post_compR, { postCompControlBuses[1].getSynchronous });


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

    ampBuses.do(_.free);
    ampBuses.free;
    envBuses.do(_.free);
    envBuses.free;

    preCompControlBuses.do(_.free);
    preCompControlBuses.free;
    postCompControlBuses.do(_.free);
    postCompControlBuses.free;
  }
}