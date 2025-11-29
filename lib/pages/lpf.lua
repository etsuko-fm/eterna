local create_filter_page = include(from_root("lib/pages/factories/filter"))

return create_filter_page({
    page_name           = "LOWPASS",
    engine_freq         = engine_lib.get_id("lpf_freq"),
    engine_res          = engine_lib.get_id("lpf_res"),
    engine_dry          = engine_lib.get_id("lpf_dry"),

    id_lfo_enabled      = ID_LPF_LFO_ENABLED,
    id_wet              = ID_LPF_WET,
    id_base_freq        = ID_LPF_BASE_FREQ,
    id_freq_mod         = ID_LPF_FREQ_MOD,
    id_lfo_rate         = ID_LPF_LFO_RATE,
    id_lfo_range        = ID_LPF_LFO_RANGE,

    freq_param_name     = "lpf_freq",
    res_param_name      = "lpf_res",

    lfo_shapes          = LPF_LFO_SHAPES,
    filter_graphic_type = "LP",
})
