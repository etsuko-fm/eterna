MistEcho {
	*initClass {
		StartUp.add {
			var s = Server.default;
			s.waitForBoot {
				SynthDef("MistEcho", {
					arg in, out, wetAmount=0.5, feedback=0.8, delayTime=0.1, t_trig;
					var input = In.ar(in, 2);
                    var output;
                    var delayTimesL = [11, 19, 37, 39, 77, 101];
                    var delayTimesR = [17, 25, 31, 13, 12, 111];	
                    var modTimesL = [0.053, 0.097, 0.163, 0.233, 0.307, 0.383];
                    var modTimesR = [0.067, 0.121, 0.187, 0.257, 0.331, 0.397];

                    var allPassDelayTimesL = delayTimesL.collect { |p| p * 0.001 };
                    var allPassDelayTimesR = delayTimesR.collect { |p| p * 0.001 };

                    var delA, delB, delX, fbSignal;
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
                    var reverbMix = 0.3;
                    var dryFeedback;

                    // Delay line with input local to this SynthDef
                    fbSignal = input + (LocalIn.ar(2) * feedback);

                    // Create delay lines, compensating time for processing of sample
                    delA = DelayL.ar(fbSignal, 1.0, delayTimeA - ControlDur.ir);
                    delB = DelayL.ar(fbSignal, 1.0, delayTimeB - ControlDur.ir);

                    // Crossfade between delay lines to prevent clicks when switching time param
                    delX = SelectX.ar(fade, [delA, delB]);

                    // Swap left and right channel (ping-pong)
                    delX = delX.swap(0, 1);

                    // Filter feedback before going into reverb stage
                    delX = HPF.ar(LPF.ar(delX, 4500), 150);

                    // Reference to the delay line before reverb
                    dryFeedback = delX;

                    // Reverb - series of allpass filters with different delay times for left and right
                    // After each pass, the left and right channels are mixed
                    // Each APF's delay time is modulated with ±10ms, using a 0.1Hz sine LFO
                    allPassDelayTimesL.do { |t,i|
                        delX[0] = HPF.ar(LPF.ar(
                            AllpassL.ar(
                                delX[0], 
                                0.3, 
                                (t - 0.01 + (SinOsc.ar(modTimesL[i]) * (t * 0.02))).abs, 
                                1
                            ), 
                            5000
                        ), 150);
                        delX[1] = HPF.ar(LPF.ar(
                            AllpassL.ar(
                                delX[1], 
                                0.3, 
                                (allPassDelayTimesR[i] - 0.01 + (SinOsc.ar(modTimesR[i]) * (allPassDelayTimesR[i] * 0.02))).abs, 
                                1
                            ), 
                            5000
                        ), 150);
                        
                        // Crossmix left/right channels
                        delX = [
                            (1 - cross) * delX[0] + (cross * delX[1]),
                            (1 - cross) * delX[1] + (cross * delX[0])
                        ];
                    };

                    // Mix in original delay line (from before reverb)
                    delX = SelectX.ar(reverbMix, [dryFeedback, delX]);

                    LocalOut.ar(delX);
                    delX = LPF.ar(delX, 10000);
                    output = input + (delX * wetAmount); // wet/dry mix

					Out.ar(out, output);
				}).add;
			}
		}
	}   
}
