local MasterGraphic = include("symbiosis/lib/graphics/MasterGraphic")
local page_name = "MASTER"
local window
local master_graphic

local function adjust_drive(d)
    local p = ID_MASTER_COMP_DRIVE
    local new_val = params:get_raw(p) + d * controlspec_master_drive.quantum
    params:set_raw(p, new_val, false)
end

local function toggle_spread()
end

local function adjust_bass_mono_freq(d)
    local p = ID_MASTER_MONO_FREQ
    local new_val = params:get_raw(p) + d * controlspec_master_mono.quantum
    params:set_raw(p, new_val, false)
end


local page = Page:create({
    name = page_name,
    e2 = adjust_drive,
    e3 = adjust_bass_mono_freq,
    k2_off = nil,
    k3_off = toggle_spread,
})

local function add_params()
    params:set_action(ID_MASTER_COMP_DRIVE, function(v) engine.comp_gain(v) end)
    params:set_action(ID_MASTER_MONO_FREQ, function(v) engine.bass_mono_freq(v) end)
end

function page:render()
    window:render()

    -- if math.random() > .95 then
        engine.request_amp_history()
    -- end
    pre_compL_poll:update()
    pre_compR_poll:update()
    post_compL_poll:update()
    post_compR_poll:update()
    comp_amountL_poll:update()
    comp_amountR_poll:update()

    master_graphic.drive_amount = params:get_raw(ID_MASTER_COMP_DRIVE)

    master_graphic:render()

    local drive = params:get(ID_MASTER_COMP_DRIVE)
    local mono_freq = params:get(ID_MASTER_MONO_FREQ)
    page.footer.button_text.e2.value = drive
    page.footer.button_text.e3.value = mono_freq
    page.footer:render()
end

function page:initialize()
    add_params()
    master_graphic = MasterGraphic:new()

    pre_compL_poll.callback = function(v) master_graphic.pre_comp_levels[1] = amp_to_log(v) end
    pre_compR_poll.callback = function(v) master_graphic.pre_comp_levels[2] = amp_to_log(v) end
    post_compL_poll.callback = function(v) master_graphic.post_comp_levels[1] = amp_to_log(v) end
    post_compR_poll.callback = function(v) master_graphic.post_comp_levels[2] = amp_to_log(v) end
    comp_amountL_poll.callback = function(v) master_graphic.comp_amount_levels[1] = amp_to_log(v) end
    comp_amountR_poll.callback = function(v) master_graphic.comp_amount_levels[2] = amp_to_log(v) end

    window = Window:new({
        x = 0,
        y = 0,
        w = 128,
        h = 64,
        title = "MASTER",
        font_face = TITLE_FONT,
        brightness = 15,
        border = false,
        selected = true,
        horizontal_separations = 0,
        vertical_separations = 0,
    })
    -- graphics
    page.footer = Footer:new({
        button_text = {
            k2 = {
                name = "COMP",
                value = "",
            },
            k3 = {
                name = "VERB",
                value = "",
            },
            e2 = {
                name = "DRIVE",
                value = "",
            },
            e3 = {
                name = "MONO",
                value = "",
            },
        },
        font_face = FOOTER_FONT,
    })
end

return page
