-- Each test loads a fresh addon and WoW globals; no state/order dependencies.
-- These are mocked callback/data-flow tests, not a live-client or visual test.
local function chunk(path, environment)
    if setfenv then return setfenv(assert(loadfile(path)), environment) end
    return assert(loadfile(path, "t", environment))
end
local function fixture()
    local env = setmetatable({}, { __index = _G }); env._G = env
    local Stub = chunk("tests/wow_stub.lua", env)(); Stub.Install()
    env.SLASH_OTHER1 = "/ic"; env.SlashCmdList.OTHER = function() end
    local IC = {}
    for line in io.lines("InCharacter/InCharacter.toc") do
        if line:match("%.lua$") then chunk("InCharacter/" .. line, env)("InCharacter", IC) end
    end
    local function event(name, ...)
        local frames = {}; for i, frame in ipairs(Stub.frames) do frames[i] = frame end
        for _, frame in ipairs(frames) do if frame.events[name] then frame:Fire("OnEvent", name, ...) end end
    end
    event("ADDON_LOADED", "InCharacter")
    return IC, Stub, env, event
end
local tests = 0
local function eq(a, b) assert(a == b, tostring(a) .. " ~= " .. tostring(b)) end
local function test(name, fn)
    local ok, err = pcall(function() fn(fixture()) end)
    if not ok then error("FAIL " .. name .. ": " .. tostring(err)) end
    tests = tests + 1; print("ok " .. tests .. " - " .. name)
end
local function page(IC, tab) IC.Editor.Open(tab); return IC.Editor.pages[tab] end
local function point(Stub, IC, dx, dy)
    local cx, cy = IC.Wheel.frame:GetCenter()
    local scale = IC.Wheel.frame:GetEffectiveScale()
    Stub.cursorX, Stub.cursorY = (cx + dx) * scale, (cy + dy) * scale
    IC.Wheel.Track()
end
local function pointAt(Stub, IC, slot)
    local x, y = slot:GetCenter(); local scale = slot:GetEffectiveScale()
    Stub.cursorX, Stub.cursorY = x * scale, y * scale; IC.Wheel.Track()
end

local function ringSlot(IC, id)
    for _, slot in ipairs(IC.Wheel.slots) do if slot:IsShown() and slot.node.id == id then return slot end end
    error("No ring slot: " .. id)
end
local function flyRow(IC, depth, id)
    for _, row in ipairs(IC.Flyout.levels[depth].rows) do if row:IsShown() and row.node.id == id then return row end end
    error("No flyout row: " .. id)
end

test("load registers commands, Settings page, launcher and the main bar without sending", function(IC, Stub, env)
    assert(IC.db); eq(env.SLASH_INCHARACTER1, "/incharacter"); eq(env.SLASH_INCHARACTER2, nil)
    eq(Stub.settingsCategory.name, "In Character"); assert(Stub.settingsPanel)
    assert(IC.Launcher.button:IsShown()); assert(IC.Bars.frames[1]:IsShown()); eq(IC.Layout().launcher.click, nil); eq(IC.Layout().mode, "one")
    Stub.Button(Stub.settingsPanel, "Move & edit bars"):Click(); assert(IC.Bars.editing); IC.Bars.SetEditing(false)
    eq(#Stub.sends, 0); eq(#Stub.emotes, 0)
end)

test("every page builds, old page names still open and switching sends nothing", function(IC, Stub)
    for _, name in ipairs({ "Lists", "Lines", "Layout", "Profiles" }) do
        page(IC, name); assert(IC.Editor.pages[name]:IsShown())
        for other, p in pairs(IC.Editor.pages) do if other ~= name then assert(not p:IsShown()) end end
    end
    IC.Editor.Open("Home"); eq(IC.Editor.tab, "Lists"); IC.Editor.Open("Dialogue"); eq(IC.Editor.tab, "Lines")
    eq(#Stub.sends, 0); eq(#Stub.emotes, 0)
end)

test("lists page searches aliases, shows no testing labels and edits list membership", function(IC, Stub)
    local p = page(IC, "Lists")
    IC.Editor.list = "Combat"; IC.Editor.RefreshLists()
    assert(type(p.kind) ~= "table" and p.missing == nil and p.detail.sound == nil, "no testing filters")
    for _, row in ipairs(p.libRows) do
        local right = row.right:GetText() or ""
        assert(not right:find("ref", 1, true) and not right:find("checked", 1, true), right)
    end
    p.advanced:SetChecked(true); p.advanced:Click()
    p.search:SetText("joke"); eq(p.shown[1].id, "emote:silly")
    p.libRows[1]:Click("RightButton"); assert(IC.Collections.Contains("Combat", "emote:silly"))
    p.libRows[1]:Click("RightButton"); assert(not IC.Collections.Contains("Combat", "emote:silly"))
    local before = IC.Collections.Refs("Combat")[1]
    p.itemRows[1]:Click(); Stub.Button(p, "Down"):Click(); eq(IC.Collections.Refs("Combat")[2], before)
    Stub.Button(p, "Remove"):Click(); assert(not IC.Collections.Contains("Combat", before))
    Stub.Button(p, "+ New list"):Click(); IC.Editor.nameDialog.name:SetText("Tavern"); Stub.Button(IC.Editor.nameDialog, "Save"):Click()
    local tavern = IC.Editor.list; eq(IC.Collections.Get(tavern).name, "Tavern")
    p.groupChoice:SetValue("Social"); Stub.Button(p, "+ Group"):Click(); assert(IC.Collections.Contains(tavern, "set:Social"))
    p.inline:SetChecked(true); p.groupChoice:SetValue("favorites"); Stub.Button(p, "+ Group"):Click(); assert(IC.Collections.Contains(tavern, "all:favorites"))
    eq(#Stub.sends + #Stub.emotes, 0)
end)

test("library detail tries and renames; bars follow; tooltips carry no test status", function(IC, Stub, env)
    local p = page(IC, "Lists"); local d = p.detail
    IC.Editor.selected = "emote:wave"; IC.Editor.RefreshLibrary()
    Stub.Button(d, "Try it"):Click(); eq(Stub.emotes[1], "WAVE")
    d.rename:SetText("Hiya"); Stub.Button(d, "Rename"):Click()
    IC.Editor.frame:Hide()
    local wave = IC.Bars.frames[1].actionButtons[1]; eq(wave.node.name, "Hiya"); eq(wave.node.payload, "WAVE"); assert(not wave.dot:IsShown())
    local lines = {}; local add = env.GameTooltip.AddLine
    env.GameTooltip.AddLine = function(_, text) lines[#lines + 1] = text end
    wave:Fire("OnEnter"); env.GameTooltip.AddLine = add; local tip = table.concat(lines, " | "); eq(tip, "/wave")
    assert(not tip:find("checked", 1, true), tip); wave:Fire("OnLeave")
    page(IC, "Lists"); IC.Editor.selected = "emote:wave"; IC.Editor.RefreshLibrary()
    Stub.Button(d, "Reset"):Click(); eq(IC.Actions.Resolve("emote:wave").name, "Wave")
end)

test("lines page: play a preset character, roles, drafts survive switching, save, preview, greet", function(IC, Stub)
    local p = page(IC, "Lines")
    p.pack:Choose("office-stanley"); Stub.Button(p, "Play as this character"):Click()
    eq(IC.Personas.Name(), "Stanley Hudson")
    local first = IC.Editor.poolID; eq(IC.Personas.RoleOf(first), "greetings"); eq(IC.Profile().pools[first].name, "Greetings")
    eq(p.rows[1]:GetText(), "Greetings"); assert(p.rows[1].right:GetText():find("Greeting"))
    p.lines:SetText("Hello, 'friend'.\nHé, hoe gaat het?")
    IC.Editor.SelectPool(IC.Personas.Pools()[2]); IC.Editor.SelectPool(first)
    eq(p.lines:GetText(), "Hello, 'friend'.\nHé, hoe gaat het?"); assert(p.info:GetText():find("unsaved"))
    p.mode:Choose("sequential"); Stub.Button(p, "Save"):Click()
    eq(#IC.Profile().pools[first].lines, 2); assert(not p.info:GetText():find("unsaved")); assert(p.info:GetText():find("The Office"))
    Stub.Button(p, "Preview"):Click(); eq(#Stub.sends, 0)
    IC.Slash("greet"); eq(Stub.sends[1][1], "Hello, 'friend'.")
    -- A new pool can take over a role; the old one becomes an extra.
    Stub.Button(p, "+ New pool"):Click(); local extra = IC.Editor.poolID; p.role:Choose("greetings")
    eq(IC.Personas.RolePool("greetings"), extra); eq(IC.Personas.RoleOf(first), nil)
    IC.Editor.frame:Hide(); eq(IC.Collections.Get("rp").name, "Stanley Hudson")
end)

test("layout page binds keys, switches one bar / separate bars and hides bars", function(IC, Stub)
    local p = page(IC, "Layout"); local key = p.keys[1]
    key:Click("LeftButton"); assert(key.capturing)
    Stub.modifiers.shift = true; key:Fire("OnKeyDown", "F"); Stub.modifiers.shift = nil
    eq(Stub.bindings["SHIFT-F"], "INCHARACTER_WHEEL"); assert(not key.capturing)
    key:Click("RightButton"); eq(Stub.bindings["SHIFT-F"], nil)
    assert(not p.launcherClick, "the launcher is not configurable per mouse button")
    p.barMode:Choose("separate"); eq(#IC.Layout().bars, 7); eq(IC.Layout().bars[2].collection, "Combat"); eq(IC.Layout().bars[7].collection, "rp")
    p.barMode:Choose("one"); eq(#IC.Layout().bars, 1); eq(IC.Layout().bars[1].collection, "main")
    p.barsToggle:Click(); assert(IC.Layout().barsHidden); IC.Editor.frame:Hide()
    for _, frame in ipairs(IC.Bars.frames) do assert(not frame:IsShown()) end
    IC.Slash("bars"); assert(IC.Bars.frames[1]:IsShown())
    IC.Launcher.button:Click(); assert(IC.Menu.IsOpen()); IC.Flyout.Close()
    IC.Launcher.button:Click("RightButton"); assert(IC.Editor.frame:IsShown())
end)

test("ring: at most 8 slices; pointing names the slice outside the ring and never sends", function(IC, Stub, env)
    env.InCharacter_WheelBinding("down"); assert(IC.Wheel.open); env.InCharacter_WheelBinding("up"); assert(IC.Wheel.open)
    assert(#IC.Wheel.items <= 8); eq(IC.Wheel.Current().collection, "ring")
    local favorites = ringSlot(IC, "set:favorites"); assert(favorites.arrow:IsShown(), "groups carry a badge")
    pointAt(Stub, IC, favorites); eq(IC.Wheel.hover, favorites); eq(IC.Wheel.label:GetText(), "Favorites"); eq(#Stub.emotes, 0)
    local x = IC.Wheel.label.points.LEFT or IC.Wheel.label.points.RIGHT or IC.Wheel.label.points.BOTTOM or IC.Wheel.label.points.TOP
    assert(math.sqrt(x[3] ^ 2 + x[4] ^ 2) > IC.Wheel.geometry.radius, "the label sits outside the ring")
    IC.Wheel.catcher:Fire("OnMouseDown", "LeftButton"); eq(IC.Wheel.Current().collection, "favorites"); eq(#Stub.emotes, 0)
    pointAt(Stub, IC, ringSlot(IC, "emote:wave")); eq(IC.Wheel.label:GetText(), "Wave")
    IC.Wheel.catcher:Fire("OnMouseDown", "LeftButton"); eq(Stub.emotes[1], "WAVE"); assert(not IC.Wheel.open)
    IC.Wheel.Open(false); point(Stub, IC, 0, 0); IC.Wheel.catcher:Fire("OnMouseDown", "LeftButton"); assert(not IC.Wheel.open); eq(#Stub.emotes, 1)
end)

test("ring: a group replaces the ring, the centre goes back, right-click and Esc cancel", function(IC, Stub)
    IC.Wheel.Open(false); pointAt(Stub, IC, ringSlot(IC, "set:Voice/Fun"))
    IC.Wheel.catcher:Fire("OnMouseDown", "LeftButton"); eq(IC.Wheel.Current().collection, "Voice/Fun"); assert(IC.Wheel.open)
    eq(IC.Wheel.label:GetText(), "Playful emotes")
    point(Stub, IC, 0, 0); IC.Wheel.catcher:Fire("OnMouseDown", "LeftButton"); eq(IC.Wheel.Current().collection, "ring")
    IC.Wheel.catcher:Fire("OnMouseDown", "RightButton"); assert(not IC.Wheel.open)
    IC.Wheel.Open(false); IC.Wheel.catcher:Hide(); assert(not IC.Wheel.open); eq(#Stub.emotes, 0)
end)

test("ring: the RP slice offers the character switcher and the role words", function(IC, Stub)
    IC.Library.Install("office-stanley", true); IC.Wheel.Open(false)
    pointAt(Stub, IC, ringSlot(IC, "set:rp")); eq(IC.Wheel.label:GetText(), "Stanley Hudson")
    IC.Wheel.catcher:Fire("OnMouseDown", "LeftButton")
    local names = {}; for i, item in ipairs(IC.Wheel.items) do names[i] = item.name end
    eq(table.concat(names, ","), "Stanley Hudson,Greeting,Quote,Farewell,Joke,Battle cry,Banter")
    pointAt(Stub, IC, ringSlot(IC, "role:quotes")); IC.Wheel.catcher:Fire("OnMouseDown", "LeftButton")
    eq(#Stub.sends, 1); assert(not IC.Wheel.open)
end)

test("ring hold mode: release on a group opens it, on an item uses it, in the centre closes", function(IC, Stub, env)
    IC.Profile().wheel.mode = "hold"
    env.InCharacter_WheelBinding("down"); env.InCharacter_WheelBinding("up"); assert(not IC.Wheel.open); eq(#Stub.emotes, 0)
    env.InCharacter_WheelBinding("down"); pointAt(Stub, IC, ringSlot(IC, "set:favorites")); env.InCharacter_WheelBinding("up")
    assert(IC.Wheel.open); eq(IC.Wheel.Current().collection, "favorites"); eq(#Stub.emotes, 0)
    pointAt(Stub, IC, ringSlot(IC, "emote:dance")); IC.Wheel.catcher:Fire("OnMouseDown", "LeftButton"); eq(Stub.emotes[1], "DANCE")
    -- A mouse-button binding is swallowed by the catcher, so its release still reaches the binding.
    Stub.bindings["BUTTON4"] = "INCHARACTER_WHEEL"
    env.InCharacter_WheelBinding("down"); IC.Wheel.catcher:Fire("OnMouseUp", "Button4"); assert(not IC.Wheel.open); eq(#Stub.emotes, 1)
end)

test("ring pages long lists with the mouse wheel and works in combat", function(IC, Stub)
    for i = 1, 18 do local pool = IC.Dialogue.Create("Pool " .. i); IC.Dialogue.Save(pool, pool.name, "SAY", "sequential", pool.icon, { "line " .. i }) end
    IC.Profile().wheel.root = "rp"; Stub.combat = true
    IC.Wheel.Open(false); eq(IC.Wheel.pages, 3); eq(#IC.Wheel.items, 8)
    IC.Wheel.catcher:Fire("OnMouseWheel", -1); IC.Wheel.catcher:Fire("OnMouseWheel", -1); eq(IC.Wheel.page, 3)
    local last = IC.Wheel.slots[#IC.Wheel.items]; pointAt(Stub, IC, last); IC.Wheel.catcher:Fire("OnMouseDown", "LeftButton")
    eq(#Stub.sends, 1); eq(Stub.sends[1][1], "line 18")
end)

test("ring geometry: clockwise sectors from the top, whole-wedge selection, no overlaps, labels outside", function(IC)
    local M = IC.WheelModel
    eq(M.Sector(M.Angle(0, 10), 4), 1); eq(M.Sector(M.Angle(10, 0), 4), 2); eq(M.Sector(M.Angle(0, -10), 4), 3)
    local g = M.Geometry(8, 40); eq(M.Zone(0, 5, g), "hub"); eq(M.Zone(0, 400, g), "ring")
    for count = 1, M.PAGE do for _, icon in ipairs({ 32, 40, 48 }) do
        local geometry = M.Geometry(count, icon)
        for i = 1, count do for j = i + 1, count do
            local ax, ay = M.Position(i, count, geometry.radius); local bx, by = M.Position(j, count, geometry.radius)
            assert(math.abs(ax - bx) >= icon or math.abs(ay - by) >= icon, "overlapping slices")
        end end
        assert(geometry.hub + 4 < geometry.radius - icon / 2, "the centre never reaches the icons")
        local _, _, angle = M.Position(count, count, geometry.radius)
        local lx, ly = M.LabelPoint(angle, geometry); assert(math.sqrt(lx * lx + ly * ly) > geometry.radius + icon / 2)
    end end
end)

test("launcher menu is the compact flyout: groups open on hover and a click sends once", function(IC, Stub, env)
    IC.Launcher.button:Click(); assert(IC.Menu.IsOpen())
    flyRow(IC, 1, "set:Combat"):Fire("OnEnter"); assert(IC.Flyout.levels[2]:IsShown()); eq(#Stub.emotes, 0)
    flyRow(IC, 2, "emote:charge"):Click(); eq(Stub.emotes[1], "CHARGE"); assert(not IC.Flyout.IsOpen())
    env.InCharacter_MenuBinding(); assert(IC.Menu.IsOpen()); IC.Flyout.catcher:Hide(); assert(not IC.Menu.IsOpen())
    env.InCharacter_OnAddonCompartmentClick("InCharacter", { buttonName = "LeftButton" }); assert(IC.Menu.IsOpen()); IC.Flyout.Close()
    env.InCharacter_OnAddonCompartmentClick("InCharacter", "RightButton"); assert(IC.Editor.frame:IsShown()); eq(IC.Editor.tab, "Lists")
end)

test("edit mode: middle-click, add a bar, resize, delete, undo; clicks never play", function(IC, Stub)
    IC.Slash("edit"); assert(IC.Bars.editing); local p = IC.Bars.inspector
    IC.Bars.frames[1].actionButtons[1]:Click(); eq(#Stub.emotes, 0)
    Stub.Button(p, "+ Bar"):Click(); eq(#IC.Layout().bars, 2); eq(IC.Bars.selectedBar, 2); eq(IC.Layout().bars[2].collection, "favorites")
    p.source:Choose("Reactions"); eq(IC.Layout().bars[2].collection, "Reactions"); eq(IC.Layout().bars[2].name, "Reactions")
    p.size:SetValue(36); eq(IC.Layout().bars[2].size, 36); p.perRow:SetValue(3); eq(IC.Layout().bars[2].perRow, 3)
    p.delete:Click(); eq(#IC.Layout().bars, 2); p.delete:Click(); eq(#IC.Layout().bars, 1)
    Stub.Button(p, "Undo all"):Click(); eq(#IC.Layout().bars, 1); eq(IC.Layout().bars[1].collection, "main")
    IC.Bars.SelectLauncher(); assert(p.launcherForm:IsShown()); p.launcherSize:SetValue(30); eq(IC.Layout().launcher.size, 30)
    -- The bar's name is centred on its own overlay, never above the bar.
    local title = IC.Bars.frames[1].moveHandle.title; assert(title.points.LEFT and title.points.RIGHT); eq(title.points.BOTTOMLEFT, nil)
    p:Hide(); assert(not IC.Bars.editing); eq(#Stub.emotes, 0)
end)

test("missing icon files fall back and the picker returns the chosen icon", function(IC, Stub, env)
    local texture = env.UIParent:CreateTexture()
    Stub.missing["Interface\\Icons\\Gone"] = true
    IC.UI.SetIcon(texture, "Interface\\Icons\\Gone", "Interface\\Icons\\INV_Misc_Book_09"); eq(texture.texture, "Interface\\Icons\\INV_Misc_Book_09")
    page(IC, "Lines")
    IC.Editor.PickIcon(nil, function(icon) IC.Editor.pickedIcon = icon end)
    IC.Editor.picker.slots[9]:Click(); Stub.Button(IC.Editor.picker, "Use icon"):Click(); eq(IC.Editor.pickedIcon, 134400)
end)

test("combat hides only the window, defers rebuilds and never replays chat", function(IC, Stub, env, event)
    page(IC, "Lists"); Stub.combat = true; event("PLAYER_REGEN_DISABLED")
    assert(not IC.Editor.frame:IsShown()); IC.Editor.Open("Lists"); assert(not IC.Editor.frame:IsShown())
    IC.Refresh(); assert(IC.refreshPending)
    IC.Launcher.button:Click("LeftButton"); assert(IC.Menu.IsOpen()); IC.Flyout.Close()
    Stub.combat = false; event("PLAYER_REGEN_ENABLED"); assert(not IC.refreshPending); eq(#Stub.sends, 0)
end)

test("upgraded saves start from the clean interface: one main bar, old bars retired, fixed launcher", function(IC, Stub, env, event)
    local layout = { bars = { { name = "Social bar", source = "Social", x = 5 }, { name = "RP", source = "pools", catalog = true } }, launcher = { click = "quick" } }
    IC.Profiles.Open({ version = 10 }, { version = 10, layout = layout }); IC.Refresh()
    eq(#layout.bars, 1); eq(layout.bars[1].collection, "main"); eq(layout.retired.bars[1].name, "Social bar")
    eq(IC.Layout().launcher.click, nil); assert(IC.Bars.frames[1]:IsShown()); assert(not IC.Bars.frames[2] or not IC.Bars.frames[2]:IsShown())
end)
test("review fixes: vertical names, pin keeps the list on its group, sub-lists beside the parent, combat ends drags", function(IC, Stub, env, event)
    local g = IC.CollectionBar.Geometry({ size = 28, vertical = true, labels = true }, { { segment = 1 }, { segment = 1 } })
    eq(g.width, 56); eq(g.positions[1].x, 14); eq(g.positions[2].y, 28 + 12 + 2); eq(g.height, 28 * 2 + 12 * 2 + 2)
    local bar = IC.Bars.frames[1]; local combat
    for _, button in ipairs(bar.actionButtons) do if button.node.id == "set:Voice/Fun" then combat = button end end
    combat:Click(); local level = IC.Flyout.levels[1]
    local chicken; for _, row in ipairs(level.rows) do if row:IsShown() and row.node.id == "emote:chicken" then chicken = row end end
    chicken:Click("RightButton"); assert(IC.Actions.IsFavorite("emote:chicken")); assert(IC.Flyout.IsOpen())
    eq(level.anchor.node.id, "set:Voice/Fun"); assert(level.anchor ~= combat, "followed the moved group button")
    IC.Flyout.Close(); IC.Launcher.button:Click()
    local group; for _, row in ipairs(IC.Flyout.levels[1].rows) do if row:IsShown() and row.node.id == "set:Combat" then group = row end end
    group:Fire("OnEnter"); eq(IC.Flyout.levels[2].relative, IC.Flyout.levels[1]); IC.Flyout.Close()
    IC.Bars.SetEditing(true); local frame = IC.Bars.frames[1]
    frame.moveHandle:Fire("OnDragStart"); assert(frame.moving); assert(frame:IsShown())
    Stub.combat = true; event("PLAYER_REGEN_DISABLED"); assert(not frame.moving); assert(not IC.Bars.editing)
end)
test("native blocked-chat events preserve selection even when the send API returns nil", function(IC, Stub, env, event)
    local pool = IC.Profile().pools.quotes; pool.mode = "sequential"; pool.lines = { "first", "second" }
    for _, blockedEvent in ipairs({ "ADDON_ACTION_BLOCKED", "ADDON_ACTION_FORBIDDEN" }) do
        env.C_ChatInfo.SendChatMessage = function()
            event(blockedEvent, "InCharacter", "C_ChatInfo.SendChatMessage()")
        end
        local ok, reason = IC.Actions.Dispatch("pool:quotes")
        eq(ok, false); eq(reason, "The game blocked this message."); eq(IC.Dialogue.states.quotes, nil)
        eq(#Stub.sends, 0)
    end
    env.C_ChatInfo.SendChatMessage = function(text, channel)
        event("ADDON_ACTION_BLOCKED", "OtherAddon", "UnrelatedFunction()")
        Stub.sends[#Stub.sends + 1] = { text, channel }
    end
    assert(IC.Actions.Dispatch("pool:quotes")); eq(Stub.sends[1][1], "first")
end)
test("blocked chat is reported plainly, never retried, and there is no debug command", function(IC, Stub, env, event)
    local pool = IC.Profile().pools.quotes; pool.lines = { "One user action" }
    local calls = 0
    env.C_ChatInfo.SendChatMessage = function()
        calls = calls + 1; event("ADDON_ACTION_BLOCKED", "InCharacter", "C_ChatInfo.SendChatMessage()")
    end
    local ok, reason = IC.Actions.Dispatch("pool:quotes")
    assert(not ok); eq(calls, 1); eq(#Stub.sends, 0); eq(IC.Dialogue.states.quotes, nil)
    eq(reason, "The game blocked this message.")
    eq(IC.Platform.lastBlockedAction, nil)
    eq(calls, 1); eq(#Stub.sends, 0)
end)
assert(loadfile("tests/ui_collections.lua"))()(test, eq, page)
assert(loadfile("tests/ui_input.lua"))()(test, eq, page)
assert(loadfile("tests/ui_audit.lua"))()(test, eq, page)
assert(loadfile("tests/ui_foundations.lua"))()(test, eq, page)
print("PASS: " .. tests .. " isolated mocked UI/integration tests (not a live-client test)")
