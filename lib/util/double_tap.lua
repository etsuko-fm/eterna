-- A generic utility for detecting double taps on any key

-- Usage:
-- local DoubleTapState = include(from_root("lib/util/double_tap"))
-- local detector = DoubleTapState.new(0.4) -- 400ms window

-- -- In any input handler (e.g. grid.key):
-- if detector:register("x7:y3") then
--     -- double tap detected for this reference
-- end

local DoubleTapState = {}
DoubleTapState.__index = DoubleTapState

-- IDLE: no taps registered
local STATE_IDLE = "idle"
-- AWAITING: waiting for a second tap with the same key ref
local STATE_AWAITING = "awaiting" 

function DoubleTapState.new(threshold)
    local self = setmetatable({}, DoubleTapState)
    self.threshold = threshold or 0.3
    self.state = STATE_IDLE
    self.pending_key = nil
    self.pending_time = nil
    return self
end

function DoubleTapState:register(key)
    local now = util.time()

    if self.state == STATE_IDLE then
        self.state = STATE_AWAITING
        self.pending_key = key
        self.pending_time = now
        return false
    end

    -- STATE_AWAITING
    local elapsed = now - self.pending_time

    if key == self.pending_key and elapsed <= self.threshold then
        -- Double tap detected, reset to idle
        self.state = STATE_IDLE
        self.pending_key = nil
        self.pending_time = nil
        return true
    end

    -- Different key or expired window: this tap becomes the new first tap
    self.pending_key = key
    self.pending_time = now
    -- state stays AWAITING
    return false
end

function DoubleTapState:reset()
    self.state = STATE_IDLE
    self.pending_key = nil
    self.pending_time = nil
end

return DoubleTapState