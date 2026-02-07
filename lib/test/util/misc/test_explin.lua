local luaunit = require 'test.luaunit'

TestExplin = {}

function TestExplin:test_basic_conversion_positive_range()
    -- 100 Hz to 10000 Hz mapped to 0-127
    -- at 100 Hz (min) should give 0
    local result = misc_util.explin(100, 10000, 0, 127, 100)
    luaunit.assertAlmostEquals(result, 0, 0.01)
end

function TestExplin:test_basic_conversion_at_max()
    -- at 10000 Hz (max) should give 127
    local result = misc_util.explin(100, 10000, 0, 127, 10000)
    luaunit.assertAlmostEquals(result, 127, 0.01)
end

function TestExplin:test_midpoint_conversion()
    -- at 1000 Hz (geometric midpoint) should give ~63.5
    local result = misc_util.explin(100, 10000, 0, 127, 1000)
    luaunit.assertAlmostEquals(result, 63.5, 0.5)
end

function TestExplin:test_with_exp_factor()
    -- test with exponentiality factor of 2
    local result = misc_util.explin(100, 10000, 0, 127, 1000, 2)
    luaunit.assertTrue(result > 0 and result < 127)
end

function TestExplin:test_negative_range()
    -- test with negative source range
    local result = misc_util.explin(-10000, -100, 0, 127, -1000)
    luaunit.assertAlmostEquals(result, 63.5, 0.5)
end

function TestExplin:test_error_on_zero_slo()
    luaunit.assertErrorMsgContains("non-zero", misc_util.explin, 0, 100, 0, 127, 50)
end

function TestExplin:test_error_on_zero_shi()
    luaunit.assertErrorMsgContains("non-zero", misc_util.explin, 100, 0, 0, 127, 50)
end

function TestExplin:test_error_on_mixed_signs()
    luaunit.assertErrorMsgContains("same sign", misc_util.explin, -100, 100, 0, 127, 50)
end