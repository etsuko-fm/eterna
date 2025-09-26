GlueCompressor {
	*initClass {
		StartUp.add {
			var s = Server.default;
			s.waitForBoot {
				SynthDef("GlueCompressor", {
					arg in, out, preControlBuses, postControlBuses, gain=1.0;
                    var in_signal = In.ar(in, 2) * gain;

                    var compressed = Compander.ar(in_signal, in_signal, thresh: 0.5, slopeBelow: 1.0, slopeAbove: 1/3, clampTime: 0.01, relaxTime: 0.3);
                    var limited = compressed.tanh;

					var preLevel =  LagUD.ar(Peak.ar(In.ar(in, 2), Impulse.ar(60)), 0, 1);
					var postLevel =  LagUD.ar(Peak.ar(limited, Impulse.ar(60)), 0, 1);

					Out.ar(out, limited);
					Out.kr(preControlBuses[0], preLevel[0]);
					Out.kr(preControlBuses[1], preLevel[1]);
					Out.kr(postControlBuses[0], postLevel[0]);
					Out.kr(postControlBuses[1], postLevel[1]);

				}).add;
			}
		}
	}
}
