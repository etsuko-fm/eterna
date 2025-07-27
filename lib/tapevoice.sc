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
					 t_trig=0, attack=0.01, decay=1.0, pan=0.0, level=1.0, envLevel=1.0, freq=400.0,
					 res=0.2, xfade=0.05, curve=(-4), enableEnv=1;
					var start, end, playhead1, playhead2, playback, playback1, playback2, startA, startB, endA, endB;
					var playheadId = ToggleFF.kr(t_trig); // toggles each time voice is triggered

					// crossfade value between -1 and 1; pleayheadId is 0 or 1, so subtract 1, multiply by 2 to get a value in correct range
					var crossfade = -1 + Lag.ar(K2A.ar(playheadId*2), xfade);
					var t_1 = Select.kr(playheadId, [t_trig, 0]);
					var t_2 = Select.kr(playheadId, [0, t_trig]);
					var percEnv1, percEnv2, duration, ramp, position, ramp1, ramp2, playheadEnv;

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
					startA = Latch.kr(start, playheadId);
					startB = Latch.kr(start, 1-playheadId);
					endA = Latch.kr(end, playheadId);
					endB = Latch.kr(end, 1-playheadId);

 					//duration of enabled section, in seconds
					duration = (end - start).abs / BufSampleRate.ir(bufnum) / rate.abs;

					playheadEnv = Env.new([0, 1, 1, 0], [0.001, duration - 0.001, 0], \lin);

					ramp1 = Phasor.ar(t_1, rate, startA, endA, resetPos: startA);
					ramp2 = Phasor.ar(t_2, rate, startB, endB, resetPos: startB);

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

					percEnv1 = EnvGen.ar(Env.perc(attack, decay, envLevel, curve), gate: t_1, doneAction: 0);
					percEnv2 = EnvGen.ar(Env.perc(attack, decay, envLevel, curve), gate: t_2, doneAction: 0);

					// If envelopes are disabled, the voice plays continuously with envLevel as optional amplitude modulator
					percEnv1 = Select.kr(enableEnv, [envLevel, percEnv1]);
					percEnv2 = Select.kr(enableEnv, [envLevel, percEnv2]);

					playback1 = playback1 * percEnv1 * EnvGen.ar(playheadEnv, gate: t_1, doneAction: 0);
					// playback1 = SVF.ar(playback1, percEnv1 * Lag.kr(freq), Lag.kr(res), 1.0, 0.0, 0.0);

					playback2 = playback2 * percEnv2 * EnvGen.ar(playheadEnv, gate: t_2, doneAction: 0);
					// playback2 = SVF.ar(playback2, percEnv2 * Lag.kr(freq), Lag.kr(res), 1.0, 0.0, 0.0);

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
}