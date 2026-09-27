-- The five Titans, drawn Teen Titans Go! style: three-quarter fighting view,
-- huge heads, sculpted limbs and heavy ink. Colours and shapes follow the show's
-- character sheets. Each figure stands with its feet at (0, 0) and faces +x;
-- the game mirrors it for the other direction.
local G = require('gfx')
local P = require('pose')
local Profile = require('profiles')
local PowerArt = require('power_art')
local Arms = require('armature')
local Motion = require('motion')

local HX = {}
local H = G.hex
local INK = G.INK

-- Pose helpers ---------------------------------------------------------------------

local function lerp(a: number, b: number, k: number): number
    return a + (b - a) * k
end

local function bob(p: P.Pose): number
    if p.down > 0 then return 0 end
    if p.air then return if p.style=='beast' then (1-math.abs(p.rise))*4 else 0 end
    local heavy=p.style=='cyborg'
    local contact=(.5+.5*math.cos(p.phase*2-.5))
    local weight=(contact*(if heavy then 5 elseif p.style=='beast' then 5 else 4)-1)*p.walk+p.dash*2
    local anticipation=math.max(0,-p.ext)*8
    local crouch=if heavy and p.move==8 then math.max(0,p.ext)*28 else 0
    local strike=if p.move>=1 and p.move<=3 then math.max(0,p.ext)*(if p.move==2 then 5 else 2) else 0
    local spring=p.launch*(if heavy then 17 elseif p.style=='raven' then 7 else 14)
    local landing=p.land*(if heavy then 18 elseif p.style=='starfire' or p.style=='raven' then 8 else 14)
    return weight+anticipation+crouch+spring+landing-strike-math.sin(p.t*2.4)*.8*(1-p.walk)
end

-- Where a hand goes: its idle spot (ix, iy), or wherever the move takes it.
local function handTarget(p: P.Pose, front: boolean, sx: number, sy: number, ix: number, iy: number, reach: number): (number, number)
    local ePos = math.max(0, p.ext)
    local eNeg = math.max(0, -p.ext)
    local swing = math.sin(p.phase) * p.walk * (if front then -12 else 12)
    local m = p.move
    if p.style ~= '' then
        ix = sx + (if p.style == 'cyborg' then 30 elseif p.style == 'starfire' then 22 else 20) - (if front then 0 else 5)
        iy = sy + (if p.style == 'cyborg' then 22 else 13) - (if front then 0 else 5)
    end
    if p.hurt then
        return sx - 10, sy - 14 + (if front then 0 else 3)
    end
    if m == 8 or m == 9 then
        local k = p.style
        if k == 'robin' then
            return if m == 8 then 12 else sx + 36, sy + (if front then 7 else 13)
        elseif k == 'cyborg' then
            if m == 9 then return sx + reach, sy + (if front then 3 else 9) end
            return lerp(ix, sx + 34, ePos), lerp(iy, -9, ePos) - p.windup * 65
        elseif k == 'starfire' then
            if m == 9 then return sx + (if front then 29 else -23), sy - 24 * ePos - p.windup * 15 end
            return sx + (if front then 38 * ePos else -15), sy + (if front then 3 else 12)
        elseif k == 'raven' then
            return sx + (if m == 9 then 12 else 23), sy - (if m == 9 then 27 * ePos else -7)
        end
    end
    if m >= 1 and m <= 3 and p.style ~= '' then
        local k, u = p.style, p.stroke
        local tx: number = ix
        local ty: number = iy
        if k == 'robin' then
            local fx,fy,bx,by=Motion.staff(m,p.ext,p.windup,u,-62+bob(p))
            return if front then fx else bx,if front then fy else by
        elseif k == 'cyborg' then
            if m == 3 then
                tx, ty = sx + 47, sy + 35
                ix, iy = ix + p.windup * 4, iy - p.windup * 68
            elseif (m == 1 and front) or (m == 2 and not front) then
                tx = sx + (if m == 1 then 51 else 32)
                ty = sy + (if m == 1 then 18 else 20 - u * 52)
            else
                local blend=math.max(ePos,p.windup)
                return lerp(ix,sx+8,blend),lerp(iy,sy+14,blend)
            end
        elseif k == 'starfire' then
            if m == 3 or (m == 1 and front) or (m == 2 and not front) then
                tx, ty = sx + 36, sy + (if m == 2 then 12 - u * 32 else (if front then 5 else -8))
            else
                local blend=math.max(ePos,p.windup)
                return lerp(ix,sx+12,blend),lerp(iy,sy+13,blend)
            end
        elseif k == 'raven' then
            tx = sx + (if m == 3 then 28 else 18)
            ty = sy + (if m == 1 then 18 - u * 12 elseif m == 2 then 24 - u * 40 else (if front then 9 else -9))
        elseif k == 'beast' then
            if m == 3 or (m == 1 and front) or (m == 2 and not front) then
                tx = sx + (if m == 3 then 36 else 29)
                ty = sy + (if m == 2 then 22 - u * 30 else -14 + u * 35)
                ix=lerp(ix,sx-7,p.windup)
                iy=lerp(iy,sy-13,p.windup)
            else
                local blend=math.max(ePos,p.windup)
                return lerp(ix,sx+10,blend),lerp(iy,sy+13,blend)
            end
        end
        return lerp(ix, tx, ePos) - eNeg * 20, lerp(iy, ty, ePos) + eNeg * 12
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
        if p.style=='beast' then return sx+lerp(8,34,ePos),sy+lerp(5,-4,ePos) end
        if p.style=='raven' then return sx+lerp(14,30,ePos),sy-7*ePos end
        if p.style=='cyborg' then return sx+(if front then 20 else 14),sy-9-10*p.windup end
        return sx+(if front then 12-9*ePos else 22),sy+(if front then 4 else -9)

    elseif m == 5 then
        return sx + reach, sy + (if front then 2 else 6)
    end
    if p.air then
        local rise,fall=math.max(0,p.rise),math.max(0,-p.rise)
        local apex=math.max(0,1-math.abs(p.rise)*1.5)
        if p.style=='starfire' then
            return sx+(if front then 23 else -14),sy+(if front then 5-rise*12 else 14)
        elseif p.style=='raven' then
            return sx+(if front then 25 else -16),sy+8+fall*5
        elseif p.style=='cyborg' then
            return sx+(if front then 21 else 16)+fall*7,sy-12*rise+12*fall+apex*6
        elseif p.style=='beast' then
            return sx+(if front then 22-18*rise else -12+fall*24),sy-12*rise+fall*14
        end
        return sx+(if front then 13-20*rise else 17+rise*8),sy+(if front then 7-22*rise else -8+fall*18)
    end
    if p.move==0 and (p.launch>0 or p.land>0) then
        return sx+lerp(20,-9,p.launch),sy+13+p.launch*9+p.land*7
    end
    if p.style ~= '' then
        local guardX = if p.style == 'cyborg' then 30 elseif p.style == 'starfire' then 22 else 20
        local guardY = if p.style == 'cyborg' then 22 else 13
        if not front then guardX -= 5; guardY -= 5 end
        local swingCycle=(if front then -1 else 1)*math.cos(p.phase)
        local runX=sx+5+swingCycle*(if p.style=='cyborg' then 32 elseif p.style=='beast' then 29 else 27)
        local runY=sy+(if p.style=='cyborg' then 26 else 15)-math.max(0,swingCycle)*24+math.max(0,-swingCycle)*9
        if p.style=='starfire' then
            runX=sx+(if front then 29+p.dash*6 else -25)
            runY=sy+(if front then -6 else 20)+math.sin(p.t*5)*3
        elseif p.style=='raven' then
            runX=sx+(if front then 30 else -26)
            runY=sy+(if front then 5 else 18)+math.sin(p.t*4+(if front then 0 else 1.6))*5
        end
        return lerp(sx + guardX, runX, p.walk), lerp(sy + guardY, runY, p.walk)
    end
    return lerp(ix, sx, p.walk) + swing, iy - math.abs(swing) * 0.15
end

-- Keep the actual wrist and projectile attachment inside the same arm reach.
local function hand(p: P.Pose, front: boolean, sx: number, sy: number, ix: number, iy: number, reach: number): (number, number)
    local x, y = handTarget(p, front, sx, sy, ix, iy, reach)
    if p.style == '' then return x, y end
    local _, _, hx, hy = Arms.solve(p.style, sx, sy, x, y)
    return hx, hy
end

-- Elbow or knee: the midpoint pushed sideways by `bend`.
local function joint(ax: number, ay: number, bx: number, by: number, bend: number): (number, number)
    local dx, dy = bx - ax, by - ay
    local len = math.max(1, math.sqrt(dx * dx + dy * dy))
    return (ax + bx) / 2 - dy / len * bend, (ay + by) / 2 + dx / len * bend
end

local function armJoint(p: P.Pose, sx: number, sy: number, hx: number, hy: number, portraitBend: number): (number, number)
    if p.style == '' then return joint(sx, sy, hx, hy, portraitBend) end
    local ex, ey = Arms.solve(p.style, sx, sy, hx, hy)
    return ex, ey
end

local function legJoint(p: P.Pose, hx: number, hy: number, fx: number, fy: number): (number, number)
    if p.style=='' and p.walk<.01 and p.move==0 and not p.air then
        return joint(hx, hy, fx, fy, -2)
    end
    -- Solve to the ankle, not the bottom of the shoe. Bone lengths fit the
    -- standing hip height; overlong bones force both knees into a deep crouch.
    local dx, dy = fx - hx, fy - (if p.style~='' then 4 else 0) - hy
    local d = math.max(0.01, math.sqrt(dx * dx + dy * dy))
    local upper=if p.style=='cyborg' then 21 elseif p.style=='starfire' then 25 elseif p.style=='beast' then 13 elseif p.style~='' then 16 else math.abs(hy)*.53+2
    local lower=if p.style=='cyborg' then 23 elseif p.style=='starfire' then 27 elseif p.style=='beast' then 15 elseif p.style~='' then 18 else math.abs(hy)*.5+2
    -- A wide attack stance can exceed the bind reach slightly: extend along
    -- the hip-to-ankle line rather than letting the shin reverse at the knee.
    if d>=upper+lower then
        return hx+dx*upper/(upper+lower),hy+dy*upper/(upper+lower)
    end
    local along = math.clamp((upper * upper - lower * lower + d * d) / (2 * d), 0, d)
    local bend = math.sqrt(math.max(0, upper * upper - along * along))
    -- Both knees bend toward local +x. Facing is applied once to the figure.
    return hx + dx / d * along + dy / d * bend, hy + dy / d * along - dx / d * bend
end

-- Where a foot goes.
local function foot(p: P.Pose, front: boolean, hipX: number, hipY: number, restX: number): (number, number)
    local s = math.sin(p.phase) * p.walk
    local c = math.cos(p.phase)
    local dir = if front then 1 else -1
    local ePos = math.max(0, p.ext)
    if p.style ~= '' and not p.air then restX += (if front then 7 else -6) * (1 - p.walk) end
    if p.move >= 1 and p.move <= 3 and p.style ~= '' then
        local spread = if p.style == 'cyborg' then 15 elseif p.style == 'beast' then 16 else 12
        return restX + dir * spread * ePos, if p.style == 'beast' and p.move == 3 and not front then -9 * ePos else 0
    elseif p.move == 3 and front then
        local chamber = math.min(1, math.max(0, -p.ext) / 0.35)
        local reach = hipX + math.abs(hipY) * 1.03 + 3 - restX
        return lerp(restX, hipX + 12, chamber) + ePos * reach, lerp(0, hipY * 0.6, chamber) + (hipY + 4) * ePos
    elseif p.move == 4 then
        if p.style=='beast' then
            return hipX+(if front then 10 else -9)-ePos*7,hipY*.65
        elseif p.style=='raven' then
            return hipX+(if front then 9 else -8),hipY*.28
        end
        if front then
            return lerp(hipX+11,hipX+math.abs(hipY)*.98,ePos),lerp(hipY*.6,hipY+6,ePos)
        end
        return restX-8,hipY*.62
    end
    if p.air then
        local rise,fall=math.max(0,p.rise),math.max(0,-p.rise)
        local tuck=math.max(0,1-math.abs(p.rise)*1.4)
        if p.style=='starfire' then
            return hipX+(if front then 10 else -18)+fall*6,hipY*(if front then .32 else .08)-tuck*3
        elseif p.style=='beast' then
            return hipX+(if front then 12 else -13)*(1-fall*.35),hipY*(if front then .26+tuck*.18 else .12+tuck*.16)-rise*3
        elseif p.style=='cyborg' then
            return hipX+(if front then 17 else -15),hipY*(.08+tuck*(if front then .32 else .15))
        end
        return hipX+(if front then 12+rise*4 else -15+fall*4),hipY*(.1+tuck*(if front then .3 else .12)+rise*(if front then .12 else 0))
    end
    if p.style~='' then
        if p.walk>.01 then
            if p.style=='starfire' then
                local wave=math.sin(p.t*5+(if front then 0 else 1.8))
                return lerp(restX,if front then hipX+9 else hipX-21-p.dash*5,p.walk),
                    (if front then hipY*.3 else hipY*.06)*p.walk+wave*2*p.walk
            end
            local stride,lift=Motion.gait(p.style,p.dash)
            local x,y=Motion.stride(p.phase+(if front then 0 else math.pi),stride,lift)
            return lerp(restX,hipX+x,p.walk),y*p.walk
        end
        return restX,0
    end
    local fy=0
    if p.walk>.05 then fy=-math.max(0,dir*c)*12*p.walk end
    return restX+dir*s*math.min(20,math.abs(hipY)*.55),fy

end

-- Chest leads the action while the head counter-rotates to keep the gaze level.
local function leanAngle(p: P.Pose): number
    local lean=p.walk*(if p.style=='beast' then .34 elseif p.style=='cyborg' then .2 elseif p.style=='starfire' then .31 elseif p.style=='raven' then .18 else .27)
    if p.move==8 or p.move==9 then
        lean=if p.style=='starfire' and p.move==8 then .38*math.max(0,p.ext) else 0
    elseif p.hurt then
        lean=-.22
    elseif p.move>=1 and p.move<=3 then
        local e=math.max(0,p.ext)
        local strength=if p.style=='beast' then .46 elseif p.style=='raven' then .19 elseif p.style=='cyborg' then .29 else .34
        if p.move==3 then strength*=1.35 end
        lean=strength*e-p.windup*(if p.style=='raven' then .14 else .3)
        if p.move==2 then lean-=e*(1-p.stroke)*.13 end
        lean+=math.sin(p.settle*math.pi)*.035
    elseif p.air then
        local rise,fall=math.max(0,p.rise),math.max(0,-p.rise)
        lean=if p.style=='beast' then .38*rise-.16*fall elseif p.style=='starfire' then .28*p.speed elseif p.style=='raven' then -.09 else .22*rise-.15*fall
        if p.move==4 then lean+=math.max(0,p.ext)*(if p.style=='beast' then .42 else .23) end
    elseif p.launch>0 or p.land>0 then
        lean=.25*p.launch+.2*p.land
    end
    return lean+p.dash*.22
end

local function torsoScale(p: P.Pose): (number, number)
    if p.style=='' or p.down>0 or p.hurt then return 1,1 end
    local compression=if p.move==0 then p.launch*.12+p.land*.16 else 0
    local impact=if p.move>=1 and p.move<=3 then math.max(0,p.ext)*.06 else 0
    return 1+compression+impact,1-compression*.65
end

local function leanBegin(p: P.Pose, pivotY: number)
    local sx,sy=torsoScale(p)
    G.save()
    G.translate(0, pivotY)
    G.rotate(leanAngle(p))
    G.scale(sx,sy)
    G.translate(0, -pivotY)
end

local function bodyPoint(p: P.Pose, pivotY: number, x: number, y: number): (number, number)
    local sx,sy=torsoScale(p)
    local angle=leanAngle(p)
    local dx,dy=x*sx,(y-pivotY)*sy
    return dx*math.cos(angle)-dy*math.sin(angle),pivotY+dx*math.sin(angle)+dy*math.cos(angle)
end

local function hoverOffset(p: P.Pose, hover: number): number
    return hover+math.sin(p.t*2.6)*3+(if p.style=='starfire' then p.walk*10 elseif p.style=='raven' then p.walk*9 else 0)
end

-- Knocked down or floating.
local function frameBegin(p: P.Pose, hover: number, lie: number)
    G.save()
    if p.down > 0 then
        G.translate(0, -lie * p.down)
        G.rotate(-math.pi / 2 * p.down)
    elseif hover > 0 then
        G.translate(0,-hoverOffset(p,hover))
    end
end

local function stick(ax: number, ay: number, bx: number, by: number, cx: number, cy: number, th: number, c: Color)
    G.limb(ax, ay, bx, by, cx, cy, th, c)
end

-- Tapered, curved volumes instead of constant-width strokes. The broad upper
-- limb narrows at the joint and wrist; the outline stays continuous when bent.
local function bodyLimb(p: P.Pose, ax: number, ay: number, bx: number, by: number, cx: number, cy: number, th: number, c: Color)
    if p.style == '' then stick(ax, ay, bx, by, cx, cy, th, c); return end
    local dx1,dy1,dx2,dy2=bx-ax,by-ay,cx-bx,cy-by
    if dx1*dx1+dy1*dy1<.01 then dx1,dy1=dx2,dy2 end
    if dx2*dx2+dy2*dy2<.01 then dx2,dy2=dx1,dy1 end
    local d1,d2=math.max(.01,math.sqrt(dx1*dx1+dy1*dy1)),math.max(.01,math.sqrt(dx2*dx2+dy2*dy2))
    local nx1,ny1,nx2,ny2=-dy1/d1,dx1/d1,-dy2/d2,dx2/d2
    local mx,my=(nx1+nx2)*.5,(ny1+ny2)*.5
    local bulk=if p.style=='beast' then 1.4 elseif p.style=='cyborg' then 1.3 else 1.25
    local root,elbow,wrist=th*.66*bulk,th*.52*bulk,th*.38*bulk
    G.contour({ ax+nx1*root,ay+ny1*root,
        lerp(ax,bx,.55)+nx1*root,lerp(ay,by,.55)+ny1*root,bx+nx1*elbow,by+ny1*elbow,bx+mx*elbow,by+my*elbow,
        bx+nx2*elbow,by+ny2*elbow,lerp(bx,cx,.6)+nx2*wrist,lerp(by,cy,.6)+ny2*wrist,cx+nx2*wrist,cy+ny2*wrist,
        cx+dx2/d2*2,cy+dy2/d2*2,cx+dx2/d2*2,cy+dy2/d2*2,cx-nx2*wrist,cy-ny2*wrist,
        lerp(bx,cx,.6)-nx2*wrist,lerp(by,cy,.6)-ny2*wrist,bx-nx2*elbow,by-ny2*elbow,bx-mx*elbow,by-my*elbow,
        bx-nx1*elbow,by-ny1*elbow,lerp(ax,bx,.55)-nx1*root,lerp(ay,by,.55)-ny1*root,ax-nx1*root,ay-ny1*root,
        ax-dx1/d1*2,ay-dy1/d1*2,ax-dx1/d1*2,ay-dy1/d1*2,ax+nx1*root,ay+ny1*root },c,1.5)
end

-- Gloves and armour follow the forearm angle rather than staying upright.
local function forearmShell(ex: number, ey: number, hx: number, hy: number, start: number, width: number, wrist: number, c: Color, panel: Color?)
    width*=1.12
    wrist*=1.08
    local x, y = lerp(ex, hx, start), lerp(ey, hy, start)
    local dx, dy = hx - x, hy - y
    local length = math.sqrt(dx * dx + dy * dy)
    G.save(); G.translate(x, y); G.rotate(math.atan2(dy, dx))
    G.contour({ 0,-width, length*.3,-width,length*.75,-wrist,length,-wrist,
        length+2,-wrist,length+2,wrist,length,wrist,
        length*.7,wrist,length*.25,width,0,width,
        -2,width,-2,-width,0,-width }, c, 1.4)
    if panel ~= nil then
        G.poly({ 2,-width*.48,length-3,-wrist*.48,length-3,wrist*.48,2,width*.48 },panel)
        G.line(1,-width+2,1,width-2,1,INK)
    end
    G.restore()
end

local function fist(ex: number, ey: number, hx: number, hy: number, size: number, c: Color)
    G.save(); G.translate(hx,hy); G.rotate(math.atan2(hy-ey,hx-ex)); G.scale(size*1.16,size*1.16)
    G.contour({ -2,-4, 0,-5,4,-5,6,-3,
        7,-1,7,2,5,4, 3,5,-1,5,-3,2,
        -4,0,-3,-3,-2,-4 }, c, 1.2)
    G.polyline({ -1,2,2,2,3,4 },1,INK)
    G.line(4,-2,4,0,0.8,INK)
    G.restore()
end

local function footPitch(p: P.Pose, front: boolean): number
    if p.style=='starfire' then return if front then .08 else .2 end
    if p.air then return if front then -.08 else .18 end
    if p.move~=0 or p.walk<.01 then return 0 end
    local cycle=((p.phase+(if front then 0 else math.pi))/(math.pi*2))%1
    if cycle<.56 then return 0 end
    return math.sin((cycle-.56)/.44*math.pi*2)*.23*p.walk
end

-- Keep the head's volume and gaze stable as the chest compresses and rotates.
local function headBegin(p: P.Pose, x: number, y: number)
    G.save()
    G.translate(x, y)
    if p.style~='' then
        local sx,sy=torsoScale(p)
        G.scale(1/sx,1/sy)
        G.rotate(-leanAngle(p)*.6)
    end
    G.translate(-x, -y)
end

local function mitt(x: number, y: number, r: number, c: Color, cuff: boolean)
    if cuff then
        G.poly({ x - r * 1.2, y - r * 1.6, x + r * 1.2, y - r * 1.6, x + r * 0.7, y - r * 0.4, x - r * 0.7, y - r * 0.4 }, c, 2)
    end
    G.oellipse(x, y, r, r * 0.9, c, 2)
end

local function glowHands(p: P.Pose, x1: number, y1: number, x2: number, y2: number, c: Color)
    if p.move == 5 then
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

-- Tapered arcs expose the sweep without covering the pose with a solid flash.
local function ribbon(x: number, y: number, radius: number, first: number, last: number, c: Color)
    local pts: {number}={}
    local edge: {number}={}
    for i=0,14 do
        local u=i/14
        local a=lerp(first,last,u)
        local r=radius+math.sin(u*math.pi)*5
        table.insert(pts,x+math.cos(a)*r);table.insert(pts,y+math.sin(a)*r)
        table.insert(edge,x+math.cos(a)*r);table.insert(edge,y+math.sin(a)*r)
    end
    for i=14,0,-1 do
        local u=i/14
        local a=lerp(first,last,u)
        local r=radius-math.sin(u*math.pi)*8
        table.insert(pts,x+math.cos(a)*r);table.insert(pts,y+math.sin(a)*r)
    end
    G.poly(pts,G.fade(c,.32))
    G.polyline(edge,1.6,G.fade(c,.8))
end

local function actionFx(p: P.Pose)
    if not p.active or p.move<1 or p.move>3 or p.hurt or p.down>0 then return end
    local u=p.stroke
    if p.style=='robin' then
        if p.move~=1 then
            ribbon(-4,-43,if p.move==3 then 77 else 68,-1.9+u*.4,.35+u*.65,H(0xFFE04D))
        end
    elseif p.style=='cyborg' then
        if p.move==2 then ribbon(0,-61,66,1.05-u*.3,-1.0-u*.2,H(0x9CEAFF))
        elseif p.move==3 then
            ribbon(-7,-42,77,-1.8+u*.5,.35+u*.3,H(0x9CEAFF))
        else
            G.poly({ 16,-83,83+u*16,-60,20,-56,49,-64 },G.fade(H(0x9CEAFF),.38))
        end
    elseif p.style=='beast' then
        for i=0,2 do ribbon(-2,-33,48+i*8,-1.5+u*.4,.2+u*.8,H(0xB9FF72)) end
    elseif p.style=='starfire' then
        ribbon(1,-63,54+u*7,if p.move==2 then 1.3 else -1.3,if p.move==2 then -.9 else .5,H(0xACFF72))
    elseif p.style=='raven' then
        ribbon(-1,-50,60,-1.4+u*.6,.85+u*.5,H(0xB880FF))
    end
end

-- Draw normal weapons/effects in the same leaned coordinate frame as the hands.
local function normalFx(p: P.Pose, fx: number, fy: number, bx: number, by: number)
    local m=if p.move==4 and p.style=='beast' then 3 else p.move
    if m==4 and p.active then
        if p.style=='raven' then
            G.contour({ fx,fy-4,fx+18,fy-25,fx+43,fy-16,fx+55,fy-2,
                fx+35,fy-6,fx+18,fy+14,fx,fy+4,fx-4,fy+2,fx-4,fy-2,fx,fy-4 },H(0x241138),1.4)
            G.polyline({ fx+3,fy,fx+25,fy-9,fx+52,fy-2 },2,H(0xB66BFF))
        elseif p.style=='starfire' then
            G.glow(bx+8,by,21,H(0x5CFF6A),.75)
            G.poly({ bx+3,by-6,bx+38,by,bx+3,by+6 },H(0xCFFF97))
        end
        return
    end
    if m<1 or m>3 or p.style=='' then return end
    local e, u = math.max(0, p.ext), p.stroke
    if p.style == 'robin' then
        local angle=math.atan2(fy-by,fx-bx)
        local dx, dy = math.cos(angle), math.sin(angle)
        G.line(fx - dx * 28, fy - dy * 28, fx + dx * 57, fy + dy * 57, 6, INK)
        G.line(fx - dx * 28, fy - dy * 28, fx + dx * 57, fy + dy * 57, 3.3, H(0xC5CEDC))
        G.line(fx - dx * 17, fy - dy * 17, fx + dx * 3, fy + dy * 3, 4, H(0x38475D))
        G.oellipse(bx,by,4,3.5,H(0x1F9C5B),1.2)
        G.oellipse(fx,fy,4.5,3.8,H(0x22B86C),1.3)
        if p.active then
            G.line(fx + dx * 34 - 10, fy + dy * 34 - 7, fx + dx * 57 - 10, fy + dy * 57 - 7, 2, H(0xFFE04D))
            if m==1 then
                G.poly({ fx+dx*30-dy*4,fy+dy*30+dx*4,
                    fx+dx*78,fy+dy*78,
                    fx+dx*30+dy*4,fy+dy*30-dx*4 },G.fade(H(0xFFE04D),.55))
            end
        end
    elseif p.style == 'beast' then
        -- Brief paw morphs: the gloves grow into green three-clawed hands.
        for i = 1, 2 do
            if m == 3 or (m == 1 and i == 1) or (m == 2 and i == 2) then
                local x, y = if i == 1 then fx else bx, if i == 1 then fy else by
                G.oellipse(x, y, 5 + e * 3, 5 + e * 2, H(0xA2E84A), 1.7)
                for j = -1, 1 do
                    G.poly({ x + 3, y + j * 4 - 2, x + 11 + e * 3, y + j * 4, x + 3, y + j * 4 + 2 }, H(0xF6F1D6), 1)
                    if p.active then G.line(x + 16, y + j * 6 - 12, x + 23, y + j * 6 + 4, 1.8, H(0xC6FF92)) end
                end
            end
        end
    elseif p.active then
        local x, y = if m == 2 then bx else fx, if m == 2 then by else fy
        if p.style == 'cyborg' then
            G.polyline({ x - 14, y - 18, x + 6, y - 12, x + 21, y + 2 }, 3, H(0x91EEF1))
            if m == 3 then
                G.polyline({ x + 5, y + 10, x + 24, y + 4, x + 38, y + 15 }, 3, H(0xD8FAFF))
            end
        elseif p.style == 'starfire' then
            local radius = if m == 3 then 26 else 15
            G.glow(x + radius * 0.7, y, radius, H(0x5CFF6A), .9)
            G.ellipse(x + 9, y, radius * .65, radius * .48, H(0xDFFF9E))
            G.poly({ x + 12, y - 7, x + radius * 2, y, x + 12, y + 7 }, H(0x9DFF76))
            if m == 3 then G.glow(bx + 10, by, 21, H(0x5CFF6A), .8) end
        elseif p.style == 'raven' then
            local endX = x + (if m == 3 then 62 else 52)
            local endY = y + (if m == 2 then 12 - u * 32 else 0)
            G.contour({ x, y - 4, x + 18, y - 26, endX - 12, endY - 24, endX, endY,
                endX - 17, endY - 7, x + 23, y + 16, x, y + 4, x - 4, y + 1, x - 4, y - 1, x, y - 4 }, H(0x241138), 1.5)
            G.polyline({ x + 3, y, x + 24, y - 9, endX - 4, endY }, 2, H(0xB66BFF))
            if m == 3 then
                G.glow(endX - 7, endY, 22, H(0x8A3CFF), .65)
                G.oellipse(endX - 7, endY, 8, 20, H(0x251332), 2)
            end
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
    local flare=p.walk*23+p.dash*17+math.abs(p.ext)*14+(if p.air then 14+(1-math.abs(p.rise))*13 else 0)+math.sin(p.t*(if p.air then 10 else 7))*3
    local lift=p.walk*20+p.dash*9+(if p.air then 15 else 0)
    -- Cape roots share the torso transform during running and attacks.
    leanBegin(p, hipY)
    if titleFacing then
        G.poly({ -13, sh, 14, sh, 19 + flare * 0.4, -11, 2, -9, -18 - flare, -11 }, R_CAPE, 2.5)
        G.line(-8, sh + 6, -14 - flare, -12, 2, H(0x8F6A1E))
    else
        G.contour({ -13,sh, -24,sh+13,-29-flare,-31-lift,-45-flare,-12-lift,
            -33-flare,-14-lift,-27-flare,-8-lift,-24-flare,-5-lift,
            -17-flare,-14-lift,-11-flare,-6-lift,-8-flare,-4-lift,
            0,-12,9,-11,14,-10, 9,-28,12,sh+9,10,sh,
            2,sh-3,-8,sh-3,-13,sh },R_CAPE,2)
        G.contour({ -10,sh+6, -16,sh+25,-23-flare,-21-lift,-33-flare,-13-lift,
            -21-flare,-17-lift,-11,-13,1,-13, -8,-25,-7,sh+19,-10,sh+6 },H(0xB28B2B))
        G.line(-9,sh+9,-24-flare,-16-lift,1.3,H(0xFFE674))
    end
    G.restore()
    -- back arm
    leanBegin(p, hipY)
    local bsx: number, bsy: number, bhx: number, bhy: number
    if titleFacing then
        bsx, bsy = -9, sh + 3
        bhx, bhy = hand(p, false, bsx, bsy, -11, hipY - 3, 19)
    else
        bsx, bsy = 11, sh + 2
        bhx, bhy = hand(p, false, bsx, bsy, 18, hipY - 10, 25)
    end
    local bex, bey = armJoint(p, bsx, bsy, bhx, bhy, if p.move == 0 then 6 else 3)
    bodyLimb(p, bsx, bsy, bex, bey, bhx, bhy, 4.5, G.shade(R_SKIN, -0.12))
    if titleFacing then mitt(bhx, bhy, 4.8, G.shade(R_GREEN, -0.15), true)
    else
        forearmShell(bex,bey,bhx,bhy,.44,5.8,3.2,G.shade(R_GREEN,-.15),nil)
        fist(bex,bey,bhx,bhy,.92,G.shade(R_GREEN,-.15))
    end
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
        bodyLimb(p, hx, hipY, kx, ky, fx, fy - (if titleFacing then 3 else 4), 6.5, G.shade(R_GREEN, k))
        -- One costume drawing for menus and play: short black boots with the
        -- same rounded toe. Only the ankle pitch changes with the gait.
        local bootColor=G.shade(R_HAIR,k)
        G.limb(lerp(kx,fx,.5),lerp(ky,fy,.5),fx,fy-3,fx,fy-3,6.5,bootColor)
        G.save();G.translate(fx,fy-3)
        G.rotate(footPitch(p,i==2))
        G.oellipse(3,.5,5.5,3.4,bootColor,2)
        G.restore()
    end
    leanBegin(p, hipY)
    -- black neck
    G.poly({ -5, sh - 7, 5, sh - 7, 4, sh + 8, -4, sh + 8 }, R_HAIR)
    -- The menu is the model sheet: both views share the tunic silhouette.
    -- Perspective comes from the side shading, not an enlarged chest.
    G.poly({ -11, sh - 1, 12, sh - 1, 10, hipY + 2, -9, hipY + 2 }, R_RED, 2.5)
    if not titleFacing then
        G.poly({ 8, sh, 12, sh, 10, hipY + 2, 6, hipY + 2 }, G.shade(R_RED, -.18))
    end
    G.poly({ -5, sh - 1, 0, sh + 4, 5, sh - 1 }, R_HAIR)
    G.line(-6, sh + 9, -1, sh + 8, 2, R_YELLOW)
    G.line(-6, sh + 14, -1, sh + 13, 2, R_YELLOW)
    -- R badge
    G.oellipse(5.5, sh + 11, 3.4, 3.4, R_YELLOW, 1.5)
    G.save()
    G.translate(5.5, sh + 11)
    G.scale(p.flip, 1)
    G.label('R', -1.1, -2, 4.2, R_HAIR)
    G.restore()
    -- belt
    G.rrect(-10, hipY - 4, 21, 4.5, 2, R_YELLOW, 1.5)
    G.oellipse(0, hipY - 2, 2.6, 2.6, R_YELLOW, 1.5)
    G.circle(0, hipY - 2, 1.2, H(0xD08A1E))
    -- green short sleeves
    G.oellipse(if titleFacing then -10 else 11, sh + 2, 4.5, 3.8, G.shade(R_GREEN, -0.12), 1.8)
    G.oellipse(if titleFacing then 11 else -10, sh + 2, 4.5, 3.8, R_GREEN, 1.8)
    -- head
    headBegin(p,2,sh-26)
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
        fsx, fsy = -10, sh + 4
        fhx, fhy = hand(p, true, fsx, fsy, 14, hipY - 7, 33)
    end
    local fex, fey = armJoint(p, fsx, fsy, fhx, fhy, if p.move == 0 then -6 else 3)
    bodyLimb(p, fsx, fsy, fex, fey, fhx, fhy, 4.5, R_SKIN)
    if titleFacing then mitt(fhx, fhy, 4.2, R_GREEN, true)
    else
        forearmShell(fex,fey,fhx,fhy,.4,6.2,3.4,R_GREEN,nil)
        fist(fex,fey,fhx,fhy,1,R_GREEN)
    end
    normalFx(p, fhx, fhy, bhx, bhy)
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
    local ex, ey = armJoint(p, sx, sy, hx, hy, if front then -4 else 4)
    if p.style ~= '' then
        -- The same silver armour and upper-arm cyan inset as the menu model.
        bodyLimb(p,sx,sy,ex,ey,ex,ey,10,G.shade(C_GREY,k))
        bodyLimb(p,lerp(sx,ex,.25),lerp(sy,ey,.25),lerp(sx,ex,.5),lerp(sy,ey,.5),lerp(sx,ex,.6),lerp(sy,ey,.6),7,G.shade(C_CYAN,k-.1))
        G.oellipse(ex,ey,6,5.5,G.shade(C_GREY,k),1.6)
        forearmShell(ex,ey,hx,hy,.08,10.5,8.2,G.shade(C_GREY,k),nil)
        local dx,dy=hx-ex,hy-ey
        local length=math.max(1,math.sqrt(dx*dx+dy*dy))
        G.line(lerp(ex,hx,.4)+dy/length*3,lerp(ey,hy,.4)-dx/length*3,
            lerp(ex,hx,.9)+dy/length*3,lerp(ey,hy,.9)-dx/length*3,1.3,C_TRACE)
        if front and (p.move == 5 or p.move == 9) then
            G.glow(hx+6,hy,30,H(0x9FE8FF),.9)
            G.oellipse(hx+4,hy,8,8,C_GREY,1.6)
            G.circle(hx+4,hy,5,H(0xDDF8FF))
        else
            fist(ex,ey,hx,hy,1.8,G.shade(C_LIGHT,k))
        end
        return
    end
    -- Portrait arm retains the original front-facing drawing.
    bodyLimb(p, sx, sy, ex, ey, ex, ey, 14, G.shade(C_GREY, k))
    bodyLimb(p, sx, sy, lerp(sx, ex, 0.25), lerp(sy, ey, 0.25), lerp(sx, ex, 0.5), lerp(sy, ey, 0.5), 11.5, G.shade(C_CYAN, k - 0.1))
    G.polyline({ lerp(sx, ex, 0.3), lerp(sy, ey, 0.3) + 3, lerp(sx, ex, 0.55), lerp(sy, ey, 0.55) + 3 }, 1.3, C_TRACE)
    G.oellipse(ex, ey, 6, 5.5, G.shade(C_GREY, k), 2)
    bodyLimb(p, ex, ey, ex, ey, hx, hy, 20, G.shade(C_GREY, k))
    G.line(lerp(ex, hx, 0.4), lerp(ey, hy, 0.4) - 3, lerp(ex, hx, 0.9), lerp(ey, hy, 0.9) - 3, 1.3, C_TRACE)
    if front and (p.move == 5 or p.move == 9) then
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
        cyborgArm(p, false, 22, sh + 7, 22, hipY - 7)
        shoulderPad(23, sh, -0.15)
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
        bodyLimb(p,hx,hipY,kx,ky,fx,fy-4,if titleFacing then 11.5 else 9.5,G.shade(C_GREY,k))
        bodyLimb(p,hx,hipY+2,lerp(hx,kx,.4),lerp(hipY,ky,.4),lerp(hx,kx,.6),lerp(hipY,ky,.6),if titleFacing then 12 else 10,G.shade(C_DARK,k-.15))
        -- Shared white shin armour, rounded boot and toe groove.
        G.limb(kx,ky+2,lerp(kx,fx,.5),lerp(ky+2,fy-5,.5),fx,fy-5,16,G.shade(C_LIGHT,k))
        G.save();G.translate(fx,fy-4);G.rotate(footPitch(p,i==2))
        G.oellipse(3.5,0,11,5,G.shade(C_LIGHT,k),1.7)
        G.line(-2,-1.5,8,-1.5,1.6,C_DARK)
        G.restore()
    end
    leanBegin(p, hipY)
    -- Shared menu armour proportions; only the inset seam turns toward +x.
    G.contour({ -27, sh - 4, -10, sh - 9, 12, sh - 9, 27, sh - 4,
        26, sh + 20, 21, hipY - 3, 14, hipY + 3,
        6, hipY + 7, -8, hipY + 7, -15, hipY + 2,
        -23, hipY - 9, -27, sh + 13, -27, sh - 4,
    }, C_GREY, 2)
    G.contour({ -23, sh - 2, -9, sh - 5, 12, sh - 5, 23, sh - 2,
        22, sh + 7, 19, sh + 19, 16, sh + 24,
        5, sh + 27, -8, sh + 27, -17, sh + 23,
        -21, sh + 14, -23, sh + 6, -23, sh - 2,
    }, C_LIGHT, 1.5)
    if titleFacing then
        G.line(0, sh + 1, 0, sh + 23, 1.3, C_DARK)
        G.oellipse(0, sh + 29, 5, 3, C_CYAN, 1.2)
        G.circle(-1, sh + 28, 1, G.WHITE)
    else
        G.line(7, sh + 1, 5, sh + 23, 1.3, C_DARK)
        G.oellipse(4, sh + 29, 5, 3, C_CYAN, 1.2)
        G.circle(3, sh + 28, 1, G.WHITE)
    end
    -- belt
    G.rrect(-14, hipY - 8, 28, 9, 3, C_DARK, 2)
    G.rrect(-5, hipY - 7, 10, 7, 2, C_GREY, 1.5)
    headBegin(p,2,sh-24)
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
        cyborgArm(p, true, -21, sh + 10, 10, hipY + 1)
        shoulderPad(-21, sh + 3, 0)
        local fx, fy = hand(p, true, -21, sh + 10, 10, hipY + 1, 64)
        local bx, by = hand(p, false, 22, sh + 7, 22, hipY - 7, 36)
        normalFx(p, fx, fy, bx, by)
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
        bsx, bsy = 10, sh + 2
        bhx, bhy = hand(p, false, bsx, bsy, 16, hipY - 8, 26)
    end
    local bex, bey = armJoint(p, bsx, bsy, bhx, bhy, 4)
    bodyLimb(p, bsx, bsy, bex, bey, bhx, bhy, 4, B_SUIT)
    if titleFacing then
        G.oellipse(lerp(bex, bhx, 0.6), lerp(bey, bhy, 0.6), 4, 3.5, B_GREY, 1.6)
        mitt(bhx, bhy, 4.6, G.shade(B_GREY, -0.08), false)
    else
        forearmShell(bex,bey,bhx,bhy,.58,4.5,3.5,G.shade(B_GREY,-.1),nil)
        fist(bex,bey,bhx,bhy,.95,G.shade(B_GREY,-.1))
    end
    G.restore()
    local ffx, ffy = foot(p, true, 3, hipY, 4)
    local bfx, bfy = foot(p, false, -3, hipY, -3)
    for i = 1, 2 do
        local hx = if i == 1 then -3 else 3
        local fx = if i == 1 then bfx else ffx
        local fy = if i == 1 then bfy else ffy
        local kx, ky = legJoint(p, hx, hipY, fx, fy)
        bodyLimb(p, hx, hipY, kx, ky, fx, fy - (if titleFacing then 3 else 4), 4.5, B_SUIT)
        -- The grey shoes are part of the costume in both views.
        G.save();G.translate(fx,fy-3);G.rotate(footPitch(p,i==2))
        G.oellipse(2,.5,5,3,B_GREY,1.8)
        G.restore()
    end
    leanBegin(p, hipY)
    G.poly({ -9, sh - 1, 10, sh - 1, 8, hipY + 1, -7, hipY + 1 }, B_SUIT, 2.5)
    -- magenta collar, chest strap and hip straps
    G.rrect(-5, sh - 2, 11, 4, 2, B_MAGENTA, 1.4)
    if titleFacing then
        G.rrect(-2, sh, 4.5, hipY - sh + 1, 1.6, B_MAGENTA, 1.2)
    else
        G.poly({ 1, sh, 6, sh, 5, hipY + 1, 0, hipY + 1 }, B_MAGENTA, 1)
    end
    G.rrect(-2, hipY, 4.5, 7, 1.6, B_MAGENTA, 1.2)
    -- grey shoulder caps and belt
    if titleFacing then
        G.oellipse(-8, sh + 1, 4, 3, B_GREY, 1.6)
        G.oellipse(9, sh + 1, 4.5, 3.5, B_GREY, 1.6)
    else
        G.oellipse(10, sh, 3, 3, B_GREY, 1.2)
        G.oellipse(-9, sh + 3, 4.5, 3.5, B_GREY, 1.4)
    end
    G.rrect(-8, hipY - 4, 16, 4.5, 2, B_GREY, 1.5)
    G.oellipse(0, hipY - 2, 2.6, 2.6, G.shade(B_GREY, 0.15), 1.2)
    headBegin(p,2,sh-24)
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
        fsx, fsy = -9, sh + 4
        fhx, fhy = hand(p, true, fsx, fsy, 13, hipY - 5, 31)
    end
    local fex, fey = armJoint(p, fsx, fsy, fhx, fhy, -4)
    bodyLimb(p, fsx, fsy, fex, fey, fhx, fhy, 4, B_SUIT)
    if titleFacing then
        G.oellipse(lerp(fex, fhx, 0.6), lerp(fey, fhy, 0.6), 4, 3.5, B_GREY, 1.6)
        mitt(fhx, fhy, 4.8, B_GREY, false)
    else
        forearmShell(fex,fey,fhx,fhy,.55,5,3.8,B_GREY,nil)
        fist(fex,fey,fhx,fhy,1,B_GREY)
    end
    normalFx(p, fhx, fhy, bhx, bhy)
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
    local sway=p.walk*29+p.dash*20+math.sin(p.t*6)*p.walk*6+math.abs(p.ext)*16+(if p.air then 14+(1-math.abs(p.rise))*12 else 0)
    local lift=p.walk*18+p.dash*13+(if p.air then 9 else 0)
    local top = -63 + b
    leanBegin(p, -40)
    local showArms=p.move~=0 or p.hurt or ((p.air or p.walk>.12) and not titleFacing)
    local fsx: number, fsy: number, bsx: number, bsy: number
    if titleFacing then
        fsx, fsy = 8, top + 8
        bsx, bsy = -6, top + 8
    else
        fsx, fsy = -9, top + 8
        bsx, bsy = 11, top + 6
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
            fhx, fhy = hand(p, true, fsx, fsy, 12, top + 24, 35)
            bhx, bhy = hand(p, false, bsx, bsy, 19, top + 21, 32)
        end
    end
    if showArms then
        local ex, ey = armJoint(p, bsx, bsy, bhx, bhy, 4)
        bodyLimb(p, bsx, bsy, ex, ey, bhx, bhy, 6.5, G.shade(V_CLOAK, -0.15))
        if titleFacing then G.oellipse(bhx, bhy, 4.4, 4.4, G.shade(V_SKIN, -0.15), 2)
        else fist(ex,ey,bhx,bhy,.9,G.shade(V_SKIN,-.15)) end
    end
    -- One bell-shaped cloak model. Motion pulls the hem back without widening
    -- the shoulders or upper body compared with the start menu.
    local trail = if titleFacing then 0 else sway
    local hemLift = if titleFacing then 0 else lift
    G.contour({ -12, top, -3, top - 4, 9, top - 4, 14, top,
        16, top + 28, 17, -13, 27 + (if titleFacing then sway else 0), -3 - hemLift * .2,
        14, 5 - hemLift * .2, -11 - trail * .4, 5 - hemLift * .6, -23 - sway, -3 - hemLift,
        -17 - trail * .45, -23 - hemLift * .5, -16, top + 16, -12, top,
    }, V_CLOAK, 1.8)
    if titleFacing then
        G.line(1, top + 6, 1, -1, 2, INK)
    else
        G.contour({ -10,top+10, -16,top+30,-17-sway*.6,-12-lift*.8,-22-sway,-3-lift,
            -17-sway*.6,-lift*.6,-10,-2-lift*.4,-4,1-lift*.2,
            -9,-15,-5,top+26,-10,top+10 },V_FOLD)
        G.polyline({ 6,top+6,8,-28,5,-1-lift*.3 },1.5,INK)
    end
    G.line(-8,top+10,-12-sway*.5,-3-lift*.7,1.8,V_FOLD)
    if titleFacing then
        G.line(10, top + 10, 14, -3, 1.8, V_FOLD)
    else
        G.line(10, top + 10, 14, -3 - lift * .2, 1.8, V_FOLD)
    end
    -- Let the kick emerge from the cloak so its direction matches the hitbox.
    if p.move==4 and titleFacing then
        local fx, fy = foot(p, true, 3, -30, 5)
        local kx, ky = joint(3, -32, fx, fy - 3, -3)
        bodyLimb(p, 3, -32, kx, ky, fx, fy - 3, 6, INK)
        G.oellipse(fx + 4, fy - 3, 7, 4, V_CLOAK, 1.4)
    end
    headBegin(p,1,top-26)
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
        G.poly({ 6, top + 3, 10, top + 8, 6, top + 13.5, 2, top + 8 }, H(0xD8A93A), 1.5)
        G.circle(6, top + 8, 1.6, H(0xD8203A))
    end
    if showArms then
        local ex, ey = armJoint(p, fsx, fsy, fhx, fhy, -4)
        bodyLimb(p, fsx, fsy, ex, ey, fhx, fhy, 6.5, V_CLOAK)
        if titleFacing then G.oellipse(fhx, fhy, 4.6, 4.6, V_SKIN, 2)
        else fist(ex,ey,fhx,fhy,1,V_SKIN) end
        glowHands(p, fhx, fhy, bhx, bhy, H(0x8A3CFF))
        normalFx(p, fhx, fhy, bhx, bhy)
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

local function starfireCuff(ex: number, ey: number, hx: number, hy: number, front: boolean)
    G.save();G.translate(lerp(ex,hx,.55),lerp(ey,hy,.55))
    G.rotate(math.atan2(hy-ey,hx-ex)-math.pi/2)
    G.oellipse(0,0,if front then 4.6 else 4.2,if front then 4.2 else 3.8,G.shade(S_SILVER,if front then 0 else -.15),if front then 1.8 else 1.6)
    if front then G.circle(0,0,1.6,S_GEM) end
    G.restore()
end

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
    -- Hair roots move with the head; only the trailing tips sway independently.
    leanBegin(p, hipY)
    headBegin(p,hx,hy)
    if titleFacing then
        starfireHairBack(hx, hy, p.t, p.walk, -48)
    else
        Profile.starfireHair(hx+3,hy,p.t,p.walk+p.dash*.7+math.abs(p.ext)*.65+(if p.air then .4+math.max(0,-p.rise)*.7 else 0))
    end
    G.restore()
    G.restore()
    leanBegin(p, hipY)
    local bsx: number, bsy: number, bhx: number, bhy: number
    if titleFacing then
        bsx, bsy = -7, sh + 3
        bhx, bhy = hand(p, false, bsx, bsy, -11, hipY - 2, 24)
    else
        bsx, bsy = 8, sh + 2
        bhx, bhy = hand(p, false, bsx, bsy, 17, hipY - 8, 28)
    end
    local bex, bey = armJoint(p, bsx, bsy, bhx, bhy, 4)
    bodyLimb(p, bsx, bsy, bex, bey, bhx, bhy, 3.6, G.shade(S_SKIN, -0.12))
    starfireCuff(bex,bey,bhx,bhy,false)
    if titleFacing then
        G.oellipse(bhx, bhy, 3.8, 3.8, G.shade(S_SKIN, -0.12), 1.8)
    else
        fist(bex,bey,bhx,bhy,.8,G.shade(S_SKIN,-.12))
    end
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
        bodyLimb(p, x, hipY, kx, ky, fx, fy - 4, 5.5, G.shade(S_SKIN, k))
        -- Shared knee-high purple boot, round silver plate and pointed toe.
        G.limb(kx,ky,lerp(kx,fx,.5),lerp(ky,fy-4,.5),fx,fy-4,6,G.shade(S_SKIRT,k))
        G.oellipse(kx,ky,3.6,3.2,G.shade(S_SILVER,k),1.6)
        G.save();G.translate(fx,fy-3);G.rotate(footPitch(p,i==2))
        G.poly({ -3,-4,4,-3,2,5 },G.shade(S_SKIRT,k),1.8)
        G.restore()
    end
    leanBegin(p, hipY)
    -- The same narrow torso, collar and crop top as the menu model.
    G.poly({ -8, sh - 1, 9, sh - 1, 7, hipY + 1, -6, hipY + 1 }, S_SKIN, 2.2)
    G.rrect(-7, sh - 2, 15, 5, 2.5, S_SILVER, 1.8)
    G.oellipse(0, sh, 5, 3.5, S_PURPLE, 1.6)
    G.poly({ -7, sh + 2, 8, sh + 2, 6, sh + 13, -5, sh + 13 }, S_PURPLE, 2)
    if titleFacing then
        G.oellipse(0, sh + 2, 3, 3, S_SILVER, 1)
        G.circle(0, sh + 2, 1.5, S_GEM)
    else
        G.oellipse(4, sh + 2, 3, 3, S_SILVER, 1)
        G.circle(4, sh + 2, 1.5, S_GEM)
    end
    -- purple skirt with a silver front plate
    G.poly({ -6, hipY - 3, 7, hipY - 3, 10, hipY + 8, -8, hipY + 8 }, S_SKIRT, 2.2)
    G.rrect(-6, hipY - 4, 13, 3, 1, S_SILVER, 1)
    headBegin(p,hx,hy)
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
        fsx, fsy = -8, sh + 4
        fhx, fhy = hand(p, true, fsx, fsy, 12, hipY - 5, 34)
    end
    local fex, fey = armJoint(p, fsx, fsy, fhx, fhy, -4)
    bodyLimb(p, fsx, fsy, fex, fey, fhx, fhy, 3.6, S_SKIN)
    G.oellipse(fsx,fsy-1,4.2,3.8,S_SILVER,1.8)
    starfireCuff(fex,fey,fhx,fhy,true)
    if titleFacing then
        G.oellipse(fhx, fhy, 4, 4, S_SKIN, 1.8)
    else
        fist(fex,fey,fhx,fhy,.9,S_SKIN)
    end
    glowHands(p, fhx, fhy, bhx, bhy, H(0x5CFF6A))
    normalFx(p, fhx, fhy, bhx, bhy)
    G.restore()
    G.restore()
end

-- Small character-specific flight cues sit behind the figure, below the face.
local function flightFx(p: P.Pose)
    if (not p.air and p.walk<.1) or p.down>0 or p.hurt then return end
    local strength=if p.air then math.min(1,p.airTime/.1) else p.walk*.7
    local clock=if p.air then p.airTime else p.t
    if p.style=='starfire' then
        for i=0,2 do
            local k=(clock*2.5+i/3)%1
            G.circle(-16-i*8-p.walk*k*25,4+k*22,1.5+(1-k)*3,G.fade(H(0xACFF72),(1-k)*strength*.65))
        end
    elseif p.style=='raven' then
        G.ring(0,7,23+math.sin(clock*7)*4,5,1.5,G.fade(H(0xA574F1),strength*.6))
        for i=0,2 do
            local angle=clock*5+i*math.pi*2/3
            G.circle(math.cos(angle)*25,7+math.sin(angle)*5,2.2,G.fade(H(0xC8A3FF),strength*.7))
        end
    end
end

-- Public -----------------------------------------------------------------------------

HX.HEIGHTS = { robin = 130, cyborg = 143, starfire = 149, raven = 124, beast = 115 } :: { [string]: number }

-- Special-projectile attachment points use the same posed hands as the art.
-- Coordinates are local to the unmirrored fighter, with negative y upward.
function HX.projectileOrigin(kind: string, p: P.Pose): (number, number)
    local b = bob(p)
    if kind == 'cyborg' then
        local x, y = hand(p, true, -21, -83 + b, 10, -43 + b, 64)
        return bodyPoint(p,-44+b,x+4,y)
    elseif kind == 'starfire' then
        local x, y = hand(p, true, -8, -76 + b * 0.4, 12, -56 + b * 0.4, 34)
        local ox,oy=bodyPoint(p,-51+b*.4,x+4,y)
        return ox,oy-hoverOffset(p,10)
    end
    local x, y = hand(p, true, -10, -58 + b, 14, -41 + b, 33)
    return bodyPoint(p,-34+b,x+4,y)
end

function HX.isHero(kind: string): boolean
    return HX.HEIGHTS[kind] ~= nil
end

function HX.draw(kind: string, p: P.Pose, titleFacing: boolean?)
    p.style = if titleFacing then '' else kind
    if not titleFacing then flightFx(p);actionFx(p) end
    if not titleFacing and PowerArt.form(kind, p) then
        PowerArt.effects(kind, p)
        return
    end
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
    if not titleFacing then PowerArt.effects(kind, p) end
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
