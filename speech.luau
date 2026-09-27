-- Comic bubbles in screen coordinates: Unicode wrapping, safe HUD margins,
-- and collision placement shared with the native visual checks.
local G = require('gfx')
local S = {}
S.size = 16
S.lineHeight = 22
S.maxWidth = 224

export type Box = { x:number, y:number, w:number, h:number, lines:{string} }

function S.wrap(text: string): { string }
    local tokens: {string} = {}
    if #text==utf8.len(text) then
        for word in string.gmatch(text,'%S+') do table.insert(tokens,word) end
    else
        for _,code in utf8.codes(text) do table.insert(tokens,utf8.char(code)) end
    end
    local space = if #text==utf8.len(text) then ' ' else ''
    local lines: {string} = {}
    local line: string = ''
    for _,token in tokens do
        local candidate = if line=='' then token else line..space..token
        if G.textWidth(candidate,S.size)>S.maxWidth and line~='' then
            table.insert(lines,line)
            line=token
        else line=candidate end
    end
    if line~='' then table.insert(lines,line) end
    return lines
end

function S.overlaps(a: Box, b: Box): boolean
    return a.x<b.x+b.w+12 and a.x+a.w+12>b.x and a.y<b.y+b.h+16 and a.y+a.h+16>b.y
end

function S.place(text: string, anchorX: number, anchorY: number, occupied: {Box}): Box
    local lines = S.wrap(text)
    local width = 100
    for _,line in lines do width=math.max(width,G.textWidth(line,S.size)+30) end
    local height = #lines*S.lineHeight+24
    local x = math.clamp(anchorX-width/2,14,G.W-width-14)
    local y = math.clamp(anchorY-height-18,166,G.H-height-18)
    -- A high jump can leave no room above the head. Move beside the speaker
    -- instead of clamping a wide bubble over the airborne character.
    if anchorY-height-18<166 then
        x=math.clamp(if anchorX<G.W/2 then anchorX+80 else anchorX-width-80,14,G.W-width-14)
    end
    local result: Box = {x=x,y=y,w=width,h=height,lines=lines}
    -- At most two characters speak at once. Prefer a small sideways shift;
    -- if the street edge blocks it, use a separate row below the HUD.
    for _,other in occupied do
        if S.overlaps(result,other) then
            local left,right=other.x-width-14,other.x+other.w+14
            if left>=14 and (right>G.W-width-14 or math.abs(left-x)<math.abs(right-x)) then result.x=left
            elseif right<=G.W-width-14 then result.x=right
            elseif other.y-height-18>=166 then result.y=other.y-height-18
            else result.y=math.min(G.H-height-18,other.y+other.h+18) end
        end
    end
    return result
end

function S.draw(box: Box, anchorX: number, anchorY: number, color: Color, alpha: number)
    local x,y,w,h=box.x,box.y,box.w,box.h
    local paper=G.hex(0xFFFBEF)
    local side=anchorX<x or anchorX>x+w
    local below=anchorY>=y+h/2
    local edgeY=if below then y+h else y
    local baseX=math.clamp(anchorX,x+20,x+w-20)
    local tipX=math.clamp(anchorX,baseX-30,baseX+30)
    local tipY=if below then math.min(anchorY,edgeY+22) else math.max(166,edgeY-18)
    local sideX=if anchorX<x then x else x+w
    local sideY=math.clamp(anchorY,y+20,y+h-20)
    G.save()
    G.opacity(alpha)
    G.rrect(x+4,y+5,w,h,12,G.fade(G.INK,.4))
    if side then
        local tx=if anchorX<x then math.max(anchorX,x-24) else math.min(anchorX,x+w+24)
        local ty=math.clamp(anchorY,math.max(166,sideY-16),sideY+16)
        G.poly({sideX,sideY-9,tx,ty,sideX,sideY+9},paper,2.5)
    else
        G.poly({baseX-9,edgeY,tipX,tipY,baseX+9,edgeY},paper,2.5)
    end
    G.rrect(x,y,w,h,12,paper,2.5)
    if side then G.line(sideX,sideY-7,sideX,sideY+7,3,paper)
    else G.line(baseX-7,edgeY,baseX+7,edgeY,3,paper) end
    G.rrect(x+12,y+8,w-24,3,1.5,color)
    for i,line in box.lines do G.text(line,x+w/2,y+18+(i-1)*S.lineHeight,S.size,G.INK,.5,paper) end
    G.restore()
end

return S
