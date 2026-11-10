local _, IC = ...
-- Pure ring geometry, after OPie and ConsolePort. Angles run clockwise from the top, in radians.
-- At most 8 slices per ring (marking-menu research); longer lists page. Selection is by angle
-- anywhere outside the centre, which is the back / close zone.
IC.WheelModel = { PAGE = 8, ICON = 40 }
local M = IC.WheelModel
local TAU = math.pi * 2

function M.Pages(count) return math.max(1, math.ceil(count / M.PAGE)) end
function M.Slice(list, page)
    local result, first = {}, (page - 1) * M.PAGE + 1
    for index = first, math.min(#list, first + M.PAGE - 1) do result[#result + 1] = list[index] end
    return result
end
-- OPie: radius = max(minimum, n * slot / 2pi), then grown until no two square icons touch.
function M.Radius(count, icon)
    local slot = icon + 8
    local radius = math.max(math.ceil(icon * 2.1), math.ceil(count * slot / TAU))
    for i = 1, count do for j = i + 1, count do
        local a, b = (i - 1) * TAU / count, (j - 1) * TAU / count
        local separation = math.max(math.abs(math.sin(a) - math.sin(b)), math.abs(math.cos(a) - math.cos(b)))
        if separation > 0 then radius = math.max(radius, math.ceil((icon + 6) / separation)) end
    end end
    return radius
end
function M.Geometry(count, icon)
    icon = icon or M.ICON
    local radius = M.Radius(count, icon)
    return { icon = icon, radius = radius, hub = math.max(16, math.floor(radius - icon / 2 - 12)), size = (radius + icon) * 2 }
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
-- "hub" inside the dead zone, otherwise "ring": the whole wedge selects, however far out.
function M.Zone(dx, dy, g)
    return math.sqrt(dx * dx + dy * dy) < g.hub and "hub" or "ring"
end
-- Reserve square icons, including hover growth and the highlight, rather than just the ring.
function M.LabelEdge(g) return g.radius + (g.icon * 1.1 + 6) / 2 + 12 end
-- Anchor the whole text block outside that envelope; a radial offset is unsafe at diagonals.
function M.LabelPoint(angle, g)
    local s, c, edge = math.sin(angle), math.cos(angle), M.LabelEdge(g)
    if s > 0.3 then return edge, c * g.radius, "LEFT"
    elseif s < -0.3 then return -edge, c * g.radius, "RIGHT" end
    return 0, c > 0 and edge or -edge, "CENTER"
end
