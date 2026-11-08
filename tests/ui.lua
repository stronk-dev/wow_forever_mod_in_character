-- Each test loads a fresh addon and WoW globals; no state/order dependencies.
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
local function panel(IC, tab)
    if not IC.Editor.frame then IC.Editor.Toggle() end
    IC.Editor.SelectTab(tab)
    return IC.Editor.panels[tab]
end
local function cycleTo(button, value)
    for _ = 1, #button.values do if button.value == value then return end; button:Click() end
    eq(button.value, value)
end
local function install(IC)
    local ok, _, id = IC.Library.Install("office-stanley", true); assert(ok)
    return id
end
local function selectWheel(IC, id)
    for _, button in ipairs(IC.Wheel.buttons) do if button:IsShown() and button.action.id == id then button:Click(); return end end
    error("Missing wheel action: " .. id)
end
local function point(Stub, IC, button)
    local x, y = button:GetCenter(); local scale = IC.Wheel.frame:GetEffectiveScale()
    Stub.cursorX, Stub.cursorY = x * scale, y * scale
    IC.Wheel.frame:Fire("OnUpdate", 0.016)
    eq(IC.Wheel.hover, button)
end
test("TOC initialization preserves existing slash aliases and creates the wheel before use", function(IC, Stub, env)
    assert(IC.db); eq(env.SLASH_INCHARACTER1, "/incharacter"); eq(env.SLASH_INCHARACTER2, nil)
    eq(#Stub.sends, 0); assert(IC.Bars.frames[1]:IsShown()); assert(IC.Wheel.frame); assert(not IC.Wheel.open)
    eq(env.InCharacterCharDB, IC.Profiles.Character()); eq(IC.Profiles.Character().profile, nil)
end)
test("all editor tabs construct without FontString-only calls on EditBox", function(IC, Stub)
    for _, name in ipairs({ "Emotes", "Dialogue Pools", "Bars", "Wheel", "Profiles" }) do assert(panel(IC, name):IsShown()) end
    eq(#Stub.sends, 0)
end)
test("editor copies a preset, saves multiline text and previews without sending", function(IC, Stub)
    local p = panel(IC, "Dialogue Pools"); cycleTo(p.pack, "office-stanley")
    Stub.Button(p, "Copy + greet/quote/bye"):Click()
    local pool = IC.Profile().pools[IC.Editor.poolID]; eq(#pool.lines, 5)
    p.name:SetText("Custom Stanley"); p.lines:SetText("Hello, 'friend'.\nHé, hoe gaat het?\n" .. string.rep("long", 100))
    cycleTo(p.mode, "sequential"); cycleTo(p.channel, "SAY"); Stub.Button(p, "Save"):Click()
    eq(pool.name, "Custom Stanley"); eq(#pool.lines, 3); assert(#pool.lines[3] > 255)
    Stub.Button(p, "Preview"):Click(); eq(#Stub.sends, 0); assert(IC.Editor.preview:IsShown())
    IC.Editor.preview:Hide(); IC.Slash("greet"); eq(#Stub.sends, 1); eq(Stub.sends[1][1], "Hello, 'friend'.")
    Stub.Button(p, "Favorite"):Click(); assert(IC.Actions.IsFavorite("pool:" .. pool.id))
end)
test("pool drafts survive switching pools and tabs without changing saved text", function(IC, Stub)
    local p = panel(IC, "Dialogue Pools")
    p.lines:SetText("unsaved greeting"); p.name:SetText("Draft name")
    p.rows[2]:Click(); p.rows[1]:Click(); eq(p.lines:GetText(), "unsaved greeting"); eq(p.name:GetText(), "Draft name")
    panel(IC, "Bars"); panel(IC, "Dialogue Pools"); eq(p.lines:GetText(), "unsaved greeting")
    eq(#IC.Profile().pools.greetings.lines, 0); eq(IC.Profile().pools.greetings.name, "Greetings")
    Stub.Button(p, "Discard draft"):Click(); eq(p.lines:GetText(), ""); eq(p.name:GetText(), "Greetings"); eq(#Stub.sends, 0)
end)
test("bars select sources through cycle callbacks and dispatch the shared action", function(IC, Stub)
    local id = install(IC); local pool = IC.Profile().pools[id]; pool.mode = "sequential"; pool.lines = { "one", "two" }
    local p = panel(IC, "Bars"); Stub.Button(p, "Add bar"):Click(); eq(#IC.Layout().bars, 2)
    cycleTo(p.source, "pool:" .. id)
    local bar = IC.Layout().bars[2]; eq(bar.source, "pool:" .. id)
    IC.Bars.frames[2].buttons[1]:Click(); eq(#Stub.sends, 1); eq(Stub.sends[1][1], "one")
    IC.Bars.frames[2].header:Click(); assert(bar.collapsed)
    p.checks.hidden:SetChecked(true); p.checks.hidden:Click(); assert(bar.hidden); assert(not IC.Bars.frames[2]:IsShown())
    p.checks.hidden:SetChecked(false); p.checks.hidden:Click(); assert(IC.Bars.frames[2]:IsShown())
end)
test("favorite bindings use the same filtered slots as the bar", function(IC, Stub, env)
    IC.Profile().pools.quotes.lines = { "visible favorite" }
    IC.Profile().favorites = { "emote:dance", "pool:quotes", "emote:wave" }; IC.Profile().hideUnverified = true
    IC.Refresh(); eq(IC.Bars.frames[1].buttons[1].action.id, "pool:quotes")
    env.InCharacter_FavoriteBinding(1); eq(#Stub.sends, 1); eq(Stub.sends[1][1], "visible favorite")
end)
test("wheel has direct favorites, nested Roleplay and Back without sending", function(IC, Stub)
    install(IC); IC.Wheel.Open(false); assert(IC.Wheel.quick[1]:IsShown())
    selectWheel(IC, "roleplay"); eq(#IC.Wheel.state.stack, 2)
    selectWheel(IC, "office-stanley"); eq(#IC.Wheel.state.stack, 3); eq(IC.Wheel.buttons[1].action.type, "pool")
    IC.Wheel.back:Click(); eq(#IC.Wheel.state.stack, 2); eq(#Stub.sends, 0)
    IC.Wheel.catcher:Hide(); assert(not IC.Wheel.open); eq(#Stub.sends, 0)
end)
test("wheel click sends once; right-click and Escape frame cancellation send nothing", function(IC, Stub, env)
    local id = install(IC); IC.Profile().pools[id].lines = { "Click me" }
    IC.Wheel.Open(false); selectWheel(IC, "roleplay"); selectWheel(IC, "office-stanley")
    IC.Wheel.buttons[1]:Click("RightButton"); assert(not IC.Wheel.open); eq(#Stub.sends, 0)
    IC.Wheel.Open(false); env.InCharacterWheelCatcher:Hide(); IC.Wheel.Binding("up"); eq(#Stub.sends, 0)
    IC.Wheel.Open(false); selectWheel(IC, "roleplay"); selectWheel(IC, "office-stanley")
    IC.Wheel.buttons[1]:Click(); assert(not IC.Wheel.open); eq(#Stub.sends, 1); eq(Stub.sends[1][1], "Click me")
end)
test("release mode uses cursor hit-testing, dwell and fresh page selection", function(IC, Stub)
    local id = install(IC); IC.Profile().pools[id].lines = { "Release me" }; IC.Profile().wheel.mode = "hold"
    local W = IC.Wheel
    W.Binding("down"); point(Stub, IC, W.buttons[1]); Stub.clock = Stub.clock + 1
    W.Binding("up"); eq(#Stub.sends, 0); assert(not W.open) -- submenu
    W.Binding("down"); selectWheel(IC, "roleplay"); selectWheel(IC, "office-stanley")
    point(Stub, IC, W.buttons[1]); W.Binding("up"); eq(#Stub.sends, 0) -- no dwell
    W.Binding("down"); selectWheel(IC, "roleplay"); selectWheel(IC, "office-stanley")
    point(Stub, IC, W.buttons[1]); Stub.clock = Stub.clock + 0.2; W.Binding("up")
    eq(#Stub.sends, 1); eq(Stub.sends[1][1], "Release me")
    W.Binding("down"); selectWheel(IC, "roleplay"); selectWheel(IC, "office-stanley")
    point(Stub, IC, W.buttons[1]); Stub.clock = Stub.clock + 0.2
    Stub.cursorX, Stub.cursorY = -1000, -1000; W.frame:Fire("OnUpdate", 0.016)
    eq(W.hover, nil); W.Binding("up"); eq(#Stub.sends, 1) -- gap cancels
    W.Binding("down"); selectWheel(IC, "roleplay"); selectWheel(IC, "office-stanley")
    point(Stub, IC, W.buttons[1]); W.back:Click(); eq(W.hover, nil); W.Binding("up"); eq(#Stub.sends, 1)
end)
test("click binding remains open on release; slash opening ignores release mode", function(IC, Stub)
    IC.Profile().wheel.mode = "click"; IC.Wheel.Binding("down"); IC.Wheel.Binding("up"); assert(IC.Wheel.open)
    IC.Wheel.Binding("down"); assert(not IC.Wheel.open)
    IC.Profile().wheel.mode = "hold"; IC.Wheel.Open(false); IC.Wheel.Binding("up"); assert(IC.Wheel.open); IC.Wheel.Close()
    eq(#Stub.sends, 0)
end)
test("combat wheel stays usable while editor closes and layout rebuilds defer", function(IC, Stub, env, event)
    env.EMOTE2_TOKEN, env.EMOTE2_CMD1 = "OOM", "/oom"; IC.Emotes.Validate()
    IC.Editor.Toggle(); IC.Wheel.Open(false); Stub.combat = true; event("PLAYER_REGEN_DISABLED")
    assert(IC.Wheel.open); assert(not IC.Editor.frame:IsShown())
    selectWheel(IC, "Combat"); selectWheel(IC, "emote:oom"); eq(#Stub.emotes, 1); eq(Stub.emotes[1], "OOM")
    IC.Wheel.Open(false); assert(IC.Wheel.open)
    IC.Refresh(); assert(IC.refreshPending)
    Stub.combat = false; event("PLAYER_REGEN_ENABLED"); assert(not IC.refreshPending); eq(#Stub.sends, 0)
end)
test("combat chat lockdown leaves pool state unchanged and never replays on combat end", function(IC, Stub, env, event)
    local id = install(IC); IC.Profile().pools[id].lines = { "blocked" }
    env.C_ChatInfo.InChatMessagingLockdown = function() return true end
    Stub.combat = true; IC.Wheel.Open(false); selectWheel(IC, "roleplay"); selectWheel(IC, "office-stanley")
    IC.Wheel.buttons[1]:Click(); eq(#Stub.sends, 0); eq(IC.Dialogue.states[id], nil)
    Stub.combat = false; event("PLAYER_REGEN_ENABLED"); eq(#Stub.sends, 0)
end)
test("realm formatting changes cannot switch live character settings", function(IC, Stub, env)
    env.GetRealmName = function() return "Argent Dawn" end
    env.UnitFullName = function() return "Tester", nil end
    IC.Profiles.SetScope("character"); IC.Profile().pools.quotes.lines = { "stay" }; IC.Layout().bars[1].x = 51
    local db, char = env.InCharacterDB, env.InCharacterCharDB
    env.UnitFullName = function() return "Tester", "ArgentDawn" end
    IC.Initialize(db, char); eq(IC.Profile().pools.quotes.lines[1], "stay"); eq(IC.Layout().bars[1].x, 51)
    eq(IC.Profiles.Character(), char); eq(#Stub.sends, 0)
end)
test("wheel model exposes every custom pool across pages and Back", function(IC)
    for i = 1, 25 do IC.Dialogue.Create("More " .. i) end
    local M = IC.WheelModel; local state = M.New(M.Tree()); local roleplay = state.stack[1].children[7]
    M.Enter(state, roleplay); M.Enter(state, roleplay.children[1])
    local seen = {}; local _, pages = M.Items(state, 8)
    for _ = 1, pages do for _, action in ipairs(M.Items(state, 8)) do seen[action.id] = true end; M.Page(state, 1, 8) end
    local count = 0; for _ in pairs(seen) do count = count + 1 end; eq(count, 28)
    assert(M.Back(state)); assert(M.Back(state)); assert(not M.Back(state)); eq(state.page, 1)
end)
print("PASS: " .. tests .. " isolated mocked UI/integration tests (not a live-client test)")
