local _, IC = ...
IC.Dialogue = { states = {} }
local D = IC.Dialogue
local modes = { random = true, shuffle = true, sequential = true }
local channels = { SAY = true, YELL = true, EMOTE = true }

function D.Clear(id) if id then D.states[id] = nil else D.states = {} end end
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
function D.Select(pool)
    local text, state = D.Next(pool, D.states[pool.id])
    D.states[pool.id] = state
    return text
end
function D.Preview(pool)
    -- A preview neither sends nor consumes the live selection state.
    return D.Next(pool, IC.Copy(D.states[pool.id] or {}))
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
    IC.Changed()
    return pool
end
function D.Save(pool, name, channel, mode, icon, lines)
    if IC.Trim(name) == "" then return false, "A pool needs a name." end
    if not modes[mode] or not channels[channel] then return false, "Invalid mode or channel." end
    for _, line in ipairs(lines) do
        if type(line) ~= "string" or line:find("[%z\1-\31\127]") then return false, "Lines cannot contain control characters." end
    end
    pool.name, pool.channel, pool.mode, pool.icon, pool.lines = IC.Trim(name), channel, mode, icon, IC.Copy(lines)
    pool.revision = (pool.revision or 0) + 1
    IC.Changed()
    return true
end
function D.Delete(id)
    local profile = IC.Profile()
    profile.pools[id] = nil
    D.Clear(id)
    for shortcut, poolID in pairs(profile.shortcuts) do if poolID == id then profile.shortcuts[shortcut] = nil end end
    for i = #profile.poolOrder, 1, -1 do if profile.poolOrder[i] == id then table.remove(profile.poolOrder, i) end end
    for i = #profile.favorites, 1, -1 do if profile.favorites[i] == "pool:" .. id then table.remove(profile.favorites, i) end end
    -- The currently loaded character and shared layout can both reference this pool.
    -- Archived pre-v3 character records remain intact as migration/recovery backups.
    for _, layout in ipairs({ IC.Profiles.Character().layout, IC.Profiles.db.sharedLayout }) do
        for _, bar in ipairs(layout.bars) do if bar.source == "pool:" .. id then bar.source = "favorites" end end
    end
    IC.Changed()
end
function D.Move(id, delta)
    local order = IC.Profile().poolOrder
    for i, value in ipairs(order) do
        if value == id then
            local target = i + delta
            if target >= 1 and target <= #order then order[i], order[target] = order[target], order[i] end
            break
        end
    end
    IC.Changed()
end
