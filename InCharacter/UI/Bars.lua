local _, IC = ...
-- Bar manager. Every bar shows one collection, drawn by UI/CollectionBar.lua.
IC.Bars = { frames = {} }
local B = IC.Bars

local function createFrame(index)
    local frame = CreateFrame("Frame", nil, UIParent)
    frame:SetClampedToScreen(true); frame:SetMovable(true); frame:SetFrameStrata("MEDIUM")
    frame.index = index
    return frame
end

function B.Add(collection)
    local bars = IC.Layout().bars
    local bar = IC.Defaults.CollectionBar(#bars + 1, collection or "favorites")
    local list = IC.Collections.Get(bar.collection)
    bar.name = list and list.name or ("Bar " .. #bars + 1)
    bar.y = bar.y + 40 * #bars
    bars[#bars + 1] = bar
    IC.Changed()
    return #bars
end
function B.Delete(index)
    local bars = IC.Layout().bars
    if not bars[index] then return false end
    table.remove(bars, index)
    if B.selectedBar and B.selectedBar >= index then B.selectedBar = bars[1] and 1 or nil end
    IC.Changed(); return true
end
-- "one" bar or "separate" bars. Each mode keeps its own bars (positions, sizes); switching
-- stores the current set and restores the other one.
function B.Mode() return IC.Layout().mode == "separate" and "separate" or "one" end
function B.SetMode(mode)
    if IC.InCombat() then IC.Print("Change bars after combat."); return false end
    mode = mode == "separate" and "separate" or "one"
    local layout = IC.Layout()
    if B.Mode() == mode then return true end
    layout.stash = layout.stash or {}
    layout.stash[B.Mode()] = layout.bars
    layout.bars = layout.stash[mode] or IC.Defaults.ModeBars(mode)
    layout.stash[mode] = nil
    layout.mode, layout.barsHidden = mode, nil
    B.selectedBar = nil
    if IC.Flyout then IC.Flyout.Close() end
    IC.Changed(); return true
end
-- Hides every bar at once (and shows them again) without touching each bar's own setting.
function B.ToggleAll()
    local layout = IC.Layout()
    layout.barsHidden = not layout.barsHidden
    IC.Changed()
end

function B.RenderFrame(frame, config)
    IC.CollectionBar.Render(frame, config)
    if IC.Layout().barsHidden and not B.editing then frame:Hide() end
    if B.UpdateEditControls then B.UpdateEditControls(frame) end
end
function B.Refresh()
    if IC.InCombat() then IC.refreshPending = true; return end
    local bars = IC.Layout().bars
    for index = #bars + 1, #B.frames do B.frames[index]:Hide() end
    for index, config in ipairs(IC.Layout().bars) do
        local frame = B.frames[index] or createFrame(index); B.frames[index] = frame
        frame.config, frame.index = config, index
        B.RenderFrame(frame, config)
    end
    if B.RefreshInspector then B.RefreshInspector() end
end
