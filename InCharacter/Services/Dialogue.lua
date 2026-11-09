local _, IC = ...
IC.Dialogue = { states = {} }
local D = IC.Dialogue
local modes = { random = true, shuffle = true, sequential = true }
local channels = { SAY = true, YELL = true, EMOTE = true }
local function allocateLineID(pool)
    local id = pool.messageUID .. "-" .. pool.nextLineID
    pool.nextLineID = pool.nextLineID + 1
    return id
end
function D.EnsureLines(pool, database)
    pool.lineIDs = pool.lineIDs or {}
    pool.nextLineID = math.max(1, math.floor(tonumber(pool.nextLineID) or 1))
    local db = database or IC.db or IC.Profiles.db
    if not pool.messageUID then
        assert(db, "Message IDs require an initialized profile database")
        db.nextMessagePoolID = math.max(1, math.floor(tonumber(db.nextMessagePoolID) or 1))
        pool.messageUID = tostring(db.nextMessagePoolID); db.nextMessagePoolID = db.nextMessagePoolID + 1
    else
        if db and tonumber(pool.messageUID) then db.nextMessagePoolID = math.max(db.nextMessagePoolID or 1, tonumber(pool.messageUID) + 1) end
    end
    -- Reserve existing IDs before filling holes, so a partial legacy record cannot
    -- accidentally give an old message's ID to an earlier new row.
    for _, id in pairs(pool.lineIDs) do
        local number = tonumber(id) or tonumber(tostring(id):match("^" .. pool.messageUID .. "%-(%d+)$"))
        if number then pool.nextLineID = math.max(pool.nextLineID, math.floor(number) + 1) end
    end
    local seen = {}
    for i = 1, #pool.lines do
        local id = pool.lineIDs[i]
        if id ~= nil then
            id = tostring(id); pool.nextLineID = math.max(pool.nextLineID, (tonumber(id) or 0) + 1)
        end
        if not id or seen[id] then id = allocateLineID(pool) end
        pool.lineIDs[i], seen[id] = id, true
    end
    for i = #pool.lineIDs, #pool.lines + 1, -1 do pool.lineIDs[i] = nil end
end
function D.Line(pool, lineID)
    D.EnsureLines(pool)
    for index, id in ipairs(pool.lineIDs) do if id == tostring(lineID) then return pool.lines[index], index end end
end
function D.StateKey(pool, mode) return mode and (pool.id .. "\031" .. mode) or pool.id end
local function cleanPins(pool)
    local profile = IC.Profile()
    local valid = {}; for _, id in ipairs(pool.lineIDs) do valid[id] = true end
    for id in pairs(pool.lineIcons or {}) do if not valid[id] then pool.lineIcons[id] = nil end end
    local removed = 0
    for i = #profile.favorites, 1, -1 do
        local poolID, lineID = profile.favorites[i]:match("^line:(.*):([^:]+)$")
        if poolID == pool.id and not valid[lineID] then table.remove(profile.favorites, i); removed = removed + 1 end
    end
    for _, collection in pairs(profile.collections or {}) do
        if collection.store ~= "favorites" then
            for i = #(collection.items or {}), 1, -1 do
                local owner, id = collection.items[i]:match("^line:(.*):([^:]+)$")
                if owner == pool.id and not valid[id] then table.remove(collection.items, i); removed = removed + 1 end
            end
        end
    end
    return removed
end

function D.Clear(id)
    if not id then D.states = {}; return end
    for key in pairs(D.states) do if key == id or key:sub(1, #id + 1) == id .. "\031" then D.states[key] = nil end end
end
function D.Next(pool, state, random)
    state, random = state or {}, random or math.random
    local lines = pool.lines or {}
    local count = #lines
    if count == 0 then return nil, state end
    -- Detect even same-length edits made by integrations, without depending on a hash collision.
    local changed = state.mode ~= pool.mode or not state.lines or #state.lines ~= count
    if not changed then for i = 1, count do if state.lines[i] ~= lines[i] then changed = true; break end end end
    if changed then
        state.bag, state.cursor, state.mode, state.lines = nil, 0, pool.mode, IC.Copy(lines)
    end
    local index
    if pool.mode == "sequential" then
        index = (state.cursor or 0) % count + 1
        state.cursor = index
    elseif pool.mode == "shuffle" then
        if not state.bag or #state.bag == 0 then
            state.bag = {}
            for i = 1, count do state.bag[i] = i end
            for i = count, 2, -1 do
                local j = random(i)
                state.bag[i], state.bag[j] = state.bag[j], state.bag[i]
            end
        end
        index = table.remove(state.bag)
    else index = random(count) end
    return lines[index], state, index
end
function D.Select(pool, mode)
    local key = D.StateKey(pool, mode)
    local text, state = D.Next(mode and { lines = pool.lines, mode = mode } or pool, D.states[key])
    D.states[key] = state
    return text
end
function D.Preview(pool, mode)
    -- A preview neither sends nor consumes the live selection state.
    return D.Next(mode and { lines = pool.lines, mode = mode } or pool, IC.Copy(D.states[D.StateKey(pool, mode)] or {}))
end
function D.Find(name)
    if IC.Profile().pools[name] then return IC.Profile().pools[name] end
    local normalized = IC.Normalize(name)
    local found
    if normalized == "" then return nil, "Choose a pool name." end
    for id, pool in pairs(IC.Profile().pools) do
        if IC.Normalize(id) == normalized or IC.Normalize(pool.name) == normalized then
            if found and found ~= pool then return nil, "Ambiguous pool name; use /ic pool <exact ID>." end
            found = pool
        end
    end
    if found then return found end
    return nil, "Pool not found. Install a preset or create one with /ic."
end
function D.Create(name)
    name = IC.Trim(name)
    local base = IC.Normalize(name)
    if base == "" then return nil, "Enter a name containing letters or numbers." end
    local profile, id, n = IC.Profile(), base, 2
    while profile.pools[id] do id = base .. "-" .. n; n = n + 1 end
    local pool = IC.Defaults.Pool(id, name)
    profile.pools[id] = pool
    table.insert(profile.poolOrder, id)
    if IC.Personas then IC.Personas.AddPool(id) end
    IC.Changed()
    return pool
end
function D.Save(pool, name, channel, mode, icon, lines)
    if IC.Trim(name) == "" then return false, "A pool needs a name." end
    if not modes[mode] or not channels[channel] then return false, "Invalid mode or channel." end
    for _, line in ipairs(lines) do
        if type(line) ~= "string" or line:find("[%z\1-\31\127]") then return false, "Lines cannot contain control characters." end
    end
    D.EnsureLines(pool)
    local ids, byText, consumed = {}, {}, {}
    for i, text in ipairs(pool.lines) do
        byText[text] = byText[text] or {}; table.insert(byText[text], pool.lineIDs[i])
    end
    -- Bulk edits retain IDs for unchanged/reordered text. Replacements receive fresh IDs;
    -- explicit Edit message preserves its ID even when its text changes.
    for i, line in ipairs(lines) do
        local queue, position = byText[line], (consumed[line] or 0) + 1
        if queue and queue[position] then ids[i] = queue[position]; consumed[line] = position end
        if not ids[i] then ids[i] = allocateLineID(pool) end
    end
    local retained, referenced = {}, {}
    for _, id in ipairs(ids) do retained[id] = true end
    for _, ref in ipairs(IC.Profile().favorites) do referenced[ref] = true end
    for _, collection in pairs(IC.Profile().collections or {}) do for _, ref in ipairs(collection.items or {}) do referenced[ref] = true end end
    for _, id in ipairs(pool.lineIDs) do
        if not retained[id] and referenced["line:" .. pool.id .. ":" .. id] then
            return false, "A changed/deleted message has buttons in a list. Use Individual messages to edit it without changing its ID, or delete it explicitly there."
        end
    end
    pool.name, pool.channel, pool.mode, pool.icon, pool.lines = IC.Trim(name), channel, mode, icon, IC.Copy(lines)
    pool.lineIDs = ids
    local removed = cleanPins(pool)
    pool.revision = (pool.revision or 0) + 1
    IC.Changed()
    return true, removed > 0 and ("Saved. Removed " .. removed .. " pins for replaced/deleted messages. Use Individual messages to keep button IDs when editing.") or nil
end
function D.SaveLine(pool, lineID, text)
    if type(text) ~= "string" or IC.Trim(text) == "" or text:find("[%z\1-\31\127]") then return false, "Enter one non-empty message without line breaks or control characters." end
    D.EnsureLines(pool)
    local index
    if lineID then local previous; previous, index = D.Line(pool, lineID) end
    if lineID and not index then return false, "This message was removed; it cannot be replaced through a stale selection." end
    if not index then
        index = #pool.lines + 1; pool.lineIDs[index] = allocateLineID(pool)
    end
    pool.lines[index] = text; pool.revision = (pool.revision or 0) + 1
    D.Clear(pool.id); IC.Changed()
    return true, nil, pool.lineIDs[index]
end
function D.DeleteLine(pool, lineID)
    local _, index = D.Line(pool, lineID)
    if not index then return false end
    table.remove(pool.lines, index); table.remove(pool.lineIDs, index); cleanPins(pool)
    pool.revision = (pool.revision or 0) + 1; D.Clear(pool.id); IC.Changed(); return true
end
function D.MoveLine(pool, lineID, delta)
    local _, index = D.Line(pool, lineID); local target = index and index + delta
    if not target or target < 1 or target > #pool.lines then return false end
    pool.lines[index], pool.lines[target] = pool.lines[target], pool.lines[index]
    pool.lineIDs[index], pool.lineIDs[target] = pool.lineIDs[target], pool.lineIDs[index]
    pool.revision = (pool.revision or 0) + 1; D.Clear(pool.id); IC.Changed(); return true
end
function D.Delete(id)
    local profile = IC.Profile()
    for _, actor in pairs(profile.personas or {}) do for i = #actor.poolIDs, 1, -1 do if actor.poolIDs[i] == id then table.remove(actor.poolIDs, i) end end end
    profile.pools[id] = nil
    D.Clear(id)
    for shortcut, poolID in pairs(profile.shortcuts) do if poolID == id then profile.shortcuts[shortcut] = nil end end
    for i = #profile.poolOrder, 1, -1 do if profile.poolOrder[i] == id then table.remove(profile.poolOrder, i) end end
    for i = #profile.favorites, 1, -1 do
        local value = profile.favorites[i]
        local linePool = value:match("^line:(.*):[^:]+$")
        local playPool = value:match("^play:%a+:(.+)$")
        if value == "pool:" .. id or linePool == id or playPool == id then table.remove(profile.favorites, i) end
    end
    for _, collection in pairs(profile.collections or {}) do
        for i = #(collection.items or {}), 1, -1 do
            local ref = collection.items[i]
            if ref == "pool:" .. id or ref:match("^line:(.*):[^:]+$") == id or ref:match("^play:%a+:(.+)$") == id then table.remove(collection.items, i) end
        end
    end
    -- The currently loaded character and shared layout can both reference this pool.
    -- Archived pre-v3 character records remain intact as migration/recovery backups.
    for _, layout in ipairs({ IC.Profiles.Character().layout, IC.Profiles.db.sharedLayout }) do
        for _, bar in ipairs(layout.bars) do
            local source = bar.source or ""
            if source == "pool:" .. id or source == "lines:" .. id or source:match("^line:(.*):[^:]+$") == id or source:match("^play:%a+:(.+)$") == id then
                if bar.catalogCompanion then bar.hidden = true else bar.source = "favorites" end
            end
        end
    end
    IC.Changed()
end
function D.Move(id, delta)
    local function move(order)
        for i, value in ipairs(order) do
            if value == id then
                local target = i + delta
                if target >= 1 and target <= #order then order[i], order[target] = order[target], order[i] end
                break
            end
        end
    end
    local profile = IC.Profile()
    move(profile.poolOrder)
    for _, actor in pairs(profile.personas or {}) do move(actor.poolIDs) end
    IC.Changed()
end
