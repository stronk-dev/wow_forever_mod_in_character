return function(test, eq, page)
    local function entry(level, id)
        for _, row in ipairs(level.rows) do if row:IsShown() and row.entry.id == id then return row end end
        error("No menu entry " .. id)
    end
    test("options gives emotes and RP independent bars context and radial switches", function(IC, Stub)
        local p = page(IC, "Home")
        for primitive, controls in pairs(p.presentations) do for presentation, check in pairs(controls) do
            check:SetChecked(false); check:Click(); assert(not IC.Presentation.Enabled(primitive, presentation))
            local other = primitive == "emotes" and "roleplay" or "emotes"
            assert(IC.Presentation.Enabled(other, presentation)); check:SetChecked(true); check:Click()
        end end
        p.presentations.emotes.menu:SetChecked(false); p.presentations.emotes.menu:Click()
        local entries = IC.Menu.Entries(); for _, e in ipairs(entries) do assert(e.id ~= "emote-categories") end
        p.presentations.roleplay.wheel:SetChecked(false); p.presentations.roleplay.wheel:Click()
        for _, category in ipairs(IC.WheelModel.Categories()) do assert(category.id ~= "Roleplay") end
        eq(#Stub.sends + #Stub.emotes, 0)
    end)
    test("two bare emote buttons occupy exactly two slots in play instead of the sizing region", function(IC, Stub)
        IC.Profile().favorites = { "emote:wave", "emote:cheer" }; IC.Refresh()
        local frame = IC.Bars.frames[1]; eq(frame:GetWidth(), 52); eq(frame:GetHeight(), 26)
        assert(not frame.header:IsShown()); assert(not frame.buttons[1].caption:IsShown())
        local left, top = frame:GetLeft(), frame:GetTop()
        IC.Bars.SetEditing(true); eq(frame:GetWidth(), 388); eq(frame:GetLeft(), left); eq(frame:GetTop(), top)
        IC.Bars.SetEditing(false); eq(frame:GetWidth(), 52); eq(frame:GetLeft(), left); eq(frame:GetTop(), top)
        local p = page(IC, "Home"); p.emoteSize:SetValue(12); eq(frame:GetWidth(), 28); eq(frame:GetHeight(), 14)
        eq(#Stub.emotes + #Stub.sends, 0)
    end)
    test("emote bars are explicitly recoverable without removing menu radial or RP choices", function(IC, Stub)
        IC.Layout().bars = { IC.Layout().bars[2] }; IC.Refresh(); IC.Slash("emote-bars")
        local found; for i, c in ipairs(IC.Layout().bars) do if IC.Bars.IsEmoteConfig(c) then found = i end end
        assert(found and IC.Bars.frames[found]:IsShown())
        IC.Bars.frames[found].config.hidden = true; IC.Refresh(); page(IC, "Home").favToggle:Click()
        assert(IC.Bars.frames[found]:IsShown()); assert(IC.Profile().presentations.roleplay.bar)
        IC.Slash("wheel"); assert(IC.Wheel.open); IC.Slash("menu"); assert(IC.Menu.IsOpen()); eq(#Stub.sends + #Stub.emotes, 0)
    end)
    test("loaded-character options and library loading show only that character's RP pools", function(IC, Stub)
        local p = page(IC, "Home"); p.character:Choose("preset:office-stanley")
        eq(IC.Personas.Name(), "Stanley Hudson"); local stanley = IC.Personas.Active()
        IC.Library.Load("dutch-mastermovies"); eq(IC.Personas.Name(), "Michael Nicht")
        for _, action in ipairs(IC.Presentation.BarActions(IC.Layout().bars[2])) do assert(IC.Personas.HasPool(action.payload)); assert(IC.Profile().pools[action.payload].provenance.pack == "dutch-mastermovies") end
        IC.Personas.Load(stanley.id); local dialogue = page(IC, "Dialogue")
        for _, row in ipairs(dialogue.rows) do if row:IsShown() then assert(IC.Personas.HasPool(row.poolID)) end end
        eq(#Stub.sends + #Stub.emotes, 0)
    end)
    test("menu pool click plays directly while its separate arrow chooses a specific saved message", function(IC, Stub)
        IC.Library.Load("office-stanley"); IC.Menu.OpenAtCursor(); local root = IC.Menu.levels[1]
        assert(#root.entries <= 12); eq(root.entries[1].label, "Stanley Hudson")
        local id = IC.Personas.Pools()[1]; local pool = IC.Profile().pools[id]; pool.mode = "sequential"; IC.Menu.Rebuild()
        local row = entry(root, "pool:" .. id); row:Fire("OnEnter"); eq(#Stub.sends, 0)
        row:Click(); eq(Stub.sends[1][1], pool.lines[1]); assert(not IC.Menu.IsOpen())
        IC.Menu.OpenAtCursor(); row = entry(root, "pool:" .. id); row.more:Click(); eq(#Stub.sends, 1)
        local details = IC.Menu.levels[2]; local messages = entry(details, "messages:" .. id); messages:Fire("OnEnter")
        IC.Menu.levels[3].rows[2]:Click(); eq(Stub.sends[2][1], pool.lines[2])
        eq(IC.Dialogue.Preview(pool), pool.lines[2])
    end)
    test("switching character hides stale pinned RP actions and never sends another actor's lines", function(IC, Stub, env, event)
        IC.Library.Load("office-stanley"); local id = IC.Personas.Pools()[1]; IC.Actions.Favorite("pool:" .. id)
        local old = IC.Actions.Resolve("pool:" .. id); local charState = IC.Personas.Active().id
        Stub.combat = true; event("PLAYER_REGEN_DISABLED"); IC.Library.Load("dutch-mastermovies")
        assert(not IC.Actions.Dispatch(old)); eq(#Stub.sends, 0); Stub.combat = false; event("PLAYER_REGEN_ENABLED")
        for _, action in ipairs(IC.Actions.List("favorites")) do assert(action.payload ~= id) end
        IC.Personas.Load(charState); assert(IC.Actions.Dispatch(old)); eq(#Stub.sends, 1)
    end)
    test("custom characters can own jokes and tones and the editor can reassign stored pools", function(IC, Stub)
        local p = page(IC, "Home"); p.newCharacter:Click(); local dialog = IC.Editor.characterDialog
        dialog.name:SetText("My own persona"); Stub.Button(dialog, "Save"):Click(); eq(IC.Personas.Name(), "My own persona")
        local d = page(IC, "Dialogue"); assert(d.noPool:IsShown()); Stub.Button(d, "+ New pool"):Click()
        local id = IC.Editor.poolID; assert(IC.Personas.HasPool(id)); d.name:SetText("Dry jokes"); d.lines:SetText("One joke."); Stub.Button(d, "Save"):Click()
        local owner = IC.Personas.Active().id; IC.Personas.Load("custom"); page(IC, "Dialogue").poolView:Choose("all"); IC.Editor.SelectPool(id)
        d.owner:Choose("custom"); assert(IC.Personas.HasPool(id)); eq(IC.Profile().pools[id].lines[1], "One joke.")
        IC.Personas.Load(owner); assert(not IC.Personas.HasPool(id)); eq(#Stub.sends, 0)
    end)
    test("native widgets and slider art are used throughout the normal options screen", function(IC, Stub)
        local p = page(IC, "Home")
        eq(p.openMenu.template, "UIPanelButtonTemplate"); eq(p.emoteSize.template, "UISliderTemplate")
        eq(p.openMenu.label, p.openMenu.Text)
        eq(p.emoteSize:GetThumbTexture().texture, "Interface\\Buttons\\UI-SliderBar-Button-Horizontal")
        eq(p.presentations.emotes.bar.template, "UICheckButtonTemplate"); assert(Stub.KeyDown("W"))
        eq(#Stub.sends + #Stub.emotes, 0)
    end)
    test("favorite actions honor each primitive's radial switch without hiding the other primitive", function(IC, Stub)
        local pool = IC.Profile().pools.quotes; IC.Dialogue.SaveLine(pool, nil, "A saved quote")
        local options = page(IC, "Home"); options.presentations.emotes.wheel:SetChecked(false); options.presentations.emotes.wheel:Click()
        local categories = IC.WheelModel.Categories(); local favorites
        for _, category in ipairs(categories) do if category.id == "Favorites" then favorites = category end end
        assert(favorites); for _, action in ipairs(favorites.children) do assert(action.type ~= "emote") end
        assert(#favorites.children > 0); eq(#Stub.sends + #Stub.emotes, 0)
    end)
    test("dedicated RP bars follow their owning character without losing bar settings", function(IC, Stub)
        IC.Library.Load("office-stanley"); local actor = IC.Personas.Active(); local id = actor.poolIDs[1]
        IC.Bars.Pin("pool:" .. id); local index = #IC.Layout().bars; local config = IC.Layout().bars[index]
        config.x, config.y = 77, -104; IC.Refresh(); assert(IC.Bars.frames[index]:IsShown())
        IC.Library.Load("dutch-mastermovies"); assert(not IC.Bars.frames[index]:IsShown()); assert(not config.hidden)
        IC.Personas.Load(actor.id); assert(IC.Bars.frames[index]:IsShown()); eq(config.x, 77); eq(config.y, -104)
        eq(#Stub.sends, 0)
    end)
end
