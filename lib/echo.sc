Echo {
	*initClass {
		StartUp.add {
			var s = Server.default;
			s.waitForBoot {
				SynthDef("Echo", {
					arg in, out, wet=1.0, freq=63.0, res = 0.2, gain=1.0;
					var dry, dryL, dryR, outputL, outputR, dry_signal, signal;
					var input = In.ar(in, 2);
					var safeFreq = freq.clip(5.0, 24000.0);
					var safeRes = res.clip(0.1, 2.0);
					var filtersL = Mix.ar([
						SVF.ar(input[0], safeFreq*2, Lag.kr(res), 0.0, 1.0, 0.0).tanh,
					]);

					var filtersR = Mix.ar([
						SVF.ar(input[1], safeFreq*2, Lag.kr(res), 0.0, 1.0, 0.0).tanh,
					]);

                    var numAllPassFilters = 4;
                    var delayTime, output;
                    var primes = [3, 5, 7, 11, 13, 17, 19, 23];
                    var delayTimes = primes.collect { |p| p * 0.001 };
                    delayTimes = delayTimes.keep(numAllPassFilters);

                    delayTime = 0.1;

                    wet = input + (LocalIn.ar(2) * -2.dbamp); // feedback control
                    wet = DelayC.ar(wet, 1.0, delayTime - ControlDur.ir);
                    delayTimes.do{|delay|
                        wet = AllpassC.ar(wet, 0.1, delay, 1);
                    };
                    wet = LPF.ar(wet, 2000);
                    LocalOut.ar(wet);
                    output = input + (wet * -5.dbamp); // wet/dry mix

					Out.ar(out, output);
				}).add;
			} // waitForBoot
		} //add
	} // initClass
}
