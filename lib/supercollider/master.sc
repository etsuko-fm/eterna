Master {
	*initClass {
		StartUp.add {
			var s = Server.default;
			s.waitForBoot {
				SynthDef("Master", {
					arg in, out, 
					preControlBusL, preControlBusR, 
					postCompControlBusL, postCompControlBusR, 
					postGainBusL, postGainBusR, 
					masterOutControlBusL, masterOutControlBusR,
					ratio=3, drive=1.0, metering_rate = 0, 
					threshold=0.25, attack=0.01, release=0.3, out_level=1.0;
                    var in_signal = In.ar(in, 2);

					// Measure amplitude of unprocessed input
					var preAmp = LagUD.kr(Peak.kr(in_signal, Impulse.kr(metering_rate)), 0, 0.1);

					// Apply drive before compression
					var in_scaled = in_signal * drive;

					// Add compression, limit using tanh
                    var compressed = Compander.ar(in_scaled, in_scaled, thresh: threshold, slopeBelow: 1.0, slopeAbove: 1/ratio, clampTime: attack, relaxTime: release);
                    var limited = compressed.tanh;

					// Amplitude meter after drive, before compression
					var postGainAmp = LagUD.kr(Peak.kr(in_scaled, Impulse.kr(metering_rate)), 0, 0.1);

					// Amplitude meter after compression and limiting
					var postCompAmp = LagUD.kr(Peak.kr(limited, Impulse.kr(metering_rate)), 0, 0.1);

					// Master out (expects out_level to be <= 1.0, because no limiter on this bit)
					var masterOut = limited * out_level;
					var masterOutAmp = LagUD.kr(Peak.kr(masterOut, Impulse.kr(metering_rate)), 0, 0.1);

					// Send sample values, can be used, for example, to plot Lissajous curve
					SendReply.kr(Impulse.kr(metering_rate), '/amp', [limited[0], limited[1]]);

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
