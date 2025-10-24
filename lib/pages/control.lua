local ControlGraphic = include("symbiosis/lib/graphics/ControlGraphic")
local page_name = "SEQUENCE CONTROL"

local function adjust_bpm(d)
    params:set("clock_tempo", math.max(params:get('clock_tempo') + d, 15))
end


local function toggle_transport(v)
    page_sequencer:toggle_transport()
end

local page = Page:create({
    name = page_name,
    e2 = adjust_bpm,
    e3 = nil,
    k2_off = toggle_transport,
    k3_on = function() page_sequencer:toggle_hold_step() end,
})

local function add_params()
    -- 
end

function page:render()
    self.window:render()
    local tempo_trimmed = util.round(clock.get_tempo())
    local is_playing = page_sequencer.transport_on
    self.footer.button_text.e2.value = tempo_trimmed
    self.footer.button_text.k2.value = is_playing and "ON" or "OFF"
    -- local hold_text
    -- local s = page_sequencer.hold_status
    -- if s == "HOLD" or s == "AWAIT_RESUME" then hold_text = "ON"
    -- else hold_text = "OFF"
    -- end

    self.footer.button_text.k3.value = "PERL"
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
            k3 = { name = "SRC", value = "" },
            e2 = { name = "BPM", value = "" },
            e3 = { name = "STEPS", value = "" },
        },
        font_face = FOOTER_FONT,
    })
end

return page
