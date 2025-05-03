// a few aul sines
// https://github.com/catfact/zebra/blob/master/lib/Engine_Zsins.sc
// thank you zebra

Engine_Sines : CroneEngine {
  classvar num;
  var <synth, <bus, <output_stage;

  *initClass {  num = 16; }

  *new { arg context, doneCallback;
    ^super.new(context, doneCallback);
  }

  alloc {
    var server = Crone.server;
    var def = SynthDef.new(\sin, {
      arg out, vol=0.0, hz=220, hz_lag=0.005, env_bias=0.0,
      amp_atk=0.001, amp_rel=0.05, amp_slew=0.01, env_delay=0.0,
      env_delay_rand=0.0, pan=0.0, pan_lag=0.005, mul=1, modPartial=1, carPartial=1,
      fm_index=1.0, sample_rate=48000, bit_depth=24;
      var mod, car, car_decimate, amp_, hz_, pan_, vol_;

      //amp_ = EnvGen.ar(Env.circle([0, 1, 0, 0], [amp_atk, amp_rel, env_delay + env_delay_rand]), levelBias: env_bias);
      amp_ = EnvGen.ar(Env.asr(amp_atk, 1.0, amp_rel, -4.0), levelBias: env_bias);

      hz_ = Lag.ar(K2A.ar(hz), hz_lag);
      pan_ = Lag.ar(K2A.ar(pan), pan_lag);
      vol_ = Lag.ar(K2A.ar(vol), amp_slew);

      mod = SinOsc.ar(hz_ * modPartial, 0, hz_ * fm_index * LFNoise1.kr(5.reciprocal).abs);
      car = SinOsc.ar(hz_ * carPartial + mod, 0, mul);
      car_decimate = Decimator.ar(car, sample_rate, bit_depth, 1.0, 0);

      Out.ar(out, Pan2.ar(car_decimate * amp_ * vol_, pan_));
    });

    SynthDef.new(\sines_output, {|in, out|
        var sig = In.ar(in, 2);
        sig = Limiter.ar(sig, 1.0, 0.01); // Apply Limiter.ar to prevent clipping
        Out.ar(out, sig);
    }).add;

    def.send(server);
    bus = Bus.audio(server, 2);
    server.sync;
    synth = Array.fill(num, { Synth.new(\sin, [\out, bus], target: context.xg) });
    #[\hz, \vol, \env_bias, \pan, \amp_atk, \amp_rel, \env_delay, \env_delay_rand, \amp_slew, \hz_lag, \pan_lag, \fm_index].do({
      arg name;
      this.addCommand(name, "if", {
        arg msg;
        var i = msg[1];
        synth[i].set(name, msg[2]);
      });
    });

    server.sync;
    output_stage = Synth.new(\sines_output, [\out, context.out_b, \in, bus], addAction: \addToTail);
    server.sync;

    #[\sample_rate, \bit_depth].do({
      arg name;
      this.addCommand(name, "ii", {
        arg msg;
        var i = msg[1];
        synth[i].set(name, msg[2]);
      });
    });

  }

  free {
    synth.do({ |syn| syn.free; });
    output_stage.free;
    bus.free;
  }
}