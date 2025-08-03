local page_name = "MASTER"
local window

local function adjust_drive(d)
    local p = ID_FILTER_DRIVE
    local new_val = params:get_raw(p) + d * controlspec_filter_drive.quantum
    params:set_raw(p, new_val, false)
end

local function toggle_spread()
end

local page = Page:create({
    name = page_name,
    e2 = adjust_drive,
    k2_off = nil,
    k3_off = toggle_spread,
})

local function add_params()
    params:set_action(ID_FILTER_DRIVE, function(v) engine.gain(v) end)
end

function page:render()
    window:render()
    screen.move(64,32)
    screen.text_center("MASTER")
    local drive = params:get(ID_FILTER_DRIVE)
    page.footer.button_text.e2.value = drive
    page.footer:render()
end

function page:initialize()
    add_params()
    window = Window:new({
        x = 0,
        y = 0,
        w = 128,
        h = 64,
        title = "FX",
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
                name = "SELECT",
                value = "",
            },
            k3 = {
                name = "PARAM",
                value = "",
            },
            e2 = {
                name = "DRIVE",
                value = "",
            },
            e3 = {
                name = "",
                value = "",
            },
        },
        font_face = FOOTER_FONT,
    })
end

return page
