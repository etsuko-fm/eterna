DustEcho {
	*initClass {
		StartUp.add {
			var s = Server.default;
			s.waitForBoot {
				SynthDef("DustEcho", {
					arg in, out, wet=0.5, feedback=0.8, time=0.1;
                    var grains, rate, filteredFeedback;
					var input = In.ar(in, 2);
                    var output;
                    var delA, delB, delX, fbSignal;
                    var times = [5,19,35,36];
                    var allPassDelayTimes = times.collect { |p| p * 0.01 };
                    var trig;
                    var buf = LocalBuf(48000);
                    var mix;
	                buf.clear;

                    fbSignal = LocalIn.ar(1);
                    filteredFeedback = LPF.ar(fbSignal, 7000, 1);

                    allPassDelayTimes.do { |t,i|
                        filteredFeedback = AllpassL.ar(
                            CombL.ar(filteredFeedback, 0.2, t),
                            0.3, //max delay time
                            t, //delay
                            LFNoise1.kr(25, mul: 0.5, add: 1)
                        ); // decay
                    };
                    RecordBuf.ar(LPF.ar((fbSignal*0.5)+(filteredFeedback*0.5), 4500).tanh , buf, recLevel: feedback, loop: 1);
                    
                    // Alter forward/backward playback
                    rate = Dseq([1, 1, -1, 1, -1, -1, 1], inf);
                    
                    // Trigger random grains, plus one every <time>
                    trig = Dust.kr(2/time) + Impulse.kr(2/time);

                    // Grains plays from the feedback buffer
                    grains = DelayL.ar(TGrains.ar(
                        2, //numchannels
                        trig,
                        buf,
                        rate,
                        LFNoise1.kr(1/time, mul: 0.25, add: 0.75), // position in buffer
                        LFNoise1.kr(1/time, mul: 0.25, add: 0.26), // duration
                        Dseq([-1, 1, 0], inf),//,LFNoise1.kr(50),      // random pan
                        0.7, //amp
                    ), 2, time);

                    // Send grains into feedback loop
                    LocalOut.ar(Mix.ar(input) * 0.5 + Mix.ar(grains) * 0.5);

                    // Output wet+dry mix
                    output = input + (grains * wet);
					Out.ar(out, output);
				}).add;
			}
		}
	}   
}
