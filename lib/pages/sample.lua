local SampleGraphic = include(from_root("lib/graphics/SampleGraphic"))

local page_name = "SAMPLE"
local fileselect = require('fileselect')
local page_disabled = false
local preload_sample = nil --"audio/etsuko/chris/play-safe.wav"

local filename = ""

-- In rare cases sample loading may fail, these are for a retry mechanism
local MAX_RETRIES = 1
local retries = {}

-- State of loading file, per channel of file
local ready = {}

local active_channels = 1

local page = Page:create({
    name = page_name,
    --
    sample_duration = nil,
})

local function path_to_file_name(file_path)
    -- strips '/foo/bar/audio.wav' to 'audio.wav'
    local split_at = string.match(file_path, "^.*()/")
    return string.sub(file_path, split_at + 1)
end

local function remove_extension(filename)
    return filename:match("^(.*)%.[^%.]+$") or filename
end

local function to_sample_name(path)
    local s = string.upper(remove_extension(path_to_file_name(path)))
    return s:sub(1,11)
end

local function all_true(t)
    for _, v in pairs(t) do
        if not v then
            return false
        end
    end
    return true
end

local function encoder_drive(d)
    misc_util.adjust_param(d, ID_SAMPLER_DRIVE, controlspec_sample_drive.quantum)
end


function page:load_sample(file)
    -- use specified `file` as a sample and store enabled length of buffer in state
    if not file or file == "-" then return end
    local num_channels = audio_util.num_channels(file)
    ready = {}
    -- hard to reproduce, but a hypothesis is that
    -- this flush might sometimes prevent supercollider from failing to load a sample
    engine_lib.flush()
    retries = {}
    window.title = "LOADING..."
    self.sample_duration_txt = nil
    for _, p in ipairs({page, page_slice}) do
        -- reset waveforms in both pages
        for channel=1, 6 do
            p.graphic.waveform_graphics[channel].samples = {}
        end
    end

    for channel = 1, math.min(num_channels, 6) do
        -- load file to buffer corresponding to channel
        ready[channel] = false
        local buffer = channel
        if engine_lib.load_file(file, channel, buffer) then
            active_channels = num_channels
            self.graphic.num_channels = num_channels
            page_slice.graphic.num_channels = num_channels
        end
    end
end

-- function engine_lib.on_normalize(buffer)
--     print("buffer " .. buffer .. " normalized")
--     engine_lib.get_waveform(buffer, 64)
-- end

function engine_lib.on_duration(duration)
    page:set_sample_duration(duration)
end

function engine_lib.on_waveform(waveform, channel)
    print("Lua: /waveform received from SC")
    page.graphic.waveform_graphics[channel].samples = waveform
    page_slice.graphic.waveform_graphics[channel].samples = waveform
end

function engine_lib.on_file_load_success(path, channel, buffer)
    print('successfully loaded channel ' .. channel .. " of " .. path .. " to buffer " .. buffer)
    ready[channel] = true
    -- engine_lib.normalize(buffer)

    -- see engine_lib.on_waveform for what happens next
    engine_lib.get_waveform(buffer, 64)

    if all_true(ready) then
        for voice = 1, 6 do
            local buffer_idx = util.wrap(voice, 1, active_channels)
            params:set(engine_lib.get_id("voice_bufnum", voice), buffer_idx)
            page.graphic.voice_to_buffer[voice] = buffer_idx
            page_slice.graphic.voice_to_buffer[voice] = buffer_idx
            print("lua: voice " .. voice .. " set to buffer " .. buffer_idx)
        end
    end
end

function engine_lib.on_file_load_fail(path, channel, buffer)
    if retries[channel] == nil then
        retries[channel] = 0
    end
    if retries[channel] < MAX_RETRIES then
        -- try once more
        print("retry #" .. retries[channel])
        engine_lib.load_file(path, channel, buffer)
        retries[channel] = retries[channel] + 1
    else
        print('failed to load channel ' .. channel .. "of " .. path .. " to buffer " .. buffer)
    end
    -- deselect sample? retry?
end

local function select_sample()
    local function callback(file_path)
        if file_path ~= 'cancel' then
            print("setting path to " .. file_path)
            params:set(ID_SAMPLER_AUDIO_FILE, file_path)
        end
        page_disabled = false -- proceed with rendering page instead of file menu
        window.page_indicator_disabled = false
    end
    fileselect.enter(_path.audio, callback, "audio")
    page_disabled = true           -- don't render current page
    window.page_indicator_disabled = true -- hide page indicator
end
local function s_to_minsec(s)
    local minutes = math.floor(s / 60)
    local seconds = math.floor(s % 60)
    return string.format("%d'%02d", minutes, seconds)
end



function page:render()
    if page_disabled then
        fileselect:redraw()
        return
    end -- for rendering the fileselect interface
    if params:get(ID_SAMPLER_AUDIO_FILE) ~= "-" then
        -- show filename of selected sample in title bar
        if self.sample_duration_txt then
            window.title = filename .. " (" .. self.sample_duration_txt .. ")"
        end
        self.graphic.sample_duration = self.sample_duration
        self.graphic:render(false, true)
    else
        screen.level(3)
        screen.font_face(DEFAULT_FONT)
        screen.move(64, 32)
        screen.text_center("PRESS K2 TO LOAD SAMPLE")
    end
    page.footer.button_text.e2.value = params:get(ID_SAMPLER_DRIVE)

    window:render()
    page.footer:render()
end

function page:add_params()
    -- file selection
    params:set_action(ID_SAMPLER_AUDIO_FILE,
        function(file)
            if file ~= "-" then
                filename = to_sample_name(file)
                self:load_sample(file)
            end
        end
    )
    params:set_action(ID_SAMPLER_DRIVE, engine_lib.each_voice_drive)
end

function page:set_sample_duration(v)
    print('Sample duration: ' .. v)
    self.sample_duration = v
    self.sample_duration_txt = s_to_minsec(v)
    page_slice.sample_duration = v
    page_slice:update_loop_ranges()
end

function page:initialize()
    self.graphic = SampleGraphic:new()
    self.k2_off = select_sample
    self.e2 = encoder_drive

    self:add_params()
    local selected_sample = params:get(ID_SAMPLER_AUDIO_FILE)
    if selected_sample ~= nil and selected_sample ~= "-" then
        filename = to_sample_name(params:get(ID_SAMPLER_AUDIO_FILE))
        print("initialize, file load")
    end
    if preload_sample then
        -- silent set, main module invokes params:bang() after initialization
        params:set(ID_SAMPLER_AUDIO_FILE, _path.dust .. preload_sample, true)
    end


    page.footer = Footer:new({
        button_text = {
            k2 = { name = "LOAD", value = "" },
            k3 = { name = "", value = "" },
            e2 = { name = "DRIVE", value = "" },
            e3 = { name = "", value = "" },
        },
        font_face = FOOTER_FONT,
    })
end
function page:enter()
    window.title = "SAMPLING"
end


return page
