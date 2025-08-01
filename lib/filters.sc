Swirl {
	*initClass {
		StartUp.add {
			var s = Server.default;
			s.waitForBoot {
				SynthDef("SwirlFilter", {
					arg in, out, freq=63.0, res = 0.2, gain=1.0;
					var outputL, outputR;
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

					outputL = (filtersL * gain).tanh;
					outputR = (filtersR * gain).tanh;
					Out.ar(out, [outputL, outputR]);
				}).add;
				SynthDef("LowPass", {
					arg in, out, freq=20000.0, res = 0.2, gain=1.0;
					var input = In.ar(in, 2);
					var safeFreq = freq.clip(5.0, 24000.0);
					var safeRes = res.clip(0.1, 1.0);
					var filter = MoogVCF.ar(input, Lag.kr(safeFreq*2), Lag.kr(res)).tanh;
					var output = (filter * gain).tanh;
					Out.ar(out, output);
				}).add;
				SynthDef("HighPass", {
					arg in, out, freq=20000.0, res = 0.2, gain=1.0;
					var input = In.ar(in, 2);
					var safeFreq = freq.clip(5.0, 24000.0);
					var safeRes = res.clip(0.1, 1.0);
					var filter = BMoog.ar(input, Lag.kr(safeFreq), Lag.kr(res), mode: 1).tanh;
					var output = (filter * gain).tanh;	
					Out.ar(out, output);
				}).add;
				SynthDef("PassThrough", {
					arg in, out, freq=0.0, res = 0.0, gain=1.0;
					var outputL, outputR;
					var input = In.ar(in, 2);
					var output = (input * gain).tanh;
					Out.ar(out, output);
				}).add;
			} // waitForBoot
		} //add
	} // initClass
}
