-- Character, prop, effect and stage art. Everything is drawn from paths in
-- local coordinates: fighters stand with their feet at (0, 0) facing +x, and
-- the game places and mirrors them with transforms.
--
-- The Titans live in heroes.luau; this file draws the villains, props,
-- effects and the Jump City stage.
local G = require('gfx')
local L = require('localization')
local P = require('pose')
local HX = require('heroes')

local A = {}
local H = G.hex
local INK = G.INK

export type Pose = P.Pose

A.newPose = P.new
A.projectileOrigin = HX.projectileOrigin

-- Villains -------------------------------------------------------------------------

type Rig = {
    headR: number,
    bodyW: number,
    bodyH: number,
    legLen: number,
    armLen: number,
    th: number,
    torso: Color,
    arm: Color,
    hand: Color,
    leg: Color,
    boot: Color,
}

local RIGS: { [string]: Rig } = {
    bot = {
        headR = 16, bodyW = 28, bodyH = 34, legLen = 32, armLen = 27, th = 9,
        torso = H(0x2A2A2E), arm = H(0x55585F), hand = H(0x1E1E22), leg = H(0x3A3B40), boot = H(0x16161A),
    },
    heavy = {
        headR = 17, bodyW = 46, bodyH = 38, legLen = 30, armLen = 30, th = 15,
        torso = H(0x6E7480), arm = H(0x5A5F69), hand = H(0x2F3238), leg = H(0x4C5058), boot = H(0x25272C),
    },
}

-- Different silhouettes, colors and equipment keep mixed waves readable.
RIGS.runner = { headR = 14, bodyW = 23, bodyH = 31, legLen = 36, armLen = 30, th = 7,
    torso = H(0x813E47), arm = H(0xB55A64), hand = H(0x252535), leg = H(0x4E293B), boot = H(0x251C30) }
RIGS.gunner = { headR = 15, bodyW = 32, bodyH = 34, legLen = 30, armLen = 28, th = 10,
    torso = H(0x285878), arm = H(0x3C8BA4), hand = H(0x183644), leg = H(0x304659), boot = H(0x172936) }
RIGS.shield = { headR = 16, bodyW = 38, bodyH = 39, legLen = 28, armLen = 26, th = 12,
    torso = H(0x33576B), arm = H(0x548195), hand = H(0x1D344A), leg = H(0x344455), boot = H(0x172736) }
RIGS.shock = { headR = 15, bodyW = 31, bodyH = 34, legLen = 31, armLen = 29, th = 10,
    torso = H(0x56377C), arm = H(0x7A5CA0), hand = H(0x342442), leg = H(0x45375C), boot = H(0x271E39) }
RIGS.mammoth = { headR = 18, bodyW = 61, bodyH = 48, legLen = 29, armLen = 38, th = 21,
    torso = H(0x382D3A), arm = H(0xDCA073), hand = H(0xDCA073), leg = H(0x545464), boot = H(0x272534) }
RIGS.jinx = { headR = 18, bodyW = 23, bodyH = 31, legLen = 40, armLen = 29, th = 7,
    torso = H(0x301F42), arm = H(0xDDD0E8), hand = H(0xDDD0E8), leg = H(0x936F9E), boot = H(0x272034) }
RIGS.slade = { headR = 17, bodyW = 35, bodyH = 40, legLen = 37, armLen = 33, th = 12,
    torso = H(0x3D424D), arm = H(0x59616E), hand = H(0x20252D), leg = H(0x333B46), boot = H(0x171D28) }

-- Height of a figure's head top above its feet, for placing name tags.
function A.height(kind: string): number
    local h = HX.HEIGHTS[kind]
    if h then
        return h
    end
    if kind == 'boss' then
        return 128
    end
    local r = RIGS[kind] or RIGS.bot
    return r.legLen + r.bodyH + r.headR * 2 + 4
end

local function headBot(hx: number, hy: number, r: number)
    -- the two-tone mask
    G.ellipse(hx, hy, r + 2.5, r * 1.1 + 2.5, INK)
    G.save()
    G.clipEllipse(hx, hy, r, r * 1.1)
    G.ellipse(hx, hy, r, r * 1.1, H(0xE27B23))
    G.rect(hx - r * 1.2, hy - r * 1.2, r * 1.28, r * 2.4, H(0x151518))
    G.line(hx + r * 0.08, hy - r * 1.2, hx + r * 0.08, hy + r * 1.2, 2, INK)
    G.restore()
    G.ellipse(hx + r * 0.55, hy - r * 0.12, r * 0.2, r * 0.1, INK)
    G.ellipse(hx + r * 0.6, hy - r * 0.14, r * 0.05, r * 0.04, G.WHITE)
end

local function headHeavy(hx: number, hy: number, r: number)
    G.ellipse(hx, hy, r + 2.5, r + 2.5, INK)
    G.save()
    G.clipEllipse(hx, hy, r, r)
    G.ellipse(hx, hy, r, r, H(0x7A808C))
    G.rect(hx - r * 0.3, hy - r * 0.4, r * 1.5, r * 0.45, H(0xFF8A1E))
    G.restore()
    G.glow(hx + r * 0.6, hy - r * 0.18, r * 0.9, H(0xFF8A1E), 0.4)
    G.line(hx - r * 0.2, hy + r * 0.45, hx + r * 0.8, hy + r * 0.45, 2, INK)
end

local function headSpecial(kind: string, hx: number, hy: number, r: number)
    if kind == 'jinx' then
        G.poly({ hx-r, hy+8, hx-r-13, hy-28, hx-2, hy-15, hx+15, hy-30, hx+r+4, hy+10 }, H(0xF795D4), 2)
        G.oellipse(hx, hy, r, r*.88, H(0xE1D0E7), 2)
        G.poly({ hx-r, hy-8, hx, hy-22, hx+r, hy-9, hx+3, hy-7, hx-2, hy+2 }, H(0xD56AAD), 2)
        G.line(hx-6, hy+2, hx-1, hy+3, 3, H(0xC62276))
        G.line(hx+6, hy+3, hx+12, hy+1, 3, H(0xC62276))
        G.line(hx+1, hy+10, hx+8, hy+9, 2, INK)
    elseif kind == 'mammoth' then
        G.oellipse(hx-3, hy+4, r+9, r+10, H(0xA44326), 3)
        G.rrect(hx-r+2, hy-r+5, r*2, r*1.9, 7, H(0xE6AF80), 2)
        G.poly({ hx-r-5, hy-7, hx-r, hy-r-6, hx+8, hy-r-9, hx+r+5, hy-8, hx+3, hy-12 }, H(0xC75127), 2)
        G.line(hx-7, hy-1, hx, hy+1, 3, INK)
        G.line(hx+7, hy+1, hx+14, hy-2, 3, INK)
        G.rect(hx-2, hy+9, 16, 5, G.WHITE)
    elseif kind == 'slade' then
        headBot(hx, hy, r)
        G.line(hx-r-2, hy+8, hx-8, hy+16, 4, H(0x8F98A2))
        G.circle(hx-r+4, hy-8, 2, H(0xA5AEB9))
        G.circle(hx-r+4, hy+4, 2, H(0xA5AEB9))
    else
        G.rrect(hx-r, hy-r, r*2, r*1.9, if kind == 'runner' then 4 else 9, RIGS[kind].torso, 2.5)
        local glow = if kind == 'runner' then H(0xFF6B68) elseif kind == 'shock' then H(0xD38BFF) else H(0x60E9F5)
        G.rect(hx-7, hy-3, r+7, 5, glow)
        G.circle(hx+r-5, hy-1, 2, G.WHITE)
        if kind == 'runner' then
            G.poly({ hx-r, hy-6, hx-r-13, hy-18, hx+5, hy-r }, glow, 2)
        elseif kind == 'shock' then
            G.line(hx-9, hy-r, hx-13, hy-r-12, 3, glow)
            G.circle(hx-13, hy-r-12, 4, glow)
        elseif kind == 'gunner' then
            G.oellipse(hx+r-1, hy-1, 6, 7, glow, 2)
        end
    end
end

-- Portrait for HUD and select screen: head only, centred at (x, y).
function A.portrait(kind: string, x: number, y: number, s: number, t: number)
    if HX.isHero(kind) then
        HX.portrait(kind, x, y, s, t)
        return
    end
    G.save()
    G.translate(x, y)
    G.scale(s, s)
    if kind == 'heavy' then
        headHeavy(0, 0, RIGS.heavy.headR)
    else
        headBot(0, 0, RIGS.bot.headR)
    end
    G.restore()
end

local function limbWithHand(rig: Rig, sx: number, sy: number, hx: number, hy: number, back: boolean)
    local k = if back then -0.2 else 0
    local ex, ey = (sx + hx) / 2 + (if back then -3 else 2), (sy + hy) / 2 + 3
    G.limb(sx, sy, ex, ey, hx, hy, rig.th, G.shade(rig.arm, k))
    local hr = if rig.th > 12 then rig.th * 0.8 else rig.th * 0.7
    G.oellipse(hx, hy, hr, hr, G.shade(rig.hand, k), 2)
end

local function villainLeg(rig: Rig, hipX: number, hipY: number, fx: number, fy: number, back: boolean)
    local k = if back then -0.2 else 0
    local kx, ky = (hipX + fx) / 2 + 5, (hipY + fy) / 2
    G.limb(hipX, hipY, kx, ky, fx, fy, rig.th, G.shade(rig.leg, k))
    G.oellipse(fx + rig.th * 0.4, fy - rig.th * 0.35, rig.th * 0.95, rig.th * 0.58, G.shade(rig.boot, k), 2)
end

-- Slade bots and heavy bots share one side-on rig.
local function villain(kind: string, rig: Rig, p: Pose)
    local L = rig.legLen
    local s = math.sin(p.phase) * p.walk
    local c = math.cos(p.phase)
    local e = p.ext
    local ePos = math.max(0, e)
    local eNeg = math.max(0, -e)

    G.save()
    if p.down > 0 then
        G.translate(0, -rig.bodyW * 0.3 * p.down)
        G.rotate(-math.pi / 2 * p.down)
    end
    local bob = 0
    if not p.air then
        bob = math.abs(math.sin(p.phase)) * 2.5 * p.walk + math.sin(p.t * 2.4) * 1.2 * (1 - p.walk)
    end
    local hipY = -L + bob
    local shY = hipY - rig.bodyH + 4
    local lean = 0
    if p.move > 0 then
        lean = 0.12 * ePos - 0.08 * eNeg
    end
    if p.hurt then
        lean = -0.3
    end

    -- feet
    local fFx, fFy = 5 + s * 13, -math.max(0, c) * 6 * p.walk
    local bFx, bFy = -5 - s * 13, -math.max(0, -c) * 6 * p.walk
    if p.air then
        fFx, fFy = 10, hipY + L * 0.72
        bFx, bFy = -8, hipY + L * 0.85
    end

    -- hands
    local aL = rig.armLen
    local fSx, bSx, sY = rig.bodyW * 0.36, -rig.bodyW * 0.36, shY + 5
    local fHx, fHy = fSx + rig.th * 0.6 - s * 10, shY + aL
    local bHx, bHy = bSx - rig.th * 0.4 + s * 10, shY + aL - 3
    if p.move == 1 or p.move == 6 then
        fHx = 8 + ePos * (aL + 2) - eNeg * 16
        fHy = shY + 9 - ePos * 3
        bHx, bHy = 10, shY + 12
    end
    if p.hurt then
        fHx, fHy = -6, shY - 10
        bHx, bHy = -16, shY - 6
    end

    local function leanBegin()
        G.save()
        G.translate(0, hipY)
        G.rotate(lean)
        G.translate(0, -hipY)
    end

    leanBegin()
    limbWithHand(rig, bSx, sY, bHx, bHy, true)
    G.restore()
    villainLeg(rig, -3, hipY, bFx, bFy, true)
    villainLeg(rig, 3, hipY, fFx, fFy, false)
    leanBegin()
    local w = rig.bodyW
    local top = shY - 3
    local h = hipY - top + 6
    if kind == 'heavy' then
        G.rrect(-w / 2, top, w, h, 12, rig.torso, 2.5)
        for i = 0, 2 do
            G.line(-w / 2 + 10, top + 12 + i * 8, w / 2 - 10, top + 12 + i * 8, 3, H(0x3A3E46))
        end
        G.oellipse(0, top + 2, w * 0.55, 9, H(0xFF8A1E), 2)
        headHeavy(2, shY - rig.headR + 3, rig.headR)
    elseif kind ~= 'bot' then
        G.rrect(-w / 2, top, w, h, if kind == 'mammoth' then 16 else 7, rig.torso, 2.5)
        if kind == 'mammoth' then
            G.poly({ -22, top+3, -11, top+4, -8, top+22, 8, top+22, 11, top+4, 22, top+3, 19, top+34, -19, top+34 }, H(0xBD6439), 2)
            G.rect(-w/2, hipY-6, w, 7, H(0xA98558))
        elseif kind == 'jinx' then
            G.poly({ -10, hipY-12, 12, hipY-12, 23, hipY+9, -22, hipY+9 }, H(0x423052), 2)
            G.line(-8, top+9, 8, top+9, 3, H(0xEC7AC2))
        elseif kind == 'slade' then
            G.line(-14, top+2, 12, hipY-3, 7, H(0x222731))
            G.rrect(-21, top-2, 22, 14, 5, H(0xDA792E), 2)
            G.rect(-w/2, hipY-6, w, 7, H(0xA5A6A1))
        else
            local accent = if kind == 'runner' then H(0xFF7D78) elseif kind == 'shock' then H(0xC794F7) else H(0x60D9E8)
            G.poly({ -8, top+7, 8, top+7, 5, top+21, -5, top+21 }, accent, 2)
            if kind == 'shock' then
                G.line(-w/2-4, top+2, -w/2-4, hipY, 8, H(0x8FDFFA))
                for i=0,3 do G.line(-w/2-10, top+4+i*8, -w/2+1, top+4+i*8, 2, INK) end
            end
        end
        headSpecial(kind, 2, shY-rig.headR+3, rig.headR)
    else
        G.rrect(-w / 2, top, w, h, 8, rig.torso, 2.5)
        G.rrect(-w / 2 + 5, top + 4, w - 10, h * 0.45, 5, H(0x4A4C53))
        G.rect(-w / 2 + 1, hipY - 7, w - 2, 6, H(0x55585F))
        G.rect(-3, hipY - 8, 8, 8, H(0xE27B23))
        headBot(2, shY - rig.headR + 3, rig.headR)
    end
    limbWithHand(rig, fSx, sY, fHx, fHy, false)
    if kind == 'runner' then
        G.poly({ fHx, fHy-4, fHx+31, fHy-16, fHx+15, fHy+2, fHx, fHy+4 }, H(0xC6EAF4), 2)
    elseif kind == 'gunner' then
        G.rrect(fHx-4, fHy-12, 40, 22, 6, H(0x223947), 2)
        G.rect(fHx+23, fHy-7, 13, 12, H(0x60E9F5))
    elseif kind == 'shield' then
        G.poly({ fHx-11, fHy-33, fHx+18, fHy-30, fHx+21, fHy+21, fHx+4, fHy+34, fHx-13, fHy+20 }, H(0x366782), 3)
        G.polyline({ fHx+1, fHy-25, fHx+10, fHy-22, fHx+12, fHy+16, fHx+3, fHy+24 }, 4, H(0x70E9F6))
    elseif kind == 'shock' then
        G.line(fHx+4, fHy-36, fHx+4, fHy+18, 5, H(0xD9D1ED))
        G.glow(fHx+4, fHy-31, 22, H(0xC794F7), .65)
        G.polyline({ fHx-3, fHy-39, fHx+11, fHy-32, fHx-2, fHy-23 }, 3, G.WHITE)
    elseif kind == 'jinx' then
        G.glow(fHx+5, fHy-3, 18 + 6*math.sin(p.t*8), H(0xF273C6), .65)
        G.circle(fHx+5, fHy-3, 6, H(0xFFC5EE))
    elseif kind == 'slade' then
        G.line(fHx-9, fHy+14, fHx+31, fHy-55, 5, H(0xB7C9D5))
        G.line(fHx-6, fHy-5, fHx+12, fHy+5, 5, H(0xD88B38))
    end
    if kind == 'heavy' then
        G.oellipse(fSx, sY - 2, rig.th * 0.9, rig.th * 0.7, H(0xFF8A1E), 2)
    end
    G.restore()
    G.restore()
end

local function golem(p: Pose)
    -- Cinderblock: a hunched boulder of a villain, drawn without the humanoid rig.
    local light = H(0xA7A29A)
    local mid = H(0x8F8A84)
    local dark = H(0x6A655F)
    local crack = H(0x4E4944)
    local t = p.t
    local s = math.sin(p.phase) * p.walk
    local e = p.ext
    local ePos = math.max(0, e)
    local eNeg = math.max(0, -e)
    local bob = math.abs(math.sin(p.phase)) * 3 * p.walk + math.sin(t * 1.6) * 1.5

    local lean = 0.12
    if p.move == 6 then
        lean = 0.12 + 0.2 * ePos - 0.12 * eNeg
    elseif p.move == 7 then
        lean = if e < 0 then -0.15 else 0.45
    elseif p.move == 1 then
        lean = 0.35
    end
    if p.hurt then
        lean = -0.2
    end

    G.save()
    if p.down > 0 then
        G.translate(0, -30 * p.down)
        G.rotate(-math.pi / 2 * p.down)
    end

    -- fists: back (b) and front (f)
    local fx, fy = 34 - s * 10, -24
    local bx, by = -26 + s * 10, -26
    if p.move == 6 then
        fx, fy = 36 + ePos * 44 - eNeg * 30, -58 - eNeg * 26
    elseif p.move == 7 then
        if e < 0 then
            fx, fy = 18, -168
            bx, by = -4, -160
        else
            fx, fy = 66, -10
            bx, by = 52, -8
        end
    elseif p.move == 1 then
        fx, fy = 62, -40
        bx, by = 40, -36
    end
    if p.hurt then
        fx, fy = 20, -120
        bx, by = -30, -116
    end

    local hipY = -38 + bob
    local shY = -96 + bob

    -- back arm
    G.save()
    G.translate(0, hipY)
    G.rotate(lean)
    G.translate(0, -hipY)
    G.limb(-24, shY + 6, (bx - 24) / 2 - 10, (by + shY) / 2 + 4, bx, by, 24, G.shade(mid, -0.2))
    G.oellipse(bx, by, 19, 17, G.shade(dark, -0.1), 2.5)
    G.restore()

    -- legs
    G.limb(-16, hipY, -18 - s * 8, hipY / 2, -20 - s * 14, -2, 24, G.shade(mid, -0.2))
    G.oellipse(-16 - s * 14, -6, 20, 10, dark, 2.5)
    G.limb(16, hipY, 18 + s * 8, hipY / 2, 20 + s * 14, -2, 24, mid)
    G.oellipse(24 + s * 14, -6, 20, 10, dark, 2.5)

    G.save()
    G.translate(0, hipY)
    G.rotate(lean)
    G.translate(0, -hipY)
    -- the boulder body
    G.rrect(-44, shY - 10, 84, hipY - shY + 22, 30, mid, 3)
    G.rrect(-30, shY + 2, 56, 34, 14, light)
    G.rrect(-36, shY + 42, 64, 20, 10, dark)
    G.polyline({ -20, shY + 4, -8, shY + 18, -18, shY + 32 }, 2.5, crack)
    G.polyline({ 18, shY + 6, 10, shY + 22, 20, shY + 34 }, 2.5, crack)
    G.polyline({ -34, shY + 50, -24, shY + 56, -10, shY + 50 }, 2.5, crack)
    -- small head sunk between the shoulders
    local hx, hy = 16, shY - 14
    G.oellipse(hx, hy, 16, 14, mid, 2.5)
    G.rect(hx - 6, hy - 9, 22, 6, dark)
    G.glow(hx + 7, hy - 1, 22, H(0xFFD23A), 0.7)
    G.circle(hx + 2, hy - 1, 3, H(0xFFF0A0))
    G.circle(hx + 11, hy - 1, 3, H(0xFFF0A0))
    -- shoulder boulders
    G.oellipse(-30, shY - 2, 20, 17, G.shade(mid, -0.1), 2.5)
    G.oellipse(30, shY, 20, 17, light, 2.5)
    -- front arm
    G.limb(30, shY + 4, (fx + 30) / 2 + 6, (fy + shY) / 2 + 6, fx, fy, 26, mid)
    G.oellipse(fx, fy, 21, 19, dark, 2.5)
    G.polyline({ fx - 8, fy - 6, fx - 2, fy + 2, fx - 8, fy + 8 }, 2, crack)
    G.restore()

    G.restore()
end


-- Draw one fighter at the origin, facing +x.
function A.fighter(kind: string, p: Pose, titleFacing: boolean?)
    if HX.isHero(kind) then
        HX.draw(kind, p, titleFacing)
    elseif kind == 'boss' then
        golem(p)
    else
        villain(kind, RIGS[kind] or RIGS.bot, p)
    end
end

-- Props and projectiles --------------------------------------------------------

function A.pizza(x: number, y: number, t: number)
    G.save()
    G.translate(x, y)
    G.rotate(math.sin(t * 3) * 0.15)
    G.poly({ -16, -8, 16, -8, 0, 18 }, H(0xFFD34D), 2.5)
    G.rrect(-18, -13, 36, 8, 4, H(0xC9853A), 2)
    G.circle(-5, -1, 3.5, H(0xC8322B))
    G.circle(5, 2, 3.2, H(0xC8322B))
    G.circle(0, 9, 2.6, H(0xC8322B))
    G.restore()
end

function A.birdarang(x: number, y: number, rot: number)
    G.save()
    G.translate(x, y)
    G.rotate(rot)
    G.poly({ 0, -4, 16, -14, 10, 0, 16, 14, 0, 4, -16, 14, -10, 0, -16, -14 }, H(0xD7263D), 2)
    G.circle(0, 0, 3, H(0xF5C518))
    G.restore()
end

function A.starbolt(x: number, y: number, t: number, dir: number)
    G.glow(x, y, 34, H(0x5CFF6A), 0.8)
    for i = 1, 3 do
        G.circle(x - dir * i * 9, y + math.sin(t * 30 + i) * 2, 7 - i * 1.6, G.fade(H(0x9CFF8A), 0.7 - i * 0.18))
    end
    G.circle(x, y, 9, H(0x5CFF6A))
    G.circle(x, y, 5, H(0xEFFFE8))
end

function A.enemyShot(kind: string, x: number, y: number, t: number, dir: number)
    if kind == 'blade' then
        G.save()
        G.translate(x, y)
        G.rotate(t*18)
        G.poly({ 0,-18, 5,-5, 18,0, 5,5, 0,18, -5,5, -18,0, -5,-5 }, H(0xBCD6E6), 2)
        G.circle(0,0,4,H(0xED8D3A))
        G.restore()
    else
        local c = if kind == 'hex' then H(0xF66ED1) else H(0xFF684F)
        G.glow(x,y,28,c,.65)
        G.line(x-dir*26,y,x,y,if kind=='hex' then 12 else 7,c)
        G.circle(x,y,if kind=='hex' then 10 else 6,G.WHITE)
    end
end

function A.beam(x: number, y: number, len: number, t: number, dir: number, power: number)
    local h = 26 * power + math.sin(t * 60) * 3
    local x0 = if dir > 0 then x else x - len
    G.save()
    G.opacity(0.35)
    G.rrect(x0 - 10, y - h, len + 20, h * 2, h, H(0x7FD8FF))
    G.restore()
    G.rrect(x0, y - h * 0.55, len, h * 1.1, h * 0.55, H(0xA8E6FF))
    G.rrect(x0, y - h * 0.25, len, h * 0.5, h * 0.25, G.WHITE)
    G.glow(x, y, 60 * power, H(0x7FD8FF), 0.9)
end

local function ravenShape(x: number, y: number, s: number, c: Color)
    G.poly({
        x, y - 12 * s,
        x + 14 * s, y - 20 * s,
        x + 46 * s, y - 34 * s,
        x + 34 * s, y - 14 * s,
        x + 58 * s, y - 8 * s,
        x + 26 * s, y + 2 * s,
        x + 10 * s, y + 6 * s,
        x, y + 24 * s,
        x - 10 * s, y + 6 * s,
        x - 26 * s, y + 2 * s,
        x - 58 * s, y - 8 * s,
        x - 34 * s, y - 14 * s,
        x - 46 * s, y - 34 * s,
        x - 14 * s, y - 20 * s,
    }, c)
end

function A.darkBurst(x: number, y: number, r: number, a: number)
    G.save()
    G.opacity(a)
    G.ellipse(x, y, r, r * 0.45, G.fade(H(0x3A1670), 0.55))
    G.ring(x, y, r, r * 0.45, 6, H(0x8A3CFF))
    G.ring(x, y, r * 0.8, r * 0.36, 3, H(0x1A0833))
    ravenShape(x, y - 70, r / 160, H(0x14062A))
    G.glow(x, y - 60, r * 0.8, H(0x8A3CFF), 0.45)
    G.restore()
end

function A.shockwave(x: number, y: number, r: number, a: number)
    G.save()
    G.opacity(a)
    G.ring(x, y, r, r * 0.35, 10, H(0xC9B79C))
    G.ring(x, y, r * 0.92, r * 0.3, 4, H(0x7A6A55))
    for i = 0, 7 do
        local ang = i / 8 * math.pi * 2
        G.poly({
            x + math.cos(ang) * r - 6, y + math.sin(ang) * r * 0.35,
            x + math.cos(ang) * r, y + math.sin(ang) * r * 0.35 - 14,
            x + math.cos(ang) * r + 6, y + math.sin(ang) * r * 0.35,
        }, H(0x8F8A84), 1.5)
    end
    G.restore()
end

function A.spark(x: number, y: number, k: number, c: Color)
    -- k: 0..1 life
    local s = 1 - k
    G.save()
    G.opacity(s * 1.3)
    G.burst(x, y, 28 * (0.6 + k), 10 * (0.6 + k), 8, k * 2, c, 2)
    G.burst(x, y, 14 * (0.6 + k), 5, 8, k * 2 + 0.3, G.WHITE)
    G.restore()
end

function A.dust(x: number, y: number, k: number)
    G.save()
    G.opacity((1 - k) * 0.7)
    G.ellipse(x, y - k * 8, 10 + k * 16, 6 + k * 8, H(0xCFC6D8))
    G.restore()
end

function A.shadow(x: number, y: number, w: number, z: number)
    local k = math.clamp(1 - z / 300, 0.35, 1)
    G.ellipse(x, y, w * k, w * 0.28 * k, G.fade(H(0x0A0614), 0.38 * k))
end

-- Stage ------------------------------------------------------------------------

local function hash(i: number, k: number): number
    local v = math.sin(i * 127.1 + k * 311.7) * 43758.5453
    return v - math.floor(v)
end

A.FLOOR_TOP = 452

function A.titansTower(x: number, y: number, s: number)
    local white = H(0xE9E6F2)
    local glass = H(0x7FB8E6)
    G.oellipse(x, y + 6 * s, 90 * s, 16 * s, H(0x3E6B45), 2)
    -- shaft
    G.rrect(x - 26 * s, y - 200 * s, 52 * s, 205 * s, 4 * s, white, 2)
    for i = 0, 6 do
        G.rect(x - 18 * s, y - 180 * s + i * 25 * s, 36 * s, 11 * s, glass)
    end
    -- the T crossbar
    G.rrect(x - 78 * s, y - 250 * s, 156 * s, 58 * s, 6 * s, white, 2)
    G.rect(x - 70 * s, y - 238 * s, 140 * s, 20 * s, glass)
    G.rect(x - 70 * s, y - 214 * s, 140 * s, 8 * s, G.shade(glass, -0.2))
end

local FACADES = {
    H(0xB24A3C), H(0x3E7C8C), H(0xE0C58F), H(0x6A4C93), H(0x4E8F5B), H(0xC96E3A), H(0x375A9E),
}
local SIGNS = { 'PIZZA', 'ARCADE', 'COMICS', 'JUMP CITY', 'TACOS', 'MUSIC', 'TOWER GYM', 'DONUTS' }

-- The later stages share floor coordinates but each has its own architecture.
local function themedStage(camX: number, t: number, theme: string, locale: L.Locale)
    local docks, foundry = theme == 'docks', theme == 'foundry'
    local accent = if docks then H(0x64D6D2) elseif foundry then H(0xF390DA) else H(0xF69B49)
    G.vgrad(0,0,G.W,460,if docks then H(0x102C46) elseif foundry then H(0x221630) else H(0x100E29),if docks then H(0x428895) elseif foundry then H(0x71395D) else H(0x57436E))
    if not foundry then
        G.glow(1000,175,140,accent,.18)
        G.circle(1000,175,48,if docks then H(0xBBE5DD) else H(0xDDD0EB))
        for i=0,15 do
            local x = (i*101-camX*.08) % 1380-50
            local h = 50+hash(i,4)*140
            G.rect(x,360-h,70,h,H(0x1B2943))
            for k=0,3 do G.rect(x+12,340-h+k*30,8,12,G.fade(accent,.4)) end
        end
    end
    if docks then
        G.vgrad(0,335,G.W,95,H(0x377D8C),H(0x183C55))
        for i=0,22 do
            local x = (i*73-camX*.15+t*13)%1400-60
            G.line(x,347+(i%5)*15,x+40,347+(i%5)*15,2,G.fade(accent,.4))
        end
        for i=0,3 do
            local x=(i*480-camX*.35)%1750-220
            G.line(x,390,x,135,13,H(0x20334A))
            G.line(x-40,143,x+250,143,11,H(0x20334A))
            G.polyline({x,240,x+170,143,x,143},5,H(0x20334A))
            G.line(x+210,145,x+210,260+math.sin(t)*4,3,accent)
            G.rrect(x+202,258+math.sin(t)*4,16,16,4,H(0xD7B15E),2)
        end
        for i=0,5 do
            local x=(i*310-camX)%1860-310
            local col=if i%2==0 then H(0x386D78) else H(0x9D5844)
            G.rrect(x,330,280,112,4,col,3)
            for k=1,12 do G.line(x+k*21,339,x+k*21,430,3,G.shade(col,-.25)) end
            G.text(L.text(locale, 'HIVE CARGO'),x+140,371,19,H(0xDEDDD1),.5)
            G.rect(x+15,417,30,6,accent)
        end
    elseif foundry then
        for i=0,5 do
            local x=(i*290-camX*.4)%1740-290
            G.rect(x,110,24,332,H(0x35223F))
            G.polyline({x,140,x+230,350,x+230,140,x,350},7,H(0x402748))
            G.line(x,177,x+270,177,12,H(0x977088))
            G.circle(x+105,177,17,H(0x473453))
            G.line(x+94,166,x+116,188,4,accent)
            G.line(x+116,166,x+94,188,4,accent)
        end
        for i=0,4 do
            local x=(i*345-camX)%1725-345
            G.rrect(x+20,245,260,197,16,H(0x382D45),3)
            G.rrect(x+42,266,216,126,12,H(0x171C2C),3)
            G.glow(x+145,335,90,H(0xE078DD),.32)
            G.poly({x+145,278,x+199,327,x+145,383,x+93,327},H(0xA557AB),3)
            G.poly({x+145,299,x+173,327,x+145,360,x+120,327},H(0xEEA8E7))
            G.line(x+52,414,x+239,414,7,H(0x6B5E77))
            G.circle(x+245,252,5,H(0x7DE7D1))
        end
        G.rrect(450,188,380,41,7,H(0x211D30),2)
        G.text(L.text(locale, 'H.I.V.E. HEX REACTOR'),640,200,19,accent,.5)
    else
        for i=0,4 do
            local x=(i*365-camX*.3)%1825-365
            G.rect(x,230,270,209,H(0x292940))
            for k=0,5 do
                for row=0,4 do G.rect(x+20+k*40,250+row*33,17,11,G.fade(accent,.45)) end
            end
        end
        for i=0,3 do
            local x=(i*570-camX)%2280-570
            G.rrect(x+30,337,170,101,8,H(0x545164),3)
            for k=0,5 do G.line(x+45,351+k*13,x+183,351+k*13,4,H(0x292C3D)) end
            G.line(x+260,427,x+260,176,8,H(0x33394A))
            G.polyline({x+215,218,x+260,176,x+305,218},5,H(0x727487))
            G.circle(x+260,176,5,H(0xFD5A57))
        end
        G.rrect(497,217,286,57,8,H(0x201C2B),3)
        G.text(L.text(locale, 'SLADE INDUSTRIES'),640,237,20,accent,.5)
    end
    G.rect(0,439,G.W,31,H(0x343548))
    G.line(0,440,G.W,440,5,accent)
    G.vgrad(0,470,G.W,250,if docks then H(0x526572) elseif foundry then H(0x55435F) else H(0x494456),H(0x242639))
    local off=-(camX%100)
    for i=0,14 do
        G.line(off+i*100,479,off+i*100-90,720,2,G.fade(accent,.14))
        G.poly({off+i*100,457,off+i*100+29,457,off+i*100+12,469,off+i*100-17,469},if foundry then H(0xDBA35F) else G.fade(accent,.55))
    end
    G.line(0,565,G.W,565,2,G.fade(accent,.14))
    G.line(0,672,G.W,672,2,G.fade(accent,.14))
    if not docks and not foundry then
        G.ellipse(840-camX%200,607,145,55,G.fade(accent,.08))
    end
end

function A.stage(camX: number, t: number, theme: string?, locale: L.Locale?)
    if theme and theme ~= 'city' then
        themedStage(camX, t, theme, locale or 'en')
        return
    end
    local W = G.W
    local HH = G.H
    -- sky
    G.vgrad(0, 0, W, 340, H(0x2B1655), H(0xF08A4B))
    local sunX = 920 - camX * 0.03
    G.glow(sunX, 250, 260, H(0xFFD27A), 0.5)
    G.circle(sunX, 250, 64, H(0xFFC870))
    -- clouds
    for i = 0, 5 do
        local cx = ((i * 260 - camX * 0.05 + t * 6) % (W + 300)) - 150
        local cy = 60 + hash(i, 3) * 90
        G.ellipse(cx, cy, 60, 14, G.fade(H(0xF7B6A0), 0.5))
        G.ellipse(cx + 30, cy - 8, 40, 12, G.fade(H(0xF7B6A0), 0.5))
    end
    -- far skyline
    local far = camX * 0.1
    local i0 = math.floor(far / 70) - 1
    for i = i0, i0 + math.ceil(W / 70) + 2 do
        local h = 50 + hash(i, 1) * 120
        local x = i * 70 - far
        G.rect(x, 300 - h, 64, h, H(0x4A2E6E))
    end
    -- the bay and the tower
    G.vgrad(0, 290, W, 60, H(0x5B4A9A), H(0x2E2A63))
    for i = 0, 8 do
        local wx = ((i * 170 - camX * 0.12 + t * 12) % (W + 100)) - 50
        G.line(wx, 305 + (i % 3) * 12, wx + 40, 305 + (i % 3) * 12, 2, G.fade(H(0xF7B6A0), 0.5))
    end
    A.titansTower(760 - camX * 0.06, 300, 0.9)
    -- mid buildings
    local mid = camX * 0.35
    local j0 = math.floor(mid / 130) - 1
    for i = j0, j0 + math.ceil(W / 130) + 2 do
        local h = 110 + hash(i, 2) * 130
        local x = i * 130 - mid
        local col = Color.lerp(H(0x3B2A5E), H(0x5A3E7A), hash(i, 5))
        G.rect(x, 340 - h, 122, h, col)
        for wy = 0, math.floor(h / 26) - 2 do
            for wx = 0, 3 do
                if hash(i * 7 + wx, wy) > 0.45 then
                    G.rect(x + 12 + wx * 27, 340 - h + 14 + wy * 26, 12, 12, G.fade(H(0xFFD98A), 0.75))
                end
            end
        end
    end
    -- street-level facades (scroll with the play field)
    local fw = 320
    local k0 = math.floor(camX / fw) - 1
    for i = k0, k0 + math.ceil(W / fw) + 2 do
        local x = i * fw - camX
        local h = 170 + hash(i, 7) * 90
        local top = 420 - h
        local col = FACADES[(i % #FACADES) + 1]
        G.rect(x, top, fw, h, col)
        G.rect(x, top, fw, 10, G.shade(col, -0.3))
        -- upper windows
        for wy = 0, math.floor((h - 120) / 44) do
            for wx = 0, 3 do
                local wxp = x + 24 + wx * 74
                local wyp = top + 22 + wy * 44
                G.rrect(wxp, wyp, 44, 28, 3, H(0x2A2350), 2)
                if hash(i * 13 + wx, wy + 9) > 0.55 then
                    G.rect(wxp + 3, wyp + 3, 38, 22, H(0xFFD98A))
                end
            end
        end
        -- shop front and striped awning
        G.rect(x + 20, 330, 190, 90, H(0x2A2350))
        G.rect(x + 26, 336, 178, 62, G.fade(H(0x9CCBE8), 0.85))
        G.rect(x + 230, 324, 66, 96, H(0x3A2A1E))
        G.circle(x + 286, 374, 3, H(0xF5C518))
        for s = 0, 6 do
            local sc = if s % 2 == 0 then H(0xF4F0E6) else G.shade(col, 0.1)
            G.poly({
                x + 16 + s * 30, 300,
                x + 46 + s * 30, 300,
                x + 46 + s * 30, 326,
                x + 16 + s * 30, 326,
            }, sc)
        end
        G.line(x + 16, 326, x + 226, 326, 3, G.INK)
        if hash(i, 11) > 0.35 then
            local sign = SIGNS[(math.floor(hash(i, 12) * #SIGNS)) + 1]
            G.rrect(x + 40, top - 30, 240, 44, 8, H(0x1E1633), 2)
            G.text(L.text(locale or 'en', sign), x + 160, top - 20, 22, H(0xFFE14D), 0.5)
        end
    end
    -- sidewalk
    G.rect(0, 420, W, A.FLOOR_TOP - 420, H(0xB3A9C2))
    local tile = 80
    local off = -(camX % tile)
    for i = 0, math.ceil(W / tile) + 1 do
        G.line(off + i * tile, 420, off + i * tile - 14, A.FLOOR_TOP, 2, H(0x8D839E))
    end
    G.rect(0, A.FLOOR_TOP, W, 8, H(0x6E6480))
    -- road
    G.vgrad(0, A.FLOOR_TOP + 8, W, HH - A.FLOOR_TOP - 8, H(0x4A4560), H(0x2E2A40))
    local dash = 160
    local d0 = -(camX % dash)
    for i = 0, math.ceil(W / dash) + 1 do
        G.rect(d0 + i * dash, 590, 80, 7, H(0xF5C518))
    end
    -- lamp posts
    local lp = 640
    local l0 = math.floor(camX / lp)
    for i = l0, l0 + 3 do
        local x = i * lp + 200 - camX
        G.rect(x - 4, 250, 8, 190, H(0x2A2438))
        G.rrect(x - 4, 244, 40, 8, 4, H(0x2A2438))
        G.glow(x + 34, 258, 40, H(0xFFE39A), 0.5)
        G.oellipse(x + 34, 254, 9, 6, H(0xFFF2C6), 2)
    end
end

return A
