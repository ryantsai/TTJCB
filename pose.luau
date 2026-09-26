-- The animation state art needs to draw a fighter, shared by art and heroes.
local P = {}

export type Pose = {
    t: number, -- animation clock (s)
    walk: number, -- 0..1 walk blend
    phase: number, -- walk cycle (radians)
    air: boolean,
    move: number, -- 0 none, 1 jab, 2 cross, 3 kick, 4 flying kick, 5 special, 6 enemy punch, 7 boss slam
    ext: number, -- limb extension, -1 (wind-up) .. 1 (full reach)
    hurt: boolean,
    down: number, -- 0..1, lying on the ground
    ko: boolean,
    flip: number, -- -1 when the figure is mirrored, so lettering can un-mirror
}

function P.new(): Pose
    return { t = 0, walk = 0, phase = 0, air = false, move = 0, ext = 0, hurt = false, down = 0, ko = false, flip = 1 }
end

return P
