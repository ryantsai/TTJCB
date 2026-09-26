-- Normal-combo contracts shared by combat, animation and review tooling.
local A = {}
export type Strike = { name: string, duration: number, first: number, last: number,
    reach: number, depth: number, damage: number, knockback: number, launch: number, lunge: number }
local function hit(name: string, duration: number, first: number, last: number, reach: number, depth: number, damage: number, knockback: number, launch: number, lunge: number): Strike
    return { name = name, duration = duration, first = first, last = last, reach = reach,
        depth = depth, damage = damage, knockback = knockback, launch = launch, lunge = lunge }
end
A.combos = {
    robin = { hit('STAFF THRUST', .30, .08, .15, 100, 22, 7, 60, 0, 65),
        hit('STAFF SWEEP', .36, .10, .21, 105, 40, 8, 80, 0, 45),
        hit('OVERHEAD STAFF', .46, .17, .25, 108, 30, 15, 330, 290, 90) },
    cyborg = { hit('BODY BLOW', .38, .12, .20, 84, 26, 10, 70, 0, 70),
        hit('UPPERCUT', .44, .15, .24, 78, 26, 11, 90, 0, 45),
        hit('HAMMER FISTS', .58, .23, .34, 94, 42, 20, 400, 230, 100) },
    starfire = { hit('STAR PALM', .28, .07, .14, 87, 24, 7, 50, 0, 30),
        hit('RISING PALM', .32, .09, .17, 90, 28, 8, 70, 0, 35),
        hit('DOUBLE STAR BURST', .44, .15, .25, 116, 38, 14, 360, 390, 45) },
    raven = { hit('SHADOW LASH', .34, .11, .19, 106, 22, 7, 40, 0, 10),
        hit('RISING SHADOW', .39, .13, .22, 102, 34, 9, 65, 0, 10),
        hit('DARK PALM', .52, .20, .31, 120, 36, 16, 300, 460, 20) },
    beast = { hit('CLAW RAKE', .23, .06, .12, 69, 30, 6, 35, 0, 100),
        hit('BACK CLAW', .26, .07, .14, 74, 32, 7, 50, 0, 115),
        hit('TWIN CLAW POUNCE', .40, .12, .23, 85, 35, 13, 340, 330, 260) },
} :: { [string]: { Strike } }
function A.get(kind: string, combo: number): Strike
    return (A.combos[kind] or A.combos.robin)[math.clamp(combo, 1, 3)]
end
return A
