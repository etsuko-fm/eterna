local MasterGraphic = include("symbiosis/lib/graphics/MasterGraphic")
local page_name = "MASTER"
local master_graphic

local function adjust_drive(d)
    local p = ID_MASTER_COMP_DRIVE
    local new_val = params:get_raw(p) + d * controlspec_master_drive.quantum
    params:set_raw(p, new_val, false)
end

local function cycle_mono()
    local p = ID_MASTER_MONO_FREQ
    local curr = params:get(p)
    params:set(p, util.wrap(curr + 1, 1, #BASS_MONO_FREQS_STR))
end

local function cycle_comp_amount()
    local p = ID_MASTER_COMP_AMOUNT
    local curr = params:get(p)
    params:set(p, util.wrap(curr + 1, 1, #COMP_AMOUNTS))
end

local function adjust_output(d)
    local p = ID_MASTER_OUTPUT
    local new_val = params:get_raw(p) + d * controlspec_master_output.quantum
    params:set_raw(p, new_val, false)
end

local page = Page:create({
    name = page_name,
    e2 = adjust_drive,
    e3 = adjust_output,
    k2_off = cycle_mono,
    k3_off = cycle_comp_amount,
})

local function action_comp_amount(v)
    local preset = COMP_AMOUNTS[v]
    if preset == "OFF" then
        engine.comp_ratio(1)
        engine.comp_threshold(1)
    elseif preset == "SOFT" then
        engine.comp_ratio(2)
        engine.comp_threshold(0.5)
    elseif preset == "MEDIUM" then
        engine.comp_ratio(4)
        engine.comp_threshold(0.25)
    elseif preset == "HARD" then
        engine.comp_ratio(8)
        engine.comp_threshold(0.125)
    end
end

local function action_master_output(v)
     if v == "-INF" then
        engine.comp_out_level(0)
    else
        engine.comp_out_level(v)
    end
end

local function add_params()
    params:set_action(ID_MASTER_COMP_DRIVE, function(v) engine.comp_gain(v) end)
    params:set_action(ID_MASTER_COMP_AMOUNT, action_comp_amount)
    params:set_action(ID_MASTER_MONO_FREQ, function(v) engine.bass_mono_freq(BASS_MONO_FREQS_INT[v]) end)
    params:set_action(ID_MASTER_OUTPUT, action_master_output)
end

function page:render()
    self.window:render()
    engine.request_amp_history()

    pre_comp_left_poll:update()
    pre_comp_right_poll:update()
    post_comp_left_poll:update()
    post_comp_right_poll:update()
    post_gain_left_poll:update()
    post_gain_right_poll:update()
    master_left_poll:update()
    master_right_poll:update()

    master_graphic.drive_amount = params:get_raw(ID_MASTER_COMP_DRIVE)
    master_graphic.out_level = params:get(ID_MASTER_OUTPUT)
    master_graphic:render()

    local drive = params:get(ID_MASTER_COMP_DRIVE)
    local mono_freq = params:get(ID_MASTER_MONO_FREQ)
    local comp_amount = params:get(ID_MASTER_COMP_AMOUNT)
    local output = params:get(ID_MASTER_OUTPUT)
    page.footer.button_text.k2.value = BASS_MONO_FREQS_STR[mono_freq]
    page.footer.button_text.k3.value = COMP_AMOUNTS[comp_amount]
    page.footer.button_text.e2.value = drive
    page.footer.button_text.e3.value = output
    page.footer:render()
end

function page:initialize()
    add_params()
    master_graphic = MasterGraphic:new()
    engine.metering_rate(1000)

    pre_comp_left_poll.callback = function(v) master_graphic.pre_comp_levels[1] = amp_to_log(v) end
    pre_comp_right_poll.callback = function(v) master_graphic.pre_comp_levels[2] = amp_to_log(v) end
    post_comp_left_poll.callback = function(v) master_graphic.post_comp_levels[1] = amp_to_log(v) end
    post_comp_right_poll.callback = function(v) master_graphic.post_comp_levels[2] = amp_to_log(v) end
    post_gain_left_poll.callback = function(v) master_graphic.post_gain_levels[1] = amp_to_log(v) end
    post_gain_right_poll.callback = function(v) master_graphic.post_gain_levels[2] = amp_to_log(v) end
    master_left_poll.callback = function(v) master_graphic.out_levels[1] = amp_to_log(v) end
    master_right_poll.callback = function(v) master_graphic.out_levels[2] = amp_to_log(v) end

    self.window = Window:new({ title = page_name, font_face = TITLE_FONT })

    -- graphics
    page.footer = Footer:new({
        button_text = {
            k2 = {
                name = "MONO",
                value = "4:1",
            },
            k3 = {
                name = "COMP",
                value = "",
            },
            e2 = {
                name = "DRIVE",
                value = "",
            },
            e3 = {
                name = "OUT",
                value = "",
            },
        },
        font_face = FOOTER_FONT,
    })
end

return page
