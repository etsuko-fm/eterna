local create_filter_lfo_page = include(from_root("lib/pages/factories/filter_lfo"))

return create_filter_lfo_page({
    page_name        = "LOWPASS LFO",
    engine_freq      = engine_lib.get_id("lpf_freq"),
    parent_page      = page_lpf,
    lfo_shapes       = LPF_LFO_SHAPES,
    spec_freq_mod    = controlspec_lpf_freq_mod,
    spec_lfo_range   = controlspec_lpf_lfo_range,

    id_lfo           = ID_LPF_LFO,
    id_lfo_shape     = ID_LPF_LFO_SHAPE,
    id_wet           = ID_LPF_WET,
    id_base_freq     = ID_LPF_BASE_FREQ,
    id_freq_mod      = ID_LPF_FREQ_MOD,
    id_lfo_rate      = ID_LPF_LFO_RATE,
    id_lfo_range     = ID_LPF_LFO_RANGE,

    freq_param_name  = "lpf_freq",
    range_param_name = "lpf_res",


    lfo_defaults = function(last_freq)
        return {
            shape = 'sine',
            min = 0,
            max = 1,
            depth = 1,
            mode = 'clocked',
            period = 8,
            phase = 0,
            action = function(scaled)
                -- map the lfo value to the range of the controlspec
                params:set(ID_LPF_FREQ_MOD, controlspec_lpf_freq_mod:map(scaled), false)
            end
        }
    end
})
