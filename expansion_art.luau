-- Cartoon-inspired silhouettes and locations for the second campaign arc.
local G=require('gfx')
local P=require('pose')
local E={}
local H=G.hex
local K=G.INK
local kinds={modbot=true,hive=true,gordanian=true,demon=true,madmod=true,blood=true,blackfire=true,trigon=true}
function E.has(kind:string):boolean return kinds[kind]==true end
function E.height(kind:string):number return if kind=='trigon' then 450 else 145 end
local function giant(p:P.Pose)
    local breath=math.sin(p.t*1.6)*5
    local red=H(0xAC303D)
    -- 450px tall, 430px wide: roughly one third of the 1280px arena.
    G.save();G.translate(0,breath);G.scale(1,1-p.down*.8)
    G.poly({-88,-160,-90,-26,-131,0,-33,0,-20,-140,30,-140,42,0,132,0,94,-29,90,-170},H(0x6C2634),5)
    G.poly({-164,-305,-135,-150,-75,-116,76,-116,145,-162,158,-310,64,-363,-63,-363},red,6)
    G.poly({-132,-278,-70,-260,-10,-280,-22,-220,-93,-230},H(0xCF4950))
    G.poly({132,-278,70,-260,10,-280,22,-220,93,-230},H(0xCF4950))
    G.poly({-101,-182,102,-182,92,-140,-90,-140},H(0x9693A5),5)
    G.poly({-29,-189,28,-189,37,-149,0,-128,-37,-149},H(0xE3CC86),4)
    for side=-1,1,2 do
        local reach=if p.move==7 and p.ext>0 then 40 elseif p.move==6 then math.max(0,p.ext)*38 else 0
        G.poly({side*123,-309,side*182,-280,side*(207+reach),-128,side*149,-97,side*122,-213},red,5)
        G.rrect(side*(179+reach)-34,-156,68,36,6,H(0x8A879C),4)
        G.oellipse(side*(180+reach),-98,38,46,red,4)
        for j=0,2 do G.poly({side*(163+j*14+reach),-72,side*(169+j*14+reach),-46,side*(180+j*14+reach),-76},H(0xEADAB2),2) end
    end
    G.poly({-71,-385,-57,-319,0,-286,58,-319,72,-385,41,-422,-44,-422},H(0xCD4147),5)
    for side=-1,1,2 do
        G.poly({side*47,-400,side*97,-432,side*121,-450,side*106,-391,side*64,-365},H(0xE6D6AF),4)
        for row=0,1 do
            G.poly({side*8,-384+row*25,side*52,-390+row*25,side*42,-371+row*25,side*14,-371+row*25},H(0xFFE78B),2)
            G.line(side*29,-383+row*25,side*29,-373+row*25,4,H(0xE25132))
        end
    end
    G.poly({-18,-334,0,-326,18,-334,10,-307,-9,-307},K)
    G.poly({-10,-302,0,-272,11,-303},H(0xDBCEAE),2)
    G.restore()
end
function E.fighter(kind:string,p:P.Pose)
    if kind=='trigon' then giant(p);return end
    local heavy=kind=='gordanian'
    local width=if heavy then 38 elseif kind=='modbot' then 27 else 24
    local skin=H(if kind=='demon' then 0xE76032 elseif heavy then 0x84AD61 elseif kind=='blackfire' then 0xE6A266 else 0xE6C6AE)
    local suit=H(if kind=='madmod' then 0xBA3042 elseif kind=='blood' then 0xAE243B elseif kind=='blackfire' then 0x453552 elseif kind=='demon' then 0xC84729 elseif heavy then 0x504A65 else 0x4A557A)
    local stride=math.sin(p.phase)*13*p.walk
    G.save();G.translate(0,math.sin(p.t*2)*2);G.rotate(p.down*1.4)
    if kind=='blackfire' then G.poly({-26,-136,-39,-65,-29,-33,31,-35,39,-75,28,-137},H(0x211A32),3) end
    if kind=='blood' then G.poly({-24,-104,-54,-9,0,-23,49,-9,26,-105},H(0x591B39),3) end
    for side=-1,1,2 do
        local fx=side*14+side*stride
        G.polyline({side*12,-51,side*17,-28,fx,-8},if heavy then 19 else 12,H(0x303044))
        G.rrect(fx-10,-13,25,13,5,K,2)
    end
    G.poly({-width,-108,width,-108,width*.7,-47,-width*.7,-47},suit,3)
    G.line(-width*.72,-58,width*.72,-58,6,H(0xBBC0C9))
    for side=-1,1,2 do
        local extension=if side==1 then math.max(0,p.ext)*24 else 0
        local hx=side*(width+15)+extension
        G.polyline({side*width,-100,side*(width+11),-77,hx,-66-extension*.7},if heavy then 17 else 11,suit)
        G.oellipse(hx,-65-extension*.7,if heavy then 10 else 7,9,skin,2)
    end
    G.oellipse(0,-123,if heavy then 24 else 19,22,skin,3)
    if kind=='madmod' then
        G.poly({-21,-119,-23,-140,-4,-151,21,-139,22,-127,4,-137},H(0xE66C25),2)
        G.line(-16,-117,-5,-115,3,K);G.line(5,-115,16,-117,3,K)
        G.poly({-7,-103,0,-95,7,-103,0,-87},G.WHITE,2)
        G.line(41,-83,41,-4,4,H(0xECD19A));G.circle(41,-86,7,H(0x9DEBD9))
        G.line(-19,-82,19,-82,5,G.WHITE);G.line(0,-102,0,-61,5,G.WHITE)
    elseif kind=='blood' then
        G.poly({-21,-130,-18,-147,0,-155,18,-147,21,-130,12,-110,-12,-110},H(0xDDDCE6),2)
        G.poly({-16,-135,16,-135,11,-121,-12,-121},K)
        G.line(-12,-129,-3,-129,3,H(0xF65361));G.line(3,-129,12,-129,3,H(0xF65361))
        G.poly({0,-101,-14,-85,0,-64,14,-85},H(0xEFE1B0),2)
    elseif kind=='blackfire' then
        G.poly({-22,-126,-20,-145,3,-150,23,-136,20,-110,9,-131,-4,-125,-10,-137},H(0x20182F),2)
        G.line(-13,-120,-4,-119,3,H(0xAD59FF));G.line(5,-119,15,-120,3,H(0xAD59FF))
        G.poly({-19,-98,19,-98,15,-77,-15,-77},H(0xAEB3C4),2)
        G.circle(0,-95,6,H(0xA96AF2));G.poly({-16,-63,16,-63,27,-43,-27,-43},suit,2)
        if p.move==6 then G.glow(48,-77,25,H(0xBD6EFF),.8) end
    elseif heavy then
        G.poly({-22,-132,-8,-150,5,-142,25,-137,31,-118,10,-112,-20,-112},skin,2)
        G.poly({-13,-149,-3,-164,5,-144},H(0xD5C6A0),2)
        G.line(5,-132,18,-129,4,H(0xFDE89B));G.line(7,-117,26,-117,3,K)
        G.poly({-39,-104,-28,-119,-10,-101},H(0xB9B8C6),2)
    elseif kind=='demon' then
        G.poly({-23,-117,-29,-143,-13,-133,0,-160,10,-136,28,-151,23,-118},H(0xFFB53F),2)
        G.poly({-15,-124,-2,-119,-10,-115},G.WHITE);G.poly({3,-119,17,-124,12,-115},G.WHITE)
        G.poly({-20,-92,0,-115,21,-89,0,-54},H(0xFFCE58),2)
    else
        G.rrect(-22,-142,44,35,6,suit,3)
        G.rect(-15,-130,31,9,H(if kind=='modbot' then 0xFF687A else 0xF4DD5D))
        if kind=='modbot' then
            G.rrect(-24,-160,48,19,3,K,2);G.rect(-29,-143,59,5,K)
            G.line(-17,-93,17,-93,5,G.WHITE);G.line(0,-105,0,-67,5,H(0xDF3348))
        else G.poly({0,-102,16,-86,0,-69,-16,-86},H(0xF1D649),2);G.text('H',0,-94,16,K,.5) end
    end
    G.restore()
end
function E.stage(cam:number,t:number,theme:string):boolean
    if theme~='school' and theme~='academy' and theme~='tamaran' and theme~='inferno' then return false end
    local accent=H(if theme=='school' then 0xFF6FA0 elseif theme=='academy' then 0x54DFEC elseif theme=='tamaran' then 0xD6A0FF else 0xFF854C)
    G.vgrad(0,0,1280,470,H(if theme=='inferno' then 0x591E2A else 0x171E45),H(if theme=='tamaran' then 0xAA527F else 0x47314C))
    if theme=='school' then
        for row=0,7 do for col=0,15 do
            local x=(col*100-cam*.3)%1600-100
            G.poly({x,row*58,x+95,row*58+8,x+95,row*58+62,x,row*58+54},H(if (col+row)%2==0 then 0xE7DAD4 else 0x29203F),2)
        end end
        for i=0,3 do
            local x=(i*370-cam*.6)%1480-100
            G.rrect(x,220,120,226,48,H(0x912D59),5)
            for k=1,6 do G.ring(x+60,300,48-k*6,48-k*6,3,if k%2==0 then G.WHITE else K) end
            G.circle(x+94,386,7,H(0xE6C568))
        end
    elseif theme=='academy' then
        for i=0,4 do
            local x=(i*320-cam*.35)%1600-140
            G.poly({x,80,x+80,120,x+80,390,x,435,x-80,390,x-80,120},H(0x25384F),5)
            G.poly({x,175,x+52,206,x+52,322,x,353,x-52,322,x-52,206},H(0x10293C),4)
            G.line(x,203,x,326,7,accent);G.line(x-38,265,x+38,265,7,accent)
            G.glow(x,267,80,accent,.15)
        end
        G.rrect(490,190,300,60,9,H(0xB83453),4);G.text('H.I.V.E. ACADEMY',640,211,22,G.WHITE,.5)
    elseif theme=='tamaran' then
        G.circle(1040,183,86,H(0xF1CFAB));G.circle(226,155,42,H(0xBDAAF3))
        for i=0,7 do
            local x=(i*210-cam*.2)%1680-180
            G.poly({x,440,x+22,243,x+55,198,x+80,102,x+105,198,x+139,243,x+162,440},H(0x6A436B),4)
            G.poly({x+54,244,x+81,181,x+110,244},H(0xEAB769),3)
            G.rect(x+64,286,32,83,H(0xB893BA))
        end
        G.poly({475,442,540,360,740,360,810,442},H(0xD59A77),4)
        G.poly({570,360,570,280,640,227,710,280,710,360},H(0xB590BE),4)
        G.circle(640,300,27,accent)
    else
        G.circle(960,155,84,H(0xE06535));G.circle(965,151,66,H(0x36182E))
        for i=0,10 do
            local x=(i*156-cam*.23)%1716-100
            local h=105+(i%4)*38
            G.poly({x,445,x,445-h,x+29,458-h,x+55,420-h,x+81,451-h,x+110,437-h,x+110,445},H(0x231C2B),4)
            G.line(x+30,445-h,x+60,415,3,H(0xB7513C))
        end
        G.poly({550,432,580,260,543,218,728,218,698,260,716,432},H(0x453B49),5)
        for i=0,5 do G.glow(i*260,433,80,H(0xFE7834),.22) end
    end
    G.rect(0,443,1280,29,H(0x343044));G.line(0,444,1280,444,5,accent)
    G.vgrad(0,472,1280,248,H(if theme=='tamaran' then 0x936A86 else 0x444053),H(0x201D30))
    for i=0,13 do
        local x=i*110-cam%110
        G.line(x,472,x-70,720,2,G.fade(accent,.25))
    end
    for y=510,720,65 do G.line(0,y,1280,y,2,G.fade(accent,.22)) end
    if theme=='inferno' then
        for i=0,5 do local x=(i*291-cam)%1746-100;G.polyline({x,484,x+35,520,x+10,560,x+82,625,x+70,720},5,H(0xE06A43)) end
    end
    return true
end
return E
