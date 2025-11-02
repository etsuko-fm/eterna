local MasterGraphic = include("symbiosis/lib/graphics/MasterGraphic")
local page_name = "MASTER"
local master_graphic

local ENGINE_MASTER_COMP_DRIVE = sym.get_id("comp_drive")
local ENGINE_MASTER_OUTPUT = sym.get_id("comp_out_level")
local ENGINE_BASS_MONO_FREQ = sym.get_id("bass_mono_freq")
local ENGINE_COMP_RATIO = sym.get_id("comp_ratio")
local ENGINE_COMP_THRESHOLD = sym.get_id("comp_threshold")

local function adjust_drive(d)
    misc_util.adjust_param(d, ENGINE_MASTER_COMP_DRIVE, sym.specs["comp_drive"])
end

local function adjust_output(d)
    misc_util.adjust_param(d, ENGINE_MASTER_OUTPUT, sym.specs["comp_out_level"])
end

local function cycle_mono()
    misc_util.cycle_param(ID_MASTER_MONO_FREQ, BASS_MONO_FREQS_STR)
end

local function cycle_comp_amount()
    misc_util.cycle_param(ID_MASTER_COMP_AMOUNT, COMP_AMOUNTS)
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
        params:set(ENGINE_COMP_RATIO, 1)
        params:set(ENGINE_COMP_THRESHOLD, 1)
    elseif preset == "SOFT" then
        params:set(ENGINE_COMP_RATIO, 2)
        params:set(ENGINE_COMP_THRESHOLD, 1/2)
    elseif preset == "MEDIUM" then
        params:set(ENGINE_COMP_RATIO, 4)
        params:set(ENGINE_COMP_THRESHOLD, 1/4)
    elseif preset == "HARD" then
        params:set(ENGINE_COMP_RATIO, 8)
        params:set(ENGINE_COMP_THRESHOLD, 1/8)
    end
end

local function add_params()
    params:set_action(ID_MASTER_COMP_AMOUNT, action_comp_amount)
    params:set_action(ID_MASTER_MONO_FREQ, function(v) params:set(ENGINE_BASS_MONO_FREQ, BASS_MONO_FREQS_INT[v])  end)
end

function page:render()
    self.window:render()
    sym.request_amp_history()

    pre_comp_left_poll:update()
    pre_comp_right_poll:update()
    post_comp_left_poll:update()
    post_comp_right_poll:update()
    post_gain_left_poll:update()
    post_gain_right_poll:update()
    master_left_poll:update()
    master_right_poll:update()

    master_graphic.drive_amount = params:get_raw(ENGINE_MASTER_COMP_DRIVE)
    master_graphic.out_level = params:get(ENGINE_MASTER_OUTPUT)
    master_graphic:render()

    local drive = params:get(ENGINE_MASTER_COMP_DRIVE)
    local mono_freq = params:get(ID_MASTER_MONO_FREQ)
    local comp_amount = params:get(ID_MASTER_COMP_AMOUNT)
    local output = params:get(ENGINE_MASTER_OUTPUT) 
    page.footer.button_text.k2.value = BASS_MONO_FREQS_STR[mono_freq]
    page.footer.button_text.k3.value = COMP_AMOUNTS[comp_amount]
    page.footer.button_text.e2.value = util.round(drive, 0.1)
    if output == sym.master_out_min then
        page.footer.button_text.e3.value = "-INF"
    else
        page.footer.button_text.e3.value = util.round(output, 0.1)
    end
    page.footer:render()
end

function page:initialize()
    add_params()
    master_graphic = MasterGraphic:new()

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
            k2 = { name = "MONO", value = "4:1" },
            k3 = { name = "COMP", value = "" },
            e2 = { name = "DRIVE", value = "" },
            e3 = { name = "OUT", value = "" },
        },
        font_face = FOOTER_FONT,
    })
end

function page:enter()
    params:set(sym.get_id("metering_rate"), 1000)
end

function page:exit()
    params:set(sym.get_id("metering_rate"), 0)
end


return page
