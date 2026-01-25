local luaunit = require 'test.luaunit'

TestCycleParam = {}

function TestCycleParam:setUp()
    self.test_table = { 1, 2, 3, 4, 5 }
    params:add_option("test", 'test_cycle_param', self.test_table)
end

function TestCycleParam:tearDown()
    -- reset param
    params.lookup["test"] = nil
end

function TestCycleParam:test_basic_increment()
    params:set("test", 1)
    misc_util.cycle_param("test", self.test_table, 1, true)
    luaunit.assertEquals(params:get("test"), 2)
end

function TestCycleParam:test_wrap_from_end_to_start()
    params:set("test", 5)
    misc_util.cycle_param("test", self.test_table, 1, true)
    luaunit.assertEquals(params:get("test"), 1)
end

function TestCycleParam:test_decrement_wrap_to_end()
    params:set("test", 1)
    misc_util.cycle_param("test", self.test_table, -1, true)
    luaunit.assertEquals(params:get("test"), 5)
end

function TestCycleParam:test_clamp_at_end_no_wrap()
    params:set("test", 5)
    misc_util.cycle_param("test", self.test_table, 1, false)
    luaunit.assertEquals(params:get("test"), 5)
end

function TestCycleParam:test_clamp_at_start_no_wrap()
    params:set("test", 1)
    misc_util.cycle_param("test", self.test_table, -1, false)
    luaunit.assertEquals(params:get("test"), 1)
end

function TestCycleParam:test_skip_single_index()
    params:set("test", 1)
    misc_util.cycle_param("test", self.test_table, 1, true, { 2 })
    luaunit.assertEquals(params:get("test"), 3)
end

function TestCycleParam:test_skip_multiple_indexes()
    params:set("test", 1)
    misc_util.cycle_param("test", self.test_table, 1, true, { 2, 3 })
    luaunit.assertEquals(params:get("test"), 4)
end

function TestCycleParam:test_skip_with_wrap_around()
    params:set("test", 4)
    misc_util.cycle_param("test", self.test_table, 1, true, { 5, 1 })
    luaunit.assertEquals(params:get("test"), 2)
end

function TestCycleParam:test_delta_of_2()
    params:set("test", 1)
    misc_util.cycle_param("test", self.test_table, 2, true)
    luaunit.assertEquals(params:get("test"), 3)
end

function TestCycleParam:test_delta_of_2_with_skip()
    params:set("test", 1)
    misc_util.cycle_param("test", self.test_table, 2, true, { 3 })
    luaunit.assertEquals(params:get("test"), 5)
end

function TestCycleParam:test_negative_delta_with_skip()
    params:set("test", 5)
    misc_util.cycle_param("test", self.test_table, -1, true, { 4 })
    luaunit.assertEquals(params:get("test"), 3)
end

function TestCycleParam:test_all_but_current_skipped()
    params:set("test", 1)
    misc_util.cycle_param("test", self.test_table, 1, true, { 2, 3, 4, 5 })
    luaunit.assertEquals(params:get("test"), 1)
end

-- local runner = luaunit.LuaUnit.new()
-- runner:setOutputType('text')
-- runner:runSuite('TestCycleParam')

-- dofile('/home/we/dust/code/eterna/lib/test/util/misc/test_cycle_param.lua')

return TestCycleParam