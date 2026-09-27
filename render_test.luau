local G=require('gfx')

-- Capture native Path submissions while avoiding a GPU dependency in unit tests.
local function recorder():any
    return {
        paths={},
        save=function(self:any) end,
        restore=function(self:any) end,
        transform=function(self:any,m:Mat2D) end,
        drawPath=function(self:any,p:Path,paint:Paint) table.insert(self.paths,p) end,
    }
end

return function():Tests
    return function(test:Tester)
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
