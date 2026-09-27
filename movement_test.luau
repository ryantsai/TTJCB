-- Exercise the real game callbacks and state transitions without rendering.
local makeMain = require('game').create
local Art = require('art')
local Motion = require('motion')
local Attacks = require('attacks')
local Powers = require('powers')
local Arms = require('armature')

local function step(app: any, frames: number)
    for _ = 1, frames do
        app.advance(app, 1 / 60)
    end
end

local function key(app: any, code: number, down: boolean)
    app.keyboardEvent(app, { key = code, phase = if down then 'down' else 'up' })
end

local function press(app: any, code: number)
    key(app, code, true)
    step(app, 1)
    key(app, code, false)
    step(app, 1)
end

local function game(hero: number): any
    local app: any = (makeMain :: any)(nil)
    app.g.tutorialSeen=true -- Onboarding has its own real-input regression suite.
    press(app, 257) -- Enter the level map.
    press(app, 257) -- Open character selection from the map.
    app.g.slots[1].hero = hero
    press(app, 257)
    press(app, 257)
    step(app, 75)
    -- Keep a controlled arena; input, physics, combat and pose updates stay real.
    app.g.pending = {}
    app.g.lockX = 260
    app.g.bannerT = 0
    local f = app.g.slots[1].fighter
    app.g.fighters = { f }
    f.x = 600
    f.y = 590
    f.invuln = 100
    return app
end

local function target(app: any, dx: number): any
    local f = table.clone(app.g.slots[1].fighter)
    f.id = 100 + #app.g.fighters
    f.x += dx
    f.team = 2
    f.slot = 0
    f.kind = 'bot'
    f.state = 'target'
    f.hp = 1000
    f.maxHp = 1000
    f.invuln = 0
    f.pose = Art.newPose()
    f.hit = {}
    table.insert(app.g.fighters, f)
    return f
end

local function face(app: any, direction: number)
    press(app, if direction == 1 then 68 else 65)
end

local function pad(app: any, button: string, down: boolean)
    local event: any = {
        deviceId = 0, isStandardMapping = true, leftStick = Vector.xy(0, 0),
        dpadLeft = false, dpadRight = false, dpadUp = false, dpadDown = false,
        south = false, east = false, west = false, north = false,
        rightShoulder = false, rightTriggerPressed = false, rightTrigger = 0,
        start = false, forward = false, back = false,
    }
    if button == 'rt' then event.rightTrigger = if down then .9 else 0
    elseif button == 'a' then event.south = down
    elseif button == 'y' then event.north = down
    elseif button == 'b' then event.east = down
    elseif button == 'rb' then event.rightShoulder = down end
    app.gamepadEvent(app, event)
end

local function padMove(app: any, x: number, y: number, dpad: boolean?, attack: boolean?)
    app.gamepadEvent(app, {
        deviceId=0, isStandardMapping=true, leftStick=Vector.xy(if dpad then 0 else x, if dpad then 0 else y),
        dpadLeft=dpad and x<0, dpadRight=dpad and x>0, dpadUp=dpad and y<0, dpadDown=dpad and y>0,
        south=false, east=false, west=attack==true, north=false, rightShoulder=false,
        rightTriggerPressed=false, rightTrigger=0, start=false, forward=false, back=false,
    })
end

return function(): Tests
    return function(test: Tester)
        test.case('spawned Titans preserve the animated lineup height relationships', function(expect)
            local heights = {}
            for hero = 1, 5 do
                local app = game(hero)
                local f = app.g.slots[1].fighter
                heights[hero] = Art.height(f.kind) * f.scale
            end
            -- Broad reference ranges allow breathing, hair and hover while
            -- catching either uniform hero scaling or the wrong height order.
            expect(heights[2] / heights[1]).greaterThan(1.24)
            expect(heights[2] / heights[1]).lessThan(1.32)
            expect(heights[3] / heights[1]).greaterThan(1.04)
            expect(heights[3] / heights[1]).lessThan(1.15)
            expect(heights[4] / heights[1]).greaterThan(.77)
            expect(heights[4] / heights[1]).lessThan(.86)
            expect(heights[5] / heights[1]).greaterThan(.70)
            expect(heights[5] / heights[1]).lessThan(.78)
        end)
        test.case('resized Titans keep planted feet fixed during a running contact', function(expect)
            for _, hero in { 1, 2, 5 } do
                local app = game(hero)
                key(app, 68, true)
                step(app, 20)
                local f = app.g.slots[1].fighter
                f.pose.phase = .1
                local stride, lift = Motion.gait(f.kind, 0)
                local foot = Motion.stride(f.pose.phase, stride, lift)
                local plantedX = f.x + foot * f.scale
                step(app, 6)
                local nextFoot, nextY = Motion.stride(f.pose.phase, stride, lift)
                expect(nextY).is(0)
                expect(math.abs(f.x + nextFoot * f.scale - plantedX)).lessThan(.02)
            end
        end)
        test.case('strikes anticipate, hold through hit window, and recover smoothly', function(expect)
            for _, timing in { { 0.28, 0.06, 0.15 }, { 0.42, 0.12, 0.24 } } do
                local duration, first, last = timing[1], timing[2], timing[3]
                expect(Motion.strike(0, duration, first, last)).is(0)
                expect(Motion.windup(0, first, 0)).is(0)
                expect(Motion.windup(first * .55, first, -.35)).is(1)
                expect(Motion.windup(first, first, 1)).is(0)
                expect(Motion.windup(duration, first, 0)).is(0)
                expect(Motion.strike(first * 0.5, duration, first, last)).lessThan(0)
                expect(Motion.strike(first, duration, first, last)).is(1)
                expect(Motion.strike(last, duration, first, last)).is(1)
                local previous = 1
                for i = 1, 20 do
                    local time = last + (duration - last) * i / 20
                    local extension = Motion.strike(time, duration, first, last)
                    expect(extension).lessThanOrEqual(previous)
                    expect(extension).greaterThanOrEqual(0)
                    previous = extension
                end
                expect(Motion.strike(duration, duration, first, last)).is(0)
            end
        end)
        test.case('side-view elbows bend below forward fists and preserve both bone lengths', function(expect)
            for _, kind in { 'robin', 'cyborg', 'starfire', 'raven', 'beast' } do
                local upper, lower = Arms.lengths(kind)
                for _, target in { { 20, 13 }, { 30, 0 }, { 100, 0 }, { 0, 0 }, { -17, 46 } } do
                    local ex, ey, hx, hy = Arms.solve(kind, 0, 0, target[1], target[2])
                    expect(math.abs(math.sqrt(ex * ex + ey * ey) - upper)).lessThan(.001)
                    expect(math.abs(math.sqrt((hx - ex)^2 + (hy - ey)^2) - lower)).lessThan(.001)
                    if target[1] > 0 and target[2] >= 0 then
                        expect(ey).greaterThan(0)
                        -- Elbow stays on the same lower/back side of the shoulder-to-hand line.
                        expect(hx * ey - hy * ex).greaterThan(0)
                        for _, facing in { -1, 1 } do
                            expect(hx * facing * facing).greaterThan(0)
                            expect((hx * facing * ey - hy * ex * facing) * facing).greaterThan(0)
                        end
                    end
                end
            end
        end)
        test.case('keyboard moves and faces in all four directions', function(expect)
            for hero = 1, 5 do
                local app = game(hero)
                local f = app.g.slots[1].fighter
                key(app, 68, true)
                step(app, 12)
                expect(f.x).greaterThan(600)
                expect(f.facing).is(1)
                expect(f.pose.flip).is(1)
                key(app, 68, false)
                local x = f.x
                key(app, 65, true)
                step(app, 12)
                expect(f.x).lessThan(x)
                expect(f.facing).is(-1)
                expect(f.pose.flip).is(-1)
                key(app, 65, false)
                key(app, 87, true)
                step(app, 12)
                expect(f.y).lessThan(590)
                expect(f.facing).is(-1)
                key(app, 87, false)
                local y = f.y
                key(app, 83, true)
                step(app, 12)
                expect(f.y).greaterThan(y)
                key(app, 83, false)
                step(app, 1)
                expect(f.vx).is(0)
                expect(f.vy).is(0)
                expect(f.state).is('idle')
            end
        end)
        test.case('jump and landing preserve ground position', function(expect)
            for hero = 1, 5 do
                local app = game(hero)
                local f = app.g.slots[1].fighter
                press(app, 75)
                step(app, 10)
                expect(f.z).greaterThan(0)
                expect(f.pose.air).is(true)
                expect(f.y).is(590)
                step(app, 110)
                expect(f.z).is(0)
                expect(f.pose.air).is(false)
                expect(f.state).is('idle')
                expect(f.y).is(590)
            end
        end)
        test.case('tap and held jumps have distinct heights and readable takeoff, fall and landing', function(expect)
            for hero=1,5 do
                local peaks: { number }={}
                for _,held in {false,true} do
                    local app=game(hero)
                    local f=app.g.slots[1].fighter
                    key(app,75,true)
                    step(app,2)
                    expect(f.state).is('takeoff')
                    expect(f.z).is(0)
                    expect(f.pose.launch).greaterThan(0)
                    if not held then key(app,75,false) end
                    local peak=0
                    local rose,fell,landed=false,false,false
                    for _=1,120 do
                        step(app,1)
                        peak=math.max(peak,f.z)
                        rose=rose or (f.pose.air and f.pose.rise>.2)
                        fell=fell or (f.pose.air and f.pose.rise<-.2)
                        landed=landed or f.pose.land>0
                    end
                    expect(rose and fell and landed).is(true)
                    expect(f.z).is(0)
                    expect(f.pose.land).is(0)
                    expect(f.y).is(590)
                    expect(f.state).is('idle')
                    table.insert(peaks,peak)
                    key(app,75,false)
                end
                expect(peaks[2]-peaks[1]).greaterThan(25)
            end
        end)
        test.case('a jump pressed just before landing is buffered without automatic repeats', function(expect)
            local app=game(1)
            local f=app.g.slots[1].fighter
            press(app,75)
            for _=1,100 do
                step(app,1)
                if f.vz<0 and f.z<20 and f.z>0 then break end
            end
            expect(f.pose.air).is(true)
            press(app,75)
            local relaunched=false
            for _=1,20 do
                step(app,1)
                relaunched=relaunched or f.vz>200
            end
            expect(relaunched).is(true)
            step(app,120)
            expect(f.state).is('idle')
            expect(f.z).is(0)
        end)
        test.case('gamepad A supports the same tap and hold jump control', function(expect)
            local peaks: { number }={}
            for _,held in {false,true} do
                local app=game(1)
                app.g.slots[1].dev='pad0'
                local f=app.g.slots[1].fighter
                pad(app,'a',true)
                step(app,2)
                if not held then pad(app,'a',false) end
                local peak=0
                for _=1,100 do
                    step(app,1)
                    peak=math.max(peak,f.z)
                end
                expect(f.state).is('idle')
                table.insert(peaks,peak)
            end
            expect(peaks[2]-peaks[1]).greaterThan(25)
        end)
        test.case('air attacks have a forward hit window and recover into flight', function(expect)
            for _,direction in {-1,1} do
                local app=game(1)
                local f=app.g.slots[1].fighter
                face(app,direction)
                key(app,75,true)
                step(app,10)
                local front=target(app,direction*60)
                local back=target(app,-direction*60)
                front.z=f.z;front.vz=f.vz
                back.z=f.z;back.vz=f.vz
                press(app,74)
                expect(front.hp).is(1000)
                expect(f.pose.active).is(false)
                step(app,8)
                expect(front.hp).lessThan(1000)
                expect(back.hp).is(1000)
                local health=front.hp
                step(app,18)
                expect(front.hp).is(health)
                expect(f.pose.active).is(false)
                step(app,80)
                expect(f.state).is('idle')
                expect(f.z).is(0)
                key(app,75,false)
            end
        end)
        test.case('Robin keeps a rigid two-handed staff throughout all three swings', function(expect)
            local upper,lower=Arms.lengths('robin')
            for combo=1,3 do
                local attack=Attacks.get('robin',combo)
                for frame=0,60 do
                    local t=frame/60*attack.duration
                    local e=Motion.strike(t,attack.duration,attack.first,attack.last)
                    local w=Motion.windup(t,attack.first,e)
                    local u=math.clamp((t-attack.first)/(attack.last-attack.first),0,1)
                    local fx,fy,bx,by=Motion.staff(combo,e,w,u,-62)
                    expect(math.abs(math.sqrt((fx-bx)^2+(fy-by)^2)-14)).lessThan(.001)
                    expect(math.sqrt((fx+10)^2+(fy+58)^2)).lessThanOrEqual(upper+lower)
                    expect(math.sqrt((bx-11)^2+(by+60)^2)).lessThanOrEqual(upper+lower)
                end
            end
        end)
        test.case('gamepad diagonal speed matches keyboard diagonal speed', function(expect)
            local app = game(1)
            key(app, 68, true)
            key(app, 83, true)
            local keyboard = app.g.devs.kb1
            local magnitude = math.sqrt(keyboard.mx ^ 2 + keyboard.my ^ 2)
            local event: any = {
                deviceId = 0, isStandardMapping = true, leftStick = Vector.xy(1, 1),
                dpadLeft = false, dpadRight = false, dpadUp = false, dpadDown = false,
                south = false, east = false, west = false, north = false,
                rightShoulder = false, rightTriggerPressed = false, rightTrigger = 0,
                start = false, forward = false, back = false,
            }
            app.gamepadEvent(app, event)
            local pad = app.g.devs.pad0
            expect(math.abs(math.sqrt(pad.mx ^ 2 + pad.my ^ 2) - magnitude)).lessThan(0.0001)
        end)
        test.case('jump kick follows the newly selected direction', function(expect)
            local app = game(1)
            local f = app.g.slots[1].fighter
            key(app, 68, true)
            press(app, 75)
            press(app, 74)
            key(app, 68, false)
            key(app, 65, true)
            step(app, 4)
            expect(f.state).is('jumpatk')
            expect(f.vx).lessThan(0)
            expect(f.facing).is(-1)
            expect(f.pose.flip).is(-1)
        end)
        test.case('attacks damage and knock opponents only in the facing direction', function(expect)
            for hero = 1, 5 do
                for _, dir in { -1, 1 } do
                    local app = game(hero)
                    face(app, dir)
                    local front = target(app, dir * 70)
                    local back = target(app, -dir * 70)
                    press(app, 74)
                    step(app, 8)
                    expect(front.hp).lessThan(1000)
                    expect(back.hp).is(1000)
                    expect(front.vx * dir).greaterThan(0)
                    expect(app.g.slots[1].fighter.pose.move).is(1)
                    expect(app.g.slots[1].fighter.pose.flip).is(dir)
                end
            end
        end)
        test.case('all 15 normal moves chain, hit once during their window, and finish in either direction', function(expect)
            for hero = 1, 5 do
                for _, dir in { -1, 1 } do
                    for combo = 1, 3 do
                        local app = game(hero)
                        face(app, dir)
                        local f = app.g.slots[1].fighter
                        local energy = app.g.slots[1].energy
                        press(app, 74)
                        -- Reach later moves through the real input buffer, without a target.
                        for stage = 1, combo - 1 do
                            for _ = 1, 15 do
                                if f.st > .065 then break end
                                step(app, 1)
                            end
                            press(app, 74)
                            for _ = 1, 60 do
                                if f.combo > stage then break end
                                step(app, 1)
                            end
                            expect(f.combo).is(stage + 1)
                        end
                        local attack = Attacks.get(f.kind, combo)
                        local opponent = target(app, dir * 55)
                        local behind = target(app, -dir * 65)
                        local distant = target(app, dir * (attack.reach + 70))
                        local total = math.floor(attack.damage * f.power + .5)
                        local sawActive = false
                        for _ = 1, 75 do
                            if f.state ~= 'attack' then break end
                            step(app, 1)
                            if f.state == 'attack' and f.st < attack.first then expect(opponent.hp).is(1000) end
                            if f.pose.active then
                                sawActive = true
                                expect(f.pose.ext).is(1)
                                expect(f.pose.move).is(combo)
                                expect(f.pose.style).is(f.kind)
                            end
                            -- Keep a hittable target inside the box to catch repeat-hit bugs.
                            opponent.x = f.x + dir * 55
                            opponent.y = f.y
                            opponent.z = 0
                            opponent.invuln = 0
                            if combo < 3 then opponent.state = 'target' end
                        end
                        expect(sawActive).is(true)
                        expect(opponent.hp).is(1000 - total)
                        expect(behind.hp).is(1000)
                        expect(distant.hp).is(1000)
                        expect(f.state).is('idle')
                        expect(f.pose.active).is(false)
                        expect(app.g.slots[1].energy).greaterThanOrEqual(energy)
                        if combo == 3 then expect(opponent.state).is('down') end
                    end
                end
            end
        end)
        test.case('projectiles leave the hand and travel in both facing directions', function(expect)
            for _, hero in { 1, 3 } do
                for _, dir in { -1, 1 } do
                    local app = game(hero)
                    face(app, dir)
                    local f = app.g.slots[1].fighter
                    press(app, 76)
                    step(app, 9)
                    local shot = app.g.shots[1]
                    expect(shot ~= nil).is(true)
                    if shot then
                        expect((shot.x - f.x) * dir).greaterThan(0)
                        expect(shot.vx * dir).greaterThan(0)
                        local _, oy = Art.projectileOrigin(f.kind, f.pose)
                        expect(math.abs(shot.z - (f.z - oy * f.scale))).lessThan(2)
                    end
                end
            end
        end)
        test.case('Cyborg cannon hits ahead and Raven burst hits both sides', function(expect)
            for _, hero in { 2, 4 } do
                for _, dir in { -1, 1 } do
                    local app = game(hero)
                    face(app, dir)
                    local front = target(app, dir * 180)
                    local back = target(app, -dir * 180)
                    press(app, 76)
                    step(app, 30)
                    expect(front.hp).lessThan(1000)
                    if hero == 2 then
                        expect(back.hp).is(1000)
                    else
                        expect(back.hp).lessThan(1000)
                    end
                end
            end
        end)
        test.case('Beast Boy charges and hits in his facing direction', function(expect)
            for _, dir in { -1, 1 } do
                local app = game(5)
                face(app, dir)
                local f = app.g.slots[1].fighter
                local x = f.x
                local opponent = target(app, dir * 180)
                press(app, 76)
                step(app, 20)
                expect((f.x - x) * dir).greaterThan(70)
                expect(f.vx * dir).greaterThan(0)
                expect(opponent.hp).lessThan(1000)
                expect(f.pose.move).is(5)
            end
        end)
        test.case('rhino refunds one energy per enemy up to four per cast and cannot pay for another charge', function(expect)
            local passive = 0
            for _, count in {0, 1, 4, 8} do
                local app = game(5)
                local slot = app.g.slots[1]
                local f = slot.fighter
                local function crowd()
                    app.g.fighters = {f}
                    f.x = 600;f.facing = 1
                    target(app, -300) -- Keep a missed charge in the same encounter.
                    local foes = {}
                    for i = 1, count do table.insert(foes, target(app, i * 60)) end
                    return foes
                end
                local foes = crowd()
                slot.energy = 30
                press(app, 76);step(app, 60)
                expect(f.state).is('idle')
                for _, foe in foes do expect(foe.hp).is(1000 - math.floor(18 * f.power + .5)) end
                if count == 0 then passive = slot.energy end
                expect(math.abs(slot.energy - passive - math.min(count, 4))).lessThan(.01)
                expect(slot.energy).lessThan(30)
                press(app, 76)
                expect(f.state).is('idle');expect(slot.denyT).greaterThan(0)
                if count == 8 then
                    -- A fresh paid cast gets a fresh budget without resetting the fighter.
                    crowd();slot.energy = 30
                    press(app, 76);step(app, 60)
                    expect(math.abs(slot.energy - passive - 4)).lessThan(.01)
                end
            end
        end)
        test.case('Beast Boy normal melee and gorilla hits keep their normal energy gain', function(expect)
            for _, secondary in {false, true} do
                local app = game(5)
                local slot = app.g.slots[1]
                local foe = target(app, 60)
                slot.fighter.rhinoEnergyGained = 4
                slot.energy = if secondary then 40 else 0
                press(app, if secondary then 73 else 74)
                step(app, if secondary then 65 else 20)
                expect(foe.hp).lessThan(1000)
                expect(slot.energy).greaterThan(if secondary then 8 else 4)
            end
        end)
        test.case('gamepad Y and RT trigger all ten powers, with correct cost, direction and friendly-fire filtering', function(expect)
            for hero = 1, 5 do
                for _, dir in { -1, 1 } do
                    for _, ultimate in { false, true } do
                        local app = game(hero)
                        face(app, dir)
                        local f = app.g.slots[1].fighter
                        local slot = app.g.slots[1]
                        slot.dev = 'pad0'
                        slot.energy = 100
                        local power = Powers.get(f.kind, ultimate)
                        local front = target(app, dir * (if ultimate and hero ~= 5 then 250 else 100))
                        local back = target(app, -dir * 100)
                        local ally = target(app, dir * 110)
                        ally.team = 1
                        local oldFront = front.x
                        pad(app, if ultimate then 'rt' else 'y', true)
                        step(app, 1)
                        expect(f.state).is(if ultimate then 'ultimate' else 'secondary')
                        expect(f.pose.move).is(if ultimate then 9 else 8)
                        expect(slot.energy).is(100 - power.cost)
                        pad(app, if ultimate then 'rt' else 'y', false)
                        local sawActive = false
                        for _ = 1, 180 do
                            step(app, 1)
                            sawActive = sawActive or f.pose.active
                            if f.state == 'idle' then break end
                        end
                        expect(sawActive).is(true)
                        expect(front.hp).lessThan(1000)
                        expect(ally.hp).is(1000)
                        expect(f.state).is('idle')
                        expect(f.vx).is(0)
                        expect(f.vy).is(0)
                        expect(f.pose.flip).is(dir)
                        local radial = if ultimate then hero == 3 else hero == 1 or hero == 2 or hero == 5
                        if radial then expect(back.hp).lessThan(1000)
                        else expect(back.hp).is(1000) end
                        if hero == 4 and not ultimate then
                            expect((front.x - oldFront) * dir).lessThan(0)
                        end
                    end
                end
            end
        end)
        test.case('insufficient energy rejects powers, holding RT never repeats, and B/RB preserve the primary', function(expect)
            for _, button in { 'y', 'rt' } do
                local app = game(2)
                local slot = app.g.slots[1]
                slot.dev = 'pad0'
                slot.energy = if button == 'y' then 39 else 99
                pad(app, button, true)
                step(app, 1)
                expect(slot.fighter.state).is('idle')
                expect(slot.denyT).greaterThan(0)
                pad(app, button, false)
                slot.energy = 100
                pad(app, button, true)
                step(app, 1)
                expect(slot.fighter.state).is(if button == 'y' then 'secondary' else 'ultimate')
                -- Even with a replenished meter and repeated held-axis events, one press casts once.
                for _ = 1, 180 do
                    slot.energy = 100
                    pad(app, button, true)
                    step(app, 1)
                end
                expect(slot.fighter.state).is('idle')
                pad(app, button, false)
                pad(app, button, true)
                step(app, 1)
                expect(slot.fighter.state).is(if button == 'y' then 'secondary' else 'ultimate')
            end
            for _, button in { 'b', 'rb' } do
                local app = game(1)
                app.g.slots[1].dev = 'pad0'
                app.g.slots[1].energy = 100
                pad(app, button, true)
                step(app, 1)
                expect(app.g.slots[1].fighter.state).is('special')
                expect(app.g.slots[1].energy).is(70)
            end
        end)
        test.case('keyboard secondary and ultimate bind separately and cancel normal attacks', function(expect)
            for _, binding in { { key = 73, state = 'secondary', cost = 40 }, { key = 85, state = 'ultimate', cost = 100 } } do
                local app = game(1)
                app.g.slots[1].energy = 100
                press(app, 74)
                press(app, binding.key)
                expect(app.g.slots[1].fighter.state).is(binding.state)
                expect(app.g.slots[1].fighter.queued).is(false)
                expect(app.g.slots[1].fighter.combo).is(0)
                expect(app.g.slots[1].energy).lessThan(101 - binding.cost)
            end
        end)
        test.case('diagonal keyboard input is normalized and release restores one axis', function(expect)
            local app = game(1)
            key(app, 68, true)
            key(app, 87, true)
            local d = app.g.devs.kb1
            expect(math.abs(d.mx ^ 2 + d.my ^ 2 - 1)).lessThan(0.0001)
            key(app, 87, false)
            expect(d.mx).is(1)
            expect(d.my).is(0)
            key(app, 65, true)
            expect(d.mx).is(0)
            key(app, 68, false)
            expect(d.mx).is(-1)
        end)
        test.case('double taps dash in all four directions for every Titan and holding does not repeat', function(expect)
            for hero=1,5 do
                for _,dir in {{65,-1,0},{68,1,0},{87,0,-1},{83,0,1}} do
                    local app=game(hero)
                    local f=app.g.slots[1].fighter
                    press(app,dir[1])
                    expect(f.state).is('idle')
                    key(app,dir[1],true)
                    step(app,1)
                    expect(f.state).is('dash')
                    expect(f.dashX).is(dir[2])
                    expect(f.dashY).is(dir[3])
                    expect(f.pose.dash).is(1)
                    local v=if dir[2]~=0 then math.abs(f.vx) else math.abs(f.vy)/.62
                    expect(v).greaterThan(f.speed*2)
                    if dir[2]~=0 then expect(f.facing).is(dir[2]) end
                    step(app,45)
                    expect(f.state).is('walk')
                    expect(f.pose.dash).is(0)
                    key(app,dir[1],false)
                    step(app,1)
                    expect(f.state).is('idle')
                end
            end
        end)
        test.case('slow, alternating, repeated-held, paused and airborne taps cannot prime a dash', function(expect)
            for _,mode in {'slow','alternate','held','paused','air'} do
                local app=game(1)
                local f=app.g.slots[1].fighter
                press(app,68)
                if mode=='slow' then step(app,20)
                elseif mode=='alternate' then press(app,65)
                elseif mode=='paused' then press(app,257); step(app,1); press(app,257)
                elseif mode=='air' then press(app,75); step(app,7)
                elseif mode=='held' then
                    step(app,20)
                    key(app,68,true)
                    step(app,1)
                end
                key(app,68,true)
                step(app,1)
                expect(f.state).never.is('dash')
            end
        end)
        test.case('keyboard two and gamepad stick or D-pad double taps use the same dash gesture', function(expect)
            for _,dpad in {false,true} do
                for _,dir in {{1,0},{-1,0},{0,1},{0,-1}} do
                    local app=game(1)
                    app.g.slots[1].dev='pad0'
                    padMove(app,dir[1],dir[2],dpad); step(app,1)
                    padMove(app,0,0,dpad); step(app,3)
                    padMove(app,dir[1],dir[2],dpad); step(app,1)
                    expect(app.g.slots[1].fighter.state).is('dash')
                    padMove(app,dir[1],dir[2],dpad,true); step(app,1)
                    expect(app.g.slots[1].fighter.state).is('dashatk')
                end
            end
            local app=game(1)
            app.g.slots[1].dev='kb2'
            press(app,262); press(app,262)
            expect(app.g.slots[1].fighter.state).is('dash')
            press(app,44)
            expect(app.g.slots[1].fighter.state).is('dashatk')
        end)
        test.case('stick jitter does not simulate a second directional press', function(expect)
            local app=game(1)
            app.g.slots[1].dev='pad0'
            for _,x in {1,.49,.7,.4,.8,.51,1} do
                padMove(app,x,0); step(app,1)
                expect(app.g.slots[1].fighter.state).is('walk')
            end
            padMove(app,0,0); step(app,1)
            padMove(app,1,0); step(app,1)
            expect(app.g.slots[1].fighter.state).is('dash')
        end)
        test.case('dash attacks hit once along travel, knock down, skip allies and recover for all Titans', function(expect)
            for hero=1,5 do
                for _,dir in {{65,-1,0},{68,1,0},{87,0,-1},{83,0,1}} do
                    local app=game(hero)
                    local f=app.g.slots[1].fighter
                    press(app,dir[1]); press(app,dir[1])
                    local front=target(app,dir[2]*85)
                    front.y=f.y+dir[3]*65
                    local rear=target(app,-dir[2]*160)
                    rear.y=f.y-dir[3]*140
                    local ally=target(app,dir[2]*85)
                    ally.y=front.y
                    ally.team=1
                    local energy=app.g.slots[1].energy
                    press(app,74)
                    expect(f.state).is('dashatk')
                    expect(f.pose.move).is(1)
                    step(app,40)
                    expect(front.hp).is(1000-math.floor(20*f.power+.5))
                    expect(front.state).is('down')
                    expect(rear.hp).is(1000)
                    expect(ally.hp).is(1000)
                    expect(f.state).is('idle')
                    expect(f.vx).is(0)
                    expect(f.vy).is(0)
                    expect(app.g.slots[1].energy).greaterThanOrEqual(energy)
                end
            end
        end)
        test.case('attack can share the second tap, but attacks after the dash are normal', function(expect)
            local app=game(1)
            local f=app.g.slots[1].fighter
            press(app,68)
            key(app,68,true); key(app,74,true); step(app,1)
            expect(f.state).is('dashatk')
            key(app,68,false); key(app,74,false); step(app,40)
            press(app,74)
            expect(f.state).is('attack')
            expect(f.combo).is(1)
        end)
        test.case('dash ends at arena bounds, does not hurt on contact and cannot override damage', function(expect)
            local app=game(1)
            local f=app.g.slots[1].fighter
            local foe=target(app,80)
            press(app,68); press(app,68); step(app,18)
            expect(foe.hp).is(1000)
            f.x=app.g.camX+40
            press(app,65); press(app,65); step(app,10)
            expect(f.x).is(app.g.camX+36)
            f.state='hurt'
            f.st=0
            f.vx=0
            press(app,74)
            expect(f.state).is('hurt')
        end)
        test.case('movement stays inside the street and stops while paused', function(expect)
            local app = game(1)
            local f = app.g.slots[1].fighter
            key(app, 87, true)
            step(app, 120)
            expect(f.y).is(478)
            key(app, 87, false)
            key(app, 83, true)
            step(app, 180)
            expect(f.y).is(698)
            key(app, 83, false)
            key(app, 65, true)
            step(app, 180)
            expect(f.x).is(app.g.camX + 36)
            key(app, 65, false)
            press(app, 257)
            local x, y = f.x, f.y
            key(app, 68, true)
            step(app, 30)
            expect(f.x).is(x)
            expect(f.y).is(y)
        end)
    end
end
