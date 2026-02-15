local Sequencer = {}
Sequencer.__index = Sequencer

--[[
Sequencer timing overview:

- tick: the smallest time unit, advanced every call to `advance()`
- beat: a group of ticks, defined by `ticks_per_beat` (e.g. 16 ticks = 1 beat); 
        can be used in conjunction with midi clock sync, which is based on beats
        (as in quarter notes in any time signature), or to run a metronome;
- step: a musical subdivision controlled by `ticks_per_step`, defines the number 
        of ticks that goes into a step; each step triggers `on_step`
]]

function Sequencer.new(o)
    local s = setmetatable({}, Sequencer)

    s.steps = o.steps or 16
    s.rows = o.rows or 8
    s.ticks_per_beat = o.ticks_per_beat or 16
    s.ticks_per_step = o.ticks_per_step or 1
    s.cued_ticks_per_step = nil
    s.cued_num_steps = nil
    s.transport_on = o.transport_on or false

    s.current_tick = 0
    s.current_step = 1

    -- callbacks
    s.on_step = o.on_step or function(_) end       -- called when a new step is evaluated
    s.on_tick = o.on_tick or function(_) end -- called every tick
    s.on_reset = o.on_reset or function(_) end     -- called on reset

    return s
end

function Sequencer:reset()
    self.current_tick = 1
    self.current_step = 1
    self.on_reset(self)
end

function Sequencer:set_num_steps(steps)
    -- Sets the number of steps in the sequence
    if self.transport_on then
        -- cue the change so it can be applied exactly on the next step
        self.cued_num_steps = steps
    else
        -- if transport is stopped, change can be applied instantly
        self.steps = steps
    end
end

function Sequencer:set_ticks_per_step(ticks)
    -- Sets the rhythmic subdivision for each step (e.g. 1/8, 1/16). 
    -- 'ticks' is a positive integer (must be > 0)
    if self.transport_on then
        self.cued_ticks_per_step = ticks
    else
        self.ticks_per_step = ticks
    end
end

function Sequencer:advance()
    -- resets sequencer, in sync with beat, when step divider (=ticks per step) changes (e.g. from 1/16th to 1/8)
    if self.cued_ticks_per_step and self.current_tick == 1 then
        self.ticks_per_step = self.cued_ticks_per_step
        self.cued_ticks_per_step = nil
        self:reset()
    end

    -- change number of steps in sequence, in sync
    if self.cued_num_steps and self.current_tick == 1 then
        self.steps = self.cued_num_steps
        if self.current_step > self.steps then
            self:reset()
        end
    end

    -- when the ticks accumulate to one step according to the current ticks_per_step
    if (self.current_tick - 1) % self.ticks_per_step == 0 then
        -- allow client to handle engine calls, graphics, etc.
        self.on_step(self.current_step)

        -- advance step, take 1-based index into account
        self.current_step = (self.current_step % self.steps) + 1
    end

    -- advance tick
    self.current_tick = util.wrap(self.current_tick + 1, 1, self.ticks_per_step)
end

return Sequencer
