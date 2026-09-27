-- Event-driven banter. The private random stream keeps chatter from changing
-- enemy decisions or loot, and selection never repeats the previous variant.
local R = {}
R.lines = require('remarks_catalog')
R.bossLines = require('boss_remarks')
R.priority = { encounter=1, victory=1, heal=2, hurt=2, special=3, secondary=3, ultimate=4, low_health=5, down=6 } :: { [string]: number }

export type Voice = {
    text: string, event: string, time: number, life: number, age: number,
    cooldown: number, priority: number, last: { [string]: number }, rng: number,
    seenWave: number, danger: boolean,
}

function R.new(seed: number): Voice
    return { text='', event='', time=0, life=0, age=0, cooldown=0, priority=0,
        last={}, rng=(math.floor(seed)*48271)%2147483646+1, seenWave=0, danger=false }
end

local function random(v: Voice): number
    v.rng = (v.rng * 16807) % 2147483647
    return v.rng / 2147483647
end

function R.update(v: Voice, dt: number)
    v.time = math.max(0, v.time-dt)
    v.cooldown = math.max(0, v.cooldown-dt)
    v.age += dt
end

function R.offer(v: Voice, kind: string, event: string): boolean
    local bank = R.lines[kind] or R.bossLines[kind]
    local lines = if bank then bank[event] else nil
    local priority = R.priority[event] or 0
    if not lines or #lines==0 then return false end
    local resolved = (event=='heal' and v.event=='low_health') or (event=='victory' and v.event=='encounter')
    if v.cooldown>0 and priority<=v.priority and not resolved then return false end
    -- Give an existing line time to register before another move replaces it;
    -- urgent health/KO reactions can always interrupt lesser chatter.
    if v.time>0 and v.age<.65 and priority<5 and not resolved then return false end
    local previous = v.last[event]
    local index = math.floor(random(v)*(if previous then #lines-1 else #lines))+1
    if previous and index>=previous then index+=1 end
    if lines[index][1]==v.text and #lines>1 then
        index=index%#lines+1
        if index==previous then index=index%#lines+1 end
    end
    local text = lines[index][1]
    v.last[event], v.text, v.event = index, text, event
    v.life = math.clamp(2.1 + #text*.026, 2.4, 3.3)
    v.time, v.age, v.priority = v.life, 0, priority
    v.cooldown = if event=='encounter' or event=='victory' then 6 elseif event=='hurt' then 4.5 else 3.6
    return true
end

return R
