Compressor {
	*initClass {
		StartUp.add {
			var s = Server.default;
			s.waitForBoot {
				SynthDef("GlueCompressor", {
					arg in, out, 
					preControlBusL, preControlBusR, 
					postCompControlBusL, postCompControlBusR, 
					postGainBusL, postGainBusR, 
					masterOutControlBusL, masterOutControlBusR,
					ratio=3, gain=1.0, meteringRate = 500, 
					threshold=0.25, attack=0.01, release=0.3, outLevel=1.0;
                    var in_signal = In.ar(in, 2);

					// Measure amplitude of unprocessed input
					var preAmp = LagUD.ar(Peak.ar(in_signal, Impulse.ar(meteringRate)), 0, 0.1);

					// Apply gain before compression
					var in_scaled = in_signal * gain;

					// Add compression, limit using tanh
                    var compressed = Compander.ar(in_scaled, in_scaled, thresh: threshold, slopeBelow: 1.0, slopeAbove: 1/ratio, clampTime: attack, relaxTime: release);
                    var limited = compressed.tanh;

					// Amplitude after gain, before compression
					var postGainAmp = LagUD.ar(Peak.ar(in_scaled, Impulse.ar(meteringRate)), 0, 0.1);

					// Amplitude after compression and limiting
					var postCompAmp = LagUD.ar(Peak.ar(limited, Impulse.ar(meteringRate)), 0, 0.1);

					// Send sample values, can be used to plot Lissajous curve
					SendReply.ar(Impulse.ar(meteringRate), '/amp', [limited[0], limited[1]]);

					var masterOut = limited * outLevel;
					var masterOutAmp = LagUD.ar(Peak.ar(masterOut, Impulse.ar(meteringRate)), 0, 0.1);

					// Audio out
					Out.ar(out, masterOut);

					// Send amplitudes to control buses
					Out.kr(preControlBusL, preAmp[0]);
					Out.kr(preControlBusR, preAmp[1]);
					Out.kr(postGainBusL, postGainAmp[0]);
					Out.kr(postGainBusR, postGainAmp[1]);
					Out.kr(postCompControlBusL, postCompAmp[0]);
					Out.kr(postCompControlBusR, postCompAmp[1]);
					Out.kr(masterOutControlBusL, masterOutAmp[0]);
					Out.kr(masterOutControlBusR, masterOutAmp[1]);

				}).add;
			}
		}
	}
}
