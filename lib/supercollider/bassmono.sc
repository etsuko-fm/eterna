BassMono {
	*initClass {
		StartUp.add {
			var s = Server.default;
			s.waitForBoot {
				SynthDef("BassMono", {
					arg in, out, freq=100.0;
					var input = In.ar(in, 2);
					var rq = 1.5; // higher value is lower res
					
					// Lag prevents clicks when switching
					var lag_freq = LagUD.kr(freq, 1.0, 0.1);
					
					var signal = BLowPass4.ar(Mix(input), lag_freq, rq) + [
							BHiPass4.ar(input[0], lag_freq, rq),
							BHiPass4.ar(input[1], lag_freq, rq),
					];
					Out.ar(out, signal);
				}).add;
			}
		}
	}
}
