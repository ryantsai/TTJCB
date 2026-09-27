-- Side-view two-bone arms. Local +x is forward; the whole fighter is mirrored
-- once by the game. Both elbows use the same anatomical bend, independent of
-- which arm is drawn in front of the torso.
local A = {}
function A.lengths(kind: string): (number, number)
    if kind == 'cyborg' then return 28, 38 end
    if kind == 'starfire' then return 17, 21 end
    if kind == 'raven' then return 22, 28 end
    if kind == 'beast' then return 16, 21 end
    return 16, 20
end
function A.solve(kind: string, sx: number, sy: number, tx: number, ty: number): (number, number, number, number)
    local upper, lower = A.lengths(kind)
    local dx, dy = tx - sx, ty - sy
    local distance = math.sqrt(dx * dx + dy * dy)
    local nx, ny = if distance > .001 then dx / distance else 1, if distance > .001 then dy / distance else 0
    local d = math.clamp(distance, math.abs(upper - lower) + .1, upper + lower - .1)
    local hx, hy = sx + nx * d, sy + ny * d
    local along = (upper * upper - lower * lower + d * d) / (2 * d)
    local bend = math.sqrt(math.max(0, upper * upper - along * along))
    -- A forward fist puts the elbow below the shoulder, never above it.
    return sx + nx * along - ny * bend, sy + ny * along + nx * bend, hx, hy
end
return A
