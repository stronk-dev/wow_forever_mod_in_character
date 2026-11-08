local IC = {}
local function load(path) assert(loadfile("InCharacter/" .. path))("InCharacter", IC) end
load("Core.lua"); load("Defaults.lua"); load("Data/EmoteCatalog.lua"); load("Data/Emotes.lua")
load("Services/Profiles.lua"); load("Services/Dialogue.lua"); load("Services/Actions.lua")
local total = 0
local function test(name, fn)
    local ok, err = pcall(fn)
    if not ok then error("FAIL " .. name .. ": " .. tostring(err)) end
    total = total + 1; print("ok " .. total .. " - " .. name)
end
local function eq(a, b) assert(a == b, tostring(a) .. " ~= " .. tostring(b)) end
-- Simulate Blizzard selecting a SavedVariablesPerCharacter table on each login.
local characterStores = setmetatable({}, { __mode = "k" })
local function open(db, key)
    db, key = db or {}, key or "Realm:Player"
    characterStores[db] = characterStores[db] or {}
    local store = characterStores[db]; store[key] = store[key] or {}
    IC.db = IC.Profiles.Open(db, store[key], { key }); IC.Dialogue.Clear()
    return IC.db
end
test("sequential loops", function()
    local state, pool = {}, { mode = "sequential", lines = { "a", "b", "c" } }
    for _, expected in ipairs({ "a", "b", "c", "a" }) do eq(IC.Dialogue.Next(pool, state), expected) end
end)
test("random maps requested indices directly and allows repeats", function()
    local pool, state = { mode = "random", lines = { "a", "b", "c" } }, {}
    for i = 1, 3 do
        for _ = 1, 2 do eq(IC.Dialogue.Next(pool, state, function(n) eq(n, 3); return i end), pool.lines[i]) end
    end
end)
test("random distribution sanity with fixed seed", function()
    math.randomseed(5101)
    local pool, state, counts = { mode = "random", lines = { "a", "b", "c" } }, {}, { a = 0, b = 0, c = 0 }
    for _ = 1, 30000 do local line = IC.Dialogue.Next(pool, state); counts[line] = counts[line] + 1 end
    for _, n in pairs(counts) do assert(n > 9500 and n < 10500, "biased selection") end
end)
test("shuffle is a permutation each cycle", function()
    local pool, state = { mode = "shuffle", lines = { "a", "b", "c", "d" } }, {}
    for _ = 1, 20 do
        local seen = {}
        for _ = 1, 4 do local line = IC.Dialogue.Next(pool, state); assert(not seen[line]); seen[line] = true end
    end
end)
test("all modes handle empty and singleton pools", function()
    for _, mode in ipairs({ "random", "shuffle", "sequential" }) do
        eq(IC.Dialogue.Next({ mode = mode, lines = {} }), nil)
        local state = {}
        for _ = 1, 4 do eq(IC.Dialogue.Next({ mode = mode, lines = { "één 'quote'" } }, state), "één 'quote'") end
    end
end)
test("selection resets after same-length edit and mode change", function()
    local pool, state = { mode = "sequential", lines = { "a", "b" } }, {}
    eq(IC.Dialogue.Next(pool, state), "a"); pool.lines[1] = "c"
    eq(IC.Dialogue.Next(pool, state), "c"); pool.mode = "shuffle"
    assert(IC.Dialogue.Next(pool, state)); eq(#state.bag, 1)
end)
test("defaults are independent deep copies", function()
    local a, b = IC.Defaults.Profile(), IC.Defaults.Profile()
    a.pools.quotes.lines[1] = "mine"; eq(#b.pools.quotes.lines, 0)
end)
test("merge retains false, empty lists, user strings and adds record defaults", function()
    local db = open(); db.profiles.account.favorites = {}; db.profiles.account.hideUnverified = false
    db.profiles.account.wheel = { mode = "hold" }
    db.profiles.account.pools.quotes.lines = { "don't change me" }
    open(db); eq(#IC.Profile().favorites, 0); eq(IC.Profile().wheel.mode, "hold")
    eq(IC.Profile().wheel.radius, 165); eq(IC.Profile().pools.quotes.lines[1], "don't change me")
end)
test("v1 migration retains user and unknown data", function()
    local account = IC.Defaults.Profile(); account.pools.quotes.lines = { "old" }
    local db = open({ version = 1, account = account, customFutureKey = "keep" })
    eq(db.version, 4); eq(IC.Profile().pools.quotes.lines[1], "old"); eq(db.customFutureKey, "keep")
end)
test("deleted defaults stay deleted across upgrades", function()
    local db = open(); IC.Dialogue.Delete("quotes"); open(db)
    eq(IC.Profile().pools.quotes, nil); eq(#IC.Profile().poolOrder, 2)
end)
test("characters isolate pools and layouts; shared account remains available", function()
    local db = open(); IC.Profiles.SetScope("character"); IC.Profile().pools.quotes.lines = { "only A" }
    IC.Layout().bars[1].x = 42; open(db, "Realm:Other")
    eq(#IC.Profile().pools.quotes.lines, 0); eq(IC.Layout().bars[1].x, 0)
    open(db); eq(IC.Profile().pools.quotes.lines[1], "only A"); eq(IC.Layout().bars[1].x, 42)
    IC.Profiles.SetScope("account"); eq(#IC.Profile().pools.quotes.lines, 0)
end)
test("reset only active profile and future schema is refused", function()
    local db = open(); IC.Profiles.SetScope("character"); IC.Profile().pools.quotes.lines = { "reset" }
    IC.Profiles.Reset(); eq(#IC.Profile().pools.quotes.lines, 0)
    eq(IC.Profiles.Character().scope, "character")
    local future = { version = 999 }; assert(not pcall(open, future)); eq(future.version, 999)
end)
test("preview never consumes state or sends", function()
    open(); local pool = IC.Profile().pools.quotes; pool.mode = "sequential"; pool.lines = { "a", "b" }
    eq(IC.Dialogue.Preview(pool), "a"); eq(IC.Dialogue.Select(pool), "a")
    eq(IC.Dialogue.Preview(pool), "b"); eq(IC.Dialogue.Select(pool), "b")
end)
test("dispatcher sends once, validates channel, refuses long text and empty pools", function()
    open(); local calls = 0; C_ChatInfo = { SendChatMessage = function(text, channel) calls = calls + 1; eq(text, "Hello!"); eq(channel, "SAY") end }
    local pool = IC.Profile().pools.quotes
    assert(not IC.Actions.Dispatch("pool:quotes")); eq(calls, 0)
    pool.lines = { "Hello!" }; assert(IC.Actions.Dispatch("pool:quotes")); eq(calls, 1)
    pool.lines = { string.rep("é", 128) }; assert(not IC.Actions.Dispatch("pool:quotes")); eq(calls, 1)
    pool.channel = "GUILD"; assert(not IC.Actions.Dispatch("pool:quotes")); eq(calls, 1)
    C_ChatInfo = nil
end)
test("emotes are gated by runtime token recognition", function()
    open(); local calls = 0; DoEmote = function(token) eq(token, "WAVE"); calls = calls + 1 end
    IC.Emotes.Validate(); assert(not IC.Actions.Dispatch("emote:wave"))
    EMOTE1_TOKEN, EMOTE1_CMD1 = "WAVE", "/wave"; IC.Emotes.Validate()
    assert(IC.Actions.Dispatch("emote:wave")); eq(calls, 1)
    EMOTE1_TOKEN, EMOTE1_CMD1, DoEmote = nil, nil, nil
end)
test("custom pool normalization, unique IDs and favorite cleanup", function()
    open(); local one = IC.Dialogue.Create("My RP's"); local two = IC.Dialogue.Create("My RP's")
    assert(one.id ~= two.id); eq(IC.Dialogue.Find(one.id), one)
    eq(IC.Dialogue.Find("my rps"), nil)
    IC.Actions.Favorite("pool:" .. one.id); assert(IC.Actions.IsFavorite("pool:" .. one.id))
    IC.Dialogue.Delete(one.id); assert(not IC.Actions.IsFavorite("pool:" .. one.id))
end)
assert(loadfile("tests/library.lua"))()(IC, test, eq, open)
test("new bar defaults merge into existing layouts without restoring deleted bars", function()
    local db = open(); IC.Layout().bars = { { name = "Old", x = 55, hidden = true } }
    db.sharedLayout.bars = {}; open(db)
    eq(IC.Layout().bars[1].source, "favorites"); eq(IC.Layout().bars[1].name, "Old"); eq(IC.Layout().bars[1].x, 55)
    eq(IC.Layout().bars[1].hidden, true); eq(#db.sharedLayout.bars, 0)
end)
test("emote label/icon overrides do not change trusted tokens", function()
    open(); IC.Profile().emoteOverrides["emote:wave"] = { label = "Hi!", icon = IC.Icons[2] }
    local action = IC.Actions.Resolve("emote:wave"); eq(action.label, "Hi!"); eq(action.icon, IC.Icons[2]); eq(action.payload, "WAVE")
    eq(IC.Emotes.byID["emote:wave"].label, "/wave")
end)
test("failed chat attempts are not queued and preserve selection", function()
    open(); local pool = IC.Profile().pools.quotes; pool.lines = { "first", "second" }; pool.mode = "sequential"
    C_ChatInfo = { SendChatMessage = function() error("blocked by client") end }
    assert(not IC.Actions.Dispatch("pool:quotes"))
    C_ChatInfo = { SendChatMessage = function(text) eq(text, "first") end }
    assert(IC.Actions.Dispatch("pool:quotes")); C_ChatInfo = nil
end)
test("deleting preset pools clears dangling shortcuts", function()
    open(); IC.Library.Install("office-stanley", true)
    local id = IC.Profile().shortcuts.greetings; IC.Dialogue.Delete(id); eq(IC.Profile().shortcuts.greetings, nil)
end)
assert(loadfile("tests/regressions.lua"))()(IC, test, eq, open)
assert(loadfile("tests/messages.lua"))()(IC, test, eq, open)
print("PASS: " .. total .. " tests")
