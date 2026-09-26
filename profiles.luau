-- Right-facing gameplay heads. Portraits keep their separate frontal artwork.
-- Every nose, eye line and hair silhouette is authored toward local +x.
local G = require('gfx')
local H = G.hex
local I = G.INK
local F = {}

function F.robin(x: number, y: number, hurt: boolean)
    G.save()
    G.translate(x, y)
    local skin, hair = H(0xF7BEA5), H(0x0A0A12)
    G.contour({ -20, -18,
        -7, -27, 17, -24, 22, -12,
        25, -5, 23, -2, 30, 3,
        32, 5, 26, 7, 24, 7,
        26, 17, 18, 22, 4, 23,
        -14, 22, -27, 2, -20, -18,
    }, skin, 1.8)
    G.poly({ -21, 7, -28, -10, -34, -24, -25, -21,
        -26, -36, -16, -29, -11, -42, -4, -33, 7, -40,
        10, -31, 21, -32, 26, -20, 23, -9, 13, -15,
        5, -11, 2, -17, -9, -11, -14, 6 }, hair, 1.6)
    -- Mask band wraps back to the visible ear; a single eye reads in profile.
    G.poly({ -18, -2, 0, -11, 22, -10, 27, 4, 20, 11,
        7, 12, -1, 6, -17, 4 }, hair, 1.2)
    G.contour({ 1, -7,
        7, -6, 16, -3, 22, 0,
        19, 10, 8, 13, 3, 5,
        1, 2, 0, -3, 1, -7,
    }, G.WHITE)
    G.oellipse(-17, 5, 4.5, 6, skin, 1.4)
    G.polyline({ -18, 2, -15, 3, -17, 7 }, 1, H(0xD98C78))
    if hurt then G.line(4, 2, 20, 3, 2, hair) end
    G.polyline({ 12, 16, 18, 17, 24, 14 }, 1.2, I)
    G.restore()
end

function F.cyborg(x: number, y: number, hurt: boolean)
    G.save()
    G.translate(x, y)
    local skin, metal = H(0xA86858), H(0xCDD2DF)
    G.contour({ -20, -19,
        -10, -27, 14, -24, 22, -16,
        26, -11, 23, -3, 29, 2,
        33, 5, 28, 8, 24, 8,
        26, 17, 22, 23, 8, 25,
        -6, 25, -20, 16, -22, 2,
        -24, -8, -24, -14, -20, -19,
    }, skin, 1.8)
    -- Rear skull plate and temple circuitry follow the turn of the head.
    G.contour({ -20, -19,
        -14, -24, -3, -25, 5, -24,
        2, -15, -2, -9, -7, -4,
        -10, 5, -8, 15, -6, 21,
        -16, 17, -22, 8, -22, 2,
        -24, -8, -24, -14, -20, -19,
    }, metal, 1)
    G.poly({ -18, -19, 1, -22, -3, -12, -17, -9 }, H(0x91EEF1), 0.8)
    G.polyline({ -13, -18, -13, -13, -7, -13 }, 1.1, H(0x3FA8C8))
    G.oellipse(-14, 2, 5, 6, H(0x6E7080), 1.2)
    G.oellipse(-13, 2, 2.7, 3, H(0xE80050), 0.7)
    G.oellipse(12, -3, 6, 6, G.WHITE, 1)
    G.ellipse(15, -2.5, 2.1, 3.6, I)
    G.polyline({ 4, -10, 12, -12, 21, -8 }, 2.6, I)
    if hurt then
        G.line(11, 15, 24, 15, 1.5, I)
    else
        G.contour({ 3, 12, 11, 15, 19, 15, 25, 11,
            22, 22, 9, 23, 3, 12,
        }, G.WHITE, 1)
    end
    G.poly({ 6, 23, 15, 22, 17, 25, 8, 26 }, metal, 0.8)
    G.restore()
end

function F.beast(x: number, y: number, hurt: boolean)
    G.save()
    G.translate(x, y)
    local skin, hair = H(0xA2E84A), H(0x487A53)
    G.contour({ -22, -13,
        -10, -23, 13, -24, 23, -13,
        27, -6, 24, -2, 31, 3,
        35, 6, 29, 9, 25, 9,
        26, 19, 16, 23, 4, 23,
        -17, 23, -29, 7, -22, -13,
    }, skin, 1.7)
    G.poly({ -21, 1, -28, -9, -34, -12, -26, -21, -31, -22,
        -14, -31, -3, -28, 10, -33, 23, -27, 26, -17,
        16, -20, 10, -12, 8, -20, -1, -13, -1, -21,
        -11, -12, -13, 2 }, hair, 1.5)
    G.contour({ -15, -2,
        -22, -4, -29, -9, -34, -15,
        -31, -3, -31, 7, -23, 11,
        -16, 14, -11, 6, -15, -2,
    }, skin, 1.5)
    G.polyline({ -27, -4, -23, 6, -18, 4 }, 1, H(0x64AA34))
    G.oellipse(12, 1, 8, 8, G.WHITE, 1.1)
    G.ellipse(16, 2, 2.3, 4, I)
    G.poly({ 2, -10, 23, -11, 21, -2, 3, 1 }, skin)
    G.line(4, 0, 21, -3, 2, I)
    G.circle(29, 5, 0.9, I)
    if hurt then G.line(9, 15, 23, 14, 1.3, I)
    else
        G.contour({ 0, 12, 10, 17, 20, 14, 26, 10,
            25, 23, 7, 25, 0, 12,
        }, G.WHITE, 1.1)
        G.poly({ 18, 14, 23, 12, 21, 19 }, G.WHITE, 0.6)
    end
    G.restore()
end

function F.raven(x: number, y: number, hurt: boolean)
    G.save()
    G.translate(x, y)
    local cloak, skin = H(0x4838A0), H(0xD0C8C8)
    G.contour({ -29, 10,
        -29, -9, -13, -30, 3, -30,
        18, -32, 23, -23, 28, -15,
        21, -6, 23, 10, 28, 20,
        13, 29, -10, 25, -29, 10,
    }, cloak, 1.8)
    G.contour({ 4, -14,
        13, -20, 20, -18, 25, -14,
        21, -6, 24, -1, 30, 5,
        31, 8, 26, 9, 24, 9,
        26, 18, 19, 23, 11, 23,
        -2, 20, -5, 0, 4, -14,
    }, I, 1)
    G.contour({ 6, 11,
        15, 15, 21, 8, 24, 7,
        28, 9, 25, 14, 24, 16,
        18, 26, 9, 23, 6, 11,
    }, skin)
    if hurt then G.line(5, 4, 23, 6, 2, G.WHITE)
    else
        G.contour({ 1, -1, 9, 3, 17, 4, 24, 1,
            23, 15, 7, 16, 1, -1,
        }, G.WHITE)
        G.ellipse(18, 6, 2.6, 3.7, H(0x9B6BD6))
        G.ellipse(19, 6, 1.3, 2.7, I)
    end
    G.line(17, 18, 24, 17, 1.2, I)
    G.contour({ -29, 10, -23, -1, -12, -14, 4, -23,
        -1, -8, -4, 10, 5, 24,
        -10, 23, -21, 18, -29, 10,
    }, cloak, 1.1)
    G.restore()
end

function F.starfireHair(x: number, y: number, t: number, walk: number)
    G.save()
    G.translate(x, y)
    local trail = walk * 13 + math.sin(t * 2.6) * 2
    G.contour({ -22, -18,
        -35, -8, -29, 20, -41 - trail, 45,
        -49 - trail, 59, -40 - trail, 77, -31 - trail, 80,
        -34 - trail, 69, -27, 65, -24, 62,
        -20, 80, -7, 91, 4, 84,
        -5, 76, -4, 59, -3, 44,
        3, 22, 11, -6, 9, -20,
        1, -30, -14, -28, -22, -18,
    }, H(0xE00078), 1.8)
    G.polyline({ -23, 8, -26 - trail, 42, -29 - trail, 61 }, 1.2, H(0xB00060))
    G.restore()
end

function F.starfire(x: number, y: number, hurt: boolean)
    G.save()
    G.translate(x, y)
    local skin, hair = H(0xFFBD79), H(0xE00078)
    G.contour({ -22, -15,
        -8, -27, 17, -23, 22, -13,
        25, -6, 22, 0, 29, 4,
        32, 7, 27, 9, 24, 9,
        24, 19, 13, 24, 4, 25,
        -13, 25, -29, 6, -22, -15,
    }, skin, 1.7)
    G.oellipse(12, 1, 8.5, 10.5, H(0xC7FF77), 1)
    G.ellipse(15, 1, 4.8, 8, H(0x54C925))
    G.ellipse(17, 0, 2.6, 6, H(0x174C20))
    G.ellipse(13, -3, 1.7, 2.4, G.WHITE)
    G.polyline({ 4, -5, 8, -9, 17, -9, 22, -6, 25, -10 }, 1.8, I)
    G.line(22, -3, 26, -5, 1.5, I)
    G.ellipse(10, -14, 3.2, 1.5, hair)
    G.contour({ -22, 9,
        -29, -3, -29, -24, -15, -28,
        -4, -34, 4, -25, 10, -27,
        20, -30, 26, -24, 25, -16,
        19, -22, 10, -19, 8, -15,
        3, -13, 0, -24, -9, -17,
        -17, -13, -14, 2, -22, 9,
    }, hair, 1.5)
    G.oellipse(-15, 7, 3.4, 5, skin, 1.2)
    if hurt then G.oellipse(19, 17, 2.6, 2, H(0x5E1426), 0.8)
    else G.polyline({ 10, 17, 17, 18, 23, 15 }, 1.2, I) end
    G.restore()
end

return F
