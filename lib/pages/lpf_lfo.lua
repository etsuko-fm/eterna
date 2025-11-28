local create_filter_lfo_page = include(from_root("lib/pages/factories/filter_lfo"))

return create_filter_lfo_page({
    page_name           = "LOWPASS LFO",
    engine_freq         = engine_lib.get_id("lpf_freq"),
    engine_res          = engine_lib.get_id("lpf_res"),
    lfo_shapes          = LPF_LFO_SHAPES,
    spec_freq_mod       = controlspec_freq_mod,
    spec_lfo_range      = controlspec_lfo_range,

    id_lfo_enabled      = ID_LPF_LFO_ENABLED,
    id_lfo_shape        = ID_LPF_LFO_SHAPE,
    id_wet              = ID_LPF_WET,
    id_base_freq        = ID_LPF_BASE_FREQ,
    id_freq_mod         = ID_LPF_FREQ_MOD,
    id_lfo_rate         = ID_LPF_LFO_RATE,
    id_lfo_range        = ID_LPF_LFO_RANGE,

    freq_param_name     = "lpf_freq",
    range_param_name    = "lpf_res",
    filter_graphic_type = "LP",
})
