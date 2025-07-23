TapeVoice {
	var <params;
	*initClass {
		StartUp.add {
			var s = Server.default;
			s.waitForBoot {
				SynthDef("tapevoice", {
					// loopStart and loopEnd in seconds
					// 't_' has a special meaning in SC, resets value to zero after receiving a 1
					arg out, rate = 0, bufnum=0, loop=0.0, loopStart=0.0, loopEnd=0.0, gate=0, t_trig=0, attack=0.01, decay=1.0, pan=0.0, level=1.0, envLevel=1.0, freq=400.0, res=0.2, xfade=0.01, curve=(-4);
					var end, playhead1, playhead2, playback, playback1, playback2;
					var start = loopStart  * SampleRate.ir; // convert seconds to samples
					var playheadId = ToggleFF.kr(t_trig); // toggles each time voice is triggered
					var crossfade = -1 + Lag.ar(K2A.ar(playheadId*2), xfade);
					var t_1 = Select.kr(playheadId, [t_trig, 0]);
					var t_2 = Select.kr(playheadId, [0, t_trig]);

					// if loopEnd is set, use it; otherwise use entire buffer
					end = Select.kr(
						loopEnd > 0,
						[
							BufFrames.kr(bufnum),
							loopEnd * SampleRate.ir
						]
					);

					playhead1 = Phasor.ar(
						trig: t_1,
						rate: BufRateScale.kr(bufnum) * rate,
						start: start,
						end: end,
						resetPos: start
					);
					playhead2 = Phasor.ar(
						trig: t_2,
						rate: BufRateScale.kr(bufnum) * rate,
						start: start,
						end: end,
						resetPos: start
					);
					playback1 = BufRd.ar(
						numChannels: 1,
						bufnum: bufnum,
						phase: playhead1,
						loop: loop,
						interpolation: 4
					);
					playback2 = BufRd.ar(
						numChannels: 1,
						bufnum: bufnum,
						phase: playhead2,
						loop: loop,
						interpolation: 4
					);

					// First "VCA" is envLevel
					playback1 = playback1 * EnvGen.ar(Env.perc(attack, decay, envLevel, curve), t_1);
					playback1 = SVF.ar(playback1, EnvGen.ar(Env.perc(attack, decay, envLevel, curve), t_1) * Lag.kr(freq), Lag.kr(res), 1.0, 0.0, 0.0);

					playback2 = playback2 * EnvGen.ar(Env.perc(attack, decay, envLevel, curve), t_2);
					playback2 = SVF.ar(playback2, EnvGen.ar(Env.perc(attack, decay, envLevel, curve), t_2) * Lag.kr(freq), Lag.kr(res), 1.0, 0.0, 0.0);

					playback = XFade2.ar(playback1, playback2, crossfade);
					playback = Pan2.ar(playback, pan);

					// Second "VCA" is level
					Out.ar(out, playback * level);
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