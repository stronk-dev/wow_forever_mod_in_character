local _, IC = ...
IC.Profiles = { VERSION = 8 }
local P = IC.Profiles

local function CompleteLayout(layout)
    local initializeCatalog = not layout.catalogBarInitialized
    IC.Merge(layout, IC.Defaults.Layout())
    for index, bar in ipairs(layout.bars) do
        if not bar.stripIntroduced then
            local emotes = bar.source == "favoriteEmotes" or bar.source == "categories" or bar.source == "all"
            for _, id in ipairs(IC.Emotes.categories) do if bar.source == id then emotes = true end end
            if emotes and not bar.catalog and not bar.catalogCompanion and (not bar.buttonStyle or bar.buttonStyle == "icons") then
                bar.previousGrid = { labels = bar.labels, columns = bar.columns, rows = bar.rows, size = bar.size }
                bar.strip, bar.labels = true, false
                bar.stripRows = math.max(1, math.min(4, bar.rows or 1))
            end
        end
        IC.Merge(bar, IC.Defaults.Bar(index)); bar.stripIntroduced = true
    end
    if initializeCatalog and #layout.bars > 0 then
        local found
        for _, bar in ipairs(layout.bars) do if bar.catalog then found = true end end
        if not found then layout.bars[#layout.bars + 1] = IC.Defaults.CatalogBar(#layout.bars + 1) end
    end
    layout.catalogBarInitialized = true
    return layout
end

local function CompleteProfile(profile, database)
    -- Pool maps are user collections: never merge seed pools back into an existing map.
    local defaults = IC.Defaults.Profile()
    local introduceBars = not (profile.quick and profile.quick.barsIntroduced)
    local pools = profile.pools
    defaults.pools = nil
    if pools ~= nil then defaults.poolOrder = nil end
    IC.Merge(profile, defaults)
    if profile.quick.style == "panel" and introduceBars then
        profile.quick.previousStyle, profile.quick.style = "panel", "bars"
    end
    profile.quick.barsIntroduced = true
    local filters = { all = true, heard = true, observed = true, textChecked = true }
    if not filters[profile.emoteFilter] then profile.emoteFilter = "all" end
    if profile.emoteScope ~= "all" and profile.emoteScope ~= "essentials" then profile.emoteScope = "essentials" end
    if pools == nil then profile.pools = IC.Defaults.Profile().pools end
    if type(profile.poolOrder) ~= "table" then profile.poolOrder = {} end
    local seen, order = {}, {}
    for _, id in ipairs(profile.poolOrder) do
        if profile.pools[id] and not seen[id] then order[#order + 1] = id; seen[id] = true end
    end
    local missing = {}
    for id, pool in pairs(profile.pools) do
        if not seen[id] then missing[#missing + 1] = id end
        pool.id = id
        IC.Merge(pool, IC.Defaults.Pool(id, id))
        IC.Dialogue.EnsureLines(pool, database)
    end
    table.sort(missing)
    for _, id in ipairs(missing) do order[#order + 1] = id end
    profile.poolOrder = order
    -- Canonicalize legacy aliases without losing a pin or creating duplicates.
    local favorites, pinned = {}, {}
    for _, id in ipairs(profile.favorites) do
        local emote = IC.Emotes.byID[id]
        local canonical = emote and emote.id or id
        if not pinned[canonical] then favorites[#favorites + 1] = canonical; pinned[canonical] = true end
        if canonical ~= id and profile.emoteOverrides[id] and not profile.emoteOverrides[canonical] then
            profile.emoteOverrides[canonical] = IC.Copy(profile.emoteOverrides[id])
        end
    end
    profile.favorites = favorites
    return profile
end

function P.Open(database, characterDatabase, legacyKeys)
    local db = type(database) == "table" and database or {}
    local character = type(characterDatabase) == "table" and characterDatabase or {}
    if type(db.version) == "number" and db.version > P.VERSION then
        error("In Character: this database is newer than this addon; install the newer addon to preserve it.")
    end
    if type(character.version) == "number" and character.version > P.VERSION then
        error("In Character: character settings are newer than this addon; install the newer addon.")
    end
    -- v1 stored the shared profile under account; retain unknown fields for future migrations.
    if not db.profiles then db.profiles = { account = db.account or IC.Defaults.Profile() } end
    db.profiles.account = CompleteProfile(db.profiles.account or IC.Defaults.Profile(), db)
    db.sharedLayout = CompleteLayout(db.sharedLayout or IC.Defaults.Layout())
    if character.version == nil and next(character) == nil and db.characters then
        local matches, seen = {}, {}
        for _, key in ipairs(legacyKeys or {}) do
            if db.characters[key] and not seen[key] then matches[#matches + 1] = key; seen[key] = true end
        end
        if matches[1] then
            IC.Merge(character, db.characters[matches[1]])
            character.legacyKey = matches[1]
            if #matches > 1 then
                character.legacyConflicts = matches
                IC.Print("Found multiple legacy character records. Migrated " .. matches[1] .. "; originals remain in InCharacterDB.characters for recovery.")
            end
        end
    end
    -- Keep all legacy records intact so other characters can migrate when they log in.
    IC.Merge(character, { scope = "account", layoutScope = "character", emoteObservations = {} })
    character.layout = character.layout or IC.Defaults.Layout()
    CompleteLayout(character.layout)
    if character.profile then CompleteProfile(character.profile, db) end
    if character.scope == "character" and not character.profile then character.profile = IC.Copy(db.profiles.account) end
    db.version, character.version = P.VERSION, P.VERSION
    P.db, P.character = db, character
    return db
end
function P.Character() return P.character end
function P.Get()
    local character = P.Character()
    return character.scope == "character" and character.profile or P.db.profiles.account
end
function P.Layout()
    local character = P.Character()
    return character.layoutScope == "account" and P.db.sharedLayout or character.layout
end
function P.SetScope(scope)
    assert(scope == "account" or scope == "character", "invalid profile scope")
    if scope == "character" and not P.Character().profile then P.Character().profile = IC.Copy(P.db.profiles.account) end
    P.Character().scope = scope
    IC.Dialogue.Clear()
    IC.Changed()
end
function P.SetLayoutScope(scope)
    assert(scope == "account" or scope == "character", "invalid layout scope")
    P.Character().layoutScope = scope
    IC.Changed()
end
function P.CopyAccount()
    P.Character().profile = IC.Copy(P.db.profiles.account)
    P.Character().scope = "character"
    IC.Dialogue.Clear()
    IC.Changed()
end
function P.Reset()
    local character = P.Character()
    if character.scope == "character" then character.profile = IC.Defaults.Profile()
    else P.db.profiles.account = IC.Defaults.Profile() end
    IC.Dialogue.Clear()
    IC.Changed()
end
