-- Co-op impact regressions use the actual keyboard/gamepad and game callbacks.
local Game=require('game')
local Art=require('art')
local Remarks=require('remarks')

local function step(app:any,n:number)
    for _=1,n do app.advance(app,1/60) end
end
local function key(app:any,code:number,down:boolean)
    app.keyboardEvent(app,{key=code,phase=if down then 'down' else 'up'})
end
local function press(app:any,code:number)
    key(app,code,true);step(app,1);key(app,code,false);step(app,1)
end
local function pad(app:any,id:number,start:boolean,attack:boolean)
    app.gamepadEvent(app,{deviceId=id,isStandardMapping=true,leftStick=Vector.xy(0,0),
        dpadLeft=false,dpadRight=false,dpadUp=false,dpadDown=false,south=false,east=false,
        west=attack,north=false,rightShoulder=false,rightTriggerPressed=false,rightTrigger=0,
        start=start,forward=false,back=false})
end
local function game():any
    local app:any=(Game.create :: any)(nil)
    app.g.tutorialSeen=true
    press(app,257) -- Enter the level map.
    press(app,257);press(app,257);press(app,257);step(app,90);press(app,344)
    for id=0,1 do pad(app,id,true,false);step(app,1);pad(app,id,false,false) end
    local g=app.g
    g.fighters={};g.pending={};g.shots={};g.fx={};g.pickups={}
    g.camX=0;g.lockX=-1;g.cp=1;g.bannerT=0
    for i,s in g.slots do
        local f=s.fighter
        f.x=180+(i-1)*275;f.y=590;f.z=0;f.vx=0;f.vy=0;f.vz=0
        f.state='idle';f.st=0;f.invuln=1000;f.hitPause=0
        f.pose=Art.newPose();f.voice=Remarks.new(i);s.energy=100
        table.insert(g.fighters,f)
    end
    return app
end
local function target(app:any,hero:number):any
    local f=table.clone(app.g.slots[hero].fighter)
    f.id=100+#app.g.fighters;f.x+=52;f.team=2;f.hero=0;f.slot=0;f.kind='bot'
    f.state='target';f.hp=1000;f.maxHp=1000;f.invuln=0;f.hit={};f.buffered={}
    f.pose=Art.newPose();f.voice=Remarks.new(f.id)
    table.insert(app.g.fighters,f)
    return f
end
local function hit(app:any):any
    local foe=target(app,1)
    key(app,74,true);step(app,1);key(app,74,false)
    for _=1,30 do
        step(app,1)
        if foe.hp<1000 then break end
    end
    return foe
end

return function():Tests
    return function(test:Tester)
        test.case('an ally hit never pauses another player, airborne physics or projectiles',function(expect)
            local app=game()
            local foe=hit(app)
            local attacker=app.g.slots[1].fighter
            local runner=app.g.slots[2].fighter
            local jumper=app.g.slots[3].fighter
            expect(foe.hp).lessThan(1000)
            expect(attacker.hitPause).greaterThan(0)
            jumper.state='air';jumper.z=150;jumper.vz=-100
            app.g.shots={{kind='bolt',x=50,y=480,z=200,vx=360,t=0,life=3,
                owner=jumper,dmg=10,knock=false,hit={},dead=false,back=false}}
            key(app,262,true)
            local x,z,age=runner.x,jumper.z,attacker.st
            step(app,1)
            expect(runner.x-x).greaterThan(3)
            expect(jumper.z).lessThan(z)
            expect(app.g.shots[1].x).greaterThan(50)
            expect(attacker.st).is(age)
            step(app,4)
            expect(attacker.st).greaterThan(age)
        end)
        test.case('a teammate can attack on the frame after another player lands a hit',function(expect)
            local app=game();hit(app)
            key(app,44,true);step(app,1);key(app,44,false)
            expect(app.g.slots[2].fighter.state).is('attack')
        end)
        test.case('an attack tap during the local impact hold chains exactly once',function(expect)
            local app=game();hit(app)
            local f=app.g.slots[1].fighter
            key(app,74,true);step(app,1);key(app,74,false)
            local chained=false
            for _=1,45 do
                step(app,1)
                if f.combo==2 then chained=true;break end
            end
            expect(chained).is(true)
            step(app,60)
            expect(f.state).is('idle')
            expect(f.combo).is(0)
        end)
        test.case('a special tapped during impact is delivered once without repeating its cost',function(expect)
            local app=game();hit(app)
            local f=app.g.slots[1].fighter
            key(app,76,true);step(app,1);key(app,76,false);step(app,2)
            expect(f.state).is('special')
            expect(app.g.slots[1].energy).lessThan(71)
            step(app,12)
            expect(app.g.slots[1].energy).greaterThan(69)
            expect(f.st).greaterThan(.15)
        end)
        test.case('a distant projectile hit does not hold its owner even during a melee attack',function(expect)
            local app=game()
            local owner=app.g.slots[1].fighter
            local foe=target(app,4)
            owner.state='attack';owner.combo=1;owner.st=0
            app.g.shots={{kind='bolt',x=foe.x,y=foe.y,z=40,vx=0,t=0,life=1,
                owner=owner,dmg=10,knock=false,hit={},dead=false,back=false}}
            step(app,1)
            expect(foe.hp).lessThan(1000)
            expect(foe.hitPause).greaterThan(0)
            expect(owner.hitPause).is(0)
            local age=owner.st;step(app,1)
            expect(owner.st).greaterThan(age)
        end)
        test.case('four simultaneous contact attacks retain bounded individual holds and recover',function(expect)
            local app=game()
            local foes={}
            for i=1,4 do table.insert(foes,target(app,i)) end
            key(app,74,true);key(app,44,true)
            pad(app,0,false,true);pad(app,1,false,true);step(app,1)
            key(app,74,false);key(app,44,false)
            pad(app,0,false,false);pad(app,1,false,false)
            for _=1,45 do
                step(app,1)
                for _,f in app.g.fighters do expect(f.hitPause).lessThanOrEqual(.05) end
            end
            for i,s in app.g.slots do
                expect(foes[i].hp).lessThan(1000)
                expect(s.fighter.hitPause).is(0)
                expect(s.fighter.state).is('idle')
            end
        end)
    end
end
