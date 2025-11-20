local ControlGraphic = include("mist-system/lib/graphics/ControlGraphic")
local page_name = "SEQUENCE CONTROL"
local MIN_BPM = 20 -- minimum for Ableton Link
local function adjust_bpm(d)
    params:set("clock_tempo", math.max(params:get('clock_tempo') + d, MIN_BPM))
end


local function toggle_transport(v)
    page_sequencer:toggle_transport()
end

local function adjust_num_steps(d)
    misc_util.adjust_param(d, ID_SEQ_NUM_STEPS, controlspec_num_steps.quantum)
end

local page = Page:create({
    name = page_name,
    e2 = adjust_bpm,
    e3 = adjust_num_steps,
    k2_off = toggle_transport,
    k3_on = function() page_sequencer:toggle_hold_step() end,
})

local function action_num_steps(v)
    page_sequencer.seq.steps = v
end

local function add_params()
    params:set_action(ID_SEQ_NUM_STEPS, action_num_steps)
end

function page:render()
    self.window:render()
    local tempo_trimmed = util.round(params:get("clock_tempo"))
    local is_playing = page_sequencer.seq.transport_on
    self.footer.button_text.e2.value = tempo_trimmed
    self.footer.button_text.e3.value = page_sequencer.seq.steps
    self.footer.button_text.k2.value = is_playing and "ON" or "OFF"
    self.graphic.num_steps = page_sequencer.seq.steps
    self.graphic.bpm = tempo_trimmed
    self.graphic.is_playing = is_playing
    self.graphic.current_beat = self.current_beat
    self.graphic.current_step = self.current_step
    self.graphic.cue = page_sequencer.seq.cued_ticks_per_step
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
            k3 = { name = "", value = "" },
            e2 = { name = "BPM", value = "" },
            e3 = { name = "STEPS", value = "" },
        },
        font_face = FOOTER_FONT,
    })
end

return page
