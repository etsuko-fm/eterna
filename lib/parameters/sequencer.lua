---
--- SEQUENCER
---

-- some values to seed the perlin noise, fact that they're primes is just for fun, can provide 
-- any set of reasonably spread numbers
local primes = {
  1, 2, 3, 5, 7, 11, 13, 17, 19, 23, 29,
  31, 37, 41, 43, 47, 53, 59, 61, 67,
  71, 73, 79, 83, 89, 97
}
controlspec_perlin = controlspec.def {
    min = 0,
    max = 100,
    warp = 'lin',
    step = .01,
    default = primes[math.floor(math.random(1,#primes))],
    units = '',
    quantum = .05,
    wrap = true
}

controlspec_perlin_z = controlspec.def {
    min = 0,
    max = 100,
    warp = 'lin',
    step = .01,
    default = 1,
    units = '',
    quantum = .05,
    wrap = true
}


controlspec_perlin_y = controlspec.def {
    min = 0,
    max = 25,
    warp = 'lin',
    step = .00001,
    default = math.random(4) * 25.0,
    units = '',
    quantum = .00001,
    wrap = true
}


controlspec_perlin_density = controlspec.def {
    min = 0,
    max = 1,
    warp = 'lin',
    step = .001,
    default = 0.0,
    units = '',
    quantum = .01,
    wrap = false
}

ID_SEQ_PERLIN_X = "sequencer_perlin_x"
ID_SEQ_PERLIN_Y = "sequencer_perlin_y"
ID_SEQ_PERLIN_Z = "sequencer_perlin_z"
-- ID_SEQ_EVOLVE = "sequencer_evolve"
ID_SEQ_PERLIN_DENSITY = "sequencer_perlin_density"
ID_SEQ_STYLE = "sequencer_style"
ID_SEQ_VELOCITY = "sequencer_velocity"

SEQ_VELOCITY_TABLE = {"LOW", "MID", "HIGH"}
-- SEQ_EVOLVE_TABLE = { "OFF", "SLOW", "MED", "FAST" }
-- SEQ_STREAM = "STREA"
-- SEQ_GRID = "MANUA"
-- SEQ_MOMENTARY = "MOMEN"
-- SEQ_GATE = "GATE"
-- SEQUENCE_STYLE_TABLE = { SEQ_GATE, SEQ_GRID }
ID_SEQ_STEP = {}
SEQ_ROWS=6
SEQ_COLUMNS=16

params:add_separator("SEQUENCER", "SEQUENCER")
params:add_control(ID_SEQ_PERLIN_X, "perlin x", controlspec_perlin)
params:add_control(ID_SEQ_PERLIN_Y, "perlin y", controlspec_perlin_y)
params:hide(ID_SEQ_PERLIN_Y)

params:add_control(ID_SEQ_PERLIN_Z, "perlin z", controlspec_perlin_z)
params:hide(ID_SEQ_PERLIN_Z)

params:add_control(ID_SEQ_PERLIN_DENSITY, "sequence density", controlspec_perlin_density)
params:add_option(ID_SEQ_VELOCITY, "evolve", SEQ_VELOCITY_TABLE, 3)
-- params:add_option(ID_SEQ_EVOLVE, "evolve", SEQ_EVOLVE_TABLE, 1)
-- params:add_option(ID_SEQ_STYLE, "sequence style", SEQUENCE_STYLE_TABLE, 1)

-- add 96 params for sequence step status
for y = 1, SEQ_ROWS do
    ID_SEQ_STEP[y] = {}
    for x = 1, SEQ_COLUMNS do
        ID_SEQ_STEP[y][x] = "sequencer_step_" .. y .. "_" .. x
        params:add_number(ID_SEQ_STEP[y][x], ID_SEQ_STEP[y][x], -1, 1, 0)
        params:hide(ID_SEQ_STEP[y][x])
    end
end
