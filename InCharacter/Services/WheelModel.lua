local _, IC = ...
IC.WheelModel = {}
local M = IC.WheelModel
local function submenu(id, label, children)
    return { id = id, type = "submenu", label = label, children = children, icon = IC.Icons[1] }
end
function M.Tree()
    local root = submenu("root", "In Character", {})
    root.children[1] = submenu("favorites", "Favorites", IC.Actions.List("favorites"))
    for _, category in ipairs(IC.Emotes.categories) do root.children[#root.children + 1] = submenu(category, category, IC.Actions.List(category)) end
    local roleplay, groups = submenu("roleplay", "Roleplay", {}), {}
    for _, id in ipairs(IC.Profile().poolOrder) do
        local pool = IC.Profile().pools[id]
        local packID = pool.provenance and pool.provenance.pack
        local groupID = packID or "custom"
        if not groups[groupID] then
            local pack = packID and IC.Library.packs[packID]
            groups[groupID] = submenu(groupID, pack and pack.title or "Custom pools", {})
            roleplay.children[#roleplay.children + 1] = groups[groupID]
        end
        groups[groupID].children[#groups[groupID].children + 1] = IC.Actions.Resolve("pool:" .. id)
    end
    root.children[#root.children + 1] = roleplay
    return root
end
function M.New(tree) return { stack = { tree }, page = 1, favoritePage = 1 } end
function M.Current(state) return state.stack[#state.stack] end
function M.Enter(state, action)
    if action.type ~= "submenu" then return false end
    state.stack[#state.stack + 1] = action; state.page = 1
    return true
end
function M.Back(state)
    if #state.stack > 1 then table.remove(state.stack); state.page = 1; return true end
    return false
end
function M.Page(state, delta, size)
    local pages = math.max(1, math.ceil(#M.Current(state).children / size))
    state.page = math.max(1, math.min(pages, state.page + delta))
end
function M.Items(state, size)
    local result, children = {}, M.Current(state).children
    for i = (state.page - 1) * size + 1, math.min(state.page * size, #children) do result[#result + 1] = children[i] end
    return result, math.max(1, math.ceil(#children / size))
end
