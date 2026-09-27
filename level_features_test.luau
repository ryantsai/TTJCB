local Game=require('game')
local C=require('campaign')
local B=require('boss_patterns')
local F=require('level_features')
local R=require('remarks')
local L=require('localization')
local S=require('speech')
local G=require('gfx')
local function step(a:any,n:number) for _=1,n do a.advance(a,1/60) end end
local function press(a:any,k:number)
    a.keyboardEvent(a,{key=k,phase='down'});step(a,1)
    a.keyboardEvent(a,{key=k,phase='up'});step(a,1)
end
local function setup(stage:number):any
    local a:any=(Game.create :: any)(nil);a.g.tutorialSeen=true
    press(a,257);press(a,257);press(a,257);press(a,257);step(a,90)
    local g=a.g;local h=g.slots[1].fighter
    g.runLevel=stage;g.cp=stage*4;g.lockX=-1;g.camX=C.checkpoints[g.cp].x
    g.fighters={h};g.shots={};g.pickups={};g.pending={};h.x=g.camX+600;h.y=580
    h.z=0;h.vz=0;h.state='idle';h.hitPause=0;h.invuln=10000
    step(a,1);g.waveT=100;step(a,1)
    local boss=g.boss
    g.fighters={h,boss};g.pending={{kind='bot',delay=9999,side=1}};g.shots={}
    boss.entering=false;boss.x=g.camX+960;boss.y=580;boss.state='idle';boss.st=0;boss.cd=100;boss.signatureCd=100
    return a
end
local function collect(a:any,kind:string)
    local h=a.g.slots[1].fighter
    a.g.pickups={{x=h.x,y=h.y,t=0,dead=false,kind=kind}}
    step(a,1)
end
return function():Tests
    return function(test:Tester)
        test.case('each later level provides its own translated equipment and boss pattern',function(expect)
            local kinds={}
            for stage=2,8 do
                local a=setup(stage);local d=F.defs[stage];local kind=a.g.boss.kind
                expect(kinds[d.kind]).is(nil);kinds[d.kind]=true
                expect(B.labels[kind]~=nil).is(true)
                for _,text in {d.name,d.hint,B.labels[kind]} do expect(L.catalog[text]~=nil).is(true) end
                local found=false
                for _,p in a.g.pickups do if p.kind==d.kind then found=true end end
                expect(found).is(true)
                collect(a,d.kind)
                if d.kind=='capacitor' then expect(a.g.slots[1].energy).is(100)
                else expect(a.g.slots[1].fighter.boost).is(d.kind);expect(a.g.slots[1].fighter.boostT).is(d.duration) end
            end
            expect(L.text('zh-TW','H.I.V.E. ACADEMY')).is('海夫學院')
            expect(L.text('zh-TW','H.I.V.E.')).is('海夫')
        end)
        test.case('boss signatures lock targets, warn before damage, and leave safe space',function(expect)
            for kind in B.labels do
                local a=B.new(kind,960,580,600,575,0)
                for _,z in a.zones do
                    local x,y=z.x,z.y
                    if z.shape=='ring' then x+=z.rx*.7 end
                    if z.shape=='rush' then x,y=B.position(a,(z.start+z.finish)/2) end
                    a.t=z.start-.01;expect(B.hits(a,z,x,y,0)).is(false)
                    a.t=(z.start+z.finish)/2;expect(B.hits(a,z,x,y,0)).is(true)
                    expect(B.hits(a,z,x,y,z.height+1)).is(false)
                    expect(B.hits(a,z,-500,700,0)).is(false)
                    a.t=z.finish;expect(B.hits(a,z,x,y,0)).is(false)
                end
            end
            local ring=B.new('blood',640,580,600,575,0)
            ring.t=1.5;expect(B.hits(ring,ring.zones[1],640,580,0)).is(false)
            local screens=B.new('madmod',960,580,600,575,0);screens.t=1.5
            for _,z in screens.zones do expect(B.hits(screens,z,640,580,0)).is(false) end
        end)
        test.case('every boss starts a signature, pauses its clock and cancels it on defeat',function(expect)
            for stage=1,8 do
                local a=setup(stage);local g=a.g;local b=g.boss;local h=g.slots[1].fighter
                expect(L.catalog[B.labels[b.kind]]~=nil).is(true)
                b.cd=0;b.signatureCd=0
                step(a,1);expect(b.state).is('signature');expect(b.pattern.kind).is(b.kind)
                expect(R.bossLines[b.kind].special~=nil).is(true)
                local t=b.st;g.paused=true;step(a,60);expect(b.st).is(t)
                g.paused=false;step(a,260);expect(b.pattern).is(nil)
                b.state='signature';b.st=0;b.hitPause=0;b.y=h.y
                b.pattern=B.new(b.kind,b.x,b.y,b.x,b.y,g.camX)
                b.hp=1;b.invuln=0;b.z=0;h.boost='';h.boostT=0
                g.shots={{kind='bolt',x=b.x,y=b.y,z=60,vx=0,t=0,life=1,owner=h,dmg=500,knock=false,hit={},dead=false,back=false}}
                step(a,1);expect(b.hp).is(0);expect(b.pattern).is(nil)
            end
        end)
        test.case('Cinderblock fissures travel outward, allow jumping or sidestepping and hit only once',function(expect)
            for _,targetX in {200,1100} do
                local pattern=B.new('boss',640,580,targetX,620,0)
                local lastX=640;local lastStart=0
                for _,z in pattern.zones do
                    expect(z.start).greaterThan(lastStart)
                    expect((z.x-lastX)*(targetX-640)>0).is(true)
                    pattern.t=z.start+.1
                    expect(B.hits(pattern,z,z.x,z.y,0)).is(true)
                    expect(B.hits(pattern,z,z.x,z.y,43)).is(false)
                    expect(B.hits(pattern,z,z.x,z.y+37,0)).is(false)
                    lastX=z.x;lastStart=z.start
                end
            end
            local a=setup(1);local g=a.g;local b=g.boss;local h=g.slots[1].fighter
            g.lockX=-1;g.cp=99;g.pickups={};g.shots={}
            b.state='signature';b.pattern=B.new('boss',b.x,b.y,h.x,h.y,g.camX)
            local pattern=b.pattern;local hp=h.hp
            for i,z in pattern.zones do
                b.st=z.start+.05;b.hitPause=0
                h.x=z.x;h.y=z.y;h.z=0;h.vz=0;h.vx=0;h.vy=0;h.invuln=0;h.hitPause=0;h.state='idle'
                step(a,1);expect(h.hp).is(hp-b.dmg)
                if i==1 then expect(h.state).is('down') end
            end
        end)
        test.case('signature hits are per-phase and mind drain and hypnosis have distinct effects',function(expect)
            for _,kind in {'blood','madmod'} do
                local a=setup(if kind=='blood' then 6 else 5);local g=a.g;local b=g.boss;local h=g.slots[1].fighter
                g.lockX=-1;g.cp=99;g.pickups={};g.shots={};b.state='signature'
                b.pattern=B.new(kind,b.x,b.y,h.x,h.y,g.camX);b.st=1.5
                local z=b.pattern.zones[1];h.x=z.x+(if kind=='blood' then z.rx*.7 else 0);h.y=z.y;h.invuln=0;h.z=0;h.state='idle'
                local hp=h.hp;g.slots[1].energy=80
                step(a,1);expect(h.hp).is(hp-12)
                if kind=='blood' then expect(g.slots[1].energy).lessThan(65) else expect(h.slowT).greaterThan(1.9) end
                h.invuln=0;h.state='idle';h.hitPause=0;step(a,1);expect(h.hp).is(hp-12)
            end
        end)
        test.case('jammer blocks school traps and hypnosis while shields consume three hits',function(expect)
            local a=setup(5);local g=a.g;local h=g.slots[1].fighter;local b=g.boss
            collect(a,'jammer');expect(g.hazardMuted).is(12)
            b.state='signature';b.st=1.5;b.pattern=B.new('madmod',b.x,b.y,h.x,h.y,g.camX)
            h.x=b.pattern.zones[1].x;h.y=570;h.invuln=0
            local hp=h.hp;step(a,1);expect(h.hp).is(hp);expect(h.slowT).is(0)
            b.state='idle';b.pattern=nil;b.cd=100;g.lockX=-1;g.cp=99
            collect(a,'shield')
            for hit=1,4 do
                h.invuln=0;h.state='idle';h.hitPause=0;h.z=0
                g.shots={{kind='laser',x=h.x,y=h.y,z=60,vx=0,t=0,life=1,owner=b,dmg=10,knock=false,hit={},dead=false,back=false}}
                step(a,1)
                expect(h.hp).is(if hit<=3 then hp else hp-10)
            end
        end)
        test.case('equipment produces cover fire, sonic damage, healing and projectile protection',function(expect)
            local a=setup(4);local g=a.g;local h=g.slots[1].fighter;local b=g.boss
            g.lockX=-1;g.cp=99;g.pickups={};b.x=h.x+250;b.y=h.y
            collect(a,'drone');step(a,1);expect(#g.shots).greaterThan(0);expect(g.shots[1].owner).is(h)
            g.shots={};b.x=h.x+100;b.invuln=0;local hp=b.hp
            collect(a,'amplifier');step(a,1);expect(b.hp).is(hp-14)
            h.hp=h.maxHp-20;collect(a,'ward');local health=h.hp
            g.shots={{kind='laser',x=h.x,y=h.y,z=60,vx=0,t=0,life=1,owner=b,dmg=10,knock=false,hit={},dead=false,back=false}}
            h.invuln=0;step(a,30);expect(h.hp).greaterThan(health);expect(#g.shots).is(0)
            local time=h.boostT;g.paused=true;step(a,60);expect(h.boostT).is(time)
            g.paused=false;h.boostT=.01;step(a,1);expect(h.boostT).is(0)
        end)
        test.case('salvage gauntlet strengthens melee only while equipped',function(expect)
            local a=setup(2);local g=a.g;local h=g.slots[1].fighter;local b=g.boss
            g.lockX=-1;g.cp=99;g.pickups={}
            for _,boosted in {false,true,false} do
                h.state='attack';h.st=.1;h.combo=1;h.facing=1;h.hit={};h.hitPause=0;h.z=0
                h.boost='gauntlet';h.boostT=if boosted then 12 else 0
                b.x=h.x+60;b.y=h.y;b.z=0;b.invuln=0;b.state='idle';b.cd=100;b.armor=0
                local hp=b.hp;step(a,1)
                expect(hp-b.hp).is(math.floor(7*h.power*(if boosted then 1.5 else 1)+.5))
            end
        end)
        test.case('boss dialogue has independent voices and all translations fit the speech bubble',function(expect)
            local intros={}
            for kind,bank in R.bossLines do
                for _,lines in bank do
                    expect(#lines).greaterThanOrEqual(3)
                    for _,pair in lines do
                        expect(L.text('zh-TW',pair[1])).is(pair[2])
                        expect(L.text('ja',pair[1])).is(pair[3])
                        for _,text in pair do
                            local wrapped=S.wrap(text);expect(#wrapped).lessThanOrEqual(3)
                            for _,line in wrapped do expect(G.textWidth(line,S.size)).lessThanOrEqual(S.maxWidth) end
                        end
                    end
                end
                expect(intros[bank.encounter[1][1]]).is(nil);intros[bank.encounter[1][1]]=true
                local v=R.new(77);expect(R.offer(v,kind,'encounter')).is(true)
                expect(R.offer(v,kind,'low_health')).is(true)
                expect(R.offer(v,kind,'down')).is(true)
            end
        end)
    end
end
