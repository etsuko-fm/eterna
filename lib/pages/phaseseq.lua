local Page = include("bits/lib/Page")
local Window = include("bits/lib/graphics/Window")
local misc_util = include("bits/lib/util/misc")
local lfo_util = include("bits/lib/util/lfo")

local page_name = "PHASE SEQUENCER"
local window
local filter_lfo

local page = Page:create({
    name = page_name,
    e2 = nil,
    e3 = nil,
    k2_off = nil,
    k3_off = nil,
})

local function add_params()
end
local count = 0


local function draw_arrow(x,y)
    screen.fill()
    screen.move(x,y)
    screen.line_rel(-2,-2)
    screen.stroke()
    screen.move(x,y-1)
    screen.line_rel(-2,2)
    screen.stroke()
    screen.pixel(x-2,y-1)
    screen.fill()
end

local enabled = {4,2,6,1,5,7}
local basex = 42
local basey = 10
local spacing_w = 4
local spacing_h = 4
function page:render()
    window:render()
    count = util.wrap(count + 1, 1, 10)
    
    for j=1,6 do
        -- screen.level(3+math.abs(j-6)*2)
        local phase = voice_pos_percentage[j]
        if phase ~= nil then
            local x = basex
            local y = basey + j*spacing_h
            screen.move(x, y)
            screen.level(math.floor(1+math.abs(phase-.5)*15))
            screen.line_rel(32*phase, 0)
            screen.stroke()
        end
    end
    page.footer:render()
end

function page:initialize()
    add_params()
    window = Window:new({
        x = 0,
        y = 0,
        w = 128,
        h = 64,
        title = "PHASE SEQUENCER",
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
                name = "A",
                value = "",
            },
            k3 = {
                name = "B",
                value = "",
            },
            e2 = {
                name = "C",
                value = "",
            },
            e3 = {
                name = "D",
                value = "",
            },
        },
        font_face = FOOTER_FONT,
    })
end

return page
