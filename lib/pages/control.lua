local ControlGraphic = include(from_root("lib/graphics/ControlGraphic"))
local page_name = "SEQUENCE CONTROL"
local MIN_BPM = 20 -- minimum for Ableton Link

local function adjust_bpm(d)
    params:set("clock_tempo", math.max(params:get('clock_tempo') + d, MIN_BPM))
end

clock.tempo_change_handler = function(bpm)
    -- sync echo
    recalculate_echo_time(bpm)
    -- save bpm to param for pset recalls; don't call action to prevent infinite loop
    params:set(ID_SEQ_BPM, bpm, true)
end

local function toggle_transport(v)
    page_sequencer:toggle_transport()
end

local function adjust_step_size()
    local p = ID_SEQ_SPEED
    local v = params:get(p)
    local new = util.wrap(v + 1, 1, #sequence_util.sequence_speeds)
    params:set(p, new)
end

local page = Page:create({
    name = page_name,
    e2 = adjust_bpm,
    k2_off = toggle_transport,
    k3_off = adjust_step_size,
    current_step = 1,
})

local function action_set_bpm(bpm)
    params:set("clock_tempo", bpm)
end


local function add_params()
    params:set_action(ID_SEQ_BPM, action_set_bpm)
end

function page:update_graphics_state()
    local tempo_trimmed = util.round(params:get("clock_tempo"))
    local is_playing = page_sequencer.seq.transport_on
    local loop_start = params:get(ID_SEQ_STEP_START)
    local loop_end = page_sequencer:get_loop_end()

    self.footer:set_value("e2", tempo_trimmed)
    self.footer:set_value("k2", is_playing and "ON" or "OFF")
    self.footer:set_value('k3', params:string(ID_SEQ_SPEED))
    self.graphic:set("loop_start", loop_start)
    self.graphic:set("loop_end", loop_end)
    self.graphic:set("bpm", tempo_trimmed)
    self.graphic:set("is_playing", is_playing)
    self.graphic:set("current_step", self.current_step)
    self.graphic:set("cue", page_sequencer.seq.cued_ticks_per_step)
end

function page:initialize()
    add_params()
    -- graphics
    self.graphic = ControlGraphic:new()
    page.footer = Footer:new({
        button_text = {
            k2 = { name = "PLAY", value = "" },
            k3 = { name = "DIV", value = "" },
            e2 = { name = "BPM", value = "" },
            e3 = { name = "", value = "" },
        },
        font_face = FOOTER_FONT,
    })
end

function page:enter()
    header.title = page_name
end

return page
