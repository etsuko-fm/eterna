local create_filter_lfo_page = include(from_root("lib/pages/factories/filter_lfo"))

return create_filter_lfo_page({
    page_name           = "HIGHPASS LFO",
    engine_freq         = engine_lib.get_id("hpf_freq"),
    engine_res          = engine_lib.get_id("hpf_res"),
    parent_page         = page_hpf,
    lfo_shapes          = HPF_LFO_SHAPES,
    spec_freq_mod       = controlspec_hpf_freq_mod,
    spec_lfo_range      = controlspec_hpf_lfo_range,

    id_lfo              = ID_HPF_LFO,
    id_lfo_shape        = ID_HPF_LFO_SHAPE,
    id_wet              = ID_HPF_WET,
    id_base_freq        = ID_HPF_BASE_FREQ,
    id_freq_mod         = ID_HPF_FREQ_MOD,
    id_lfo_rate         = ID_HPF_LFO_RATE,
    id_lfo_range        = ID_HPF_LFO_RANGE,

    freq_param_name     = "hpf_freq",
    range_param_name    = "hpf_res",
    filter_graphic_type = "HP",


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
                params:set(ID_HPF_FREQ_MOD, controlspec_hpf_freq_mod:map(scaled), false)
            end
        }
    end
})
