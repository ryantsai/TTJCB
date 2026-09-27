local Game=require('game')
local T=require('tutorial')
local L=require('localization')
local G=require('gfx')
local Font=require('font')

local function step(app:any,n:number)
    for _=1,n do app.advance(app,1/60) end
end
local function press(app:any,key:number)
    app.keyboardEvent(app,{key=key,phase='down'});step(app,1)
    app.keyboardEvent(app,{key=key,phase='up'});step(app,1)
end
local function app():any return (Game.create :: any)(nil) end
local function pointer(id:number,x:number,y:number):any
    return {id=id,position=Vector.xy(x,y),hit=function(self:any) end}
end
local function click(a:any,x:number,y:number)
    a.pointerDown(a,pointer(1,x,y));a.pointerUp(a,pointer(1,x,y))
end
local function pad(a:any,start:boolean,south:boolean,back:boolean?,north:boolean?)
    a.gamepadEvent(a,{deviceId=0,isStandardMapping=true,leftStick=Vector.xy(0,0),
        dpadLeft=false,dpadRight=false,dpadUp=false,dpadDown=false,south=south,east=false,
        west=false,north=north==true,leftShoulder=false,rightShoulder=false,
        rightTriggerPressed=false,rightTrigger=0,start=start,forward=false,back=back==true})
    step(a,1)
end

return function():Tests
    return function(test:Tester)
        test.case('first start runs a skippable tutorial without spending player resources',function(expect)
            local a=app();press(a,257)
            expect(a.g.mode).is('tutorial')
            expect(a.g.slots[1].dev).is('kb1')
            expect(a.g.demo.slots[1].fighter.kind).is('robin')
            expect(a.g.demo==a.g).is(false)
            step(a,110);press(a,257)
            expect(a.g.mode).is('map')
            expect(a.g.slots[1].locked).is(false)
            expect(a.g.slots[1].energy).is(0)
            expect(a.g.devs.demo==nil).is(true)
            expect(#a.g.fighters).is(0)
            expect(a.g.demo==nil).is(true)
            press(a,257);press(a,257);press(a,257);press(a,257);step(a,90)
            expect(a.g.mode).is('play')
            expect(a.g.slots[1].fighter.hp).is(110)
            press(a,257);press(a,256);press(a,257)
            expect(a.g.mode).is('map')
        end)
        test.case('keyboard and controller skip preserve co-op joins and do not ready a slot',function(expect)
            local a=app();press(a,257);press(a,344)
            expect(a.g.mode).is('map')
            expect(a.g.slots[2].dev).is('kb2')
            expect(a.g.slots[2].locked).is(false)
            local b=app();pad(b,true,false);pad(b,false,false)
            expect(b.g.mode).is('tutorial')
            pad(b,false,true);pad(b,false,true)
            expect(b.g.tutorial.index).is(2)
            pad(b,false,false);pad(b,false,false,true)
            expect(b.g.mode).is('map')
            expect(b.g.slots[1].dev).is('pad0')
            expect(b.g.slots[1].locked).is(false)
        end)
        test.case('the short automatic tour completes at the level map without starting combat',function(expect)
            local a=app();press(a,257);step(a,26.5*60)
            expect(a.g.mode).is('map')
            expect(a.g.tutorialSeen).is(true)
            expect(a.g.tutorial==nil).is(true)
            expect(a.g.slots[1].locked).is(false)
            expect(#a.g.fighters).is(0)
        end)
        test.case('replay, previous, next and skip clicks honor letterboxing and pointer capture',function(expect)
            local a=app();a.resize(a,Vector.xy(1600,1000),1)
            -- 1.25x scene with 50 px top letterbox; help center is 640,689.
            a.pointerDown(a,pointer(1,800,911.25))
            a.pointerUp(a,pointer(2,800,911.25))
            expect(a.g.mode).is('title')
            a.pointerExit(a,pointer(1,800,911.25));a.pointerUp(a,pointer(1,800,911.25))
            expect(a.g.mode).is('title')
            click(a,800,911.25)
            expect(a.g.mode).is('tutorial')
            click(a,1460,882.5)
            expect(a.g.tutorial.index).is(2)
            click(a,75,882.5)
            expect(a.g.tutorial.index).is(1)
            a.pointerDown(a,pointer(1,1450,117.5));a.pointerUp(a,pointer(1,400,300))
            expect(a.g.mode).is('tutorial')
            click(a,1450,117.5)
            expect(a.g.mode).is('title')
            expect(a.g.slots[1].dev).is('')
        end)
        test.case('H and controller Y replay the tour in the selected language',function(expect)
            local a=app();press(a,258);press(a,72)
            expect(a.g.mode).is('tutorial')
            expect(a.g.locale).is('zh-TW')
            expect(a.g.demo.locale).is('zh-TW')
            press(a,256)
            expect(a.g.mode).is('title')
            pad(a,false,false,false,true)
            expect(a.g.mode).is('tutorial')
            pad(a,false,false);pad(a,true,false)
            expect(a.g.mode).is('title')
            expect(a.g.locale).is('zh-TW')
        end)
        test.case('every tutorial step drives actual Robin actions with synchronized displayed inputs',function(expect)
            local a=app();press(a,72)
            local seen:{[string]:boolean}={}
            local combos:{[number]:boolean}={}
            local damaged:{[string]:boolean}={}
            local minX,maxX,minY,maxY,maxZ,maxShots=10000,0,10000,0,0,0
            local sawRB,sawReturn,sawPause,sawMenu=false,false,false,false
            for _=1,26.5*60 do
                if a.g.mode~='tutorial' then break end
                local s,demo=a.g.tutorial,a.g.demo
                local id=T.steps[s.index].id
                local f=demo.slots[1].fighter
                if f then
                    seen[id..':'..f.state]=true
                    if id=='move' then
                        minX=math.min(minX,f.x);maxX=math.max(maxX,f.x)
                        minY=math.min(minY,f.y);maxY=math.max(maxY,f.y)
                    elseif id=='jump' then maxZ=math.max(maxZ,f.z)
                    elseif id=='combo' then combos[f.combo]=true
                    elseif id=='ultimate' then maxShots=math.max(maxShots,#demo.shots) end
                    for _,enemy in demo.fighters do
                        if enemy.team==2 and enemy.hp<enemy.maxHp then damaged[id]=true end
                    end
                end
                if demo.mode=='play' then
                    local dev=demo.devs.demo
                    expect(dev.mx).is(s.input.mx)
                    expect(dev.my).is(s.input.my)
                    for _,button in {'a','b','x','y','rt','start','cancel'} do
                        expect(dev.held[button]==true).is(s.input.held[button]==true)
                    end
                end
                sawRB=sawRB or s.input.rb
                for _,shot in demo.shots do sawReturn=sawReturn or shot.back end
                sawPause=sawPause or demo.paused
                sawMenu=sawMenu or demo.mode=='title'
                step(a,1)
            end
            expect(maxX-minX).greaterThan(80);expect(maxY-minY).greaterThan(25)
            expect(seen['dash:dash']).is(true);expect(seen['dash:dashatk']).is(true)
            expect(maxZ).greaterThan(110)
            for i=1,3 do expect(combos[i]).is(true) end
            expect(seen['air:jumpatk']).is(true)
            expect(seen['special:special']).is(true)
            expect(seen['secondary:secondary']).is(true)
            expect(seen['ultimate:ultimate']).is(true)
            expect(damaged.combo).is(true);expect(damaged.secondary).is(true)
            expect(damaged.special).is(true);expect(damaged.ultimate).is(true)
            expect(maxShots).greaterThanOrEqual(6)
            expect(sawRB).is(true);expect(sawReturn).is(true)
            expect(sawPause).is(true);expect(sawMenu).is(true)
            expect(a.g.mode).is('title')
            expect(a.g.paused).is(false)
        end)
        test.case('all tutorial copy is localized and physical keyboard keycaps have glyphs',function(expect)
            for _,s in T.steps do
                for _,value in {s.title,s.line1,s.line2} do
                    expect(L.catalog[value]~=nil).is(true)
                    for _,locale in {'en','zh-TW'} do
                        expect(G.textWidth(L.text(locale :: L.Locale,value),16)).lessThan(635)
                    end
                end
                for _,keys in {s.keys1,s.keys2} do
                    for _,key in keys do
                        for char in string.gmatch(key.label,'.') do
                            if char~=' ' then expect(Font.glyphs[char]~=nil).is(true) end
                        end
                    end
                end
            end
        end)
    end
end
