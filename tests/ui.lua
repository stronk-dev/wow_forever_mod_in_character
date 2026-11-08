local Stub = assert(loadfile("tests/wow_stub.lua"))()
Stub.Install()
local IC, tests = {}, 0
for line in io.lines("InCharacter/InCharacter.toc") do
    if line:match("%.lua$") then assert(loadfile("InCharacter/" .. line))("InCharacter", IC) end
end
local function eq(a, b) assert(a == b, tostring(a) .. " ~= " .. tostring(b)) end
local function test(name, fn)
    local ok, err = pcall(fn); if not ok then error("FAIL " .. name .. ": " .. tostring(err)) end
    tests = tests + 1; print("ok " .. tests .. " - " .. name)
end
local function selectWheel(id)
    for _, button in ipairs(IC.Wheel.buttons) do if button:IsShown() and button.action.id == id then button:Click(); return end end
    error("Missing wheel action: " .. id)
end
test("TOC initialization and slash registration leave existing aliases alone", function()
    SLASH_OTHER1 = "/ic"; SlashCmdList.OTHER = function() end
    for _, frame in ipairs(Stub.frames) do if frame.events.ADDON_LOADED then frame:Fire("OnEvent", "ADDON_LOADED", "InCharacter"); break end end
    assert(IC.db); eq(SLASH_INCHARACTER1, "/incharacter"); eq(SLASH_INCHARACTER2, nil); eq(#Stub.sends, 0)
    assert(IC.Bars.frames[1]:IsShown())
end)
test("all editor tabs construct, with no FontString-only calls on EditBox", function()
    IC.Editor.Toggle(); assert(IC.Editor.frame:IsShown())
    for _, name in ipairs({ "Emotes", "Dialogue Pools", "Bars", "Wheel", "Profiles" }) do IC.Editor.SelectTab(name); assert(IC.Editor.panels[name]:IsShown()) end
    eq(#Stub.sends, 0)
end)
test("editor installs a library preset then saves multiline quotes and previews without sending", function()
    IC.Editor.SelectTab("Dialogue Pools"); local panel = IC.Editor.panels["Dialogue Pools"]
    panel.pack:SetValue("office-stanley"); Stub.Button(panel, "Copy + greet/quote/bye"):Click()
    local pool = IC.Profile().pools[IC.Editor.poolID]; eq(#pool.lines, 5)
    panel.name:SetText("Custom Stanley"); panel.lines:SetText("Hello, 'friend'.\nHé, hoe gaat het?\n" .. string.rep("long", 100))
    panel.mode:SetValue("sequential"); panel.channel:SetValue("SAY"); Stub.Button(panel, "Save"):Click()
    eq(pool.name, "Custom Stanley"); eq(#pool.lines, 3); assert(#pool.lines[3] > 255)
    Stub.Button(panel, "Preview"):Click(); eq(#Stub.sends, 0); assert(IC.Editor.preview:IsShown())
    IC.Editor.preview:Hide(); IC.Slash("greet"); eq(#Stub.sends, 1); eq(Stub.sends[1][1], "Hello, 'friend'.")
    Stub.Button(panel, "Favorite"):Click(); assert(IC.Actions.IsFavorite("pool:" .. pool.id))
end)
test("bars dispatch shared actions and save independent configuration", function()
    IC.Editor.SelectTab("Bars"); local panel = IC.Editor.panels.Bars
    Stub.Button(panel, "Add bar"):Click(); eq(#IC.Layout().bars, 2)
    panel.source:SetValue("pool:" .. IC.Profile().shortcuts.greetings); panel.source:Click()
    -- Use the cycle callback to choose a source, as in the real UI.
    local bar = IC.Layout().bars[2]; bar.source = "pool:" .. IC.Profile().shortcuts.greetings; IC.Refresh()
    IC.Bars.frames[2].buttons[1]:Click(); eq(#Stub.sends, 2); eq(Stub.sends[2][1], "Hé, hoe gaat het?")
    IC.Bars.frames[2].header:Click(); assert(bar.collapsed)
    panel.checks.hidden:SetChecked(true); panel.checks.hidden:Click(); assert(bar.hidden); assert(not IC.Bars.frames[2]:IsShown())
    panel.checks.hidden:SetChecked(false); panel.checks.hidden:Click(); assert(IC.Bars.frames[2]:IsShown())
end)
test("wheel starts with immediately available favorites and supports nested Roleplay", function()
    IC.Wheel.Open(false); assert(IC.Wheel.open); assert(IC.Wheel.quick[1]:IsShown())
    selectWheel("roleplay"); eq(#IC.Wheel.state.stack, 2)
    selectWheel("office-stanley"); eq(#IC.Wheel.state.stack, 3)
    local first = IC.Wheel.buttons[1].action; eq(first.type, "pool")
    IC.Wheel.back:Click(); eq(#IC.Wheel.state.stack, 2); eq(#Stub.sends, 2)
    IC.Wheel.catcher:Hide(); assert(not IC.Wheel.open); eq(#Stub.sends, 2)
end)
test("wheel click-confirm sends once and right-click cancels", function()
    local pool = IC.Profile().pools[IC.Profile().shortcuts.greetings]; pool.lines = { "Click me" }; IC.Dialogue.Clear()
    IC.Wheel.Open(false); selectWheel("roleplay"); selectWheel("office-stanley")
    IC.Wheel.buttons[1]:Click("RightButton"); assert(not IC.Wheel.open); eq(#Stub.sends, 2)
    IC.Wheel.Open(false); selectWheel("roleplay"); selectWheel("office-stanley")
    IC.Wheel.buttons[1]:Click(); assert(not IC.Wheel.open); eq(#Stub.sends, 3); eq(Stub.sends[3][1], "Click me")
end)
test("experimental release requires dwell and never executes submenus or stale selections", function()
    IC.Profile().wheel.mode = "hold"; local W = IC.Wheel
    W.Binding("down"); W.hover = W.buttons[1]; W.hoverSince = Stub.clock - 1; Stub.clock = Stub.clock + 1
    W.Binding("up"); eq(#Stub.sends, 3); assert(not W.open)
    W.Binding("down"); selectWheel("roleplay"); selectWheel("office-stanley")
    W.hover = W.buttons[1]; W.hoverSince = Stub.clock; W.Binding("up"); eq(#Stub.sends, 3)
    W.Binding("down"); selectWheel("roleplay"); selectWheel("office-stanley")
    W.hover = W.buttons[1]; W.hoverSince = Stub.clock; Stub.clock = Stub.clock + 0.2
    W.Binding("up"); eq(#Stub.sends, 4)
    W.Binding("down"); selectWheel("roleplay"); selectWheel("office-stanley"); W.back:Click()
    W.Binding("up"); eq(#Stub.sends, 4)
end)
test("click mode remains open on binding release and slash wheel always click-confirms", function()
    IC.Profile().wheel.mode = "click"; IC.Wheel.Binding("down"); IC.Wheel.Binding("up"); assert(IC.Wheel.open)
    IC.Wheel.Binding("down"); assert(not IC.Wheel.open)
    IC.Profile().wheel.mode = "hold"; IC.Wheel.Open(false); IC.Wheel.Binding("up"); assert(IC.Wheel.open); IC.Wheel.Close()
    eq(#Stub.sends, 4)
end)
test("combat closes wheel/editor and defers rebuilds without replaying sends", function()
    IC.Wheel.Open(false); Stub.combat = true
    for _, frame in ipairs(Stub.frames) do if frame.events.PLAYER_REGEN_DISABLED then frame:Fire("OnEvent", "PLAYER_REGEN_DISABLED") end end
    assert(not IC.Wheel.open); assert(not IC.Editor.frame:IsShown())
    IC.Refresh(); assert(IC.refreshPending); IC.Wheel.Open(false); assert(not IC.Wheel.open)
    Stub.combat = false
    for _, frame in ipairs(Stub.frames) do if frame.events.PLAYER_REGEN_ENABLED then frame:Fire("OnEvent", "PLAYER_REGEN_ENABLED") end end
    assert(not IC.refreshPending); eq(#Stub.sends, 4)
end)
test("wheel model exposes every pool across pages and back navigation", function()
    for i = 1, 25 do IC.Dialogue.Create("More " .. i) end
    local M = IC.WheelModel; local state = M.New(M.Tree())
    local roleplay = state.stack[1].children[7]; M.Enter(state, roleplay); M.Enter(state, roleplay.children[1])
    local seen = {}; local _, pages = M.Items(state, 8)
    for _ = 1, pages do for _, action in ipairs(M.Items(state, 8)) do seen[action.id] = true end; M.Page(state, 1, 8) end
    local count = 0; for _ in pairs(seen) do count = count + 1 end; eq(count, 28)
    assert(M.Back(state)); assert(M.Back(state)); assert(not M.Back(state)); eq(state.page, 1)
end)
print("PASS: " .. tests .. " mocked UI/integration tests (not a live-client test)")
