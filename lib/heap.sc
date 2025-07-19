Engine_Heap : CroneEngine {
  var swirlFilter;
  var samplePlayer;
  var filterBus;
  
  *new { arg context, doneCallback;
    ^super.new(context, doneCallback);
  }
  
  alloc {
    var s = Server.default;
    var isLoaded = false;
    // server, frames, channels, bufnum
    var buffNum = 0;
    var channels = 2;
    var buff = Buffer.new(context.server, 0, channels, buffNum);
 
    // Done with definitions, sync
    context.server.sync;
    filterBus = Bus.audio(context.server, 2);
    // ("filterBus index" + filterBus.index).postln;

    swirlFilter = Synth.new("swirlFilter", target:context.xg, args: [\in, filterBus, \out, 0]);
    samplePlayer = Synth.before(swirlFilter, "tapevoice", [
      \out, filterBus,
      \rate, 0.5,
      \loopStart, 2,
      \loopEnd, 12,
      \numChannels, 1,
      \decay, 4.0,
      \t_trig, 0
    ]);

    context.server.sync;

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

    this.addCommand("rate", "f", { arg msg;
      samplePlayer.set(\t_trig, 1);
      samplePlayer.set(\rate, msg[1]);
    });

  	this.addCommand("load_file","si", { 
      arg msg;
      buff.free;
      isLoaded = false;
    	buff = Buffer.read(context.server,msg[1], numFrames:msg[2], action: { 
        |buffer| 
        ("Loaded" + buffer.numFrames + "frames of" + buffer.path).postln;
	      isLoaded = true;
        samplePlayer.set(\bufnum, buffer.bufnum);
      });
    });

    this.addCommand("rate", "if", {
      arg msg;
      ("Setting voice" + msg[1] + "to rate" + msg[2]).postln;
      samplePlayer.set(\rate, msg[2]);
    });

    this.addCommand("trigger", "i", {
      arg msg;
      ("Triggered voice" + msg[1]).postln;
      samplePlayer.set(\t_trig, 1);
    });

    this.addCommand("stop", "i", {
      arg msg;
      ("Stopping voice" + msg[1]).postln;
      samplePlayer.set(\rate, 0);
    });
    this.addCommand("position", "if", {arg msg;
      ("Setting playback position for voice" + msg[1] + "to" + msg[2]).postln;
    });

    this.addPoll(\file_loaded, {
	      isLoaded;
	    }, periodic:false
    );
  }
  
  free {
    Buffer.freeAll;
    swirlFilter.free;
    samplePlayer.free;
    filterBus.free;
  }
}