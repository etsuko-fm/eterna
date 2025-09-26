BassMono {
	*initClass {
		StartUp.add {
			var s = Server.default;
			s.waitForBoot {
				SynthDef("BassMono", {
					arg in, out, freq=100.0, dry=0.0;
					var input = In.ar(in, 2);
                    var bassMono = BLowPass.ar(BLowPass.ar(Mix(input), freq), freq);
                    var stereo = [
                        BHiPass.ar(BHiPass.ar(input[0], freq), freq),
                        BHiPass.ar(BHiPass.ar(input[1], freq), freq),
                    ];
                    var filteredSignal = bassMono + stereo;
					var drySig = input * dry;
					var wetSig = filteredSignal * (1-dry);
					var mix = drySig + wetSig;
                    // use tanh as a limiter
					var output = mix.tanh;
					Out.ar(out, output);
				}).add;
			}
		}
	}
}
