GlueCompressor {
	*initClass {
		StartUp.add {
			var s = Server.default;
			s.waitForBoot {
				SynthDef("GlueCompressor", {
					arg in, out, preControlBusL, preControlBusR, postControlBusL, postControlBusR, compAmountBusL, compAmountBusR, gain=1.0;
                    var in_signal = In.ar(in, 2);
					var in_scaled = in_signal * gain;
					var preLevel =  Amplitude.ar(in_signal, 0, 0.2);

                    var compressed = Compander.ar(in_scaled, in_scaled, thresh: 0.5, slopeBelow: 1.0, slopeAbove: 1/3, clampTime: 0.01, relaxTime: 0.3);
                    var limited = compressed.tanh;

					// measure amplitude envelopes
					var inAmp  = Amplitude.ar(in_scaled, 0, 0.01);   // short attack/release
					var outAmp = Amplitude.ar(limited, 0, 0.01);
					var compAmount = inAmp - outAmp;

					var postLevel = Amplitude.ar(limited, 0, 0.2);

					Out.ar(out, limited);
					Out.kr(preControlBusL, preLevel[0]);
					Out.kr(preControlBusR, preLevel[1]);
					Out.kr(postControlBusL, postLevel[0]);
					Out.kr(postControlBusR, postLevel[1]);
					Out.kr(compAmountBusL, compAmount[0]);
					Out.kr(compAmountBusR, compAmount[1]);

				}).add;
			}
		}
	}
}
