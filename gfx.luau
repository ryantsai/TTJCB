-- Drawing primitives shared by every screen.
--
-- Two renderer rules shape this module:
--  * A Path must not be mutated after it is drawn in the same frame, so
--    dynamic shapes come from a pool that is rewound once per frame.
--  * Only clockwise contours fill (in path space), so poly() fixes winding.
-- Fixed shapes (circle, square, glyphs) are built once and placed with
-- transforms, which keeps the per-frame path count low.
local font = require('font')
local tcGlyphs = require('tc_glyphs')

local G = {}

G.W = 1280
G.H = 720

local R: Renderer = (nil :: any)

local fillPaint = Paint.with({ style = 'fill', color = Color.rgb(255, 255, 255) })
local strokePaint = Paint.with({
    style = 'stroke',
    cap = 'round',
    join = 'round',
    thickness = 2,
    color = Color.rgb(0, 0, 0),
})
local gradPaint = Paint.with({ style = 'fill' })

local pool: { Path } = {}
local poolIdx = 0

local unitCircle = Path.new()
local unitSquare = Path.new()
local glyphPaths: { [string]: Path } = {}
local tcPaths: { [number]: Path } = {}

G.INK = Color.rgb(24, 14, 36)
G.WHITE = Color.rgb(255, 255, 255)
G.BLACK = Color.rgb(0, 0, 0)

function G.hex(h: number): Color
    return Color.rgb(bit32.band(bit32.rshift(h, 16), 255), bit32.band(bit32.rshift(h, 8), 255), bit32.band(h, 255))
end

-- k < 0 darkens toward black, k > 0 lightens toward white.
function G.shade(c: Color, k: number): Color
    if k < 0 then
        return Color.lerp(c, G.BLACK, -k)
    end
    return Color.lerp(c, G.WHITE, k)
end

function G.fade(c: Color, a: number): Color
    return Color.opacity(c, math.clamp(a, 0, 1)) :: Color
end

-- Build the fixed shapes -----------------------------------------------------

do
    -- Unit circle from four cubic arcs, wound clockwise (y down).
    local k = 0.5523
    unitCircle:moveTo(Vector.xy(1, 0))
    unitCircle:cubicTo(Vector.xy(1, k), Vector.xy(k, 1), Vector.xy(0, 1))
    unitCircle:cubicTo(Vector.xy(-k, 1), Vector.xy(-1, k), Vector.xy(-1, 0))
    unitCircle:cubicTo(Vector.xy(-1, -k), Vector.xy(-k, -1), Vector.xy(0, -1))
    unitCircle:cubicTo(Vector.xy(k, -1), Vector.xy(1, -k), Vector.xy(1, 0))
    unitCircle:close()

    unitSquare:moveTo(Vector.xy(0, 0))
    unitSquare:lineTo(Vector.xy(1, 0))
    unitSquare:lineTo(Vector.xy(1, 1))
    unitSquare:lineTo(Vector.xy(0, 1))
    unitSquare:close()

    for ch, def in font.glyphs do
        local p = Path.new()
        for _, strokeDef in string.split(def, '|') do
            local first = true
            for _, pt in string.split(strokeDef, ' ') do
                local xy = string.split(pt, ',')
                local v = Vector.xy(tonumber(xy[1]) or 0, tonumber(xy[2]) or 0)
                if first then
                    p:moveTo(v)
                    first = false
                else
                    p:lineTo(v)
                end
            end
        end
        glyphPaths[ch] = p
    end
end

-- Frame and transform state --------------------------------------------------

function G.begin(r: Renderer)
    R = r
    poolIdx = 0
end

local function newPath(): Path
    poolIdx += 1
    local p = pool[poolIdx]
    if p == nil then
        p = Path.new()
        pool[poolIdx] = p
    else
        p:reset()
    end
    return p
end

function G.save()
    R:save()
end

function G.restore()
    R:restore()
end

function G.translate(x: number, y: number)
    R:transform(Mat2D.withTranslation(x, y))
end

function G.scale(sx: number, sy: number)
    R:transform(Mat2D.withScale(sx, sy))
end

function G.rotate(a: number)
    R:transform(Mat2D.withRotation(a))
end

function G.transform(m: Mat2D)
    R:transform(m)
end

function G.opacity(a: number)
    R:modulateOpacity(math.clamp(a, 0, 1))
end

function G.tint(c: Color)
    R:modulateColor(c)
end

-- Clip following draws to an ellipse. Pair with G.save()/G.restore().
function G.clipEllipse(x: number, y: number, rx: number, ry: number)
    local k = 0.5523
    local p = newPath()
    p:moveTo(Vector.xy(x + rx, y))
    p:cubicTo(Vector.xy(x + rx, y + ry * k), Vector.xy(x + rx * k, y + ry), Vector.xy(x, y + ry))
    p:cubicTo(Vector.xy(x - rx * k, y + ry), Vector.xy(x - rx, y + ry * k), Vector.xy(x - rx, y))
    p:cubicTo(Vector.xy(x - rx, y - ry * k), Vector.xy(x - rx * k, y - ry), Vector.xy(x, y - ry))
    p:cubicTo(Vector.xy(x + rx * k, y - ry), Vector.xy(x + rx, y - ry * k), Vector.xy(x + rx, y))
    p:close()
    R:clipPath(p)
end

-- Clip to a rounded rectangle. Pair with G.save()/G.restore().
function G.clipRRect(x: number, y: number, w: number, h: number, rad: number)
    local r = math.min(rad, w / 2, h / 2)
    local p = newPath()
    p:moveTo(Vector.xy(x + r, y))
    p:lineTo(Vector.xy(x + w - r, y))
    p:quadTo(Vector.xy(x + w, y), Vector.xy(x + w, y + r))
    p:lineTo(Vector.xy(x + w, y + h - r))
    p:quadTo(Vector.xy(x + w, y + h), Vector.xy(x + w - r, y + h))
    p:lineTo(Vector.xy(x + r, y + h))
    p:quadTo(Vector.xy(x, y + h), Vector.xy(x, y + h - r))
    p:lineTo(Vector.xy(x, y + r))
    p:quadTo(Vector.xy(x, y), Vector.xy(x + r, y))
    p:close()
    R:clipPath(p)
end

-- Clip to a polygon (winding fixed like poly). Pair with G.save()/G.restore().
function G.clipPoly(pts: { number })
    local n = #pts // 2
    local area = 0
    for i = 1, n do
        local j = i % n + 1
        area += pts[i * 2 - 1] * pts[j * 2] - pts[j * 2 - 1] * pts[i * 2]
    end
    local p = newPath()
    if area >= 0 then
        p:moveTo(Vector.xy(pts[1], pts[2]))
        for i = 2, n do
            p:lineTo(Vector.xy(pts[i * 2 - 1], pts[i * 2]))
        end
    else
        p:moveTo(Vector.xy(pts[n * 2 - 1], pts[n * 2]))
        for i = n - 1, 1, -1 do
            p:lineTo(Vector.xy(pts[i * 2 - 1], pts[i * 2]))
        end
    end
    p:close()
    R:clipPath(p)
end

function G.clipRect(x: number, y: number, w: number, h: number)
    local p = newPath()
    p:moveTo(Vector.xy(x, y))
    p:lineTo(Vector.xy(x + w, y))
    p:lineTo(Vector.xy(x + w, y + h))
    p:lineTo(Vector.xy(x, y + h))
    p:close()
    R:clipPath(p)
end

-- Filled primitives ----------------------------------------------------------

function G.ellipse(x: number, y: number, rx: number, ry: number, c: Color)
    if rx <= 0 or ry <= 0 then
        return
    end
    R:save()
    R:transform(Mat2D.withScaleAndTranslation(rx, ry, x, y))
    fillPaint.color = c
    R:drawPath(unitCircle, fillPaint)
    R:restore()
end

function G.circle(x: number, y: number, r: number, c: Color)
    G.ellipse(x, y, r, r, c)
end

-- Ellipse with a cartoon ink outline.
function G.oellipse(x: number, y: number, rx: number, ry: number, c: Color, ow: number?)
    local o = ow or 2.5
    G.ellipse(x, y, rx + o, ry + o, G.INK)
    G.ellipse(x, y, rx, ry, c)
end

function G.rect(x: number, y: number, w: number, h: number, c: Color)
    if w <= 0 or h <= 0 then
        return
    end
    R:save()
    R:transform(Mat2D.withScaleAndTranslation(w, h, x, y))
    fillPaint.color = c
    R:drawPath(unitSquare, fillPaint)
    R:restore()
end

-- Polygon from a flat list {x1, y1, x2, y2, ...}. Winding is fixed so the
-- shape always fills. outline > 0 strokes an ink border behind it.
function G.poly(pts: { number }, c: Color, outline: number?)
    local n = #pts // 2
    if n < 3 then
        return
    end
    local area = 0
    for i = 1, n do
        local j = i % n + 1
        area += pts[i * 2 - 1] * pts[j * 2] - pts[j * 2 - 1] * pts[i * 2]
    end
    local p = newPath()
    if area >= 0 then
        p:moveTo(Vector.xy(pts[1], pts[2]))
        for i = 2, n do
            p:lineTo(Vector.xy(pts[i * 2 - 1], pts[i * 2]))
        end
    else
        p:moveTo(Vector.xy(pts[n * 2 - 1], pts[n * 2]))
        for i = n - 1, 1, -1 do
            p:lineTo(Vector.xy(pts[i * 2 - 1], pts[i * 2]))
        end
    end
    p:close()
    if outline and outline > 0 then
        strokePaint.color = G.INK
        strokePaint.thickness = outline * 2
        R:drawPath(p, strokePaint)
    end
    fillPaint.color = c
    R:drawPath(p, fillPaint)
end

-- Closed silhouette: start x/y followed by cubic control/control/end
-- triples. Curves keep faces and hair smooth at both HUD and full-body sizes.
function G.contour(pts: { number }, c: Color, outline: number?)
    local p = newPath()
    -- Match poly's clockwise fill convention, including mirrored silhouettes.
    local area = 0
    for i = 1, #pts, 2 do
        local j = (i + 1) % #pts + 1
        area += pts[i] * pts[j + 1] - pts[j] * pts[i + 1]
    end
    if area >= 0 then
        p:moveTo(Vector.xy(pts[1], pts[2]))
        for i = 3, #pts, 6 do
            p:cubicTo(Vector.xy(pts[i], pts[i + 1]), Vector.xy(pts[i + 2], pts[i + 3]), Vector.xy(pts[i + 4], pts[i + 5]))
        end
    else
        p:moveTo(Vector.xy(pts[#pts - 1], pts[#pts]))
        for i = #pts - 5, 3, -6 do
            p:cubicTo(Vector.xy(pts[i + 2], pts[i + 3]), Vector.xy(pts[i], pts[i + 1]), Vector.xy(pts[i - 2], pts[i - 1]))
        end
    end
    p:close()
    if outline and outline > 0 then
        strokePaint.color = G.INK
        strokePaint.thickness = outline * 2
        R:drawPath(p, strokePaint)
    end
    fillPaint.color = c
    R:drawPath(p, fillPaint)
end

-- Rounded rectangle, clockwise.
function G.rrect(x: number, y: number, w: number, h: number, rad: number, c: Color, outline: number?)
    if w <= 0 or h <= 0 then
        return
    end
    local r = math.min(rad, w / 2, h / 2)
    local p = newPath()
    p:moveTo(Vector.xy(x + r, y))
    p:lineTo(Vector.xy(x + w - r, y))
    p:quadTo(Vector.xy(x + w, y), Vector.xy(x + w, y + r))
    p:lineTo(Vector.xy(x + w, y + h - r))
    p:quadTo(Vector.xy(x + w, y + h), Vector.xy(x + w - r, y + h))
    p:lineTo(Vector.xy(x + r, y + h))
    p:quadTo(Vector.xy(x, y + h), Vector.xy(x, y + h - r))
    p:lineTo(Vector.xy(x, y + r))
    p:quadTo(Vector.xy(x, y), Vector.xy(x + r, y))
    p:close()
    if outline and outline > 0 then
        strokePaint.color = G.INK
        strokePaint.thickness = outline * 2
        R:drawPath(p, strokePaint)
    end
    fillPaint.color = c
    R:drawPath(p, fillPaint)
end

-- Vertical gradient rectangle.
function G.vgrad(x: number, y: number, w: number, h: number, top: Color, bottom: Color)
    gradPaint.gradient = Gradient.linear(Vector.xy(0, y), Vector.xy(0, y + h), {
        { position = 0, color = top },
        { position = 1, color = bottom },
    })
    local p = newPath()
    p:moveTo(Vector.xy(x, y))
    p:lineTo(Vector.xy(x + w, y))
    p:lineTo(Vector.xy(x + w, y + h))
    p:lineTo(Vector.xy(x, y + h))
    p:close()
    R:drawPath(p, gradPaint)
end

-- Soft radial glow.
function G.glow(x: number, y: number, r: number, c: Color, a: number)
    if r <= 0 then
        return
    end
    gradPaint.gradient = Gradient.radial(Vector.xy(0, 0), 1, {
        { position = 0, color = G.fade(c, a) },
        { position = 1, color = G.fade(c, 0) },
    })
    R:save()
    R:transform(Mat2D.withScaleAndTranslation(r, r, x, y))
    R:drawPath(unitCircle, gradPaint)
    R:restore()
end

-- Strokes --------------------------------------------------------------------

function G.line(x1: number, y1: number, x2: number, y2: number, th: number, c: Color)
    local p = newPath()
    p:moveTo(Vector.xy(x1, y1))
    p:lineTo(Vector.xy(x2, y2))
    strokePaint.color = c
    strokePaint.thickness = th
    R:drawPath(p, strokePaint)
end

function G.polyline(pts: { number }, th: number, c: Color, closed: boolean?)
    local n = #pts // 2
    if n < 2 then
        return
    end
    local p = newPath()
    p:moveTo(Vector.xy(pts[1], pts[2]))
    for i = 2, n do
        p:lineTo(Vector.xy(pts[i * 2 - 1], pts[i * 2]))
    end
    if closed then
        p:close()
    end
    strokePaint.color = c
    strokePaint.thickness = th
    R:drawPath(p, strokePaint)
end

-- An arm or leg: an inked capsule through a joint.
function G.limb(x1: number, y1: number, xm: number, ym: number, x2: number, y2: number, th: number, c: Color)
    local p = newPath()
    p:moveTo(Vector.xy(x1, y1))
    p:lineTo(Vector.xy(xm, ym))
    p:lineTo(Vector.xy(x2, y2))
    strokePaint.color = G.INK
    strokePaint.thickness = th + 5
    R:drawPath(p, strokePaint)
    strokePaint.color = c
    strokePaint.thickness = th
    R:drawPath(p, strokePaint)
end

function G.ring(x: number, y: number, rx: number, ry: number, th: number, c: Color)
    if rx <= 0 or ry <= 0 then
        return
    end
    local p = newPath()
    local n = 28
    for i = 0, n do
        local a = i / n * math.pi * 2
        local v = Vector.xy(x + math.cos(a) * rx, y + math.sin(a) * ry)
        if i == 0 then
            p:moveTo(v)
        else
            p:lineTo(v)
        end
    end
    strokePaint.color = c
    strokePaint.thickness = th
    R:drawPath(p, strokePaint)
end

-- Comic "burst" star.
function G.burst(x: number, y: number, r1: number, r2: number, spikes: number, rot: number, c: Color, outline: number?)
    local pts: { number } = {}
    for i = 0, spikes * 2 - 1 do
        local a = rot + i / (spikes * 2) * math.pi * 2
        local r = if i % 2 == 0 then r1 else r2
        table.insert(pts, x + math.cos(a) * r)
        table.insert(pts, y + math.sin(a) * r)
    end
    G.poly(pts, c, outline)
end

-- Text -----------------------------------------------------------------------

-- Decode each outline once, on first use. The shipped WOFF2 subset is converted
-- to these paths at authoring time because Renderer has no font/text API.
local function tcPath(code: number): Path?
    if tcPaths[code] then return tcPaths[code] end
    local data = tcGlyphs[code]
    if data == nil then return nil end
    local tokens = string.split(data, ' ')
    local path = Path.new()
    local i = 1
    while i <= #tokens do
        local command = tokens[i]
        i += 1
        if command == 'Z' then
            path:close()
        elseif command ~= '' then
            local a = Vector.xy(tonumber(tokens[i]) or 0, tonumber(tokens[i + 1]) or 0)
            i += 2
            if command == 'M' then path:moveTo(a)
            elseif command == 'L' then path:lineTo(a)
            else
                local b = Vector.xy(tonumber(tokens[i]) or 0, tonumber(tokens[i + 1]) or 0)
                i += 2
                if command == 'Q' then path:quadTo(a, b)
                elseif command == 'C' then
                    local c = Vector.xy(tonumber(tokens[i]) or 0, tonumber(tokens[i + 1]) or 0)
                    i += 2
                    path:cubicTo(a, b, c)
                end
            end
        end
    end
    tcPaths[code] = path
    return path
end

function G.textWidth(s: string, size: number): number
    local width, trailing = 0, 0
    for _, code in utf8.codes(s) do
        width += if code < 128 then font.ADVANCE else 6.3
        trailing = if code < 128 then 1.4 else .3
    end
    return math.max(0, width - trailing) * size / 6
end

-- Draw `s` with its top edge at y. align: 0 left, 0.5 centre, 1 right.
-- Letters are italic and inked, comic-book style.
function G.text(s: string, x: number, y: number, size: number, c: Color, align: number?, ink: Color?)
    local sc = size / 6
    local w = G.textWidth(s, size)
    local x0 = x - w * (align or 0)
    local th = 1.15
    local chinese = #s ~= utf8.len(s)
    R:save()
    R:transform(Mat2D.values(sc, 0, if chinese then 0 else -sc * 0.16, sc, x0 + sc * 0.5, y))
    local up = string.upper(s)
    for pass = 1, 2 do
        local cursor = 0
        for _, code in utf8.codes(up) do
            local isTC = code >= 128
            local g = if isTC then tcPath(code) else glyphPaths[string.char(code)]
            if isTC and not g then g = glyphPaths['?'] end
            if g then
                R:save()
                R:transform(Mat2D.withTranslation(cursor, 0))
                if isTC and pass == 2 then
                    fillPaint.color = c
                    R:drawPath(g, fillPaint)
                else
                    strokePaint.color = if pass == 1 then ink or G.INK else c
                    strokePaint.thickness = if isTC then math.min(.45, 4 / sc) elseif pass == 1 then th + 5 / sc else th
                    R:drawPath(g, strokePaint)
                end
                R:restore()
            end
            cursor += if isTC then 6.3 else font.ADVANCE
        end
    end
    R:restore()
end

-- Plain upright text with no ink pass, for tiny details like emblems.
function G.label(s: string, x: number, y: number, size: number, c: Color, align: number?)
    local sc = size / 6
    local x0 = x - G.textWidth(s, size) * (align or 0)
    R:save()
    R:transform(Mat2D.withScaleAndTranslation(sc, sc, x0, y))
    strokePaint.color = c
    strokePaint.thickness = 1.3
    local up = string.upper(s)
    local cursor = 0
    for _, code in utf8.codes(up) do
        local isTC = code >= 128
        local g = if isTC then tcPath(code) else glyphPaths[string.char(code)]
        if isTC and not g then g = glyphPaths['?'] end
        if g then
            R:save()
            R:transform(Mat2D.withTranslation(cursor, 0))
            fillPaint.color = c
            R:drawPath(g, if isTC then fillPaint else strokePaint)
            R:restore()
        end
        cursor += if isTC then 6.3 else font.ADVANCE
    end
    R:restore()
end

return G
