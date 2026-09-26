-- Shared ability contracts: energy costs, windows, names and area dimensions.
local P = {}
export type Power = { name: string, cost: number, duration: number, first: number, last: number,
    reach: number, depth: number, damage: number, launch: number }
local function power(name: string, cost: number, duration: number, first: number, last: number, reach: number, depth: number, damage: number, launch: number): Power
    return { name = name, cost = cost, duration = duration, first = first, last = last,
        reach = reach, depth = depth, damage = damage, launch = launch }
end
P.secondary = {
    robin = power('STAFF CYCLONE', 40, .85, .16, .62, 150, 65, 25, 340),
    cyborg = power('SEISMIC SLAM', 40, .95, .38, .62, 210, 80, 30, 440),
    starfire = power('COMET RUSH', 40, .85, .16, .65, 100, 38, 26, 380),
    raven = power('SHADOW GRASP', 40, .90, .28, .62, 300, 55, 18, 0),
    beast = power('GORILLA SMASH', 40, 1.0, .40, .68, 220, 85, 32, 460),
} :: { [string]: Power }
P.ultimate = {
    robin = power('BIRDARANG STORM', 100, 1.35, .25, .95, 1000, 90, 14, 380),
    cyborg = power('MEGA SONIC CANNON', 100, 1.65, .45, 1.30, 1150, 80, 16, 460),
    starfire = power('STAR NOVA', 100, 1.55, .65, 1.08, 430, 170, 72, 520),
    raven = power('SOUL SELF', 100, 1.65, .50, 1.24, 650, 115, 68, 520),
    beast = power('T-REX RAMPAGE', 100, 2.05, .40, 1.70, 165, 75, 62, 520),
} :: { [string]: Power }
function P.get(kind: string, ultimate: boolean): Power
    return (if ultimate then P.ultimate else P.secondary)[kind]
end
return P
