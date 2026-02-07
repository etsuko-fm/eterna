local luaunit = require 'test.luaunit'

TestToggleParam = {}

function TestToggleParam:setUp()
    params:add_number("test_toggle", "test toggle param", 0, 1, 0)
end

function TestToggleParam:tearDown()
    -- reset param
    params.lookup["test_toggle"] = nil
end

function TestToggleParam:test_toggle_from_zero_to_one()
    params:set("test_toggle", 0)
    local result = misc_util.toggle_param("test_toggle")
    luaunit.assertEquals(params:get("test_toggle"), 1)
    luaunit.assertEquals(result, 1)
end

function TestToggleParam:test_toggle_from_one_to_zero()
    params:set("test_toggle", 1)
    local result = misc_util.toggle_param("test_toggle")
    luaunit.assertEquals(params:get("test_toggle"), 0)
    luaunit.assertEquals(result, 0)
end

function TestToggleParam:test_toggle_twice_returns_to_original()
    params:set("test_toggle", 0)
    misc_util.toggle_param("test_toggle")
    misc_util.toggle_param("test_toggle")
    luaunit.assertEquals(params:get("test_toggle"), 0)
end