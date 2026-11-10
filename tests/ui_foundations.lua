return function(test, eq, page)
    test('individual message editing keeps pinned buttons and custom icons through save and reload', function(IC, Stub)
        local pool = IC.Profile().pools.quotes
        IC.Dialogue.Save(pool, pool.name, 'SAY', 'sequential', pool.icon, { 'Before', 'Second' })
        local id = pool.lineIDs[1]; local ref = 'line:quotes:' .. id
        IC.Collections.Add('favorites', ref); IC.Actions.SetIcon(ref, 'chosen-icon')
        local p = page(IC, 'Lines'); IC.Editor.SelectPool(pool.id)
        p.messageToggle:Click(); assert(p.messages:IsShown()); assert(not p.lines:IsShown())
        p.messageRows[1]:Click(); p.messageText:SetText('After'); p.messageSave:Click()
        eq(pool.lineIDs[1], id); eq(pool.lines[1], 'After'); eq(IC.Actions.Resolve(ref).icon, 'chosen-icon')
        assert(IC.Actions.IsFavorite(ref)); eq(#Stub.sends, 0)
        IC.Actions.Dispatch(ref); eq(Stub.sends[1][1], 'After')
        IC.Initialize(IC.db, IC.Profiles.Character()); eq(IC.Actions.Resolve(ref).label, 'After'); eq(pool.lineIDs[1], id)
    end)
    test('unsaved individual messages survive switching pools and pages without sending', function(IC, Stub)
        local pool = IC.Profile().pools.quotes
        IC.Dialogue.Save(pool, pool.name, 'SAY', 'random', pool.icon, { 'Original' })
        local p = page(IC, 'Lines'); IC.Editor.SelectPool(pool.id); IC.Editor.SetMessageView(true)
        p.messageText:SetText('Unsaved message')
        IC.Editor.SelectPool('greetings'); IC.Editor.SelectPool(pool.id)
        eq(p.messageText:GetText(), 'Unsaved message'); eq(pool.lines[1], 'Original')
        page(IC, 'Layout'); page(IC, 'Lines'); eq(p.messageText:GetText(), 'Unsaved message'); eq(#Stub.sends, 0)
    end)
    test('exact lines can be put directly in any list, and any list can drive the wheel and menu', function(IC, Stub)
        local pool = IC.Profile().pools.quotes
        IC.Dialogue.Save(pool, pool.name, 'SAY', 'shuffle', pool.icon, { 'First', 'Second' })
        local custom = IC.Collections.Create('My combined controls')
        local p = page(IC, 'Lists'); IC.Editor.list = custom.id; IC.Editor.RefreshLists()
        p.category:Choose('rp'); eq(#p.shown, 3 + 2) -- the three roles, then the Quotes lines
        eq(p.shown[1].id, 'role:greetings')
        p.libRows[5]:Click('RightButton')
        local line = 'line:quotes:' .. pool.lineIDs[2]; assert(IC.Collections.Contains(custom.id, line))
        p.libRows[2]:Click('RightButton'); assert(IC.Collections.Contains(custom.id, 'role:quotes'))
        local layout = page(IC, 'Layout'); layout.wheelRoot:Choose(custom.id); eq(IC.Profile().wheel.root, custom.id)
        layout.menuRoot:Choose(custom.id); eq(IC.Profile().menu.root, custom.id)
        p = page(IC, 'Lists'); IC.Editor.list = custom.id; IC.Editor.RefreshLists()
        p.listIcon:Click(); IC.Editor.picker.path:SetText('custom-group-icon'); Stub.Button(IC.Editor.picker, 'Use icon'):Click()
        eq(custom.icon, 'custom-group-icon'); eq(#Stub.sends + #Stub.emotes, 0)
    end)
    test('a bar longer than the screen wraps into rows and keeps every button reachable', function(IC, Stub)
        local pool = IC.Profile().pools.quotes; local lines = {}
        for i = 1, 90 do lines[i] = 'Line ' .. i end
        IC.Dialogue.Save(pool, pool.name, 'SAY', 'shuffle', pool.icon, lines)
        local list = IC.Collections.Create('Long'); for _, id in ipairs(pool.lineIDs) do IC.Collections.Add(list.id, 'line:quotes:' .. id) end
        local cfg = IC.Layout().bars[1]; cfg.collection = list.id; IC.Refresh()
        local f = IC.Bars.frames[1]; eq(f.geometry.pages, 1); assert(f:GetWidth() <= 1920 - 80); assert(f:GetHeight() > 28)
        local shown = 0; for _, b in ipairs(f.actionButtons) do if b:IsShown() then shown = shown + 1 end end
        eq(shown, 90); assert(not f.pager:IsShown()); eq(#Stub.sends, 0)
    end)
    test('outside-click observation never intercepts a click needed to switch bar groups', function(IC, Stub, env, event)
        local first, second
        for _, b in ipairs(IC.Bars.frames[1].actionButtons) do
            if b.node.id == 'set:Combat' then first = b elseif b.node.id == 'set:Social' then second = b end
        end
        first:Click(); assert(IC.Flyout.IsOpen()); eq(IC.Flyout.catcher.mouseEnabled, false)
        second:ClearAllPoints(); second:SetPoint('CENTER', env.UIParent, 'CENTER', 500, 100)
        local x, y = second:GetCenter(); Stub.cursorX, Stub.cursorY = x, y
        event('GLOBAL_MOUSE_DOWN', 'LeftButton'); assert(not IC.Flyout.IsOpen())
        second:Click(); assert(IC.Flyout.IsOpen()); eq(IC.Flyout.levels[1].node.id, 'set:Social')
        assert(Stub.KeyDown('W')); eq(#Stub.sends + #Stub.emotes, 0)
    end)
    test('the launcher follows the addon convention: left-click menu, right-click settings, nothing else', function(IC, Stub)
        IC.Launcher.button:Click('LeftButton'); assert(IC.Menu.IsOpen()); IC.Flyout.Close()
        IC.Launcher.button:Click('RightButton'); assert(IC.Editor.frame:IsShown()); IC.Editor.frame:Hide()
        IC.Launcher.button:Click('MiddleButton'); assert(not IC.Bars.editing); assert(not IC.Menu.IsOpen())
        eq(#Stub.sends + #Stub.emotes, 0)
    end)
    test('the platform preserves both binding keys rather than losing the secondary return value', function(IC, Stub, env)
        env.GetBindingKey = function() return 'F', 'G' end
        local first, second = IC.Platform.BindingKeys('INCHARACTER_WHEEL'); eq(first, 'F'); eq(second, 'G')
    end)

    test('message deletion confirmation belongs to the selected message, not the reused button', function(IC)
        local pool = IC.Profile().pools.quotes
        IC.Dialogue.Save(pool, pool.name, 'SAY', 'shuffle', pool.icon, { 'Keep me', 'Delete me' })
        local p = page(IC, 'Lines'); IC.Editor.SelectPool(pool.id); IC.Editor.SetMessageView(true)
        p.messageRows[1]:Click(); p.messageDelete:Click(); eq(#pool.lines, 2)
        p.messageRows[2]:Click(); p.messageDelete:Click(); eq(#pool.lines, 2)
        p.messageDelete:Click(); eq(#pool.lines, 1); eq(pool.lines[1], 'Keep me')
    end)

end
