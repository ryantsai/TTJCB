local G=require('gfx')
local L=require('localization')
local C=require('campaign')
local P=require('progress')
local M={}
local INK=G.INK
local PAPER=G.hex(0xF5F0DF)
local YELLOW=G.hex(0xFFE14D)
local CYAN=G.hex(0x7FD8FF)
local GREEN=G.hex(0x74E5A0)
local MUTED=G.hex(0x9E94B0)
local RED=G.hex(0xFF6375)
local nodes={{180,233},{486,233},{792,233},{1098,233},{180,433},{486,433},{792,433},{1098,433}}
local bosses={'CINDERBLOCK','MAMMOTH','JINX','SLADE','MAD MOD','BROTHER BLOOD','BLACKFIRE','TRIGON'}
M.bounds={reset={x=1002,y=32,w=242,h=48},
    back={x=34,y=651,w=176,h=42},play={x=1004,y=552,w=216,h=52},
    keep={x=388,y=416,w=234,h=52},confirm={x=656,y=416,w=234,h=52}}
local function text(locale:L.Locale,s:string,x:number,y:number,size:number,c:Color,align:number?,width:number?,ink:Color?)
    local v=L.text(locale,s)
    if #v~=utf8.len(v) then size=math.max(14,size) end
    if width then size=math.min(size,size*width/math.max(1,G.textWidth(v,size))) end
    G.text(v,x,y,size,c,align,ink)
end
local function button(locale:L.Locale,key:string,label:string,hover:string,fill:Color,disabled:boolean?)
    local b=M.bounds[key]
    local color=if disabled then G.hex(0x40384C) elseif key==hover then G.shade(fill,.18) else fill
    G.rrect(b.x,b.y+4,b.w,b.h,8,INK)
    G.rrect(b.x,b.y,b.w,b.h,8,color,2)
    text(locale,label,b.x+b.w/2,b.y+(b.h-17)/2,17,if disabled then MUTED else INK,.5,b.w-24,color)
end
function M.actionAt(mode:string,x:number,y:number,confirm:boolean):string?
    for key,b in M.bounds do
        local allowed=if mode=='map' then
            (if confirm then key=='keep' or key=='confirm' else key=='reset' or key=='back' or key=='play') else false
        if allowed and x>=b.x and x<=b.x+b.w and y>=b.y and y<=b.y+b.h then return key end
    end
    if mode=='map' and not confirm then
        for i,n in nodes do if math.abs(x-n[1])<132 and y>=n[2]-92 and y<=n[2]+80 then return `level{i}` end end
    end
    return nil
end
local function lock(x:number,y:number,c:Color)
    G.polyline({x-7,y-3,x-7,y-11,x-3,y-15,x+3,y-15,x+7,y-11,x+7,y-3},3,c)
    G.rrect(x-12,y-4,24,21,4,c);G.circle(x,y+4,2,INK);G.line(x,y+4,x,y+9,2,INK)
end
local function landmark(i:number,x:number,y:number,color:Color)
    G.save();G.translate(x,y);G.scale(.55,.55)
    local dark=G.shade(color,-.5)
    G.poly({-100,20,-75,-2,83,-10,107,15,48,40,-63,44},G.hex(0x322A46),3)
    if i==1 then
        for _,v in {{-67,-64,33,79},{-27,-91,45,100},{27,-51,39,64}} do
            G.rrect(v[1],v[2],v[3],v[4],3,dark,2)
            for row=0,2 do G.rect(v[1]+9,v[2]+12+row*17,8,7,color);G.rect(v[1]+23,v[2]+12+row*17,6,7,color) end
        end
        G.poly({-25,-91,-6,-112,17,-91},color,2)
    elseif i==2 then
        G.line(-67,18,-67,-93,7,color);G.line(-89,-90,55,-90,7,color)
        G.line(-67,-121,-88,-92,3,color);G.line(-67,-121,51,-92,3,color)
        G.line(38,-90,38,-48,3,color);G.polyline({30,-48,30,-39,43,-39},3,color)
        G.rrect(-31,-23,70,33,3,dark,2);G.rrect(0,-57,64,33,3,color,2)
        for k=0,3 do G.line(-19+k*14,-17,-19+k*14,6,2,color) end
        G.polyline({-82,29,-48,35,-5,25,38,33,78,22},3,CYAN)
    elseif i==3 then
        G.rect(-68,-75,21,87,dark);G.rect(46,-94,19,105,dark)
        G.poly({-80,12,-80,-35,-44,-57,-44,-35,-7,-57,-7,-35,29,-57,72,-35,72,12},dark,3)
        G.oellipse(0,-13,21,24,color,3);G.poly({-2,-32,-12,-10,0,-10,-6,7,15,-18,3,-18},INK)
        G.ellipse(55,-108,19,8,G.fade(color,.2));G.ellipse(-58,-91,15,7,G.fade(color,.2))
    elseif i>=5 then
        local color2=if i==8 then RED elseif i==7 then G.hex(0xD4AEFF) elseif i==6 then CYAN else YELLOW
        G.poly({-70,16,-58,-61,0,-100,58,-61,70,16},dark,3)
        if i==8 then
            G.poly({-45,-54,-67,-103,-19,-77,20,-77,67,-103,45,-54,0,-19},color2,3)
            G.line(-28,-58,-8,-51,6,YELLOW);G.line(8,-51,28,-58,6,YELLOW)
        elseif i==7 then G.poly({-34,10,-34,-51,0,-90,34,-51,34,10},color2,3)
        elseif i==6 then G.poly({0,-86,38,-64,38,-20,0,2,-38,-20,-38,-64},color2,3);G.poly({0,-66,17,-55,17,-37,0,-26,-17,-37,-17,-55},INK,2)
        else for k=1,5 do G.ring(0,-44,k*9,k*9,4,if k%2==0 then color2 else PAPER) end end
    else
        G.poly({-48,17,-40,-61,-15,-80,-15,-111,0,-124,15,-111,15,-80,40,-61,48,17},dark,3)
        G.poly({-29,-55,0,-74,29,-55,25,-8,0,8,-25,-8},color,3)
        G.line(0,-69,0,3,3,INK);G.poly({7,-47,23,-41,11,-34},INK)
        G.line(-63,17,-63,-24,4,color);G.line(63,17,63,-24,4,color)
    end
    G.restore()
end
function M.draw(locale:L.Locale,p:P.State,selected:number,cleared:number,confirm:boolean,resetYes:boolean,hover:string,t:number)
    G.rect(0,0,1280,720,G.hex(0x140C24))
    G.poly({0,0,675,0,337,720,0,720},G.hex(0x241434))
    for x=0,1280,64 do G.line(x,133,x,516,1,G.hex(0x30253F)) end
    for y=133,516,64 do G.line(0,y,1280,y,1,G.hex(0x30253F)) end
    text(locale,'LEVEL MAP',34,32,43,PAPER)
    local summary=if cleared>0 then L.format(locale,'LEVEL {level} CLEARED!',{level=cleared}) else
        L.format(locale,'{count} / 8 LEVELS CLEARED',{count=p.cleared})
    text(locale,summary,37,94,18,if cleared>0 then GREEN else CYAN)
    button(locale,'reset','RESET PROGRESS',hover,RED)
    for i=1,#nodes-1 do
        local a,b=nodes[i],nodes[i+1]
        local mid=(a[1]+b[1])/2
        local route={a[1],a[2],mid,a[2],mid,b[2],b[1],b[2]}
        G.polyline(route,17,INK)
        G.polyline(route,7,if i<=p.cleared then GREEN else G.hex(0x51445F))
    end
    for i,n in nodes do
        local available=P.canPlay(p,i)
        local color=if i<=p.cleared then GREEN elseif available then YELLOW else MUTED
        landmark(i,n[1],n[2]-35,if available then color else G.hex(0x62576E))
        if i==selected then G.ring(n[1],n[2],35+math.sin(t*3)*2,35+math.sin(t*3)*2,3,CYAN) end
        G.oellipse(n[1],n[2],28,28,if available then color else G.hex(0x393044),4)
        if available then G.text(tostring(i),n[1],n[2]-12,24,INK,.5,color)
        else lock(n[1],n[2],MUTED) end
        if i<=p.cleared then
            G.oellipse(n[1]+25,n[2]-23,14,14,GREEN,2)
            G.polyline({n[1]+28,n[2]-29,n[1]+33,n[2]-24,n[1]+42,n[2]-35},3,INK)
        end
        text(locale,C.stages[i].name,n[1],n[2]+40,17,if available then PAPER else MUTED,.5,258)
        text(locale,if i<=p.cleared then 'CLEARED' elseif available then 'AVAILABLE' else 'LOCKED',n[1],n[2]+66,11,color,.5)
    end
    G.rrect(30,526,1220,105,12,G.hex(0x2A1E3C),3)
    text(locale,L.format(locale,'LEVEL {level}',{level=selected}),52,544,13,CYAN)
    text(locale,C.stages[selected].name,52,571,26,PAPER,0,350)
    text(locale,L.format(locale,'4 WAVES / {boss}',{boss=L.text(locale,bosses[selected])}),440,546,16,YELLOW,0,515)
    local detail=if not P.canPlay(p,selected) then L.format(locale,'Clear {level} to unlock.',{level=L.text(locale,C.stages[selected-1].name)})
        elseif selected<=p.cleared then 'Cleared! Replay this level anytime.' else 'Defeat the boss to unlock the next level.'
    if selected==P.levels and P.canPlay(p,selected) and p.cleared<P.levels then detail='Defeat Trigon and restore the world.' end
    text(locale,detail,440,580,15,MUTED,0,520)
    button(locale,'play',if not P.canPlay(p,selected) then 'LOCKED' elseif selected<=p.cleared then 'REPLAY LEVEL' else 'PLAY LEVEL',hover,YELLOW,not P.canPlay(p,selected))
    button(locale,'back','BACK',hover,PAPER)
    local status=if p.status=='saved' then 'SAVED IN THIS BROWSER' elseif p.status=='unavailable' then 'SAVING UNAVAILABLE - SESSION ONLY' else 'SESSION PROGRESS'
    text(locale,status,640,674,12,MUTED,.5,630)
    text(locale,'MOVE: SELECT   A / SPACE: PLAY   R / Y: RESET',1243,644,11,MUTED,1,745)
    if confirm then
        G.rect(0,0,1280,720,G.fade(INK,.88))
        G.rrect(314,232,652,270,16,G.hex(0x2A1E3C),4)
        text(locale,'RESET PROGRESS?',640,264,32,RED,.5,586)
        text(locale,'All cleared levels will be locked again.',640,328,18,PAPER,.5,580)
        text(locale,'Level 1 will remain available.',640,366,17,MUTED,.5,570)
        button(locale,'keep','KEEP PROGRESS',if not resetYes then 'keep' else hover,PAPER)
        button(locale,'confirm','RESET',if resetYes then 'confirm' else hover,RED)
        local b=M.bounds[if resetYes then 'confirm' else 'keep']
        G.polyline({b.x,b.y+b.h+10,b.x+b.w,b.y+b.h+10},3,YELLOW)
    end
end
return M
