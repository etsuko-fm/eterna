local luaunit = require 'test.luaunit'

TestCycleParam = include(from_root("lib/test/util/misc/test_cycle_param"))
TestExplin = include(from_root("lib/test/util/misc/test_explin"))
TestToggleParam = include(from_root("lib/test/util/misc/test_toggle_param"))
TestGrid = include(from_root("lib/test/test_grid"))

local runner = luaunit.LuaUnit.new()
runner:setOutputType('text')
runner:runSuite('TestCycleParam', 'TestExplin', 'TestToggleParam', 'TestGrid')

-- dofile('/home/we/dust/code/eterna/lib/test/run.lua')
