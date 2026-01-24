DubEcho {
	*initClass {
		StartUp.add {
			var s = Server.default;
			s.waitForBoot {
				SynthDef("DubEcho", {
					arg in, out, wet=0.5, feedback=0.8, time=0.1;
					var input = In.ar(in, 2);
                    var output;
                    var delA, delB, delX, fbSignal;
                    var fadeTime=0.05;
                    var drive = 1.5;

                    var first = Impulse.kr(0);

                    // If time changed, or first run, trigger
                    var t_trig = Changed.kr(time) + first;

                    // Mechanism to allow one t_trig to alternately trigger t_1 and t_2
                    var which = ToggleFF.kr(t_trig);
                    var t_1 = Select.kr(which, [t_trig, 0]);
					var t_2 = Select.kr(which, [0, t_trig]);

                    var fade = EnvGen.kr(Env([1-which, which],[fadeTime]), t_trig);

                    // Alternately update delay time A/B, to enable crossfading to prevent click on changing delay time
                    var timeA = Latch.kr(time, t_1);
                    var timeB = Latch.kr(time, t_2);

                    // Delay line with input local to this SynthDef
                    fbSignal = input + (LocalIn.ar(2) * feedback);
                    fbSignal = BPF.ar((fbSignal * drive).tanh * 1/drive, 1000, 2.0);

                    // Create delay lines, compensating time for processing of sample
                    // timeA and timeB are different when delay time was adjusted by client
                    delA = DelayL.ar(fbSignal, 2.0, timeA - ControlDur.ir);
                    delB = DelayL.ar(fbSignal, 2.0, timeB - ControlDur.ir);

                    // Crossfade between delay lines to prevent clicks when changing delay time
                    delX = SelectX.ar(fade, [delA, delB]);

                    // Swap left and right channel (ping-pong)
                    delX = delX.swap(0, 1);

                    LocalOut.ar(delX);
                    delX = LPF.ar(delX, 10000);
                    output = input + (delX * wet); // wet/dry mix

					Out.ar(out, output);
				}).add;
			}
		}
	}   
}
