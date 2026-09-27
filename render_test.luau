local G=require('gfx')
local Game=require('game')

-- Capture native Path submissions while avoiding a GPU dependency in unit tests.
local function recorder():any
    return {
        paths={},backdropOpacity={},
        save=function(self:any) end,
        restore=function(self:any) end,
        transform=function(self:any,m:Mat2D) end,
        clipPath=function(self:any,p:Path) end,
        -- Model the browser backend's ignored script-level opacity modulation.
        modulateOpacity=function(self:any,alpha:number) end,
        modulateColor=function(self:any,c:Color) end,
        drawPath=function(self:any,p:Path,paint:Paint)
            table.insert(self.paths,p)
            if not paint.gradient and paint.style=='fill' and bit32.band(paint.color,0xFFFFFF)==0x140C24 then
                table.insert(self.backdropOpacity,Color.opacity(paint.color))
            end
        end,
    }
end

return function():Tests
    return function(test:Tester)
        test.case('menu and pause shading leaves the scene visible without renderer opacity modulation',function(expect)
            for _,locale in {'en','zh-TW','ja'} do
                for _,screen in {'title','select','paused','continue','win','over'} do
                    local app:any=(Game.create :: any)(nil)
                    local g=app.g
                    g.locale=locale;g.modeT=1
                    g.mode=if screen=='paused' or screen=='continue' then 'play' else screen
                    g.paused=screen=='paused';g.continueT=if screen=='continue' then 5 else 0
                    local r=recorder();app.draw(app,r)
                    expect(#r.backdropOpacity).is(1)
                    local expected=if screen=='title' then .45 elseif screen=='win' or screen=='over' then .75 else .6
                    expect(math.abs(r.backdropOpacity[1]-expected)).lessThan(.005)
                end
            end
        end)
        test.case('text reuses native run geometry across colors, sizes, positions and frames',function(expect)
            local r=recorder()
            G.begin(r);G.text('BOOYAH!',10,20,16,G.WHITE)
            expect(#r.paths).is(2)
            local outline=r.paths[1]
            expect(#outline).greaterThan(0)
            local commands=#outline
            table.clear(r.paths)
            G.begin(r);G.text('BOOYAH!',600,80,30,G.INK,1)
            expect(#r.paths).is(2)
            expect(r.paths[1]==outline).is(true)
            expect(#outline).is(commands)
        end)
        test.case('Japanese and Taiwan glyph runs keep separate regional caches',function(expect)
            local r=recorder()
            G.setLocale('zh-TW');G.begin(r);G.text('強',0,0,20,G.WHITE)
            local tc=r.paths[1];table.clear(r.paths)
            G.setLocale('ja');G.begin(r);G.text('強',0,0,20,G.WHITE)
            local jp=r.paths[1];expect(jp==tc).is(false);expect(#jp).greaterThan(0)
            table.clear(r.paths)
            G.setLocale('zh-TW');G.begin(r);G.text('強',0,0,20,G.WHITE)
            expect(r.paths[1]==tc).is(true)
            table.clear(r.paths)
            G.setLocale('ja');G.begin(r);G.text('強',0,0,20,G.WHITE)
            expect(r.paths[1]==jp).is(true)
            G.setLocale('en')
        end)
        test.case('mixed Taiwan text batches glyphs and cache eviction never mutates submitted paths',function(expect)
            local r=recorder()
            G.begin(r);G.text('4 人遊玩  剩餘敵人 12',10,20,16,G.WHITE)
            expect(#r.paths).is(4)
            local ascii,tc=r.paths[1],r.paths[2]
            local asciiCount,tcCount=#ascii,#tc
            expect(tcCount).greaterThan(asciiCount)
            for score=1,600 do
                G.begin(r);G.text(`{score*10}`,0,0,14,G.WHITE)
                table.clear(r.paths)
            end
            G.begin(r);G.text('4 人遊玩  剩餘敵人 12',10,20,16,G.WHITE)
            expect(#r.paths).is(4)
            expect(r.paths[1]==ascii).is(false)
            expect(#ascii).is(asciiCount)
            expect(#tc).is(tcCount)
            expect(#r.paths[1]).is(asciiCount)
            expect(#r.paths[2]).is(tcCount)
        end)
    end
end
