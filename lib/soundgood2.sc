// Source: https://github.com/geikha/30-_TEKZ/blob/main/SC/SYNTHDEFS/soundgood_2.scd
SoundGood {
	*initClass {
		StartUp.add {
			var s = Server.default;
			s.waitForBoot {
				SynthDef("soundgood_2", {
					arg in, out, wet=0.36, makeup=0.98;
                    var lfreq = 250, hfreq = 4000, q = 1.5;
                    var dry, low, mid, high, master;
                    var att = 20/1000;
                    var lrel = 137/1000, lpre = dbamp(4.4*wet), lpos = dbamp(6*wet), lexp = 0.07*wet, lstereo = -0.8*wet;
                    var mrel = 85/1000, mpre = dbamp(6*wet), mpos = 1.32, mstereo = 0.3*wet;
                    var hrel = 75/1000, hpre = dbamp(6.3*wet), hpos = dbamp(4.1*wet), hexp = 0.1*wet, hstereo = 0.2, hsat = 1/12*wet;
                    var output;
                    var midside = {|in, msBalance=0|
                        var sig = Balance2.ar(in[0] + in[1], in[0] - in[1], msBalance);
                        [sig[0] + sig[1], sig[0] - sig[1]] * sqrt((msBalance.max(0) + 1) / 2)
                    };

                    dry = In.ar(in,2);
                    dry = LeakDC.ar(dry,0.996);

                    low = BLowPass4.ar(dry,lfreq,q);
                    mid = BHiPass4.ar(dry,lfreq,q); 
                    mid = BLowPass4.ar(mid,hfreq,q);
                    high = BHiPass4.ar(dry,hfreq,q);

                    low = CompanderD.ar(low*lpre,1,1+lexp,10,att,lrel,lpos);
                    low = midside.(low, lstereo);
                    low = SineShaper.ar(low);

                    mid = CompanderD.ar(mid*mpre,1,1,10,att,lrel,mpos);
                    mid = midside.(mid, mstereo);

                    high = CompanderD.ar(high*hpre,1,1+hexp,10,att,hrel,hpos);
                    high = midside.(high, hstereo);
                    high = SineShaper.ar(high,hpos-(hpos*hsat));

                    master = Limiter.ar(LeakDC.ar(Mix.new([low,mid,high])),0.99,0.01)*makeup;

                    Out.ar(out, master);
                }).add;
			}
		}
	}
}
