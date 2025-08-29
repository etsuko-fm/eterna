Echo {
	*initClass {
		StartUp.add {
			var s = Server.default;
			s.waitForBoot {
				SynthDef("BitsEcho", {
					arg in, out, wetAmount=0.5, feedback=0.8, delayTime=0.1, style=0;
					var input = In.ar(in, 2);
					var wetSig;
                    var numAllPassFilters = 8;
                    var output;
                    var primes = [3, 5, 7, 11, 13, 17, 19, 23];
                    var delayTimes = primes.collect { |p| p * 0.001 };
                    delayTimes = delayTimes.keep(numAllPassFilters);

                    wetSig = input + (LocalIn.ar(2) * feedback); // feedback control
                    wetSig = DelayC.ar(wetSig, 1.0, Lag.kr(delayTime, 0.4) - ControlDur.ir);
                    delayTimes.do{|delay|
                        wetSig = AllpassC.ar(wetSig, 0.1, delay, 1);
                    };

                    wetSig = Select.ar(style, [
                        HPF.ar(wetSig, 25), // neutral 
                        HPF.ar(LPF.ar(wetSig, 2400), 50), // dark
                        HPF.ar(wetSig, 800) // bright
                    ]);
                    LocalOut.ar(wetSig);
                    output = input + (wetSig * wetAmount); // wet/dry mix

					Out.ar(out, output);
				}).add;
			}
		}
	}   
}
