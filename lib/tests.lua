local lu = require("lib.test.luaunit")

TestEvaluateStep = {}

function TestEvaluateStep:testCallsEnvLevelNotLevel()
    -- arrange: stub engine calls
    local called = {
        env_level = 0,
        level     = 0,
        trigger   = 0,
        lpg_freq  = 0,
        attack    = 0,
        decay     = 0,
    }

    local orig = {}

    -- increase call count when called
    for k in pairs(called) do
        orig[k] = engine[k]
        engine[k] = function(...) called[k] = called[k] + 1 end
    end

    -- act: call function under test
    evaluate_step(1, 1, true)

    -- assert: env_level called once, level never called
    lu.assertEquals(called.env_level, 1, "env_level should be called once")
    lu.assertEquals(called.level, 0, "level should not be called")

    -- cleanup
    for k, v in pairs(orig) do
        engine[k] = v
    end
end

-- os.exit(lu.LuaUnit.run())