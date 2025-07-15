Engine_Heap : CroneEngine {
  var <synth;
  
  *new { arg context, doneCallback;
    ^super.new(context, doneCallback);
  }
  
  alloc {
    synth = {
      arg out, v1 = 0, v2 = 0, v3 = 0, v4 = 0, v5 = 0, v6 = 0, v7 = 0, v8 = 0, wet=1.0, freq=63.0, res = 0.2, gain=1.0;

      var dry, dryL, dryR, outputL, outputR;
      var inputL = SoundIn.ar(0);
      var inputR = SoundIn.ar(1);
      var safeFreq = freq.clip(50.0, 100.0)
      var safeRes = res.clip(0.1, 2.0)
	
    	var filtersL = Mix.ar([
    		BPF.ar(inputL, safeFreq*2, Lag.kr(res), Lag.kr(v1)).tanh,
    		BPF.ar(inputL, safeFreq*8, Lag.kr(res), Lag.kr(v2)).tanh,
    		BPF.ar(inputL, safeFreq*32, Lag.kr(res), Lag.kr(v3)).tanh,
    		BPF.ar(inputL, safeFreq*128, Lag.kr(res), Lag.kr(v4)).tanh,
      ]);
    	
    	var filtersR = Mix.ar([
    		BPF.ar(inputR, safeFreq, Lag.kr(res), Lag.kr(v1)).tanh,
    		BPF.ar(inputR, safeFreq*2, Lag.kr(res), Lag.kr(v2)).tanh,
    		BPF.ar(inputR, safeFreq*4, Lag.kr(res), Lag.kr(v3)).tanh,
    		BPF.ar(inputR, safeFreq*8, Lag.kr(res), Lag.kr(v4)).tanh,
    		BPF.ar(inputR, safeFreq*16, Lag.kr(res), Lag.kr(v5)).tanh,
      ]);

      dry = 1.0 - wet;
      filtersL = filtersL * wet;
      filtersR = filtersR * wet;
      dryL = inputL * dry;
      dryR = inputR * dry;
      outputL = ((filtersL + dryL) * gain).tanh;
      outputR = ((filtersR + dryR) * gain).tanh;

      Out.ar(out, [outputL, outputR]);
    }.play(args: [\out, context.out_b], target: context.xg);

    this.addCommand("freq", "f", { arg msg;
      synth.set(\freq, msg[1]);
    });

    this.addCommand("res", "f", { arg msg;
      synth.set(\res, msg[1]);
    });
    this.addCommand("wet", "f", { arg msg;
      synth.set(\wet, msg[1]);
    });

    this.addCommand("gain", "f", { arg msg;
      synth.set(\gain, msg[1]);
    });

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