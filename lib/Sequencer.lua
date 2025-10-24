local Sequencer = {}
Sequencer.__index = Sequencer

function Sequencer.new(o)
    local s = setmetatable({}, Sequencer)

    -- step may be 1 or 4, while master step is 16 or 32; this enables syncing events to the master step
    s.steps = o.steps or 16
    s.rows = o.rows or 8
    s.ticks_per_beat = o.ticks_per_beat or 16
    s.step_divider = o.step_divider or 1
    s.cued_step_divider = nil
    s.master_steps = o.master_steps or 16

    s.current_substep = 0
    s.current_step = 0
    s.current_master_step = 0
    s.current_beat = 0

    -- callbacks
    s.on_step = o.on_step or function(_) end       -- called when a new step is evaluated
    s.on_substep = o.on_substep or function(_) end -- called every substep
    s.on_reset = o.on_reset or function(_) end     -- called on reset

    return s
end

function Sequencer:reset()
    self.current_substep = 0
    self.current_master_step = 0
    self.current_step = 0
    self.current_beat = 0
    self.on_reset(self)
end

function Sequencer:set_step_divider(div)
    self.cued_step_divider = div
end

function Sequencer:advance()
    -- this method advances a single substep
    local ticks_per_beat = self.ticks_per_beat

    -- resets sequencer, in sync with beat, when step divider changes (e.g. from 1/16th to 1/8)
    if self.cued_step_divider and self.current_substep == 0 then
        self.step_divider = self.cued_step_divider
        self.cued_step_divider = nil
        self:reset()
    end

    -- optional callback every substep
    self.on_substep(self.current_substep, self.current_beat)

    -- when the susbteps accumulate to one step according to the current step divider
    if self.current_substep % self.step_divider == 0 then
        -- external logic handles engine calls, graphics, etc.
        self.on_step(self.current_step, self.current_master_step)

        -- advance step
        self.current_master_step = (self.current_master_step + 1) % self.master_steps
        self.current_step = (self.current_step + 1) % self.steps
    end

    -- advance substep + beat tracking
    local beats_per_sequence = 4 -- TODO: might make sense as a variable on the instance
    self.current_substep = (self.current_substep + 1) % (ticks_per_beat * beats_per_sequence)
    self.current_beat = math.floor(self.current_substep / ticks_per_beat)
end

return Sequencer
