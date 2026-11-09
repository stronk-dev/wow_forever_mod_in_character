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
    test('exact lines and mode overrides can be put directly in any list and used by every surface', function(IC, Stub)
        local pool = IC.Profile().pools.quotes
        IC.Dialogue.Save(pool, pool.name, 'SAY', 'shuffle', pool.icon, { 'First', 'Second' })
        local custom = IC.Collections.Create('My combined controls')
        local p = page(IC, 'Lists'); IC.Editor.list = custom.id; IC.Editor.RefreshLists()
        p.kind:Choose('messages'); eq(#p.shown, 2); p.libRows[2]:Click('RightButton')
        local line = 'line:quotes:' .. pool.lineIDs[2]; assert(IC.Collections.Contains(custom.id, line))
        p.kind:Choose('playback'); eq(#p.shown, 9) -- includes the three empty starter pools' modes
        local sequential
        for _, row in ipairs(p.libRows) do if row:IsShown() and row.action.payload == 'quotes' and row.action.selectionMode == 'sequential' then sequential = row end end
        sequential:Click('RightButton'); assert(IC.Collections.Contains(custom.id, 'play:sequential:quotes'))
        Stub.Button(p, 'Bar'):Click(); eq(IC.Layout().bars[#IC.Layout().bars].collection, custom.id)
        Stub.Button(p, 'Ring'):Click(); eq(IC.Profile().wheel.root, custom.id)
        Stub.Button(p, 'Menu'):Click(); eq(IC.Profile().menu.root, custom.id)
        p.listIcon:Click(); IC.Editor.picker.path:SetText('custom-group-icon'); Stub.Button(IC.Editor.picker, 'Use icon'):Click()
        eq(custom.icon, 'custom-group-icon'); eq(#Stub.sends + #Stub.emotes, 0)
    end)
    test('resize handle fits a bar, paging reaches every button, and collapsing uses one icon', function(IC, Stub)
        IC.Bars.SetEditing(true); local f, cfg = IC.Bars.frames[1], IC.Layout().bars[1]
        f.resizeGrip:Fire('OnDragStart'); assert(f.resizing and f.sizing)
        f:SetSize(62, 62); f.resizeGrip:Fire('OnDragStop'); assert(not f.resizing)
        eq(cfg.fitWidth, 62); eq(cfg.fitHeight, 62); eq(cfg.perRow, 0)
        IC.Bars.inspector.size:SetValue(12); eq(cfg.size, 12)
        IC.Bars.SetEditing(false); assert(f:GetWidth() <= 62 and f:GetHeight() <= 62)
        cfg.size = 28; IC.Refresh(); assert(f.geometry.pages > 1)
        local pageBefore = f.geometry.page; f.pager:Click(); assert(f.geometry.page ~= pageBefore)
        Stub.modifiers.shift = true; f.actionButtons[1]:Click('MiddleButton'); Stub.modifiers.shift = nil
        assert(cfg.collapsed); eq(f:GetWidth(), 28); eq(f:GetHeight(), 28); assert(f.folded:IsShown())
        f.folded:Click(); assert(not cfg.collapsed); assert(not f.folded:IsShown()); eq(#Stub.sends + #Stub.emotes, 0)
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
    test('all three launcher mouse mappings have controls and preserve configured actions', function(IC, Stub)
        local p = page(IC, 'Layout')
        p.launcherRight:Choose('menu'); p.launcherMiddle:Choose('bars'); IC.Editor.frame:Hide()
        IC.Launcher.button:Click('RightButton'); assert(IC.Menu.IsOpen()); IC.Flyout.Close()
        IC.Launcher.button:Click('MiddleButton'); assert(IC.Layout().barsHidden)
        IC.Refresh(); eq(IC.Layout().launcher.rightClick, 'menu'); eq(IC.Layout().launcher.middleClick, 'bars')
        eq(#Stub.sends + #Stub.emotes, 0)
    end)
    test('combat interrupts resizing without moving or revealing hidden bars later', function(IC, Stub, env, event)
        IC.Bars.SetEditing(true); local f = IC.Bars.frames[1]
        f.resizeGrip:Fire('OnDragStart'); f:SetSize(100, 60)
        Stub.combat = true; event('PLAYER_REGEN_DISABLED'); assert(not f.resizing and not f.sizing)
        eq(f.config.fitWidth, 100); eq(f.config.fitHeight, 60); assert(not IC.Bars.editing)
        Stub.combat = false; event('PLAYER_REGEN_ENABLED'); eq(#Stub.sends + #Stub.emotes, 0)
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
