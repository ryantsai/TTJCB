-- The animation state art needs to draw a fighter, shared by art and heroes.
local P = {}

export type Pose = {
    t: number, -- animation clock (s)
    dash: number, -- 0..1 sprint lean and dash-strike momentum
    walk: number, -- 0..1 walk blend
    phase: number, -- walk cycle (radians)
    air: boolean,
    rise: number, -- vertical velocity / launch velocity, positive while rising
    airTime: number, -- continuous airborne clock, independent of attack state
    launch: number, -- takeoff crouch, 0..1
    land: number, -- landing compression, 1..0
    speed: number, -- planar speed / run speed
    settle: number, -- strike recovery, 0..1
    move: number, -- 0 none, 1/2/3 hero normal combo, 4 flying kick, 5 special, 6 enemy punch, 7 boss slam, 8 secondary, 9 ultimate
    powerTime: number, -- elapsed time of the current ability
    style: string, -- hero-specific normal-combo choreography
    windup: number, -- preparation lift, released before impact
    stroke: number, -- progress through the active part of a strike
    active: boolean, -- combat hit window; gates normal attack effects
    ext: number, -- limb extension, -1 (wind-up) .. 1 (full reach)
    hurt: boolean,
    down: number, -- 0..1, lying on the ground
    ko: boolean,
    flip: number, -- -1 when the figure is mirrored, so lettering can un-mirror
}

function P.new(): Pose
    return { t = 0, dash = 0, walk = 0, phase = 0, air = false, rise = 0, airTime = 0, launch = 0, land = 0, speed = 0, settle = 0, move = 0, powerTime = 0, style = '', windup = 0, stroke = 0, active = false, ext = 0, hurt = false, down = 0, ko = false, flip = 1 }
end

return P
