SymSVF {
	*initClass {
		StartUp.add {
			var s = Server.default;
			s.waitForBoot {
				SynthDef("SymSVF", {
					arg in, out, freq=2500.0, res = 0.2, gain=1.0, dry=0.0, filter_type=0;
					var input = In.ar(in, 2);
					var safeFreq = Lag.kr(freq.clip(5.0, 24000.0));
					var safeRes = Lag.kr(res.clip(0.0, 0.999));

					//filter_type -> 0: highpass
					//				 1: lowpass
					//			     2: bandpass
					var hp = Select.kr(filter_type, [1.0, 0.0, 0.0]);
					var lp = Select.kr(filter_type, [0.0, 1.0, 0.0]);
					var bp = Select.kr(filter_type, [0.0, 0.0, 1.0]);

					var filtered = [
							SVF.ar(input[0], safeFreq, safeRes, lp, bp, hp).tanh,
							SVF.ar(input[1], safeFreq, safeRes, lp, bp, hp).tanh,
					];

					// Make dry/wet mix between filtered/unfiltered; multiply by gain; take the tanh of that
					var drySig = input * dry;
					var wetSig = filtered * (1-dry);
					var mix = drySig + wetSig;
					var output = (gain * mix).tanh;
					Out.ar(out, output);
				}).add;
			}
		}
	}
}
