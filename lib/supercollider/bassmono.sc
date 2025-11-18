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
					var lagFreq = LagUD.kr(freq, 1.0, 0.1);
					var monoMix = Mix(input);

					/* Split off low frequency content using 2 cascaded 2nd order 
					   butterworth filters, to create a 4th order one. 
					   That creates a linear amplitude response. 
					*/
					var mono = LPF.ar(LPF.ar(monoMix, lagFreq), lagFreq); 
					
					// Same trick for frequencies above cutoff, but keep them stereo
					var signal = mono + [
							HPF.ar(HPF.ar(input[0], lagFreq), lagFreq),
							HPF.ar(HPF.ar(input[1], lagFreq), lagFreq),
					];
					Out.ar(out, signal);
				}).add;
			}
		}
	}
}
