Engine_Heap : CroneEngine {
  var <synth;
  
  *new { arg context, doneCallback;
    ^super.new(context, doneCallback);
  }
  
  alloc {
    synth = {
      arg out, v1 = 0, v2 = 0, v3 = 0, v4 = 0, v5 = 0, v6 = 0, v7 = 1, v8 = 0, res = 0.2;
      
      var inputL = SoundIn.ar(0);
      var inputR = SoundIn.ar(1);
	
    	var filtersL = Mix.ar([
    		BPF.ar(inputL, 63, Lag.kr(res), Lag.kr(v1)),
    		BPF.ar(inputL, 126, Lag.kr(res), Lag.kr(v2)),
    		BPF.ar(inputL, 252, Lag.kr(res), Lag.kr(v3)),
    		BPF.ar(inputL, 504, Lag.kr(res), Lag.kr(v4)),
    		BPF.ar(inputL, 1008, Lag.kr(res), Lag.kr(v5)),
    		BPF.ar(inputL, 2016, Lag.kr(res), Lag.kr(v6)),
    		BPF.ar(inputL, 4032, Lag.kr(res), Lag.kr(v7)),
    		BPF.ar(inputL, 8064, Lag.kr(res), Lag.kr(v8))
      ]);
    	
    	var filtersR = Mix.ar([
    		BPF.ar(inputR, 63, Lag.kr(res), Lag.kr(v1)),
    		BPF.ar(inputR, 126, Lag.kr(res), Lag.kr(v2)),
    		BPF.ar(inputR, 252, Lag.kr(res), Lag.kr(v3)),
    		BPF.ar(inputR, 504, Lag.kr(res), Lag.kr(v4)),
    		BPF.ar(inputR, 1008, Lag.kr(res), Lag.kr(v5)),
    		BPF.ar(inputR, 2016, Lag.kr(res), Lag.kr(v6)),
    		BPF.ar(inputR, 4032, Lag.kr(res), Lag.kr(v7)),
    		BPF.ar(inputR, 8064, Lag.kr(res), Lag.kr(v8)),
      ]);
      
      Out.ar(out, [filtersL, filtersR]);
    }.play(args: [\out, context.out_b], target: context.xg);
  
    this.addCommand("v1", "f", { arg msg;
      synth.set(\v1, msg[1]);
    });
    
    this.addCommand("v2", "f", { arg msg;
      synth.set(\v2, msg[1]);
    });
    
    this.addCommand("v3", "f", { arg msg;
      synth.set(\v3, msg[1]);
    });
    
    this.addCommand("v4", "f", { arg msg;
      synth.set(\v4, msg[1]);
    });
    
    this.addCommand("v5", "f", { arg msg;
      synth.set(\v5, msg[1]);
    });
    
    this.addCommand("v6", "f", { arg msg;
      synth.set(\v6, msg[1]);
    });
    
    this.addCommand("v7", "f", { arg msg;
      synth.set(\v7, msg[1]);
    });
    
    this.addCommand("v8", "f", { arg msg;
      synth.set(\v8, msg[1]);
    });
  }
  
  free {
    synth.free;
  }
}