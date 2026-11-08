return function(test, eq, page, point, pointAt)
    local function wheelClick(IC, Stub, id)
        for _ = 1, IC.WheelModel.Pages(IC.Wheel.Current()) do
            for i, action in ipairs(IC.Wheel.items) do
                if action.id == id then pointAt(Stub, IC, IC.Wheel.outer[i]); IC.Wheel.catcher:Fire("OnMouseDown", "LeftButton"); return end
            end
            IC.Wheel.catcher:Fire("OnMouseWheel", -1)
        end
        error("Wheel entry not found: " .. id)
    end
    local function pool(IC)
        local p = IC.Profile().pools.quotes; p.lines = { "first", "second", "third" }; p.mode = "sequential"
        IC.Dialogue.EnsureLines(p); return p
    end
    local function hoverEntry(IC, depth, label)
        local level = IC.Menu.levels[depth]
        while level.offset > 0 do level.previous:Click() end
        for _ = 1, #level.entries do
            for _, row in ipairs(level.rows) do if row:IsShown() and row.entry.label == label then row:Fire("OnEnter"); return end end
            local old = level.offset; level.next:Click(); if old == level.offset then break end
        end
        error("Menu entry missing: " .. label)
    end
    local function choose(Stub, env, dropdown, value)
        dropdown:Click()
        local popup = env.InCharacterDropdownList; assert(popup:IsShown())
        for _ = 1, #popup.options + 1 do
            for _, row in ipairs(popup.rows) do
                if row:IsShown() and row.option.value == value then row:Click(); return end
            end
            popup:Fire("OnMouseWheel", -1)
        end
        error("Dropdown option not found: " .. tostring(value))
    end
    test("New pool and preset copy preserve all outgoing draft fields", function(IC, Stub)
        local p = page(IC, "Dialogue"); local first = IC.Editor.poolID
        p.name:SetText("Unfinished name"); p.lines:SetText("unsaved before new pool"); p.mode:Choose("random"); p.channel:Choose("YELL")
        Stub.Button(p, "+ New pool"):Click(); IC.Editor.SelectPool(first)
        eq(p.lines:GetText(), "unsaved before new pool"); eq(p.name:GetText(), "Unfinished name"); eq(p.mode.value, "random"); eq(p.channel.value, "YELL")
        p.lines:SetText("unsaved before preset"); Stub.Button(p, "Copy preset"):Click(); IC.Editor.SelectPool(first)
        eq(p.lines:GetText(), "unsaved before preset"); eq(p.name:GetText(), "Unfinished name"); eq(#Stub.sends, 0)
    end)
    test("custom emote names reach the detail panel, wheel, menu and bar action", function(IC, Stub)
        local p = page(IC, "Emotes"); IC.Editor.emote = IC.Actions.Resolve("emote:wave"); IC.Editor.RefreshEmoteDetail()
        p.dLabel:SetText("MY CUSTOM WAVE"); Stub.Button(p, "Save name"):Click(); eq(p.dName:GetText(), "MY CUSTOM WAVE")
        IC.Editor.frame:Hide(); IC.Wheel.Open(false); wheelClick(IC, Stub, "Favorites"); eq(IC.Wheel.outer[1].label:GetText(), "MY CUSTOM WAVE")
        IC.Wheel.Close(); IC.Menu.OpenAtCursor(); eq(IC.Menu.levels[1].entries[2].label, "MY CUSTOM WAVE")
        eq(IC.Bars.frames[1].buttons[1].action.name, "MY CUSTOM WAVE"); eq(#Stub.sends, 0)
    end)
    test("all bar entries remain reachable beyond 48 with visible paging and mouse wheel", function(IC, Stub)
        IC.Layout().bars[1].source = "favorites" -- Exercise the mixed-favorites source explicitly.
        IC.Profile().favorites = {}
        for n = 1, 101 do local p = IC.Dialogue.Create("Many " .. n); IC.Profile().favorites[n] = "pool:" .. p.id end
        IC.Refresh(); local frame = IC.Bars.frames[1]
        assert(frame.next:IsShown()); eq(frame.pageLabel:GetText(), "1/3")
        local seen = {}
        for _ = 1, 3 do
            for _, slot in ipairs(frame.buttons) do if slot:IsShown() then seen[slot.action.id] = true end end
            frame.next:Click()
        end
        local count = 0; for _ in pairs(seen) do count = count + 1 end; eq(count, 101)
        frame:Fire("OnMouseWheel", -1); eq(frame.config.page, 2)
        frame.header:Click("LeftButton"); assert(not frame.next:IsShown()); eq(#Stub.sends, 0)
    end)
    test("message browser previews, sends, pins and makes a bar for an exact message", function(IC, Stub)
        local p = pool(IC); local editor = page(IC, "Dialogue"); IC.Editor.SelectPool(p.id)
        editor.browse:Click(); local f = IC.Editor.messages; assert(f:IsShown())
        f.rows[3]:Click(); eq(f.edit:GetText(), "third")
        Stub.Button(f, "Preview only"):Click(); eq(IC.Editor.preview.text:GetText(), "third"); eq(#Stub.sends, 0); IC.Editor.preview:Hide()
        f.send:Click(); eq(#Stub.sends, 1); eq(Stub.sends[1][1], "third"); eq(IC.Dialogue.states[p.id], nil)
        f.pin:Click(); assert(IC.Actions.IsFavorite("line:quotes:" .. p.lineIDs[3]))
        f.bar:Click(); local config = IC.Layout().bars[#IC.Layout().bars]; eq(config.source, "line:quotes:" .. p.lineIDs[3])
        IC.Bars.frames[#IC.Layout().bars].buttons[1]:Click(); eq(Stub.sends[2][1], "third")
    end)
    test("message browser creates, edits, reorders and deletes while maintaining stable pins", function(IC, Stub)
        local p = pool(IC); page(IC, "Dialogue"); IC.Editor.SelectPool(p.id); IC.Editor.pages.Dialogue.browse:Click()
        local f = IC.Editor.messages
        Stub.Button(f, "+ New message"):Click(); f.edit:SetText("new message")
        assert(not f.send.enabled); Stub.Button(f, "Save message"):Click()
        eq(#p.lines, 4); local id = f.lineID; eq(p.lineIDs[4], id)
        f.pin:Click(); f.edit:SetText("edited message"); assert(not f.send.enabled)
        f.send:Click(); eq(#Stub.sends, 0) -- callback also refuses if a stale/disabled click arrives
        Stub.Button(f, "Save message"):Click(); eq(f.lineID, id); assert(IC.Actions.IsFavorite("line:quotes:" .. id))
        Stub.Button(f, "Move up"):Click(); eq(p.lineIDs[3], id); eq(p.lines[3], "edited message")
        f.send:Click(); eq(Stub.sends[1][1], "edited message")
        f.delete:Click(); eq(#p.lines, 4); f.delete:Click(); eq(#p.lines, 3); assert(not IC.Actions.IsFavorite("line:quotes:" .. id))
    end)
    test("message drafts survive switching messages, browser close and page navigation", function(IC, Stub)
        local p = pool(IC); page(IC, "Dialogue"); IC.Editor.SelectPool(p.id); IC.Editor.pages.Dialogue.browse:Click()
        local f = IC.Editor.messages; f.edit:SetText("draft first"); f.rows[2]:Click(); f.rows[1]:Click(); eq(f.edit:GetText(), "draft first")
        Stub.Button(f, "Close"):Click(); IC.Editor.pages.Dialogue.browse:Click(); eq(f.edit:GetText(), "draft first")
        page(IC, "Layouts"); page(IC, "Dialogue"); IC.Editor.pages.Dialogue.browse:Click(); eq(f.edit:GetText(), "draft first")
        Stub.Button(f, "Discard edit"):Click(); eq(f.edit:GetText(), "first"); eq(p.lines[1], "first"); eq(#Stub.sends, 0)
    end)
    test("unsaved bulk pool drafts cannot be mistaken for saved play/random/message actions", function(IC, Stub)
        local p = pool(IC); local f = page(IC, "Dialogue"); IC.Editor.SelectPool(p.id); f.lines:SetText("unsaved replacement")
        Stub.Button(f.form, "Play next"):Click(); Stub.Button(f.form, "Random message"):Click(); f.browse:Click()
        eq(#Stub.sends, 0); assert(not IC.Editor.messages or not IC.Editor.messages:IsShown())
        assert(IC.Editor.status:GetText():find("Save or discard")); eq(p.lines[1], "first")
    end)
    test("actual dropdown choices set message channel and pool selection mode", function(IC, Stub, env)
        local p = pool(IC); page(IC, "Dialogue"); IC.Editor.SelectPool(p.id); IC.Editor.pages.Dialogue.browse:Click()
        local f = IC.Editor.messages
        choose(Stub, env, f.channel, "YELL"); choose(Stub, env, f.mode, "shuffle")
        eq(p.channel, "YELL"); eq(p.mode, "shuffle"); f.send:Click(); eq(Stub.sends[1][2], "YELL")
    end)
    test("launcher menu navigates group/pool/messages, pins exact messages and has Back", function(IC, Stub)
        local p = pool(IC); IC.Menu.OpenAtCursor()
        hoverEntry(IC, 1, "My dialogue"); hoverEntry(IC, 2, "Quotes"); hoverEntry(IC, 3, "Choose a specific message")
        local level = IC.Menu.levels[4]; assert(level.back:IsShown())
        eq(level.entries[3].action.lineID, p.lineIDs[3])
        level.rows[3]:Click("RightButton"); assert(IC.Actions.IsFavorite("line:quotes:" .. p.lineIDs[3])); assert(IC.Menu.IsOpen())
        level.back:Click(); assert(IC.Menu.IsOpen()); assert(not level:IsShown()); assert(IC.Menu.levels[3]:IsShown()); eq(#Stub.sends, 0)
        hoverEntry(IC, 3, "Choose a specific message"); level.rows[3]:Click(); eq(Stub.sends[1][1], "third"); assert(not IC.Menu.IsOpen())
    end)
    test("radial wheel navigates pack/pool/messages and Back restores prior context", function(IC, Stub)
        local ok, _, id = IC.Library.Install("office-stanley", false); assert(ok)
        local p = IC.Profile().pools[id]; IC.Wheel.Open(false)
        wheelClick(IC, Stub, "Roleplay")
        wheelClick(IC, Stub, "group:office-stanley"); wheelClick(IC, Stub, "browse:" .. id)
        wheelClick(IC, Stub, "messages:" .. id); eq(#IC.Wheel.stack, 4); eq(IC.Wheel.backHint:GetText(), "< Back")
        assert(IC.Wheel.breadcrumb:GetText():find("Roleplay", 1, true))
        point(Stub, IC, 0, 0); IC.Wheel.catcher:Fire("OnMouseDown", "LeftButton"); eq(#IC.Wheel.stack, 3); eq(#Stub.sends, 0)
        wheelClick(IC, Stub, "messages:" .. id); wheelClick(IC, Stub, "line:" .. id .. ":" .. p.lineIDs[2])
        eq(Stub.sends[1][1], p.lines[2]); assert(not IC.Wheel.open)
    end)
    test("wheel pages nested messages and leaves context stable when crossing inner sectors", function(IC, Stub)
        local p = pool(IC); p.lines = {}; for i = 1, 31 do p.lines[i] = "line " .. i end; IC.Dialogue.EnsureLines(p)
        IC.Wheel.Open(false); wheelClick(IC, Stub, "Roleplay")
        wheelClick(IC, Stub, "group:custom"); wheelClick(IC, Stub, "browse:quotes"); wheelClick(IC, Stub, "messages:quotes")
        IC.Wheel.catcher:Fire("OnMouseWheel", -1); eq(IC.Wheel.page, 2)
        point(Stub, IC, 0, 80); eq(#IC.Wheel.stack, 4); eq(IC.Wheel.page, 2); eq(IC.Wheel.Current().id, "messages:quotes")
        point(Stub, IC, 0, 0); IC.Wheel.catcher:Fire("OnMouseDown", "LeftButton"); eq(#IC.Wheel.stack, 3)
        eq(IC.Wheel.page, 1); eq(#Stub.sends, 0)
    end)
    test("release never enters a submenu or executes before dwell and page stabilization", function(IC, Stub)
        pool(IC); IC.Profile().wheel.mode = "hold"; IC.Wheel.Binding("down")
        pointAt(Stub, IC, IC.Wheel.outer[#IC.Wheel.categories]); Stub.clock = Stub.clock + 1
        IC.Wheel.Binding("up"); assert(not IC.Wheel.open); eq(#Stub.sends, 0)
        IC.Wheel.Binding("down"); pointAt(Stub, IC, IC.Wheel.outer[1]); IC.Wheel.Binding("up"); eq(#Stub.emotes, 0)
        IC.Wheel.Binding("down"); pointAt(Stub, IC, IC.Wheel.outer[1]); Stub.clock = Stub.clock + 0.2
        point(Stub, IC, 9999, 9999); IC.Wheel.Binding("up"); eq(#Stub.emotes + #Stub.sends, 0)
    end)
    test("favorite action page reorders, previews, plays and unpins message actions", function(IC, Stub)
        local p = pool(IC); local id = "line:quotes:" .. p.lineIDs[2]; IC.Actions.Favorite(id)
        local f = page(IC, "Favorites"); local last = #IC.Profile().favorites; local row = f.rows[last]
        Stub.Button(row, "Up"):Click(); eq(IC.Profile().favorites[last - 1], id)
        row = f.rows[last - 1]; Stub.Button(row, "Preview"):Click(); eq(IC.Editor.preview.text:GetText(), "second"); eq(#Stub.sends, 0)
        IC.Editor.preview:Hide(); Stub.Button(row, "Play"):Click(); eq(Stub.sends[1][1], "second")
        Stub.Button(row, "Unpin"):Click(); assert(not IC.Actions.IsFavorite(id))
    end)
    test("refused key assignment preserves existing keys instead of clearing them", function(IC, Stub, env)
        local f = page(IC, "Layouts"); Stub.bindings.F = "INCHARACTER_WHEEL"
        env.SetBinding = function(key, action) if key == "G" then return false end; Stub.bindings[key] = action; return true end
        f.wKey:Click(); f.wKey:Fire("OnKeyDown", "G"); eq(Stub.bindings.F, "INCHARACTER_WHEEL"); eq(Stub.bindings.G, nil)
        eq(Stub.savedBindings, nil)
    end)
    test("quick-use badges make no sound claim before a character observation", function(IC)
        local badge, info = IC.Emotes.Badge(IC.Emotes.byID["emote:chicken"])
        assert(badge:find("Not checked", 1, true)); assert(info.help:find("cannot detect", 1, true))
        assert(not IC.Emotes.IsAudible(IC.Emotes.byID["emote:chicken"]))
    end)
    test("bar page capacity fits smaller screens in both orientations", function(IC, Stub, env)
        env.UIParent:SetSize(640, 480); IC.Profile().favorites = {}
        for i = 1, 70 do local p = IC.Dialogue.Create("Screen " .. i); IC.Profile().favorites[i] = "pool:" .. p.id end
        local config = IC.Layout().bars[1]; config.size, config.columns, config.source = 64, 12, "favorites"
        for _, vertical in ipairs({ false, true }) do
            config.vertical = vertical; IC.Bars.Refresh(); local frame = IC.Bars.frames[1]
            assert(frame:GetWidth() <= env.UIParent:GetWidth()); assert(frame:GetHeight() <= env.UIParent:GetHeight())
            local seen = {}; local pages = math.ceil(70 / IC.Bars.Capacity(config))
            for _ = 1, pages do for _, slot in ipairs(frame.buttons) do if slot:IsShown() then seen[slot.action.id] = true end end; frame.next:Click() end
            local count = 0; for _ in pairs(seen) do count = count + 1 end; eq(count, 70)
        end
    end)
    test("deleting a pinned message leaves a visible missing-message warning without retargeting its bar", function(IC, Stub)
        local p = pool(IC); local id = p.lineIDs[2]; local actionID = "line:quotes:" .. id
        IC.Bars.Pin(actionID); local config = IC.Layout().bars[#IC.Layout().bars]; config.locked = true
        IC.Dialogue.DeleteLine(p, id); local frame = IC.Bars.frames[#IC.Layout().bars]
        eq(config.source, actionID); assert(frame.header:IsShown()); assert(frame.header.text:GetText():find("message removed", 1, true))
        for _, slot in ipairs(frame.buttons) do assert(not slot:IsShown()) end
        eq(#Stub.sends, 0)
    end)
    test("message browser shows a blocked-send reason locally and leaves selection unchanged", function(IC, Stub, env)
        local p = pool(IC); page(IC, "Dialogue"); IC.Editor.SelectPool(p.id); IC.Editor.pages.Dialogue.browse:Click()
        env.C_ChatInfo.InChatMessagingLockdown = function() return true end
        IC.Editor.messages.send:Click(); eq(#Stub.sends, 0); eq(IC.Dialogue.states[p.id], nil)
        assert(IC.Editor.messages.notice:GetText():find("lockdown", 1, true))
    end)
end
