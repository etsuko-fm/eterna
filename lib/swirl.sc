Swirl {
	*initClass {
		StartUp.add {
			var s = Server.default;
			s.waitForBoot {
				SynthDef("swirlFilter", {
					arg in, out, wet=1.0, freq=63.0, res = 0.2, gain=1.0;

					var dry, dry_signal, signal;
					var input = In.ar(in, 2);
					var safeFreq = freq.clip(5.0, 24000.0);
					var safeRes = res.clip(0.1, 2.0);
					var filtered_signal = Mix.ar([
						SVF.ar(input, safeFreq*2, Lag.kr(res), 0.0, 1.0, 0.0).tanh,
						SVF.ar(input, safeFreq*8, Lag.kr(res), 0.0, 1.0, 0.0).tanh,
						SVF.ar(input, safeFreq*32, Lag.kr(res), 0.0, 1.0, 0.0).tanh,
						SVF.ar(input, safeFreq*128, Lag.kr(res), 0.0, 1.0, 0.0).tanh,
					]).tanh;

					dry = 1.0 - wet;
					filtered_signal = filtered_signal * wet;
					dry_signal = input * dry;
					signal = ((filtered_signal + dry_signal) * gain).tanh;

					Out.ar(out, signal);
				}).add;

			} // waitForBoot
		} //add
	} // initClass
}