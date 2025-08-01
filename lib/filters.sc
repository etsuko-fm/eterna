BitsFilters {
	*initClass {
		StartUp.add {
			var s = Server.default;
			s.waitForBoot {
				SynthDef("BitsFilters", {
					arg in, out, freq=63.0, res = 0.2, gain=1.0, filterType=0;
					var input = In.ar(in, 2);
					var safeFreq = freq.clip(5.0, 24000.0);
					var safeRes = res.clip(0.0, 0.999);
					var filtered_signal = Select.ar(filterType, [
						// 0 - highpass
						[
							BMoog.ar(input[0], Lag.kr(safeFreq), Lag.kr(safeRes), saturation:0, gain: 0.4, mode: 1).tanh,
							BMoog.ar(input[1], Lag.kr(safeFreq), Lag.kr(safeRes), saturation:0, gain: 0.4, mode: 1).tanh,
						],
						// 1 - lowpass
						[
							MoogVCF.ar(input[0], Lag.kr(safeFreq), Lag.kr(safeRes)).tanh,
							MoogVCF.ar(input[1], Lag.kr(safeFreq), Lag.kr(safeRes)).tanh,
						],	
						// 2 - swirl
						[
							Mix.ar([
									SVF.ar(input[0], safeFreq, Lag.kr(safeRes), 0.0, 1.0, 0.0).tanh,
									SVF.ar(input[0], safeFreq*4, Lag.kr(safeRes), 0.0, 1.0, 0.0).tanh,
									SVF.ar(input[0], safeFreq*16, Lag.kr(safeRes), 0.0, 1.0, 0.0).tanh,
									SVF.ar(input[0], safeFreq*64, Lag.kr(safeRes), 0.0, 1.0, 0.0).tanh,
								]),
							Mix.ar([
								SVF.ar(input[1], safeFreq, Lag.kr(safeRes), 0.0, 1.0, 0.0).tanh,
								SVF.ar(input[1], safeFreq*4, Lag.kr(safeRes), 0.0, 1.0, 0.0).tanh,
								SVF.ar(input[1], safeFreq*16, Lag.kr(safeRes), 0.0, 1.0, 0.0).tanh,
								SVF.ar(input[1], safeFreq*64, Lag.kr(safeRes), 0.0, 1.0, 0.0).tanh,
							])
						],
						// 3 - passthrough
						input
					]);	
					var output = (filtered_signal * gain).tanh;
					Out.ar(out, output);
				}).add;
			} // waitForBoot
		} //add
	} // initClass
}
