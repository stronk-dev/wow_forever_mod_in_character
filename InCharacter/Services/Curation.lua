local _, IC = ...
IC.Curation = {}
local R = IC.Curation
-- A starting selection, not a limit or a claim of verified animations/audio.
-- Similar word variants and flavour-only commands stay in All commands until kept.
R.suggestions = { "wave", "bow", "salute", "thank", "nod", "no", "laugh", "cheer", "cry", "shrug",
    "dance", "flex", "sit", "sleep", "kneel", "point", "chicken", "train", "silly", "roar",
    "charge", "incoming", "flee", "helpme", "healme", "oom" }
local suggested = {}; for _, command in ipairs(R.suggestions) do suggested["emote:" .. command] = true end
function R.Record(id, profile) return (profile or IC.Profile()).emoteReview[IC.Actions.CanonicalID(id)] or {} end
function R.Observation(id)
    local character = IC.Profiles.Character()
    return character.emoteObservations[IC.Actions.CanonicalID(id)] or {}
end
function R.Included(action, profile)
    profile = profile or IC.Profile()
    local record = R.Record(action.id, profile)
    if record.choice == "hide" or record.choice == "duplicate" or record.choice == "text" then return false end
    if profile.emoteScope == "all" or record.choice == "keep" or suggested[action.id] then return true end
    -- Preserve deliberately pinned choices while trimming the automatically listed commands.
    for _, id in ipairs(profile.favorites) do if IC.Actions.CanonicalID(id) == action.id then return true end end
    return false
end
function R.Save(id, choice, sound, animation, duplicateOf, notes, iconReviewed)
    id = IC.Actions.CanonicalID(id)
    if not IC.Emotes.byID[id] then return false, "Unknown emote." end
    local choices = { pending = true, keep = true, hide = true, duplicate = true, text = true }
    local sounds = { unknown = true, self = true, nearby = true, silent = true }
    local animations = { unknown = true, yes = true, no = true }
    if not choices[choice] or not sounds[sound] or not animations[animation] then return false, "Choose a review result." end
    duplicateOf = IC.Trim(duplicateOf or ""):lower():gsub("^/", "")
    local other
    if choice == "duplicate" and duplicateOf ~= "" then
        other = IC.Emotes.byID[duplicateOf] or IC.Emotes.byID["emote:" .. duplicateOf]
        if not other then
            for _, action in ipairs(IC.Emotes.list) do for _, alias in ipairs(action.aliases) do if alias == duplicateOf then other = action; break end end; if other then break end end
        end
        if not other or other.id == id then return false, "Choose another known /command as the duplicate reference, or leave it blank." end
    end
    if choice == "text" then sound, animation = "silent", "no" end
    IC.Profile().emoteReview[id] = { choice = choice, duplicateOf = other and other.id, notes = tostring(notes or ""), iconReviewed = iconReviewed == true }
    local build = GetBuildInfo and select(2, GetBuildInfo())
    IC.Profiles.Character().emoteObservations[id] = { sound = sound, animation = animation, build = build }
    IC.Changed(); return true
end
function R.Badge(action)
    local observed = R.Observation(action.id)
    local label, color = "Not checked", "ff999999"
    if observed.sound == "nearby" then label, color = "Others heard", "ff66ddaa"
    elseif observed.sound == "self" then label, color = "You heard", "ff88bbdd"
    elseif observed.animation == "yes" then label, color = "Animation seen", "ffffd166"
    elseif observed.sound == "silent" and observed.animation == "no" then label = "Text only"
    elseif observed.sound == "silent" then label = "No sound heard" end
    return "|c" .. color .. label .. "|r", { label = label, color = color,
        help = "Your observations on this character. Nearby audio needs another player to confirm it. The addon cannot detect sound or animation automatically." }
end
function R.Queue(mode)
    local result, used = {}, {}
    local function add(action)
        if not action or not action.verified or used[action.payload] then return end
        used[action.payload] = true
        local record = R.Record(action.id)
        if mode == "pending" and record.choice and record.choice ~= "pending" then return end
        if mode == "icons" and record.iconReviewed then return end
        if mode == "kept" and not R.Included(action) then return end
        result[#result + 1] = action.id
    end
    for _, command in ipairs(R.suggestions) do add(IC.Emotes.byID["emote:" .. command]) end
    for _, action in ipairs(IC.Emotes.list) do add(action) end
    return result
end
