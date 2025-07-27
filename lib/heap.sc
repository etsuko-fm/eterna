Engine_Heap : CroneEngine {
  var swirlFilter;
  var voices;
  var filterBus;
  
  *new { arg context, doneCallback;
    ^super.new(context, doneCallback);
  }
  
  alloc {
    var s = Server.default;
    var isLoaded = false;
    var bufnumL = 0;
    var bufnumR = 1;
    var file;
    var numChannels;
    var buffL, buffR; // = Buffer.new(context.server, 0, 1, buffNum);
    var f;

    voices = Array.fill(6, { |i|
      Synth.before(swirlFilter, "tapevoice", [
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
      ])}
    );  

    filterBus = Bus.audio(context.server, 2);
    context.server.sync;
    
    swirlFilter = Synth.new("swirlFilter", target:context.xg, args: [\in, filterBus, \out, 0]);    

    this.addCommand("freq", "f", { arg msg;
      swirlFilter.set(\freq, msg[1]);
    });

    this.addCommand("res", "f", { arg msg;
      swirlFilter.set(\res, msg[1]);
    });
    this.addCommand("wet", "f", { arg msg;
      swirlFilter.set(\wet, msg[1]);
    });

    this.addCommand("gain", "f", { arg msg; 
      swirlFilter.set(\gain, msg[1]);
    });

    this.addCommand("set_buffer","si", { 
      arg msg;
      voices[msg[1]].set(\bufnum, msg[2]);
    });

  	this.addCommand("load_file","s", { 
      arg msg;
      buffL.free;
      buffR.free;
      
      voices.do(_.free);
      voices.free;
      
      isLoaded = false; 

      // Get file metadata 
      f = SoundFile.new;
      f.openRead(msg[1].asString);
      ("file" + msg[1].asString + "has" + f.numChannels + "channels").postln;
      f.close;


      // todo: limit buffer read to 2^24 samples because of Phasor resolution
    	buffL = Buffer.readChannel(context.server, msg[1].asString, channels:[0], bufnum: bufnumL, action: { 
        |b|
        // Create voices. Todo: this incorrectly resets all there other params, too
        voices = Array.fill(6, { |i|
          Synth.before(swirlFilter, "tapevoice", [
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
          ])}
        );  


        // if file is stereo, load the right channel into buffR
        if (f.numChannels > 1) {
          "Loading second channel".postln;
          buffR = Buffer.readChannel(context.server, msg[1].asString, channels:[1], bufnum: bufnumR, action: {|b| isLoaded = true;});
          // Spread 2 channels over 6 voices
          for(0,2) {arg i; voices[i].set(\bufnum, bufnumL)};
          for(3,5) {arg i; voices[i].set(\bufnum, bufnumR)};
        } { 
          // if mono, also mark loading as finished
          isLoaded = true;

          // Let all voices use the left buffer
          voices.do {|voice| voice.set(\bufnum, bufnumL)};
        };
      });
    });

    this.addCommand("rate", "if", {
      arg msg;
      voices[msg[1]].set(\rate, msg[2]);
    });

    this.addCommand("trigger", "i", {
      arg msg;
      voices[msg[1]].set(\t_trig, 1);
    });

    this.addCommand("position", "if", {
      arg msg;
      voices[msg[1]].set(\loopStart, msg[2]);
      voices[msg[1]].set(\t_trig, 1);
    });

    this.addCommand("attack", "if", {
      arg msg;
      voices[msg[1]].set(\attack, msg[2]);
    });

    this.addCommand("decay", "if", {
      arg msg;
      voices[msg[1]].set(\decay, msg[2]);
    });

    this.addCommand("filter_env", "if", {
      arg msg;
      voices[msg[1]].set(\freq, msg[2]);
    });

    this.addCommand("pan", "if", {
      arg msg;
      voices[msg[1]].set(\pan, msg[2]);
    });

    this.addCommand("loop_start", "if", {
      arg msg;
      voices[msg[1]].set(\loopStart, msg[2]);
    });

    this.addCommand("loop_end", "if", {
      arg msg;
      voices[msg[1]].set(\loopEnd, msg[2]);
    });

    this.addCommand("level", "if", {
      arg msg;
      voices[msg[1]].set(\level, msg[2]);
    });

    this.addCommand("env_level", "if", {
      arg msg;
      voices[msg[1]].set(\envLevel, msg[2]);
    });

    this.addCommand("env_curve", "if", {
      arg msg;
      voices[msg[1]].set(\curve, msg[2]);
    });

    this.addCommand("enable_env", "if", {
      arg msg;
      voices[msg[1]].set(\enable_env, msg[2]);
    });

    this.addPoll(\file_loaded, {
	      isLoaded;
	    }, periodic:false
    );
  }
  
  free {
    Buffer.freeAll;
    swirlFilter.free;
    voices.do(_.free);
    filterBus.free;
  }
}