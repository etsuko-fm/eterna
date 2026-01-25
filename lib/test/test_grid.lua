local luaunit = require 'test.luaunit'

TestGrid = {}

-- Tests require grid to be plugged in 
function TestGrid:setUp()
    grid_conn:refresh()
    luaunit.assertFalse(grid_conn.changed)
end

function TestGrid:tearDown()
    grid_conn:refresh()
    luaunit.assertFalse(grid_conn.changed)
end

function TestGrid:test_led_stores_value_in_grid_state()
    grid_conn:led(3, 5, 10)
    luaunit.assertEquals(grid_conn.grid_state[3][5], 10)
end

function TestGrid:test_led_ceils_fractional_value()
    grid_conn:led(1, 1, 7.3)
    luaunit.assertEquals(grid_conn.grid_state[1][1], 8)
end

function TestGrid:test_led_sets_changed_flag()
    luaunit.assertFalse(grid_conn.changed)
    grid_conn:led(2, 4, 5)
    luaunit.assertTrue(grid_conn.changed)
end

return TestGrid