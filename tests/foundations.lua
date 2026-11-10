return function(IC, test, eq, open)
    local function ids(collection) return table.concat(IC.Collections.Refs(collection), ' ') end
    -- 0.14 upgrade: generated lists nobody uses are retired (kept in the save, not shown); anything
    -- the player's own lists or favorites point to stays.
    test('upgrades retire unused generated lists, keep used ones and own lists, and reset bars to one', function()
        local p = IC.Defaults.Profile(); IC.Collections.Ensure(p); p.pools.quotes.lines = { 'mine' }
        p.collections['legacy-wheel-Combat'] = { id = 'legacy-wheel-Combat', name = 'Wheel / Combat callouts', items = { 'emote:wave' }, migrated = true }
        p.collections['legacy-wheel'] = { id = 'legacy-wheel', name = 'My wheel', items = { 'set:legacy-wheel-Combat' }, migrated = true }
        p.collections['legacy-bar-2'] = { id = 'legacy-bar-2', name = 'Bar 2', items = { 'emote:cheer', 'emote:dance' }, migrated = true }
        p.collections.c1 = { id = 'c1', name = 'Tavern', items = { 'emote:cheer', 'set:legacy-wheel-Combat' } }
        for _, id in ipairs({ 'legacy-wheel-Combat', 'legacy-wheel', 'legacy-bar-2', 'c1' }) do p.collectionOrder[#p.collectionOrder + 1] = id end
        p.wheel.root, p.menu.root = 'legacy-wheel', 'c1'
        local old = { { source = 'pool:quotes', name = 'Q', x = 5 }, { collection = 'main', name = 'Main bar', x = 40, y = -200, size = 32 } }
        local char = { version = 12, layout = { bars = old, launcher = { click = 'menu', rightClick = 'menu', x = 1, y = 2 } } }
        IC.db = IC.Profiles.Open({ version = 12, profiles = { account = p } }, char)
        local profile = IC.Profile()
        eq(profile.collections['legacy-wheel'], nil); eq(profile.collections['legacy-bar-2'], nil)
        eq(profile.retired.collections['legacy-bar-2'].items[2], 'emote:dance', 'retired lists stay in the save')
        local kept = profile.collections['legacy-wheel-Combat']; assert(kept, 'a list the player points to is kept')
        eq(kept.migrated, nil); eq(ids('c1'), 'emote:cheer set:legacy-wheel-Combat')
        eq(profile.wheel.root, 'ring'); eq(profile.menu.root, 'c1'); eq(profile.pools.quotes.lines[1], 'mine')
        local layout = IC.Layout()
        eq(#layout.bars, 1); eq(layout.bars[1].collection, 'main'); eq(layout.bars[1].x, 40); eq(layout.bars[1].size, 32)
        assert(not layout.bars[1].hidden); eq(layout.mode, 'one'); eq(layout.retired.bars[1].name, 'Q')
        eq(layout.launcher.rightClick, nil); eq(layout.launcher.x, 1)
        -- One time only: a list the player makes later is never removed.
        local later = IC.Collections.Create('Later'); later.migrated = true
        IC.db = IC.Profiles.Open({ version = 13, profiles = { account = profile } }, char); assert(IC.Collections.Get(later.id))
    end)
    test('upgrades keep generated lists reached through other generated lists, at any depth', function()
        local p = IC.Defaults.Profile(); IC.Collections.Ensure(p)
        p.collections.g3 = { id = 'g3', name = 'Deep', items = { 'emote:wave' }, migrated = true }
        p.collections.g2 = { id = 'g2', name = 'Sub', items = { 'set:g3', 'emote:cheer' }, migrated = true }
        p.collections.g1 = { id = 'g1', name = 'Group', items = { 'set:g2' }, migrated = true }
        p.collections.loop = { id = 'loop', name = 'Loop', items = { 'set:loop', 'set:g1' }, migrated = true }
        p.collections.unused = { id = 'unused', name = 'Unused', items = { 'set:g3' }, migrated = true }
        p.collections.mine = { id = 'mine', name = 'Mine', items = { 'set:g1' } }
        p.favorites = { 'set:loop' }
        for _, id in ipairs({ 'g3', 'g2', 'g1', 'loop', 'unused', 'mine' }) do p.collectionOrder[#p.collectionOrder + 1] = id end
        IC.db = IC.Profiles.Open({ version = 12, profiles = { account = p } }, { version = 12 })
        local c = IC.Profile().collections
        assert(c.g1 and c.g2 and c.g3 and c.loop, 'everything reachable is kept')
        eq(c.unused, nil); assert(IC.Profile().retired.collections.unused)
        eq(ids('g1'), 'set:g2'); eq(ids('g2'), 'set:g3 emote:cheer'); eq(ids('g3'), 'emote:wave')
    end)
    test('0.15 upgrade: default category icons update, Playful loses duplicates, custom icons stay', function()
        local p = IC.Defaults.Profile(); IC.Collections.Ensure(p)
        p.collections.Combat.icon = 'Interface\\Icons\\Ability_Warrior_BattleShout'
        p.collections.Social.icon = 'my-own-icon'
        p.collections['Voice/Fun'].items = { 'emote:chicken', 'emote:cheer', 'emote:laugh', 'emote:kiss' }
        p.contentVersion = nil
        IC.db = IC.Profiles.Open({ version = 13, profiles = { account = p } }, { version = 13 })
        local c = IC.Profile().collections
        eq(c.Combat.icon, IC.Emotes.CategoryInfo.Combat.icon); eq(c.Social.icon, 'my-own-icon')
        for _, ref in ipairs(c['Voice/Fun'].items) do assert(ref ~= 'emote:cheer' and ref ~= 'emote:laugh' and ref ~= 'emote:kiss', ref) end
        eq(c['Voice/Fun'].items[1], 'emote:chicken')
        c.Combat.icon = 'changed later'; IC.db = IC.Profiles.Open({ version = 13, profiles = { account = IC.Profile() } }, { version = 13 })
        eq(IC.Profile().collections.Combat.icon, 'changed later', 'runs once')
    end)
    test('upgrades keep a hidden or empty bar layout hidden and keep hide-all', function()
        for _, bars in ipairs({ {}, { { collection = 'main', name = 'Main bar', hidden = true } } }) do
            local char = { version = 12, layout = { bars = bars, barsHidden = (#bars == 0) or nil, launcher = {} } }
            IC.db = IC.Profiles.Open({ version = 12, profiles = { account = IC.Defaults.Profile() } }, char)
            eq(#IC.Layout().bars, 1); eq(IC.Layout().bars[1].hidden, true)
            eq(IC.Layout().barsHidden, (#bars == 0) or nil)
        end
    end)
    test('only the exact preset title is cut from pool names, once; names the player typed are kept', function()
        local p = IC.Defaults.Profile(); local pack, title
        for id, def in pairs(IC.Library.packs) do pack, title = id, def.title; break end
        p.pools.a = IC.Defaults.Pool('a', title .. ' / Quote'); p.pools.a.provenance = { pack = pack }
        p.pools.b = IC.Defaults.Pool('b', 'Jokes / Deadpan'); p.pools.b.provenance = { pack = pack }
        IC.db = IC.Profiles.Open({ version = 12, profiles = { account = p } }, { version = 12 })
        eq(IC.Profile().pools.a.name, 'Quote'); eq(IC.Profile().pools.b.name, 'Jokes / Deadpan')
        IC.Profile().pools.a.name = title .. ' / Mine'
        IC.db = IC.Profiles.Open({ version = 13, profiles = { account = IC.Profile() } }, { version = 13 })
        eq(IC.Profile().pools.a.name, title .. ' / Mine', 'renaming later is respected')
    end)
    test('bulk edits preserve referenced message actions; explicit edits and deletes affect every list correctly', function()
        open(); local p = IC.Profile().pools.quotes
        assert(IC.Dialogue.Save(p, p.name, p.channel, p.mode, p.icon, { 'Before' }))
        local id = p.lineIDs[1]; local ref = 'line:quotes:' .. id
        local list = IC.Collections.Create('Specific'); IC.Collections.Add(list.id, ref)
        assert(not IC.Dialogue.Save(p, p.name, p.channel, p.mode, p.icon, { 'After' })); eq(p.lines[1], 'Before')
        assert(IC.Dialogue.SaveLine(p, id, 'After')); eq(p.lineIDs[1], id); eq(IC.Actions.Resolve(ref).label, 'After')
        assert(IC.Collections.Contains(list.id, ref)); IC.Actions.SetIcon(ref, 'chosen-icon')
        eq(IC.Actions.Resolve(ref).icon, 'chosen-icon'); assert(IC.Dialogue.DeleteLine(p, id)); eq(#list.items, 0)
    end)
    test('deleting a collection repairs surface references; copying a dynamic RP list creates editable membership', function()
        open(); local list = IC.Collections.Copy('rp', 'My selection')
        assert(not list.dynamic); assert(IC.Collections.Remove(list.id, 'role:quotes'))
        assert(IC.Collections.Contains('rp', 'role:quotes'))
        IC.Layout().bars[1].collection = list.id; IC.Profile().wheel.root = list.id; IC.Profile().menu.root = list.id
        assert(IC.Collections.Delete(list.id)); eq(IC.Layout().bars[1].collection, 'favorites')
        eq(IC.Profile().wheel.root, 'favorites'); eq(IC.Profile().menu.root, 'favorites')
    end)
    test('bounded bar pages preserve every item once at small and large sizes in both orientations', function()
        local nodes = {}; for i = 1, 200 do nodes[i] = { segment = math.floor(i / 9) } end
        for _, vertical in ipairs({ false, true }) do for _, labels in ipairs({ false, true }) do for _, size in ipairs({ 12, 24, 64 }) do
            local c = { size = size, vertical = vertical, labels = labels }
            local first = IC.BarModel.Geometry(c, nodes, 320, 240); local seen = {}
            for page = 1, first.pages do
                c.page = page; local g = IC.BarModel.Geometry(c, nodes, 320, 240)
                assert(g.width <= 240 and g.height <= 160)
                for _, point in ipairs(g.positions) do
                    assert(not seen[point.index]); seen[point.index] = true
                    assert(point.x >= 0 and point.y >= 0)
                    assert(point.x + size <= g.width and point.y + size <= g.height)
                end
            end
            eq(#seen, 200)
        end end end
        eq(IC.BarModel.Size({ size = 12 }), 12)
        local g = IC.BarModel.Geometry({ size = 28 }, { {}, {}, {}, {}, {}, {}, {}, {}, {}, {} })
        eq(g.width, 298); eq(g.height, 28)
    end)
    test('wheel captions clear every square icon and hover highlight at every slice and size', function()
        local M = IC.WheelModel
        for count = 1, M.PAGE do for size = 32, 48, 2 do
            local g = M.Geometry(count, size)
            for selected = 1, count do
                local _, _, angle = M.Position(selected, count, g.radius)
                local x, y, justify = M.LabelPoint(angle, g)
                local left, right, bottom, top
                if justify == 'LEFT' then left, right, bottom, top = x, x + 240, y - 60, y + 30
                elseif justify == 'RIGHT' then left, right, bottom, top = x - 240, x, y - 60, y + 30
                elseif y > 0 then left, right, bottom, top = x - 120, x + 120, y, y + 90
                else left, right, bottom, top = x - 120, x + 120, y - 90, y end
                for i = 1, count do
                    local ix, iy = M.Position(i, count, g.radius)
                    local half = (size * 1.1 + 6) / 2
                    assert(right < ix - half or left > ix + half or top < iy - half or bottom > iy + half,
                        'caption overlaps a square icon or hover highlight')
                end
            end
        end end
    end)
    test('platform injection keeps action dispatch independent of client API globals', function()
        open(); local pool = IC.Profile().pools.quotes; pool.lines = { 'works' }
        local allowed, send = IC.Platform.ChatAllowed, IC.Platform.SendChat
        local calls = 0
        IC.Platform.ChatAllowed = function() return true end
        IC.Platform.SendChat = function(text, channel) eq(text, 'works'); eq(channel, 'SAY'); calls = calls + 1; return true end
        assert(IC.Actions.Dispatch('pool:quotes')); eq(calls, 1)
        IC.Platform.ChatAllowed, IC.Platform.SendChat = allowed, send
    end)

end
