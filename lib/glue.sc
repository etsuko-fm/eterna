GlueCompressor {
	*initClass {
		StartUp.add {
			var s = Server.default;
			s.waitForBoot {
				SynthDef("GlueCompressor", {
					arg in, out, preControlBusL, preControlBusR, postControlBusL, postControlBusR, gain=1.0;
                    var in_signal = In.ar(in, 2);
					var in_scaled = in_signal * gain;
					var preLevel =  LagUD.ar(Peak.ar(in_signal, Impulse.ar(60)), 0, 1);

                    var compressed = Compander.ar(in_scaled, in_scaled, thresh: 0.5, slopeBelow: 1.0, slopeAbove: 1/3, clampTime: 0.01, relaxTime: 0.3);
                    var limited = compressed.tanh;

					var postLevel =  LagUD.ar(Peak.ar(limited, Impulse.ar(60)), 0, 1);

					Out.ar(out, limited);
					Out.kr(preControlBusL, preLevel[0]);
					Out.kr(preControlBusR, preLevel[1]);
					Out.kr(postControlBusL, postLevel[0]);
					Out.kr(postControlBusR, postLevel[1]);

				}).add;
			}
		}
	}
}
