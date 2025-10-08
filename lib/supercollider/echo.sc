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
                    var delayTimesL = [11, 19, 37, 39, 77, 101];
                    var delayTimesR = [17, 25, 31, 9, 12, 111];	
                    var allPassDelayTimesL = delayTimesL.collect { |p| p * 0.001 };
                    var allPassDelayTimesR = delayTimesR.collect { |p| p * 0.001 };
                    var delA, delB, fbSignal;
                    var fadeTime=0.05;
                    
                    // Mechanism to allow one t_trig to alternately trigger t_1 and t_2
                    var which = ToggleFF.kr(t_trig);
                    var t_1 = Select.kr(which, [t_trig, 0]);
					var t_2 = Select.kr(which, [0, t_trig]);

                    var fade = EnvGen.kr(Env([1-which, which],[fadeTime]), t_trig);

                    // Alternately update delay time A/B, to enable crossfading to prevent click on changing delay time
                    var delayTimeA = Latch.kr(delayTime, t_1);
                    var delayTimeB = Latch.kr(delayTime, t_2);

                    // Amount of crossfeeding between left and right channel
                    var cross = 0.3;

                    // Delay line local to this SynthDef
                    fbSignal = input + (LocalIn.ar(2) * feedback);

                    // Create delay lines, compensating time for processing of sample
                    delA = DelayL.ar(fbSignal, 1.0, delayTimeA - ControlDur.ir);
                    delB = DelayL.ar(fbSignal, 1.0, delayTimeB - ControlDur.ir);

                    // Crossfade between delay lines to prevent clicks when switching time param
                    wetSig = SelectX.ar(fade, [delA, delB]);

                    // Modulate each APF's delay time with ±5ms, using an LFO whose frequency is set to the APF's time itself;
                    // This allows all LFOs to run at a different frequency
                    allPassDelayTimesL.do { |t|
                        wetSig[0] = LPF.ar(
                            AllpassL.ar(
                                wetSig[0], 
                                0.3, 
                                (t - 0.005 + (SinOsc.kr(t) * (t * 0.01))).abs, 
                                1
                            ), 
                            6000
                        );
                    };
                    allPassDelayTimesR.do { |t|
                        wetSig[1] = LPF.ar(
                            AllpassL.ar(
                                wetSig[0], 
                                0.3, 
                                (t - 0.005 + (SinOsc.kr(t) * (t * 0.01))).abs, 
                                1
                            ), 
                            6000
                        );
                    };

                    // crossmix left/right channels
                    wetSig = [
                        (1 - cross) * wetSig[0] + (cross * wetSig[1]),
                        (1 - cross) * wetSig[1] + (cross * wetSig[0])
                    ];

                    wetSig = Select.ar(style, [
                        HPF.ar(wetSig, 25), // neutral 
                        HPF.ar(LPF.ar(wetSig, 2400), 50), // dark
                        HPF.ar(wetSig, 800) // bright
                    ]);
                    LocalOut.ar(wetSig);
                    wetSig = LPF.ar(wetSig, 10000);
                    output = input + (wetSig * wetAmount); // wet/dry mix

					Out.ar(out, output);
				}).add;
			}
		}
	}   
}
