local Page = include("bits/lib/Page")
local Window = include("bits/lib/graphics/Window")
local ControlGraphic = include("bits/lib/graphics/ControlGraphic")

local page_name = "SEQUENCE CONTROL"
local window
local control_graphic


local page = Page:create({
    name = page_name,
    e2 = nil,
    e3 = nil,
    k2_off = nil,
    k3_off = nil,
})

local function add_params()
    params:add_separator("SEQUENCE_CONTROL", page_name)
end

function page:render()
    window:render()
    control_graphic:render()
    page.footer:render()
end

function page:initialize()
    add_params()
    window = Window:new({
        x = 0,
        y = 0,
        w = 128,
        h = 64,
        title = page_name,
        font_face = TITLE_FONT,
        brightness = 15,
        border = false,
        selected = true,
        horizontal_separations = 0,
        vertical_separations = 0,
    })
    -- graphics
    control_graphic = ControlGraphic:new()
    page.footer = Footer:new({
        button_text = {
            k2 = {
                name = "PLAY",
                value = "",
            },
            k3 = {
                name = "HOLD",
                value = "",
            },
            e2 = {
                name = "BPM",
                value = "",
            },
            e3 = {
                name = "STEP",
                value = "",
            },
        },
        font_face = FOOTER_FONT,
    })
end

return page
