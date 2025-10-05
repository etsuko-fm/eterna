BassMono {
	*initClass {
		StartUp.add {
			var s = Server.default;
			s.waitForBoot {
				SynthDef("BassMono", {
					arg in, out, freq=100.0, dry=0.0, enabled=1;
					var input = In.ar(in, 2);
					var rq = 1.5; // higher value is lower res
					var signal = Select.ar(enabled, [
						input, 
						BLowPass4.ar(Mix(input), freq, rq) + [
							BHiPass4.ar(input[0], freq, rq),
							BHiPass4.ar(input[1], freq, rq),
                    	]
					]);					
					var drySig = input * dry;
					var wetSig = signal * (1-dry);
					var mix = drySig + wetSig;
					Out.ar(out, mix);
				}).add;
			}
		}
	}
}
