Downsample {
	*initClass {
		StartUp.add {
			var s = Server.default;
			s.waitForBoot {
                SynthDef("Downsample", { |srcBuf, destBuf, channel, factor = 16|
                    // Scan through scrBuf at a given speed, write result to destBuf
					var sig = PlayBuf.ar(1, srcBuf, factor);
					var rec = RecordBuf.ar([sig], destBuf,recLevel:1, run:1.0 loop: 0);
					var done = Done.kr(sig);
					SendReply.kr(done, '/waveformDone', [channel]);
					FreeSelf.kr(done);
                }).add;
			}
		}
	}   
}
