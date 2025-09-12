TapeVoice {
	var <params;
	*initClass {
		StartUp.add {
			var s = Server.default;
			s.waitForBoot {
				SynthDef("tapevoice", {
					// loopStart and loopEnd in seconds
					// 't_' has a special meaning in SC, resets value to zero after receiving a 1
					arg out, rate = 0, bufnum=0, loop=0.0, loopStart=0.0, loopEnd=0.0,
					 t_trig=0, attack=0.01, decay=1.0, pan=0.0, level=1.0, envLevel=1.0, freq=20000,
					 res=0.0, xfade=0.05, curve=(-4), enableEnv=1, enableLpg=0, ampBus, envBus;
					var start, end, playhead1, playhead2, playback, playback1, playback2, start1, start2, end1, end2, duration1, duration2;
					var playheadId = ToggleFF.kr(t_trig); // toggles each time voice is triggered

					// crossfade value between -1 and 1; playheadId is 0 or 1, so subtract 1, multiply by 2 to get a value in correct range
					var crossfade = -1 + Lag.ar(K2A.ar(playheadId*2), xfade);
					var t_1 = Select.kr(playheadId, [t_trig, 0]);
					var t_2 = Select.kr(playheadId, [0, t_trig]);
					var percEnv1, percEnv2, ramp, position, ramp1, ramp2, playheadEnv1, playheadEnv2;
					var amp;

					// Convert start from seconds to frames
					start = loopStart  * BufSampleRate.ir(bufnum);

					// if loopEnd is set, use it; otherwise use entire buffer
					end = Select.kr(
						loopEnd > 0,
						[
							BufFrames.kr(bufnum),
							loopEnd * BufSampleRate.ir(bufnum)
						]
					);

					// Lock start and end position upon trigger
					start1 = Latch.kr(start, playheadId);
					start2 = Latch.kr(start, 1-playheadId);
					end1 = Latch.kr(end, playheadId);
					end2 = Latch.kr(end, 1-playheadId);

 					//duration of enabled section, in seconds
					duration1 = (end1 - start1).abs / BufSampleRate.ir(bufnum) / rate.abs;
					duration2 = (end2 - start2).abs / BufSampleRate.ir(bufnum) / rate.abs;
					playheadEnv1 = Env.new([0, 1, 1, 0], [0, duration1 - 0.01, 0.01], \lin);
					playheadEnv2 = Env.new([0, 1, 1, 0], [0, duration2 - 0.01, 0.01], \lin);

					ramp1 = Phasor.ar(t_1, rate, start1, end1, resetPos: start1);
					ramp2 = Phasor.ar(t_2, rate, start2, end2, resetPos: start2);

					playhead1 = BufFrames.kr(bufnum) * ramp1;
					playhead2 = BufFrames.kr(bufnum) * ramp2;

					playback1 = BufRd.ar(
						numChannels: 1,
						bufnum: bufnum,
						phase: ramp1,
						loop: 0,
						interpolation: 4
					);
					playback2 = BufRd.ar(
						numChannels: 1,
						bufnum: bufnum,
						phase: ramp2,
						loop: 0,
						interpolation: 4
					);

					percEnv1 = EnvGen.ar(Env.perc(attack, decay, envLevel, curve), gate: t_1);
					percEnv2 = EnvGen.ar(Env.perc(attack, decay, envLevel, curve), gate: t_2);

					// If envelopes are disabled, the voice plays continuously with envLevel as optional amplitude modulator
					percEnv1 = Select.kr(enableEnv, [envLevel, percEnv1]);
					percEnv2 = Select.kr(enableEnv, [envLevel, percEnv2]);

					playback1 = playback1 * percEnv1 * EnvGen.ar(playheadEnv1, gate: t_1);
					playback1 = Select.ar(enableLpg, [playback1, SVF.ar(playback1, percEnv1 * freq, res, 1.0, 0.0, 0.0)]);

					playback2 = playback2 * percEnv2 * EnvGen.ar(playheadEnv2, gate: t_2);
					playback2 = Select.ar(enableLpg, [playback2, SVF.ar(playback2, percEnv2 * freq, res, 1.0, 0.0, 0.0)]);

					playback = XFade2.ar(playback1, playback2, crossfade);
					playback = Pan2.ar(playback, pan);

					amp = LagUD.ar(Peak.ar(Mix.ar(playback), Impulse.ar(60)), 0, 0.3);
					Out.kr(ampBus, amp);
					Out.kr(envBus, Select.kr(playheadId, [percEnv1, percEnv2]));

					// Second "VCA" is level
					Out.ar(out, playback * level);
				}).add;
			} // waitForBoot
		} //add
	} // initClass

	*new { // when this class is initialized...
		^super.new.init; // ...run the 'init' below.
	}
}