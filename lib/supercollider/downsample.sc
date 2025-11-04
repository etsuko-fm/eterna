Downsample {
	*initClass {
		StartUp.add {
			var s = Server.default;
			s.waitForBoot {
                SynthDef(\Downsample, { |srcBuf, destBuf, factor = 16|
                    // Scan through scrBuf at a given speed, write result to destBuf
                    var phasor = Phasor.ar(0, factor, 0, BufFrames.kr(srcBuf));
                    var sig = BufRd.ar(1, srcBuf, phasor, loop: 0);
                    RecordBuf.ar(sig, destBuf, loop: 0, doneAction: Done.freeSelf);
                }).add;
			}
		}
	}   
}
