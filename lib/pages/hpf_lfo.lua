local create_filter_lfo_page = include(from_root("lib/pages/factories/filter_lfo"))

return create_filter_lfo_page({
    page_name           = "HIGHPASS LFO",
    engine_freq         = engine_lib.get_id("hpf_freq"),
    engine_res          = engine_lib.get_id("hpf_res"),
    lfo_shapes          = HPF_LFO_SHAPES,
    spec_freq_mod       = controlspec_hpf_freq_mod,
    spec_lfo_range      = controlspec_hpf_lfo_range,

    id_lfo_enabled      = ID_HPF_LFO_ENABLED,
    id_lfo_shape        = ID_HPF_LFO_SHAPE,
    id_wet              = ID_HPF_WET,
    id_base_freq        = ID_HPF_BASE_FREQ,
    id_freq_mod         = ID_HPF_FREQ_MOD,
    id_lfo_rate         = ID_HPF_LFO_RATE,
    id_lfo_range        = ID_HPF_LFO_RANGE,

    freq_param_name     = "hpf_freq",
    range_param_name    = "hpf_res",
    filter_graphic_type = "HP",
})
