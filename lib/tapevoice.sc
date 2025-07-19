TapeVoice {
	var <params;
	*initClass {
		StartUp.add {
			var s = Server.default;
			s.waitForBoot {
				SynthDef("tapevoice", {
					// loopStart and loopEnd in seconds
					arg out, rate = 0, bufnum=0, interpolation=4, loopStart=0.0, loopEnd=0.0, gate=0, t_trig=0, decay=1.0;
					var end, playhead, playback;
					var start = loopStart * SampleRate.ir;
					playhead = Phasor.ar(
						trig: t_trig,
						rate: rate,
						start: start,
						end: if (loopEnd == 0, { BufFrames.kr(bufnum) },{ loopEnd * SampleRate.ir }),
						resetPos: start;
					);
					playback = BufRd.ar(
						numChannels: 1,
						bufnum: bufnum,
						phase: playhead,
						interpolation: interpolation;
					);
					// to add: pan, volume
					playback = playback * EnvGen.ar(Env.perc(0.01, decay, 1, -4), t_trig);

					Out.ar(out, [playback, playback]);
				}).add;
			} // waitForBoot
		} //add
	} // initClass

	*new { // when this class is initialized...
		^super.new.init; // ...run the 'init' below.
	}

	init {
		params = Dictionary.newFrom([
			\out, 0,
			\trigger, 0,
			\rate, 0,
			\numChannels, 1,
			\buffNum, 0,
			\interpolation, 4,
			\resetPos, 0,
			\loopEnd, 0,
		]);
	}
	setParam { arg paramKey, paramValue;
		params[paramKey] = paramValue;
	}
}