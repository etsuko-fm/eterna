local luaunit = require 'test.luaunit'

TestCycleParam = include(from_root("lib/test/util/misc/test_cycle_param"))
TestExplin = include(from_root("lib/test/util/misc/test_explin"))
TestToggleParam = include(from_root("lib/test/util/misc/test_toggle_param"))

local tests = {TestCycleParam, TestExplin, TestToggleParam}

local runner = luaunit.LuaUnit.new()
runner:setOutputType('text')
runner:runSuite('TestCycleParam', 'TestExplin', 'TestToggleParam')

-- dofile('/home/we/dust/code/eterna/lib/test/run.lua')
