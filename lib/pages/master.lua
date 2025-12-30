local MasterGraphic = include(from_root("lib/graphics/MasterGraphic"))
local page_name = "MASTER"

local ENGINE_MASTER_COMP_DRIVE = engine_lib.get_id("comp_drive")
local ENGINE_MASTER_OUTPUT = engine_lib.get_id("comp_out_level")
local ENGINE_BASS_MONO_FREQ = engine_lib.get_id("bass_mono_freq")
local ENGINE_COMP_RATIO = engine_lib.get_id("comp_ratio")
local ENGINE_COMP_THRESHOLD = engine_lib.get_id("comp_threshold")

local function adjust_drive(d)
    engine_lib.comp_drive(d, true)
end

local function adjust_output(d)
    engine_lib.comp_out_level(d, true)
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

function page:update_graphics_state()
    engine_lib.request_amp_history()

    -- poll for metering graphics
    pre_comp_left_poll:update()
    pre_comp_right_poll:update()
    post_comp_left_poll:update()
    post_comp_right_poll:update()
    post_gain_left_poll:update()
    post_gain_right_poll:update()
    master_left_poll:update()
    master_right_poll:update()

    local drive = params:get(ENGINE_MASTER_COMP_DRIVE)
    local mono_freq = params:get(ID_MASTER_MONO_FREQ)
    local comp_amount = params:get(ID_MASTER_COMP_AMOUNT)
    local output = params:get(ENGINE_MASTER_OUTPUT)

    self.graphic:set("drive_amount", params:get_raw(ENGINE_MASTER_COMP_DRIVE))
    self.graphic:set("out_level", params:get(ENGINE_MASTER_OUTPUT))
    self.graphic:set("amp_history", self.amp_history)
    self.footer:set_value("k2", BASS_MONO_FREQS_STR[mono_freq])
    self.footer:set_value("k3", COMP_AMOUNTS[comp_amount])
    self.footer:set_value("e2", util.round(drive, 0.1))
    if output == engine_lib.master_out_min then
        self.footer:set_value("e3", "-INF")
    else
        self.footer:set_value("e3", util.round(output, 0.1))
    end
end

function page:initialize()
    add_params()
    self.amp_history = {{}, {}}
    self.graphic = MasterGraphic:new()
    pre_comp_left_poll.callback = function(v) self.graphic:set_table("pre_comp_levels", 1, amp_to_log(v)) end
    pre_comp_right_poll.callback = function(v) self.graphic:set_table("pre_comp_levels", 2, amp_to_log(v)) end
    post_comp_left_poll.callback = function(v) self.graphic:set_table("post_comp_levels", 1, amp_to_log(v)) end
    post_comp_right_poll.callback = function(v) self.graphic:set_table("post_comp_levels", 2, amp_to_log(v)) end
    post_gain_left_poll.callback = function(v) self.graphic:set_table("post_gain_levels", 1, amp_to_log(v)) end
    post_gain_right_poll.callback = function(v) self.graphic:set_table("post_gain_levels", 2, amp_to_log(v)) end
    master_left_poll.callback = function(v) self.graphic:set_table("out_levels",  1, amp_to_log(v)) end
    master_right_poll.callback = function(v) self.graphic:set_table("out_levels", 2, amp_to_log(v)) end

    window.title = page_name

    -- graphics
    self.footer = Footer:new({
        button_text = {
            k2 = { name = "MONO", value = "" },
            k3 = { name = "COMP", value = "" },
            e2 = { name = "DRIVE", value = "" },
            e3 = { name = "OUT", value = "" },
        },
        font_face = FOOTER_FONT,
    })
end

function page:enter()
    window:set("title", page_name)
    params:set(engine_lib.get_id("metering_rate"), 500)
end


function page:exit()
    params:set(engine_lib.get_id("metering_rate"), 0)
end


return page
