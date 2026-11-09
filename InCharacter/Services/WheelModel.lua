local _, IC = ...
-- Pure ring geometry. Angles run clockwise from the top, in radians.
-- The ring holds a collection's items; hovering a group or pool fans its items out beyond it.
IC.WheelModel = { PAGE = 12 }
local M = IC.WheelModel
local TAU = math.pi * 2

function M.Pages(count) return math.max(1, math.ceil(count / M.PAGE)) end
function M.Slice(list, page)
    local result, first = {}, (page - 1) * M.PAGE + 1
    for index = first, math.min(#list, first + M.PAGE - 1) do result[#result + 1] = list[index] end
    return result
end
-- The smallest radius that keeps icons from touching, never below 64.
function M.Radius(count, icon)
    local radius = 64
    -- Axis-aligned square icons need separation on at least one axis. Arc length
    -- alone underestimates their footprint at diagonal angles.
    for i = 1, count do for j = i + 1, count do
        local a, b = (i - 1) * TAU / count, (j - 1) * TAU / count
        local separation = math.max(math.abs(math.sin(a) - math.sin(b)), math.abs(math.cos(a) - math.cos(b)))
        if separation > 0 then radius = math.max(radius, math.ceil((icon + 4) / separation)) end
    end end
    return radius
end
function M.Geometry(count, icon)
    local radius = M.Radius(count, icon)
    return { icon = icon, radius = radius, hub = math.max(18, math.floor(radius * 0.3)), band = radius + icon * 0.75,
        fanIcon = math.max(16, icon - 8), size = (radius + icon) * 2 }
end
function M.Angle(dx, dy)
    local angle = math.atan2 and math.atan2(dx, dy) or math.atan(dx, dy)
    if angle < 0 then angle = angle + TAU end
    return angle
end
function M.Position(index, count, radius)
    local angle = (index - 1) * TAU / count
    return math.sin(angle) * radius, math.cos(angle) * radius, angle
end
function M.Sector(angle, count)
    local size = TAU / count
    return math.floor((angle + size / 2) / size) % count + 1
end
-- "hub", "ring" or "outside", by distance from the centre.
function M.Zone(dx, dy, g)
    local distance = math.sqrt(dx * dx + dy * dy)
    if distance < g.hub then return "hub" end
    if distance <= g.band then return "ring" end
    return "outside"
end

-- Positions for a fan of count items centred on angle, in rows outside the ring.
-- Each row covers at most half a circle. Returns positions and how many fit.
function M.Fan(count, angle, g, rows)
    rows = rows or 2
    local positions, placed = {}, 0
    local step = math.ceil(math.sqrt(2) * (g.fanIcon + 2))
    for row = 1, rows do
        if placed >= count then break end
        local radius = g.radius + math.ceil((g.icon + g.fanIcon) / 2 * math.sqrt(2)) + 8 + (row - 1) * step
        local capacity = math.max(1, math.floor(math.pi * radius / step))
        local here = math.min(capacity, count - placed)
        local spread = step / radius
        for i = 1, here do
            local a = angle + (i - (here + 1) / 2) * spread
            positions[#positions + 1] = { x = math.sin(a) * radius, y = math.cos(a) * radius }
        end
        placed = placed + here
    end
    return positions, placed
end
-- Index of the nearest position within reach, or nil.
function M.Nearest(dx, dy, positions, reach)
    local best, bestDistance
    for index, p in ipairs(positions) do
        local distance = (dx - p.x) ^ 2 + (dy - p.y) ^ 2
        if distance <= reach * reach and (not bestDistance or distance < bestDistance) then best, bestDistance = index, distance end
    end
    return best
end
