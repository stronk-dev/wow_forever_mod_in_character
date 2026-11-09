return function(IC, test, eq, open)
    test("compact strip geometry fits ten actions into a horizontal region without fixed slot counts", function()
        local config = IC.Defaults.EmoteBar(1); config.stripWidth, config.size = 388, 36
        local g = IC.Presentation.StripGeometry(config, 10, 1920)
        eq(g.size, 36); eq(g.rows, 1); eq(g.capacity, 10); eq(g.height, 38)
        config.stripWidth = 268; g = IC.Presentation.StripGeometry(config, 10, 1920)
        eq(g.size, 24); eq(g.capacity, 10); eq(g.height, 26)
        config.stripRows = 2; g = IC.Presentation.StripGeometry(config, 10, 1920)
        eq(g.size, 36); eq(g.rows, 2); assert(g.capacity >= 10)
    end)
    test("strip geometry bounds every icon and paging control across screen sizes and counts", function()
        for _, screen in ipairs({ 320, 640, 1920 }) do
            for _, width in ipairs({ 40, 80, 268, 388, 1200, 5000 }) do
                for rows = 1, 4 do for count = 0, 140 do
                    local g = IC.Presentation.StripGeometry({ stripWidth = width, stripRows = rows, size = 36 }, count, screen)
                    assert(g.width <= screen - 56); assert(g.size >= 12 and g.size <= 36)
                    assert(g.capacity >= 1 and g.capacity <= 48)
                    local shown = math.min(g.capacity, count)
                    for n = 1, shown do
                        local right = g.padding + ((n - 1) % g.columns) * (g.size + g.gap) + g.size
                        local bottom = g.padding + math.floor((n - 1) / g.columns) * g.cellHeight + g.size
                        assert(right <= g.width - g.controls - g.padding); assert(bottom <= g.height - g.padding)
                    end
                    if count > g.capacity then eq(g.controls, 48) end
                end end
            end
        end
    end)
    test("combined categories union actions once while retaining individual hidden choices", function()
        open(); local bar = IC.Defaults.EmoteBar(1, "categories")
        local seen, total = {}, 0
        for _, id in ipairs(IC.Emotes.categories) do
            for _, action in ipairs(IC.Actions.List(id, true)) do
                if not seen[action.payload] then total = total + 1; seen[action.payload] = true end
            end
        end
        eq(#IC.Presentation.BarActions(bar, true), total)
        for _, id in ipairs(IC.Emotes.categories) do bar.categories[id] = false end
        eq(#IC.Presentation.BarActions(bar, true), 0)
        bar.categories.Social, bar.categories.Reactions = true, true
        seen = {}; for _, action in ipairs(IC.Presentation.BarActions(bar, true)) do assert(not seen[action.payload]); seen[action.payload] = true end
        bar.hiddenActions["emote:wave"] = true
        for _, action in ipairs(IC.Presentation.BarActions(bar)) do assert(action.id ~= "emote:wave") end
        local found; for _, action in ipairs(IC.Presentation.BarActions(bar, true)) do if action.id == "emote:wave" then found = true end end
        assert(found)
    end)
    test("upgrades preserve existing emote presentation and text bar position and item choices", function()
        local db = open(); db.version = 7; local char = IC.Profiles.Character(); char.version = 7
        local emotes = char.layout.bars[1]
        emotes.stripIntroduced, emotes.strip, emotes.labels = nil, nil, true
        emotes.x, emotes.y, emotes.size, emotes.hiddenActions["emote:wave"] = 71, -112, 32, true
        local rp = char.layout.bars[2]; rp.buttonWidth = 220
        open(db); eq(db.version, 10); assert(not emotes.strip); assert(emotes.labels); eq(emotes.previousGrid, nil)
        eq(emotes.x, 71); eq(emotes.y, -112); eq(emotes.size, 32); assert(emotes.hiddenActions["emote:wave"])
        eq(rp.buttonWidth, 220); assert(not rp.strip); eq(rp.buttonStyle, "text")
        emotes.strip, emotes.labels = false, true; open(db); assert(not emotes.strip); assert(emotes.labels)
    end)
    test("strip dimensions and all-disabled category choices persist and remain per character", function()
        local db = open(); local bar = IC.Layout().bars[1]
        bar.source, bar.stripWidth, bar.stripRows = "categories", 452, 2
        for _, id in ipairs(IC.Emotes.categories) do bar.categories[id] = false end
        open(db); eq(IC.Layout().bars[1].stripWidth, 452); eq(#IC.Presentation.BarActions(IC.Layout().bars[1], true), 0)
        open(db, "Realm:Other"); eq(IC.Layout().bars[1].stripWidth, 388); eq(IC.Layout().bars[1].stripRows, 1)
        open(db); eq(IC.Layout().bars[1].stripRows, 2)
    end)
    test("two-axis strip bounds retain readable icons and fit their fixed height with labels", function()
        for _, labels in ipairs({ false, true }) do for _, height in ipairs({ 20, 42, 80, 160, 500 }) do
            for count = 1, 90 do
                local g = IC.Presentation.StripGeometry({ stripWidth = 280, stripHeight = height, labels = labels, size = 36 }, count, 1920)
                assert(g.size >= 12)
                for n = 1, math.min(count, g.capacity) do
                    local bottom = g.padding + math.floor((n - 1) / g.columns) * g.cellHeight + g.size + (labels and 14 or 0)
                    assert(bottom <= g.height - g.padding)
                end
            end
        end end
    end)
    test("new controls merge without changing viewport size launcher actions and per-bar emote overrides", function()
        local db = open(); local layout = IC.Layout()
        layout.bars[2].width, layout.bars[2].height = 340, 190
        layout.bars[1].emoteView = "all"; layout.bars[1].includedActions["emote:hug"] = true
        layout.launcher.click, layout.launcher.rightClick = "menu", "bars"
        IC.Profile().quick.style = "panel"; open(db)
        eq(IC.Layout().bars[2].width, 340); eq(IC.Layout().bars[2].height, 190)
        eq(IC.Layout().bars[1].emoteView, "all"); assert(IC.Layout().bars[1].includedActions["emote:hug"])
        eq(IC.Layout().launcher.click, "menu"); eq(IC.Layout().launcher.rightClick, "bars"); eq(IC.Profile().quick.style, "panel")
    end)
end
