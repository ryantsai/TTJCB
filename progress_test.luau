local Game=require('game')
local C=require('campaign')
local P=require('progress')
local B=require('browser_input')

local function step(a:any,n:number)
    for _=1,n do a.advance(a,1/60) end
end
local function press(a:any,key:number)
    a.keyboardEvent(a,{key=key,phase='down'});step(a,1)
    a.keyboardEvent(a,{key=key,phase='up'});step(a,1)
end
local function pointer(id:number,x:number,y:number):any
    return {id=id,position=Vector.xy(x,y),hit=function(self:any) end}
end
local function click(a:any,x:number,y:number)
    a.pointerDown(a,pointer(1,x,y));a.pointerUp(a,pointer(1,x,y));step(a,1)
end
local function app(cleared:number?,ready:boolean?):(any,any)
    local a:any=(Game.create :: any)(nil)
    a.g.tutorialSeen=true
    local props:any={completedLevels={value=cleared or 0},progressReady={value=ready~=false},
        progressRevision={value=0},progressStatus={value='saved'},browserGamepads={value=''},
        browserKeyboard={value=''}}
    local vm:any={getNumber=function(self:any,key:string) return props[key] end,
        getBoolean=function(self:any,key:string) return props[key] end,
        getString=function(self:any,key:string) return props[key] end}
    a.init(a,{viewModel=function(self:any) return vm end})
    step(a,1)
    return a,props
end
local function launch(a:any)
    press(a,257);press(a,257);press(a,257);step(a,90)
    a.g.slots[1].fighter.invuln=10000
end
local function encounter(a:any,index:number)
    local g=a.g
    local h=g.slots[1].fighter
    g.fighters={h};g.shots={};g.pending={}
    g.cp=index;g.lockX=-1;g.camX=C.checkpoints[index].x
    h.x=g.camX+600;h.hitPause=0
    step(a,1);g.waveT=100;step(a,1)
end
local function clearWave(a:any,index:number)
    encounter(a,index)
    a.g.fighters={a.g.slots[1].fighter};step(a,1)
end
local function snapshot(a:any,p:any,value:string)
    p.browserGamepads.value=value;step(a,1)
end

return function():Tests
    return function(test:Tester)
        test.case('browser keyboard snapshot makes Space start and enter character selection once',function(expect)
            local a,p=app()
            p.browserKeyboard.value='1,32,down;2,32,up';step(a,1)
            expect(a.g.mode).is('map')
            step(a,3);expect(a.g.mode).is('map')
            p.browserKeyboard.value='1,32,down;2,32,up;3,32,down;4,32,up';step(a,1)
            expect(a.g.mode).is('select')
            local events,seq=B.decodeKeyboard('6,32,up;7,257,down;8,257,up',6)
            expect(#events).is(2);expect(seq).is(8)
            expect(#B.decodeKeyboard(string.rep('x',2049),8)).is(0)
        end)
        test.case('map selects an unlocked level then opens character selection',function(expect)
            local a=app()
            press(a,257);expect(a.g.mode).is('map')
            press(a,68);expect(a.g.selectedLevel).is(2)
            press(a,257);expect(a.g.mode).is('map')
            click(a,180,233);expect(a.g.mode).is('map')
            expect(a.g.selectedLevel).is(1)
            click(a,1100,579);expect(a.g.mode).is('select')
        end)
        test.case('new players can inspect locked levels but cannot launch them by keyboard or pointer',function(expect)
            local a=app();press(a,257)
            expect(a.g.mode).is('map');expect(a.g.selectedLevel).is(1)
            expect(P.canPlay(a.g.progress,1)).is(true)
            for level=2,8 do
                press(a,68);press(a,257);click(a,1100,579)
                expect(a.g.selectedLevel).is(level);expect(a.g.mode).is('map')
                expect(P.canPlay(a.g.progress,level)).is(false)
            end
            click(a,180,233);launch(a)
            expect(a.g.mode).is('play');expect(a.g.runLevel).is(1)
            expect(a.g.progress.cleared).is(0)
        end)
        test.case('all eight levels start at their own stage and unlock only after the boss wave',function(expect)
            local a,p=app();press(a,257)
            for level=1,8 do
                expect(a.g.selectedLevel).is(level)
                launch(a)
                expect(a.g.runLevel).is(level);expect(a.g.stage).is(level)
                expect(a.g.cp).is((level-1)*4+1)
                for wave=1,4 do
                    clearWave(a,(level-1)*4+wave)
                    expect(a.g.progress.cleared).is(if wave==4 then level else level-1)
                    expect(p.completedLevels.value).is(a.g.progress.cleared)
                    if wave<4 then expect(a.g.mode).is('play') end
                end
                expect(p.progressRevision.value).is(level)
                if level==8 then
                    expect(a.g.mode).is('win');step(a,91);press(a,257)
                end
                expect(a.g.mode).is('map');expect(a.g.mapCleared).is(level)
                expect(P.unlocked(a.g.progress)).is(math.min(8,level+1))
                expect(a.g.slots[1].dev).is('kb1')
            end
            for level=1,8 do expect(P.canPlay(a.g.progress,level)).is(true) end
        end)
        test.case('boss death waits for reinforcements and a surviving Titan before unlocking',function(expect)
            local a,p=app();press(a,257);launch(a);encounter(a,4)
            local h=a.g.slots[1].fighter
            a.g.fighters={h};a.g.pending={{kind='runner',delay=200,side=1}}
            step(a,1)
            expect(a.g.mode).is('play');expect(p.completedLevels.value).is(0)
            a.g.pending={};h.hp=0;h.state='ko';h.removed=true
            a.g.slots[1].lives=0;a.g.slots[1].out=true
            step(a,660)
            expect(a.g.mode).is('over');expect(p.completedLevels.value).is(0)
            step(a,91);press(a,257)
            expect(a.g.mode).is('map');expect(P.canPlay(a.g.progress,2)).is(false)
        end)
        test.case('replaying a cleared level keeps every later unlock and does not write a lower save',function(expect)
            local a,p=app(3);press(a,257)
            expect(a.g.selectedLevel).is(4)
            click(a,180,233);launch(a)
            for wave=1,4 do clearWave(a,wave) end
            expect(a.g.mode).is('map');expect(a.g.mapCleared).is(1)
            expect(a.g.progress.cleared).is(3);expect(p.completedLevels.value).is(3)
            expect(p.progressRevision.value).is(0);expect(P.canPlay(a.g.progress,4)).is(true)
        end)
        test.case('old four-stage saves unlock the new arc and every lower-row map node is clickable',function(expect)
            local a=app(4);press(a,257)
            expect(a.g.selectedLevel).is(5);expect(P.canPlay(a.g.progress,5)).is(true)
            for level=5,8 do
                click(a,180+(level-5)*306,433)
                expect(a.g.selectedLevel).is(level)
            end
            press(a,257);expect(a.g.mode).is('map')
            click(a,180,433);press(a,257);expect(a.g.mode).is('select')
        end)
        test.case('reset can be cancelled and confirmation locks later levels without changing language',function(expect)
            local a,p=app(4);press(a,258);press(a,257);press(a,82)
            expect(a.g.resetConfirm).is(true);expect(a.g.resetYes).is(false)
            press(a,257)
            expect(a.g.resetConfirm).is(false);expect(a.g.progress.cleared).is(4)
            press(a,82);press(a,256)
            expect(a.g.resetConfirm).is(false);expect(p.progressRevision.value).is(0)
            press(a,82);press(a,68);press(a,257)
            expect(a.g.mode).is('map');expect(a.g.progress.cleared).is(0)
            expect(a.g.selectedLevel).is(1);expect(a.g.locale).is('zh-TW')
            expect(p.completedLevels.value).is(0);expect(p.progressRevision.value).is(1)
            expect(P.canPlay(a.g.progress,1)).is(true);expect(P.canPlay(a.g.progress,2)).is(false)
        end)
        test.case('map and reset pointer targets respect scaling, capture and the confirmation modal',function(expect)
            local a,p=app(2);a.resize(a,Vector.xy(1600,1000),1)
            click(a,168.75,118.75) -- Former title shortcut is inert at 1.25x scale.
            expect(a.g.mode).is('title')
            press(a,77);expect(a.g.mode).is('title')
            press(a,257)
            expect(a.g.mode).is('map')
            a.pointerDown(a,pointer(1,1400,120));a.pointerUp(a,pointer(2,1400,120))
            expect(a.g.resetConfirm).is(false)
            a.pointerExit(a,pointer(1,1400,120));click(a,1400,120)
            expect(a.g.resetConfirm).is(true)
            click(a,225,495);click(a,1375,773.75) -- Neither a node nor Play bypasses the modal.
            expect(a.g.selectedLevel).is(3);expect(a.g.mode).is('map')
            click(a,966.25,602.5)
            expect(a.g.resetConfirm).is(false);expect(a.g.selectedLevel).is(1)
            expect(p.completedLevels.value).is(0)
        end)
        test.case('save hydration waits for the host and later tab changes update the map without echo writes',function(expect)
            local a,p=app(2,false);press(a,257)
            expect(a.g.progress.cleared).is(0);expect(p.completedLevels.value).is(2)
            p.progressReady.value=true;step(a,1)
            expect(a.g.progress.cleared).is(2);expect(a.g.selectedLevel).is(3)
            expect(p.progressRevision.value).is(0)
            p.completedLevels.value=0;step(a,1)
            expect(a.g.selectedLevel).is(1);expect(a.g.progress.cleared).is(0)
            expect(p.progressRevision.value).is(0)
            p.completedLevels.value=4.5;step(a,1)
            expect(a.g.progress.cleared).is(0);expect(P.canPlay(a.g.progress,2)).is(false)
            p.progressStatus.value='unavailable';step(a,1)
            expect(a.g.progress.status).is('unavailable')
        end)
        test.case('browser controller snapshots use native input handling through map, play and disconnect',function(expect)
            local a,p=app()
            local function pad(mask:number)
                snapshot(a,p,`0,0,0,{mask}`);snapshot(a,p,'0,0,0,0')
            end
            pad(512);expect(a.g.mode).is('map');expect(a.g.slots[1].dev).is('pad0')
            pad(32768);pad(1);expect(a.g.mode).is('map');expect(a.g.selectedLevel).is(2)
            pad(16384);pad(1);expect(a.g.mode).is('select')
            pad(1);pad(512);expect(a.g.mode).is('play')
            snapshot(a,p,'');expect(a.g.paused).is(true);expect(a.g.devs.pad0).is(nil)
        end)
        test.case('touch controller shares the browser bridge and stays independent of physical input',function(expect)
            local a,p=app()
            local function touch(mask:number)
                snapshot(a,p,`0,0,0,0;31,0,0,{mask}`)
                snapshot(a,p,'0,0,0,0;31,0,0,0')
            end
            touch(512);expect(a.g.mode).is('map');expect(a.g.slots[1].dev).is('pad31')
            touch(1);expect(a.g.mode).is('select')
            touch(1);touch(512);expect(a.g.mode).is('play')
            snapshot(a,p,'0,-1,0,0;31,1,0,5')
            expect(a.g.devs.pad31.mx).is(1);expect(a.g.devs.pad0.mx).is(-1)
            expect(a.g.devs.pad31.held.a).is(true);expect(a.g.devs.pad31.held.x).is(true)
            snapshot(a,p,'0,-1,0,0;31,0,0,0')
            expect(a.g.devs.pad31.mx).is(0);expect(a.g.devs.pad31.held.a).is(false)
            expect(a.g.devs.pad31.held.x).is(false);expect(a.g.devs.pad0.mx).is(-1)
            touch(512);expect(a.g.paused).is(true)
        end)
        test.case('malformed controller snapshots are ignored and buttons retain standard Xbox mapping',function(expect)
            for _,bad in {'','x','0,0','0,0,0,no','32,0,0,0','0,2,0,0','0,0,0,-1','0,0,0,65536'} do
                expect(#B.decode(bad)).is(0)
            end
            local events=B.decode('0,-1,0.5,65535;1,0,0,0;2,0,0,0;3,0,0,0;4,0,0,0')
            expect(#events).is(4);expect(events[1].leftStick.x).is(-1)
            expect(events[1].leftStick.y).is(.5)
            for _,button in {'south','east','west','north','leftShoulder','rightShoulder','rightTriggerPressed',
                'back','start','dpadUp','dpadDown','dpadLeft','dpadRight'} do
                expect(events[1][button]).is(true);expect(events[2][button]).is(false)
            end
        end)
    end
end
