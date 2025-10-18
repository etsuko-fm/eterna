local ControlGraphic = include("symbiosis/lib/graphics/ControlGraphic")
local page_name = "SEQUENCE CONTROL"
local window
local control_graphic

local PARAM_ID_SEQUENCE_SPEED = "sequencer_speed"

local function adjust_bpm(d)
    params:set("clock_tempo", math.max(params:get('clock_tempo') + d, 15))
end

local function adjust_step_size(d)
    local p = PARAM_ID_SEQUENCE_SPEED
    local v = params:get(p)
    local new = util.clamp(v + d, 1, #sequence_util.sequence_speeds)
    params:set(p, new)
end

local page = Page:create({
    name = page_name,
    e2 = adjust_bpm,
    e3 = adjust_step_size,
    k2_off = function() page_sequencer:toggle_transport() end,
    k3_on = function() page_sequencer:toggle_hold_step() end,
})

local function action_sequence_speed(v)
    -- convert table index of human-readable options to value for clock.sync
    -- calls global function defined on sequencer page
    page_sequencer.cued_step_divider = sequence_util.convert_sequence_speed[v]
end

local function add_params()
    params:add_separator("SEQUENCE_CONTROL", page_name)
    params:add_option(PARAM_ID_SEQUENCE_SPEED, "sequence speed", sequence_util.sequence_speeds, sequence_util.default_speed_idx)
    params:set_action(PARAM_ID_SEQUENCE_SPEED, action_sequence_speed)
end

function page:render()
    window:render()
    local tempo_trimmed = misc_util.trim(tostring(clock.get_tempo()), 5)
    local is_playing = page_sequencer.transport_on
    page.footer.button_text.e2.value = tempo_trimmed
    page.footer.button_text.k2.value = is_playing and "ON" or "OFF"
    page.footer.button_text.k3.value = (page_sequencer.playback == "HOLD" or page.playback == "AWAIT_RESUME") and "ON" or "OFF"
    page.footer.button_text.e3.value = sequence_util.sequence_speeds[params:get(PARAM_ID_SEQUENCE_SPEED)]
    control_graphic.bpm = tempo_trimmed
    control_graphic.is_playing = is_playing
    control_graphic.current_step = page_sequencer.current_step
    -- quarters are always counted by substeps, even if a step is on hold
    control_graphic.current_quarter = page_sequencer.current_beat
    control_graphic.cue = page_sequencer.cued_step_divider
    control_graphic:render()
    -- screen.font_size(12 )
    -- screen.level(15)
    screen.move(16, 32) 
    screen.text_center(page_sequencer.current_substep)
    -- screen.move(16, 42) 
    -- screen.text_center(page_sequencer.current_master_step)
    -- screen.move(100, 32) 
    -- screen.text_center(control_graphic.current_quarter)

    page.footer:render()
end

function page:initialize()
    add_params()
    window = Window:new({ title = page_name, font_face = TITLE_FONT })
    -- graphics
    control_graphic = ControlGraphic:new()
    page.footer = Footer:new({
        button_text = {
            k2 = { name = "PLAY", value = "" },
            k3 = { name = "HOLD", value = "" },
            e2 = { name = "BPM", value = "" },
            e3 = { name = "STEP", value = "" },
        },
        font_face = FOOTER_FONT,
    })
end

return page
