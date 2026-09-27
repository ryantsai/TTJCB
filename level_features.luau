-- Recoverable stage equipment. Effects are applied by game.luau.
local G=require('gfx')
local L=require('localization')
local F={}
export type Def={kind:string,name:string,hint:string,color:number,duration:number}
F.defs={
    [2]={kind='gauntlet',name='SALVAGE GAUNTLET',hint='12S: MELEE DAMAGE +50%',color=0xF3B85D,duration=12},
    [3]={kind='capacitor',name='HEX CAPACITOR',hint='RESTORE 60 ENERGY',color=0xF577CD,duration=0},
    [4]={kind='drone',name='HACKED DRONE',hint='12S: ROBOT COVER FIRE',color=0x73DBFF,duration=12},
    [5]={kind='jammer',name='HYPNO JAMMER',hint='12S: TRAPS AND HYPNOSIS BLOCKED',color=0xD5B4FF,duration=12},
    [6]={kind='amplifier',name='SONIC AMPLIFIER',hint='10S: CLOSE-RANGE SONIC PULSES',color=0x51EEE2,duration=10},
    [7]={kind='shield',name='TAMARANEAN SHIELD',hint='12S: BLOCK THREE HITS',color=0xDB9BFF,duration=12},
    [8]={kind='ward',name='AZARATH WARD',hint='10S: HEAL AND CLEAR PROJECTILES',color=0xF3F1FF,duration=10},
} :: {[number]:Def}
function F.get(kind:string):Def?
    for _,d in F.defs do if d.kind==kind then return d end end
    return nil
end
function F.icon(kind:string,x:number,y:number,t:number)
    local d=F.get(kind);if not d then return end
    local c=G.hex(d.color)
    G.save();G.translate(x,y)
    G.oellipse(0,0,26,26,G.hex(0x231D35),3)
    if kind=='gauntlet' then
        G.rrect(-16,-10,27,24,5,c,2);for i=0,3 do G.rrect(-17+i*8,-18,7,17,3,c,1) end
    elseif kind=='capacitor' then
        G.rrect(-14,-17,28,34,4,c,2);G.poly({1,-14,-9,3,0,3,-2,14,10,-4,1,-4},G.INK)
    elseif kind=='drone' then
        G.rrect(-15,-9,30,21,6,c,2);G.circle(0,0,6,G.WHITE);G.line(-24,-15,24,-15,3,c);G.line(0,-15,0,-22,3,c)
    elseif kind=='jammer' then
        G.line(0,16,0,-14,5,c);for i=1,3 do G.ring(0,-7,i*7,i*7,2,c) end;G.line(-19,19,19,-19,4,G.WHITE)
    elseif kind=='amplifier' then
        G.rrect(-17,-20,34,40,4,c,2);G.oellipse(0,6,11,11,G.INK,2);G.circle(0,-11,5,G.INK)
    elseif kind=='shield' then
        G.poly({0,-22,18,-12,14,10,0,22,-14,10,-18,-12},c,3);G.poly({0,-13,9,0,0,13,-9,0},G.WHITE)
    else
        G.poly({0,17,-6,0,-23,-17,-10,-12,0,-19,10,-12,23,-17,6,0},c,2);G.circle(0,-9,4,G.INK)
    end
    G.restore()
end
function F.draw(kind:string,x:number,y:number,t:number,locale:L.Locale)
    local d=F.get(kind);if not d then return end
    F.icon(kind,x,y-30-math.sin(t*4)*4,t)
    G.text(L.text(locale,d.name),x,y+7,14,G.hex(d.color),.5)
    G.text(L.text(locale,d.hint),x,y+27,if locale=='zh-TW' then 14 else 10,G.WHITE,.5)
end
return F
