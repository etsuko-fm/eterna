GlueCompressor {
	*initClass {
		StartUp.add {
			var s = Server.default;
			s.waitForBoot {
				SynthDef("GlueCompressor", {
					arg in, out, preControlBusL, preControlBusR, postControlBusL, postControlBusR, compAmountBusL, compAmountBusR, ratio=3, gain=1.0, meteringRate = 500, threshold=0.5, attack=0.01, release=0.3;
                    var in_signal = In.ar(in, 2);

					// Measure amplitude of input
					var preLevel = LagUD.ar(Peak.ar(in_signal, Impulse.ar(meteringRate)), 0, 0.1);

					// Apply gain before compression
					var in_scaled = in_signal * gain;

					// Add compression, limit using tanh
                    var compressed = Compander.ar(in_scaled, in_scaled, thresh: threshold, slopeBelow: 1.0, slopeAbove: 1/ratio, clampTime: attack, relaxTime: release);
                    var limited = compressed.tanh;

					// Measure amplitude envelopes
					var inAmp  = Amplitude.ar(in_scaled, 0, 0.01);   // short attack/release
					// var outAmp = Amplitude.ar(limited, 0, 0.01);
					var outAmp = LagUD.ar(Peak.ar(limited, Impulse.ar(meteringRate)), 0, 0.1);
					var compAmount = inAmp - Amplitude.ar(limited, 0, 0.01); // was: - outAmp

					var postLevel = Amplitude.ar(limited, 0, 0.2);
					var ampSendTrig = Impulse.ar(meteringRate);
					SendReply.ar(ampSendTrig, '/amp', [limited[0], limited[1]]);

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
