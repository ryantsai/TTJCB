-- Native Rive onboarding: one input timeline drives the demo and its diagrams.
local G=require('gfx')
local L=require('localization')
local T={}

type Key={label:string,button:string}
export type Step={id:string,title:string,line1:string,line2:string,duration:number,
    keys1:{Key},keys2:{Key},target:boolean}
export type Input={mx:number,my:number,held:{[string]:boolean},rb:boolean}
export type State={index:number,time:number,input:Input}

local function k(label:string,button:string):Key return {label=label,button=button} end
T.steps={
    {id='move',title='MOVE AROUND',line1='Use the stick or D-pad.',line2='Move up and down to line up a hit.',duration=2.8,target=false,
        keys1={k('W','U'),k('A','L'),k('S','D'),k('D','R')},keys2={k('UP','U'),k('LEFT','L'),k('DOWN','D'),k('RIGHT','R')}},
    {id='dash',title='DOUBLE-TAP TO DASH',line1='Tap a direction twice, quickly.',line2='Add an attack for a dash strike.',duration=2.7,target=false,
        keys1={k('A','L'),k('D','R'),k('J','x')},keys2={k('LEFT','L'),k('RIGHT','R'),k(',','x')}},
    {id='jump',title='JUMP',line1='Tap for a hop. Hold to jump higher.',line2='Keep moving while you are in the air.',duration=3.1,target=false,
        keys1={k('K','a'),k('SPACE','a')},keys2={k('.','a')}},
    {id='combo',title='THREE-HIT COMBO',line1='Tap attack again to keep the combo going.',line2='The third hit knocks enemies down.',duration=2.8,target=true,
        keys1={k('J','x')},keys2={k(',','x')}},
    {id='air',title='AERIAL ATTACK',line1='Jump, then press attack.',line2='Robin follows up with a flying kick.',duration=2.5,target=true,
        keys1={k('K','a'),k('J','x')},keys2={k('.','a'),k(',','x')}},
    {id='special',title='BIRDARANG',line1='B or RB throws a returning birdarang.',line2='Special moves use 30 energy.',duration=2.8,target=true,
        keys1={k('L','b')},keys2={k('/','b')}},
    {id='secondary',title='STAFF CYCLONE',line1='Y unleashes your second power.',line2='This move uses 40 energy.',duration=2.5,target=true,
        keys1={k('I','y')},keys2={k(';','y')}},
    {id='ultimate',title='BIRDARANG STORM',line1='RT unleashes your ultimate.',line2='Fill your energy bar to 100 first.',duration=3.0,target=true,
        keys1={k('U','rt')},keys2={k("'",'rt')}},
    {id='pause',title='JOIN, PAUSE, RETURN',line1='Menu / Enter joins or pauses the game.',line2='When paused, View / Esc returns to the menu.',duration=3.6,target=false,
        keys1={k('ENTER','start'),k('ESC','cancel')},keys2={k('R SHIFT','start'),k('R CTRL','cancel')}},
} :: {Step}

local function between(t:number,a:number,b:number):boolean return t>=a and t<b end
local function pulse(t:number,a:number):boolean return between(t,a,a+.12) end

function T.inputs(index:number,t:number):Input
    local h:{[string]:boolean}={}
    local mx,my,rb=0,0,false
    local id=T.steps[index].id
    if id=='move' then
        if between(t,.35,.95) then mx=.65
        elseif between(t,.95,1.3) then my=.65
        elseif between(t,1.3,1.95) then mx=-.65
        elseif between(t,1.95,2.3) then my=-.65 end
    elseif id=='dash' then
        if between(t,.4,.47) or between(t,.57,.86) then mx=1
        elseif between(t,1.4,1.47) or between(t,1.57,1.95) then mx=-1 end
        h.x=pulse(t,1.62)
    elseif id=='jump' then
        h.a=between(t,.4,.53) or between(t,1.4,2.08)
    elseif id=='combo' then
        h.x=pulse(t,.45) or pulse(t,.69) or pulse(t,1.03)
    elseif id=='air' then
        h.a=between(t,.4,.72);h.x=pulse(t,.65)
    elseif id=='special' then
        rb=pulse(t,1.5);h.b=pulse(t,.45) or rb
    elseif id=='secondary' then h.y=pulse(t,.5)
    elseif id=='ultimate' then h.rt=pulse(t,.5)
    elseif id=='pause' then
        mx=if between(t,.15,2.25) then .45 else 0
        h.start=pulse(t,.6) or pulse(t,1.45) or pulse(t,2.25)
        h.cancel=pulse(t,2.95)
    end
    h.L=mx<0;h.R=mx>0;h.U=my<0;h.D=my>0
    return {mx=mx,my=my,held=h,rb=rb}
end

function T.new():State return {index=1,time=0,input=T.inputs(1,0)} end
function T.next(s:State):boolean
    if s.index==#T.steps then return false end
    s.index+=1;s.time=0;s.input=T.inputs(s.index,0)
    return true
end
function T.previous(s:State)
    s.index=math.max(1,s.index-1);s.time=0;s.input=T.inputs(s.index,0)
end

T.bounds={
    help={x=530,y=672,w=220,h=34},
    skip={x=1064,y=30,w=180,h=48},
    previous={x=32,y=642,w=58,h=48},
    next={x=1088,y=642,w=160,h=48},
}
function T.actionAt(mode:string,x:number,y:number):string?
    for action,b in T.bounds do
        if ((mode=='title' and action=='help') or (mode=='tutorial' and action~='help'))
            and x>=b.x and x<=b.x+b.w and y>=b.y and y<=b.y+b.h then return action end
    end
    return nil
end

local INK=G.INK
local BG=G.hex(0x140C24)
local PANEL=G.hex(0x241A37)
local PAPER=G.hex(0xF5F0DF)
local YELLOW=G.hex(0xFFE14D)
local MUTED=G.hex(0xABA0BC)
local RED=G.hex(0xD7263D)
local CYAN=G.hex(0x7FD8FF)

local function text(locale:L.Locale,s:string,x:number,y:number,size:number,c:Color,align:number?,maxWidth:number?,ink:Color?)
    local value=L.text(locale,s)
    if #value~=utf8.len(value) then size=math.max(14,size) end
    if maxWidth then size=math.min(size,size*maxWidth/math.max(1,G.textWidth(value,size))) end
    G.text(value,x,y,size,c,align,ink)
end

local function button(locale:L.Locale,action:string,label:string,hover:string,primary:boolean)
    local b=T.bounds[action]
    local fill=if primary or action==hover then YELLOW else G.hex(0x3A2D50)
    G.rrect(b.x,b.y+4,b.w,b.h,8,INK)
    G.rrect(b.x,b.y,b.w,b.h,8,fill,2)
    text(locale,label,b.x+b.w/2,b.y+(b.h-16)/2,16,if primary or action==hover then INK else PAPER,.5,b.w-20,if primary or action==hover then fill else INK)
end

function T.drawHelp(locale:L.Locale,hover:string)
    button(locale,'help','HOW TO PLAY',hover,false)
    -- A short affordance on the replay button replaces the old control chart.
    text(locale,'H / Y',766,683,10,MUTED)
end

local function faceButton(label:string,x:number,y:number,c:Color,down:boolean)
    if down then G.circle(x,y,23,YELLOW) end
    G.oellipse(x,y,17,17,G.hex(0x64696F),2)
    G.circle(x,y+(if down then 3 else -1),15,if down then c else G.hex(0x171B20))
    G.label(label,x,y-8+(if down then 3 else 0),16,if down then INK else c,.5)
end

local function controller(input:Input)
    local h=input.held
    local shell=G.hex(0xF5F6F7)
    local rubber=G.hex(0x22262C)
    local edge=G.hex(0x737A82)
    G.save();G.translate(992,296)
    G.ellipse(0,123,172,12,G.fade(G.BLACK,.25))
    -- Xbox Series silhouette: a broad level crown, full body and short grips.
    for _,side in {-1,1} do
        local rt=side==1 and h.rt
        G.rrect(side*105-25,-119+(if rt then 2 else 0),50,29,10,if rt then YELLOW else rubber,3)
        G.label(if side==1 then 'RT' else 'LT',side*105,-116+(if rt then 2 else 0),11,if rt then INK else PAPER,.5)
        local rb=side==1 and input.rb
        G.rrect(side*107-36,-98+(if rb then 2 else 0),72,25,11,if rb then YELLOW else G.hex(0xD8DDE2),3)
        G.label(if side==1 then 'RB' else 'LB',side*107,-97+(if rb then 2 else 0),10,INK,.5)
    end
    G.contour({0,-87, 45,-87,85,-88,112,-77,
        142,-65,151,-37,161,4, 172,46,177,83,167,108,
        162,120,153,127,144,125, 129,116,111,89,96,77,
        85,68,74,68,58,68, 20,68,-20,68,-58,68,
        -74,68,-85,68,-96,77, -111,89,-129,116,-144,125,
        -153,127,-162,120,-167,108, -177,83,-172,46,-161,4,
        -151,-37,-142,-65,-112,-77, -85,-88,-45,-87,0,-87},shell,4)
    -- White shell with a bright upper bevel and softly shaded grip seams.
    G.contour({-137,-57,-110,-84,-60,-83,0,-83,
        60,-83,110,-84,137,-57, 112,-76,60,-78,0,-78,
        -60,-78,-112,-76,-137,-57},G.WHITE)
    for _,side in {-1,1} do
        G.save();G.scale(side,1)
        G.contour({159,22,168,57,172,88,161,108,
            157,116,151,121,144,122, 128,108,112,83,99,76,
            121,79,145,62,159,22},G.hex(0xD8DDE2))
        G.polyline({101,79,121,104,143,124},1.5,G.hex(0xB9C0C8))
        G.restore()
    end
    -- Left analog stick visibly travels with exactly the demo's input vector.
    local moving=input.mx~=0 or input.my~=0
    for _,stick in {{-98,-21,input.mx,input.my},{49,37,0,0}} do
        local x,y=stick[1],stick[2]
        G.oellipse(x,y,30,29,if x<0 and moving then YELLOW else edge,3)
        G.ellipse(x,y,27,26,rubber)
        local sx,sy=x+stick[3]*11,y+stick[4]*11
        G.oellipse(sx,sy,22,21,edge,2)
        G.ellipse(sx,sy,18,17,rubber)
        G.ellipse(sx,sy+2,13,12,G.hex(0x30353B))
    end
    -- The circular, faceted hybrid D-pad is distinctive to the Xbox Series pad.
    G.save();G.translate(-53,36)
    G.oellipse(0,0,32,32,edge,2)
    G.poly({-12,-28,12,-28,28,-12,28,12,12,28,-12,28,-28,12,-28,-12},rubber)
    for _,a in {{0,'U'},{math.pi,'D'},{-math.pi/2,'L'},{math.pi/2,'R'}} do
        local active=h[a[2] :: string]
        G.save();G.rotate(a[1] :: number)
        G.poly({-10,-10,-12,-28,12,-28,10,-10},if active then YELLOW else G.hex(0x535A62))
        G.poly({10,-10,12,-28,28,-12},G.hex(0x353B42))
        G.poly({0,-23,4,-17,-4,-17},if active then INK else G.hex(0x939AA2))
        G.restore()
    end
    G.rect(-10,-10,20,20,G.hex(0x454C54))
    G.restore()
    for _,v in {{-29,'cancel'},{29,'start'}} do
        local x=v[1] :: number
        local active=h[v[2] :: string]
        if active then G.circle(x,-20,16,YELLOW) end
        G.oellipse(x,-20,11,11,if active then YELLOW else rubber,1.5)
        local icon=if active then INK else PAPER
        if x>0 then for i=-1,1 do G.line(x-5,-20+i*3,x+5,-20+i*3,1.3,icon) end
        else
            G.polyline({x-1,-25,x-6,-25,x-6,-20},1.3,icon)
            G.polyline({x-2,-22,x+5,-22,x+5,-16,x-2,-16},1.3,icon,true)
        end
    end
    G.rrect(-13,0,26,17,8,rubber,1.5)
    G.polyline({-6,8,-6,12,6,12,6,8},1.2,edge)
    G.line(0,4,0,9,1.2,edge);G.polyline({-3,6,0,3,3,6},1.2,edge)
    faceButton('Y',106,-49,G.hex(0xF9D33B),h.y==true)
    faceButton('X',75,-18,G.hex(0x4799FF),h.x==true)
    faceButton('B',137,-18,G.hex(0xFF5961),h.b==true and not input.rb)
    faceButton('A',106,13,G.hex(0x78D965),h.a==true)
    G.restore()
end

local function keyRow(locale:L.Locale,keys:{Key},y:number,player:number,input:Input)
    text(locale,if player==1 then 'KEYBOARD 1' else 'KEYBOARD 2',760,y+13,13,MUTED)
    local widths,total={},0
    for _,key in keys do
        local w=math.max(42,#key.label*8+18)
        table.insert(widths,w);total+=w+8
    end
    local x=1130-(total-8)/2
    for i,key in keys do
        local down=input.held[key.button]==true
        local dy=if down then 4 else 0
        G.rrect(x,y+5,widths[i],38,6,INK)
        G.rrect(x,y+dy,widths[i],36,6,if down then YELLOW else PAPER,2)
        G.label(L.text(locale,key.label),x+widths[i]/2,y+12+dy,12,INK,.5)
        x+=widths[i]+8
    end
end

function T.draw(s:State,locale:L.Locale,hover:string,drawDemo:()->(),paused:boolean,returned:boolean)
    local step=T.steps[s.index]
    G.rect(0,0,G.W,G.H,BG)
    G.poly({0,0,580,0,340,720,0,720},G.hex(0x241434))
    text(locale,'HOW TO PLAY',34,23,14,RED)
    text(locale,"ROBIN'S CRASH COURSE",34,55,34,PAPER,0,950)
    button(locale,'skip','SKIP',hover,true)
    text(locale,'START / ENTER / ESC',1244,92,11,MUTED,1)

    G.rrect(28,139,680,477,15,PANEL,3)
    G.save();G.clipRRect(30,141,676,473,13)
    G.save();G.clipRect(30,256,676,358);drawDemo();G.restore()
    G.rect(30,141,676,115,PANEL)
    text(locale,step.title,54,164,29,YELLOW,0,630)
    text(locale,step.line1,54,206,16,PAPER,0,630)
    text(locale,step.line2,54,232,16,MUTED,0,630)
    G.rrect(47,273,104,28,6,RED)
    text(locale,'ROBIN',99,280,13,PAPER,.5)
    text(locale,'AUTO DEMO',688,280,11,MUTED,1)
    if paused or returned then
        G.rect(30,307,676,307,G.fade(BG,.68))
        text(locale,if returned then 'BACK TO MENU' else 'PAUSED',368,425,32,YELLOW,.5)
    end
    G.restore()

    G.rrect(732,139,520,477,15,PANEL,3)
    text(locale,'CONTROLLER',760,155,13,MUTED)
    controller(s.input)
    G.line(756,437,1228,437,1,G.hex(0x554365))
    keyRow(locale,step.keys1,460,1,s.input)
    keyRow(locale,step.keys2,517,2,s.input)
    text(locale,'HIGHLIGHTED BUTTONS PLAY THE DEMO',992,583,12,CYAN,.5,466)

    button(locale,'previous','<',hover,false)
    button(locale,'next',if s.index==#T.steps then 'DONE' else 'NEXT >',hover,false)
    text(locale,`{s.index} / {#T.steps}`,125,655,22,PAPER)
    for i=1,#T.steps do
        local x=242+(i-1)*91
        G.rrect(x,653,79,9,4,G.hex(0x44334F))
        local fraction=if i<s.index then 1 elseif i==s.index then s.time/step.duration else 0
        if fraction>0 then G.rrect(x,653,math.max(8,79*fraction),9,4,if i==s.index then YELLOW else RED) end
    end
    text(locale,'WATCH ROBIN. SKIP ANYTIME.',650,681,12,MUTED,.5)
end

return T
