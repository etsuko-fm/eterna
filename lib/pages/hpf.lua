local create_filter_page = include(from_root("lib/pages/factories/filter"))

return create_filter_page({
    page_name           = "HIGHPASS",
    engine_freq         = engine_lib.get_id("hpf_freq"),
    engine_res          = engine_lib.get_id("hpf_res"),
    engine_dry          = engine_lib.get_id("hpf_dry"),

    id_lfo_enabled      = ID_HPF_LFO_ENABLED,
    id_lfo_shape        = ID_HPF_LFO_SHAPE,
    id_wet              = ID_HPF_WET,
    id_base_freq        = ID_HPF_BASE_FREQ,
    id_freq_mod         = ID_HPF_FREQ_MOD,
    id_lfo_rate         = ID_HPF_LFO_RATE,
    id_lfo_range        = ID_HPF_LFO_RANGE,
    id_ctrl_mode        = ID_HPF_CTRL_MODE,

    freq_param_name     = "hpf_freq",
    res_param_name      = "hpf_res",
    spec_freq_mod       = controlspec_freq_mod,
    spec_lfo_range      = controlspec_lfo_range,

    lfo_shapes          = HPF_LFO_SHAPES,
    filter_graphic_type = "HP",
})
