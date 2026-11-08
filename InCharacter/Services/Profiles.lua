local _, IC = ...
IC.Profiles = { VERSION = 2 }
local P = IC.Profiles

local function CompleteLayout(layout)
    IC.Merge(layout, IC.Defaults.Layout())
    for index, bar in ipairs(layout.bars) do IC.Merge(bar, IC.Defaults.Bar(index)) end
    return layout
end

local function CompleteProfile(profile)
    -- Pool maps are user collections: never merge seed pools back into an existing map.
    local defaults = IC.Defaults.Profile()
    local pools = profile.pools
    defaults.pools = nil
    if pools ~= nil then defaults.poolOrder = nil end
    IC.Merge(profile, defaults)
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
    end
    table.sort(missing)
    for _, id in ipairs(missing) do order[#order + 1] = id end
    profile.poolOrder = order
    return profile
end

function P.Open(database, characterKey)
    local db = type(database) == "table" and database or {}
    if type(db.version) == "number" and db.version > P.VERSION then
        error("In Character: this database is newer than this addon; install the newer addon to preserve it.")
    end
    -- v1 stored the shared profile under account; retain unknown fields for future migrations.
    if not db.profiles then db.profiles = { account = db.account or IC.Defaults.Profile() } end
    db.profiles.account = CompleteProfile(db.profiles.account or IC.Defaults.Profile())
    db.characters = db.characters or {}
    db.sharedLayout = CompleteLayout(db.sharedLayout or IC.Defaults.Layout())
    for _, character in pairs(db.characters) do
        if character.profile then CompleteProfile(character.profile) end
        if character.layout then CompleteLayout(character.layout) end
    end
    local character = db.characters[characterKey]
    if not character then character = {}; db.characters[characterKey] = character end
    IC.Merge(character, { scope = "account", layoutScope = "character", layout = IC.Defaults.Layout() })
    CompleteLayout(character.layout)
    character.profile = character.profile or IC.Copy(db.profiles.account)
    CompleteProfile(character.profile)
    db.version = P.VERSION
    P.key, P.db = characterKey, db
    return db
end
function P.Character() return P.db.characters[P.key] end
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
