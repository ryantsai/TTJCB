-- Timing shared by gameplay poses and the animation review.
local M = {}

function M.strike(time: number, duration: number, activeStart: number, activeEnd: number): number
    local windup = activeStart * 0.55
    if time < windup then
        return -0.35 * math.sin(math.clamp(time / windup, 0, 1) * math.pi / 2)
    elseif time < activeStart then
        local t = (time - windup) / (activeStart - windup)
        return -0.35 + 1.35 * (1 - (1 - t) ^ 3)
    elseif time <= activeEnd then
        return 1
    end
    local t = math.clamp((time - activeEnd) / (duration - activeEnd), 0, 1)
    return 1 - t * t * (3 - 2 * t)
end

return M
