local _, IC = ...
-- Pure data/geometry for the two-ring wheel: inner ring = categories, outer ring = actions.
IC.WheelModel = { PAGE = 12 }
local M = IC.WheelModel

local function usable(list)
    local result = {}
    for _, action in ipairs(list) do
        if action.type ~= "emote" or action.verified then result[#result + 1] = action end
    end
    return result
end
function M.Categories()
    local info = IC.Emotes.CategoryInfo
    local result = { { id = "Favorites", label = info.Favorites.label, icon = info.Favorites.icon, items = usable(IC.Actions.List("favorites")) } }
    for _, id in ipairs(IC.Emotes.categories) do
        result[#result + 1] = { id = id, label = info[id].label, icon = info[id].icon, items = usable(IC.Actions.List(id)) }
    end
    result[#result + 1] = { id = "Roleplay", label = info.Roleplay.label, icon = info.Roleplay.icon, items = IC.Actions.RoleplayGroups() }
    return result
end
function M.Children(node) return node.items or node.children or {} end
function M.Pages(category) return math.max(1, math.ceil(#M.Children(category) / M.PAGE)) end
function M.Items(category, page)
    local result = {}
    local children = M.Children(category)
    for i = (page - 1) * M.PAGE + 1, math.min(page * M.PAGE, #children) do result[#result + 1] = children[i] end
    return result
end
-- Angle in degrees, 0 at the top, increasing clockwise.
function M.Angle(dx, dy)
    local angle = math.deg(math.atan2 and math.atan2(dx, dy) or math.atan(dx, dy))
    return angle < 0 and angle + 360 or angle
end
function M.Sector(angle, count)
    if count < 1 then return nil end
    local size = 360 / count
    return math.floor(((angle + size / 2) % 360) / size) + 1
end
function M.Position(index, count, radius)
    local angle = math.rad((index - 1) * 360 / count)
    return math.sin(angle) * radius, math.cos(angle) * radius
end
-- Which ring the cursor points at. The hub is a dead zone; past the split everything is the outer ring.
function M.Hit(dx, dy, geometry, innerCount, outerCount)
    local distance = math.sqrt(dx * dx + dy * dy)
    if distance < geometry.hub then return "hub" end
    if distance > geometry.outer + 40 then return "outside" end
    local angle = M.Angle(dx, dy)
    if distance < geometry.split then return "inner", M.Sector(angle, innerCount) end
    if outerCount < 1 then return "hub" end
    return "outer", M.Sector(angle, outerCount)
end
function M.Geometry(radius)
    return { outer = radius, inner = radius * 0.5, hub = radius * 0.27, split = radius * 0.75 }
end
