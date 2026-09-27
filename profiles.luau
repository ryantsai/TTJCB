-- Three-quarter gameplay drawings, shaped against the show's character lineup.
-- Features share one face plane; the far eye is only lightly foreshortened.
-- The title/select artwork remains in heroes.luau.
local G = require('gfx')
local H, I = G.hex, G.INK
local F = {}

function F.robin(x: number, y: number, hurt: boolean)
    G.save(); G.translate(x,y)
    local skin, hair = H(0xF7BEA5), H(0x090A10)
    G.oellipse(-24,3,4.2,6.4,skin,1.5)
    G.contour({ -23,-17, -13,-27,12,-26,23,-16,
        29,-4,27,12,18,18, 12,22,8,24,4,25,
        -9,22,-21,16,-24,7, -27,0,-27,-9,-23,-17 },skin,1.6)
    -- Three broad swept peaks and the distinctive central widow's peak.
    G.poly({ -24,1,-28,-17,-24,-26,-21,-22,-11,-34,-12,-28,
        5,-39,16,-29,15,-35,27,-21,27,-4,22,-12,
        14,-16,7,-17,3,-8,-2,-12,-5,-19,-16,-15,-21,-9 },hair,1.5)
    G.contour({ -22,-12, -13,-11,-1,-3,5,3,
        0,13,-12,17,-19,9, -23,4,-24,-6,-22,-12 },hair,1.1)
    G.contour({ 24,-12, 27,-4,26,5,22,10,
        15,16,8,11,5,3, 10,-3,18,-9,24,-12 },hair,1.1)
    G.contour({ -19,-8, -13,-5,-4,0,1,4,
        -4,12,-13,12,-17,7, -20,3,-20,-4,-19,-8 },G.WHITE)
    G.contour({ 22,-8, 24,-1,22,6,19,8,
        14,11,10,8,8,4, 12,-1,18,-5,22,-8 },G.WHITE)
    if hurt then G.line(-17,2,-3,5,2,hair); G.line(11,4,22,0,1.8,hair) end
    G.contour({ 1,17, 6,19,11,19,16,15,
        12,19,6,21,1,17 },hair)
    G.restore()
end

function F.cyborg(x: number, y: number, hurt: boolean)
    G.save(); G.translate(x,y)
    -- Match the menu head's width and crown-to-chin height in the turned view.
    G.scale(.93,.93)
    local skin, metal = H(0xA86858), H(0xF1F4FA)
    -- A flat crown and strong jaw, rather than a circular baby face.
    G.contour({ -21,-21, -10,-25,9,-23,21,-17,
        27,-8,28,11,19,23, 10,29,-6,27,-17,19,
        -24,9,-27,-10,-21,-21 },skin,1.7)
    G.oellipse(-23,-2,4.5,6,skin,1.3)
    G.contour({ 9,-22, 18,-20,23,-17,24,-11,
        29,2,27,15,19,23, 15,26,12,26,10,26,
        16,11,13,-7,9,-22 },metal,1.3)
    G.poly({ 12,-18,21,-15,23,-8,13,-9 },H(0x91EEF1),.8)
    G.oellipse(-6,-3,6.4,6.8,G.WHITE,1.1)
    G.ellipse(-3.5,-2,2,3.7,I)
    G.poly({ -14,-11,-7,-15,3,-8,2,-5,-6,-9,-13,-7 },I)
    G.poly({ 12,-6,26,-5,26,2,13,2 },I,1)
    G.contour({ 15,0, 19,0,22,0,24,0,
        25,9,15,10,15,0 },H(0xE80050),.7)
    G.polyline({ 4,0,9,7,5,8,1,6 },1.1,I)
    if hurt then G.line(-9,15,14,16,1.5,I)
    else G.contour({ -13,10, -4,16,8,18,19,12,
        9,19,-2,20,-13,10 },I) end
    G.contour({ 1,24, 3,21,8,21,11,24,
        12,26,12,27,11,28, 7,29,3,28,0,27,
        0,26,0,25,1,24 },metal,1)
    G.restore()
end

function F.beast(x: number, y: number, hurt: boolean)
    G.save(); G.translate(x,y)
    local skin,hair = H(0xA2E84A),H(0x487A53)
    -- Long pointed ears frame a wide, short face and a swept fringe.
    G.contour({ 20,-3, 24,-13,30,-17,34,-20,
        31,-11,29,-4,31,3, 31,8,25,11,21,8,
        19,5,18,0,20,-3 },skin,1.4)
    G.contour({ -23,-15, -12,-23,12,-23,23,-14,
        27,-5,27,9,21,15, 12,22,-8,23,-19,19,
        -25,14,-27,-5,-23,-15 },skin,1.6)
    G.contour({ -22,1, -27,-9,-33,-14,-38,-15,
        -30,-4,-34,6,-28,10, -24,13,-21,9,-20,6,
        -19,4,-21,3,-22,1 },skin,1.4)
    G.polyline({ -32,-6,-27,-1,-27,6 },1,H(0x64AA34))
    G.poly({ -24,-1,-24,-14,-32,-9,-27,-20,-37,-15,
        -27,-28,-14,-28,4,-27,18,-29,20,-34,23,-27,28,-26,
        22,-22,25,-13,23,-3,17,-17,5,-19,-6,-10,-5,-19,-18,-10,-16,-19 },hair,1.3)
    G.contour({ -18,-5, -11,-6,-4,-4,2,-2,
        3,12,-14,13,-17,5, -18,2,-18,-1,-18,-5 },G.WHITE,1)
    G.contour({ 8,-2, 13,-5,19,-7,24,-7,
        26,5,19,11,13,9, 9,7,8,2,8,-2 },G.WHITE,1)
    G.ellipse(-4,3,2.3,4,I); G.ellipse(19,2,2.1,3.9,I)
    G.poly({ -19,-8,2,-4,2,0,-18,-1 },hair)
    G.poly({ 8,-4,24,-11,25,-6,10,2 },hair)
    G.polyline({ 3,6,5,7,7,6 },1,I)
    if hurt then G.line(-9,16,16,16,1.3,I)
    else
        G.contour({ -14,13, -4,18,12,17,22,10,
            15,20,-3,23,-14,13 },G.WHITE,1.1)
        G.poly({ 13,15,17,13,16,18 },skin,.6)
    end
    G.restore()
end

function F.raven(x: number, y: number, hurt: boolean)
    G.save(); G.translate(x,y)
    -- Keep the hood-to-cloak ratio from the menu model.
    G.scale(.92,.95)
    local cloak = H(0x4838A0)
    -- The hood hides the forehead; black shadow surrounds the eyes.
    G.contour({ -30,4, -30,-16,-21,-29,-7,-30,
        6,-34,22,-30,26,-20, 29,-9,26,8,31,17,
        18,28,-5,31,-21,19, -27,15,-31,10,-34,5,
        -32,5,-31,5,-30,4 },cloak,1.7)
    G.contour({ -25,5, -21,-6,-13,-16,-5,-20,
        2,-14,7,-6,10,-1, 16,-5,20,-13,22,-18,
        25,-5,23,9,26,16, 17,25,-1,26,-15,19,
        -21,15,-24,10,-25,5 },I,1)
    G.contour({ -14,16, -7,11,-2,9,3,10,
        9,12,13,17,15,22, 4,27,-8,25,-14,16 },H(0xD0C8C8))
    if hurt then G.line(-17,2,-4,7,1.7,G.WHITE); G.line(9,8,21,3,1.7,G.WHITE)
    else
        G.contour({ -19,-1, -13,3,-5,5,1,6,
            -2,16,-14,16,-19,-1 },G.WHITE)
        G.contour({ 8,7, 13,7,19,3,23,1,
            24,13,11,17,8,7 },G.WHITE)
        G.ellipse(-5,7,2.5,3.5,H(0x9B6BD6)); G.ellipse(-4.3,6.7,1.2,2.6,I)
        G.ellipse(18,8,2.1,3.2,H(0x9B6BD6)); G.ellipse(18.6,7.7,1.1,2.4,I)
    end
    G.polyline({ 0,18,5,17,9,18 },1.1,I)
    G.restore()
end

function F.starfireHair(x: number,y: number,t: number,walk: number)
    G.save(); G.translate(x,y)
    local flow=math.clamp(walk,0,2)
    local trail=flow*27+math.sin(t*5-1)*3
    local lift=flow*17
    G.contour({ -23,-16, -29,-3,-29-trail*.4,26-lift*.3,-29-trail,47-lift,
        -35-trail,56-lift,-35-trail,68-lift,-32-trail,73-lift,
        -23-trail,67-lift,-18-trail*.7,58-lift,-15-trail*.7,55-lift,
        -12-trail*.6,69-lift,1-trail*.8,81-lift,14-trail*.8,76-lift,
        9-trail*.6,77-lift,7-trail*.6,70-lift,9-trail*.5,66-lift,
        24-trail*.4,64-lift,28,52-lift*.5,27,43-lift*.4,
        24,24,26,0,22,-17, 13,-28,-12,-27,-23,-16 },H(0xE00078),1.6)
    G.polyline({ -22,8,-23-trail*.6,36-lift*.5,-29-trail,59-lift },2,H(0xB00060))
    G.polyline({ 20,20,16-trail*.4,48-lift*.4,3-trail*.7,67-lift },1.5,H(0xFF469B))
    G.restore()
end

function F.starfire(x: number,y: number,hurt: boolean)
    G.save(); G.translate(x,y)
    local skin,hair = H(0xFFBD79),H(0xE00078)
    G.contour({ -23,-14, -15,-26,12,-26,23,-15,
        30,0,26,14,16,20, 12,23,7,25,3,26,
        -11,24,-25,14,-25,1, -26,-5,-26,-10,-23,-14 },skin,1.6)
    local function eye(ex: number,ey: number,rx: number,lash: number)
        G.oellipse(ex,ey,rx,10,H(0xC7FF77),.9)
        G.ellipse(ex+1.8,ey-1,rx*.38,6.1,H(0x185B25))
        G.ellipse(ex+.4,ey-4.2,1.7,2.3,G.WHITE)
        G.polyline({ ex-rx,ey-3,ex-rx*.6,ey-8,ex,ey-10,ex+rx*.6,ey-8,ex+rx,ey-3 },2,I)
        G.line(ex+lash*rx*.65,ey-7,ex+lash*(rx+3),ey-12,2,I)
    end
    eye(-9,1,8.8,-1); eye(15,0,7.6,1)
    G.ellipse(-8,-13,3.4,1.7,hair); G.ellipse(15,-14,2.8,1.5,hair)
    G.polyline({ 3,9,5,7,7,9 },1,I)
    -- Two rounded bangs make the heart-shaped hairline.
    G.contour({ -24,3, -28,-9,-27,-25,-15,-28,
        -5,-31,1,-27,5,-23, 12,-30,23,-28,27,-22,
        29,-15,24,-9,21,-10, 24,-16,20,-22,14,-22,
        10,-22,7,-18,5,-17, -1,-22,-7,-25,-14,-22,
        -22,-18,-18,-10,-24,3 },hair,1.4)
    G.oellipse(-24,5,3.5,5.2,skin,1.2)
    if hurt then G.oellipse(7,18,2.6,2,H(0x5E1426),.8)
    else G.contour({ -2,18, 3,20,11,20,16,16,
        11,21,4,22,-2,18 },I) end
    G.restore()
end
return F
