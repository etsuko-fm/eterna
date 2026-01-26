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

local function toggle_source(v)
    misc_util.cycle_param(ID_SEQ_SOURCE, SEQUENCER_SOURCES, 1)
end

local function adjust_num_steps(d)
    misc_util.adjust_param(d, ID_SEQ_NUM_STEPS, controlspec_num_steps.quantum)
end

local page = Page:create({
    name = page_name,
    e2 = adjust_bpm,
    e3 = adjust_num_steps,
    k2_off = toggle_transport,
    k3_off = toggle_source,
    current_step = 0,
})

local function action_num_steps(v)
    page_sequencer.seq.steps = v
end

local function action_set_bpm(bpm)
    params:set("clock_tempo", bpm)
end

local function action_source(v)
    -- clear sequence graphic from Grid and graphic when switching source
    page_sequencer.graphic:clear()
    grid_conn:reset_sequence_leds()
    local new_source = SEQUENCER_SOURCES[v]
    page_sequencer.source = new_source
    if new_source == SOURCE_PERLIN then
        -- re-render perlin sequence
        page_sequencer:toggle_redraw()
    else
        -- switch back to last saved user sequence
    end
end

local function add_params()
    params:set_action(ID_SEQ_NUM_STEPS, action_num_steps)
    params:set_action(ID_SEQ_BPM, action_set_bpm)
    -- todo
    params:set_action(ID_SEQ_SOURCE, action_source)
end

function page:update_graphics_state()
    local tempo_trimmed = util.round(params:get("clock_tempo"))
    local is_playing = page_sequencer.seq.transport_on
    local source = params:get(ID_SEQ_SOURCE)
    self.footer:set_value("e2", tempo_trimmed)
    self.footer:set_value("e3", page_sequencer.seq.steps)
    self.footer:set_value("k2", is_playing and "ON" or "OFF")
    self.footer:set_value("k3", SEQUENCER_SOURCES[source])
    self.graphic:set("num_steps", page_sequencer.seq.steps)
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
            k3 = { name = "SRC", value = "" },
            e2 = { name = "BPM", value = "" },
            e3 = { name = "STEPS", value = "" },
        },
        font_face = FOOTER_FONT,
    })
end

function page:enter()
    header.title = page_name
end

return page
