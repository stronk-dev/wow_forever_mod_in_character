return function(IC, test, eq, open)
    test("Normalize returns one value; single-pool names resolve with case/punctuation/UTF-8", function()
        eq(select("#", IC.Normalize("My RP's")), 1); eq(IC.Normalize("My RP's"), "my-rps")
        open(); local pool = IC.Dialogue.Create("My RP's Café")
        for _, name in ipairs({ "My RP's Café", "my rps Café", "  My   RP's Café  ", pool.id }) do
            local found, problem = IC.Dialogue.Find(name); eq(found, pool); eq(problem, nil)
        end
        eq(IC.Dialogue.Find("Quotes"), IC.Profile().pools.quotes)
        eq(IC.Dialogue.Find("nobody"), nil); eq(IC.Dialogue.Find(""), nil)
    end)
    test("both name slash forms dispatch the intended pool", function()
        open(); local pool = IC.Dialogue.Create("My Custom Pool"); pool.lines = { "works" }
        local sends = 0; C_ChatInfo = { SendChatMessage = function(text) eq(text, "works"); sends = sends + 1 end }
        IC.Slash("My Custom Pool"); IC.Slash("pool My Custom Pool"); eq(sends, 2); C_ChatInfo = nil
    end)
    test("duplicate names are ambiguous while exact IDs remain usable", function()
        open(); local a = IC.Dialogue.Create("A name"); local b = IC.Dialogue.Create("A name")
        local found, problem = IC.Dialogue.Find("A name"); eq(found, nil); assert(problem:find("Ambiguous"))
        eq(IC.Dialogue.Find(a.id), a); eq(IC.Dialogue.Find(b.id), b)
    end)
    test("private profiles are created lazily from current shared data", function()
        local db = open(); eq(IC.Profiles.Character().profile, nil)
        IC.Profile().pools.quotes.lines = { "shared A" }; open(db, "Realm:Other")
        eq(IC.Profiles.Character().profile, nil); IC.Profile().pools.quotes.lines = { "updated account" }
        open(db); IC.Profiles.SetScope("character"); eq(IC.Profile().pools.quotes.lines[1], "updated account")
        IC.Profile().pools.quotes.lines[1] = "private"; IC.Profiles.SetScope("account")
        eq(IC.Profile().pools.quotes.lines[1], "updated account"); eq(db.characters, nil)
    end)
    test("v2 migration preserves spaced/unspaced legacy records and other characters", function()
        for _, realm in ipairs({ "Argent Dawn", "ArgentDawn" }) do
            local profile = IC.Defaults.Profile(); profile.pools.quotes.lines = { realm }
            local legacy = { scope = "character", layoutScope = "character", profile = profile, layout = { bars = { { x = 97 } } } }
            local db = { version = 2, characters = { [realm .. ":Player"] = legacy, ["Other:Alt"] = { custom = "keep" } } }
            local char = {}; IC.db = IC.Profiles.Open(db, char, { "Argent Dawn:Player", "ArgentDawn:Player" })
            eq(IC.Profile().pools.quotes.lines[1], realm); eq(IC.Layout().retired.bars[1].x, 97); eq(IC.Layout().bars[1].collection, "main")
            eq(db.characters[realm .. ":Player"], legacy); eq(db.characters["Other:Alt"].custom, "keep")
            IC.Profile().pools.quotes.lines[1] = "migrated edit"; eq(profile.pools.quotes.lines[1], realm)
            IC.db = IC.Profiles.Open(db, char, { "wrong realm" }); eq(IC.Profile().pools.quotes.lines[1], "migrated edit")
        end
    end)
    test("conflicting legacy records are retained and identified", function()
        local db = { version = 2, characters = { ["Argent Dawn:P"] = { scope = "account" }, ["ArgentDawn:P"] = { scope = "character" } } }
        local char = {}; IC.db = IC.Profiles.Open(db, char, { "Argent Dawn:P", "ArgentDawn:P" })
        eq(char.legacyKey, "Argent Dawn:P"); eq(#char.legacyConflicts, 2); eq(db.characters["ArgentDawn:P"].scope, "character")
    end)
    test("future per-character schema is refused without changing it", function()
        local char = { version = 999, content = "keep" }; assert(not pcall(IC.Profiles.Open, {}, char))
        eq(char.version, 999); eq(char.content, "keep")
    end)
    test("chat preflight rejects lockdown, account restrictions and predicate errors before selection", function()
        for _, mode in ipairs({ "random", "shuffle", "sequential" }) do
            for _, block in ipairs({ "lockdown", "restriction", "account", "error" }) do
                open(); local pool = IC.Profile().pools.quotes; pool.mode = mode; pool.lines = { "a", "b" }
                local calls = 0
                C_ChatInfo = { SendChatMessage = function() calls = calls + 1 end,
                    InChatMessagingLockdown = function() if block == "error" then error("unavailable") end; return block == "lockdown" end }
                Enum = { AddOnRestrictionType = { Chat = 0 } }
                C_RestrictedActions = { IsAddOnRestrictionActive = function(value) eq(value, 0); return block == "restriction" end }
                C_SocialRestrictions = { CanSendChat = function() return block ~= "account" end }
                assert(not IC.Actions.Dispatch("pool:quotes")); eq(calls, 0); eq(IC.Dialogue.states.quotes, nil)
            end
        end
        C_ChatInfo, C_RestrictedActions, C_SocialRestrictions, Enum = nil, nil, nil, nil
    end)
    test("explicit false sends preserve selection; missing optional APIs use legacy chat", function()
        open(); local pool = IC.Profile().pools.quotes; pool.mode = "sequential"; pool.lines = { "a", "b" }
        C_ChatInfo = { InChatMessagingLockdown = function() return false end, SendChatMessage = function() return false end }
        assert(not IC.Actions.Dispatch("pool:quotes")); eq(IC.Dialogue.states.quotes, nil)
        C_ChatInfo = nil; local calls = 0; SendChatMessage = function(text) eq(text, "a"); calls = calls + 1 end
        assert(IC.Actions.Dispatch("pool:quotes")); eq(calls, 1); SendChatMessage = nil
    end)
    test("chat API is invoked directly from the platform rather than through a protected-call wrapper", function()
        open(); local pool = IC.Profile().pools.quotes; pool.lines = { "User-chosen message" }
        local calls = 0
        local function send(text, channel)
            eq(debug.getinfo(2, "f").func, IC.Platform.SendChat)
            eq(text, pool.lines[1]); eq(channel, pool.channel); calls = calls + 1
        end
        C_ChatInfo = { SendChatMessage = send }
        for _, channel in ipairs({ "SAY", "YELL", "EMOTE" }) do
            pool.channel = channel; assert(IC.Actions.Dispatch("pool:quotes"))
        end
        C_ChatInfo, SendChatMessage = nil, send
        assert(IC.Actions.Dispatch("pool:quotes")); eq(calls, 4)
        SendChatMessage = nil
    end)
    test("all playback modes commit state only after a direct chat send returns successfully", function()
        for _, mode in ipairs({ "random", "shuffle", "sequential" }) do
            open(); local pool = IC.Profile().pools.quotes; pool.mode = mode; pool.lines = { "a", "b", "c" }
            IC.Dialogue.Select(pool)
            local current = IC.Dialogue.states.quotes
            local cursor, bag = current.cursor, current.bag and table.concat(current.bag, ",")
            local calls = 0
            C_ChatInfo = { SendChatMessage = function()
                calls = calls + 1; eq(IC.Dialogue.states.quotes, current)
                error("native chat failure")
            end }
            assert(not pcall(IC.Actions.Dispatch, "pool:quotes")); eq(calls, 1)
            eq(IC.Dialogue.states.quotes, current); eq(current.cursor, cursor)
            eq(current.bag and table.concat(current.bag, ","), bag)
            C_ChatInfo.SendChatMessage = function() eq(IC.Dialogue.states.quotes, current); calls = calls + 1 end
            assert(IC.Actions.Dispatch("pool:quotes")); eq(calls, 2)
            assert(IC.Dialogue.states.quotes ~= current)
        end
        C_ChatInfo = nil
    end)
    test("pipes are literal and encoded byte length is checked without editing stored text", function()
        open(); local pool = IC.Profile().pools.quotes; pool.lines = { "literal |cffff0000red|r and |Hlink" }
        local calls = 0; C_ChatInfo = { SendChatMessage = function(text)
            eq(text, "literal ||cffff0000red||r and ||Hlink"); calls = calls + 1
        end }
        assert(IC.Actions.Dispatch("pool:quotes")); eq(pool.lines[1], "literal |cffff0000red|r and |Hlink")
        pool.lines = { string.rep("|", 128) }; assert(not IC.Actions.Dispatch("pool:quotes")); eq(calls, 1); C_ChatInfo = nil
    end)
    test("emotes follow Charades DoEmote path without guessing return semantics", function()
        open(); EMOTE1_TOKEN, EMOTE1_CMD1 = "WAVE", "/wave"; IC.Emotes.Validate()
        local calls, modernCalls = 0, 0
        C_ChatInfo = { PerformEmote = function() modernCalls = modernCalls + 1 end }
        for _, result in ipairs({ "nil", false, true }) do
            DoEmote = function(token) eq(token, "WAVE"); calls = calls + 1; if result ~= "nil" then return result end end
            assert(IC.Actions.Dispatch("emote:wave"))
        end
        eq(calls, 3); eq(modernCalls, 0)
        DoEmote, C_ChatInfo, EMOTE1_TOKEN, EMOTE1_CMD1 = nil, nil, nil, nil
    end)
    test("emotes only fall back when DoEmote is absent and never retry errors", function()
        open(); EMOTE1_TOKEN, EMOTE1_CMD1 = "WAVE", "/wave"; IC.Emotes.Validate()
        local calls = 0; DoEmote = nil
        C_ChatInfo = { PerformEmote = function(token) eq(token, "WAVE"); calls = calls + 1; return false end }
        assert(IC.Actions.Dispatch("emote:wave")); eq(calls, 1)
        DoEmote = function() error("client refused") end
        assert(not IC.Actions.Dispatch("emote:wave")); eq(calls, 1)
        DoEmote, C_ChatInfo, EMOTE1_TOKEN, EMOTE1_CMD1 = nil, nil, nil, nil
    end)
    test("emote dispatch preserves the exact client token instead of deriving it from a command", function()
        open(); EMOTE1_TOKEN, EMOTE1_CMD1 = "Client_Wave", "/wave"; IC.Emotes.Validate()
        local token; DoEmote = function(value) token = value end
        assert(IC.Actions.Dispatch("emote:wave")); eq(token, "Client_Wave")
        DoEmote, EMOTE1_TOKEN, EMOTE1_CMD1 = nil, nil, nil
    end)
    test("reference metadata remains available without establishing actual sound", function()
        open()
        local byID = IC.Emotes.byID
        for _, command in ipairs({ "chicken", "cheer", "laugh", "charge", "healme" }) do eq(byID["emote:" .. command].kind, "sound") end
        for _, command in ipairs({ "flex", "dance", "sit", "wave" }) do eq(byID["emote:" .. command].kind, "animation") end
        eq(byID["emote:hug"].kind, "text"); eq(byID["emote:apologize"].kind, "voice")
        assert(not IC.Emotes.IsAudible(byID["emote:apologize"])); assert(not IC.Emotes.IsAudible(byID["emote:dance"]))
        assert(#IC.Emotes.list >= 250)
        for _, category in ipairs(IC.Emotes.categories) do
            assert(#IC.Emotes.byCategory[category] >= 10, category)
            for _, action in ipairs(IC.Emotes.byCategory[category]) do assert(action.categories[category]) end
        end
    end)
    test("filters use recorded character observations and legacy reference filters migrate to all", function()
        open()
        local M, byID = IC.Emotes.Matches, IC.Emotes.byID
        assert(not M(byID["emote:chicken"], "heard"))
        IC.Curation.Save("emote:chicken", "keep", "nearby", "yes")
        IC.Curation.Save("emote:dance", "keep", "silent", "yes")
        IC.Curation.Save("emote:hug", "text", "unknown", "unknown")
        assert(M(byID["emote:chicken"], "heard")); assert(not M(byID["emote:dance"], "heard"))
        assert(M(byID["emote:dance"], "observed")); assert(not M(byID["emote:cheer"], "observed"))
        assert(M(byID["emote:hug"], "textChecked"))
        local db = open(); IC.Profile().emoteFilter = "audible"; open(db); eq(IC.Profile().emoteFilter, "all")
        IC.Profile().emoteFilter = "silent"; open(db); eq(IC.Profile().emoteFilter, "all")
        IC.Profile().emoteFilter = "heard"; open(db); eq(IC.Profile().emoteFilter, "heard")
    end)
    test("validation maps aliases, adds client-only emotes and is repeatable", function()
        EMOTE1_TOKEN, EMOTE1_CMD1, EMOTE1_CMD2 = "SILLY", "/silly", "/joke"
        EMOTE2_TOKEN, EMOTE2_CMD1 = "BRANDNEW", "/brandnew"
        IC.Emotes.Validate(); IC.Emotes.Validate()
        eq(IC.Emotes.byID["emote:joke"], IC.Emotes.byID["emote:silly"]); eq(IC.Emotes.byID["emote:silly"].payload, "SILLY")
        assert(IC.Emotes.byID["emote:silly"].verified); assert(not IC.Emotes.byID["emote:dance"].verified)
        local extra = IC.Emotes.byID["emote:brandnew"]; eq(extra.kind, "unknown"); assert(extra.verified)
        local count = 0; for _, action in ipairs(IC.Emotes.list) do if action.command == "brandnew" then count = count + 1 end end
        eq(count, 1)
        EMOTE2_TOKEN, EMOTE2_CMD1 = nil, nil; IC.Emotes.Validate(); eq(IC.Emotes.byID["emote:brandnew"], nil)
        EMOTE1_TOKEN, EMOTE1_CMD1, EMOTE1_CMD2 = nil, nil, nil; IC.Emotes.Validate()
    end)
    test("search matches names and every alias", function()
        local cry = IC.Emotes.byID["emote:cry"]
        assert(IC.Emotes.Search(cry, "/sob")); assert(IC.Emotes.Search(cry, "CR")); assert(not IC.Emotes.Search(cry, "dance"))
        assert(IC.Emotes.Search(IC.Emotes.byID["emote:healme"], "heal me"))
    end)
    test("deleting a pool cleans both loaded layout scopes without changing legacy backups", function()
        local db = open(); local char = IC.Profiles.Character()
        char.layout.bars[1].source = "pool:quotes"; db.sharedLayout.bars[1].source = "pool:quotes"
        db.characters = { archive = { layout = { bars = { { source = "pool:quotes" } } } } }
        IC.Dialogue.Delete("quotes"); eq(char.layout.bars[1].source, "favorites"); eq(db.sharedLayout.bars[1].source, "favorites")
        eq(db.characters.archive.layout.bars[1].source, "pool:quotes")
    end)
    test("all shuffle permutations of three items occur once across all Fisher-Yates choices", function()
        local permutations = {}
        for first = 1, 3 do for second = 1, 2 do
            local step = 0; local state = {}; local values = {}
            local function rng(n) step = step + 1; eq(n, step == 1 and 3 or 2); return step == 1 and first or second end
            local pool = { mode = "shuffle", lines = { "a", "b", "c" } }
            for i = 1, 3 do values[i] = IC.Dialogue.Next(pool, state, rng) end
            local result = table.concat(values); assert(not permutations[result]); permutations[result] = true
        end end
        local count = 0; for _ in pairs(permutations) do count = count + 1 end; eq(count, 6)
    end)
end
