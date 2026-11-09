local _, IC = ...
-- The emote menu is the flyout list of a root collection, opened at the launcher or the cursor.
IC.Menu = {}
local Menu = IC.Menu

function Menu.Root()
    local id = IC.Profile().menu.root or "main"
    local collection = IC.Collections.Get(id) or IC.Collections.Get("main")
    return { id = "set:" .. collection.id, type = "group", collection = collection.id, name = collection.name, icon = collection.icon }
end
function Menu.IsOpen() return IC.Flyout.IsOpen() and IC.Flyout.levels[1].anchor == Menu.anchor end
function Menu.Close() if Menu.IsOpen() then IC.Flyout.Close() end end
function Menu.Open(anchor)
    if not IC.db then return end
    if IC.Wheel then IC.Wheel.Close() end
    if Menu.IsOpen() and IC.Flyout.levels[1].anchor == anchor then IC.Flyout.Close(); return end
    Menu.anchor = anchor
    return IC.Flyout.Open(anchor, Menu.Root(), 1)
end
function Menu.OpenAtCursor(node)
    if not IC.db then return end
    local point = Menu.point
    if not point then point = CreateFrame("Frame", nil, UIParent); point:SetSize(1, 1); Menu.point = point end
    local x, y = IC.Platform.Cursor()
    local scale = UIParent:GetEffectiveScale()
    point:ClearAllPoints(); point:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x / scale, y / scale)
    local _, middle = UIParent:GetCenter()
    point.side = (y / scale) > middle and "DOWN" or "UP"
    if node then
        if IC.Wheel then IC.Wheel.Close() end
        Menu.anchor = point; return IC.Flyout.Open(point, node, 1)
    end
    return Menu.Open(point)
end
