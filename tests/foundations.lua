return function(IC, test, eq, open)
    local function ids(collection) return table.concat(IC.Collections.Refs(collection), ' ') end
    test('legacy migration preserves exact bar contents, visibility, geometry, mode and empty layouts', function()
        local p = IC.Defaults.Profile(); p.pools.quotes.lines = { 'one', 'two' }
        local bar = { name = 'Only quotes', source = 'pool:quotes', poolMode = 'random', size = 12, x = 17, y = -29, collapsed = true }
        local db = { version = 10, profiles = { account = p } }
        local char = { version = 10, layout = { bars = { bar, { name = 'Social', source = 'Social', hiddenActions = { ['emote:wave'] = true }, includedActions = { ['emote:flirt'] = true }, hidden = true } } } }
        IC.db = IC.Profiles.Open(db, char)
        eq(#char.layout.bars, 2); assert(not bar.hidden); eq(bar.size, 12); eq(bar.x, 17); eq(bar.y, -29); assert(bar.collapsed)
        eq(ids(bar.collection), 'play:random:quotes')
        assert(not IC.Collections.Contains(char.layout.bars[2].collection, 'emote:wave'))
        assert(IC.Collections.Contains(char.layout.bars[2].collection, 'emote:flirt')); assert(char.layout.bars[2].hidden)
        eq(char.layout.preFoundation.bars[1].source, 'pool:quotes')
        IC.Collections.Remove(bar.collection, 'play:random:quotes')
        IC.db = IC.Profiles.Open(db, char); eq(ids(bar.collection), '')
        IC.db = IC.Profiles.Open(db, { version = 10, layout = { bars = {} } }); eq(#IC.Layout().bars, 0)
    end)
    test('migration isolates per-surface hidden selections and disabled primitive types', function()
        local p = IC.Defaults.Profile(); p.presentations = { emotes = { wheel = true, menu = false }, roleplay = { wheel = false, menu = true } }
        p.wheel.hiddenCategories.Combat = true; p.wheel.hiddenActions['emote:wave'] = true
        open({ version = 10, profiles = { account = p } })
        local root = IC.Collections.Refs(p.wheel.root)
        for _, ref in ipairs(root) do
            local id = ref:sub(5)
            assert(not IC.Collections.Contains(id, 'emote:wave'))
            assert(not IC.Collections.Contains(id, 'pool:quotes'))
            assert(not id:find('Combat', 1, true))
        end
        for _, ref in ipairs(IC.Collections.Refs(p.menu.root)) do
            for _, action in ipairs(IC.Collections.Refs(ref:sub(5))) do assert(not IC.Emotes.byID[action]) end
        end
    end)
    test('0.12 repair restores bars hidden by upgrade, keeps deliberate hiding, and archives original data', function()
        local p = IC.Defaults.Profile(); IC.Collections.Ensure(p)
        local layout = { collectionBarIntroduced = true, bars = {
            { source = 'pool:quotes', collection = 'rp', hidden = true, hiddenByUpgrade = true, name = 'Q', size = 12 },
            { source = 'Social', collection = 'Social', hidden = true, name = 'Deliberate' },
            IC.Defaults.CollectionBar(3),
        } }
        local db, char = { version = 11, profiles = { account = p } }, { version = 11, layout = layout }
        IC.db = IC.Profiles.Open(db, char)
        assert(not layout.bars[1].hidden); assert(layout.bars[2].hidden); assert(layout.bars[3].hidden)
        eq(ids(layout.bars[1].collection), 'pool:quotes'); assert(layout.preFoundation.bars[1].hidden)
        layout.bars[1].hidden = true; IC.db = IC.Profiles.Open(db, char); assert(layout.bars[1].hidden, 'repair is one-time')
    end)
    test('layout identities do not collide between characters and shared layouts gain private profile lists', function()
        local db = { version = 10 }
        local a = { version = 10, layout = { bars = { { source = 'Social' } } } }
        local b = { version = 10, scope = 'character', profile = IC.Defaults.Profile(), layout = { bars = { { source = 'pool:quotes' } } } }
        IC.db = IC.Profiles.Open(db, a); local first = a.layout.bars[1].collection
        IC.db = IC.Profiles.Open(db, b); local second = b.layout.bars[1].collection
        assert(first ~= second); eq(ids(second), 'pool:quotes')
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
        assert(not list.dynamic); assert(IC.Collections.Remove(list.id, 'pool:quotes'))
        assert(IC.Collections.Contains('rp', 'pool:quotes'))
        IC.Layout().bars[1].collection = list.id; IC.Profile().wheel.root = list.id; IC.Profile().menu.root = list.id
        assert(IC.Collections.Delete(list.id)); eq(IC.Layout().bars[1].collection, 'favorites')
        eq(IC.Profile().wheel.root, 'favorites'); eq(IC.Profile().menu.root, 'favorites')
    end)
    test('bounded bar pages preserve every item once at small and large sizes in both orientations', function()
        local nodes = {}; for i = 1, 200 do nodes[i] = { segment = math.floor(i / 9) } end
        for _, vertical in ipairs({ false, true }) do for _, labels in ipairs({ false, true }) do for _, size in ipairs({ 12, 24, 64 }) do
            local c = { size = size, vertical = vertical, labels = labels, fitWidth = 130, fitHeight = 96 }
            local first = IC.BarModel.Geometry(c, nodes, 320, 240); local seen = {}
            for page = 1, first.pages do
                c.page = page; local g = IC.BarModel.Geometry(c, nodes, 320, 240)
                assert(g.width <= 130 and g.height <= 96)
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
    test('legacy observation filters migrate to explicit membership without losing include overrides', function()
        local p = IC.Defaults.Profile(); p.emoteFilter = 'heard'; p.wheel.root = nil
        p.wheel.hiddenCategories.Combat = true
        local char = { version = 8, emoteObservations = { ['emote:wave'] = { sound = 'nearby' } }, layout = { bars = {
            { source = 'favorites' }, { source = 'Reactions', includedActions = { ['emote:cheer'] = true } },
        } } }
        IC.db = IC.Profiles.Open({ version = 8, profiles = { account = p } }, char)
        assert(IC.Collections.Contains(char.layout.bars[1].collection, 'emote:wave'))
        assert(not IC.Collections.Contains(char.layout.bars[1].collection, 'emote:cheer'))
        assert(IC.Collections.Contains(char.layout.bars[2].collection, 'emote:cheer'))
        for _, ref in ipairs(IC.Collections.Refs(p.wheel.root)) do assert(not ref:find('Combat', 1, true)) end
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

    test('ring and fan square bounds never overlap, including diagonal sectors and small icons', function()
        local M = IC.WheelModel
        for count = 1, M.PAGE do for _, size in ipairs({ 24, 30, 40 }) do
            local g = M.Geometry(count, size)
            for sector = 1, count do
                local boxes = {}
                for i = 1, count do local x, y = M.Position(i, count, g.radius); boxes[#boxes + 1] = { x = x, y = y, size = size } end
                local _, _, angle = M.Position(sector, count, g.radius)
                for _, p in ipairs(M.Fan(100, angle, g)) do boxes[#boxes + 1] = { x = p.x, y = p.y, size = g.fanIcon } end
                for i = 1, #boxes do for j = i + 1, #boxes do
                    local a, b = boxes[i], boxes[j]; local half = (a.size + b.size) / 2
                    assert(math.abs(a.x - b.x) >= half or math.abs(a.y - b.y) >= half, 'overlapping ring/fan icons')
                end end
            end
        end end
    end)

end
