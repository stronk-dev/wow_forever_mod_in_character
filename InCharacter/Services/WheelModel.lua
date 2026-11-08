local _, IC = ...
-- Pure hierarchy and geometry. A single labeled ring starts with categories;
-- entering a category is explicit, so opening the wheel never selects an action.
IC.WheelModel = { PAGE = 12 }
local M = IC.WheelModel

local function usable(list)
    local result = {}
    for _, action in ipairs(list) do
        if action.type ~= "emote" or action.verified then result[#result + 1] = action end
    end
    return result
end
function M.Categories(raw)
    local info = IC.Emotes.CategoryInfo
    local settings = raw and {} or IC.Profile().wheel
    local result = {}
    local function category(id, actions)
        if not raw and settings.hiddenCategories[id] then return end
        if not raw then actions = usable(actions); actions = IC.Presentation.Tree(actions, settings) end
        result[#result + 1] = { id = id, type = "submenu", label = info[id].label, icon = info[id].icon, items = actions, children = actions }
    end
    category("Favorites", IC.Actions.List("favorites", raw))
    for _, id in ipairs(IC.Emotes.categories) do
        local actions = IC.Actions.List(id, raw)
        if not raw then actions = usable(actions); actions = IC.Presentation.Filter(actions, settings); actions = IC.Presentation.EmoteGroups(id, actions) end
        category(id, actions)
    end
    category("Roleplay", IC.Actions.RoleplayGroups())
    return result
end
function M.Children(node) return node.items or node.children or {} end
function M.PageSize() return math.max(4, math.min(12, math.floor(tonumber(IC.Profile().wheel.pageSize) or 8))) end
function M.Pages(category) return math.max(1, math.ceil(#M.Children(category) / M.PageSize())) end
function M.Items(category, page)
    local result = {}
    local children = M.Children(category)
    local per = M.PageSize()
    for i = (page - 1) * per + 1, math.min(page * per, #children) do result[#result + 1] = children[i] end
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
-- The full centre is neutral. Only pointing at the displayed ring selects.
function M.Hit(dx, dy, geometry, innerCount, outerCount)
    local distance = math.sqrt(dx * dx + dy * dy)
    if distance <= geometry.hub then return "hub" end
    if distance > geometry.outer + 40 then return "outside" end
    local angle = M.Angle(dx, dy)
    if distance < geometry.outer - geometry.hitWidth then return "gap" end
    if outerCount < 1 then return "hub" end
    return "outer", M.Sector(angle, outerCount)
end
function M.Geometry(radius, deadZone, buttonSize)
    return { outer = radius, inner = 0, hub = math.min(radius * 0.65, deadZone or 62), split = 0,
        hitWidth = math.max(28, (buttonSize or 42) * 0.7) }
end
