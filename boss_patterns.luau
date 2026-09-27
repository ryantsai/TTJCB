-- Authored encounters inspired by the cartoon; research in docs/level-identities.md.
-- Warning shapes and collision share the same immutable, target-locked geometry.
local G=require('gfx')
local L=require('localization')
local B={}
export type Zone={x:number,y:number,rx:number,ry:number,height:number,start:number,finish:number,phase:number,shape:string,inner:number}
export type Attack={kind:string,label:string,color:Color,x:number,y:number,tx:number,ty:number,t:number,total:number,zones:{Zone},hits:{[string]:boolean}}
B.labels={boss='CONCRETE FISSURE - JUMP OR SIDESTEP',mammoth='MAMMOTH RUSH - LEAVE THE LANE',jinx='BAD LUCK - LEAVE THE HEXES',slade='CROSS STRIKE - CHANGE LANES',madmod='HYPNOSCREENS - FIND THE GAP',blood='MIND DRAIN - GET INSIDE OR OUT',blackfire='CHARTA STORM - DODGE THE MARKS',trigon='FOUR-EYE BEAMS - FIND A SAFE LANE'} :: {[string]:string}
B.colors={boss=0xC0CBD6,mammoth=0xF5AA49,jinx=0xF478C5,slade=0xF7B14C,madmod=0xD399FF,blood=0xFF557A,blackfire=0xB984FF,trigon=0xFF763D} :: {[string]:number}
function B.new(kind:string,x:number,y:number,tx:number,ty:number,cam:number):Attack
    local a:Attack={kind=kind,label=B.labels[kind],color=G.hex(B.colors[kind]),x=x,y=y,tx=math.clamp(tx,cam+180,cam+1100),ty=math.clamp(ty,510,640),t=0,total=3.6,zones={},hits={}}
    local function zone(px:number,py:number,rx:number,ry:number,height:number,start:number,finish:number,phase:number,shape:string,inner:number)
        table.insert(a.zones,{x=px,y=py,rx=rx,ry=ry,height=height,start=start,finish=finish,phase=phase,shape=shape,inner=inner})
    end
    if kind=='boss' then
        -- A concrete crack travels from his feet toward the locked target's side.
        -- One shared phase prevents overlapping segments from hitting twice.
        local edge=if a.tx<x then cam+70 else cam+1210
        local stride=(edge-x)/4
        for i=0,3 do zone(x+stride*(i+.5),y,math.abs(stride)/2,36,42,1.2+i*.22,1.5+i*.22,1,'fissure',0) end
    elseif kind=='mammoth' then
        zone((x+a.tx)/2,a.ty,math.abs(x-a.tx)/2+65,38,95,1,1.9,1,'rush',0)
        zone(a.tx,a.ty,150,72,38,1.9,2.25,1,'ellipse',0)
    elseif kind=='jinx' then
        for i=-1,1 do zone(math.clamp(a.tx+i*190,cam+140,cam+1140),math.clamp(a.ty+i*35,495,665),105,45,300,1+(i+1)*.45,1.4+(i+1)*.45,i+2,'hex',0) end
    elseif kind=='slade' then
        zone((x+a.tx)/2,a.ty,math.abs(x-a.tx)/2+75,27,105,.95,1.3,1,'rect',0)
        zone((x+a.tx)/2,if a.ty>580 then a.ty-85 else a.ty+85,math.abs(x-a.tx)/2+75,27,105,1.8,2.15,2,'rect',0)
    elseif kind=='madmod' then
        zone(cam+310,570,170,85,300,1.2,2.6,1,'screen',0)
        zone(cam+970,570,170,85,300,1.2,2.6,1,'screen',0)
    elseif kind=='blood' then
        zone(x,y,340,140,220,1.3,2.6,1,'ring',.43)
    elseif kind=='blackfire' then
        for i=0,3 do zone(cam+230+i*265,if i%2==0 then 535 else 620,90,48,400,1.1+i*.38,1.4+i*.38,i+1,'star',0) end
    else
        a.total=4
        for i=0,3 do zone(cam+580,495+i*50,510,15,320,1.5,2.6,1,'beam',0) end
    end
    return a
end
function B.contains(z:Zone,x:number,y:number,height:number):boolean
    if height>=z.height then return false end
    local dx,dy=(x-z.x)/z.rx,(y-z.y)/z.ry
    if z.shape=='rect' or z.shape=='rush' or z.shape=='screen' or z.shape=='beam' or z.shape=='fissure' then return math.abs(dx)<1 and math.abs(dy)<1 end
    local r=dx*dx+dy*dy
    return r<1 and (z.inner==0 or r>z.inner*z.inner)
end
function B.position(a:Attack,t:number):(number,number)
    if a.kind=='mammoth' then return a.x+(a.tx-a.x)*math.clamp((t-1)/.9,0,1),a.ty end
    if a.kind=='slade' then
        if t<1.5 then return a.x+(a.tx-a.x)*math.clamp((t-.95)/.35,0,1),a.ty end
        return a.tx+(a.x-a.tx)*math.clamp((t-1.8)/.35,0,1),a.zones[2].y
    end
    return a.x,a.y
end
function B.hits(a:Attack,z:Zone,x:number,y:number,height:number):boolean
    if a.t<z.start or a.t>=z.finish then return false end
    if z.shape=='rush' then
        local bx,by=B.position(a,a.t)
        return math.abs(x-bx)<80 and math.abs(y-by)<z.ry and height<z.height
    end
    return B.contains(z,x,y,height)
end
function B.draw(a:Attack,cam:number,locale:L.Locale)
    for _,z in a.zones do
        if a.t<z.finish then
            local x,y=z.x-cam,z.y
            local active=a.t>=z.start
            local c=if active then a.color else G.hex(0xFFE14D)
            local alpha=if active then .4 else .13
            if z.shape=='rect' or z.shape=='rush' or z.shape=='screen' or z.shape=='beam' or z.shape=='fissure' then
                G.rrect(x-z.rx,y-z.ry,z.rx*2,z.ry*2,7,G.fade(c,alpha),2)
                G.line(x-z.rx,y-z.ry,x+z.rx,y-z.ry,3,c);G.line(x-z.rx,y+z.ry,x+z.rx,y+z.ry,3,c)
            else
                G.oellipse(x,y,z.rx,z.ry,G.fade(c,alpha),2)
                G.ring(x,y,z.rx,z.ry,3,c)
            end
            if z.shape=='fissure' then
                G.polyline({x-z.rx,y,x-z.rx*.5,y-10,x,y+12,x+z.rx*.5,y-8,x+z.rx,y},if active then 9 else 3,if active then G.INK else c)
                if active then
                    for i=-1,1 do
                        local px=x+i*z.rx*.6
                        G.poly({px-16,y-3,px-11,y-25,px+7,y-31,px+18,y-14,px+11,y+2},a.color,2)
                        G.line(px-8,y-19,px+7,y-13,2,G.hex(0x697487))
                    end
                end
            elseif z.shape=='ring' then
                G.ellipse(x,y,z.rx*z.inner,z.ry*z.inner,G.hex(0x373347))
                G.ring(x,y,z.rx*z.inner,z.ry*z.inner,3,G.hex(0x91FFCE))
            elseif z.shape=='hex' then
                G.polyline({x-z.rx*.6,y,x-z.rx*.3,y-z.ry*.8,x+z.rx*.3,y-z.ry*.8,x+z.rx*.6,y,x+z.rx*.3,y+z.ry*.8,x-z.rx*.3,y+z.ry*.8,x-z.rx*.6,y},3,c)
                if active then G.line(x,y-140,x,y,8,a.color) end
            elseif z.shape=='screen' then
                G.rrect(x-46,y-145,92,65,10,G.hex(0x25213D),3)
                for i=1,4 do G.ring(x,y-113,i*9,i*6,2,c) end
                G.line(x,y-80,x,y,5,c)
            elseif z.shape=='star' then
                G.polyline({x,y-z.ry,x+20,y-12,x+z.rx,y,x+20,y+12,x,y+z.ry,x-20,y+12,x-z.rx,y,x-20,y-12,x,y-z.ry},3,c)
                if active then G.line(x,230,x,y,18,a.color) end
            elseif z.shape=='beam' and active then G.line(x-z.rx,y,x+z.rx,y,12,a.color)
            elseif z.shape=='rush' then
                for px=x-z.rx+25,x+z.rx-25,65 do G.polyline({px-10,y-10,px+6,y,px-10,y+10},3,c) end
            end
        end
    end
end
function B.drawLabel(a:Attack,locale:L.Locale)
    local text=L.text(locale,a.label)
    local w=G.textWidth(text,16)+32
    G.rrect(640-w/2,184,w,29,7,G.hex(0x20172F),2)
    G.text(text,640,191,16,G.hex(0xFFE14D),.5)
end
return B
