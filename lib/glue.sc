GlueCompressor {
	*initClass {
		StartUp.add {
			var s = Server.default;
			s.waitForBoot {
				SynthDef("GlueCompressor", {
					arg in, out, gain=1.0;
                    var in_signal = In.ar(in, 2) * gain;
                    var compressed = Compander.ar(in_signal, in_signal, thresh: 0.5, slopeBelow: 1.0, slopeAbove: 1/3, clampTime: 0.01, relaxTime: 0.3);
                    var limited = compressed.tanh;
					Out.ar(out, limited);
				}).add;
			}
		}
	}
}
