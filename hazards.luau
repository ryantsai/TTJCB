-- One deterministic hazard per encounter. Telegraphs and hit tests share geometry.
local G=require('gfx')
local L=require('localization')
local H={}
export type Zone={kind:string,x:number,y:number,rx:number,ry:number,height:number,active:boolean,warning:boolean,cycle:number,label:string}
function H.zone(stage:number,wave:number,t:number):Zone?
    if stage==1 then return nil end
    local cycle=math.floor(t/9)
    local phase=t%9
    local lane=500+((cycle+wave)%3)*70
    local z:Zone={kind='vent',x=350+((cycle+wave)%3)*290,y=lane,rx=135,ry=48,height=45,
        active=phase>=4 and phase<6,warning=phase>=2 and phase<4,cycle=cycle,label='JUMP THE STEAM'}
    if stage==2 then
        z.kind='truck';z.x=-220+(phase-4)*860;z.y=lane;z.rx=145;z.ry=39;z.height=110;z.label='CARGO TRUCK - CLEAR THE LANE'
    elseif stage==3 then z.kind='reactor';z.height=180;z.label='REACTOR VENT - MOVE AWAY'
    elseif stage==4 then z.kind='laser';z.x=640;z.rx=640;z.ry=24;z.height=38;z.label='SECURITY LASER - JUMP'
    elseif stage==5 then z.kind='tiles';z.rx=155;z.height=35;z.label='FALSE FLOOR - JUMP OR MOVE'
    elseif stage==6 then z.kind='pulse';z.rx=210;z.ry=65;z.height=40;z.label='SONIC FIELD - JUMP'
    elseif stage==7 then z.kind='orbital';z.rx=110;z.ry=58;z.height=400;z.label='ORBITAL STRIKE - MOVE AWAY'
    else z.kind='lava';z.rx=150;z.ry=60;z.height=300;z.label='HELLFIRE - MOVE AWAY' end
    return z
end
function H.hits(z:Zone,x:number,y:number,height:number):boolean
    return z.active and height<z.height and math.abs(x-z.x)<z.rx and math.abs(y-z.y)<z.ry
end
function H.draw(z:Zone,locale:L.Locale,t:number,body:boolean)
    if not z.active and not z.warning then return end
    local color=G.hex(if z.warning then 0xFFE14D elseif z.kind=='pulse' then 0x6DE8FF else 0xFF654E)
    if not body then
        local x,rx=z.x,z.rx
        if z.kind=='truck' then x=640;rx=640 end
        G.rrect(x-rx,z.y-z.ry,rx*2,z.ry*2,8,G.fade(color,if z.warning then .13 else .28))
        G.line(x-rx,z.y-z.ry,x+rx,z.y-z.ry,3,color)
        G.line(x-rx,z.y+z.ry,x+rx,z.y+z.ry,3,color)
        for k=0,math.floor(rx/35) do
            local px=x-rx+k*70
            G.polyline({px,z.y-8,px+14,z.y,px,z.y+8},3,color)
        end
        G.text(L.text(locale,z.label),640,160,16,color,.5)
    elseif z.active then
        if z.kind=='truck' then
            local x,y=z.x,z.y
            G.rrect(x-140,y-90,200,85,8,G.hex(0x287F90),4)
            G.rrect(x+60,y-73,80,68,10,G.hex(0xEFA62F),4)
            G.rrect(x+73,y-62,50,30,4,G.hex(0xA5EFF5),3)
            for k=0,5 do G.line(x-122+k*29,y-77,x-122+k*29,y-21,3,G.hex(0x185663)) end
            for _,dx in {-90,92} do G.oellipse(x+dx,y-4,23,23,G.INK,3);G.circle(x+dx,y-4,10,G.hex(0x9AABC5)) end
            G.text('H.I.V.E.',x-40,y-59,18,G.WHITE,.5)
            G.circle(x+139,y-28,7,G.hex(0xFFF9B0))
        elseif z.kind=='laser' then
            G.line(0,z.y-26,1280,z.y-26,12,G.fade(color,.4));G.line(0,z.y-26,1280,z.y-26,4,G.WHITE)
        elseif z.kind=='pulse' or z.kind=='tiles' then
            for i=1,3 do G.ring(z.x,z.y,z.rx*i/3,z.ry*i/3,4,G.fade(color,.8)) end
        else
            for i=-2,2 do
                local x=z.x+i*z.rx*.32
                local h=60+math.abs(math.sin(t*7+i))*95
                G.poly({x-25,z.y+8,x-15,z.y-h*.6,x,z.y-h,x+24,z.y-33,x+27,z.y+8},color,2)
                G.poly({x-11,z.y,x,z.y-h*.7,x+13,z.y},G.hex(0xFFE9A3))
            end
            if z.kind=='orbital' then G.line(z.x,190,z.x,z.y,22,G.fade(G.hex(0xDDA4FF),.6)) end
        end
    end
end
return H
