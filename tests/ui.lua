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

test("load registers commands, Settings page and shows the launcher without sending", function(IC, Stub, env)
    assert(IC.db); eq(env.SLASH_INCHARACTER1, "/incharacter"); eq(env.SLASH_INCHARACTER2, nil)
    eq(Stub.settingsCategory.name, "In Character"); assert(Stub.settingsPanel)
    assert(IC.Launcher.button:IsShown()); assert(IC.Bars.frames[1]:IsShown())
    eq(#Stub.sends, 0); eq(#Stub.emotes, 0)
end)

test("every page of the window builds and switching pages sends nothing", function(IC, Stub)
    for _, name in ipairs({ "Home", "Emotes", "Dialogue", "Favorites", "Layouts", "Profiles" }) do
        page(IC, name); assert(IC.Editor.pages[name]:IsShown())
        for other, p in pairs(IC.Editor.pages) do if other ~= name then assert(not p:IsShown()) end end
    end
    eq(#Stub.sends, 0); eq(#Stub.emotes, 0)
end)

test("home cards turn each layout option on and off", function(IC, Stub)
    local p = page(IC, "Home")
    p.launcherToggle:Click(); assert(not IC.Launcher.button:IsShown())
    p.launcherToggle:Click(); assert(IC.Launcher.button:IsShown())
    p.catToggle:Click()
    local auto = 0
    for _, bar in ipairs(IC.Layout().bars) do if bar.auto then auto = auto + 1 end end
    eq(auto, #IC.Emotes.categories); eq(#IC.Bars.frames, 1 + auto)
    p.catToggle:Click(); eq(#IC.Layout().bars, 1)
    p.favToggle:Click(); assert(IC.Layout().bars[1].hidden); assert(not IC.Bars.frames[1]:IsShown())
    p.launcherClick:Choose("wheel"); IC.Launcher.button:Click("LeftButton"); assert(IC.Wheel.open)
end)

test("emote library filters by what others can hear, searches, pins and tries emotes", function(IC, Stub)
    local p = page(IC, "Emotes")
    IC.Editor.emoteCategory = "all"; IC.Editor.RefreshEmotes()
    local everything = #p.shown
    for _, chip in ipairs(p.chips) do if chip.value == "sound" then chip:Click() end end
    assert(#p.shown > 0 and #p.shown < everything)
    for _, action in ipairs(p.shown) do assert(IC.Emotes.IsAudible(action)) end
    for _, chip in ipairs(p.chips) do if chip.value == "silent" then chip:Click() end end
    for _, action in ipairs(p.shown) do eq(action.kind, "animation") end
    for _, chip in ipairs(p.chips) do if chip.value == "all" then chip:Click() end end
    p.search:SetText("chick"); eq(#p.shown, 1); eq(p.shown[1].command, "chicken")
    p.tiles[1]:Click("RightButton"); assert(IC.Actions.IsFavorite("emote:chicken"))
    p.tiles[1]:Click("LeftButton"); assert(p.detail:IsShown()); eq(IC.Editor.emote.command, "chicken")
    p.dTry:Click(); eq(Stub.emotes[1], "CHICKEN")
    p.search:SetText("")
    p.hide:SetChecked(true); p.hide:Click()
    for _, action in ipairs(p.shown) do assert(action.verified) end
end)

test("emote library shows client-only emotes and disables unknown ones", function(IC, Stub)
    local p = page(IC, "Emotes")
    IC.Editor.emoteCategory = "all"; p.search:SetText("foreveronly"); eq(#p.shown, 1); eq(p.shown[1].kind, "unknown")
    p.search:SetText("flex"); eq(#p.shown, 1); assert(not p.shown[1].verified); assert(p.tiles[1].icon.desaturated)
    p.tiles[1]:Click(); IC.Editor.RefreshEmoteDetail(); eq(p.dTry.enabled, false)
end)

test("dialogue: preset copy, drafts survive switching, save, preview and shortcuts", function(IC, Stub)
    local p = page(IC, "Dialogue")
    p.pack:Choose("office-stanley"); Stub.Button(p, "Copy + use for /ic greet, quote, bye"):Click()
    local first = IC.Editor.poolID; eq(#IC.Profile().pools[first].lines, 5)
    p.lines:SetText("Hello, 'friend'.\nHé, hoe gaat het?")
    IC.Editor.SelectPool("quotes"); IC.Editor.SelectPool(first)
    eq(p.lines:GetText(), "Hello, 'friend'.\nHé, hoe gaat het?"); assert(p.info:GetText():find("unsaved"))
    eq(#IC.Profile().pools[first].lines, 5)
    p.mode:Choose("sequential"); Stub.Button(p, "Save"):Click()
    eq(#IC.Profile().pools[first].lines, 2); assert(not p.info:GetText():find("unsaved"))
    Stub.Button(p, "Preview"):Click(); eq(#Stub.sends, 0)
    IC.Slash("greet"); eq(Stub.sends[1][1], "Hello, 'friend'.")
end)

test("launcher menu lists favorites and categories, uses an emote and pins without closing", function(IC, Stub)
    IC.Launcher.button:Click("LeftButton"); assert(IC.Menu.IsOpen())
    local root = IC.Menu.levels[1]
    eq(root.entries[1].label, "Favorites")
    local combat
    for i, entry in ipairs(root.entries) do if entry.label == IC.Emotes.CategoryInfo.Combat.label then combat = i end end
    assert(combat and combat <= 16)
    root.rows[combat]:Fire("OnEnter")
    local flyout = IC.Menu.levels[2]; assert(flyout:IsShown()); assert(flyout.back:IsShown()); eq(flyout.entries[1].action.command, "charge")
    flyout.rows[1]:Click("RightButton"); assert(IC.Menu.IsOpen()); assert(flyout:IsShown())
    flyout.rows[1]:Click("LeftButton"); assert(not IC.Menu.IsOpen()); eq(Stub.emotes[1], "CHARGE")
end)

test("wheel starts with categories, requires explicit navigation and leaves the hub neutral", function(IC, Stub)
    IC.Wheel.Open(false); assert(IC.Wheel.open); eq(#IC.Wheel.stack, 0)
    point(Stub, IC, 0, 0); eq(IC.Wheel.hover, nil)
    local combat = IC.Wheel.outer[2]
    pointAt(Stub, IC, combat); eq(#IC.Wheel.stack, 0); eq(IC.Wheel.hover.action.id, "Combat")
    IC.Wheel.catcher:Fire("OnMouseDown", "LeftButton"); eq(IC.Wheel.Current().id, "Combat")
    eq(#IC.Wheel.items, 1); eq(IC.Wheel.items[1].command, "charge")
    pointAt(Stub, IC, IC.Wheel.outer[1]); eq(IC.Wheel.hover, IC.Wheel.outer[1])
    point(Stub, IC, 0, 0); eq(IC.Wheel.hover, nil); eq(#Stub.emotes, 0)
    pointAt(Stub, IC, IC.Wheel.outer[1])
    IC.Wheel.catcher:Fire("OnMouseDown", "LeftButton"); eq(Stub.emotes[1], "CHARGE"); assert(not IC.Wheel.open)
    IC.Wheel.Open(false); point(Stub, IC, 0, 0); IC.Wheel.catcher:Fire("OnMouseDown", "LeftButton")
    assert(not IC.Wheel.open); eq(#Stub.emotes, 1)
    IC.Wheel.Open(false); IC.Wheel.catcher:Fire("OnMouseDown", "RightButton"); assert(not IC.Wheel.open); eq(#Stub.emotes, 1)
end)

test("wheel hold mode uses the action under the cursor on release only", function(IC, Stub)
    IC.Profile().wheel.mode = "hold"
    IC.Wheel.Binding("down"); assert(IC.Wheel.open)
    pointAt(Stub, IC, IC.Wheel.outer[1]); IC.Wheel.catcher:Fire("OnMouseDown", "LeftButton")
    point(Stub, IC, 0, 0)
    pointAt(Stub, IC, IC.Wheel.outer[1]); local expected = IC.Wheel.items[1]
    Stub.clock = Stub.clock + 0.2
    eq(#Stub.emotes + #Stub.sends, 0)
    IC.Wheel.Binding("up"); assert(not IC.Wheel.open)
    if expected.type == "emote" then eq(Stub.emotes[1], expected.payload) else eq(#Stub.sends, 1) end
    IC.Wheel.Binding("down"); point(Stub, IC, 0, 0); IC.Wheel.Binding("up")
    assert(not IC.Wheel.open); eq(#Stub.emotes + #Stub.sends, 1)
    IC.Profile().wheel.mode = "click"; IC.Wheel.Binding("down"); IC.Wheel.Binding("up"); assert(IC.Wheel.open)
    IC.Wheel.Binding("down"); assert(not IC.Wheel.open)
end)

test("wheel pages long categories with the mouse wheel and opens in combat", function(IC, Stub, env, event)
    for i = 1, 14 do IC.Dialogue.Create("Line pool " .. i) end
    Stub.combat = true; event("PLAYER_REGEN_DISABLED")
    IC.Wheel.Open(false); assert(IC.Wheel.open)
    pointAt(Stub, IC, IC.Wheel.outer[#IC.Wheel.categories]); IC.Wheel.catcher:Fire("OnMouseDown", "LeftButton")
    eq(IC.Wheel.Current().id, "Roleplay")
    eq(#IC.Wheel.items, 1); pointAt(Stub, IC, IC.Wheel.outer[1]); IC.Wheel.catcher:Fire("OnMouseDown", "LeftButton")
    eq(#IC.Wheel.items, 8); IC.Wheel.catcher:Fire("OnMouseWheel", -1); eq(IC.Wheel.page, 2); eq(#IC.Wheel.items, 8)
    IC.Wheel.catcher:Fire("OnMouseWheel", -1); eq(IC.Wheel.page, 3); eq(#IC.Wheel.items, 1)
    IC.Wheel.Close()
end)

test("category bars show only their category and dispatch on click", function(IC, Stub)
    local p = page(IC, "Home"); p.catToggle:Click()
    local frame
    for i, bar in ipairs(IC.Layout().bars) do if bar.source == "Voice/Fun" then frame = IC.Bars.frames[i] end end
    local shown = 0
    for _, slot in ipairs(frame.buttons) do
        if slot:IsShown() then shown = shown + 1; assert(slot.action.categories["Voice/Fun"]) end
    end
    eq(shown, #IC.Actions.List("Voice/Fun"))
    for _, slot in ipairs(frame.buttons) do
        if slot.action.command == "chicken" then slot:Click(); assert(slot.kind:IsShown()) end
        if slot.action.command == "moo" then assert(slot.icon.desaturated) end
    end
    eq(Stub.emotes[1], "CHICKEN")
    frame.header:Click("LeftButton"); assert(frame.config.collapsed)
    frame.config.collapsed, frame.config.locked = false, true; IC.Bars.Refresh(); assert(not frame.header:IsShown())
end)

test("layouts page edits bars with dropdowns and sliders", function(IC, Stub)
    local p = page(IC, "Layouts")
    Stub.Button(p, "+ Add bar"):Click(); eq(#IC.Layout().bars, 2); eq(IC.Editor.barIndex, 2)
    p.bSource:Choose("Combat"); eq(IC.Layout().bars[2].source, "Combat")
    p.bSize:SetValue(48); eq(IC.Layout().bars[2].size, 48)
    p.bColumns:SetValue(3); eq(IC.Layout().bars[2].columns, 3)
    p.bOrientation:Choose("vertical"); assert(IC.Layout().bars[2].vertical)
    p.which:Choose(1); eq(IC.Editor.barIndex, 1); eq(p.bSource.value, "favorites")
    p.lSize:SetValue(52); eq(IC.Layout().launcher.size, 52); eq(IC.Launcher.button:GetWidth(), 52)
    p.wRadius:SetValue(200); eq(IC.Profile().wheel.radius, 200)
end)

test("key capture binds the wheel with modifiers and right-click clears it", function(IC, Stub)
    local p = page(IC, "Layouts")
    p.wKey:Click("LeftButton"); assert(p.wKey.capturing)
    p.wKey:Fire("OnKeyDown", "LSHIFT"); assert(p.wKey.capturing)
    Stub.modifiers.shift = true; p.wKey:Fire("OnKeyDown", "F"); Stub.modifiers.shift = nil
    eq(Stub.bindings["SHIFT-F"], "INCHARACTER_WHEEL"); assert(not p.wKey.capturing); assert(p.wKey:GetText():find("SHIFT%-F"))
    p.wKey:Click("RightButton"); eq(Stub.bindings["SHIFT-F"], nil); eq(Stub.savedBindings, 2)
    p.wKey:Click("LeftButton"); p.wKey:Fire("OnKeyDown", "ESCAPE"); assert(not p.wKey.capturing); eq(Stub.savedBindings, 2)
end)

test("missing icon files fall back instead of showing a blank texture", function(IC, Stub, env)
    local texture = env.UIParent:CreateTexture()
    Stub.missing["Interface\\Icons\\Gone"] = true
    IC.UI.SetIcon(texture, "Interface\\Icons\\Gone", "Interface\\Icons\\INV_Misc_Book_09"); eq(texture.texture, "Interface\\Icons\\INV_Misc_Book_09")
    local p = page(IC, "Dialogue")
    IC.Editor.PickIcon(nil, function(icon) IC.Editor.pickedIcon = icon end)
    IC.Editor.picker.slots[9]:Click(); Stub.Button(IC.Editor.picker, "Use icon"):Click(); eq(IC.Editor.pickedIcon, 134400)
end)

test("combat hides only the window, defers rebuilds and never replays chat", function(IC, Stub, env, event)
    page(IC, "Home"); Stub.combat = true; event("PLAYER_REGEN_DISABLED")
    assert(not IC.Editor.frame:IsShown())
    IC.Refresh(); assert(IC.refreshPending)
    IC.Launcher.button:Click("LeftButton"); assert(IC.Menu.IsOpen()); IC.Menu.Close()
    Stub.combat = false; event("PLAYER_REGEN_ENABLED"); assert(not IC.refreshPending); eq(#Stub.sends, 0)
end)

test("addon compartment opens the menu and settings", function(IC, Stub, env)
    env.InCharacter_OnAddonCompartmentClick("InCharacter", "LeftButton"); assert(IC.Menu.IsOpen()); IC.Menu.Close()
    env.InCharacter_OnAddonCompartmentClick("InCharacter", "RightButton"); assert(IC.Editor.frame:IsShown()); eq(IC.Editor.tab, "Home")
end)

test("wheel geometry: sectors start at the top and go clockwise; hub is a dead zone", function(IC)
    local M = IC.WheelModel
    eq(M.Sector(M.Angle(0, 10), 4), 1); eq(M.Sector(M.Angle(10, 0), 4), 2)
    eq(M.Sector(M.Angle(0, -10), 4), 3); eq(M.Sector(M.Angle(-10, 0), 4), 4)
    eq(M.Sector(M.Angle(-1, 10), 4), 1)
    local g = M.Geometry(160)
    eq(M.Hit(5, 5, g, 7, 12), "hub")
    local kind, index = M.Hit(0, g.hub + 4, g, 7, 12); eq(kind, "gap"); eq(index, nil)
    kind, index = M.Hit(g.outer, 0, g, 7, 12); eq(kind, "outer"); eq(index, 4)
    eq(M.Hit(0, 400, g, 7, 0), "outside")
    for i = 1, 12 do local x, y = M.Position(i, 12, g.outer); local _, hit = M.Hit(x, y, g, 7, 12); eq(hit, i) end
end)
test("review fixes: mouse-button wheel key, unmoved hold release, Esc closes flyouts, compartment table args", function(IC, Stub, env)
    Stub.bindings["BUTTON4"] = "INCHARACTER_WHEEL"; IC.Profile().wheel.mode = "hold"
    IC.Wheel.Binding("down"); assert(IC.Wheel.open)
    -- The catcher swallows the mouse button, so its release must still reach the binding.
    IC.Wheel.catcher:Fire("OnMouseUp", "Button4"); assert(not IC.Wheel.open)
    -- Opening with the cursor already over an action (edge clamping) and releasing without moving does nothing.
    IC.Wheel.Binding("down"); local slot = IC.Wheel.outer[1]; IC.Wheel.hover = slot; IC.Wheel.moved = false
    local x, y = slot:GetCenter(); Stub.cursorX, Stub.cursorY = x, y; IC.Wheel.start = { x - 960, y - 540 }
    IC.Wheel.Binding("up"); eq(#Stub.emotes + #Stub.sends, 0); assert(not IC.Wheel.open)
    IC.Launcher.button:Click("LeftButton"); IC.Menu.levels[1].rows[3]:Fire("OnEnter")
    local combat; for i, entry in ipairs(IC.Menu.levels[1].entries) do if entry.children then combat = i; break end end
    IC.Menu.levels[1].rows[combat]:Fire("OnEnter"); assert(IC.Menu.levels[2]:IsShown())
    IC.Menu.catcher:Hide(); assert(not IC.Menu.levels[2].shown)
    env.InCharacter_OnAddonCompartmentClick("InCharacter", { buttonName = "RightButton" }); assert(IC.Editor.frame:IsShown())
    local key = IC.Editor.pages.Home.wheelKey; key:Click("LeftButton"); assert(key.capturing)
    IC.Editor.frame:Hide(); key:Fire("OnHide"); assert(not key.capturing)
end)
assert(loadfile("tests/ui_enhancements.lua"))()(test, eq, page, point, pointAt)
assert(loadfile("tests/ui_input.lua"))()(test, eq, page)
assert(loadfile("tests/ui_layouts.lua"))()(test, eq, page, point, pointAt)
print("PASS: " .. tests .. " isolated mocked UI/integration tests (not a live-client test)")
