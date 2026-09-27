-- Campaign roster and authored encounters, shared by gameplay and regression tests.
local C = {}
export type EnemyDef = {
    name: string, hp: number, speed: number, scale: number, radius: number,
    reach: number, dmg: number, windup: number, score: number,
    behavior: string, boss: boolean,
}
C.enemies = {
    bot = { name = 'SLADE BOT', hp = 42, speed = 150, scale = 1.35, radius = 26, reach = 76, dmg = 8, windup = .38, score = 300, behavior = 'melee', boss = false },
    heavy = { name = 'HEAVY BOT', hp = 100, speed = 105, scale = 1.5, radius = 38, reach = 104, dmg = 15, windup = .55, score = 800, behavior = 'melee', boss = false },
    runner = { name = 'RAZOR BOT', hp = 32, speed = 245, scale = 1.2, radius = 23, reach = 82, dmg = 7, windup = .27, score = 450, behavior = 'rush', boss = false },
    gunner = { name = 'BLASTER BOT', hp = 46, speed = 135, scale = 1.3, radius = 26, reach = 420, dmg = 9, windup = .7, score = 600, behavior = 'ranged', boss = false },
    shield = { name = 'GUARD BOT', hp = 90, speed = 95, scale = 1.45, radius = 34, reach = 96, dmg = 12, windup = .6, score = 750, behavior = 'guard', boss = false },
    shock = { name = 'SHOCK BOT', hp = 68, speed = 140, scale = 1.35, radius = 28, reach = 130, dmg = 11, windup = .8, score = 700, behavior = 'shock', boss = false },
    boss = { name = 'CINDERBLOCK', hp = 560, speed = 125, scale = 1.9, radius = 70, reach = 170, dmg = 20, windup = .55, score = 5000, behavior = 'golem', boss = true },
    mammoth = { name = 'MAMMOTH', hp = 650, speed = 145, scale = 2, radius = 57, reach = 145, dmg = 21, windup = .65, score = 6500, behavior = 'brute', boss = true },
    jinx = { name = 'JINX', hp = 530, speed = 185, scale = 1.65, radius = 30, reach = 450, dmg = 12, windup = .85, score = 7500, behavior = 'hex', boss = true },
    slade = { name = 'SLADE', hp = 820, speed = 205, scale = 1.65, radius = 34, reach = 125, dmg = 18, windup = .4, score = 10000, behavior = 'master', boss = true },
    modbot = { name = 'MOD ROBOT', hp = 65, speed = 165, scale = 1.4, radius = 28, reach = 95, dmg = 11, windup = 0.6, score = 800, behavior = 'rush', boss = false },
    hive = { name = 'HIVE CADET', hp = 85, speed = 160, scale = 1.45, radius = 30, reach = 390, dmg = 12, windup = 0.8, score = 950, behavior = 'ranged', boss = false },
    gordanian = { name = 'GORDANIAN', hp = 125, speed = 130, scale = 1.65, radius = 40, reach = 115, dmg = 15, windup = 0.65, score = 1100, behavior = 'guard', boss = false },
    demon = { name = 'FIRE DEMON', hp = 80, speed = 205, scale = 1.55, radius = 28, reach = 135, dmg = 14, windup = 0.85, score = 1200, behavior = 'shock', boss = false },
    madmod = { name = 'MAD MOD', hp = 900, speed = 175, scale = 1.7, radius = 32, reach = 440, dmg = 14, windup = 1, score = 12000, behavior = 'hex', boss = true },
    blood = { name = 'BROTHER BLOOD', hp = 1100, speed = 180, scale = 1.85, radius = 38, reach = 135, dmg = 19, windup = 0.65, score = 14000, behavior = 'master', boss = true },
    blackfire = { name = 'BLACKFIRE', hp = 1250, speed = 195, scale = 1.8, radius = 32, reach = 460, dmg = 17, windup = 0.9, score = 16000, behavior = 'hex', boss = true },
    trigon = { name = 'TRIGON', hp = 2400, speed = 55, scale = 1, radius = 145, reach = 260, dmg = 24, windup = 1.25, score = 30000, behavior = 'titan', boss = true },
} :: { [string]: EnemyDef }
export type Spawn = { kind: string, delay: number, side: number }
export type Checkpoint = { x: number, spawns: { Spawn }, pizza: boolean, boss: boolean, stage: number, wave: number }
C.stages = {
    { name = 'JUMP CITY', subtitle = 'STREET SWEEP', theme = 'city' },
    { name = 'IRON DOCKS', subtitle = 'BREAK THE BLOCKADE', theme = 'docks' },
    { name = 'HEX FOUNDRY', subtitle = 'SHUT DOWN THE MACHINES', theme = 'foundry' },
    { name = 'SLADE HQ', subtitle = 'ROOFTOP SHOWDOWN', theme = 'rooftop' },
    { name = 'MAD MOD SCHOOL', subtitle = 'ESCAPE THE ILLUSION', theme = 'school' },
    { name = 'HIVE ACADEMY', subtitle = 'BREAK BLOODS CONTROL', theme = 'academy' },
    { name = 'TAMARAN', subtitle = 'CHALLENGE THE THRONE', theme = 'tamaran' },
    { name = 'TRIGONS EARTH', subtitle = 'THE END', theme = 'inferno' },
}
local function wave(list: { string }, gap: number): { Spawn }
    local out: { Spawn } = {}
    for i, kind in list do
        table.insert(out, { kind = kind, delay = (i - 1) * gap, side = if i % 2 == 0 then -1 else 1 })
    end
    return out
end
local encounters = {
    { 'bot', 'bot', 'runner', 'bot', 'runner' },
    { 'bot', 'runner', 'heavy', 'bot', 'runner', 'bot' },
    { 'heavy', 'bot', 'gunner', 'runner', 'bot', 'heavy', 'bot' },
    { 'boss', 'bot', 'runner', 'bot', 'gunner' },
    { 'shield', 'bot', 'gunner', 'runner', 'shield', 'bot', 'gunner' },
    { 'gunner', 'runner', 'heavy', 'shield', 'runner', 'bot', 'gunner', 'bot' },
    { 'heavy', 'shield', 'gunner', 'runner', 'heavy', 'runner', 'shield', 'gunner' },
    { 'mammoth', 'runner', 'shield', 'runner', 'gunner', 'bot' },
    { 'shock', 'bot', 'runner', 'gunner', 'shock', 'shield', 'bot', 'runner' },
    { 'shield', 'shock', 'gunner', 'heavy', 'runner', 'shock', 'bot', 'gunner' },
    { 'shock', 'heavy', 'runner', 'shield', 'gunner', 'shock', 'heavy', 'runner', 'bot' },
    { 'jinx', 'shock', 'runner', 'shield', 'shock', 'gunner' },
    { 'runner', 'shield', 'gunner', 'shock', 'heavy', 'runner', 'gunner', 'shield', 'bot' },
    { 'heavy', 'runner', 'shock', 'gunner', 'shield', 'runner', 'heavy', 'shock', 'gunner' },
    { 'shield', 'gunner', 'runner', 'shock', 'heavy', 'gunner', 'runner', 'shield', 'shock', 'heavy' },
    { 'slade', 'runner', 'shield', 'gunner', 'shock', 'heavy', 'runner', 'gunner' },
    { 'modbot', 'runner', 'modbot', 'modbot', 'runner', 'modbot' },
    { 'modbot', 'runner', 'modbot', 'modbot', 'runner', 'modbot', 'modbot' },
    { 'modbot', 'runner', 'modbot', 'modbot', 'runner', 'modbot', 'modbot', 'modbot' },
    { 'madmod', 'modbot', 'modbot', 'runner', 'modbot' },
    { 'hive', 'shock', 'hive', 'hive', 'shock', 'hive' },
    { 'hive', 'shock', 'hive', 'hive', 'shock', 'hive', 'hive' },
    { 'hive', 'shock', 'hive', 'hive', 'shock', 'hive', 'hive', 'hive' },
    { 'blood', 'hive', 'hive', 'shock', 'hive' },
    { 'gordanian', 'hive', 'gordanian', 'gordanian', 'hive', 'gordanian' },
    { 'gordanian', 'hive', 'gordanian', 'gordanian', 'hive', 'gordanian', 'gordanian' },
    { 'gordanian', 'hive', 'gordanian', 'gordanian', 'hive', 'gordanian', 'gordanian', 'gordanian' },
    { 'blackfire', 'gordanian', 'gordanian', 'hive', 'gordanian' },
    { 'demon', 'gordanian', 'demon', 'demon', 'gordanian', 'demon' },
    { 'demon', 'gordanian', 'demon', 'demon', 'gordanian', 'demon', 'demon' },
    { 'demon', 'gordanian', 'demon', 'demon', 'gordanian', 'demon', 'demon', 'demon' },
    { 'trigon', 'demon', 'demon', 'gordanian', 'demon' },
}
C.checkpoints = {} :: { Checkpoint }
for i, list in encounters do
    local boss = i % 4 == 0
    table.insert(C.checkpoints, {
        x = 260 + (i - 1) * 1000, spawns = wave(list, if boss then 2.8 else .95),
        pizza = i > 1, boss = boss, stage = math.ceil(i / 4), wave = (i - 1) % 4 + 1,
    })
end
function C.isBoss(kind: string): boolean
    local def = C.enemies[kind]
    return def ~= nil and def.boss
end
-- Co-op tuning lives here so every spawn and drop-in uses the same rules.
function C.healthFor(kind: string, players: number): number
    local def = C.enemies[kind]
    local extra = math.clamp(players, 1, 4) - 1
    return math.floor(def.hp * (1 + extra * (if def.boss then .60 else .25)) + .5)
end

function C.extraEnemies(cp: Checkpoint, players: number): number
    local regulars = 0
    for _, sp in cp.spawns do
        if not C.isBoss(sp.kind) then regulars += 1 end
    end
    return math.floor(regulars * .5 * (math.clamp(players, 1, 4) - 1) + .5)
end
return C
