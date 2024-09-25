function get_duration(file)
    local ch, samples, samplerate = audio.file_info(file)
    local duration = samples/samplerate
    return duration
end

bits_sampler = {
    get_duration=get_duration
}
return bits_sampler