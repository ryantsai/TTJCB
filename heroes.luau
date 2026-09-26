-- The five Titans, drawn Teen Titans Go! style: right-facing side view,
-- huge heads, slim bodies and heavy ink. Colours and shapes follow the show's
-- character sheets. Each figure stands with its feet at (0, 0) and faces +x;
-- the game mirrors it for the other direction.
local G = require('gfx')
local P = require('pose')
local Profile = require('profiles')

local HX = {}
local H = G.hex
local INK = G.INK

-- Pose helpers ---------------------------------------------------------------------

local function lerp(a: number, b: number, k: number): number
    return a + (b - a) * k
end

local function bob(p: P.Pose): number
    if p.air or p.down > 0 then
        return 0
    end
    local weight = math.abs(math.sin(p.phase)) * 3 * p.walk
    local anticipation = math.max(0, -p.ext) * 8
    local strike = if p.move >= 1 and p.move <= 3 then math.max(0, p.ext) * 2 else 0
    return weight + anticipation - strike - math.sin(p.t * 2.4) * 0.8 * (1 - p.walk)
end

-- Where a hand goes: its idle spot (ix, iy), or wherever the move takes it.
local function hand(p: P.Pose, front: boolean, sx: number, sy: number, ix: number, iy: number, reach: number): (number, number)
    local ePos = math.max(0, p.ext)
    local eNeg = math.max(0, -p.ext)
    local swing = math.sin(p.phase) * p.walk * (if front then -12 else 12)
    local m = p.move
    if p.hurt then
        return sx - 10, sy - 14 + (if front then 0 else 3)
    end
    if m == 1 or m == 6 then
        if front then
            return lerp(ix, sx + reach, ePos) - eNeg * 12, lerp(iy, sy + 3, ePos) - eNeg * 4
        end
        return sx + 10, sy + 10
    elseif m == 2 then
        if not front then
            return lerp(ix, sx + reach + 12, ePos) - eNeg * 22, lerp(iy, sy + 4, ePos) - eNeg * 8
        end
        return sx + 6, sy + 10
    elseif m == 3 then
        return (if front then sx - 8 else sx + 12), (if front then sy + 8 else sy - 6)
    elseif m == 4 then
        return (if front then sx - 10 else sx + 6), (if front then sy - 6 else sy - 14)
    elseif m == 5 then
        return sx + reach, sy + (if front then 2 else 6)
    end
    if p.air then
        return sx + (if front then 8 else -8), sy - 10
    end
    return lerp(ix, sx, p.walk) + swing, iy - math.abs(swing) * 0.15
end

-- Elbow or knee: the midpoint pushed sideways by `bend`.
local function joint(ax: number, ay: number, bx: number, by: number, bend: number): (number, number)
    local dx, dy = bx - ax, by - ay
    local len = math.max(1, math.sqrt(dx * dx + dy * dy))
    return (ax + bx) / 2 - dy / len * bend, (ay + by) / 2 + dx / len * bend
end

local function legJoint(p: P.Pose, hx: number, hy: number, fx: number, fy: number): (number, number)
    if p.walk < 0.01 and p.move == 0 and not p.air then
        return joint(hx, hy, fx, fy, -2)
    end
    local dx, dy = fx - hx, fy - hy
    local d = math.max(0.01, math.sqrt(dx * dx + dy * dy))
    local upper = math.abs(hy) * 0.53 + 2
    local lower = math.abs(hy) * 0.5 + 2
    local along = math.clamp((upper * upper - lower * lower + d * d) / (2 * d), 0, d)
    local bend = math.sqrt(math.max(0, upper * upper - along * along))
    return hx + dx / d * along + dy / d * bend, hy + dy / d * along - dx / d * bend
end

-- Where a foot goes.
local function foot(p: P.Pose, front: boolean, hipX: number, hipY: number, restX: number): (number, number)
    local s = math.sin(p.phase) * p.walk
    local c = math.cos(p.phase)
    local dir = if front then 1 else -1
    local ePos = math.max(0, p.ext)
    if p.move == 3 and front then
        local chamber = math.min(1, math.max(0, -p.ext) / 0.35)
        local reach = hipX + math.abs(hipY) * 1.03 + 3 - restX
        return lerp(restX, hipX + 12, chamber) + ePos * reach, lerp(0, hipY * 0.6, chamber) + (hipY + 4) * ePos
    elseif p.move == 4 then
        if front then
            return hipX + math.abs(hipY) * 0.98, hipY + 6
        end
        return restX - 2, hipY * 0.45
    end
    if p.air then
        return restX + dir * 3 + 2, hipY * 0.35
    end
    local fy = 0
    if p.walk > 0.05 then
        fy = -math.max(0, dir * c) * 12 * p.walk
    end
    return restX + dir * s * math.min(20, math.abs(hipY) * 0.55), fy
end

-- Lean the upper body around the hips.
local function leanBegin(p: P.Pose, pivotY: number)
    local lean = p.walk * 0.08
    if p.hurt then
        lean = -0.22
    elseif p.move ~= 0 and p.move ~= 5 then
        lean = 0.19 * math.max(0, p.ext) - 0.32 * math.max(0, -p.ext)
    end
    G.save()
    G.translate(0, pivotY)
    G.rotate(lean)
    G.translate(0, -pivotY)
end

-- Knocked down or floating.
local function frameBegin(p: P.Pose, hover: number, lie: number)
    G.save()
    if p.down > 0 then
        G.translate(0, -lie * p.down)
        G.rotate(-math.pi / 2 * p.down)
    elseif hover > 0 then
        G.translate(0, -hover - math.sin(p.t * 2.6) * 3)
    end
end

local function stick(ax: number, ay: number, bx: number, by: number, cx: number, cy: number, th: number, c: Color)
    G.limb(ax, ay, bx, by, cx, cy, th, c)
end

-- Scale drawings around a point; pair with G.restore().
local function scaleAt(x: number, y: number, k: number)
    G.save()
    G.translate(x, y)
    G.scale(k, k)
    G.translate(-x, -y)
end

local function mitt(x: number, y: number, r: number, c: Color, cuff: boolean)
    if cuff then
        G.poly({ x - r * 1.2, y - r * 1.6, x + r * 1.2, y - r * 1.6, x + r * 0.7, y - r * 0.4, x - r * 0.7, y - r * 0.4 }, c, 2)
    end
    G.oellipse(x, y, r, r * 0.9, c, 2)
end

local function glowHands(p: P.Pose, x1: number, y1: number, x2: number, y2: number, c: Color)
    if p.move == 5 or (p.ext > 0.3 and p.move ~= 3 and p.move ~= 4) then
        if p.move == 2 then
            G.glow(x2, y2, 24, c, 0.85)
        else
            G.glow(x1, y1, 24, c, 0.85)
        end
        if p.move == 5 then
            G.glow(x2, y2, 20, c, 0.7)
        end
    end
end

-- Robin -----------------------------------------------------------------------------

local R_SKIN = H(0xF7BEA5)
local R_RED = H(0xE00048)
local R_GREEN = H(0x22B86C)
local R_YELLOW = H(0xFFE04D)
local R_CAPE = H(0xEAC543)
local R_HAIR = H(0x0A0A12)

local function robinHead(hx: number, hy: number, hurt: boolean, t: number)
    G.save()
    G.translate(hx, hy)
    G.oellipse(-24, 3, 4, 7, R_SKIN, 1.5)
    G.oellipse(24, 3, 4, 7, R_SKIN, 1.5)
    G.contour({ -24, -14,
        -16, -25, 16, -25, 24, -14,
        29, -2, 23, 18, 0, 24,
        -20, 19, -29, 5, -24, -14,
    }, R_SKIN, 1.8)
    -- Compact swept spikes and a widow's peak, with a clear brow underneath.
    G.poly({ -24, 1, -28, -19, -21, -31, -20, -23, -8, -37,
        -9, -28, 7, -41, 6, -31, 18, -39, 27, -22, 26, 1,
        20, -13, 10, -17, 3, -12, 0, -7, -5, -14, -15, -17, -21, -11 }, R_HAIR, 1.8)
    -- Each white eye follows the tapered mask, instead of floating circles.
    G.contour({ -21, -11,
        -14, -10, -5, -3, 0, 3,
        -5, 13, -16, 15, -20, 8,
        -23, 2, -23, -5, -21, -11,
    }, R_HAIR, 1.2)
    G.contour({ 21, -11,
        23, -5, 23, 2, 20, 8,
        16, 15, 5, 13, 0, 3,
        5, -3, 14, -10, 21, -11,
    }, R_HAIR, 1.2)
    G.contour({ -19, -7,
        -12, -4, -7, 0, -3, 4,
        -7, 10, -14, 11, -17, 6,
        -19, 3, -20, -2, -19, -7,
    }, G.WHITE)
    G.contour({ 19, -7,
        20, -2, 19, 3, 17, 6,
        14, 11, 7, 10, 3, 4,
        7, 0, 12, -4, 19, -7,
    }, G.WHITE)
    if hurt then
        G.line(-18, 1, -6, 4, 2.2, R_HAIR)
        G.line(6, 4, 18, 1, 2.2, R_HAIR)
    end
    G.polyline({ -4, 16, 0, 17, 5, 15 }, 1.3, INK)
    G.restore()
end

local function robin(p: P.Pose, titleFacing: boolean)
    frameBegin(p, 0, 16)
    local b = bob(p)
    local hipY, sh = -34 + b, -62 + b
    local flare = p.walk * 7 + math.abs(p.ext) * 10 + (if p.air then 6 else 0) + math.sin(p.t * 4) * 1.5
    -- cape
    if titleFacing then
        G.poly({ -13, sh, 14, sh, 19 + flare * 0.4, -11, 2, -9, -18 - flare, -11 }, R_CAPE, 2.5)
        G.line(-8, sh + 6, -14 - flare, -12, 2, H(0x8F6A1E))
    else
        G.poly({ -8, sh, 4, sh + 2, -9, -12, -32 - flare, -8, -23 - flare, -25 }, R_CAPE, 2)
        G.line(-9, sh + 6, -24 - flare, -14, 1.5, H(0xB28B2B))
    end
    -- back arm
    leanBegin(p, hipY)
    local bsx: number, bsy: number, bhx: number, bhy: number
    if titleFacing then
        bsx, bsy = -9, sh + 3
        bhx, bhy = hand(p, false, bsx, bsy, -11, hipY - 3, 19)
    else
        bsx, bsy = 6, sh + 4
        bhx, bhy = hand(p, false, bsx, bsy, 18, hipY - 10, 25)
    end
    local bex, bey = joint(bsx, bsy, bhx, bhy, if p.move == 0 then 6 else 3)
    stick(bsx, bsy, bex, bey, bhx, bhy, 4.5, G.shade(R_SKIN, -0.12))
    mitt(bhx, bhy, 4.8, G.shade(R_GREEN, -0.15), true)
    G.restore()
    -- legs
    local ffx, ffy = foot(p, true, 4, hipY, 5)
    local bfx, bfy = foot(p, false, -4, hipY, -5)
    for i = 1, 2 do
        local hx = if i == 1 then -4 else 4
        local fx = if i == 1 then bfx else ffx
        local fy = if i == 1 then bfy else ffy
        local k = if i == 1 then -0.15 else 0
        local kx, ky = legJoint(p, hx, hipY, fx, fy)
        stick(hx, hipY, kx, ky, fx, fy - 3, 6.5, G.shade(R_GREEN, k))
        stick(lerp(kx, fx, 0.5), lerp(ky, fy, 0.5), fx, fy - 3, fx, fy - 3, 6.5, G.shade(R_HAIR, k))
        G.oellipse(fx + 3, fy - 2.5, 5.5, 3.4, G.shade(R_HAIR, k), 2)
    end
    leanBegin(p, hipY)
    -- black neck
    G.poly({ -5, sh - 7, 5, sh - 7, 4, sh + 8, -4, sh + 8 }, R_HAIR)
    -- tunic
    if titleFacing then
        G.poly({ -11, sh - 1, 12, sh - 1, 10, hipY + 2, -9, hipY + 2 }, R_RED, 2.5)
    else
        G.poly({ -8, sh, 11, sh - 1, 15, sh + 12, 7, hipY + 2, -8, hipY + 2 }, R_RED, 2)
    end
    G.poly({ -5, sh - 1, 0, sh + 4, 5, sh - 1 }, R_HAIR)
    if titleFacing then
        G.line(-6, sh + 9, -1, sh + 8, 2, R_YELLOW)
        G.line(-6, sh + 14, -1, sh + 13, 2, R_YELLOW)
    else
        G.line(8, sh + 8, 12, sh + 7, 2, R_YELLOW)
        G.line(8, sh + 13, 12, sh + 12, 2, R_YELLOW)
    end
    -- R badge
    if titleFacing then
        G.oellipse(5.5, sh + 11, 3.4, 3.4, R_YELLOW, 1.5)
    else
        G.oellipse(3, sh + 10, 3.1, 3.4, R_YELLOW, 1)
    end
    G.save()
    if titleFacing then
        G.translate(5.5, sh + 11)
    else
        G.translate(3, sh + 10)
    end
    G.scale(p.flip, 1)
    G.label('R', -1.1, -2, 4.2, R_HAIR)
    G.restore()
    -- belt
    G.rrect(-10, hipY - 4, 21, 4.5, 2, R_YELLOW, 1.5)
    G.oellipse(0, hipY - 2, 2.6, 2.6, R_YELLOW, 1.5)
    G.circle(0, hipY - 2, 1.2, H(0xD08A1E))
    -- green short sleeves
    if titleFacing then
        G.oellipse(-10, sh + 2, 4.5, 3.8, G.shade(R_GREEN, -0.12), 1.8)
        G.oellipse(11, sh + 2, 4.5, 3.8, R_GREEN, 1.8)
    else
        G.oellipse(8, sh + 2, 3.5, 3.8, G.shade(R_GREEN, -0.12), 1.5)
        G.oellipse(-1, sh + 2, 4.5, 4, R_GREEN, 1.5)
    end
    -- head
    scaleAt(2, sh - 26, 1.0)
    if titleFacing then
        robinHead(2, sh - 26, p.hurt or p.ko, p.t)
    else
        Profile.robin(4, sh - 26, p.hurt or p.ko)
    end
    G.restore()
    -- front arm
    local fsx: number, fsy: number, fhx: number, fhy: number
    if titleFacing then
        fsx, fsy = 11, sh + 3
        fhx, fhy = hand(p, true, fsx, fsy, 12, hipY - 3, 21)
    else
        fsx, fsy = -1, sh + 3
        fhx, fhy = hand(p, true, fsx, fsy, 14, hipY - 7, 33)
    end
    local fex, fey = joint(fsx, fsy, fhx, fhy, if p.move == 0 then -6 else 3)
    stick(fsx, fsy, fex, fey, fhx, fhy, 4.5, R_SKIN)
    mitt(fhx, fhy, 4.2, R_GREEN, true)
    G.restore()
    G.restore()
end

-- Cyborg ---------------------------------------------------------------------------

local C_SKIN = H(0xA86858)
local C_GREY = H(0xCDD2DF)
local C_LIGHT = H(0xF1F4FA)
local C_DARK = H(0x6E7080)
local C_CYAN = H(0x91EEF1)
local C_TRACE = H(0x3FA8C8)
local C_RED = H(0xE80050)

local function cyborgHead(hx: number, hy: number, hurt: boolean, t: number)
    G.save()
    G.translate(hx, hy)
    G.oellipse(-22, 0, 4, 6, C_SKIN, 1.5)
    G.contour({ -20, -21,
        -8, -25, 15, -23, 21, -14,
        24, -5, 23, 14, 15, 23,
        5, 26, -12, 22, -19, 14,
        -23, 6, -24, -11, -20, -21,
    }, C_SKIN, 1.8)
    -- The mechanical side is a narrow face plate, not half a cyan skull.
    G.contour({ 7, -22,
        14, -21, 19, -18, 21, -14,
        24, -3, 23, 14, 15, 23,
        16, 11, 14, 1, 9, -3,
        9, -10, 9, -17, 7, -22,
    }, C_LIGHT, 1.2)
    G.poly({ 10, -18, 19, -14, 21, -7, 10, -8 }, C_CYAN, 0.8)
    G.poly({ 9, -7, 22, -6, 22, 3, 10, 3 }, INK, 1)
    G.oellipse(15.5, -1, 4.5, 3.7, C_RED, 0.7)
    G.circle(17, -2, 1.1, G.WHITE)
    G.oellipse(-6, -3, 5.5, 5, G.WHITE, 1.1)
    G.ellipse(-4, -2.5, 1.9, 3, INK)
    G.polyline({ -13, -9, -7, -11, -1, -7 }, 3, INK)
    G.polyline({ 1, -2, 3, 6, -1, 7 }, 1.3, INK)
    if hurt then
        G.line(-12, 13, 5, 13, 1.6, INK)
    else
        G.contour({ -13, 10,
            -6, 14, 4, 15, 12, 11,
            5, 20, -6, 20, -13, 10,
        }, G.WHITE, 1)
    end
    G.poly({ -1, 20, 6, 20, 8, 24, -2, 23 }, C_LIGHT, 0.8)
    G.restore()
end

local function cyborgArm(p: P.Pose, front: boolean, sx: number, sy: number, ix: number, iy: number)
    local k = if front then 0 else -0.15
    local hx, hy = hand(p, front, sx, sy, ix, iy, if front then 64 else 36)
    local ex, ey = joint(sx, sy, hx, hy, if front then -4 else 4)
    -- grey arm with a cyan band at the shoulder
    stick(sx, sy, ex, ey, ex, ey, 14, G.shade(C_GREY, k))
    stick(sx, sy, lerp(sx, ex, 0.25), lerp(sy, ey, 0.25), lerp(sx, ex, 0.5), lerp(sy, ey, 0.5), 11.5, G.shade(C_CYAN, k - 0.1))
    G.polyline({ lerp(sx, ex, 0.3), lerp(sy, ey, 0.3) + 3, lerp(sx, ex, 0.55), lerp(sy, ey, 0.55) + 3 }, 1.3, C_TRACE)
    G.oellipse(ex, ey, 6, 5.5, G.shade(C_GREY, k), 2)
    stick(ex, ey, ex, ey, hx, hy, 20, G.shade(C_GREY, k))
    G.line(lerp(ex, hx, 0.4), lerp(ey, hy, 0.4) - 3, lerp(ex, hx, 0.9), lerp(ey, hy, 0.9) - 3, 1.3, C_TRACE)
    if front and p.move == 5 then
        -- the Sonic Cannon: forearm becomes a barrel
        G.glow(hx + 6, hy, 30, H(0x9FE8FF), 0.9)
        G.oellipse(hx + 4, hy, 8, 8, C_GREY, 2)
        G.circle(hx + 4, hy, 5, H(0xDDF8FF))
    else
        G.oellipse(hx, hy, 10, 8, G.shade(C_LIGHT, k), 1.7)
        G.line(hx - 3, hy - 4, hx + 3, hy - 4, 1.4, C_DARK)
        G.line(hx - 3, hy + 2, hx + 3, hy + 2, 1.4, C_DARK)
    end
end

local function shoulderPad(x: number, y: number, k: number)
    G.poly({
        x - 13, y + 8,
        x - 12, y - 4,
        x - 6, y - 11,
        x + 7, y - 12,
        x + 13, y - 4,
        x + 14, y + 8,
    }, G.shade(C_GREY, k), 2.5)
    local hex: { number } = {}
    for i = 0, 5 do
        local a = i / 6 * math.pi * 2 + math.pi / 6
        table.insert(hex, x + math.cos(a) * 4)
        table.insert(hex, y - 3 + math.sin(a) * 4)
    end
    G.poly(hex, C_DARK, 1.4)
    G.circle(x, y - 3, 1.8, C_GREY)
end

local function cyborg(p: P.Pose, titleFacing: boolean)
    frameBegin(p, 0, 26)
    local b = bob(p)
    local hipY, sh = -44 + b, -93 + b
    leanBegin(p, hipY)
    if titleFacing then
        cyborgArm(p, false, -28, sh + 9, -34, hipY + 1)
        shoulderPad(-29, sh + 2, -0.15)
    else
        cyborgArm(p, false, 13, sh + 9, 22, hipY - 7)
        shoulderPad(14, sh + 2, -0.15)
    end
    G.restore()
    -- legs
    local ffx, ffy = foot(p, true, 8, hipY, 11)
    local bfx, bfy = foot(p, false, -7, hipY, -9)
    for i = 1, 2 do
        local hx = if i == 1 then -7 else 8
        local fx = if i == 1 then bfx else ffx
        local fy = if i == 1 then bfy else ffy
        local k = if i == 1 then -0.15 else 0
        local kx, ky = legJoint(p, hx, hipY, fx, fy)
        stick(hx, hipY, kx, ky, fx, fy - 4, 11.5, G.shade(C_GREY, k))
        stick(hx, hipY + 2, lerp(hx, kx, 0.4), lerp(hipY, ky, 0.4), lerp(hx, kx, 0.6), lerp(hipY, ky, 0.6), 12, G.shade(C_DARK, k - 0.15))
        stick(kx, ky + 2, fx, fy - 10, fx, fy - 5, 16, G.shade(C_LIGHT, k))
        G.oellipse(fx + 3.5, fy - 4, 11, 5, G.shade(C_LIGHT, k), 1.7)
        G.line(fx - 2, fy - 5.5, fx + 8, fy - 5.5, 1.6, C_DARK)
    end
    leanBegin(p, hipY)
    -- torso
    if titleFacing then
        G.contour({ -27, sh - 4, -10, sh - 9, 12, sh - 9, 27, sh - 4,
            26, sh + 20, 21, hipY - 3, 14, hipY + 3,
            6, hipY + 7, -8, hipY + 7, -15, hipY + 2,
            -23, hipY - 9, -27, sh + 13, -27, sh - 4,
        }, C_GREY, 2)
    else
        G.contour({ -18, sh - 4, -5, sh - 9, 12, sh - 9, 23, sh - 4,
            26, sh + 20, 21, hipY - 3, 14, hipY + 3,
            6, hipY + 7, -8, hipY + 7, -15, hipY + 2,
            -18, hipY - 9, -20, sh + 13, -18, sh - 4,
        }, C_GREY, 2)
    end
    -- chest plate and belly
    if titleFacing then
        G.contour({ -23, sh - 2, -9, sh - 5, 12, sh - 5, 23, sh - 2,
            22, sh + 7, 19, sh + 19, 16, sh + 24,
            5, sh + 27, -8, sh + 27, -17, sh + 23,
            -21, sh + 14, -23, sh + 6, -23, sh - 2,
        }, C_LIGHT, 1.5)
        G.line(0, sh + 1, 0, sh + 23, 1.3, C_DARK)
        G.oellipse(0, sh + 29, 5, 3, C_CYAN, 1.2)
        G.circle(-1, sh + 28, 1, G.WHITE)
    else
        G.contour({ 2, sh - 2, 10, sh - 5, 16, sh - 5, 23, sh - 2,
            22, sh + 7, 19, sh + 19, 16, sh + 24,
            12, sh + 27, 4, sh + 27, 0, sh + 23,
            -2, sh + 14, 0, sh + 6, 2, sh - 2,
        }, C_LIGHT, 1.5)
        G.line(15, sh + 1, 12, sh + 23, 1.3, C_DARK)
        G.oellipse(10, sh + 29, 4, 3, C_CYAN, 1.2)
        G.circle(9, sh + 28, 1, G.WHITE)
    end
    -- belt
    G.rrect(-14, hipY - 8, 28, 9, 3, C_DARK, 2)
    G.rrect(-5, hipY - 7, 10, 7, 2, C_GREY, 1.5)
    scaleAt(2, sh - 24, 1.0)
    if titleFacing then
        cyborgHead(2, sh - 24, p.hurt or p.ko, p.t)
    else
        Profile.cyborg(5, sh - 24, p.hurt or p.ko)
    end
    G.restore()
    if titleFacing then
        cyborgArm(p, true, 29, sh + 9, 35, hipY + 1)
        shoulderPad(30, sh + 2, 0)
    else
        cyborgArm(p, true, -5, sh + 9, 10, hipY + 1)
        shoulderPad(-5, sh + 2, 0)
    end
    G.restore()
    G.restore()
end

-- Beast Boy ------------------------------------------------------------------------

local B_SKIN = H(0xA2E84A)
local B_HAIR = H(0x487A53)
local B_SUIT = H(0x101018)
local B_MAGENTA = H(0xC800A0)
local B_GREY = H(0xC0B8C0)

local function beastHead(hx: number, hy: number, hurt: boolean, t: number)
    G.save()
    G.translate(hx, hy)
    -- Wide, side-pointing ears and a low swept fringe.
    G.contour({ -20, -7,
        -26, -10, -30, -15, -35, -17,
        -30, -8, -32, 5, -24, 8,
        -19, 7, -17, 0, -20, -7,
    }, B_SKIN, 1.6)
    G.contour({ 20, -7,
        26, -10, 30, -15, 35, -17,
        30, -8, 32, 5, 24, 8,
        19, 7, 17, 0, 20, -7,
    }, B_SKIN, 1.6)
    G.line(-28, -7, -25, 3, 1.2, G.shade(B_SKIN, -0.25))
    G.line(28, -7, 25, 3, 1.2, G.shade(B_SKIN, -0.25))
    G.contour({ -23, -13,
        -12, -23, 12, -23, 23, -12,
        27, -2, 25, 12, 14, 18,
        5, 23, -12, 22, -21, 15,
        -27, 8, -26, -6, -23, -13,
    }, B_SKIN, 1.7)
    G.poly({ -25, -1, -28, -15, -34, -12, -24, -24, -29, -23,
        -12, -31, 9, -30, 21, -34, 18, -27, 26, -27, 23, -19,
        22, -5, 17, -15, 8, -20, -1, -18, -9, -13, -7, -22,
        -18, -13, -16, -21, -24, -10 }, B_HAIR, 1.5)
    G.oellipse(-9, 1, 7, 7, G.WHITE, 1.1)
    G.oellipse(9, 0, 7, 7, G.WHITE, 1.1)
    G.ellipse(-6.5, 2, 2.1, 3.5, INK)
    G.ellipse(11, 1, 2.1, 3.5, INK)
    G.poly({ -17, -8, -1, -7, -1, -1, -17, -2 }, B_SKIN)
    G.poly({ 1, -8, 17, -10, 17, -3, 1, 0 }, B_SKIN)
    G.line(-16, -2, -2, -1, 1.8, INK)
    G.line(2, 0, 16, -3, 1.8, INK)
    G.polyline({ -1, 6, 2, 7, 4, 5 }, 1.1, INK)
    if hurt then
        G.line(-7, 13, 10, 13, 1.4, INK)
    else
        G.contour({ -12, 10,
            -3, 15, 9, 14, 17, 8,
            12, 19, -4, 21, -12, 10,
        }, G.WHITE, 1.1)
        G.poly({ 9, 12, 13, 10, 11, 16 }, G.WHITE, 0.6)
    end
    G.restore()
end

local function beast(p: P.Pose, titleFacing: boolean)
    frameBegin(p, 0, 14)
    local b = bob(p)
    local hipY, sh = -28 + b, -56 + b
    leanBegin(p, hipY)
    local bsx: number, bsy: number, bhx: number, bhy: number
    if titleFacing then
        bsx, bsy = -8, sh + 3
        bhx, bhy = hand(p, false, bsx, bsy, -11, hipY - 3, 18)
    else
        bsx, bsy = 5, sh + 4
        bhx, bhy = hand(p, false, bsx, bsy, 16, hipY - 8, 26)
    end
    local bex, bey = joint(bsx, bsy, bhx, bhy, 4)
    stick(bsx, bsy, bex, bey, bhx, bhy, 4, B_SUIT)
    G.oellipse(lerp(bex, bhx, 0.6), lerp(bey, bhy, 0.6), 4, 3.5, B_GREY, 1.6)
    mitt(bhx, bhy, 4.6, G.shade(B_GREY, -0.08), false)
    G.restore()
    local ffx, ffy = foot(p, true, 3, hipY, 4)
    local bfx, bfy = foot(p, false, -3, hipY, -3)
    for i = 1, 2 do
        local hx = if i == 1 then -3 else 3
        local fx = if i == 1 then bfx else ffx
        local fy = if i == 1 then bfy else ffy
        local kx, ky = legJoint(p, hx, hipY, fx, fy)
        stick(hx, hipY, kx, ky, fx, fy - 3, 4.5, B_SUIT)
        G.oellipse(fx + 2, fy - 2.5, 5, 3, B_GREY, 1.8)
    end
    leanBegin(p, hipY)
    G.poly({ -9, sh - 1, 10, sh - 1, 8, hipY + 1, -7, hipY + 1 }, B_SUIT, 2.5)
    -- magenta collar, chest strap and hip straps
    G.rrect(-5, sh - 2, 11, 4, 2, B_MAGENTA, 1.4)
    if titleFacing then
        G.rrect(-2, sh, 4.5, hipY - sh + 1, 1.6, B_MAGENTA, 1.2)
    else
        G.poly({ 6, sh, 10, sh, 8, hipY + 1, 4, hipY + 1 }, B_MAGENTA, 1)
    end
    G.rrect(-2, hipY, 4.5, 7, 1.6, B_MAGENTA, 1.2)
    -- grey shoulder caps and belt
    if titleFacing then
        G.oellipse(-8, sh + 1, 4, 3, B_GREY, 1.6)
        G.oellipse(9, sh + 1, 4.5, 3.5, B_GREY, 1.6)
    else
        G.oellipse(7, sh + 1, 3, 3, B_GREY, 1.2)
        G.oellipse(-2, sh + 1, 4.5, 3.5, B_GREY, 1.4)
    end
    G.rrect(-8, hipY - 4, 16, 4.5, 2, B_GREY, 1.5)
    G.oellipse(0, hipY - 2, 2.6, 2.6, G.shade(B_GREY, 0.15), 1.2)
    scaleAt(2, sh - 24, 1.0)
    if titleFacing then
        beastHead(2, sh - 24, p.hurt or p.ko, p.t)
    else
        Profile.beast(4, sh - 24, p.hurt or p.ko)
    end
    G.restore()
    local fsx: number, fsy: number, fhx: number, fhy: number
    if titleFacing then
        fsx, fsy = 9, sh + 3
        fhx, fhy = hand(p, true, fsx, fsy, 12, hipY - 3, 20)
    else
        fsx, fsy = -2, sh + 3
        fhx, fhy = hand(p, true, fsx, fsy, 13, hipY - 5, 31)
    end
    local fex, fey = joint(fsx, fsy, fhx, fhy, -4)
    stick(fsx, fsy, fex, fey, fhx, fhy, 4, B_SUIT)
    G.oellipse(lerp(fex, fhx, 0.6), lerp(fey, fhy, 0.6), 4, 3.5, B_GREY, 1.6)
    mitt(fhx, fhy, 4.8, B_GREY, false)
    G.restore()
    G.restore()
end

local function rhino(p: P.Pose)
    -- Beast Boy's charge: a green rhino.
    local g = B_SKIN
    local d = G.shade(g, -0.25)
    local s = math.sin(p.t * 22)
    G.limb(-24, -30, -24 - s * 8, -14, -24 - s * 10, 0, 12, d)
    G.limb(16, -30, 16 + s * 8, -14, 16 + s * 10, 0, 12, d)
    G.oellipse(-2, -40, 44, 26, g)
    G.limb(-20, -30, -20 + s * 8, -14, -20 + s * 10, 0, 12, g)
    G.limb(20, -30, 20 - s * 8, -14, 20 - s * 10, 0, 12, g)
    G.oellipse(44, -46, 20, 16, g)
    G.poly({ 56, -58, 70, -86, 66, -52 }, H(0xF2EAD0), 2)
    G.poly({ 34, -60, 30, -74, 42, -62 }, g, 2)
    G.circle(50, -52, 2.5, INK)
    G.line(-44, -44, -54, -36, 3, INK)
    G.glow(0, -40, 70, H(0x9CFF6A), 0.25)
end

-- Raven ----------------------------------------------------------------------------

local V_CLOAK = H(0x4838A0)
local V_FOLD = H(0x322880)
local V_SKIN = H(0xD0C8C8)
local V_IRIS = H(0x9B6BD6)

local function ravenHead(hx: number, hy: number, hurt: boolean, t: number)
    G.save()
    G.translate(hx, hy)
    G.contour({ -27, 5,
        -28, -14, -13, -28, 3, -29,
        24, -32, 27, -13, 26, 6,
        29, 13, 28, 17, 30, 20,
        15, 29, -9, 29, -27, 5,
    }, V_CLOAK, 1.8)
    -- Angular shadow follows the hood peak; cheek and chin stay rounded.
    G.contour({ -20, 5,
        -15, -6, -8, -12, -3, -17,
        1, -13, 6, -6, 10, -2,
        15, -4, 20, -10, 21, -14,
        23, -2, 23, 13, 19, 19,
        9, 27, -11, 23, -20, 5,
    }, INK, 0.7)
    G.contour({ -15, 13,
        -8, 15, -3, 10, 0, 8,
        5, 13, 11, 17, 20, 13,
        17, 26, -5, 28, -15, 13,
    }, V_SKIN)
    if hurt then
        G.line(-15, 3, -5, 7, 2, G.WHITE)
        G.line(7, 8, 18, 4, 2, G.WHITE)
    else
        G.contour({ -17, 0,
            -12, 4, -6, 6, -2, 6,
            -6, 14, -15, 12, -17, 0,
        }, G.WHITE)
        G.contour({ 5, 7,
            10, 7, 17, 5, 21, 2,
            21, 14, 9, 16, 5, 7,
        }, G.WHITE)
        G.ellipse(-8, 6.5, 2.1, 3.3, V_IRIS)
        G.ellipse(13, 8, 2.1, 3.3, V_IRIS)
        G.ellipse(-8, 6, 1, 2.2, INK)
        G.ellipse(13, 7.5, 1, 2.2, INK)
    end
    G.polyline({ -1, 18, 3, 17, 7, 18 }, 1.1, INK)
    G.restore()
end

local function raven(p: P.Pose, titleFacing: boolean)
    frameBegin(p, 3, 18)
    local b = bob(p) * 0.5
    local sway = math.sin(p.phase - 0.5) * p.walk * 5 + math.abs(p.ext) * 8 + (if p.air then 4 else 0)
    local top = -63 + b
    leanBegin(p, -40)
    local showArms = p.move ~= 0 or p.hurt
    local fsx: number, fsy: number, bsx: number, bsy: number
    if titleFacing then
        fsx, fsy = 8, top + 8
        bsx, bsy = -6, top + 8
    else
        fsx, fsy = 2, top + 8
        bsx, bsy = 8, top + 8
    end
    local fhx, fhy = hand(p, true, fsx, fsy, 12, top + 24, 24)
    local bhx: number, bhy: number
    if titleFacing then
        bhx, bhy = hand(p, false, bsx, bsy, -11, top + 24, 22)
    else
        bhx, bhy = hand(p, false, bsx, bsy, 19, top + 21, 24)
    end
    if p.move == 5 then
        if titleFacing then
            fhx, fhy = 37, top - 35
            bhx, bhy = -35, top - 37
        else
            fhx, fhy = 46, top - 12
            bhx, bhy = 46, top - 38
        end
    end
    if showArms then
        local ex, ey = joint(bsx, bsy, bhx, bhy, 4)
        stick(bsx, bsy, ex, ey, bhx, bhy, 6.5, G.shade(V_CLOAK, -0.15))
        G.oellipse(bhx, bhy, 4.4, 4.4, G.shade(V_SKIN, -0.15), 2)
    end
    -- the long cloak, a smooth bell with a centre seam
    if titleFacing then
        G.contour({ -12, top, -3, top - 4, 9, top - 4, 14, top,
            16, top + 28, 17, -13, 27 + sway, -3,
            14, 5, -11, 5, -23 - sway, -3,
            -17, -23, -16, top + 16, -12, top,
        }, V_CLOAK, 1.8)
        G.line(1, top + 6, 1, -1, 2, INK)
    else
        G.contour({ -12, top, -3, top - 4, 9, top - 4, 14, top,
            16, top + 28, 14, -13, 17, -3,
            4, 5, -18, 5, -32 - sway, -3,
            -17, -23, -16, top + 16, -12, top,
        }, V_CLOAK, 1.8)
        G.line(11, top + 6, 12, -1, 1.5, INK)
    end
    G.line(-8, top + 10, -12 - sway * 0.5, -3, 1.8, V_FOLD)
    if titleFacing then
        G.line(10, top + 10, 14, -3, 1.8, V_FOLD)
    else
        G.line(-1, top + 10, -5, -3, 1.8, V_FOLD)
    end
    -- Let the kick emerge from the cloak so its direction matches the hitbox.
    if p.move == 3 or p.move == 4 then
        local fx, fy = foot(p, true, 3, -30, 5)
        local kx, ky = joint(3, -32, fx, fy - 3, -3)
        stick(3, -32, kx, ky, fx, fy - 3, 6, INK)
        G.oellipse(fx + 4, fy - 3, 7, 4, V_CLOAK, 1.4)
    end
    scaleAt(1, top - 26, 1.0)
    if titleFacing then
        ravenHead(1, top - 26, p.hurt or p.ko, p.t)
    else
        Profile.raven(4, top - 26, p.hurt or p.ko)
    end
    G.restore()
    -- clasp at the throat
    if titleFacing then
        G.poly({ 1, top + 3, 5.5, top + 8, 1, top + 13.5, -3.5, top + 8 }, H(0xD8A93A), 1.5)
        G.circle(1, top + 8, 1.6, H(0xD8203A))
    else
        G.poly({ 12, top + 3, 16, top + 8, 12, top + 13.5, 8, top + 8 }, H(0xD8A93A), 1.5)
        G.circle(12, top + 8, 1.6, H(0xD8203A))
    end
    if showArms then
        local ex, ey = joint(fsx, fsy, fhx, fhy, -4)
        stick(fsx, fsy, ex, ey, fhx, fhy, 6.5, V_CLOAK)
        G.oellipse(fhx, fhy, 4.6, 4.6, V_SKIN, 2)
        glowHands(p, fhx, fhy, bhx, bhy, H(0x8A3CFF))
    end
    G.restore()
    G.restore()
end

-- Starfire -------------------------------------------------------------------------

local S_SKIN = H(0xFFBD79)
local S_HAIR = H(0xE00078)
local S_HAIR2 = H(0xB00060)
local S_PURPLE = H(0x8541B5)
local S_SKIRT = H(0x602088)
local S_SILVER = H(0xC9D3E8)
local S_GEM = H(0x28C048)

-- The mass of hair behind the head, drawn before the head.
local function starfireHairBack(hx: number, hy: number, t: number, walk: number, bottom: number)
    local sway = math.sin(t * 2.6) * 2 + walk * 4
    G.save()
    G.translate(hx, hy)
    local length = bottom - hy
    G.contour({ -20, -16,
        -29, -5, -31, 22, -30, length - 2,
        -35, length + 11, -28, length + 17, -24, length + 20,
        -23, length + 13, -20, length + 9, -16, length + 5,
        -6, length + 21, 23 + sway, length + 27, 31 + sway, length + 8,
        39 + sway, length + 3, 38 + sway, length - 8, 35 + sway, length - 18,
        32, 11, 25, -12, 20, -19,
        10, -30, -9, -28, -20, -16,
    }, S_HAIR, 1.8)
    G.polyline({ -23, 12, -25, length - 5, -24, length + 9 }, 1.2, S_HAIR2)
    G.polyline({ 21, 14, 29 + sway, length - 2, 27 + sway, length + 11 }, 1.2, S_HAIR2)
    G.restore()
end

local function starfireHairTop(hx: number, hy: number)
    G.save()
    G.translate(hx, hy)
    G.contour({ -24, 0,
        -29, -14, -23, -28, -12, -27,
        -5, -29, -2, -25, 0, -24,
        7, -30, 18, -29, 25, -23,
        27, -12, 25, -6, 23, -1,
        23, -10, 19, -16, 14, -18,
        8, -18, 8, -10, 3, -11,
        0, -11, -1, -18, -9, -19,
        -17, -22, -19, -11, -24, 0,
    }, S_HAIR, 1.5)
    G.restore()
end

local function starfireHead(hx: number, hy: number, hurt: boolean, t: number)
    G.save()
    G.translate(hx, hy)
    G.oellipse(-24, 4, 3.5, 6, S_SKIN, 1.3)
    G.oellipse(24, 4, 3.5, 6, S_SKIN, 1.3)
    G.contour({ -23, -13,
        -13, -24, 13, -24, 23, -13,
        28, 0, 23, 18, 1, 25,
        -20, 20, -29, 4, -23, -13,
    }, S_SKIN, 1.7)
    local function eye(x: number, y: number, flick: number)
        G.oellipse(x, y, 7.7, 10, H(0xC7FF77), 1)
        G.ellipse(x + 0.6, y, 4.7, 7.7, H(0x54C925))
        G.ellipse(x + 1, y - 0.3, 2.6, 6, H(0x174C20))
        G.ellipse(x - 1.4, y - 4, 1.7, 2.4, G.WHITE)
        local edge = x + flick * 6.5
        G.polyline({ x - flick * 5, y - 7, x, y - 10, edge, y - 7, edge + flick * 3, y - 11 }, 1.8, INK)
        G.line(edge, y - 5, edge + flick * 4, y - 7, 1.5, INK)
    end
    eye(-10, 1, -1)
    eye(10, 1, 1)
    G.ellipse(-9, -13, 3, 1.7, S_HAIR)
    G.ellipse(10, -13, 3, 1.7, S_HAIR)
    if hurt then
        G.oellipse(1, 17, 2.5, 2, H(0x5E1426), 1)
    else
        G.polyline({ -5, 17, 1, 18, 7, 16 }, 1.2, INK)
    end
    G.restore()
end

local function starfire(p: P.Pose, titleFacing: boolean)
    frameBegin(p, 10, 16)
    local b = bob(p) * 0.4
    local hipY, sh = -51 + b, -80 + b
    local hx, hy = 2, sh - 28
    scaleAt(hx, hy, 1.0)
    if titleFacing then
        starfireHairBack(hx, hy, p.t, p.walk, -48)
    else
        Profile.starfireHair(hx, hy, p.t, p.walk + math.abs(p.ext) * 0.65)
    end
    G.restore()
    leanBegin(p, hipY)
    local bsx: number, bsy: number, bhx: number, bhy: number
    if titleFacing then
        bsx, bsy = -7, sh + 3
        bhx, bhy = hand(p, false, bsx, bsy, -11, hipY - 2, 24)
    else
        bsx, bsy = 5, sh + 4
        bhx, bhy = hand(p, false, bsx, bsy, 17, hipY - 8, 28)
    end
    local bex, bey = joint(bsx, bsy, bhx, bhy, 4)
    stick(bsx, bsy, bex, bey, bhx, bhy, 3.6, G.shade(S_SKIN, -0.12))
    G.oellipse(lerp(bex, bhx, 0.55), lerp(bey, bhy, 0.55), 4.2, 3.8, G.shade(S_SILVER, -0.15), 1.6)
    G.oellipse(bhx, bhy, 3.8, 3.8, G.shade(S_SKIN, -0.12), 1.8)
    G.restore()
    -- legs: floating, toes pointed
    local ffx, ffy = foot(p, true, 3, hipY, 5)
    local bfx, bfy = foot(p, false, -3, hipY, -2)
    for i = 1, 2 do
        local x = if i == 1 then -3 else 3
        local fx = if i == 1 then bfx else ffx
        local fy = if i == 1 then bfy else ffy
        local k = if i == 1 then -0.15 else 0
        local kx, ky = legJoint(p, x, hipY, fx, fy)
        stick(x, hipY, kx, ky, fx, fy - 4, 5.5, G.shade(S_SKIN, k))
        stick(kx, ky, lerp(kx, fx, 0.5), lerp(ky, fy, 0.5), fx, fy - 4, 6, G.shade(S_SKIRT, k))
        G.oellipse(kx, ky, 3.6, 3.2, G.shade(S_SILVER, k), 1.6)
        G.poly({ fx - 3, fy - 7, fx + 4, fy - 6, fx + 2, fy + 2 }, G.shade(S_SKIRT, k), 1.8)
    end
    leanBegin(p, hipY)
    -- silver shoulder armour and purple collar
    G.poly({ -8, sh - 1, 9, sh - 1, 7, hipY + 1, -6, hipY + 1 }, S_SKIN, 2.2)
    G.rrect(-7, sh - 2, 15, 5, 2.5, S_SILVER, 1.8)
    G.oellipse(0, sh, 5, 3.5, S_PURPLE, 1.6)
    G.poly({ -7, sh + 2, 8, sh + 2, 6, sh + 13, -5, sh + 13 }, S_PURPLE, 2)
    if titleFacing then
        G.oellipse(0, sh + 2, 3, 3, S_SILVER, 1)
        G.circle(0, sh + 2, 1.5, S_GEM)
    else
        G.oellipse(8, sh + 2, 2.5, 3, S_SILVER, 1)
        G.circle(8, sh + 2, 1.5, S_GEM)
    end
    -- purple skirt with a silver front plate
    G.poly({ -6, hipY - 3, 7, hipY - 3, 10, hipY + 8, -8, hipY + 8 }, S_SKIRT, 2.2)
    G.rrect(-6, hipY - 4, 13, 3, 1, S_SILVER, 1)
    scaleAt(hx, hy, 1.0)
    if titleFacing then
        starfireHead(hx, hy, p.hurt or p.ko, p.t)
        starfireHairTop(hx, hy)
    else
        Profile.starfire(hx + 3, hy, p.hurt or p.ko)
    end
    G.restore()
    -- front arm with its silver gauntlet
    local fsx: number, fsy: number, fhx: number, fhy: number
    if titleFacing then
        fsx, fsy = 8, sh + 3
        fhx, fhy = hand(p, true, fsx, fsy, 12, hipY - 2, 26)
    else
        fsx, fsy = 0, sh + 3
        fhx, fhy = hand(p, true, fsx, fsy, 12, hipY - 5, 34)
    end
    local fex, fey = joint(fsx, fsy, fhx, fhy, -4)
    G.oellipse(fsx, fsy - 1, 4.2, 3.8, S_SILVER, 1.8)
    stick(fsx, fsy, fex, fey, fhx, fhy, 3.6, S_SKIN)
    G.oellipse(lerp(fex, fhx, 0.55), lerp(fey, fhy, 0.55), 4.6, 4.2, S_SILVER, 1.8)
    G.circle(lerp(fex, fhx, 0.55), lerp(fey, fhy, 0.55), 1.6, S_GEM)
    G.oellipse(fhx, fhy, 4, 4, S_SKIN, 1.8)
    glowHands(p, fhx, fhy, bhx, bhy, H(0x5CFF6A))
    G.restore()
    G.restore()
end

-- Public -----------------------------------------------------------------------------

HX.HEIGHTS = { robin = 130, cyborg = 143, starfire = 149, raven = 124, beast = 115 } :: { [string]: number }

-- Special-projectile attachment points use the same posed hands as the art.
-- Coordinates are local to the unmirrored fighter, with negative y upward.
function HX.projectileOrigin(kind: string, p: P.Pose): (number, number)
    local b = bob(p)
    if kind == 'cyborg' then
        local x, y = hand(p, true, -5, -84 + b, 10, -43 + b, 64)
        return x + 4, y
    elseif kind == 'starfire' then
        local x, y = hand(p, true, 0, -77 + b * 0.4, 12, -56 + b * 0.4, 34)
        return x + 4, y - 10 - math.sin(p.t * 2.6) * 3
    end
    local x, y = hand(p, true, -1, -59 + b, 14, -41 + b, 33)
    return x + 4, y
end

function HX.isHero(kind: string): boolean
    return HX.HEIGHTS[kind] ~= nil
end

function HX.draw(kind: string, p: P.Pose, titleFacing: boolean?)
    if kind == 'robin' then
        robin(p, titleFacing == true)
    elseif kind == 'cyborg' then
        cyborg(p, titleFacing == true)
    elseif kind == 'starfire' then
        starfire(p, titleFacing == true)
    elseif kind == 'raven' then
        raven(p, titleFacing == true)
    elseif kind == 'beast' then
        if p.move == 5 and p.down <= 0 then
            rhino(p)
        else
            beast(p, titleFacing == true)
        end
    end
end

-- Head only, centred at (x, y), for the HUD and select screen.
function HX.portrait(kind: string, x: number, y: number, s: number, t: number)
    G.save()
    G.translate(x, y)
    if kind == 'robin' then
        G.scale(s * 1.5, s * 1.5)
        robinHead(-1, 4, false, t)
    elseif kind == 'cyborg' then
        G.scale(s * 1.35, s * 1.35)
        cyborgHead(0, 1, false, t)
    elseif kind == 'starfire' then
        G.scale(s * 1.4, s * 1.4)
        starfireHairBack(0, 3, t, 0, 26)
        starfireHead(0, 3, false, t)
        starfireHairTop(0, 3)
    elseif kind == 'raven' then
        G.scale(s * 1.4, s * 1.4)
        ravenHead(0, 2, false, t)
    elseif kind == 'beast' then
        G.scale(s * 1.3, s * 1.3)
        beastHead(0, 3, false, t)
    end
    G.restore()
end

return HX
