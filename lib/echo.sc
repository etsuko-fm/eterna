Echo {
	*initClass {
		StartUp.add {
			var s = Server.default;
			s.waitForBoot {
                // refactor such that can use echo.set(\newDelayTime, time, \t_trig, 1);

				SynthDef("BitsEcho", {
					arg in, out, wetAmount=0.5, feedback=0.8, delayTime, style=0, blur=3, t_trig;
					var input = In.ar(in, 2);
					var wetSig;
                    var output;
                    var primes = [3, 5, 7, 11, 13, 17, 19, 23];
                    var allPassDelayTimes = primes.collect { |p| p * 0.001 };
                    var delA, delB, fbSignal;
                    var fadeTime=0.05;
                    
                    // Mechanism to allow one t_trig to alternately trigger t_1 and t_2
                    var which = ToggleFF.kr(t_trig);
                    var t_1 = Select.kr(which, [t_trig, 0]);
					var t_2 = Select.kr(which, [0, t_trig]);

                    var fade = EnvGen.kr(Env([1-which, which],[fadeTime]), t_trig);

                    // Alternately update delay time A/B
                    var delayTimeA = Latch.kr(delayTime, t_1);
                    var delayTimeB = Latch.kr(delayTime, t_2);

                    // Blur maps to number of allpass filters
                    allPassDelayTimes = allPassDelayTimes.keep(3);

                    fbSignal = input + (LocalIn.ar(2) * feedback);

                    delA = DelayC.ar(fbSignal, 1.0, delayTimeA - ControlDur.ir);
                    delB = DelayC.ar(fbSignal, 1.0, delayTimeB - ControlDur.ir);
                    wetSig = SelectX.ar(fade, [delA, delB]);

                    allPassDelayTimes.do{|t|
                        wetSig = AllpassC.ar(wetSig, 0.1, t, 1);
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
