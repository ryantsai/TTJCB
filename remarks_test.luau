local Game = require('game')
local R = require('remarks')
local S = require('speech')
local G = require('gfx')
local L = require('localization')

local function step(app: any, frames: number)
    for _=1,frames do app.advance(app,1/60) end
end
local function press(app: any, code: number)
    app.keyboardEvent(app,{key=code,phase='down'}); step(app,1)
    app.keyboardEvent(app,{key=code,phase='up'}); step(app,1)
end
local function game(hero: number): any
    local app: any = (Game.create :: any)(nil)
    app.g.tutorialSeen=true
    press(app,257) -- Enter the level map.
    press(app,257);press(app,257); app.g.slots[1].hero=hero
    press(app,257); press(app,257); step(app,90)
    local g=app.g
    local f=g.slots[1].fighter
    g.fighters={f}; g.shots={}; g.pending={}; g.lockX=-1; g.cp=1
    g.camX=0; g.bannerT=0; g.pickups={}
    f.x=450; f.y=590; f.z=0; f.vx=0; f.vy=0; f.vz=0
    f.state='idle'; f.st=0; f.invuln=10000; f.voice=R.new(1234)
    g.slots[1].energy=100
    return app
end
local function enemy(app: any): any
    local f=table.clone(app.g.slots[1].fighter)
    f.id=99; f.team=2; f.kind='bot'; f.slot=0; f.x=600
    f.state='target'; f.hp=10000; f.maxHp=10000; f.invuln=0
    f.voice=R.new(99)
    return f
end
local function shoot(app: any, damage: number)
    local f=app.g.slots[1].fighter
    f.invuln=0; f.state='idle'; f.z=0; f.hitPause=0
    app.g.shots={{kind='bullet',x=f.x,y=f.y,z=40,vx=0,t=0,life=1,
        owner=enemy(app),dmg=damage,knock=false,hit={},dead=false,back=false}}
    step(app,1)
end
local function count(app: any): number
    local n=0
    for _,f in app.g.fighters do if f.team==1 and f.voice.time>0 then n+=1 end end
    return n
end

return function(): Tests
    return function(test: Tester)
        test.case('every Titan has localized variants for every speech event without immediate repeats',function(expect)
            for kind,bank in R.lines do
                for event in R.priority do
                    expect(#bank[event]).greaterThanOrEqual(3)
                    local voice=R.new(743)
                    local last=''
                    local seen={}
                    for _=1,12 do
                        expect(R.offer(voice,kind,event)).is(true)
                        expect(voice.text==last).is(false)
                        expect(L.catalog[voice.text]~=nil).is(true)
                        seen[voice.text]=true; last=voice.text
                        R.update(voice,7)
                    end
                    local variants=0
                    for _ in seen do variants+=1 end
                    expect(variants).greaterThan(1)
                end
            end
        end)
        test.case('urgent speech interrupts chatter while repeated hits and weaker events are throttled',function(expect)
            local voice=R.new(18)
            expect(R.offer(voice,'raven','encounter')).is(true)
            expect(R.offer(voice,'raven','encounter')).is(false)
            R.update(voice,.8)
            expect(R.offer(voice,'raven','special')).is(true)
            expect(R.offer(voice,'raven','hurt')).is(false)
            expect(R.offer(voice,'raven','low_health')).is(true)
            expect(R.offer(voice,'raven','down')).is(true)
            R.update(voice,7)
            expect(voice.time).is(0)
            expect(R.offer(voice,'raven','heal')).is(true)
        end)
        test.case('all speech fits three readable lines in English and Traditional Chinese',function(expect)
            for _,bank in R.lines do
                for _,variants in bank do
                    for _,pair in variants do
                        for _,text in pair do
                            local lines=S.wrap(text)
                            expect(#lines).greaterThan(0)
                            expect(#lines).lessThanOrEqual(3)
                            for _,line in lines do expect(G.textWidth(line,S.size)).lessThanOrEqual(S.maxWidth) end
                            local joined=string.gsub(table.concat(lines),'%s','')
                            local original=string.gsub(text,'%s','')
                            expect(joined).is(original)
                        end
                    end
                end
            end
        end)
        test.case('co-located bubbles stay inside the screen, below HUD, and never overlap',function(expect)
            for _,x in {0,640,1280} do
                for _,y in {0,180,420,720} do
                    local a=S.place('BEHOLD! MY MASTER PLAN!',x,y,{})
                    local b=S.place('我收下這光榮的披薩！',x,y,{a})
                    expect(S.overlaps(a,b)).is(false)
                    for _,box in {a,b} do
                        expect(box.x).greaterThanOrEqual(14)
                        expect(box.x+box.w).lessThanOrEqual(G.W-14)
                        expect(box.y).greaterThanOrEqual(166)
                        expect(box.y+box.h).lessThanOrEqual(G.H-18)
                    end
                end
            end
        end)
        test.case('visible enemies trigger one encounter line per wave for all Titans',function(expect)
            for hero=1,5 do
                local app=game(hero)
                local f=app.g.slots[1].fighter
                table.insert(app.g.fighters,enemy(app)); step(app,1)
                expect(f.voice.event).is('encounter')
                local text=f.voice.text
                step(app,450)
                expect(f.voice.time).is(0)
                expect(f.voice.text).is(text)
                expect(f.voice.seenWave).is(1)
                app.g.cp=2; step(app,1)
                expect(f.voice.time).greaterThan(0)
                expect(f.voice.text==text).is(false)
            end
        end)
        test.case('fallen enemies and defeated heroes cannot start encounter chatter',function(expect)
            local app=game(1)
            local foe=enemy(app)
            foe.hp=0; foe.state='down'
            table.insert(app.g.fighters,foe); step(app,1)
            expect(app.g.slots[1].fighter.voice.time).is(0)
            foe.hp=100; foe.state='target'
            app.g.slots[1].fighter.hp=0
            app.g.slots[1].fighter.state='down'
            step(app,1)
            expect(app.g.slots[1].fighter.voice.time).is(0)
        end)
        test.case('high-jump bubbles move beside the speaker instead of covering the head',function(expect)
            for _,x in {36,620,1244} do
                local box=S.place('I COULD BE READING.',x,166,{})
                expect(box.x>x+40 or box.x+box.w<x-40).is(true)
            end
        end)
        test.case('all fifteen power activations speak and denied powers stay silent',function(expect)
            for hero=1,5 do
                for _,move in {{76,'special'},{73,'secondary'},{85,'ultimate'}} do
                    local app=game(hero)
                    press(app,move[1] :: number)
                    expect(app.g.slots[1].fighter.voice.event).is(move[2])
                    expect(app.g.slots[1].fighter.voice.time).greaterThan(0)
                    local denied=game(hero)
                    denied.g.slots[1].energy=0
                    press(denied,move[1] :: number)
                    expect(denied.g.slots[1].fighter.voice.time).is(0)
                end
            end
        end)
        test.case('real incoming hits select hurt, low-health and knockout reactions for every Titan',function(expect)
            for hero=1,5 do
                local app=game(hero)
                local f=app.g.slots[1].fighter
                shoot(app,8)
                expect(f.voice.event).is('hurt')
                f.hp=f.maxHp*.25+4
                shoot(app,8)
                expect(f.voice.event).is('low_health')
                expect(f.voice.danger).is(true)
                local text=f.voice.text
                shoot(app,1)
                expect(f.voice.text).is(text)
                f.hp=f.maxHp; step(app,1)
                expect(f.voice.danger).is(false)
                f.hp=1; shoot(app,8)
                expect(f.voice.event).is('down')
                expect(f.state).is('down')
            end
        end)
        test.case('pizza and wave clear produce the appropriate remarks',function(expect)
            for hero=1,5 do
                local app=game(hero)
                local f=app.g.slots[1].fighter
                f.hp=40
                app.g.pickups={{x=f.x,y=f.y,t=0,dead=false}}
                step(app,1)
                expect(f.voice.event).is('heal')
                expect(f.hp).is(85)
                R.update(f.voice,7)
                app.g.lockX=0; step(app,1)
                expect(f.voice.event).is('victory')
            end
        end)
        test.case('healing and victory replace speech about the situation they just resolved',function(expect)
            local app=game(1)
            local f=app.g.slots[1].fighter
            f.hp=25; shoot(app,8)
            expect(f.voice.event).is('low_health')
            app.g.pickups={{x=f.x,y=f.y,t=0,dead=false}}
            step(app,1)
            expect(f.voice.event).is('heal')
            local voice=R.new(33)
            expect(R.offer(voice,'starfire','encounter')).is(true)
            expect(R.offer(voice,'starfire','victory')).is(true)
        end)
        test.case('speech freezes on pause and is cleared on return to title',function(expect)
            local app=game(2)
            press(app,76)
            local v=app.g.slots[1].fighter.voice
            press(app,257)
            local remaining=v.time
            step(app,120)
            expect(v.time).is(remaining)
            press(app,256)
            expect(app.g.mode).is('title')
            expect(#app.g.fighters).is(0)
        end)
        test.case('four-player chatter uses two bubbles and makes room for urgent warnings',function(expect)
            local app=game(1)
            press(app,344)
            for id=0,1 do
                app.gamepadEvent(app,{deviceId=id,isStandardMapping=true,leftStick=Vector.xy(0,0),
                    dpadLeft=false,dpadRight=false,dpadUp=false,dpadDown=false,south=false,east=false,
                    west=false,north=false,rightShoulder=false,rightTriggerPressed=false,rightTrigger=0,
                    start=true,forward=false,back=false})
                step(app,1)
            end
            for _,f in app.g.fighters do
                f.state='idle'; f.z=0; f.vz=0; f.x=430+f.slot*20; f.y=590
                f.invuln=10000; f.voice=R.new(f.id*37)
            end
            table.insert(app.g.fighters,enemy(app)); step(app,1)
            expect(count(app)).is(2)
            local third=app.g.slots[3].fighter
            third.hp=third.maxHp*.2
            step(app,1)
            expect(third.voice.event).is('low_health')
            expect(count(app)).is(2)
            for _=1,600 do
                step(app,1)
                expect(count(app)).lessThanOrEqual(2)
            end
            for _,slot in app.g.slots do expect(slot.fighter.voice.seenWave).is(1) end
        end)
    end
end
