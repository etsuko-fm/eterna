local ControlGraphic = include("symbiosis/lib/graphics/ControlGraphic")
local page_name = "SEQUENCE CONTROL"

local function adjust_bpm(d)
    params:set("clock_tempo", math.max(params:get('clock_tempo') + d, 15))
end

local function adjust_step_size(d)
    local p = ID_SEQUENCE_SPEED
    local v = params:get(p)
    local new = util.clamp(v + d, 1, #sequence_util.sequence_speeds)
    params:set(p, new)
end

local function toggle_transport(v)
    page_sequencer:toggle_transport()
end

local page = Page:create({
    name = page_name,
    e2 = adjust_bpm,
    e3 = adjust_step_size,
    k2_off = toggle_transport,
    k3_on = function() page_sequencer:toggle_hold_step() end,
})

local function action_sequence_speed(v)
    -- convert table index of human-readable options to value for clock.sync
    -- calls global function defined on sequencer page
    page_sequencer.seq.cued_step_divider = sequence_util.convert_sequence_speed[v]
    print("sequence speed action, setting cued_step_divider to " .. sequence_util.convert_sequence_speed[v])
end

local function add_params()
    params:add_separator("SEQUENCE_CONTROL", page_name)
    params:set_action(ID_SEQUENCE_SPEED, action_sequence_speed)
end

function page:render()
    self.window:render()
    local tempo_trimmed = util.round(clock.get_tempo())
    local is_playing = page_sequencer.transport_on
    self.footer.button_text.e2.value = tempo_trimmed
    self.footer.button_text.k2.value = is_playing and "ON" or "OFF"
    local hold_text
    local s = page_sequencer.hold_status
    if s == "HOLD" or s == "AWAIT_RESUME" then hold_text = "ON"
    else hold_text = "OFF"
    end

    self.footer.button_text.k3.value = hold_text
    self.footer.button_text.e3.value = sequence_util.sequence_speeds[params:get(ID_SEQUENCE_SPEED)]
    self.graphic.bpm = tempo_trimmed
    self.graphic.is_playing = is_playing
    -- quarters are always counted by substeps, even if a step is on hold
    self.graphic.current_beat = self.current_beat
    self.graphic.current_step = self.current_step
    self.graphic.cue = page_sequencer.seq.cued_step_divider
    self.graphic:render()
    self.footer:render()
end

function page:initialize()
    add_params()
    self.window = Window:new({ title = page_name, font_face = TITLE_FONT })
    -- graphics
    self.graphic = ControlGraphic:new()
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
