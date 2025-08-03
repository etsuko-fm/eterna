Echo {
	*initClass {
		StartUp.add {
			var s = Server.default;
			s.waitForBoot {
				SynthDef("BitsEcho", {
					arg in, out, wetAmount=0.5, feedback=0.8, delayTime=0.1;
					var input = In.ar(in, 2);
					var wetSig;
                    var numAllPassFilters = 4;
                    var output;
                    var primes = [3, 5, 7, 11, 13, 17, 19, 23];
                    var delayTimes = primes.collect { |p| p * 0.001 };
                    delayTimes = delayTimes.keep(numAllPassFilters);

                    wetSig = input + (LocalIn.ar(2) * feedback); // feedback control
                    wetSig = DelayC.ar(wetSig, 1.0, delayTime - ControlDur.ir);
                    delayTimes.do{|delay|
                        wetSig = AllpassC.ar(wetSig, 0.1, delay, 1);
                    };
                    wetSig = LPF.ar(wetSig, 2000);
                    LocalOut.ar(wetSig);
                    output = input + (wetSig * wetAmount); // wet/dry mix

					Out.ar(out, output);
				}).add;
			} // waitForBoot
		} //add
	} // initClass
}
