local create_filter_page = include(from_root("lib/pages/factories/filter"))

return create_filter_page({
    page_name           = "HIGHPASS",
    engine_freq         = engine_lib.get_id("hpf_freq"),
    engine_res          = engine_lib.get_id("hpf_res"),
    engine_dry          = engine_lib.get_id("hpf_dry"),

    id_lfo              = ID_HPF_LFO,
    id_wet              = ID_HPF_WET,
    id_base_freq        = ID_HPF_BASE_FREQ,
    id_freq_mod         = ID_HPF_FREQ_MOD,
    id_lfo_rate         = ID_HPF_LFO_RATE,

    freq_param_name     = "hpf_freq",
    res_param_name      = "hpf_res",

    lfo_shapes          = HPF_LFO_SHAPES,
    filter_graphic_type = "HP",

    lfo_defaults        = function(last_freq)
        return {
            shape = 'sine',
            min = 0,
            max = 1,
            depth = 1,
            mode = 'clocked',
            period = 8,
            phase = 0,
            action = function(scaled, raw)
                params:set(ID_HPF_FREQ_MOD, controlspec_hpf_freq_mod:map(scaled), false)
            end
        }
    end
})
