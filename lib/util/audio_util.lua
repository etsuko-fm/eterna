local debug = include(from_root("lib/util/debug"))

function get_duration(file)
    local ch, samples, samplerate = audio.file_info(file)
    local duration = samples / samplerate -- seconds, e.g 44100 / 44100 = 1 sec
    return duration
end

function num_channels(file)
    local ch, samples, samplerate
    if util.file_exists(file) == true then
        ch, samples, samplerate = audio.file_info(file)
    end
    return ch
end

audio_util = {
    get_duration = get_duration,
    num_channels = num_channels,
}

return audio_util
