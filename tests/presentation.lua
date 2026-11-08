return function(IC, test, eq, open)
    test("v4 settings gain presentation controls without replacing saved values or empty collections", function()
        local db = open(); db.version = 4
        local profile = IC.Profile(); profile.wheel = { radius = 210, mode = "hold", hiddenActions = { ["emote:wave"] = true } }
        profile.emoteOverrides["emote:wave"] = { icon = "my-icon" }
        IC.Layout().bars[1].columns = 3; IC.Layout().bars[1].size = 48
        open(db)
        eq(db.version, 6); eq(IC.Profile().wheel.radius, 210); eq(IC.Profile().wheel.mode, "hold")
        assert(IC.Profile().wheel.hiddenActions["emote:wave"]); eq(IC.Profile().menu.pageSize, 12)
        eq(IC.Layout().bars[1].columns, 3); eq(IC.Layout().bars[1].rows, 0); eq(IC.Layout().bars[1].size, 48)
        eq(IC.Actions.Resolve("emote:wave").icon, "my-icon")
    end)
    test("bar visibility is independent and raw editing lists retain hidden and unknown entries", function()
        open(); local bar = IC.Layout().bars[1]; bar.source = "Social"; bar.hiddenActions["emote:wave"] = true
        local found = false
        for _, action in ipairs(IC.Presentation.BarActions(bar)) do assert(action.id ~= "emote:wave") end
        for _, action in ipairs(IC.Presentation.BarActions(bar, true)) do if action.id == "emote:wave" then found = true end end
        assert(found); assert(not IC.Defaults.Bar(2).hiddenActions["emote:wave"])
        assert(not IC.Profile().wheel.hiddenActions["emote:wave"]); assert(not IC.Profile().menu.hiddenActions["emote:wave"])
    end)
    test("semantic grouping partitions every action once and leaves small lists direct", function()
        open()
        for _, category in ipairs(IC.Emotes.categories) do
            local actions = IC.Actions.List(category, true); local groups = IC.Presentation.EmoteGroups(category, actions, true)
            local seen, count = {}, 0
            for _, group in ipairs(groups) do
                for _, action in ipairs(group.children or { group }) do assert(not seen[action.id]); seen[action.id] = true; count = count + 1 end
            end
            eq(count, #actions)
        end
        eq(IC.Presentation.EmoteGroups("Combat", { IC.Actions.Resolve("emote:charge") })[1].id, "emote:charge")
    end)
    test("nested visibility prunes empty groups without mutating shared source trees", function()
        open(); local nodes = { { id = "group", type = "submenu", children = { { id = "a", type = "pool" } } } }
        local result = IC.Presentation.Tree(nodes, { hiddenActions = { a = true } })
        eq(#result, 0); eq(#nodes[1].children, 1)
    end)
    test("per-message artwork follows stable IDs through edit, reorder, bulk save and removal", function()
        open(); local pool = IC.Profile().pools.quotes
        IC.Dialogue.SaveLine(pool, nil, "one"); IC.Dialogue.SaveLine(pool, nil, "two")
        local id = pool.lineIDs[2]; local action = "line:quotes:" .. id
        assert(IC.Actions.SetIcon(action, 12345)); IC.Dialogue.MoveLine(pool, id, -1)
        IC.Dialogue.SaveLine(pool, id, "edited"); eq(IC.Actions.Resolve(action).icon, 12345)
        IC.Dialogue.Save(pool, pool.name, pool.channel, pool.mode, pool.icon, { "one", "edited" })
        eq(IC.Actions.Resolve(action).icon, 12345)
        IC.Actions.SetIcon(action, nil); eq(IC.Actions.Resolve(action).icon, pool.icon)
        IC.Actions.SetIcon(action, 12345); IC.Dialogue.DeleteLine(pool, id); eq(pool.lineIcons[id], nil)
    end)
    test("common emotes use semantic artwork while user overrides and dispatch tokens remain intact", function()
        open(); local distinct = {}
        for _, command in ipairs({ "wave", "cheer", "cry", "dance", "sleep", "read", "eat", "drink", "chicken", "train", "healme", "oom" }) do
            local action = IC.Actions.Resolve("emote:" .. command); assert(not distinct[action.icon], command); distinct[action.icon] = true
        end
        IC.Actions.SetIcon("emote:wave", 777); eq(IC.Actions.Resolve("emote:wave").icon, 777)
        eq(IC.Actions.Resolve("emote:wave").payload, "WAVE"); IC.Actions.SetIcon("emote:wave", nil)
        eq(IC.Actions.Resolve("emote:wave").icon, IC.EmoteIcons.wave)
    end)
end
