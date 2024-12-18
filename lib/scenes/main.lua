local Scene = include("bits/lib/Scene")

local rings = {}
local current_ring = nil
local edit_mode = false
local zigzag_line = nil

local radians = {
    A0 = 0,                -- 3 o'clock
    A90 = math.pi / 2,     -- 6 o'clock
    A180 = math.pi,        -- 9 o'clock
    A270 = 3 * math.pi / 2 -- 12 o'clock
}


local ring_luma = {
    -- todo: could these be properties of the ring?
    -- so add when initializing
    circle = {
        normal = 3,
        deselected = 1,
    },
    rate_arc = {
        normal = 15,
        deselected = 5,
    },
    section_arc = {
        normal = 7,
        deselected = 2,
    },
}


local function create_rings(playback_rates)
    -- init rings. todo: should be in a separate file that defines this scene
    print("yes it really works")
    local y_offset = 18
    zigzag_line = shapes.ZigZagLine:new({ 0, 32, 128, 4, 4 })
    for i = 1, 6, 1 do
        -- these rings rotate according to playback rate
        rings[i] = Ring:new({
            x = i * 16 + 8,                                -- space evenly from x=24 to x=104
            y = 32 + y_offset + (-2 * y_offset * (i % 2)), -- 3 above, 3 below
            radius = 6,
            thickness = 3,
            luma = ring_luma.circle.normal, -- 15 = max level
            arcs = {
                -- {
                --   -- loop section arc
                --   a1 = loop_starts[i] / sample_length * math.pi * 2,
                --   a2 = loop_ends[i] / sample_length * math.pi * 2,
                --   luma = ring_luma.section_arc.normal,
                --   thickness = 3, -- pixels
                --   radius = 6,    -- pixels
                --   rate = 0,
                -- },
                {
                    -- playback rate arc
                    a1 = radians.A0,
                    a2 = radians.A90,
                    luma = ring_luma.rate_arc.normal, -- brightness, 0-15
                    thickness = 3,                    -- pixels
                    radius = 6,                       -- pixels
                    rate = playback_rates[i] / 10,
                },
            }
        })
    end
end

local function select_ring(n)
    current_ring = n
    for i = 1, 6 do
        if i == current_ring then
            rings[i].luma = ring_luma.circle.normal
            rings[i].arcs[1].luma = ring_luma.rate_arc.normal
            rings[i].selected = true
        else
            rings[i].luma = ring_luma.circle.deselected
            rings[i].arcs[1].luma = ring_luma.rate_arc.deselected
            rings[i].selected = false
        end
    end
end

local function deselect_rings()
    for i = 1, 6 do
        rings[i].luma = ring_luma.circle.normal
        rings[i].arcs[1].luma = ring_luma.rate_arc.normal
        rings[i].selected = false
    end
    current_ring = nil
end

local function one_indexed_modulo(n, m)
    -- utility to help cycling through 1-indexed arrays
    -- todo: move to util
    return ((n - 1) % m) + 1
end

local function select_next_ring()
    if edit_mode then return end -- in edit mode, can't select another ring
    if current_ring == nil then current_ring = 0 end
    next_ring = current_ring + 1
    if current_ring == 6 then
        current_ring = nil
        deselect_rings()
    else
        select_ring(one_indexed_modulo(next_ring, 6))
    end
end

local function render(playback_rates)
    screen.clear()
    if not next(rings) then create_rings(playback_rates) end

    for i = 1, 6, 1 do
        rings[i]:render()
    end

    if zigzag_line then
        zigzag_line:render()
    end
end

local function switch_to_edit_mode()
    if current_ring ~= nil then
        edit_mode = not edit_mode
        print("edit mode " .. tostring(edit_mode))
        if edit_mode then
            -- hide other rings
            -- hide zigzag
            -- show rate param
            -- show solo/mute param
            zigzag_line.hide = true
            for i = 1, 6 do
                if i ~= current_ring then
                    rings[i].hide = true
                end
            end
        else
            zigzag_line.hide = false
            for i = 1, 6 do
                rings[i].hide = false
            end
        end
    end
end


local scene_main = Scene:create({
    name = "Main",
    render = render,
    e1 = nil,
    e2 = nil,
    e3 = nil,
    k1_hold_on = nil,
    k1_hold_off = nil,
    k2_on = nil,
    k2_off = select_next_ring,
    k3_on = switch_to_edit_mode,
    k3_off = nil,
})

return scene_main
