BassMono {
	*initClass {
		StartUp.add {
			var s = Server.default;
			s.waitForBoot {
				SynthDef("BassMono", {
					arg in, out, freq=100.0, enabled=1;
					var input = In.ar(in, 2);
					var rq = 1.5; // higher value is lower res
					
					// Lag prevents clicks when switching
					var lag_freq = LagUD.kr(freq, 1.0, 0.1);
					
					var signal = Select.ar(enabled, [
						input, 
						BLowPass4.ar(Mix(input), LagUD.kr(freq, 1.0, 0.1), rq) + [
							BHiPass4.ar(input[0], LagUD.kr(freq, 1.0, 0.1), rq),
							BHiPass4.ar(input[1], LagUD.kr(freq, 1.0, 0.1), rq),
                    	]
					]);					
					Out.ar(out, signal);
				}).add;
			}
		}
	}
}
