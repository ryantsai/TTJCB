local Game = require('game')
local C = require('campaign')
local function step(app: any, frames: number)
    for _=1,frames do app.advance(app,1/60) end
end
local function press(app: any, code: number)
    app.keyboardEvent(app,{key=code,phase='down'})
    step(app,1)
    app.keyboardEvent(app,{key=code,phase='up'})
    step(app,1)
end
local function game(): any
    local app: any = (Game.create :: any)(nil)
    press(app,257)
    press(app,257)
    press(app,257)
    step(app,90)
    app.g.slots[1].fighter.invuln=10000
    return app
end
local function joinPad(app: any, id: number)
    for _, down in {true, false} do
        app.gamepadEvent(app, {
            deviceId=id, isStandardMapping=true, leftStick=Vector.xy(0,0),
            dpadLeft=false, dpadRight=false, dpadUp=false, dpadDown=false,
            south=false, east=false, west=false, north=false, rightShoulder=false,
            rightTriggerPressed=false, rightTrigger=0, start=down, forward=false, back=false,
        })
        step(app,1)
    end
end
local function joinPlayers(app: any, players: number)
    if players >= 2 then press(app,344) end
    if players >= 3 then joinPad(app,0) end
    if players >= 4 then joinPad(app,1) end
end
local function enemies(app: any): number
    local n=0
    for _,f in app.g.fighters do if f.team==2 and not f.removed then n+=1 end end
    return n
end
local function encounter(app: any, index: number)
    local g=app.g
    g.fighters={g.slots[1].fighter}
    g.shots={}
    g.pending={}
    g.cp=index
    g.lockX=-1
    g.camX=C.checkpoints[index].x
    g.slots[1].fighter.hitPause=0
    g.slots[1].fighter.x=g.camX+600
    step(app,1)
    g.waveT=100
    step(app,1)
end
local function enemy(app: any, kind: string): any
    for _,f in app.g.fighters do if f.kind==kind then return f end end
    error('Missing enemy: '..kind)
end
local function isolate(app: any, kind: string): any
    encounter(app,15)
    local f=enemy(app,kind)
    local h=app.g.slots[1].fighter
    app.g.fighters={h,f}
    app.g.pending={}
    f.entering=false
    f.x=h.x+300
    f.y=h.y
    f.facing=-1
    f.cd=0
    f.state='idle'
    f.st=0
    return f
end
return function(): Tests
    return function(test: Tester)
        test.case('all sixteen encounters spawn their roster and only the final boss ends the campaign',function(expect)
            local app=game()
            local bosses=0
            local total=0
            for index,cp in C.checkpoints do
                encounter(app,index)
                expect(app.g.stage).is(cp.stage)
                expect(#app.g.fighters-1).is(#cp.spawns)
                expect(#app.g.pending).is(0)
                total+=#cp.spawns
                for _,sp in cp.spawns do expect(enemy(app,sp.kind).maxHp).greaterThan(0) end
                if cp.boss then
                    bosses+=1
                    expect(app.g.boss.kind).is(cp.spawns[1].kind)
                    expect(app.g.banner).is(C.enemies[cp.spawns[1].kind].name..'!')
                end
                app.g.fighters={app.g.slots[1].fighter}
                step(app,1)
                expect(app.g.cp).is(index+1)
                expect(app.g.mode).is(if index==#C.checkpoints then 'win' else 'play')
                if cp.boss and index<#C.checkpoints then
                    expect(app.g.stage).is(cp.stage+1)
                    expect(app.g.boss).is(nil)
                    expect(app.g.slots[1].fighter.hp).is(app.g.slots[1].fighter.maxHp)
                    expect(app.g.slots[1].energy).is(100)
                end
            end
            expect(bosses).is(4)
            expect(total).greaterThan(110)
        end)
        test.case('pending reinforcements prevent premature wave completion',function(expect)
            local app=game()
            encounter(app,4)
            app.g.fighters={app.g.slots[1].fighter}
            app.g.pending={{kind='runner',delay=200,side=1}}
            step(app,1)
            expect(app.g.cp).is(4)
            expect(app.g.mode).is('play')
        end)
        test.case('ranged enemies enter the arena even when the hero is at the edge',function(expect)
            local app=game()
            local f=isolate(app,'gunner')
            local h=app.g.slots[1].fighter
            h.x=app.g.camX+1240
            f.x=app.g.camX+1360
            f.entering=true
            step(app,100)
            expect(f.entering).is(false)
            expect(f.x).lessThan(app.g.camX+1250)
        end)
        test.case('blaster windup fires once, hits heroes, and does not hit allies',function(expect)
            local app=game()
            local f=isolate(app,'gunner')
            local h=app.g.slots[1].fighter
            h.invuln=0
            step(app,30)
            expect(#app.g.shots).is(0)
            expect(f.state).is('shoot')
            step(app,20)
            expect(#app.g.shots).is(1)
            expect(app.g.shots[1].owner.team).is(2)
            local hp=h.hp
            step(app,35)
            expect(h.hp).lessThan(hp)
            expect(f.hp).is(f.maxHp)
            expect(#app.g.shots).is(0)
        end)
        test.case('razor rush and shock pulse are distinct attacks and jumping avoids a pulse',function(expect)
            local app=game()
            local f=isolate(app,'runner')
            step(app,1)
            expect(f.state).is('charge')
            step(app,30)
            expect(math.abs(f.vx)).greaterThan(500)
            f=isolate(app,'shock')
            local h=app.g.slots[1].fighter
            f.x=h.x+100
            h.invuln=0
            local hp=h.hp
            step(app,1)
            expect(f.state).is('pulse')
            f.st=f.windup+.01
            h.z=100
            h.vz=100
            step(app,1)
            expect(h.hp).is(hp)
            f.sp=0
            h.z=0
            h.vz=0
            step(app,1)
            expect(h.hp).lessThan(hp)
        end)
        test.case('Jinx and Slade fire three-lane volleys',function(expect)
            for _,index in {12,16} do
                local app=game()
                encounter(app,index)
                local f=app.g.boss
                local h=app.g.slots[1].fighter
                app.g.fighters={h,f}
                f.x=h.x+350
                f.y=h.y
                f.entering=false
                f.cd=0
                step(app,1)
                expect(f.state).is('shoot')
                f.st=f.windup+.01
                step(app,1)
                expect(#app.g.shots).is(3)
                expect(app.g.shots[2].y-app.g.shots[1].y).is(58)
                expect(app.g.shots[1].kind).is(if index==12 then 'hex' else 'blade')
            end
        end)
        test.case('guard reduces frontal light attacks but a rear attack deals full damage',function(expect)
            local amounts={}
            for _,facing in {-1,1} do
                local app=game()
                local f=isolate(app,'shield')
                local h=app.g.slots[1].fighter
                h.facing=1
                f.x=h.x+65
                f.y=h.y
                f.facing=facing
                f.state='target'
                local hp=f.hp
                press(app,74)
                step(app,12)
                table.insert(amounts,hp-f.hp)
            end
            expect(amounts[1]).greaterThan(0)
            expect(amounts[2]).greaterThan(amounts[1]*2)
        end)
        test.case('every campaign wave scales exact enemy counts and health for one through four players',function(expect)
            for players=1,4 do
                local app=game()
                joinPlayers(app,players)
                for index,cp in C.checkpoints do
                    encounter(app,index)
                    local regulars=#cp.spawns-(if cp.boss then 1 else 0)
                    local extra=math.floor(regulars*.5*(players-1)+.5)
                    expect(enemies(app)).is(#cp.spawns+extra)
                    expect(app.g.healthPlayers).is(players)
                    local bosses=0
                    for _,f in app.g.fighters do
                        if f.team==2 then
                            local def=C.enemies[f.kind]
                            local expected=math.floor(def.hp*(1+(players-1)*(if def.boss then .6 else .25))+.5)
                            expect(f.maxHp).is(expected)
                            expect(f.hp).is(expected)
                            if def.boss then bosses+=1 end
                        end
                    end
                    expect(bosses).is(if cp.boss then 1 else 0)
                end
            end
        end)
        test.case('mid-wave joins scale wounded enemies without reviving dead ones and queue extras only once',function(expect)
            local app=game()
            encounter(app,12)
            local boss=app.g.boss
            local shock=enemy(app,'shock')
            local dead=enemy(app,'runner')
            boss.hp=boss.maxHp*.37
            shock.hp=shock.maxHp*.6
            dead.hp=0
            dead.state='down'
            dead.st=0
            press(app,344)
            expect(boss.maxHp).is(848)
            expect(math.abs(boss.hp/boss.maxHp-.37)).lessThan(.000001)
            expect(shock.maxHp).is(85)
            expect(math.abs(shock.hp/shock.maxHp-.6)).lessThan(.000001)
            expect(dead.hp).is(0)
            expect(#app.g.pending).is(3)
            for _,sp in app.g.pending do
                expect(C.isBoss(sp.kind)).is(false)
                expect(sp.delay).greaterThan(app.g.waveT)
            end
            step(app,10)
            expect(#app.g.pending).is(3)
            joinPad(app,0)
            expect(#app.g.pending).is(5)
            expect(boss.maxHp).is(1166)
            joinPad(app,1)
            expect(#app.g.pending).is(8)
            expect(boss.maxHp).is(1484)
            expect(math.abs(boss.hp/boss.maxHp-.37)).lessThan(.000001)
            app.g.waveT=200
            step(app,1)
            expect(#app.g.pending).is(0)
            for _,f in app.g.fighters do
                if f.team==2 and f.hp>0 then expect(f.maxHp).is(C.healthFor(f.kind,4)) end
            end
        end)
        test.case('respawning players count, eliminated players do not, and continues never duplicate extras',function(expect)
            local app=game()
            joinPlayers(app,2)
            encounter(app,12)
            local boss=app.g.boss
            boss.hp=boss.maxHp*.37
            local slot=app.g.slots[2]
            slot.fighter=nil
            slot.respawn=1
            slot.lives=2
            step(app,1)
            expect(boss.maxHp).is(848)
            expect(app.g.healthPlayers).is(2)
            slot.respawn=0
            slot.lives=0
            slot.out=true
            step(app,1)
            expect(boss.maxHp).is(530)
            expect(math.abs(boss.hp/boss.maxHp-.37)).lessThan(.000001)
            local count=enemies(app)
            for _=1,3 do
                press(app,344)
                expect(boss.maxHp).is(848)
                expect(#app.g.pending).is(0)
                expect(enemies(app)).is(count)
                expect(math.abs(boss.hp/boss.maxHp-.37)).lessThan(.000001)
                slot.out=true
                slot.fighter=nil
                slot.respawn=0
                step(app,1)
            end
            encounter(app,13)
            expect(enemies(app)).is(#C.checkpoints[13].spawns)
            for _,f in app.g.fighters do
                if f.team==2 then expect(f.maxHp).is(C.enemies[f.kind].hp) end
            end
        end)
        test.case('co-op scales boss health and adds regular reinforcements',function(expect)
            local app=game()
            press(app,344)
            encounter(app,12)
            expect(app.g.boss.maxHp).greaterThan(C.enemies.jinx.hp)
            expect(#app.g.fighters-1).greaterThan(#C.checkpoints[12].spawns)
            local bosses=0
            for _,f in app.g.fighters do if C.isBoss(f.kind) then bosses+=1 end end
            expect(bosses).is(1)
        end)
    end
end
