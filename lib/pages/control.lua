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
    page_sequencer:render_graphic()
    self:render_footer()
end

function page:render_footer()
    local tempo_trimmed = util.round(params:get("clock_tempo"))
    self.footer.button_text.e2.value = tempo_trimmed
    self.footer.button_text.e3.value = page_sequencer.seq.steps
    self.footer.button_text.k2.value = page_sequencer.seq.transport_on and "ON" or "OFF"
    self.footer:render()
end

function page:initialize()
    add_params()
    self.parent = "sequencer"
    self.window = Window:new({ title = page_name, font_face = TITLE_FONT })
    self.footer = Footer:new({
        button_text = {
            k2 = { name = "PLAY", value = "" },
            k3 = { name = "", value = "" },
            e2 = { name = "BPM", value = "" },
            e3 = { name = "STEPS", value = "" },
        },
        font_face = FOOTER_FONT,
    })
end

function page:enter()
    page_sequencer:enter()
end

function page:exit()
    page_sequencer:exit()
end

return page
