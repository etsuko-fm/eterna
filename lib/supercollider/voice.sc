Voice {
	var <params;
	*initClass {
		StartUp.add {
			var s = Server.default;
			s.waitForBoot {
				SynthDef("SampleVoice", {
					arg out, 
					rate = 0, // playback rate
					bufnum=0, // buffer assigned to voice
					loop=1,  // 0 for one-shot, 1 for looping playback
					loop_start=0.0, loop_end=0.0, // start/end pos in seconds
					t_trig=1, // if 1, triggers the voice; it will then be reset back to zero because it starts with t_. Defaults to 1, because assumed voice is created only when it should be triggered
					attack=0.01, decay=1.0, curve=(-4), env_level=1.0, // envelope
					enable_env=1, enable_lpg=0, 
					pan=0.0, // panning (-1 to 1)
					lpg_freq=20000, res=0.0,  // filter frequency and resonance, if LPG is enabled
					ampBus, envBus, // index of control buses that report amp and env levels
					level=1.0; // final output level 
					 
					// we toggle internally between two voices to prevent clicking; this is xfade time between them
					var xfadeTime = 0.05;

					 // Playback start pos in samples
					var start = loop_start  * BufSampleRate.ir(bufnum); 

					// Playback end pos in samples; if loop_end is set, use it; otherwise use entire buffer
					var end = Select.kr(
						loop_end > 0,
						[
							BufFrames.kr(bufnum),
							loop_end * BufSampleRate.ir(bufnum)
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
					var start1 = Latch.kr(start, t_1); // start/end are in samples
					var start2 = Latch.kr(start, t_2);
					var end1 = Latch.kr(end, t_1);
					var end2 = Latch.kr(end, t_2);

 					// Duration of selected section of buffer, in seconds
					var duration1 = (end1 - start1).abs / BufSampleRate.ir(bufnum) / rate.abs;
					var duration2 = (end2 - start2).abs / BufSampleRate.ir(bufnum) / rate.abs;

					// This is a fully open envelope for the duration of the section, 
					// only useful when the AR envelope is disabled
					var openEnv1 = Env.new([0, 1, 1, 0], [0, duration1 - 0.01, 0.01], \lin);
					var openEnv2 = Env.new([0, 1, 1, 0], [0, duration2 - 0.01, 0.01], \lin);

					// Ramps for buffer playback; from start pos to end pos in samples.
					var ramp1 = Phasor.ar(t_1, rate, start1, end1, resetPos: start1);
					var ramp2 = Phasor.ar(t_2, rate, start2, end2, resetPos: start2);
					
					// `crossfade` is used to fade between internal voice 1 and 2.
					// The value should be between -1 and 1 (voice 1 -> voice 2); intVoiceId is 0 or 1; 
					// So we can use Lag.ar() and some simple math to smoothly fade to the active voice
					var crossfade = -1 + Lag.ar(K2A.ar(intVoiceId*2), xfadeTime);

					// BufReads of each internal voice
					var playback1 = BufRd.ar(
						numChannels: 1,
						bufnum: bufnum,
						phase: ramp1,
						loop: loop,
						interpolation: 2
					);
					var playback2 = BufRd.ar(
						numChannels: 1,
						bufnum: bufnum,
						phase: ramp2,
						loop: loop,
						interpolation: 2
					);

					// AR env according to env settings
					// The extra 0 stage is so that a retrigger restarts the env at 0
					var percEnv1 = EnvGen.ar(Env.new([0, 0, env_level, 0], [0, attack, decay], curve), gate: t_1);
					var percEnv2 = EnvGen.ar(Env.new([0, 0, env_level, 0], [0, attack, decay], curve), gate: t_2);

					// Assign active envelope, so we can check if the playback is done
					var percEnv = Select.kr(intVoiceId, [percEnv1, percEnv2]);
					var done1 = Done.kr(percEnv1);
					var done2 = Done.kr(percEnv2);
					var isDone = Select.kr(intVoiceId, [done1, done2]);
					var delayedDone = DelayN.kr(isDone, 1, 1);

					var amp; // for reporting amplitude

					// Free synth when playback done
					FreeSelf.kr(delayedDone);

					// If envelopes are disabled, the voice plays continuously with env_level as optional amplitude modulator
					percEnv1 = Select.kr(enable_env, [env_level, percEnv1]);
					percEnv2 = Select.kr(enable_env, [env_level, percEnv2]);

					playback1 = playback1 * percEnv1 * EnvGen.ar(openEnv1, gate: t_1);
					playback1 = Select.ar(enable_lpg, [playback1, SVF.ar(playback1, percEnv1 * lpg_freq, res, 1.0, 0.0, 0.0)]);

					playback2 = playback2 * percEnv2 * EnvGen.ar(openEnv2, gate: t_2);
					playback2 = Select.ar(enable_lpg, [playback2, SVF.ar(playback2, percEnv2 * lpg_freq, res, 1.0, 0.0, 0.0)]);

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
					// Out.ar(out, playback * level * (1-isDone));
					Out.ar(out, playback * level);
				}).add;
			}
		}
	}
}