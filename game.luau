-- TEEN TITANS: JUMP CITY BRAWL
-- An unofficial fan-made 2D belt-scrolling beat-'em-up for 1-4 players.
--
-- Controls (standard gamepad layout)
--   Left stick / d-pad  move            A (south)   jump / confirm
--   X (west)            attack combo    B / RB special, Y secondary, RT ultimate
--   Start               join / pause    Back / View  quit (while paused)
-- Keyboard players
--   Keys 1: WASD move, J attack, K / Space jump, L special, I secondary, U ultimate, Enter start, Esc back
--   Keys 2: arrows move, ',' attack, '.' jump, '/' special, Right Shift start,
--           (numpad 1 / 2 / 3 and numpad Enter also work)

local G = require('gfx')
local A = require('art')
local Motion = require('motion')
local Attacks = require('attacks')
local Powers = require('powers')
local Campaign = require('campaign')
local L = require('localization')
local Remarks = require('remarks')
local Speech = require('speech')
local Tutorial = require('tutorial')
local Progress = require('progress')
local LevelMap = require('level_map')
local BrowserInput = require('browser_input')

local W = G.W
local H = G.H
local FMIN = 478 -- nearest the shop fronts a fighter can stand
local FMAX = 698 -- nearest the camera
local GRAV = 1900
local TAKEOFF = .05
local LANDING = .18
local DOUBLE_TAP = .26
local DASH_TIME = .24
local DASH_ATTACK_TIME = .38
local DASH_HIT_START = .045
local DASH_HIT_END = .20
local SPECIAL_COST = 30
local HERO_SCALE = 1.2

-- Data -------------------------------------------------------------------------

type Hero = {
    key: string,
    name: string,
    hp: number,
    speed: number,
    power: number,
    jump: number,
    float: number,
    color: Color,
    special: string,
}

local HEROES: { Hero } = {
    {
        key = 'robin', name = 'ROBIN', hp = 110, speed = 255, power = 1.0, jump = 700, float = 1,
        color = G.hex(0xD7263D), special = 'BIRDARANG',
    },
    {
        key = 'cyborg', name = 'CYBORG', hp = 140, speed = 210, power = 1.25, jump = 640, float = 1,
        color = G.hex(0x2F6FD6), special = 'SONIC CANNON',
    },
    {
        key = 'starfire', name = 'STARFIRE', hp = 100, speed = 245, power = 1.05, jump = 640, float = 0.65,
        color = G.hex(0xF4A259), special = 'STARBOLT VOLLEY',
    },
    {
        key = 'raven', name = 'RAVEN', hp = 95, speed = 235, power = 1.1, jump = 620, float = 0.65,
        color = G.hex(0x6A4CC9), special = 'DARK BURST',
    },
    {
        key = 'beast', name = 'BEAST BOY', hp = 105, speed = 290, power = 0.95, jump = 740, float = 1,
        color = G.hex(0x6DBB45), special = 'RHINO CHARGE',
    },
}

local ENEMIES = Campaign.enemies
local CHECKPOINTS = Campaign.checkpoints
type Spawn = Campaign.Spawn
type Checkpoint = Campaign.Checkpoint
local isBoss = Campaign.isBoss
local SLOT_COLORS: { Color } = { G.hex(0xFF4D5E), G.hex(0x3A9BFF), G.hex(0x3BD16F), G.hex(0xFFC21A) }
local POW_WORDS = { 'POW!', 'BAM!', 'WHAM!', 'KAPOW!', 'THWACK!', 'BOOM!' }

-- Keyboard map: GLFW key codes to (device, button).
type KeyBind = { dev: string, btn: string }
local KEYS: { [number]: KeyBind } = {
    [87] = { dev = 'kb1', btn = 'U' }, [65] = { dev = 'kb1', btn = 'L' },
    [83] = { dev = 'kb1', btn = 'D' }, [68] = { dev = 'kb1', btn = 'R' },
    [74] = { dev = 'kb1', btn = 'x' }, [75] = { dev = 'kb1', btn = 'a' },
    [32] = { dev = 'kb1', btn = 'a' }, [76] = { dev = 'kb1', btn = 'b' },
    [73] = { dev = 'kb1', btn = 'y' }, [85] = { dev = 'kb1', btn = 'rt' },
    [257] = { dev = 'kb1', btn = 'start' }, [256] = { dev = 'kb1', btn = 'cancel' },
    [259] = { dev = 'kb1', btn = 'cancel' },
    [265] = { dev = 'kb2', btn = 'U' }, [263] = { dev = 'kb2', btn = 'L' },
    [264] = { dev = 'kb2', btn = 'D' }, [262] = { dev = 'kb2', btn = 'R' },
    [44] = { dev = 'kb2', btn = 'x' }, [46] = { dev = 'kb2', btn = 'a' },
    [47] = { dev = 'kb2', btn = 'b' }, [321] = { dev = 'kb2', btn = 'x' },
    [322] = { dev = 'kb2', btn = 'a' }, [323] = { dev = 'kb2', btn = 'b' },
    [59] = { dev = 'kb2', btn = 'y' }, [39] = { dev = 'kb2', btn = 'rt' },
    [344] = { dev = 'kb2', btn = 'start' }, [335] = { dev = 'kb2', btn = 'start' },
    [345] = { dev = 'kb2', btn = 'cancel' }, [261] = { dev = 'kb2', btn = 'cancel' },
}

-- State types --------------------------------------------------------------------

type Device = {
    id: string,
    label: string,
    mx: number,
    my: number,
    held: { [string]: boolean },
    pressed: { [string]: boolean },
}

type Fighter = {
    id: number,
    team: number, -- 1 Titans, 2 villains
    kind: string,
    hero: number, -- index into HEROES, 0 for villains
    slot: number, -- player slot, 0 for villains
    x: number,
    y: number,
    z: number,
    vx: number,
    vy: number,
    vz: number,
    facing: number,
    hp: number,
    maxHp: number,
    state: string,
    st: number,
    combo: number,
    queued: boolean,
    hit: { [number]: boolean },
    hitPause: number,
    stepDt: number,
    buffered: { [string]: boolean },
    invuln: number,
    flash: number,
    speed: number,
    power: number,
    jump: number,
    tapDir: string,
    tapTime: number,
    dashX: number,
    dashY: number,
    jumpBuffer: number,
    jumpCut: boolean,
    airTime: number,
    landing: number,
    float: number,
    scale: number,
    radius: number,
    reach: number,
    dmg: number,
    windup: number,
    pose: A.Pose,
    ai: number,
    cd: number,
    armor: number,
    removed: boolean,
    sp: number,
    entering: boolean,
    hitT: number,
    move: number,
    voice: Remarks.Voice,
}

type Slot = {
    idx: number,
    dev: string, -- '' when free
    hero: number,
    locked: boolean,
    fighter: Fighter?,
    lives: number,
    score: number,
    energy: number,
    out: boolean,
    respawn: number,
    color: Color,
    denyT: number,
}

type Shot = {
    kind: string,
    x: number,
    y: number,
    z: number,
    vx: number,
    t: number,
    life: number,
    owner: Fighter,
    dmg: number,
    knock: boolean,
    hit: { [number]: boolean },
    dead: boolean,
    back: boolean,
}

type Fx = {
    kind: string,
    x: number,
    y: number,
    z: number,
    t: number,
    life: number,
    text: string,
    color: Color,
    size: number,
}

type Pickup = { x: number, y: number, t: number, dead: boolean }

type Game = {
    locale: L.Locale,
    languageHover: number,
    mode: string, -- title, tutorial, map, select, play, over, win
    progress: Progress.State,
    selectedLevel: number,
    runLevel: number,
    mapCleared: number,
    resetConfirm: boolean,
    resetYes: boolean,
    tutorialSeen: boolean,
    tutorialReturn: string,
    tutorial: Tutorial.State?,
    demo: Game?,
    menuHover: string,
    stage: number,
    healthPlayers: number,
    wavePlayers: number,
    modeT: number,
    t: number,
    devs: { [string]: Device },
    slots: { Slot },
    fighters: { Fighter },
    shots: { Shot },
    fx: { Fx },
    pickups: { Pickup },
    camX: number,
    lockX: number,
    cp: number,
    pending: { Spawn },
    waveT: number,
    goT: number,
    shake: number,
    paused: boolean,
    nextId: number,
    continueT: number,
    banner: string,
    bannerSub: string,
    bannerT: number,
    selectT: number,
    boss: Fighter?,
}

export type Main = {
    g: Game,
    progressBridge: Progress.Bridge,
    browserGamepads: Property<string>?,
    lastBrowserGamepads: string,
    browserKeyboard: Property<string>?,
    lastBrowserKeySeq: number,
    browserLanguage: Property<string>?,
    languageRevision: Property<number>?,
    browserDevices: {[number]:boolean},
    size: Vector,
    languagePointer: number,
    languageTarget: L.Locale?,
    languageKeyHeld: boolean,
    menuPointer: number,
    menuTarget: string?,
}

-- Helpers ------------------------------------------------------------------------

local function tr(g: Game, source: string): string
    return L.text(g.locale, source)
end

local function uiText(g: Game, source: string, x: number, y: number, size: number, color: Color, align: number?, ink: Color?)
    local value = tr(g, source)
    -- Dense CJK strokes need a larger minimum than the old ASCII stroke face.
    local fontSize = if #value ~= utf8.len(value) then math.max(14, size) else size
    G.text(value, x, y, fontSize, color, align, ink)
end

local function rnd(a: number, b: number): number
    return a + math.random() * (b - a)
end

local function sign(v: number): number
    if v < 0 then
        return -1
    end
    return 1
end

local function newSlot(i: number): Slot
    return {
        idx = i, dev = '', hero = i, locked = false, fighter = nil, lives = 3, score = 0,
        energy = 0, out = false, respawn = 0, color = SLOT_COLORS[i], denyT = 0,
    }
end

local function newGame(): Game
    local slots: { Slot } = {}
    for i = 1, 4 do
        table.insert(slots, newSlot(i))
    end
    return {
        locale = 'en', languageHover = 0,
        progress = Progress.new(), selectedLevel = 1, runLevel = 1, mapCleared = 0,
        resetConfirm = false, resetYes = false,
        tutorialSeen = false, tutorialReturn = 'title', tutorial = nil, demo = nil, menuHover = '',
        mode = 'title', stage = 1, healthPlayers = 1, wavePlayers = 1, modeT = 0, t = 0, devs = {}, slots = slots, fighters = {}, shots = {},
        fx = {}, pickups = {}, camX = 0, lockX = -1, cp = 1, pending = {}, waveT = 0, goT = 0,
        shake = 0, paused = false, nextId = 1, continueT = 0, banner = '',
        bannerSub = '', bannerT = 0, selectT = -1, boss = nil,
    }
end

local function device(g: Game, id: string, label: string): Device
    local d = g.devs[id]
    if d == nil then
        local nd: Device = { id = id, label = label, mx = 0, my = 0, held = {}, pressed = {} }
        g.devs[id] = nd
        -- a controller that comes back (possibly with a new id) reclaims the
        -- player whose controller was unplugged
        if string.sub(id, 1, 3) == 'pad' then
            for _, s in g.slots do
                if string.sub(s.dev, 1, 3) == 'pad' and g.devs[s.dev] == nil then
                    s.dev = id
                    break
                end
            end
        end
        return nd
    end
    return d
end

local function setButton(d: Device, name: string, down: boolean)
    if down and not d.held[name] then
        d.pressed[name] = true
    end
    d.held[name] = down
end

local function pressed(d: Device?, name: string): boolean
    return d ~= nil and d.pressed[name] == true
end

local function slotDevice(g: Game, s: Slot): Device?
    if s.dev == '' then
        return nil
    end
    return g.devs[s.dev]
end

local function slotOf(g: Game, devId: string): Slot?
    for _, s in g.slots do
        if s.dev == devId then
            return s
        end
    end
    return nil
end

local function activeSlots(g: Game): number
    local n = 0
    for _, s in g.slots do
        if s.dev ~= '' and not s.out then
            n += 1
        end
    end
    return n
end

local function addFx(g: Game, kind: string, x: number, y: number, z: number, life: number, text: string, color: Color, size: number)
    table.insert(g.fx, { kind = kind, x = x, y = y, z = z, t = 0, life = life, text = text, color = color, size = size })
end

local function setState(f: Fighter, s: string)
    f.state = s
    f.st = 0
    f.sp = 0
    table.clear(f.hit)
end

local function alive(f: Fighter): boolean
    return not f.removed and f.state ~= 'ko'
end

local function canBeHit(f: Fighter): boolean
    return alive(f) and f.invuln <= 0 and f.state ~= 'down' and f.state ~= 'getup' and f.state ~= 'enter'
end

-- A readable conversation budget in co-op: two speakers at once. Important
-- reactions can displace lesser chatter, but never interrupt an urgent warning.
local function remark(g: Game, f: Fighter, event: string): boolean
    if f.team~=1 or f.removed then return false end
    local active, weakest = 0, nil :: Fighter?
    for _,other in g.fighters do
        if other~=f and other.team==1 and not other.removed and other.voice.time>0 then
            active+=1
            if not weakest or other.voice.priority<weakest.voice.priority then weakest=other end
        end
    end
    local priority=Remarks.priority[event] or 0
    if active>=2 and (not weakest or priority<=weakest.voice.priority) then return false end
    if not Remarks.offer(f.voice,f.kind,event) then return false end
    if active>=2 and weakest then weakest.voice.time=0 end
    return true
end

local function fighterHeight(f: Fighter): number
    local height=if f.kind=='beast' and f.state=='ultimate' then 185
        elseif f.kind=='beast' and f.state=='secondary' then 145
        else A.height(f.kind)
    return height*f.scale
end

-- Fighters -------------------------------------------------------------------------

local function newFighter(g: Game, kind: string, team: number, x: number, y: number): Fighter
    local f: Fighter = {
        id = g.nextId, team = team, kind = kind, hero = 0, slot = 0, x = x, y = y, z = 0,
        vx = 0, vy = 0, vz = 0, facing = 1, hp = 50, maxHp = 50, state = 'idle', st = 0,
        combo = 0, queued = false, hit = {}, invuln = 0, flash = 0, speed = 150, power = 1,
        hitPause = 0, stepDt = 0, buffered = {},
        jump = 600, tapDir = '', tapTime = 0, dashX = 0, dashY = 0, jumpBuffer = 0, jumpCut = false, airTime = 0, landing = 0, float = 1, scale = 1, radius = 22, reach = 64, dmg = 8, windup = 0.35,
        pose = A.newPose(), ai = rnd(0.5, 2), cd = rnd(0.6, 1.6), armor = 0, removed = false,
        sp = 0, entering = false, hitT = 99, move = 0,
        voice = Remarks.new(g.nextId*7919+math.floor(g.t*1000)),
    }
    g.nextId += 1
    local e = ENEMIES[kind]
    if e then
        local n = math.max(1, activeSlots(g))
        f.hp = Campaign.healthFor(kind, n)
        f.maxHp = f.hp
        f.speed = e.speed * rnd(0.9, 1.1)
        f.scale = e.scale
        f.radius = e.radius
        f.reach = e.reach
        f.dmg = e.dmg
        f.windup = e.windup
    end
    table.insert(g.fighters, f)
    return f
end

local function spawnHero(g: Game, s: Slot, x: number, y: number)
    local h = HEROES[s.hero]
    local f = newFighter(g, h.key, 1, x, y)
    f.hero = s.hero
    f.slot = s.idx
    f.hp = h.hp
    f.maxHp = h.hp
    f.speed = h.speed
    f.power = h.power
    f.jump = h.jump
    f.float = h.float
    f.scale = HERO_SCALE * A.modelScale(h.key)
    f.radius = if h.key == 'cyborg' then 34 else 29
    f.reach = if h.key == 'cyborg' then 96 else 86
    f.z = 520 + s.idx * 40
    f.invuln = 2.5
    setState(f, 'enter')
    s.fighter = f
end

-- Combat -----------------------------------------------------------------------------

local function damage(g: Game, att: Fighter, d: Fighter, dmg: number, kbx: number, knock: boolean, launch: number, projectile: boolean?)
    -- A guard blocks frontal light hits; flank, jump over it, or use a knockdown.
    if d.kind == 'shield' and not knock and d.state ~= 'hurt' and d.state ~= 'down'
        and (att.x - d.x) * d.facing > 0 and att.z < 35 then
        dmg *= .3
        addFx(g, 'word', d.x, d.y, 155, .45, 'BLOCK', G.hex(0x66D9FF), 16)
    end
    dmg = math.floor(dmg + 0.5)
    d.hp -= dmg
    d.flash = 0.14
    d.hitT = 0
    if d.team==1 then
        if d.hp<=0 then remark(g,d,'down')
        elseif d.hp<=d.maxHp*.25 and not d.voice.danger then
            if remark(g,d,'low_health') then d.voice.danger=true end
        else remark(g,d,'hurt') end
    end
    local top = A.height(d.kind) * d.scale
    addFx(g, 'spark', d.x - sign(kbx) * d.radius * 0.4, d.y + 1, d.z + top * 0.55, 0.28, '', G.hex(0xFFE14D), 1)
    -- Hit emphasis belongs to the two actors, never the whole co-op simulation.
    -- Keep ranged owners moving when a projectile connects across the street.
    local pause = if knock or d.hp <= 0 then .05 else .025
    d.hitPause = math.max(d.hitPause, pause)
    if not projectile and (att.state == 'attack' or att.state == 'jumpatk'
        or att.state == 'dashatk' or att.state == 'eatk') then
        att.hitPause = math.max(att.hitPause, pause)
    end

    if att.slot > 0 then
        local s = g.slots[att.slot]
        s.score += dmg * 10
        s.energy = math.min(100, s.energy + 4)
    end
    if d.slot > 0 then
        local s = g.slots[d.slot]
        s.energy = math.min(100, s.energy + 3)
    end

    if d.hp <= 0 then
        d.hp = 0
        knock = true
        launch = math.max(launch, 420)
        if d.team == 2 and att.slot > 0 then
            local e = ENEMIES[d.kind]
            if e then
                g.slots[att.slot].score += e.score
            end
        end
    elseif isBoss(d.kind) then
        -- Bosses stagger after sustained damage, with lighter armor on Jinx.
        d.armor += dmg
        if d.armor < (if d.kind == 'jinx' then 40 else 70) then
            return
        end
        d.armor = 0
        knock = false
    elseif d.kind == 'heavy' and not knock and d.state == 'eatk' then
        return -- armoured through its own swing
    end

    if knock then
        setState(d, 'down')
        d.vx = kbx
        d.vy = 0
        d.vz = launch
        d.z = math.max(d.z, 1)
        d.facing = -sign(kbx)
        g.shake = math.max(g.shake, 0.18)
        addFx(g, 'word', d.x, d.y, d.z + top + 10, 0.7, POW_WORDS[math.random(1, #POW_WORDS)], G.hex(0xFFE14D), 30)
    else
        setState(d, 'hurt')
        d.vx = kbx * 0.5
        d.vy = 0
    end
end

-- Hit every opponent inside a box in front of the attacker, once per swing.
local function sweep(g: Game, att: Fighter, reach: number, depth: number, zr: number, dmg: number, kb: number, knock: boolean, launch: number): boolean
    local any = false
    for _, d in g.fighters do
        if d.team ~= att.team and not att.hit[d.id] and canBeHit(d) then
            local dx = (d.x - att.x) * att.facing
            local dy = math.abs(d.y - att.y)
            local dz = math.abs(d.z - att.z)
            if dx > -d.radius * 0.6 and dx < reach + d.radius and dy < depth + d.radius * 0.35 and dz < zr + d.radius then
                att.hit[d.id] = true
                damage(g, att, d, dmg, kb * att.facing, knock, launch)
                any = true
            end
        end
    end
    return any
end

local function startAttack(f: Fighter, combo: number)
    setState(f, 'attack')
    f.combo = combo
    f.queued = false
    f.vx = f.facing * Attacks.get(f.kind, combo).lunge
    f.vy = 0
end

local function startSpecial(g: Game, f: Fighter, s: Slot)
    s.energy -= SPECIAL_COST
    setState(f, 'special')
    f.vx = 0
    f.vy = 0
    f.invuln = math.max(f.invuln, 0.4)
    remark(g,f,'special')
end

local function fireShot(g: Game, f: Fighter, kind: string, speed: number, dmg: number, knock: boolean, life: number)
    local ox, oy = 34, -62
    if f.team == 1 then ox, oy = A.projectileOrigin(f.kind, f.pose) end
    local shot: Shot = {
        kind = kind, x = f.x + f.facing * ox * f.scale, y = f.y, z = f.z - oy * f.scale, vx = speed * f.facing, t = 0,
        life = life, owner = f, dmg = dmg, knock = knock, hit = {}, dead = false, back = false,
    }
    table.insert(g.shots, shot)
end

local function updateSpecial(g: Game, f: Fighter, dt: number, dev: Device?)
    local key = f.kind
    local st = f.st
    local done = 0.5
    if key == 'robin' then
        done = 0.36
        if f.sp == 0 and st >= 0.12 then
            f.sp = 1
            fireShot(g, f, 'bird', 780, 16 * f.power, false, 1.8)
        end
    elseif key == 'cyborg' then
        done = 0.95
        local ticks = { 0.3, 0.45, 0.6, 0.75 }
        while f.sp < #ticks and st >= ticks[f.sp + 1] do
            f.sp += 1
            table.clear(f.hit)
            local last = f.sp == #ticks
            sweep(g, f, 1150, 30, 70, 8 * f.power, if last then 320 else 60, last, 340)
            g.shake = math.max(g.shake, 0.08)
        end
    elseif key == 'starfire' then
        done = 0.5
        local times = { 0.1, 0.22, 0.34 }
        while f.sp < #times and st >= times[f.sp + 1] do
            f.sp += 1
            fireShot(g, f, 'bolt', 840, 11 * f.power, f.sp == #times, 1.3)
        end
    elseif key == 'raven' then
        done = 0.85
        if f.sp == 0 and st >= 0.35 then
            f.sp = 1
            addFx(g, 'dark', f.x, f.y, 0, 0.75, '', G.WHITE, 1)
            g.shake = math.max(g.shake, 0.3)
            for _, d in g.fighters do
                if d.team ~= f.team and canBeHit(d) then
                    local dx = (d.x - f.x) / (250 + d.radius)
                    local dy = (d.y - f.y) / (105 + d.radius * 0.3)
                    if dx * dx + dy * dy < 1 then
                        damage(g, f, d, 24 * f.power, 280 * sign(d.x - f.x), true, 440)
                    end
                end
            end
        end
    elseif key == 'beast' then
        done = 0.8
        f.invuln = math.max(f.invuln, 0.1)
        if st > 0.08 then
            f.vx = f.facing * 660
            f.vy = if dev then dev.my * 140 else 0
            if sweep(g, f, 100, 34, 90, 18 * f.power, 400, true, 400) then
                g.shake = math.max(g.shake, 0.15)
            end
            if math.floor(st * 20) ~= math.floor((st - dt) * 20) then
                addFx(g, 'dust', f.x - f.facing * 40, f.y, 0, 0.4, '', G.WHITE, 1)
            end
        end
    end
    if st >= done then
        f.vx = 0
        f.vy = 0
        setState(f, 'idle')
    end
end

-- Secondary specials and ultimates -------------------------------------------------------
local function radialPower(g: Game, f: Fighter, power: Powers.Power)
    for _, d in g.fighters do
        if d.team ~= f.team and not f.hit[d.id] and canBeHit(d) then
            local dx = (d.x - f.x) / (power.reach + d.radius)
            local dy = (d.y - f.y) / (power.depth + d.radius * .3)
            if dx * dx + dy * dy <= 1 and math.abs(d.z - f.z) < 130 then
                f.hit[d.id] = true
                damage(g, f, d, power.damage * f.power, 340 * (if d.x == f.x then f.facing else sign(d.x - f.x)), true, power.launch)
            end
        end
    end
end

local function requestPower(g: Game, f: Fighter, s: Slot, dev: Device?): boolean
    local ultimate = pressed(dev, 'rt')
    local secondary = pressed(dev, 'y')
    if not ultimate and not secondary and not pressed(dev, 'b') then return false end
    local cost = if ultimate then 100 elseif secondary then 40 else SPECIAL_COST
    if s.energy < cost then
        s.denyT = .5
        return true
    end
    if not ultimate and not secondary then
        startSpecial(g, f, s)
        return true
    end
    local power = Powers.get(f.kind, ultimate)
    s.energy -= power.cost
    setState(f, if ultimate then 'ultimate' else 'secondary')
    f.combo = 0
    f.queued = false
    f.vx, f.vy = 0, 0
    f.invuln = math.max(f.invuln, if ultimate then power.duration else .35)
    remark(g,f,if ultimate then 'ultimate' else 'secondary')
    return true
end

local function updatePower(g: Game, f: Fighter, dt: number)
    local ultimate = f.state == 'ultimate'
    local power = Powers.get(f.kind, ultimate)
    local t = f.st
    local active = t >= power.first and t <= power.last
    if ultimate then
        if f.kind == 'robin' then
            local times = { .25, .55, .85 }
            while f.sp < #times and t >= times[f.sp + 1] do
                f.sp += 1
                for lane = -1, 1 do
                    fireShot(g, f, 'bird', 850, power.damage * f.power, f.sp == 3, 1.6)
                    g.shots[#g.shots].y += lane * 58
                end
            end
        elseif f.kind == 'cyborg' then
            local times = { .45, .65, .85, 1.05, 1.25 }
            while f.sp < #times and t >= times[f.sp + 1] do
                f.sp += 1
                table.clear(f.hit)
                sweep(g, f, power.reach, power.depth, 150, power.damage * f.power, if f.sp == 5 then 450 else 70, f.sp == 5, power.launch)
                g.shake = math.max(g.shake, .13)
            end
        elseif f.kind == 'starfire' then
            if t >= power.first and f.sp == 0 then
                f.sp = 1
                radialPower(g, f, power)
                g.shake = math.max(g.shake, .4)
            end
        elseif f.kind == 'raven' then
            if active then
                local progress = (t - power.first) / (power.last - power.first)
                sweep(g, f, power.reach * (.56 + progress * .44), power.depth, 180, power.damage * f.power, 430, true, power.launch)
            end
        elseif f.kind == 'beast' then
            f.vx = if active then f.facing * 240 else 0
            if active then
                sweep(g, f, power.reach, power.depth, 180, power.damage * f.power, 480, true, power.launch)
                if math.floor(t * 8) ~= math.floor((t - dt) * 8) then
                    addFx(g, 'dust', f.x, f.y, 0, .5, '', G.WHITE, 2)
                    g.shake = math.max(g.shake, .09)
                end
            end
        end
    else
        if f.kind == 'starfire' then
            f.vx = if active then f.facing * 490 else 0
            if active then sweep(g, f, power.reach, power.depth, 100, power.damage * f.power, 360, true, power.launch) end
        elseif f.kind == 'raven' then
            if t >= power.first and f.sp == 0 then
                f.sp = 1
                for _, d in g.fighters do
                    local dx = (d.x - f.x) * f.facing
                    if d.team ~= f.team and canBeHit(d) and dx > 0 and dx < power.reach + d.radius and math.abs(d.y - f.y) < power.depth and d.z < 100 then
                        f.hit[d.id] = true
                        damage(g, f, d, power.damage * f.power, 0, false, 0)
                        d.vx = -f.facing * 440
                        d.vy = (f.y - d.y) * 4
                    end
                end
            end
        elseif active then
            radialPower(g, f, power)
            if f.sp == 0 then
                f.sp = 1
                g.shake = math.max(g.shake, if f.kind == 'robin' then .1 else .25)
            end
        end
    end
    if t >= power.duration then
        f.vx, f.vy = 0, 0
        setState(f, 'idle')
    end
end

-- Players ------------------------------------------------------------------------------

-- Use press edges, so holding a key/stick never repeats a dash. Track taps on
-- the fighter: menu input, other players and respawns cannot prime this gesture.
local function dashDirection(g: Game, f: Fighter, dev: Device?): string
    if not dev or (f.state ~= 'idle' and f.state ~= 'walk') or f.z > 0 then
        f.tapDir = ''
        return ''
    end
    local dir = ''
    if pressed(dev, 'L') and dev.mx < -.2 then dir = 'L'
    elseif pressed(dev, 'R') and dev.mx > .2 then dir = 'R'
    elseif pressed(dev, 'U') and dev.my < -.2 then dir = 'U'
    elseif pressed(dev, 'D') and dev.my > .2 then dir = 'D' end
    if dir == '' then return '' end
    local double = f.tapDir == dir and g.t - f.tapTime <= DOUBLE_TAP
    f.tapDir = if double then '' else dir
    f.tapTime = g.t
    return if double then dir else ''
end

local function dashStrike(g: Game, f: Fighter)
    -- Project into the dash direction so lane dashes hit along their travel too.
    for _, d in g.fighters do
        if d.team ~= f.team and not f.hit[d.id] and canBeHit(d) then
            local dx, dy = d.x - f.x, d.y - f.y
            local along = dx*f.dashX + dy*f.dashY
            local across = math.abs(dx*f.dashY - dy*f.dashX)
            local reach = if f.dashX ~= 0 then f.reach + 28 else 74
            local depth = if f.dashX ~= 0 then 30 else 44
            if along > -d.radius*.6 and along < reach+d.radius
                and across < depth+d.radius*.35 and math.abs(d.z-f.z) < 70+d.radius then
                f.hit[d.id] = true
                damage(g, f, d, 20*f.power, (if f.dashX ~= 0 then f.dashX else f.facing*.25)*340, true, 300)
                if f.dashY ~= 0 and d.state == 'down' then d.vy = f.dashY*210 end
            end
        end
    end
end

local function updatePlayer(g: Game, s: Slot, f: Fighter, dt: number)
    local dev = slotDevice(g, s)
    local mx = if dev then dev.mx else 0
    local my = if dev then dev.my else 0
    local state = f.state
    local dashDir = dashDirection(g, f, dev)

    s.energy = math.min(100, s.energy + dt * 4)
    f.jumpBuffer = math.max(0, f.jumpBuffer-dt)
    if pressed(dev,'a') then f.jumpBuffer=.12 end

    if (state == 'idle' or state == 'walk') and math.abs(mx) > .2 then f.facing = sign(mx) end
    if (state == 'idle' or state == 'walk' or state == 'attack') and requestPower(g, f, s, dev) then return end

    if dashDir ~= '' and f.jumpBuffer <= 0 then
        f.dashX = if dashDir == 'L' then -1 elseif dashDir == 'R' then 1 else 0
        f.dashY = if dashDir == 'U' then -1 elseif dashDir == 'D' then 1 else 0
        if f.dashX ~= 0 then f.facing = f.dashX end
        f.combo, f.queued, f.landing = 0, false, 0
        setState(f, 'dash')
        state = 'dash'
        addFx(g, 'dust', f.x, f.y, 0, .3, '', HEROES[f.hero].color, .9)
    end

    if state == 'dash' or state == 'dashatk' then
        f.jumpBuffer = 0
        if state == 'dash' and f.st < DASH_TIME and pressed(dev, 'x') then
            setState(f, 'dashatk')
            state = 'dashatk'
        end
        local duration = if state == 'dashatk' then DASH_ATTACK_TIME else DASH_TIME
        if f.st >= duration then
            f.vx, f.vy = 0, 0
            setState(f, 'idle')
            return
        end
        local speed = f.speed * (if state == 'dashatk' then 2.3 else 2.8)
        if state == 'dashatk' then
            speed *= 1 - math.clamp((f.st-DASH_HIT_END)/(DASH_ATTACK_TIME-DASH_HIT_END),0,1)
            if f.st >= DASH_HIT_START and f.st <= DASH_HIT_END then dashStrike(g, f) end
        end
        f.vx = f.dashX * speed
        f.vy = f.dashY * speed * .62
    elseif state == 'idle' or state == 'walk' then
        f.vx = mx * f.speed
        f.vy = my * f.speed * 0.62
        if math.abs(mx) > 0.2 then
            f.facing = sign(mx)
        end
        local moving = math.abs(mx) > 0.1 or math.abs(my) > 0.1
        if moving ~= (state == 'walk') then
            f.state = if moving then 'walk' else 'idle'
        end
        if f.jumpBuffer > 0 then
            setState(f, 'takeoff')
            f.jumpBuffer=0
            f.jumpCut=false
            f.airTime=0
            f.landing=0
            f.queued=pressed(dev,'x')
        elseif pressed(dev, 'x') then
            startAttack(f, 1)
        end
    elseif state == 'takeoff' then
        f.vx=mx*f.speed*.7
        f.vy=my*f.speed*.5
        if math.abs(mx)>.2 then f.facing=sign(mx) end
        f.queued=f.queued or pressed(dev,'x')
        if f.st >= TAKEOFF then
            setState(f,if f.queued then 'jumpatk' else 'air')
            f.queued=false
            f.vz=f.jump
            f.z=1
            addFx(g,'launch',f.x,f.y,0,.25,'',HEROES[f.hero].color,if f.kind=='cyborg' then 1.3 else 1)
        end
    elseif state == 'air' or state == 'jumpatk' then
        -- A tap makes a short hop; holding A preserves the full launch arc.
        if not f.jumpCut and (not dev or not dev.held['a']) and f.vz>0 then
            f.vz=math.min(f.vz,f.jump*.68)
            f.jumpCut=true
        end
        f.vx = mx * f.speed * 0.85
        f.vy = my * f.speed * 0.4
        if math.abs(mx) > 0.2 then
            f.facing = sign(mx)
        end
        if state == 'air' and pressed(dev, 'x') then
            setState(f, 'jumpatk')
        end
        if f.state == 'jumpatk' then
            if f.st>=.06 and f.st<=.24 then
                sweep(g, f, f.reach + 10, 30, 90, 13 * f.power, 300, true, 360)
            elseif f.st>=.42 then
                setState(f,'air')
            end
        end
    elseif state == 'attack' then
        local attack = Attacks.get(f.kind, f.combo)
        local dur, a0, a1 = attack.duration, attack.first, attack.last
        f.vx *= math.max(0, 1 - dt * 10)
        if f.st >= a0 and f.st <= a1 then
            local knock = f.combo == 3
            sweep(g, f, attack.reach, attack.depth, 70, attack.damage * f.power, attack.knockback, knock, attack.launch)
        end
        if pressed(dev, 'x') and f.st > 0.06 then
            f.queued = true
        end
        if f.st >= dur then
            if f.queued and f.combo < 3 then
                startAttack(f, f.combo + 1)
            else
                f.combo = 0
                setState(f, 'idle')
            end
        end
    elseif state == 'secondary' or state == 'ultimate' then
        updatePower(g, f, dt)
    elseif state == 'special' then
        updateSpecial(g, f, dt, dev)
    end
end

-- Villains -------------------------------------------------------------------------------

local function nearestHero(g: Game, f: Fighter): Fighter?
    local best: Fighter? = nil
    local bd = math.huge
    for _, h in g.fighters do
        if h.team == 1 and alive(h) and h.state ~= 'enter' then
            local d = math.abs(h.x - f.x) + math.abs(h.y - f.y) * 1.5
            if d < bd then
                bd = d
                best = h
            end
        end
    end
    return best
end

-- How many villains are ahead of `me` in the queue on one side of a target.
local function aheadOnSide(g: Game, target: Fighter, me: Fighter, side: number): number
    local n = 0
    local myD = math.abs(me.x - target.x)
    for _, e in g.fighters do
        if e ~= me and e.team == 2 and alive(e) and not isBoss(e.kind) and sign(e.x - target.x) == side then
            local d = math.abs(e.x - target.x)
            if d < 240 and math.abs(e.y - target.y) < 70 and (d < myD or (d == myD and e.id < me.id)) then
                n += 1
            end
        end
    end
    return n
end

local function updateEnemy(g: Game, f: Fighter, dt: number)
    local state = f.state
    local behavior = ENEMIES[f.kind].behavior
    local ranged = behavior == 'ranged' or behavior == 'hex'
    local tgt = nearestHero(g, f)
    if state == 'idle' or state == 'walk' then
        f.cd -= dt
        f.ai -= dt
        if tgt == nil then
            f.vx = 0
            f.vy = 0
            f.state = 'idle'
            return
        end
        -- Ranged units must enter the arena before choosing a firing distance.
        if f.entering then
            f.vx = sign(g.camX + W/2 - f.x) * f.speed
            f.vy = math.clamp((tgt.y - f.y)*2, -f.speed*.6, f.speed*.6)
            f.facing = sign(f.vx)
            f.state = 'walk'
            return
        end
        local side = sign(f.x - tgt.x)
        local dxT = math.abs(tgt.x - f.x)
        local want = f.reach * 0.75 + tgt.radius * 0.5
        if not ranged and not isBoss(f.kind) and aheadOnSide(g, tgt, f, side) > 0 then
            -- someone already has this side: go round the back, or wait a turn
            if aheadOnSide(g, tgt, f, -side) == 0 then
                side = -side
            else
                want += 150
            end
        end
        local wx = tgt.x + side * want
        local wy = tgt.y + (if isBoss(f.kind) then 0 else math.sin(f.id * 1.7) * 6)
        local dx = wx - f.x
        local dy = wy - f.y
        if f.ai <= 0 then
            f.ai = rnd(1.4, 3)
            if math.random() < 0.22 and not isBoss(f.kind) then
                f.cd = math.max(f.cd, 0.6)
            end
        end
        if f.cd <= 0 and not f.entering and math.abs(tgt.y - f.y) < 40 then
            if ranged and dxT < f.reach + 100 then
                setState(f, 'shoot')
                f.facing = -side
                f.cd = if behavior == 'hex' then 2.4 else 2.8
                f.vx, f.vy = 0, 0
                return
            elseif behavior == 'shock' and dxT < 155 then
                setState(f, 'pulse')
                f.cd = 2.8
                f.vx, f.vy = 0, 0
                return
            elseif behavior == 'master' and dxT > 260 then
                setState(f, 'shoot')
                f.facing = -side
                f.cd = 2.1
                f.vx, f.vy = 0, 0
                return
            elseif behavior == 'rush' and dxT > 160 and dxT < 420 then
                setState(f, 'charge')
                f.facing = -side
                f.cd = 2.6
                return
            end
        end
        if (behavior == 'golem' or behavior == 'brute' or behavior == 'master') and f.cd <= 0 and not f.entering then
            if dxT > (if behavior == 'brute' then 210 else 360) then
                setState(f, 'charge')
                f.facing = -side
                f.cd = rnd(2.2, 3.2)
                return
            elseif dxT < 330 and math.random() < 0.45 then
                setState(f, 'slam')
                f.facing = -side
                f.cd = rnd(2.4, 3.6)
                return
            end
        end
        local inRange = dxT < f.reach + tgt.radius * 0.5 and math.abs(tgt.y - f.y) < 18
        if inRange and f.cd <= 0 and not ranged then
            f.vx = 0
            f.vy = 0
            f.facing = sign(tgt.x - f.x)
            setState(f, 'eatk')
            f.cd = if isBoss(f.kind) then rnd(1.2, 2) else rnd(1.1, 2.3)
        elseif math.abs(dx) < 10 and math.abs(dy) < 8 then
            f.vx = 0
            f.vy = 0
            f.facing = sign(tgt.x - f.x)
            f.state = 'idle'
        else
            f.vx = math.clamp(dx * 4, -f.speed, f.speed)
            f.vy = math.clamp(dy * 4, -f.speed * 0.6, f.speed * 0.6)
            f.facing = if math.abs(dx) > 40 then sign(dx) else sign(tgt.x - f.x)
            f.state = 'walk'
        end
    elseif state == 'shoot' then
        f.vx, f.vy = 0, 0
        if f.st >= f.windup and f.sp == 0 then
            f.sp = 1
            local kind = if behavior == 'hex' then 'hex' elseif behavior == 'master' then 'blade' else 'laser'
            local count = if behavior == 'hex' or behavior == 'master' then 3 else 1
            for i = 1, count do
                fireShot(g, f, kind, if behavior == 'hex' then 360 else 470, f.dmg, false, 3)
                if count > 1 then g.shots[#g.shots].y += (i - 2) * 58 end
            end
        end
        if f.st > f.windup + .65 then setState(f, 'idle') end
    elseif state == 'pulse' then
        f.vx, f.vy = 0, 0
        if f.st >= f.windup and f.sp == 0 then
            f.sp = 1
            addFx(g, 'wave', f.x, f.y, 0, .55, '', G.hex(0x66D9FF), 1)
            for _, d in g.fighters do
                if d.team == 1 and canBeHit(d) and d.z < 30
                    and ((d.x - f.x) / 165)^2 + ((d.y - f.y) / 65)^2 < 1 then
                    damage(g, f, d, f.dmg, sign(d.x - f.x) * 180, false, 0)
                end
            end
        end
        if f.st > f.windup + .6 then setState(f, 'idle') end
    elseif state == 'eatk' then
        f.vx = 0
        f.vy = 0
        local w = f.windup
        if f.st >= w and f.st <= w + 0.12 then
            local knock = isBoss(f.kind) or (f.kind == 'heavy' and f.id % 2 == 0)
            sweep(g, f, f.reach, 24, 70, f.dmg, if knock then 300 else 150, knock, 360)
        end
        if f.st >= w + 0.45 then
            setState(f, 'idle')
        end
    elseif state == 'slam' then
        f.vx = 0
        f.vy = 0
        if f.sp == 0 and f.st >= 0.65 then
            f.sp = 1
            g.shake = math.max(g.shake, 0.5)
            local cx = f.x + f.facing * 80
            addFx(g, 'wave', cx, f.y, 0, 0.7, '', G.WHITE, 1)
            for _, d in g.fighters do
                if d.team == 1 and canBeHit(d) and d.z < 20 then
                    local dx = (d.x - cx) / 250
                    local dy = (d.y - f.y) / 100
                    if dx * dx + dy * dy < 1 then
                        damage(g, f, d, 16, 300 * sign(d.x - cx), true, 420)
                    end
                end
            end
        end
        if f.st >= 1.25 then
            setState(f, 'idle')
        end
    elseif state == 'charge' then
        if f.st < 0.45 then
            f.vx = 0
            f.vy = 0
        else
            f.vx = f.facing * (if behavior == 'rush' then 620 else 540)
            if tgt then
                f.vy = math.clamp((tgt.y - f.y) * 2, -80, 80)
            end
            sweep(g, f, 70, 30, 80, f.dmg, 300, behavior ~= 'rush', 420)
            if math.floor(f.st * 12) ~= math.floor((f.st - dt) * 12) then
                addFx(g, 'dust', f.x - f.facing * 60, f.y, 0, 0.45, '', G.WHITE, 1.6)
            end
            local edge = (f.facing > 0 and f.x > g.camX + W - 90) or (f.facing < 0 and f.x < g.camX + 90)
            if f.st > (if behavior == 'rush' then .95 else 1.7) or edge then
                g.shake = math.max(g.shake, 0.2)
                setState(f, 'idle')
                f.vx = 0
                f.vy = 0
            end
        end
    end
end

-- Shots ------------------------------------------------------------------------------------

local function updateShots(g: Game, dt: number)
    for _, s in g.shots do
        s.t += dt
        if s.kind == 'bird' then
            if not s.back and s.t > 0.42 then
                s.back = true
                table.clear(s.hit)
            end
            if s.back then
                local o = s.owner
                local ox, oy = A.projectileOrigin(o.kind, o.pose)
                local dx = o.x + o.facing * ox * o.scale - s.x
                s.vx = sign(dx) * 820
                s.y += (o.y - s.y) * math.min(1, dt * 6)
                s.z += (o.z - oy * o.scale - s.z) * math.min(1, dt * 6)
                if math.abs(dx) < 30 or not alive(o) then
                    s.dead = true
                end
            end
        end
        s.x += s.vx * dt
        if s.t > s.life or s.x < g.camX - 120 or s.x > g.camX + W + 120 then
            s.dead = true
        end
        if not s.dead then
            for _, d in g.fighters do
                if d.team ~= s.owner.team and not s.hit[d.id] and canBeHit(d) then
                    if math.abs(d.x - s.x) < 26 + d.radius and math.abs(d.y - s.y) < 22 + d.radius * 0.3 and s.z > d.z and s.z < d.z + A.height(d.kind) * d.scale + 20 then
                        s.hit[d.id] = true
                        damage(g, s.owner, d, s.dmg, sign(s.vx) * (if s.knock then 300 else 110), s.knock, 380, true)
                        if s.kind ~= 'bird' then
                            s.dead = true
                            break
                        end
                    end
                end
            end
        end
    end
    local i = 1
    while i <= #g.shots do
        if g.shots[i].dead then
            table.remove(g.shots, i)
        else
            i += 1
        end
    end
end

-- Physics and shared state logic ------------------------------------------------------------

local function physics(g: Game, f: Fighter, dt: number)
    f.landing=math.max(0,f.landing-dt)
    f.x += f.vx * dt
    f.y += f.vy * dt
    local landed = false
    if f.z > 0 or f.vz > 0 then
        f.airTime+=dt
        local grav = GRAV
        if f.state == 'air' or f.state == 'jumpatk' then
            if f.vz < 0 then grav *= f.float * (if f.float==1 then 1.12 else 1) end
            if math.abs(f.vz)<90 then grav *= .72 end
        end
        f.vz -= grav * dt
        f.z += f.vz * dt
        if f.z <= 0 then
            f.z = 0
            f.vz = 0
            landed = true
        end
    end
    if f.state == 'hurt' or f.state == 'down' or f.state == 'ko' or f.state == 'getup' then
        if f.z <= 0 then
            f.vx *= math.max(0, 1 - dt * 7)
        end
    end

    local s = f.state
    if s == 'hurt' and f.st > (if isBoss(f.kind) then 0.45 else 0.3) then
        setState(f, 'idle')
        f.vx = 0
    elseif s == 'down' then
        if landed then
            g.shake = math.max(g.shake, 0.06)
            addFx(g, 'dust', f.x, f.y, 0, 0.4, '', G.WHITE, f.scale)
        end
        if f.z <= 0 and f.st > 0.3 and f.st > 1.0 then
            if f.hp <= 0 then
                setState(f, 'ko')
            else
                setState(f, 'getup')
            end
        end
    elseif s == 'getup' and f.st > 0.35 then
        setState(f, 'idle')
        f.invuln = math.max(f.invuln, if f.team == 1 then 1.2 else 0.3)
    elseif (s == 'air' or s == 'jumpatk') and landed then
        setState(f, 'idle')
        f.landing=LANDING
        f.airTime=0
        local heavy=f.kind=='cyborg'
        addFx(g,'landing',f.x,f.y,0,if heavy then .38 else .28,'',HEROES[f.hero].color,if heavy then 1.5 else 1)
        if heavy then g.shake=math.max(g.shake,.075) end
    elseif s == 'enter' and landed then
        setState(f, 'idle')
        addFx(g, 'dust', f.x, f.y, 0, 0.4, '', G.WHITE, 1.4)
    end

    f.y = math.clamp(f.y, FMIN, FMAX)
    if f.team == 1 then
        f.x = math.clamp(f.x, g.camX + 36, g.camX + W - 36)
    elseif f.entering then
        if f.x > g.camX + 60 and f.x < g.camX + W - 60 then
            f.entering = false
        end
    else
        f.x = math.clamp(f.x, g.camX + 30, g.camX + W - 30)
    end
end

local function updatePose(g: Game, f: Fighter, dt: number)
    local p = f.pose
    p.t = g.t + f.id * 0.37
    local speed = math.sqrt(f.vx * f.vx + f.vy * f.vy)
    local dashing = f.state == 'dash' or f.state == 'dashatk'
    p.dash = if dashing then 1 else 0
    local walking = (f.state == 'walk' or f.state == 'idle' or dashing) and speed > 20
    p.speed=math.clamp(speed/f.speed,0,1)
    p.walk += ((if walking then p.speed else 0) - p.walk) * math.min(1, dt * 14)
    local stride=if f.team==1 then Motion.gait(f.kind,p.dash) else 22
    if walking then p.phase+=speed*dt*.56*math.pi/(stride*f.scale) end
    p.rise=math.clamp(f.vz/f.jump,-1,1)
    p.airTime=f.airTime
    p.launch=if f.state=='takeoff' then math.sin(math.min(1,f.st/TAKEOFF)*math.pi/2) else 0
    p.land=f.landing/LANDING
    p.settle=0
    p.air = f.z > 1 and f.state ~= 'down' and f.state ~= 'ko'
    p.hurt = f.state == 'hurt'
    p.ko = f.state == 'ko'
    local lying = f.state == 'down' or f.state == 'ko'
    p.down += ((if lying then 1 else 0) - p.down) * math.min(1, dt * 12)
    if f.state == 'getup' then
        p.down = math.max(0, 1 - f.st / 0.3)
    end
    p.flip = f.facing
    p.move = 0
    p.ext = 0
    p.style = f.kind
    p.powerTime = f.st
    p.windup = 0
    p.stroke = 0
    p.active = false
    if f.state == 'dashatk' then
        p.move = 1
        p.ext = Motion.strike(f.st, DASH_ATTACK_TIME, DASH_HIT_START, DASH_HIT_END)
        p.windup = Motion.windup(f.st, DASH_HIT_START, p.ext)
        p.active = f.st >= DASH_HIT_START and f.st <= DASH_HIT_END
        p.stroke = math.clamp((f.st-DASH_HIT_START)/(DASH_HIT_END-DASH_HIT_START),0,1)
    elseif f.state == 'attack' then
        local attack = Attacks.get(f.kind, f.combo)
        local dur, activeStart, activeEnd = attack.duration, attack.first, attack.last
        p.stroke = math.clamp((f.st - activeStart) / (activeEnd - activeStart), 0, 1)
        p.active = f.st >= activeStart and f.st <= activeEnd
        p.move = f.combo
        p.ext = Motion.strike(f.st, dur, activeStart, activeEnd)
        p.windup = Motion.windup(f.st, activeStart, p.ext)
        p.settle=math.clamp((f.st-activeEnd)/(dur-activeEnd),0,1)
    elseif f.state == 'jumpatk' then
        p.move = 4
        p.ext = Motion.strike(f.st,.42,.06,.24)
        p.windup = Motion.windup(f.st,.06,p.ext)
        p.active=f.st>=.06 and f.st<=.24
        p.stroke=math.clamp((f.st-.06)/.18,0,1)
    elseif f.state == 'secondary' or f.state == 'ultimate' then
        local power = Powers.get(f.kind, f.state == 'ultimate')
        p.move = if f.state == 'ultimate' then 9 else 8
        p.ext = Motion.strike(f.st, power.duration, power.first, power.last)
        p.windup = Motion.windup(f.st, power.first, p.ext)
        p.active = f.st >= power.first and f.st <= power.last
    elseif f.state == 'special' then
        p.move = 5
        p.ext = 1
    elseif f.state == 'eatk' or f.state == 'shoot' or f.state == 'pulse' then
        p.move = 6
        local w = f.windup
        if f.st < w then
            p.ext = -f.st / w
        elseif f.st < w + 0.1 then
            p.ext = (f.st - w) / 0.1
        else
            p.ext = math.max(0, 1 - (f.st - w - 0.1) / 0.35)
        end
    elseif f.state == 'slam' then
        p.move = 7
        p.ext = if f.st < 0.65 then -1 else 1
    elseif f.state == 'charge' then
        p.move = 1
        p.ext = if f.st < 0.45 then -0.6 else 0.8
        p.walk = if f.st < 0.45 then 0 else 1
        p.phase += dt * 10
    end
end

-- Stage flow ------------------------------------------------------------------------------------

local function enemiesLeft(g: Game): number
    local n = 0
    for _, f in g.fighters do
        if f.team == 2 and not f.removed then
            n += 1
        end
    end
    return n
end

local function spawnEnemy(g: Game, kind: string, side: number)
    local x = if side > 0 then g.camX + W + 80 else g.camX - 80
    local y = rnd(FMIN + 20, FMAX - 20)
    local f = newFighter(g, kind, 2, x, y)
    f.entering = true
    f.facing = -side
    if isBoss(kind) then
        g.boss = f
        g.banner = tr(g, ENEMIES[kind].name) .. (if g.locale == 'zh-TW' then '！' else '!')
        g.bannerSub = if kind == 'boss' then 'JUMP OVER THE SHOCKWAVE' elseif kind == 'mammoth' then 'SIDESTEP HIS CHARGE' elseif kind == 'jinx' then 'DODGE THE HEX VOLLEY' else 'THE FINAL SHOWDOWN'
        g.bannerT = 2.2
        g.shake = 0.4
    end
end

local function addCoopReinforcements(g: Game, cp: Checkpoint, players: number)
    if players <= g.wavePlayers then return end
    local regulars: { string } = {}
    for _, sp in cp.spawns do
        if not isBoss(sp.kind) then table.insert(regulars, sp.kind) end
    end
    local previous = Campaign.extraEnemies(cp, g.wavePlayers)
    local total = Campaign.extraEnemies(cp, players)
    for i = previous + 1, total do
        table.insert(g.pending, {
            kind = regulars[1 + (i - 1) % #regulars],
            delay = g.waveT + 1.5 + (i - previous) * .7,
            side = if i % 2 == 0 then 1 else -1,
        })
    end
    -- Keep the wave's high-water mark: continuing cannot spawn the same extras twice.
    g.wavePlayers = players
end

local function syncCoopDifficulty(g: Game)
    local players = math.max(1, activeSlots(g))
    if players ~= g.healthPlayers then
        for _, f in g.fighters do
            if f.team == 2 and f.hp > 0 and not f.removed then
                local maxHp = Campaign.healthFor(f.kind, players)
                -- Preserve the exact remaining fraction, including over repeated joins.
                f.hp = f.hp / f.maxHp * maxHp
                f.maxHp = maxHp
            end
        end
        g.healthPlayers = players
    end
    if g.lockX >= 0 and g.cp <= #CHECKPOINTS then
        addCoopReinforcements(g, CHECKPOINTS[g.cp], players)
    end
end

local function beginCheckpoint(g: Game, cp: Checkpoint)
    g.stage = cp.stage
    g.lockX = cp.x
    g.waveT = 0
    g.pending = {}
    local n = math.max(1, activeSlots(g))
    for _, sp in cp.spawns do
        table.insert(g.pending, { kind = sp.kind, delay = sp.delay, side = sp.side })
    end
    g.wavePlayers = 1
    addCoopReinforcements(g, cp, n)
    if cp.pizza then
        table.insert(g.pickups, { x = cp.x + rnd(300, 900), y = rnd(FMIN + 30, FMAX - 30), t = 0, dead = false })
    end
end

local function startGame(g: Game)
    if not Progress.canPlay(g.progress,g.selectedLevel) then g.mode='map';return end
    g.mode = 'play'
    g.modeT = 0
    g.fighters = {}
    g.shots = {}
    g.fx = {}
    g.pickups = {}
    g.runLevel = g.selectedLevel
    g.cp = (g.runLevel-1)*4+1
    g.stage = CHECKPOINTS[g.cp].stage
    g.camX = if g.cp > 1 then CHECKPOINTS[g.cp].x - 260 else 0
    g.lockX = -1
    g.pending = {}
    g.goT = 0
    g.paused = false
    g.boss = nil
    g.continueT = 0
    local k = 0
    for _, s in g.slots do
        if s.dev ~= '' then
            s.lives = 3
            s.score = 0
            s.energy = 60
            s.out = false
            s.respawn = 0
            spawnHero(g, s, g.camX + 170 + k * 80, 520 + k * 44)
            k += 1
        else
            s.fighter = nil
        end
    end
    g.healthPlayers = math.max(1, activeSlots(g))
    g.wavePlayers = 1
    g.banner = 'TITANS, GO!'
    g.bannerSub = tr(g, Campaign.stages[g.stage].name) .. ' / ' .. tr(g, Campaign.stages[g.stage].subtitle)
    g.bannerT = 2.4
    g.goT = 5
end

local function toTitle(g: Game)
    g.mode = 'title'
    g.modeT = 0
    g.fighters = {}
    g.shots = {}
    g.fx = {}
    g.pickups = {}
    g.paused = false
    g.boss = nil
    g.selectT = -1
    g.tutorial = nil
    g.demo = nil
    g.menuHover = ''
    for i = 1, 4 do
        g.slots[i] = newSlot(i)
    end
end

local function toMap(g: Game, cleared: number?)
    g.mode,g.modeT,g.menuHover='map',0,''
    g.mapCleared=cleared or 0
    g.resetConfirm,g.resetYes=false,false
    if cleared then g.selectedLevel=math.min(Progress.unlocked(g.progress),cleared+1) end
    g.fighters,g.shots,g.fx,g.pickups,g.pending={},{},{},{},{}
    g.paused,g.boss,g.selectT=false,nil,-1
    for _,s in g.slots do s.locked=false end
end

local function heroTaken(g: Game, hero: number, except: Slot): boolean
    for _, s in g.slots do
        if s ~= except and s.dev ~= '' and s.hero == hero and (s.locked or g.mode == 'play') then
            return true
        end
    end
    return false
end

local function freeHero(g: Game, s: Slot): number
    for i = 0, #HEROES - 1 do
        local h = (s.hero - 1 + i) % #HEROES + 1
        if not heroTaken(g, h, s) then
            return h
        end
    end
    return s.hero
end

local function joinSlot(g: Game, devId: string): Slot?
    for _, s in g.slots do
        if s.dev == '' then
            s.dev = devId
            s.locked = false
            s.hero = s.idx
            s.hero = freeHero(g, s)
            return s
        end
    end
    return nil
end

-- Mode updates -----------------------------------------------------------------------------------

local function tutorialDemo(g: Game): Game
    local demo = newGame()
    demo.mode, demo.locale, demo.tutorialSeen = 'play', g.locale, true
    -- A separate arena uses real controls, physics, attacks and projectiles.
    -- Past the campaign's last checkpoint, it cannot spawn or clear waves.
    demo.cp, demo.lockX = #CHECKPOINTS + 1, -1
    local s = demo.slots[1]
    s.dev, s.hero, s.locked, s.energy = 'demo', 1, true, 100
    device(demo, 'demo', 'DEMO')
    spawnHero(demo, s, 265, 565)
    local f = s.fighter :: Fighter
    f.state, f.z, f.invuln, f.st = 'idle', 0, 0, 0
    f.voice.seenWave, f.voice.cooldown = demo.cp, 1000
    local state = g.tutorial :: Tutorial.State
    if Tutorial.steps[state.index].target then
        local target = newFighter(demo, 'bot', 2, f.x + 76, f.y)
        target.state, target.hp, target.maxHp = 'target', 1000, 1000
        target.speed, target.cd, target.facing = 0, 1000, -1
    end
    return demo
end

local function beginTutorial(g: Game, returnMode: string)
    g.tutorialSeen, g.tutorialReturn = true, returnMode
    g.mode, g.modeT, g.menuHover = 'tutorial', 0, ''
    g.tutorial = Tutorial.new()
    g.demo = tutorialDemo(g)
end

local function finishTutorial(g: Game)
    g.mode, g.modeT, g.menuHover = g.tutorialReturn, 0, ''
    g.tutorial, g.demo = nil, nil
    for _, d in g.devs do table.clear(d.pressed) end
end

local function tutorialNext(g: Game, previous: boolean?)
    local state = g.tutorial
    if not state then return end
    if previous then Tutorial.previous(state)
    elseif not Tutorial.next(state) then finishTutorial(g); return end
    g.demo = tutorialDemo(g)
end

local function menuAction(g: Game, action: string)
    if g.mode=='map' then
        if g.resetConfirm then
            if action=='keep' then g.resetConfirm=false
            elseif action=='confirm' then
                Progress.reset(g.progress)
                g.selectedLevel,g.mapCleared,g.resetConfirm,g.resetYes=1,0,false,false
            end
        elseif action=='reset' then g.resetConfirm,g.resetYes=true,false
        elseif action=='back' then toTitle(g)
        elseif string.sub(action,1,5)=='level' then
            g.selectedLevel=math.clamp(tonumber(string.sub(action,6)) or 1,1,4)
        elseif action=='play' and Progress.canPlay(g.progress,g.selectedLevel) then
            local joined=false
            for _,s in g.slots do if s.dev~='' then joined=true;s.locked=false end end
            if not joined then device(g,'kb1','KEYBOARD 1');joinSlot(g,'kb1') end
            if not g.tutorialSeen then beginTutorial(g,'select')
            else g.mode,g.modeT,g.selectT='select',0,-1 end
        end
    elseif action == 'help' and g.mode == 'title' then beginTutorial(g, 'title')
    elseif g.mode == 'tutorial' then
        if action == 'skip' then finishTutorial(g)
        elseif action == 'next' then tutorialNext(g)
        elseif action == 'previous' then tutorialNext(g, true) end
    end
end

local function updateTitle(g: Game)
    for id, d in g.devs do
        if pressed(d, 'y') then beginTutorial(g, 'title'); return end
        if pressed(d, 'start') or pressed(d, 'a') then
            joinSlot(g, id)
            if not g.tutorialSeen then beginTutorial(g, 'map')
            else toMap(g) end
            return
        end
    end
end

local function updateMap(g: Game)
    for id,d in g.devs do
        if g.resetConfirm then
            if pressed(d,'cancel') or pressed(d,'back') or pressed(d,'b') then menuAction(g,'keep');return end
            if pressed(d,'L') or pressed(d,'R') then g.resetYes=not g.resetYes end
            if pressed(d,'a') or pressed(d,'start') then menuAction(g,if g.resetYes then 'confirm' else 'keep');return end
        elseif pressed(d,'y') then menuAction(g,'reset');return
        elseif pressed(d,'cancel') or pressed(d,'back') or pressed(d,'b') then toTitle(g);return
        else
            if pressed(d,'L') or pressed(d,'U') then g.selectedLevel=math.max(1,g.selectedLevel-1)
            elseif pressed(d,'R') or pressed(d,'D') then g.selectedLevel=math.min(4,g.selectedLevel+1) end
            if pressed(d,'a') or pressed(d,'start') then
                if Progress.canPlay(g.progress,g.selectedLevel) then
                    if slotOf(g,id)==nil then joinSlot(g,id) end
                    menuAction(g,'play')
                end
                return
            end
        end
    end
end

local function updateSelect(g: Game, dt: number)
    -- join
    for id, d in g.devs do
        if slotOf(g, id) == nil and (pressed(d, 'start') or pressed(d, 'a')) then
            joinSlot(g, id)
            d.pressed['a'] = nil
            d.pressed['start'] = nil
        end
    end
    local allLocked = true
    local any = false
    for _, s in g.slots do
        local d = slotDevice(g, s)
        if s.dev ~= '' and d then
            any = true
            if not s.locked then
                allLocked = false
                local dir = 0
                if pressed(d, 'L') then
                    dir = -1
                elseif pressed(d, 'R') then
                    dir = 1
                end
                if dir ~= 0 then
                    for _ = 1, #HEROES do
                        s.hero = (s.hero - 1 + dir) % #HEROES + 1
                        if not heroTaken(g, s.hero, s) then
                            break
                        end
                    end
                end
                if pressed(d, 'a') or pressed(d, 'start') then
                    if not heroTaken(g, s.hero, s) then
                        s.locked = true
                        addFx(g, 'word', 0, 0, 0, 0.1, '', G.WHITE, 1)
                    end
                elseif pressed(d, 'b') or pressed(d, 'cancel') then
                    s.dev = ''
                end
            else
                if pressed(d, 'b') or pressed(d, 'cancel') then
                    s.locked = false
                    g.selectT = -1
                elseif pressed(d, 'start') then
                    g.selectT = 0.01
                end
            end
        end
    end
    if not any then
        toTitle(g)
        return
    end
    if allLocked then
        if g.selectT < 0 then
            g.selectT = 3
        end
        g.selectT -= dt
        if g.selectT <= 0 then
            startGame(g)
        end
    else
        g.selectT = -1
    end
end

local function updatePlay(g: Game, dt: number)
    -- start: drop-in, pause, continue
    for id, d in g.devs do
        if pressed(d, 'start') then
            local s = slotOf(g, id)
            if s == nil then
                local ns = joinSlot(g, id)
                if ns then
                    ns.locked = true
                    ns.lives = 3
                    ns.score = 0
                    ns.energy = 60
                    ns.out = false
                    spawnHero(g, ns, g.camX + 200 + ns.idx * 60, rnd(FMIN + 30, FMAX - 30))
                end
            elseif s.out then
                s.out = false
                s.lives = 3
                spawnHero(g, s, g.camX + 240, rnd(FMIN + 30, FMAX - 30))
            else
                g.paused = not g.paused
            end
        end
    end
    if g.paused then
        for _, f in g.fighters do f.tapDir = '' end
        for _, s in g.slots do
            local d = slotDevice(g, s)
            if d and (pressed(d, 'cancel') or pressed(d, 'back')) then
                toTitle(g)
                return
            end
        end
        return
    end

    syncCoopDifficulty(g)
    g.goT = math.max(0, g.goT - dt)
    g.bannerT = math.max(0, g.bannerT - dt)
    g.shake = math.max(0, g.shake - dt)

    for _, f in g.fighters do
        -- Determine every actor's time slice before combat. New impacts take
        -- effect next frame, independent of the order fighters are updated in.
        f.stepDt = math.max(0, dt - f.hitPause)
        f.hitPause = math.max(0, f.hitPause - dt)
        f.flash = math.max(0, f.flash - dt)
        f.hitT += dt
        if f.team==1 then
            Remarks.update(f.voice,dt)
            if f.hp>f.maxHp*.4 then f.voice.danger=false end
        end
    end

    -- fighters
    for _, s in g.slots do
        s.denyT = math.max(0, s.denyT - dt)
        local f = s.fighter
        if f and not f.removed then
            local dev = slotDevice(g, s)
            if f.stepDt <= 0 then
                -- Input edges live for only one frame. Retain combat/direction
                -- taps through the brief pose hold, then consume them once.
                if dev then
                    for button, down in dev.pressed do
                        if down and button ~= 'start' and button ~= 'back' and button ~= 'cancel' then
                            f.buffered[button] = true
                        end
                    end
                end
            else
                if dev then
                    for button in f.buffered do dev.pressed[button] = true end
                end
                table.clear(f.buffered)
                updatePlayer(g, s, f, f.stepDt)
            end
        end
    end
    for _, f in g.fighters do
        if f.team == 2 and alive(f) and f.stepDt > 0 then
            updateEnemy(g, f, f.stepDt)
        end
    end
    for _, f in g.fighters do
        if not f.removed and f.stepDt > 0 then
            f.st += f.stepDt
            f.invuln = math.max(0, f.invuln - f.stepDt)
            physics(g, f, f.stepDt)
            updatePose(g, f, f.stepDt)
        end
    end

    -- keep villains from stacking on one spot
    for _, a in g.fighters do
        if a.team == 2 and alive(a) then
            for _, b in g.fighters do
                if b ~= a and b.team == 2 and alive(b) and a.id < b.id then
                    local dx = b.x - a.x
                    local dy = b.y - a.y
                    local r = (a.radius + b.radius) * 0.9
                    if math.abs(dx) < r and math.abs(dy) < 16 then
                        local push = (r - math.abs(dx)) * 0.5 * math.min(1, dt * 10)
                        if a.stepDt > 0 then a.x -= sign(dx) * push end
                        if b.stepDt > 0 then b.x += sign(dx) * push end
                    end
                end
            end
        end
    end

    updateShots(g, dt)

    -- knocked-out fighters
    for _, f in g.fighters do
        if f.state == 'ko' and not f.removed then
            if f.team == 2 and f.st > 1.1 then
                f.removed = true
                local chance = if f.kind == 'heavy' then 0.4 else 0.12
                if not isBoss(f.kind) and math.random() < chance then
                    table.insert(g.pickups, { x = f.x, y = f.y, t = 0, dead = false })
                end
            elseif f.team == 1 and f.st > 1.3 then
                f.removed = true
                local s = g.slots[f.slot]
                s.fighter = nil
                s.lives -= 1
                if s.lives > 0 then
                    s.respawn = 0.6
                else
                    s.out = true
                end
            end
        end
    end
    for _, s in g.slots do
        if s.dev ~= '' and s.respawn > 0 then
            s.respawn -= dt
            if s.respawn <= 0 then
                s.respawn = 0
                spawnHero(g, s, g.camX + rnd(200, 500), rnd(FMIN + 30, FMAX - 30))
            end
        end
    end
    local i = 1
    while i <= #g.fighters do
        if g.fighters[i].removed then
            table.remove(g.fighters, i)
        else
            i += 1
        end
    end

    -- pizza!
    for _, p in g.pickups do
        p.t += dt
        for _, s in g.slots do
            local f = s.fighter
            if f and not p.dead and alive(f) and f.z < 30 and math.abs(f.x - p.x) < 34 and math.abs(f.y - p.y) < 22 then
                p.dead = true
                f.hp = math.min(f.maxHp, f.hp + 45)
                s.score += 100
                addFx(g, 'word', p.x, p.y, 70, 0.9, 'PIZZA!', G.hex(0xFFD34D), 26)
                remark(g,f,'heal')
            end
        end
    end
    local j = 1
    while j <= #g.pickups do
        if g.pickups[j].dead or g.pickups[j].x < g.camX - 100 then
            table.remove(g.pickups, j)
        else
            j += 1
        end
    end

    -- camera
    local minX, maxX = math.huge, -math.huge
    for _, f in g.fighters do
        if f.team == 1 and alive(f) then
            minX = math.min(minX, f.x)
            maxX = math.max(maxX, f.x)
        end
    end
    local limit = if g.lockX >= 0 then g.lockX else (if g.cp <= #CHECKPOINTS then CHECKPOINTS[g.cp].x else g.camX)
    if maxX > -math.huge then
        local target = math.min(maxX - 620, minX - 60)
        if target > g.camX then
            g.camX += (target - g.camX) * math.min(1, dt * 5)
        end
    end
    g.camX = math.min(g.camX, limit)

    -- checkpoints and waves
    if g.lockX < 0 and g.cp <= #CHECKPOINTS and g.camX >= CHECKPOINTS[g.cp].x - 1 then
        g.camX = CHECKPOINTS[g.cp].x
        beginCheckpoint(g, CHECKPOINTS[g.cp])
        g.goT = 0
    end
    if g.lockX >= 0 then
        g.waveT += dt
        local k = 1
        while k <= #g.pending do
            local sp = g.pending[k]
            if g.waveT >= sp.delay then
                spawnEnemy(g, sp.kind, sp.side)
                table.remove(g.pending, k)
            else
                k += 1
            end
        end
        local survived=false
        for _,hero in g.fighters do
            if hero.team==1 and hero.hp>0 and alive(hero) then survived=true end
        end
        if #g.pending == 0 and enemiesLeft(g) == 0 and survived then
            for _,hero in g.fighters do
                if hero.team==1 and hero.hp>0 and alive(hero) then remark(g,hero,'victory') end
            end
            local cp = CHECKPOINTS[g.cp]
            g.lockX = -1
            g.cp += 1
            if cp.boss then
                -- A level is cleared only after its boss AND reinforcements,
                -- with a surviving Titan. Replays never lower saved progress.
                if cp.stage==g.runLevel then
                    Progress.complete(g.progress,g.runLevel)
                    for _,s in g.slots do if s.dev~='' and not s.out then s.score+=2500 end end
                    if g.runLevel==4 then
                        g.mode,g.modeT,g.banner='win',0,''
                    else toMap(g,g.runLevel) end
                    return
                end
            else
                g.goT = 3.5
            end
        end
    end

    -- Notice visible enemies once per wave, after the arrival banner. A denied
    -- co-op line can wait its turn, instead of becoming a per-frame bark.
    for _,hero in g.fighters do
        if hero.team==1 and hero.hp>0 and alive(hero) and hero.state~='enter' then
            if hero.hp<=hero.maxHp*.25 and not hero.voice.danger then
                if remark(g,hero,'low_health') then hero.voice.danger=true end
            end
            if hero.voice.seenWave~=g.cp and g.bannerT<=0 and hero.z<30 and hero.state~='down' then
                for _,enemy in g.fighters do
                    if enemy.team==2 and enemy.hp>0 and alive(enemy) and enemy.x>=g.camX and enemy.x<=g.camX+W
                        and math.abs(enemy.x-hero.x)<560 and math.abs(enemy.y-hero.y)<180 then
                        if remark(g,hero,'encounter') then hero.voice.seenWave=g.cp end
                        break
                    end
                end
            end
        end
    end

    -- continue countdown when every Titan is down for good
    local anyAlive = false
    for _, s in g.slots do
        if s.dev ~= '' and not s.out then
            anyAlive = true
        end
    end
    if not anyAlive then
        if g.continueT <= 0 then
            g.continueT = 10
        end
        g.continueT -= dt
        if g.continueT <= 0 then
            g.mode = 'over'
            g.modeT = 0
        end
    else
        g.continueT = 0
    end
end

local function updateFx(g: Game, dt: number)
    for _, e in g.fx do
        e.t += dt
    end
    local i = 1
    while i <= #g.fx do
        if g.fx[i].t >= g.fx[i].life then
            table.remove(g.fx, i)
        else
            i += 1
        end
    end
end

local function updateTutorial(g: Game, dt: number)
    for id, d in g.devs do
        if pressed(d, 'start') or pressed(d, 'cancel') or pressed(d, 'back') then
            if pressed(d, 'start') and g.tutorialReturn ~= 'title' and not slotOf(g, id) then joinSlot(g, id) end
            finishTutorial(g)
            return
        elseif pressed(d, 'a') or pressed(d, 'R') then tutorialNext(g); return
        elseif pressed(d, 'L') then tutorialNext(g, true); return end
    end
    local state = g.tutorial
    if not state then return end
    state.time += dt
    if state.time >= Tutorial.steps[state.index].duration then tutorialNext(g); return end
    state.input = Tutorial.inputs(state.index, state.time)
    local demo = g.demo
    if not demo or demo.mode ~= 'play' then return end
    local dev = demo.devs['demo']
    for _, name in {'L','R','U','D','a','x','b','y','rt','start','cancel'} do
        setButton(dev, name, state.input.held[name] == true)
    end
    dev.mx, dev.my = state.input.mx, state.input.my
    demo.t += dt
    -- The target reacts to real hits but never initiates an attack.
    for _, f in demo.fighters do
        if f.team == 2 and (f.state == 'idle' or f.state == 'walk') then f.state = 'target' end
    end
    updatePlay(demo, dt)
    if not demo.paused then updateFx(demo, dt) end
    for _, d in demo.devs do table.clear(d.pressed) end
end

local function update(g: Game, dt: number)
    dt = math.min(dt, 1 / 30)
    g.t += dt
    g.modeT += dt
    if g.mode == 'title' then
        updateTitle(g)
    elseif g.mode == 'tutorial' then
        updateTutorial(g, dt)
    elseif g.mode == 'map' then
        updateMap(g)
    elseif g.mode == 'select' then
        updateSelect(g, dt)
    elseif g.mode == 'play' then
        updatePlay(g, dt)
    elseif g.mode == 'over' or g.mode == 'win' then
        for _, d in g.devs do
            if g.modeT > 1.5 and (pressed(d, 'start') or pressed(d, 'a')) then
                toMap(g,if g.mode=='win' then g.runLevel else nil)
                break
            end
        end
    end
    if not g.paused then
        updateFx(g, dt)
    end
    for _, d in g.devs do
        table.clear(d.pressed)
    end
end

-- Drawing ------------------------------------------------------------------------------------------

local function drawFighter(g: Game, f: Fighter)
    local sx = f.x - g.camX
    local sy = f.y - f.z
    if f.team == 1 and (f.state == 'dash' or f.state == 'dashatk') then
        local color = HEROES[f.hero].color
        -- Two short pose echoes follow the actual dash vector, including lanes.
        for i = 2, 1, -1 do
            G.save()
            G.translate(sx-f.dashX*i*28,sy-f.dashY*i*28)
            G.scale(f.facing*f.scale,f.scale)
            G.tint(color)
            G.opacity(.16/i)
            local echo=table.clone(f.pose)
            echo.phase-=i*.35
            A.fighter(f.kind,echo)
            G.restore()
        end
        for i = 1, 4 do
            local offset = 18 + i*11
            local x = sx - f.dashX*offset
            local y = sy - 28 - i*17 - f.dashY*offset*.62
            G.line(x, y, x-f.dashX*48, y-f.dashY*30, 4, G.fade(color,.65-i*.1))
        end
    end
    G.save()
    G.translate(sx, sy)
    G.scale(f.facing * f.scale, f.scale)
    if f.invuln > 0 and f.state ~= 'special' and f.state ~= 'secondary' and f.state ~= 'ultimate' and math.floor(g.t * 20) % 2 == 0 then
        G.opacity(0.45)
    end
    if f.state == 'ko' and f.team == 2 then
        G.opacity(if math.floor(g.t * 14) % 2 == 0 then 0.3 else 0.9)
    end
    if f.flash > 0 then
        G.tint(G.hex(0xFF9A9A))
    end
    A.fighter(f.kind, f.pose)
    G.restore()

    if f.team == 2 then
        if (f.state == 'pulse' and f.st < f.windup) or (f.state == 'slam' and f.st < .65) then
            local pulse = f.state == 'pulse'
            local radius = if pulse then 165 else 250
            local cx = sx + (if pulse then 0 else f.facing * 80)
            G.oellipse(cx, f.y, radius, if pulse then 65 else 100, G.fade(G.hex(0xFF4D5E), .14), 2)
            uiText(g, 'JUMP!', cx, f.y + 12, 14, G.hex(0xFFE14D), .5)
        elseif (f.state == 'shoot' and f.st < f.windup) or (f.state == 'charge' and f.st < .45) then
            uiText(g, if f.state == 'shoot' then '!' else 'RUSH!', sx, sy - A.height(f.kind) * f.scale - 28, 22, G.hex(0xFFE14D), .5)
        end
    end

    -- the Sonic Cannon beam comes out of Cyborg's arm
    if f.kind == 'cyborg' and f.state == 'special' and f.st > 0.28 and f.st < 0.82 then
        local p = math.min(1, (f.st - 0.28) / 0.08)
        local ox, oy = A.projectileOrigin(f.kind, f.pose)
        A.beam(sx + f.facing * ox * f.scale, sy + oy * f.scale, 1150 * p, g.t, f.facing, 1 - math.max(0, f.st - 0.7) * 6)
    end

    local top = fighterHeight(f)
    if f.slot > 0 and g.slots[f.slot].dev ~= 'demo' then
        local s = g.slots[f.slot]
        local ty = sy - top - 30
        G.poly({ sx - 7, ty + 16, sx + 7, ty + 16, sx, ty + 24 }, s.color, 1.5)
        uiText(g, `P{f.slot}`, sx, ty - 2, 14, s.color, 0.5)
    elseif f.team == 2 and not isBoss(f.kind) and f.hitT < 2 and f.state ~= 'ko' then
        local w = 60 * f.scale
        local by = sy - top - 16
        G.rect(sx - w / 2 - 2, by - 2, w + 4, 10, G.INK)
        G.rect(sx - w / 2, by, w * f.hp / f.maxHp, 6, G.hex(0xFF7A2E))
    end
end

local function drawShot(g: Game, s: Shot)
    local sx = s.x - g.camX
    local sy = s.y - s.z
    if s.kind == 'bird' then
        A.birdarang(sx, sy, s.t * 24)
    elseif s.kind == 'bolt' then
        A.starbolt(sx, sy, s.t, sign(s.vx))
    else
        A.enemyShot(s.kind, sx, sy, s.t, sign(s.vx))
    end
end

type DrawItem = { y: number, kind: number, idx: number }

local function drawWorld(g: Game)
    A.stage(g.camX, g.t, Campaign.stages[g.stage].theme, g.locale)

    -- ground effects and shadows first
    for _, e in g.fx do
        if e.kind == 'wave' then
            A.shockwave(e.x - g.camX, e.y, 40 + e.t / e.life * 260, 1 - e.t / e.life)
        end
    end
    for _, f in g.fighters do
        A.shadow(f.x - g.camX, f.y, (f.radius + 8) * (if f.kind == 'beast' and (f.state == 'special' or f.state == 'secondary' or f.state == 'ultimate') then 2 else 1), f.z)
    end
    for _, s in g.shots do
        A.shadow(s.x - g.camX, s.y, 12, s.z)
    end
    for _, p in g.pickups do
        A.shadow(p.x - g.camX, p.y, 18, 10)
    end

    -- depth-sorted bodies
    local items: { DrawItem } = {}
    for i, f in g.fighters do
        table.insert(items, { y = f.y, kind = 1, idx = i })
    end
    for i, s in g.shots do
        table.insert(items, { y = s.y + 1, kind = 2, idx = i })
    end
    for i, p in g.pickups do
        table.insert(items, { y = p.y - 1, kind = 3, idx = i })
    end
    table.sort(items, function(a: DrawItem, b: DrawItem): boolean
        return a.y < b.y
    end)
    for _, it in items do
        if it.kind == 1 then
            drawFighter(g, g.fighters[it.idx])
        elseif it.kind == 2 then
            drawShot(g, g.shots[it.idx])
        else
            local p = g.pickups[it.idx]
            A.pizza(p.x - g.camX, p.y - 26 - math.sin(p.t * 4) * 5, p.t)
        end
    end

    -- overhead effects
    for _, e in g.fx do
        local k = e.t / e.life
        local sx = e.x - g.camX
        local sy = e.y - e.z
        if e.kind == 'spark' then
            A.spark(sx, sy, k, e.color)
        elseif e.kind == 'dust' then
            G.save()
            G.translate(sx, sy)
            G.scale(e.size, e.size)
            A.dust(0, 0, k)
            G.restore()
        elseif e.kind == 'launch' or e.kind == 'landing' then
            G.save()
            G.translate(sx,sy)
            G.scale(e.size,e.size)
            G.opacity(1-k)
            local r=12+k*(if e.kind=='landing' then 58 else 32)
            G.ring(0,0,r,r*.22,2.4,G.fade(e.color,.7))
            for side=-1,1,2 do
                G.ellipse(side*r*.8,-3-k*7,5+k*9,3+k*4,G.fade(G.WHITE,.55))
                G.line(side*10,-6,side*(15+k*18),-8-k*13,1.8,G.fade(e.color,.75))
            end
            G.restore()
        elseif e.kind == 'dark' then
            A.darkBurst(sx, e.y, 60 + k * 200, 1 - k * k)
        elseif e.kind == 'word' and e.text ~= '' then
            local pop = math.min(1, e.t / 0.08)
            local sz = e.size * (0.6 + 0.4 * pop)
            G.save()
            G.opacity(1 - math.max(0, k - 0.7) / 0.3)
            uiText(g, e.text, sx, sy - k * 30, sz, e.color, 0.5)
            G.restore()
        end
    end
end

local function bar(x: number, y: number, w: number, h: number, v: number, c: Color)
    G.rrect(x - 2, y - 2, w + 4, h + 4, (h + 4) / 2, G.INK)
    G.rrect(x, y, w, h, h / 2, G.hex(0x3A2F4A))
    if v > 0 then
        G.rrect(x, y, math.max(h, w * math.clamp(v, 0, 1)), h, h / 2, c)
    end
end

local function drawHud(g: Game)
    for _, s in g.slots do
        local x = 12 + (s.idx - 1) * 317
        local y = 10
        local w = 305
        G.save()
        G.opacity(0.9)
        G.rrect(x, y, w, 92, 12, G.hex(0x1C1330), 3)
        G.restore()
        G.rrect(x + 3, y + 3, w - 6, 6, 3, s.color)
        if s.dev == '' then
            if math.floor(g.t * 2) % 2 == 0 then
                uiText(g, L.format(g.locale, 'P{player} PRESS START', { player = s.idx }), x + w / 2, y + 34, 18, s.color, 0.5)
            end
        else
            local h = HEROES[s.hero]
            G.oellipse(x + 40, y + 44, 28, 28, G.shade(h.color, -0.35), 2.5)
            G.save()
            G.clipEllipse(x + 40, y + 44, 28, 28)
            G.opacity(if s.out then 0.4 else 1)
            A.portrait(h.key, x + 40, y + 48, 0.9, g.t)
            G.restore()
            uiText(g, h.name, x + 78, y + 16, 15, G.WHITE)
            uiText(g, `{s.score}`, x + w - 12, y + 16, 14, G.hex(0xFFE14D), 1)
            if s.out then
                if math.floor(g.t * 2) % 2 == 0 then
                    uiText(g, 'CONTINUE? START', x + 78, y + 44, 14, s.color)
                end
            else
                local f = s.fighter
                local hp = if f then f.hp / f.maxHp else 0
                local hc = if hp > 0.5 then G.hex(0x3BD16F) elseif hp > 0.25 then G.hex(0xFFC21A) else G.hex(0xFF4D5E)
                bar(x + 78, y + 40, 212, 11, hp, hc)
                local ready = s.energy >= SPECIAL_COST
                local ec = if s.energy >= 100 then G.hex(0xFFE14D) elseif ready then G.hex(0x7FD8FF) else G.hex(0x3A6FB0)
                if s.denyT > 0 and math.floor(g.t * 16) % 2 == 0 then
                    ec = G.hex(0xFF4D5E)
                end
                bar(x + 78, y + 60, 150, 7, s.energy / 100, ec)
                uiText(g, 'B 30', x + 78, y + 76, 9, if s.energy >= 30 then G.hex(0x7FD8FF) else G.hex(0x655974))
                uiText(g, 'Y 40', x + 133, y + 76, 9, if s.energy >= 40 then G.hex(0x7FD8FF) else G.hex(0x655974))
                uiText(g, 'RT 100', x + 190, y + 76, 9, if s.energy >= 100 then G.hex(0xFFE14D) else G.hex(0x655974))
                uiText(g, `x{s.lives}`, x + w - 12, y + 57, 13, G.WHITE, 1)
            end
        end
    end

    local cp = CHECKPOINTS[math.min(g.cp, #CHECKPOINTS)]
    G.rrect(16, 114, 420, 34, 8, G.fade(G.INK, .88))
    uiText(g, L.format(g.locale, '{stage}/4  {name}  -  WAVE {wave}/4', { stage = g.stage, name = tr(g, Campaign.stages[g.stage].name), wave = cp.wave }), 30, 124, 13, G.hex(0xFFE14D))
    if g.lockX >= 0 then
        uiText(g, L.format(g.locale, '{players}P  ENEMIES {count}', { players = math.max(1, activeSlots(g)), count = enemiesLeft(g) + #g.pending }), W - 26, 124, 14, G.WHITE, 1)
    end
    local b = g.boss
    if b and not b.removed then
        uiText(g, ENEMIES[b.kind].name, W / 2, H - 58, 18, G.hex(0xFFD23A), 0.5)
        bar(W / 2 - 300, H - 32, 600, 16, b.hp / b.maxHp, G.hex(0xFF7A2E))
    end
end

local function drawBanner(g: Game)
    if g.bannerT <= 0 or g.banner == '' then
        return
    end
    local k = g.bannerT
    local a = math.min(1, k / 0.3)
    local slide = math.max(0, 1 - (2.6 - k) / 0.25)
    G.save()
    G.opacity(a)
    G.translate(-slide * 400, 0)
    G.poly({ 0, 260, W, 240, W, 360, 0, 380 }, G.fade(G.hex(0x1C1330), 0.85))
    uiText(g, g.banner, W / 2, 262, 64, G.hex(0xFFE14D), 0.5, G.hex(0xB0122A))
    uiText(g, g.bannerSub, W / 2, 340, 20, G.WHITE, 0.5)
    G.restore()
end

local LANGUAGE_X, LANGUAGE_Y = 950, 28
local function drawLanguage(g: Game)
    G.rrect(LANGUAGE_X, LANGUAGE_Y, 310, 58, 12, G.hex(0x1C1330), 2)
    for i, locale in { 'en', 'zh-TW' } do
        local x = LANGUAGE_X + (if i == 1 then 4 else 124)
        local w = if i == 1 then 116 else 182
        local selected = g.locale == locale
        local background = if selected then G.hex(0xFFE14D) elseif g.languageHover == i then G.hex(0x44315C) else G.hex(0x241A37)
        G.rrect(x, LANGUAGE_Y + 4, w, 50, 8, background)
        G.text(if i == 1 then 'ENGLISH' else L.languageLabel, x + w / 2, LANGUAGE_Y + 19, if i == 1 then 14 else 18, if selected then G.INK else G.WHITE, .5, background)
    end
end

local function drawTitle(g: Game)
    A.stage((g.t * 40) % 4000, g.t, nil, g.locale)
    G.save()
    G.opacity(0.45)
    G.rect(0, 0, W, H, G.hex(0x140C24))
    G.restore()

    -- logo
    G.vgrad(0, 0, W, 330, G.fade(G.hex(0x140C24), 0.85), G.fade(G.hex(0x140C24), 0))
    local bob = math.sin(g.t * 2) * 4
    G.save()
    G.translate(W / 2, 134 + bob)
    G.rotate(-0.04)
    uiText(g, 'TEEN TITANS', 0, -10, 96, G.hex(0xFFE14D), 0.5, G.hex(0xB0122A))
    G.poly({ -250, 104, 250, 96, 262, 150, -262, 156 }, G.hex(0xD7263D), 3)
    uiText(g, 'JUMP CITY BRAWL', 0, 110, 34, G.WHITE, 0.5)
    G.restore()

    -- the team
    for i, h in HEROES do
        local x = W / 2 + (i - 3) * 190
        local p = A.newPose()
        p.t = g.t + i
        local modelScale = A.modelScale(h.key)
        A.shadow(x, 560, 34 * modelScale, 0)
        G.save()
        G.translate(x, 560)
        G.scale(1.5 * modelScale, 1.5 * modelScale)
        A.fighter(h.key, p, true)
        G.restore()
        uiText(g, h.name, x, 578, 16, h.color, 0.5)
    end

    if math.floor(g.t * 2.5) % 2 == 0 then
        uiText(g, 'PRESS SPACE / START', W / 2, 628, 36, G.WHITE, 0.5)
    end
    local pads = 0
    for id, _ in g.devs do
        if string.sub(id, 1, 3) == 'pad' then
            pads += 1
        end
    end
    Tutorial.drawHelp(g.locale, g.menuHover)
    uiText(g, L.format(g.locale, '1-4 PLAYERS   CONTROLLERS CONNECTED: {count}', { count = pads }), 18, 698, 10, G.hex(0x8D839E))
    uiText(g, 'UNOFFICIAL FAN GAME', W - 16, H - 22, 11, G.hex(0x8D839E), 1)
    drawLanguage(g)
end

local function statBar(g: Game, x: number, y: number, label: string, v: number, c: Color)
    uiText(g, label, x, y, 12, G.hex(0xCFC6D8))
    bar(x + 60, y + 1, 150, 9, v, c)
end

local function drawSelect(g: Game)
    A.stage(1800 + math.sin(g.t * 0.2) * 200, g.t, nil, g.locale)
    G.save()
    G.opacity(0.6)
    G.rect(0, 0, W, H, G.hex(0x140C24))
    G.restore()
    uiText(g, 'CHOOSE YOUR TITAN', W / 2, 26, 44, G.hex(0xFFE14D), 0.5, G.hex(0xB0122A))
    uiText(g, L.format(g.locale,'LEVEL {level}',{level=g.selectedLevel}),26,28,14,G.hex(0x7FD8FF))
    uiText(g, Campaign.stages[g.selectedLevel].name,26,54,13,G.WHITE)

    for _, s in g.slots do
        local x = 24 + (s.idx - 1) * 312
        local y = 96
        local w = 296
        local h = 482
        G.save()
        G.opacity(0.92)
        G.rrect(x, y, w, h, 16, G.hex(0x1C1330), 3)
        G.restore()
        G.rrect(x + 4, y + 4, w - 8, 34, 12, s.color)
        uiText(g, L.format(g.locale, 'PLAYER {player}', { player = s.idx }), x + w / 2, y + 12, 18, G.WHITE, 0.5)
        if s.dev == '' then
            if math.floor(g.t * 2) % 2 == 0 then
                uiText(g, 'PRESS START', x + w / 2, y + 200, 22, s.color, 0.5)
            end
            uiText(g, 'TO JOIN', x + w / 2, y + 234, 16, G.hex(0x8D839E), 0.5)
        else
            local hero = HEROES[s.hero]
            local d = g.devs[s.dev]
            uiText(g, if d then (if string.sub(d.id, 1, 3) == 'pad' then L.format(g.locale, 'CONTROLLER {id}', { id = string.sub(d.id, 4) }) else tr(g, d.label)) else '', x + w / 2, y + 48, 12, G.hex(0x8D839E), 0.5)
            G.glow(x + w / 2, y + 220, 120, hero.color, 0.5)
            local p = A.newPose()
            p.t = g.t + s.idx
            local modelScale = A.modelScale(hero.key)
            A.shadow(x + w / 2, y + 310, 44 * modelScale, 0)
            G.save()
            G.translate(x + w / 2, y + 310)
            -- A common display zoom fits the tallest Titan below the device
            -- label without normalizing away the team's height differences.
            G.scale(1.4 * modelScale, 1.4 * modelScale)
            A.fighter(hero.key, p, true)
            G.restore()
            local taken = heroTaken(g, s.hero, s)
            uiText(g, hero.name, x + w / 2, y + 318, 26, if taken then G.hex(0x8D839E) else hero.color, 0.5)
            statBar(g, x + 30, y + 360, 'POWER', (hero.power - 0.8) / 0.5, G.hex(0xFF4D5E))
            statBar(g, x + 30, y + 380, 'SPEED', (hero.speed - 180) / 120, G.hex(0x3BD16F))
            statBar(g, x + 30, y + 400, 'HEALTH', (hero.hp - 80) / 70, G.hex(0x3A9BFF))
            uiText(g, 'B: ' .. tr(g, hero.special), x + w / 2, y + 423, 10, G.hex(0xFFE14D), 0.5)
            uiText(g, 'Y: ' .. tr(g, Powers.secondary[hero.key].name), x + w / 2, y + 442, 10, G.hex(0x7FD8FF), 0.5)
            uiText(g, 'RT: ' .. tr(g, Powers.ultimate[hero.key].name), x + w / 2, y + 461, 10, G.hex(0xD5AEFF), 0.5)
            if s.locked then
                G.save()
                G.translate(x + w / 2, y + 262)
                G.rotate(-0.12)
                G.rrect(-86, -26, 172, 52, 10, G.hex(0xFFE14D), 3)
                uiText(g, 'READY!', 0, -15, 30, G.hex(0xB0122A), 0.5, G.hex(0xFFE14D))
                G.restore()
            else
                local wob = math.sin(g.t * 6) * 4
                uiText(g, '<', x + 20 - wob, y + 200, 34, s.color)
                uiText(g, '>', x + w - 44 + wob, y + 200, 34, s.color)
            end
        end
    end

    -- roster
    for i, h in HEROES do
        local x = W / 2 + (i - 3) * 110
        local y = 614
        local lockedBy = 0
        for _, s in g.slots do
            if s.dev ~= '' and s.locked and s.hero == i then
                lockedBy = s.idx
            end
        end
        G.oellipse(x, y, 38, 38, if lockedBy > 0 then SLOT_COLORS[lockedBy] else G.hex(0x2A2040), 3)
        G.save()
        G.clipEllipse(x, y, 38, 38)
        G.opacity(if lockedBy > 0 then 0.55 else 1)
        A.portrait(h.key, x, y + 6, 1.15, g.t)
        G.restore()
        local n = 0
        for _, s in g.slots do
            if s.dev ~= '' and s.hero == i and not s.locked then
                uiText(g, `P{s.idx}`, x - 30 + n * 22, y + 42, 12, s.color)
                n += 1
            end
        end
    end
    if g.selectT > 0 then
        uiText(g, L.format(g.locale, 'STARTING IN {seconds}', { seconds = math.ceil(g.selectT) }), W / 2, 668, 26, G.WHITE, 0.5)
    else
        uiText(g, 'MOVE: PICK   A: READY   B: BACK   START: JOIN', W / 2, 676, 14, G.hex(0xCFC6D8), 0.5)
    end
end

local function drawEnd(g: Game)
    G.save()
    G.opacity(math.min(0.75, g.modeT))
    G.rect(0, 0, W, H, G.hex(0x140C24))
    G.restore()
    if g.mode == 'win' then
        uiText(g, 'JUMP CITY IS SAFE!', W / 2, 150, 64, G.hex(0xFFE14D), 0.5, G.hex(0xB0122A))
        uiText(g, 'TITANS WIN!', W / 2, 240, 34, G.WHITE, 0.5)
    else
        uiText(g, 'GAME OVER', W / 2, 170, 84, G.hex(0xFF4D5E), 0.5)
    end
    local row = 0
    for _, s in g.slots do
        if s.dev ~= '' then
            local h = HEROES[s.hero]
            local y = 330 + row * 64
            A.portrait(h.key, W / 2 - 200, y + 14, 0.9, g.t)
            uiText(g, `P{s.idx} {tr(g, h.name)}`, W / 2 - 160, y, 22, s.color)
            uiText(g, `{s.score}`, W / 2 + 240, y, 22, G.WHITE, 1)
            row += 1
        end
    end
    if g.modeT > 1.5 and math.floor(g.t * 2.5) % 2 == 0 then
        uiText(g, 'PRESS START', W / 2, 630, 30, G.WHITE, 0.5)
    end
end

local function drawSpeech(g: Game)
    local occupied: {Speech.Box} = {}
    for _,f in g.fighters do
        local v=f.voice
        if f.team==1 and not f.removed and v.time>0 then
            local x=f.x-g.camX
            if x>=-30 and x<=W+30 then
                local height=if f.pose.down>.5 then 30*f.scale else fighterHeight(f)
                local y=math.clamp(f.y-f.z-height-40,166,H-30)
                local box=Speech.place(tr(g,v.text),x,y,occupied)
                table.insert(occupied,box)
                Speech.draw(box,x,y,HEROES[f.hero].color,math.min(1,v.age/.10,v.time/.25))
            end
        end
    end
end

local function drawPlay(g: Game)
    local shake = g.shake
    G.save()
    if shake > 0 then
        G.translate(rnd(-1, 1) * shake * 22, rnd(-1, 1) * shake * 14)
    end
    drawWorld(g)
    drawSpeech(g)
    G.restore()

    if g.goT > 0 and math.floor(g.t * 3) % 2 == 0 then
        uiText(g, 'GO!', W - 150, 300, 56, G.hex(0xFFE14D), 0.5, G.hex(0xB0122A))
        G.poly({ W - 210, 380, W - 110, 380, W - 110, 360, W - 60, 400, W - 110, 440, W - 110, 420, W - 210, 420 }, G.hex(0xFFE14D), 3)
    end
    drawBanner(g)
    drawHud(g)

    if g.continueT > 0 then
        G.save()
        G.opacity(0.6)
        G.rect(0, 0, W, H, G.hex(0x140C24))
        G.restore()
        uiText(g, 'CONTINUE?', W / 2, 250, 64, G.hex(0xFFE14D), 0.5, G.hex(0xB0122A))
        uiText(g, `{math.ceil(g.continueT)}`, W / 2, 340, 90, G.WHITE, 0.5)
        uiText(g, 'PRESS START', W / 2, 470, 26, G.WHITE, 0.5)
    end
    if g.paused then
        G.save()
        G.opacity(0.6)
        G.rect(0, 0, W, H, G.hex(0x140C24))
        G.restore()
        uiText(g, 'PAUSED', W / 2, 270, 72, G.hex(0xFFE14D), 0.5, G.hex(0xB0122A))
        uiText(g, 'START: RESUME    BACK / ESC: QUIT TO TITLE', W / 2, 380, 18, G.WHITE, 0.5)
    end
end

local function drawGame(g: Game)
    if g.mode == 'title' then
        drawTitle(g)
    elseif g.mode == 'tutorial' then
        local state, demo = g.tutorial, g.demo
        if state and demo then
            Tutorial.draw(state, g.locale, g.menuHover, function()
                G.save(); G.translate(8, -54.75); G.scale(1.15, 1.15)
                drawWorld(demo)
                G.restore()
            end, demo.paused, demo.mode == 'title')
        end
    elseif g.mode == 'map' then
        LevelMap.draw(g.locale,g.progress,g.selectedLevel,g.mapCleared,g.resetConfirm,g.resetYes,g.menuHover,g.t)
    elseif g.mode == 'select' then
        drawSelect(g)
    elseif g.mode == 'play' then
        drawPlay(g)
    else
        drawWorld(g)
        drawHud(g)
        drawEnd(g)
    end
end

-- Layout protocol ----------------------------------------------------------------------------------

function init(self: Main, context: Context): boolean
    self.progressBridge=Progress.bridge(context)
    local vm=context:viewModel()
    if vm then
        self.browserGamepads=vm:getString('browserGamepads')
        self.browserKeyboard=vm:getString('browserKeyboard')
        self.browserLanguage=vm:getString('browserLanguage')
        self.languageRevision=vm:getNumber('languageRevision')
        if self.browserLanguage and self.browserLanguage.value=='zh-TW' then self.g.locale='zh-TW' end
    end
    return true
end

function resize(self: Main, size: Vector, scale: number)
    self.size = size
end

function advance(self: Main, seconds: number): boolean
    if self.browserLanguage then
        local value=self.browserLanguage.value
        if value=='en' or value=='zh-TW' then self.g.locale=value :: L.Locale end
    end
    local keys=self.browserKeyboard
    if keys and keys.value~='' then
        local events,newest=BrowserInput.decodeKeyboard(keys.value,self.lastBrowserKeySeq)
        self.lastBrowserKeySeq=newest
        for _,event in events do keyboardEvent(self,event :: any) end
    end
    local pads=self.browserGamepads
    if pads and pads.value~=self.lastBrowserGamepads then
        self.lastBrowserGamepads=pads.value
        local current:{[number]:boolean}={}
        for _,event in BrowserInput.decode(pads.value) do
            current[event.deviceId]=true
            gamepadEvent(self,event)
        end
        for id in self.browserDevices do
            if not current[id] then gamepadDisconnected(self,({deviceId=id} :: any)) end
        end
        self.browserDevices=current
    end
    if Progress.pull(self.g.progress,self.progressBridge) and (self.g.mode=='title' or self.g.mode=='map') then
        self.g.selectedLevel=Progress.unlocked(self.g.progress)
        self.g.mapCleared=0
    end
    update(self.g, seconds)
    Progress.push(self.g.progress,self.progressBridge)
    return true
end

function draw(self: Main, renderer: Renderer)
    G.begin(renderer)
    local sw = if self.size.x > 0 then self.size.x else W
    local sh = if self.size.y > 0 then self.size.y else H
    local sc = math.min(sw / W, sh / H)
    local ox = (sw - W * sc) / 2
    local oy = (sh - H * sc) / 2
    G.rect(0, 0, sw, sh, G.BLACK)
    G.save()
    G.translate(ox, oy)
    G.scale(sc, sc)
    G.clipRect(0, 0, W, H)
    drawGame(self.g)
    G.restore()
end

local function screenPosition(self: Main, position: Vector): Vector
    local sw = if self.size.x > 0 then self.size.x else W
    local sh = if self.size.y > 0 then self.size.y else H
    local sc = math.min(sw / W, sh / H)
    local x = (position.x - (sw - W * sc) / 2) / sc
    local y = (position.y - (sh - H * sc) / 2) / sc
    return Vector.xy(x, y)
end

local function languageAt(self: Main, position: Vector): L.Locale?
    if self.g.mode ~= 'title' then return nil end
    local point = screenPosition(self, position)
    local x, y = point.x, point.y
    if y < LANGUAGE_Y + 4 or y > LANGUAGE_Y + 54 then return nil end
    if x >= LANGUAGE_X + 4 and x <= LANGUAGE_X + 120 then return 'en' end
    if x >= LANGUAGE_X + 124 and x <= LANGUAGE_X + 306 then return 'zh-TW' end
    return nil
end

local function chooseLanguage(self: Main, locale: L.Locale)
    self.g.locale=locale
    if self.browserLanguage then self.browserLanguage.value=locale end
    if self.languageRevision then self.languageRevision.value+=1 end
end

local function menuAt(self: Main, position: Vector): string?
    local p = screenPosition(self, position)
    return LevelMap.actionAt(self.g.mode,p.x,p.y,self.g.resetConfirm) or Tutorial.actionAt(self.g.mode, p.x, p.y)
end

function pointerDown(self: Main, e: PointerEvent)
    local target = languageAt(self, e.position)
    if target and self.languagePointer == -1 then
        self.languagePointer = e.id
        self.languageTarget = target
        e:hit()
    else
        local action = menuAt(self, e.position)
        if action and self.menuPointer == -1 then
            self.menuPointer, self.menuTarget = e.id, action
            e:hit()
        end
    end
end

function pointerMove(self: Main, e: PointerEvent)
    local target = languageAt(self, e.position)
    self.g.languageHover = if target == 'en' then 1 elseif target == 'zh-TW' then 2 else 0
    if target or self.languagePointer == e.id then e:hit() end
    local action = menuAt(self, e.position)
    self.g.menuHover = action or ''
    if action or self.menuPointer == e.id then e:hit() end
end

function pointerUp(self: Main, e: PointerEvent)
    if self.menuPointer == e.id then
        local action = menuAt(self, e.position)
        if action and action == self.menuTarget then menuAction(self.g, action) end
        self.menuPointer, self.menuTarget = -1, nil
        e:hit()
    end
    if self.languagePointer ~= e.id then return end
    local target = languageAt(self, e.position)
    if target and target == self.languageTarget then chooseLanguage(self,target) end
    self.languagePointer = -1
    self.languageTarget = nil
    e:hit()
end

function pointerExit(self: Main, e: PointerEvent)
    self.g.languageHover = 0
    self.g.menuHover = ''
    if self.menuPointer == e.id then self.menuPointer, self.menuTarget = -1, nil; e:hit() end
    if self.languagePointer == e.id then
        self.languagePointer = -1
        self.languageTarget = nil
        e:hit()
    end
end

function keyboardEvent(self: Main, e: KeyboardEvent): boolean
    if e.key==82 and self.g.mode=='map' then
        if e.phase=='down' and not self.g.resetConfirm then menuAction(self.g,'reset') end
        return true
    end
    if e.key == 72 and self.g.mode == 'title' and e.phase == 'down' then
        beginTutorial(self.g, 'title')
        return true
    end
    if e.key == 258 then -- Tab: language, only on the title screen.
        if e.phase == 'up' then self.languageKeyHeld = false
        elseif e.phase == 'down' and not self.languageKeyHeld then
            self.languageKeyHeld = true
            if self.g.mode == 'title' then chooseLanguage(self,L.toggle(self.g.locale)) end
        end
        return self.g.mode == 'title'
    end
    local bind = KEYS[e.key]
    if bind == nil or e.phase == 'repeat' then
        return false
    end
    local g = self.g
    local d = device(g, bind.dev, if bind.dev == 'kb1' then 'KEYBOARD 1' else 'KEYBOARD 2')
    setButton(d, bind.btn, e.phase == 'down')
    d.mx = (if d.held['R'] then 1 else 0) - (if d.held['L'] then 1 else 0)
    d.my = (if d.held['D'] then 1 else 0) - (if d.held['U'] then 1 else 0)
    if d.mx ~= 0 and d.my ~= 0 then
        d.mx *= 0.7071
        d.my *= 0.7071
    end
    return true
end

local function padId(n: number): string
    return `pad{n}`
end

function gamepadConnected(self: Main, e: GamepadConnected)
    device(self.g, padId(e.deviceId), `CONTROLLER {e.deviceId}`)
end

function gamepadDisconnected(self: Main, e: GamepadDisconnected)
    local g = self.g
    local id = padId(e.deviceId)
    g.devs[id] = nil
    -- a pulled controller pauses the game rather than dropping the player
    if g.mode == 'play' and slotOf(g, id) ~= nil then
        g.paused = true
    end
end

function gamepadEvent(self: Main, e: GamepadEvent)
    local d = device(self.g, padId(e.deviceId), `CONTROLLER {e.deviceId}`)
    local std = e.isStandardMapping
    local wasLanguageHeld = d.held['language'] == true
    local languageDown = if std then e.leftShoulder == true else e:buttonPressed(5)
    setButton(d, 'language', languageDown)
    if self.g.mode == 'title' and languageDown and not wasLanguageHeld then
        chooseLanguage(self,L.toggle(self.g.locale))
    end
    local stick = e.leftStick
    local sx = if math.abs(stick.x) > 0.28 then stick.x else 0
    local sy = if math.abs(stick.y) > 0.28 then stick.y else 0
    local left = if std then e.dpadLeft else e:buttonPressed(15)
    local right = if std then e.dpadRight else e:buttonPressed(16)
    local up = if std then e.dpadUp else e:buttonPressed(13)
    local down = if std then e.dpadDown else e:buttonPressed(14)
    local mx = sx + (if right then 1 else 0) - (if left then 1 else 0)
    local my = sy + (if down then 1 else 0) - (if up then 1 else 0)
    d.mx = math.clamp(mx, -1, 1)
    d.my = math.clamp(my, -1, 1)
    local length = math.sqrt(d.mx * d.mx + d.my * d.my)
    if length > 1 then
        d.mx /= length
        d.my /= length
    end
    setButton(d, 'L', d.mx < -(if d.held['L'] then .3 else .65))
    setButton(d, 'R', d.mx > (if d.held['R'] then .3 else .65))
    setButton(d, 'U', d.my < -(if d.held['U'] then .3 else .65))
    setButton(d, 'D', d.my > (if d.held['D'] then .3 else .65))
    if std then
        setButton(d, 'a', e.south)
        setButton(d, 'b', e.east or e.rightShoulder)
        setButton(d, 'x', e.west)
        setButton(d, 'y', e.north)
        setButton(d, 'rt', e.rightTriggerPressed or e.rightTrigger > 0.5)
        setButton(d, 'start', e.start or e.forward)
        setButton(d, 'back', e.back)
    else
        setButton(d, 'a', e:buttonPressed(1))
        setButton(d, 'b', e:buttonPressed(2) or e:buttonPressed(6))
        setButton(d, 'x', e:buttonPressed(3))
        setButton(d, 'y', e:buttonPressed(4))
        setButton(d, 'rt', e:buttonPressed(8))
        setButton(d, 'start', e:buttonPressed(10))
        setButton(d, 'back', e:buttonPressed(9))
    end
end

local function create(context: Context): Layout<Main>
    return {
        g = newGame(),
        progressBridge = Progress.bridge(nil),
        browserGamepads = nil, lastBrowserGamepads = '', browserDevices = {},
        browserKeyboard = nil, lastBrowserKeySeq = 0,
        browserLanguage = nil, languageRevision = nil,
        size = Vector.xy(0, 0),
        languagePointer = -1, languageTarget = nil, languageKeyHeld = false,
        menuPointer = -1, menuTarget = nil,
        init = init,
        resize = resize,
        advance = advance,
        draw = draw,
        keyboardEvent = keyboardEvent,
        pointerDown = pointerDown, pointerMove = pointerMove,
        pointerUp = pointerUp, pointerExit = pointerExit,
        gamepadConnected = gamepadConnected,
        gamepadDisconnected = gamepadDisconnected,
        gamepadEvent = gamepadEvent,
    }
end

-- Plain module export lets regression tests drive the same callbacks as Rive.
return { create = create }
