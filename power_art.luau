-- Ability silhouettes and effects, in the fighter's mirrored local coordinates.
local G = require('gfx')
local P = require('pose')
local Powers = require('powers')
local V = {}
local H, INK = G.hex, G.INK
local function ring(x: number, y: number, rx: number, ry: number, width: number, c: Color)
    local points: { number } = {}
    for i = 0, 32 do
        local a = i / 32 * math.pi * 2
        table.insert(points, x + math.cos(a) * rx)
        table.insert(points, y + math.sin(a) * ry)
    end
    G.polyline(points, width, c)
end

function V.form(kind: string, p: P.Pose): boolean
    if kind ~= 'beast' or (p.move ~= 8 and p.move ~= 9) then return false end
    local green, dark = H(0xA2E84A), H(0x487A53)
    local e = math.max(0, p.ext)
    G.save()
    -- Expand into the animal form, then shrink back over the final recovery.
    local power = Powers.get(kind, p.move == 9)
    local morph = math.min(1, p.powerTime / .13, (power.duration - p.powerTime) / .16)
    G.scale(.65 + .35 * math.max(0, morph), .65 + .35 * math.max(0, morph))
    if p.move == 8 then
        local fistY = -14 - p.windup * 65
        G.oellipse(-13, -7, 18, 8, dark, 2)
        G.oellipse(27, -7, 19, 8, green, 2)
        G.limb(-9, -54, -20, -24, -13, -8, 22, dark)
        G.limb(22, -53, 35, -30, 28, -9, 24, green)
        G.oellipse(3, -67, 40, 41, green, 3)
        G.oellipse(13, -66, 24, 29, dark, 2)
        G.limb(-23, -90, -38, -54, -23, fistY, 26, dark)
        G.oellipse(-23, fistY, 17, 14, dark, 2)
        G.oellipse(16, -111, 27, 28, green, 2.5)
        G.poly({ -6,-126, 0,-144, 9,-135, 17,-143, 26,-128 }, dark, 2)
        G.oellipse(32, -105, 23, 14, H(0xC0E57C), 2)
        G.poly({ 18,-124, 40,-118, 26,-112 }, G.WHITE, 1.5)
        G.ellipse(32, -118, 3, 4, INK)
        G.line(28,-97,47,-99,2,INK)
        G.limb(28, -87, 50 + e * 6, -63, 52, fistY, 28, green)
        G.oellipse(52, fistY, 19, 15, green, 2.5)
        for i = 0, 2 do G.line(45 + i * 6, fistY - 5, 45 + i * 6, fistY + 7, 1.4, dark) end
    else
        local stride = if p.active then math.sin(p.powerTime * 17) * 12 else 0
        G.poly({ -27,-82, -65,-62, -104,-50, -76,-75, -48,-107 }, dark, 2.5)
        G.limb(-9,-62,-25,-31,-21-stride,-7,21,dark)
        G.oellipse(-15-stride,-5,23,7,dark,2)
        G.oellipse(0,-83,40,51,green,3)
        G.oellipse(17,-75,21,38,H(0xC4EC83),1.5)
        G.limb(16,-60,25,-27,22+stride,-7,25,green)
        G.oellipse(30+stride,-5,25,7,green,2)
        G.poly({ 14,-111, 12,-151, 40,-171, 60,-152, 43,-104 },green,2.5)
        G.oellipse(54,-151,43,26,green,3)
        G.poly({ 35,-142, 96,-146, 87,-125, 47,-124 },dark,2)
        for i = 0, 5 do
            local x = 47 + i * 7
            G.poly({ x,-140, x+6,-140, x+3,-130 },H(0xF6F1D6),1)
        end
        G.poly({ 40,-164,64,-161,49,-151 },G.WHITE,1.5)
        G.ellipse(54,-158,3,4,INK)
        G.circle(83,-155,2,INK)
        G.limb(31,-108,48,-98,57,-108,7,green)
        G.line(56,-108,63,-105,2,G.WHITE)
        for i = 0, 2 do G.poly({ 34+stride+i*7,-9, 43+stride+i*7,-3, 31+stride+i*7,-3 },G.WHITE,1) end
        if p.active then
            G.polyline({ 105,-157,118,-146,105,-135 },2.5,H(0xDFFF9E))
            G.polyline({ 120,-164,137,-146,120,-127 },2,H(0xA2E84A))
        end
    end
    G.restore()
    return true
end

function V.effects(kind: string, p: P.Pose)
    if p.move ~= 8 and p.move ~= 9 then return end
    local ultimate = p.move == 9
    local power = Powers.get(kind, ultimate)
    local t, e = p.powerTime, math.max(0, p.ext)
    local progress = math.clamp((t - power.first) / (power.last - power.first), 0, 1)
    local color = if kind == 'robin' then H(0xFFE04D) elseif kind == 'cyborg' then H(0x83EDFF) elseif kind == 'raven' then H(0xAC73FF) else H(0x96FF76)
    if ultimate and t < power.first then
        G.glow(0, -65, 75 * (.4 + p.windup * .6), color, .28)
        ring(0, -2, 42 + p.windup * 25, 12, 2, color)
    end
    if not ultimate then
        if kind == 'robin' then
            local a = t * 24
            local dx, dy = math.cos(a) * (30 + e * 80), math.sin(a) * (18 + e * 24)
            G.line(12 - dx,-53 - dy,12 + dx,-53 + dy,6,INK)
            G.line(12 - dx,-53 - dy,12 + dx,-53 + dy,3.5,H(0xCDD2DF))
            G.oellipse(12,-53,4,4,H(0x22B86C),1)
            if p.active then
                ring(0,-51,122,45,2.5,color)
                ring(0,-51,105,37,1,G.fade(color,.5))
            end
        elseif kind == 'cyborg' or kind == 'beast' then
            if p.active then
                local radius = power.reach / 1.2 * (.55 + progress * .45)
                ring(0,-3,radius, power.depth / 1.2,3.5,G.fade(color,1-progress*.7))
                for i = -2, 2 do
                    local x = i * radius * .36
                    G.polyline({ x-12,-2, x,-10, x+8,2, x+19,-3 },2,color)
                end
                G.glow(25,-8,43,color,.4*(1-progress))
            end
        elseif kind == 'starfire' then
            if p.active then
                G.poly({ 27,-72, -94,-104, -61,-70, -115,-61, -60,-47, -91,-20, 27,-55 },G.fade(color,.35))
                G.glow(41,-67,26,color,.8)
                G.poly({ 42,-80, 70,-67, 42,-54, 48,-67 },H(0xE3FFB9))
            end
        elseif kind == 'raven' then
            if p.active then
                for i = -1, 1 do
                    local y = -57 + i * 15
                    G.contour({ 25,y, 95,y-35, 179,y+38, 246,y+i*6,
                        194,y+53, 84,y-13, 25,y+5, 21,y+3, 21,y+1, 25,y },H(0x26113F),1.4)
                    G.polyline({ 30,y, 102,y-8, 174,y+13, 246,y+i*6 },1.6,color)
                end
                ring(246,-57,10,31,3,color)
            end
        end
    elseif p.active then
        if kind == 'robin' then
            -- The actual three-lane birdarangs are spawned by combat; these are
            -- the rotating ready-to-throw gadgets around his throwing hand.
            for i = 0, 2 do
                local a = t * 12 + i * 2.1
                local x, y = 40 + math.cos(a)*18, -60 + math.sin(a)*18
                G.poly({ x-9,y-4,x-3,y-2,x,y-8,x+3,y-2,x+9,y-4,x+5,y+4,x,y,x-5,y+4 },color,1.4)
            end
        elseif kind == 'cyborg' then
            local pulse = 1 + math.sin(t * 55) * .07
            G.line(63,-81,1020,-81,61*pulse,G.fade(color,.2))
            G.line(63,-81,1020,-81,36*pulse,color)
            G.line(63,-81,1020,-81,15*pulse,G.WHITE)
            G.glow(63,-81,42,color,.9)
            for i = 1, 5 do ring(63+i*155,-81,12,28,2,G.WHITE) end
        elseif kind == 'starfire' then
            local radius = power.reach / 1.2 * (.7 + progress*.3)
            G.glow(0,-72,100,color,.6*(1-progress*.5))
            ring(0,-5,radius,power.depth/1.2,4,G.fade(color,1-progress*.7))
            ring(0,-72,75+progress*100,75+progress*100,3,G.fade(color,1-progress))
            for i = 0, 11 do
                local a = i*math.pi/6 + .15
                local inner, outer = 52+progress*30, 105+progress*90
                G.poly({ math.cos(a-.05)*inner,-72+math.sin(a-.05)*inner,
                    math.cos(a)*outer,-72+math.sin(a)*outer,
                    math.cos(a+.05)*inner,-72+math.sin(a+.05)*inner },G.fade(H(0xE5FFC1),1-progress*.7))
            end
        elseif kind == 'raven' then
            local x = 210 + progress * 200
            local flap = math.sin(progress * math.pi * 2) * 25
            G.glow(x,-108,120,color,.28)
            G.poly({ 25,-55, x-100,-105, x-180,-217-flap, x-105,-177-flap,
                x-91,-204-flap, x-54,-150, x-5,-131, x+28,-148,
                x+53,-134, x+92,-126, x+52,-109, x+24,-89,
                x-58,-50, x-116,-20+flap, x-100,-54, x-173,-12+flap, x-125,-78, 25,-45 },H(0x170E28),3)
            G.polyline({ x-140,-188-flap,x-70,-121,x+27,-116,x+69,-124 },3,color)
            G.poly({ x+20,-131,x+41,-128,x+28,-122 },G.WHITE)
        end
    end
end
return V
