Engine_Heap : CroneEngine {
  var <synth;
  
  *new { arg context, doneCallback;
    ^super.new(context, doneCallback);
  }
  
  alloc {
    synth = {
      arg out, wet=1.0, freq=63.0, res = 0.2, gain=1.0;

      var dry, dryL, dryR, outputL, outputR;
      var inputL = SoundIn.ar(0);
      var inputR = SoundIn.ar(1);
      var safeFreq = freq.clip(5.0, 24000.0);
      var safeRes = res.clip(0.1, 2.0);
	
    	var filtersL = Mix.ar([
    		SVF.ar(inputL, safeFreq*2, Lag.kr(res), 0.0, 1.0, 0.0).tanh,
    		SVF.ar(inputL, safeFreq*8, Lag.kr(res), 0.0, 1.0, 0.0).tanh,
    		SVF.ar(inputL, safeFreq*32, Lag.kr(res), 0.0, 1.0, 0.0).tanh,
    		SVF.ar(inputL, safeFreq*128, Lag.kr(res), 0.0, 1.0, 0.0).tanh,
      ]);
    	
    	var filtersR = Mix.ar([
    		SVF.ar(inputR, safeFreq*2, Lag.kr(res), 0.0, 1.0, 0.0).tanh,
    		SVF.ar(inputR, safeFreq*8, Lag.kr(res), 0.0, 1.0, 0.0).tanh,
    		SVF.ar(inputR, safeFreq*32, Lag.kr(res), 0.0, 1.0, 0.0).tanh,
    		SVF.ar(inputR, safeFreq*128, Lag.kr(res), 0.0, 1.0, 0.0).tanh,
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
  }
  
  free {
    synth.free;
  }
}