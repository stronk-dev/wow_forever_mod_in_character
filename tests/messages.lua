return function(IC, test, eq, open)
    local function sample()
        open(); local pool = IC.Profile().pools.quotes; pool.mode = "sequential"; pool.lines = { "first", "second", "third" }
        IC.Dialogue.EnsureLines(pool); return pool
    end
    test("message IDs migrate once, remain unique and never overwrite existing text", function()
        local pool = sample(); local ids = IC.Copy(pool.lineIDs)
        IC.Dialogue.EnsureLines(pool); eq(#ids, 3)
        for i = 1, 3 do eq(pool.lineIDs[i], ids[i]); for j = i + 1, 3 do assert(ids[i] ~= ids[j]) end end
        local db = IC.db; open(db); eq(IC.Profile().pools.quotes.lineIDs[2], ids[2]); eq(IC.Profile().pools.quotes.lines[2], "second")
    end)
    test("explicit message sends exactly that line without consuming any playback state", function()
        local pool = sample(); local messages = {}; C_ChatInfo = { SendChatMessage = function(text) messages[#messages + 1] = text end }
        eq(IC.Dialogue.Select(pool), "first")
        assert(IC.Actions.Dispatch("line:quotes:" .. pool.lineIDs[3])); eq(messages[1], "third")
        eq(IC.Dialogue.Select(pool), "second"); C_ChatInfo = nil
    end)
    test("random/shuffle/sequential override states are independent of the pool's normal playback", function()
        local pool = sample(); local messages = {}; C_ChatInfo = { SendChatMessage = function(text) messages[#messages + 1] = text end }
        eq(IC.Dialogue.Select(pool), "first")
        assert(IC.Actions.Dispatch("play:sequential:quotes")); eq(messages[1], "first")
        assert(IC.Actions.Dispatch("play:sequential:quotes")); eq(messages[2], "second")
        local shuffled = {}; for _ = 1, 3 do assert(IC.Actions.Dispatch("play:shuffle:quotes")); shuffled[messages[#messages]] = true end
        local count = 0; for _ in pairs(shuffled) do count = count + 1 end; eq(count, 3)
        assert(IC.Actions.Dispatch("play:random:quotes")); eq(IC.Dialogue.Select(pool), "second"); C_ChatInfo = nil
    end)
    test("preview of an override or exact message never advances its state", function()
        local pool = sample(); eq(IC.Dialogue.Preview(pool, "sequential"), "first"); eq(IC.Dialogue.Select(pool, "sequential"), "first")
        eq(IC.Dialogue.Line(pool, pool.lineIDs[3]), "third"); eq(IC.Dialogue.Select(pool, "sequential"), "second")
    end)
    test("pinned message follows explicit edits and reordering but deletion never retargets it", function()
        local pool = sample(); local id = pool.lineIDs[2]; local actionID = "line:quotes:" .. id
        IC.Actions.Favorite(actionID); assert(IC.Actions.IsFavorite(actionID))
        assert(IC.Dialogue.SaveLine(pool, id, "edited second")); eq(IC.Dialogue.Line(pool, id), "edited second")
        assert(IC.Dialogue.MoveLine(pool, id, -1)); eq(pool.lines[1], "edited second"); eq(pool.lineIDs[1], id)
        local stale = IC.Actions.Resolve(actionID); assert(IC.Dialogue.DeleteLine(pool, id)); eq(IC.Actions.Resolve(actionID), nil)
        assert(not IC.Actions.IsFavorite(actionID)); C_ChatInfo = { SendChatMessage = function() error("deleted message must not send") end }
        assert(not IC.Actions.Dispatch(stale)); C_ChatInfo = nil
        local ok, _, new = IC.Dialogue.SaveLine(pool, nil, "replacement"); assert(ok); assert(new ~= id)
    end)
    test("bulk reorder keeps IDs; replacing text creates a fresh ID and removes stale pins", function()
        local pool = sample(); local first, third = pool.lineIDs[1], pool.lineIDs[3]
        IC.Actions.Favorite("line:quotes:" .. first)
        assert(IC.Dialogue.Save(pool, pool.name, pool.channel, pool.mode, pool.icon, { "third", "first", "second" }))
        eq(pool.lineIDs[1], third); eq(pool.lineIDs[2], first)
        assert(IC.Dialogue.Save(pool, pool.name, pool.channel, pool.mode, pool.icon, { "third", "new", "second" }))
        assert(pool.lineIDs[2] ~= first); assert(not IC.Actions.IsFavorite("line:quotes:" .. first))
    end)
    test("duplicate message text has distinct IDs that survive a bulk save", function()
        local pool = sample(); assert(IC.Dialogue.Save(pool, pool.name, pool.channel, pool.mode, pool.icon, { "same", "same", "third" }))
        assert(pool.lineIDs[1] ~= pool.lineIDs[2]); local ids = IC.Copy(pool.lineIDs)
        assert(IC.Dialogue.Save(pool, pool.name, pool.channel, pool.mode, pool.icon, pool.lines))
        eq(pool.lineIDs[1], ids[1]); eq(pool.lineIDs[2], ids[2])
    end)
    test("message edit validation keeps stored oversized UTF-8, rejects multiline and stale IDs", function()
        local pool = sample(); local id = pool.lineIDs[1]
        assert(not IC.Dialogue.SaveLine(pool, id, "a\nb")); assert(not IC.Dialogue.SaveLine(pool, "missing", "new"))
        local text = string.rep("é", 150); assert(IC.Dialogue.SaveLine(pool, id, text)); eq(IC.Dialogue.Line(pool, id), text)
        local calls = 0; C_ChatInfo = { SendChatMessage = function() calls = calls + 1 end }
        assert(not IC.Actions.Dispatch("line:quotes:" .. id)); eq(calls, 0); C_ChatInfo = nil
    end)
    test("lockdown and failed sends preserve override states and exact messages never queue", function()
        local pool = sample(); C_ChatInfo = { InChatMessagingLockdown = function() return true end, SendChatMessage = function() error("must not send") end }
        assert(not IC.Actions.Dispatch("line:quotes:" .. pool.lineIDs[1])); assert(not IC.Actions.Dispatch("play:shuffle:quotes"))
        eq(next(IC.Dialogue.states), nil)
        C_ChatInfo = { SendChatMessage = function() error("blocked") end }
        assert(not IC.Actions.Dispatch("play:sequential:quotes")); eq(IC.Dialogue.states[IC.Dialogue.StateKey(pool, "sequential")], nil)
        C_ChatInfo = nil
    end)
    test("editing one pool does not reset another pool's playback", function()
        local pool = sample(); local other = IC.Profile().pools.greetings; other.mode = "sequential"; other.lines = { "one", "two" }
        eq(IC.Dialogue.Select(other), "one"); assert(IC.Dialogue.SaveLine(pool, pool.lineIDs[1], "changed")); eq(IC.Dialogue.Select(other), "two")
    end)
    test("legacy joke pins and overrides canonicalize once and unpin without duplicates", function()
        local db = open(); IC.Profile().favorites = { "emote:joke", "emote:silly", "pool:quotes" }
        IC.Profile().emoteOverrides["emote:joke"] = { label = "My joke" }
        open(db); eq(#IC.Profile().favorites, 2); eq(IC.Profile().favorites[1], "emote:silly")
        eq(IC.Actions.Resolve("emote:joke").name, "My joke"); assert(IC.Actions.IsFavorite("emote:joke"))
        IC.Actions.Favorite("emote:joke"); assert(not IC.Actions.IsFavorite("emote:silly")); eq(#IC.Profile().favorites, 1)
    end)
    test("custom emote names resolve consistently while original commands remain available", function()
        open(); IC.Profile().emoteOverrides["emote:wave"] = { label = "Custom wave" }
        local action = IC.Actions.Resolve("emote:wave"); eq(action.name, "Custom wave"); eq(action.label, "Custom wave"); eq(action.command, "wave")
        assert(IC.Actions.Description(action):find("/wave", 1, true)); assert(IC.Emotes.Search(action, "custom"))
    end)
    test("pool menus expose configured playback, explicit modes and every exact message", function()
        local pool = sample(); local node = IC.Actions.PoolNode(pool); eq(node.type, "submenu"); eq(#node.children, 5)
        eq(node.children[1].id, "pool:quotes"); eq(node.children[2].selectionMode, "random")
        local messages = node.children[5]; eq(messages.type, "submenu"); eq(#messages.children, 3)
        eq(messages.children[3].id, "line:quotes:" .. pool.lineIDs[3]); eq(#IC.Actions.List("lines:quotes"), 3)
    end)
    test("general play and message slash commands work with custom pools", function()
        local pool = sample(); local sends = {}; C_ChatInfo = { SendChatMessage = function(text) sends[#sends + 1] = text end }
        IC.Slash("play sequential Quotes"); IC.Slash("message quotes " .. pool.lineIDs[3])
        eq(sends[1], "first"); eq(sends[2], "third"); IC.Slash("play invalid Quotes"); eq(#sends, 2); C_ChatInfo = nil
    end)
    test("deleting a pool removes its next/random/message favorites and loaded bar references", function()
        local pool = sample(); IC.Profile().favorites = { "pool:quotes", "play:random:quotes", "line:quotes:" .. pool.lineIDs[1], "pool:greetings" }
        IC.Layout().bars[1].source = "lines:quotes"; IC.Dialogue.Delete("quotes")
        eq(#IC.Profile().favorites, 1); eq(IC.Profile().favorites[1], "pool:greetings"); eq(IC.Layout().bars[1].source, "favorites")
    end)
    test("partial message ID records reserve later IDs before allocating missing ones", function()
        local pool = sample(); pool.lineIDs = { [3] = "1" }; pool.nextLineID = nil
        IC.Dialogue.EnsureLines(pool); eq(pool.lineIDs[3], "1")
        assert(pool.lineIDs[1] ~= "1" and pool.lineIDs[2] ~= "1" and pool.lineIDs[1] ~= pool.lineIDs[2])
    end)
    test("profile reset never retargets a stale exact-message action or retained bar", function()
        local pool = sample(); local id = pool.lineIDs[1]; local stale = IC.Actions.Resolve("line:quotes:" .. id)
        IC.Layout().bars[1].source = stale.id; IC.Profiles.Reset()
        local replacement = IC.Profile().pools.quotes
        local ok, _, nextID = IC.Dialogue.SaveLine(replacement, nil, "different message"); assert(ok); assert(nextID ~= id)
        eq(IC.Actions.Resolve(stale.id), nil); eq(#IC.Actions.List(IC.Layout().bars[1].source), 0)
        C_ChatInfo = { SendChatMessage = function() error("must not retarget") end }; assert(not IC.Actions.Dispatch(stale)); C_ChatInfo = nil
    end)
    test("deleting and recreating a pool cannot reuse a deleted message identity", function()
        local pool = sample(); local oldID = pool.lineIDs[1]; local stale = IC.Actions.Resolve("line:quotes:" .. oldID)
        IC.Dialogue.Delete("quotes"); local nextPool = IC.Dialogue.Create("Quotes"); eq(nextPool.id, "quotes")
        local ok, _, nextID = IC.Dialogue.SaveLine(nextPool, nil, "new pool message"); assert(ok); assert(nextID ~= oldID)
        eq(IC.Actions.Resolve(stale.id), nil)
    end)
end
