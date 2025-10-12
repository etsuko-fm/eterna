BitsFilters {
	*initClass {
		StartUp.add {
			var s = Server.default;
			s.waitForBoot {
				SynthDef("BitsFilters", {
					arg in, out, freq=63.0, res = 0.2, gain=1.0, dry=0.0, filter_type=0;
					var input = In.ar(in, 2);
					var safeFreq = Lag.kr(freq.clip(5.0, 24000.0));
					var safeRes = Lag.kr(res.clip(0.0, 0.999));
					var filteredSignal = Select.ar(filter_type, [
						// 0 - highpass
						[
							SVF.ar(input[0], safeFreq, safeRes, 0.0, 0.0, 1.0).tanh,
							SVF.ar(input[1], safeFreq, safeRes, 0.0, 0.0, 1.0).tanh,
						],
						// 1 - lowpass
						[
							SVF.ar(input[0], safeFreq, safeRes, 1.0, 0.0, 0.0).tanh,
							SVF.ar(input[1], safeFreq, safeRes, 1.0, 0.0, 0.0).tanh,
						],	
						// 2 - bandpass
						[
							SVF.ar(input[0], safeFreq, safeRes, 0.0, 1.0, 0.0).tanh,
							SVF.ar(input[1], safeFreq, safeRes, 0.0, 1.0, 0.0).tanh,
						],	
						// 3 - swirl
						[
							Mix.ar([
									SVF.ar(input[0], safeFreq, safeRes, 0.0, 1.0, 0.0).tanh,
									SVF.ar(input[0], safeFreq*4, safeRes, 0.0, 1.0, 0.0).tanh,
									SVF.ar(input[0], safeFreq*16, safeRes, 0.0, 1.0, 0.0).tanh,
									SVF.ar(input[0], safeFreq*64, safeRes, 0.0, 1.0, 0.0).tanh,
								]),
							Mix.ar([
								SVF.ar(input[1], safeFreq, safeRes, 0.0, 1.0, 0.0).tanh,
								SVF.ar(input[1], safeFreq*4, safeRes, 0.0, 1.0, 0.0).tanh,
								SVF.ar(input[1], safeFreq*16, safeRes, 0.0, 1.0, 0.0).tanh,
								SVF.ar(input[1], safeFreq*64, safeRes, 0.0, 1.0, 0.0).tanh,
							])
						],
						// 4 - passthrough
						input
					]);	
					// Make dry/wet mix between filtered/unfiltered; multiply by gain; take the tanh of that
					var drySig = input * dry;
					var wetSig = filteredSignal * (1-dry);
					var mix = drySig + wetSig;
					var output = (gain * mix).tanh;
					Out.ar(out, output);
				}).add;
			}
		}
	}
}
