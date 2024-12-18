local debug = include("bits/lib/util/debug")

function get_duration(file)
    local ch, samples, samplerate = audio.file_info(file)
    local duration = samples / samplerate
    return duration
end

function num_channels(file)
    local ch, samples, samplerate
    if util.file_exists(file) == true then
        ch, samples, samplerate = audio.file_info(file)
    end
    return ch
end

function load_sample(file, mono)
    -- simplified method for loading a sample, for when a single audio file in the softcut buffer is sufficient
    -- stereo mode yet untested
    debug.print_info(file)
    softcut.buffer_clear()
    sample_length = audio_util.get_duration(file)
    start_src = 0 -- file read position
    start_dst = 0 -- buffer write position

    if mono or (audio_util.num_channels(file) == 1) then
        softcut.buffer_read_mono(file, start_src, start_dst, sample_length, 1, 1)
    else
        softcut.buffer_read_stereo(file, start_src, start_dst, sample_length)
    end
end

audio_util = {
    get_duration = get_duration,
    num_channels = num_channels,
    load_sample = load_sample,
}

return audio_util
