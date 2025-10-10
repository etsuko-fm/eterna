Voice {
	var <params;
	*initClass {
		StartUp.add {
			var s = Server.default;
			s.waitForBoot {
				SynthDef("SampleVoice", {
					// loopStart and loopEnd in seconds
					// 't_' has a special meaning in SC, resets value to zero after receiving a 1
					arg out, 
					rate = 0, // playback rate
					bufnum=0, // buffer assigned to voice
					loop=0.0,  // ?
					loopStart=0.0, loopEnd=0.0, // start/end pos in seconds
					t_trig=0, // if 1, triggers the voice; it will then be reset back to zero because it starts with t_
					attack=0.01, decay=1.0, curve=(-4), envLevel=1.0, // envelope
					enableEnv=1, enableLpg=0, 
					pan=0.0, // panning (-1 to 1)
					freq=20000, res=0.0,  // filter frequency and resonance, if LPG is enabled
					 // this SynthDef toggles internally between two voices to prevent clicking; this is xfade time between them
					xfade=0.05,
					ampBus, envBus, // index of control buses that report amp and env levels
					level=1.0; // final output level 
					 
					 // Playback start pos in samples
					var start = loopStart  * BufSampleRate.ir(bufnum); 
					
					// Playback end pos in samples; if loopEnd is set, use it; otherwise use entire buffer
					var end = Select.kr(
						loopEnd > 0,
						[
							BufFrames.kr(bufnum),
							loopEnd * BufSampleRate.ir(bufnum)
						]
					);
					var playback; // xfaded voice (between playback1 and playback2)

					var intVoiceId = ToggleFF.kr(t_trig); // toggles each time voice is triggered
					
					// Split the incoming trigger into separate triggers for internal voice 1 and 2
					var t_1 = Select.kr(intVoiceId, [t_trig, 0]);
					var t_2 = Select.kr(intVoiceId, [0, t_trig]);

					/* 
					 When the voice is triggered, we need to capture the configured 
					 start and end position of that moment, so a ramp can be constructed for playback. 
					*/
					var start1 = Latch.kr(start, intVoiceId); // in samples
					var start2 = Latch.kr(start, 1-intVoiceId);
					var end1 = Latch.kr(end, intVoiceId);
					var end2 = Latch.kr(end, 1-intVoiceId);

					var amp; // for reporting amplitude

 					// Duration of selected section of buffer, in seconds
					var duration1 = (end1 - start1).abs / BufSampleRate.ir(bufnum) / rate.abs;
					var duration2 = (end2 - start2).abs / BufSampleRate.ir(bufnum) / rate.abs;

					// This is a fully open envelope for the duration of the section, 
					// only useful when the AD envelope is disabled
					var playheadEnv1 = Env.new([0, 1, 1, 0], [0, duration1 - 0.01, 0.01], \lin);
					var playheadEnv2 = Env.new([0, 1, 1, 0], [0, duration2 - 0.01, 0.01], \lin);

					// Ramps for buffer playback
					var ramp1 = Phasor.ar(t_1, rate, start1, end1, resetPos: start1);
					var ramp2 = Phasor.ar(t_2, rate, start2, end2, resetPos: start2);
					
					// Playhead of each internal voice
					var playhead1 = BufFrames.kr(bufnum) * ramp1;
					var playhead2 = BufFrames.kr(bufnum) * ramp2;

					// `crossfade` is used to fade between internal voice 1 and 2.
					// The value should be between -1 and 1 (voice 1 -> voice 2); intVoiceId is 0 or 1; 
					// So we can use Lag.ar() and some simple math to smoothly fade to the active voice
					var crossfade = -1 + Lag.ar(K2A.ar(intVoiceId*2), xfade);

					// BufReads of each internal voice
					var playback1 = BufRd.ar(
						numChannels: 1,
						bufnum: bufnum,
						phase: ramp1,
						loop: 0,
						interpolation: 4
					);
					var playback2 = BufRd.ar(
						numChannels: 1,
						bufnum: bufnum,
						phase: ramp2,
						loop: 0,
						interpolation: 4
					);
					
					var percEnv1 = EnvGen.ar(Env.new([0, 0, envLevel, 0], [0, attack, decay], curve), gate: t_1);
					var percEnv2 = EnvGen.ar(Env.new([0, 0, envLevel, 0], [0, attack, decay], curve), gate: t_2);

					// If envelopes are disabled, the voice plays continuously with envLevel as optional amplitude modulator
					percEnv1 = Select.kr(enableEnv, [envLevel, percEnv1]);
					percEnv2 = Select.kr(enableEnv, [envLevel, percEnv2]);

					playback1 = playback1 * percEnv1 * EnvGen.ar(playheadEnv1, gate: t_1);
					playback1 = Select.ar(enableLpg, [playback1, SVF.ar(playback1, percEnv1 * freq, res, 1.0, 0.0, 0.0)]);

					playback2 = playback2 * percEnv2 * EnvGen.ar(playheadEnv2, gate: t_2);
					playback2 = Select.ar(enableLpg, [playback2, SVF.ar(playback2, percEnv2 * freq, res, 1.0, 0.0, 0.0)]);

					playback = XFade2.ar(playback1, playback2, crossfade);
					playback = Pan2.ar(playback, pan);
					
					// Tweak spectrum due to all the digital processing
					playback = HPF.ar(playback, 30);
					playback = LPF.ar(playback, 10000); // Harshness
					playback = BPeakEQ.ar(playback, 3500, 1.0, -2.0); // Presence
					playback = BPeakEQ.ar(playback, 250, 1.0, 1.5); // Warmth

					amp =  Amplitude.ar(Mix.ar(playback), 0, 0.2);
					Out.kr(ampBus, amp);
					Out.kr(envBus, Select.kr(intVoiceId, [percEnv1, percEnv2]));

					// Second "VCA" is level
					Out.ar(out, playback * level);
				}).add;
			}
		}
	}
}