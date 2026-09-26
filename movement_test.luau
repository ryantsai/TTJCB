-- Exercise the real game callbacks and state transitions without rendering.
local makeMain = require('game').create
local Art = require('art')
local Motion = require('motion')
local Attacks = require('attacks')

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
    press(app, 257)
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

return function(): Tests
    return function(test: Tester)
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
