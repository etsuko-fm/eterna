local Page = include("bits/lib/Page")
local Window = include("bits/lib/graphics/Window")

local page_name = "SEQUENCE CONTROL"
local window


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
    local default_level = 3
    local bright_level = 15
    screen.level(default_level)

    local y = 22
    local bpm_y = y + 2
    local bar_h = 4

    screen.rect(32, bpm_y, 63, bar_h)
    screen.fill()

    for i=0,15 do
        if i == 4 then
            screen.level(bright_level)
        else
            screen.level(default_level)
        end
        screen.rect(32 + i * 4, y+8, 3, bar_h)
        screen.fill()
    end
    screen.level(default_level)
    for i=0,3 do
        screen.rect(32+i*7, y-4, 6, bar_h)
        screen.fill()
    end
    for i=5,8 do
        screen.rect(33+i*7, y-4, 6, bar_h)
        screen.fill()
    end
    screen.level(bright_level)
    screen.rect(32 + 4*7, y-4, 7, bar_h)
    screen.fill()

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
