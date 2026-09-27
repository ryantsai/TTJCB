-- Timing shared by gameplay poses and the animation review.
local Arms = require('armature')
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

-- Separate preparation from recovery so raised weapons return to the guard,
-- rather than reversing the overhead wind-up after the hit.
function M.windup(time: number, activeStart: number, extension: number): number
    if time >= activeStart then return 0 end
    return math.sin(math.clamp(time / (activeStart * .55), 0, 1) * math.pi / 2) * (1 - math.max(0, extension))
end

-- Planted half-cycle, then a curved toe-off and knee-lift return.
function M.stride(phase: number, stride: number, lift: number): (number, number)
    local cycle = (phase / (math.pi * 2)) % 1
    if cycle < .56 then
        return stride * (1 - 2 * cycle / .56), 0
    end
    local u = (cycle - .56) / .44
    local ease = u * u * (3 - 2 * u)
    return stride * (-1 + 2 * ease), -math.sin(u * math.pi) * lift
end

-- Both hands are projected together so the staff stays rigid in every pose.
function M.staff(move: number, ext: number, windup: number, stroke: number, sh: number): (number, number, number, number)
    local e = math.max(0, ext)
    local angle = .12
    if move == 2 then angle += e * (-.9 + stroke * 1.6) - windup * .6
    elseif move == 3 then angle += e * (-.3 + stroke * 1.05) - windup * 1.75 end
    local dx,dy = math.cos(angle)*14,math.sin(angle)*14
    local fx = 12 + e * (if move==1 then 12 else 8) - windup * 12
    local fy = sh + 15 - windup * (if move==3 then 32 else 6) + (if move==3 then e*stroke*12 else 0)
    for _ = 1, 4 do
        local _,_,x,y = Arms.solve('robin',-10,sh+4,fx,fy)
        fx,fy=x,y
        local _,_,bx,by = Arms.solve('robin',11,sh+2,fx-dx,fy-dy)
        fx,fy=bx+dx,by+dy
    end
    return fx,fy,fx-dx,fy-dy
end

return M
