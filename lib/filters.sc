Swirl {
	*initClass {
		StartUp.add {
			var s = Server.default;
			s.waitForBoot {
				SynthDef("swirlFilter", {
					arg in, out, wet=1.0, freq=63.0, res = 0.2, gain=1.0;
					var dry, dryL, dryR, outputL, outputR, dry_signal, signal;
					var input = In.ar(in, 2);
					var safeFreq = freq.clip(5.0, 24000.0);
					var safeRes = res.clip(0.1, 2.0);
					var filtersL = Mix.ar([
						SVF.ar(input[0], safeFreq*2, Lag.kr(res), 0.0, 1.0, 0.0).tanh,
						SVF.ar(input[0], safeFreq*8, Lag.kr(res), 0.0, 1.0, 0.0).tanh,
						SVF.ar(input[0], safeFreq*32, Lag.kr(res), 0.0, 1.0, 0.0).tanh,
						SVF.ar(input[0], safeFreq*128, Lag.kr(res), 0.0, 1.0, 0.0).tanh,
					]);
					
					var filtersR = Mix.ar([
						SVF.ar(input[1], safeFreq*2, Lag.kr(res), 0.0, 1.0, 0.0).tanh,
						SVF.ar(input[1], safeFreq*8, Lag.kr(res), 0.0, 1.0, 0.0).tanh,
						SVF.ar(input[1], safeFreq*32, Lag.kr(res), 0.0, 1.0, 0.0).tanh,
						SVF.ar(input[1], safeFreq*128, Lag.kr(res), 0.0, 1.0, 0.0).tanh,
					]);

					dry = 1.0 - wet;
					filtersL = filtersL * wet;
					filtersR = filtersR * wet;
					dryL = input[0] * dry;
					dryR = input[1] * dry;
					outputL = ((filtersL + dryL) * gain).tanh;
					outputR = ((filtersR + dryR) * gain).tanh;
					Out.ar(out, [outputL, outputR]);
				}).add;
				SynthDef("MoogVCF", {
					arg in, out, freq=20000.0, res = 0.2, gain=1.0;
					var dry, dryL, dryR, outputL, outputR, dry_signal, signal;
					var input = In.ar(in, 2);
					var safeFreq = freq.clip(5.0, 24000.0);
					var safeRes = res.clip(0.1, 2.0);
					var filtersL = Mix.ar([
						MoogVCF.ar(input[0], Lag.kr(safeFreq*2), Lag.kr(res)).tanh,
					]);
					
					var filtersR = Mix.ar([
						MoogVCF.ar(input[1], Lag.kr(safeFreq*2), Lag.kr(res)).tanh,
					]);

					outputL = (filtersL * gain).tanh;
					outputR = (filtersR * gain).tanh;
					Out.ar(out, [outputL, outputR]);
				}).add;
				SynthDef("HighPass", {
					arg in, out, freq=20000.0, res = 0.2, gain=1.0;
					var dry, dryL, dryR, outputL, outputR, dry_signal, signal;
					var input = In.ar(in, 2);
					var safeFreq = freq.clip(5.0, 24000.0);
					var safeRes = res.clip(0.1, 2.0);
					var filtersL = Mix.ar([
						BMoog.ar(input[0], Lag.kr(safeFreq*2), Lag.kr(res), mode:1).tanh,
					]);
					
					var filtersR = Mix.ar([
						BMoog.ar(input[1], Lag.kr(safeFreq*2), Lag.kr(res), mode:1).tanh,
					]);

					outputL = (filtersL * gain).tanh;
					outputR = (filtersR * gain).tanh;	
					Out.ar(out, [outputL, outputR]);
				}).add;
			} // waitForBoot
		} //add
	} // initClass
}
