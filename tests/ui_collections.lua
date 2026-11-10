-- Fresh-install fixture: the default layout is the launcher plus the combined main bar.
-- Stub tokens: WAVE, CHEER, CHICKEN, DANCE, SILLY (+ /joke), CHARGE, FOREVERONLY.
return function(test, eq)
    local function buttons(IC) return IC.Bars.frames[1].actionButtons end
    local function find(IC, id)
        for _, button in ipairs(buttons(IC)) do if button:IsShown() and button.node.id == id then return button end end
        error("No bar button: " .. id)
    end
    local function rows(IC, depth)
        local result = {}
        for _, row in ipairs(IC.Flyout.levels[depth].rows) do if row:IsShown() then result[#result + 1] = row end end
        return result
    end

    test("fresh install shows the launcher and one compact main bar with no backdrop and sends nothing", function(IC, Stub)
        assert(IC.Launcher.button:IsShown())
        eq(#IC.Bars.frames, 1); local frame = IC.Bars.frames[1]; assert(frame:IsShown())
        eq(frame.config.collection, "main"); eq(frame:GetHeight(), 28)
        local first = buttons(IC)[1]; eq(first:GetWidth(), 28); eq(first.node.id, "emote:wave")
        assert(not first.arrow:IsShown())
        local combat = find(IC, "set:Combat"); assert(combat.arrow:IsShown()); eq(combat.side, "UP")
        -- Favorites, five categories and the RP group fit in one 28px line.
        assert(frame:GetWidth() < 520, "main bar is compact: " .. frame:GetWidth())
        eq(#Stub.emotes + #Stub.sends, 0)
    end)

    test("emote buttons use on click; group buttons open a flyout whose rows send once and close", function(IC, Stub)
        find(IC, "emote:wave"):Click(); eq(Stub.emotes[1], "WAVE")
        find(IC, "set:Combat"):Click(); assert(IC.Flyout.IsOpen()); eq(#Stub.emotes, 1)
        local charge = rows(IC, 1)[1]; eq(charge.node.id, "emote:charge")
        charge:Fire("OnEnter"); eq(#Stub.emotes, 1)
        charge:Click(); eq(Stub.emotes[2], "CHARGE"); assert(not IC.Flyout.IsOpen())
        local combat = find(IC, "set:Combat"); combat:Click(); combat.arrow:Click(); assert(not IC.Flyout.IsOpen(), "second press closes")
    end)

    test("pools play on click and their arrow lists exact lines", function(IC, Stub)
        local pool = IC.Profile().pools.quotes
        IC.Dialogue.Save(pool, "Quotes", "SAY", "sequential", pool.icon, { "first line", "second line" })
        local button = find(IC, "role:quotes"); assert(button.arrow:IsShown()); eq(button.node.name, "Quote")
        button:Click(); eq(Stub.sends[1][1], "first line")
        button.arrow:Click(); assert(IC.Flyout.IsOpen()); eq(#rows(IC, 1), 2)
        rows(IC, 1)[2]:Click(); eq(Stub.sends[2][1], "second line"); eq(#Stub.sends, 2)
        find(IC, "role:quotes"):Click("RightButton"); assert(IC.Flyout.IsOpen()); eq(#Stub.sends, 2)
    end)

    test("hovering a nested pool reveals its lines without sending; right-click pins without closing", function(IC, Stub)
        local pool = IC.Profile().pools.greetings
        IC.Dialogue.Save(pool, "Greetings", "SAY", "shuffle", pool.icon, { "hello there" })
        find(IC, "set:rp"):Click(); assert(IC.Flyout.IsOpen())
        eq(rows(IC, 1)[1].node.type, "character", "the RP list starts with the character switcher")
        local greetings; for _, row in ipairs(rows(IC, 1)) do if row.node.id == "role:greetings" then greetings = row end end
        greetings:Fire("OnEnter"); assert(IC.Flyout.levels[2]:IsShown()); eq(#rows(IC, 2), 1); eq(#Stub.sends, 0)
        IC.Flyout.Close(); find(IC, "set:Voice/Fun"):Click()
        local chicken; for _, row in ipairs(rows(IC, 1)) do if row.node.id == "emote:chicken" then chicken = row end end
        assert(not IC.Actions.IsFavorite("emote:chicken"))
        chicken:Click("RightButton"); assert(IC.Actions.IsFavorite("emote:chicken")); assert(IC.Flyout.IsOpen()); eq(#Stub.emotes, 0)
        assert(chicken.text:GetText():find("%*"), "pinned rows are starred")
    end)

    test("flyouts work in combat and close from the outside click catcher", function(IC, Stub)
        Stub.combat = true
        find(IC, "set:Social"):Click(); assert(IC.Flyout.IsOpen())
        IC.Flyout.catcher:Fire("OnMouseDown"); assert(not IC.Flyout.IsOpen()); assert(not IC.Flyout.levels[1]:IsShown())
        find(IC, "set:Social"):Click(); rows(IC, 1)[1]:Click(); eq(Stub.emotes[1], "WAVE")
    end)

    test("edit mode selects the bar instead of playing; shift-right-click opens edit mode", function(IC, Stub)
        Stub.modifiers.shift = true; find(IC, "emote:wave"):Click("RightButton"); Stub.modifiers.shift = nil
        assert(IC.Bars.editing); eq(IC.Bars.selectedBar, 1)
        find(IC, "emote:wave"):Click(); find(IC, "set:Combat"):Click(); eq(#Stub.emotes, 0); assert(not IC.Flyout.IsOpen())
        IC.Bars.inspector.source:Choose("Combat"); eq(IC.Layout().bars[1].collection, "Combat")
        IC.Bars.SetEditing(false); eq(buttons(IC)[1].node.id, "emote:charge")
    end)

    test("bar geometry separates segments, wraps and stacks vertically", function(IC)
        local g = IC.CollectionBar.Geometry({ size = 28 }, { { segment = 1 }, { segment = 1 }, { segment = 1 }, { segment = 2 }, { segment = 2 } })
        eq(g.width, 5 * 28 + 3 * 2 + 6); eq(g.height, 28)
        g = IC.CollectionBar.Geometry({ size = 24, perRow = 2 }, { { segment = 1 }, { segment = 1 }, { segment = 1 } })
        eq(g.width, 24 * 2 + 2); eq(g.height, 24 * 2 + 2); eq(g.positions[3].y, 26)
        g = IC.CollectionBar.Geometry({ size = 30, vertical = true }, { { segment = 1 }, { segment = 1 } })
        eq(g.width, 30); eq(g.height, 62)
    end)
    test('switching between one bar and separate bars keeps each mode\'s own bars', function(IC)
        IC.Layout().bars[1].x = 77
        assert(IC.Bars.SetMode('separate')); eq(IC.Layout().mode, 'separate')
        local names = {}; for i, bar in ipairs(IC.Layout().bars) do names[i] = bar.collection end
        eq(table.concat(names, ' '), 'favorites Combat Social Reactions Idle Voice/Fun rp')
        IC.Layout().bars[2].y = 123
        IC.Bars.SetMode('one'); eq(#IC.Layout().bars, 1); eq(IC.Layout().bars[1].x, 77)
        IC.Bars.SetMode('separate'); eq(IC.Layout().bars[2].y, 123)
    end)
    test("the RP switcher lists characters and presets; choosing one swaps the role lines in place", function(IC, Stub)
        find(IC, "set:rp"):Click(); local switcher = rows(IC, 1)[1]
        switcher:Fire("OnEnter"); local options = rows(IC, 2); assert(#options >= 2)
        local stanley; for _, row in ipairs(options) do if row.node.name == "Load Stanley Hudson" then stanley = row end end
        stanley:Click(); eq(IC.Personas.Name(), "Stanley Hudson"); eq(#Stub.sends, 0)
        local quote = find(IC, "role:quotes"); eq(quote.node.name, "Quote"); quote:Click(); eq(#Stub.sends, 1)
        assert(IC.Profile().pools[quote.node.payload].provenance, "the Quote button now sends Stanley's lines")
    end)
    test("in edit mode the corner grip reshapes the bar into rows and keeps its top-left corner", function(IC, Stub)
        local frame = IC.Bars.frames[1]
        IC.Bars.SetEditing(true); assert(frame.resizeGrip:IsShown())
        local left, top, count = frame:GetLeft(), frame:GetTop(), #frame.nodes
        frame.resizeGrip:Fire("OnDragStart")
        IC.Bars.Reshape(frame, left + 3 * 28 + 2 * 2 + 1, top - 40)
        eq(IC.Layout().bars[1].perRow, 3); eq(IC.Bars.inspector.perRow:GetValue(), 3)
        eq(frame:GetLeft(), left); eq(frame:GetTop(), top); assert(frame:GetHeight() > 28)
        IC.Bars.Reshape(frame, left + 2000, top); eq(IC.Layout().bars[1].perRow, 0, "past the end means one line")
        frame.resizeGrip:Fire("OnDragStop"); assert(not frame.reshape)
        IC.Layout().bars[1].locked = true; IC.Refresh(); assert(not frame.resizeGrip:IsShown())
        IC.Bars.SetEditing(false); assert(not frame.moveHandle:IsShown())
        eq(count > 3, true); eq(#Stub.sends + #Stub.emotes, 0)
    end)
end
