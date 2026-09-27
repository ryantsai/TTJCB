local Game = require('game')
local L = require('localization')
local G = require('gfx')
local C = require('campaign')
local Powers = require('powers')
local glyphs = require('tc_glyphs')

local function step(app: any, frames: number)
    for _ = 1, frames do app.advance(app, 1 / 60) end
end

local function press(app: any, code: number)
    app.keyboardEvent(app, { key = code, phase = 'down' })
    step(app, 1)
    app.keyboardEvent(app, { key = code, phase = 'up' })
    step(app, 1)
end

local function pointer(id: number, x: number, y: number): any
    return { id = id, position = Vector.xy(x, y), hit = function(self: any) end }
end

local function pad(app: any, down: boolean)
    app.gamepadEvent(app, {
        deviceId = 0, isStandardMapping = true, leftStick = Vector.xy(0, 0),
        dpadLeft = false, dpadRight = false, dpadUp = false, dpadDown = false,
        south = false, east = false, west = false, north = false,
        leftShoulder = down, rightShoulder = false, rightTriggerPressed = false,
        rightTrigger = 0, start = false, forward = false, back = false,
    })
    step(app, 1)
end

return function(): Tests
    return function(test: Tester)
        test.case('browser language hydrates before play and explicit choices publish one revision', function(expect)
            local app: any = (Game.create :: any)(nil)
            local props: any = { browserLanguage = {value='zh-TW'}, languageRevision = {value=0} }
            local vm: any = {
                getString = function(self: any, key: string) return props[key] end,
                getNumber = function(self: any, key: string) return props[key] end,
                getBoolean = function(self: any, key: string) return props[key] end,
            }
            app.init(app, {viewModel = function(self: any) return vm end})
            step(app, 1)
            expect(app.g.locale).is('zh-TW')
            expect(props.languageRevision.value).is(0)
            -- Another tab updates the preference without claiming a local choice.
            props.browserLanguage.value='en';step(app,1)
            expect(app.g.locale).is('en')
            expect(props.languageRevision.value).is(0)
            press(app,258)
            expect(app.g.locale).is('zh-TW')
            expect(props.browserLanguage.value).is('zh-TW')
            expect(props.languageRevision.value).is(1)
            local chinese=pointer(1,1160,46)
            app.pointerDown(app,chinese);app.pointerUp(app,chinese)
            expect(props.languageRevision.value).is(2)
            pad(app,true);pad(app,true)
            expect(app.g.locale).is('en')
            expect(props.languageRevision.value).is(3)
        end)
        test.case('Taiwan terminology covers all heroes, enemies, stages and powers', function(expect)
            local names = { ROBIN = '羅賓', CYBORG = '鋼骨', STARFIRE = '俏嬌娃', RAVEN = '酷姬', ['BEAST BOY'] = '人皮獸' } :: { [string]: string }
            for english, chinese in names do
                expect(L.text('zh-TW', english)).is(chinese)
                expect(L.text('en', english)).is(english)
            end
            for _, enemy in C.enemies do expect(L.catalog[enemy.name] ~= nil).is(true) end
            for _, stage in C.stages do
                expect(L.catalog[stage.name] ~= nil).is(true)
                expect(L.catalog[stage.subtitle] ~= nil).is(true)
            end
            for _, roster in { Powers.secondary, Powers.ultimate } do
                for _, power in roster do expect(L.catalog[power.name] ~= nil).is(true) end
            end
            expect(L.format('zh-TW', '{stage}/4  {name}  -  WAVE {wave}/4', { stage = 4, name = L.text('zh-TW', 'SLADE HQ'), wave = 3 })).is('4/4  史萊德總部  第 3/4 波')
            expect(L.format('en', 'STARTING IN {seconds}', { seconds = 2 })).is('STARTING IN 2')
            expect(L.text('zh-TW', 'P1')).is('P1')
            expect(L.text('zh-TW', 'Skill 1')).is('招式1')
            expect(L.text('zh-TW', 'Skill 2')).is('招式2')
            expect(L.text('zh-TW', 'Super')).is('絕招')
            for _,label in {'Skill 1','Skill 2','Super'} do
                expect(G.textWidth(label,17)).lessThan(250)
                expect(G.textWidth(L.text('zh-TW',label),17)).lessThan(250)
            end
        end)

        test.case('every localized character has a bundled Noto Sans TC outline and placeholders match', function(expect)
            local function covered(value: string)
                for _, code in utf8.codes(value) do
                    if code > 127 then expect(glyphs[code] ~= nil).is(true) end
                end
            end
            covered(L.languageLabel)
            for source, translated in L.catalog do
                covered(translated)
                local a, b = {}, {}
                for name in string.gmatch(source, '{([%w_]+)}') do table.insert(a, name) end
                for name in string.gmatch(translated, '{([%w_]+)}') do table.insert(b, name) end
                table.sort(a)
                table.sort(b)
                expect(table.concat(a, ',')).is(table.concat(b, ','))
            end
            -- CJK measurement counts characters, not the three UTF-8 bytes each.
            expect(math.abs(G.textWidth('羅賓', 20) - 41) < .001).is(true)
            expect(G.textWidth('B: 超級音波砲', 14)).lessThan(250)
            expect(G.textWidth('', 20)).is(0)
        end)

        test.case('Tab switches once per press without joining and locale survives returning to title', function(expect)
            local app: any = (Game.create :: any)(nil)
            app.g.tutorialSeen = true
            app.keyboardEvent(app, { key = 258, phase = 'down' })
            app.keyboardEvent(app, { key = 258, phase = 'repeat' })
            app.keyboardEvent(app, { key = 258, phase = 'down' })
            step(app, 1)
            expect(app.g.locale).is('zh-TW')
            expect(app.g.mode).is('title')
            expect(app.g.slots[1].dev).is('')
            app.keyboardEvent(app, { key = 258, phase = 'up' })
            press(app, 257)
            press(app, 258)
            expect(app.g.mode).is('map')
            expect(app.g.locale).is('zh-TW')
            press(app, 256)
            step(app, 1)
            expect(app.g.mode).is('title')
            expect(app.g.locale).is('zh-TW')
            press(app, 258)
            expect(app.g.locale).is('en')
            local other: any = (Game.create :: any)(nil)
            expect(other.g.locale).is('en')
        end)

        test.case('language clicks respect letterboxing, release location and pointer identity', function(expect)
            local app: any = (Game.create :: any)(nil)
            app.g.tutorialSeen = true
            app.resize(app, Vector.xy(1600, 1000), 1)
            -- Design point 1160,46 at scale 1.25, with a 50px top letterbox.
            local chinese = pointer(1, 1450, 107.5)
            app.pointerDown(app, chinese)
            app.pointerUp(app, pointer(2, 1450, 107.5))
            expect(app.g.locale).is('en')
            app.pointerUp(app, chinese)
            expect(app.g.locale).is('zh-TW')
            expect(app.g.mode).is('title')
            local english = pointer(1, 1265, 107.5)
            app.pointerDown(app, english)
            app.pointerUp(app, pointer(1, 900, 900))
            expect(app.g.locale).is('zh-TW')
            app.pointerDown(app, english)
            app.pointerExit(app, english)
            app.pointerUp(app, english)
            expect(app.g.locale).is('zh-TW')
            app.pointerDown(app, english)
            app.pointerUp(app, english)
            expect(app.g.locale).is('en')
            press(app, 257)
            app.pointerDown(app, chinese)
            app.pointerUp(app, chinese)
            expect(app.g.locale).is('en')
        end)

        test.case('LB switches on its rising edge only and cannot alter gameplay language', function(expect)
            local app: any = (Game.create :: any)(nil)
            app.g.tutorialSeen = true
            pad(app, true)
            pad(app, true)
            expect(app.g.locale).is('zh-TW')
            expect(app.g.mode).is('title')
            expect(app.g.slots[1].dev).is('')
            pad(app, false)
            pad(app, true)
            expect(app.g.locale).is('en')
            pad(app, false)
            press(app, 257) -- Level map.
            press(app, 257) -- Character select.
            press(app, 257) -- Ready.
            press(app, 257) -- Start.
            step(app, 80)
            pad(app, true)
            expect(app.g.mode).is('play')
            expect(app.g.locale).is('en')
            expect(app.g.paused).is(false)
            expect(app.g.slots[2].dev).is('')
        end)

        test.case('Chinese boss banners and map returns work through all four stages', function(expect)
            local app: any = (Game.create :: any)(nil)
            app.g.tutorialSeen = true
            press(app, 258)
            press(app, 257) -- Level map.
            press(app, 257) -- Character select.
            press(app, 257) -- Ready.
            press(app, 257) -- Start.
            step(app, 80)
            expect(app.g.bannerSub).is('雀躍城 / 街頭掃蕩')
            local g = app.g
            local hero = g.slots[1].fighter
            hero.invuln = 10000
            for _, index in { 4, 8, 12, 16 } do
                local cp = C.checkpoints[index]
                g.mode='play';g.runLevel=cp.stage
                g.fighters = { hero }
                g.shots = {}
                g.pending = {}
                g.cp = index
                g.lockX = -1
                g.camX = cp.x
                hero.hitPause = 0
                hero.x = g.camX + 600
                step(app, 1)
                g.waveT = 100
                step(app, 1)
                expect(g.banner).is(L.text('zh-TW', C.enemies[cp.spawns[1].kind].name) .. '！')
                g.fighters = { hero }
                step(app, 1)
                if index < 16 then
                    expect(g.mode).is('map')
                    expect(g.mapCleared).is(cp.stage)
                    expect(g.selectedLevel).is(cp.stage+1)
                    expect(g.progress.cleared).is(cp.stage)
                else
                    expect(g.mode).is('win')
                end
            end
        end)
    end
end
