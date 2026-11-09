local _, IC = ...
-- Emote library. Facts (animation / voice) come from Data/EmoteCatalog.lua (Warcraft Wiki).
-- Whether an emote is usable comes from the running client's EMOTE<n>_TOKEN table.
local E = { list = {}, byID = {}, byCategory = {} }
IC.Emotes = E

local I = "Interface\\Icons\\"
E.KindInfo = {
    sound = { label = "Sound (ref)", color = "ff4fc3f7", icon = I .. "Ability_Warrior_BattleShout",
        help = "Retail reference: voiced animation. Nearby audio and animation on Forever are unverified and can depend on race and gender." },
    voice = { label = "Sound (ref)", color = "ff4fc3f7", icon = I .. "Ability_Warrior_BattleShout",
        help = "Retail reference: voice without animation. Nearby audio on Forever is unverified and can depend on race and gender." },
    animation = { label = "Anim. (ref)", color = "ffffd166", icon = I .. "Ability_Rogue_Disguise",
        help = "Retail reference: silent animation. Animation and silence on Forever need live verification." },
    text = { label = "Text (ref)", color = "ffa0a0a0", icon = I .. "INV_Misc_Note_01",
        help = "Retail reference: text only. The absence of audio or animation on Forever is unverified." },
    unknown = { label = "Unlisted", color = "ffa0a0a0", icon = I .. "INV_Misc_QuestionMark",
        help = "This client knows the emote, but the reference list does not say whether it animates or makes a sound." },
}
E.Filters = {
    { value = "all", label = "All" },
    { value = "heard", label = "Sound checked" },
    { value = "observed", label = "Animation checked" },
    { value = "textChecked", label = "Text checked" },
}

-- Guided categories. Ids are stable (bars and saved favorites refer to them).
E.categories = { "Combat", "Social", "Reactions", "Idle", "Voice/Fun" }
E.CategoryInfo = {
    Favorites = { label = "Favorites", icon = I .. "Spell_Holy_PowerInfusion", hint = "Your pinned emotes and dialogue." },
    Combat = { label = "Combat callouts", icon = I .. "Ability_Warrior_BattleShout",
        hint = "Group callouts: charge, heal me, out of mana. Check the result on your character." },
    Social = { label = "Greetings & manners", icon = I .. "Spell_Holy_PrayerOfHealing",
        hint = "Wave, bow, thank and welcome people." },
    Reactions = { label = "Reactions", icon = I .. "Spell_Holy_MindVision",
        hint = "Laugh, cheer, cry, facepalm: react to what just happened." },
    Idle = { label = "Poses & idle", icon = I .. "Spell_Nature_Sleep",
        hint = "Poses and activities: dance, flex, sit and read. Check the result on your character." },
    ["Voice/Fun"] = { label = "Playful emotes", icon = I .. "Ability_Druid_DemoralizingRoar",
        hint = "Chicken, train, roar and more. Sound stays unverified until you check it." },
    Roleplay = { label = "Roleplay lines", icon = I .. "INV_Misc_Book_09", hint = "Your dialogue pools." },
    all = { label = "All emotes", icon = I .. "INV_Misc_Note_01", hint = "Every emote this client knows." },
    essentials = { label = "Everyday emotes", icon = I .. "INV_Gauntlets_04", hint = "A smaller starting selection plus the emotes you keep. Review and change it freely." },
}
local curated = {
    Combat = { "charge", "attacktarget", "incoming", "openfire", "flee", "helpme", "healme", "oom",
        "followme", "wait", "threaten", "cower", "victory" },
    Social = { "wave", "hello", "bye", "bow", "salute", "curtsey", "thank", "welcome", "congratulate",
        "nod", "no", "apologize", "kiss", "flirt", "hug", "beckon", "highfive" },
    Reactions = { "laugh", "cheer", "applaud", "cry", "angry", "gasp", "shrug", "facepalm", "boggle", "blush",
        "sigh", "rofl", "giggle", "gloat", "mourn", "oops", "whoa", "taunt", "rude", "beg", "confused", "golfclap" },
    Idle = { "dance", "flex", "sit", "stand", "sleep", "lay", "kneel", "point", "pray", "talk", "read",
        "eat", "drink", "shy", "bashful", "lean", "ponder", "think" },
    ["Voice/Fun"] = { "chicken", "train", "silly", "roar", "cackle", "guffaw", "rasp", "violin", "moo",
        "forthealliance", "forthehorde", "cheer", "laugh", "kiss" },
}
local names = {
    attacktarget = "Attack target", openfire = "Open fire", helpme = "Help me", healme = "Heal me",
    oom = "Out of mana", followme = "Follow me", highfive = "High five", golfclap = "Golf clap",
    lay = "Lie down", forthealliance = "For the Alliance!", forthehorde = "For the Horde!", rofl = "ROFL",
    silly = "Silly / joke", congratulate = "Congratulate",
}
local icons = {
    charge = "Ability_Warrior_Charge", attacktarget = "Ability_Hunter_SniperShot", incoming = "Ability_Warrior_BattleShout",
    openfire = "Spell_Fire_Fireball02", flee = "Ability_Rogue_Sprint", helpme = "Spell_Holy_SealOfSacrifice",
    healme = "Spell_Holy_FlashHeal", oom = "Spell_Shadow_ManaBurn", followme = "Ability_Tracking",
    wait = "INV_Misc_PocketWatch_01", threaten = "Ability_Warrior_WarCry", cower = "Spell_Shadow_PsychicScream",
    victory = "INV_Misc_Head_Dragon_01", wave = "INV_Gauntlets_04", hello = "Spell_Holy_PrayerOfHealing",
    bye = "INV_Misc_Map_01", bow = "Spell_Holy_GreaterBlessingofKings", salute = "INV_Sword_04",
    thank = "Spell_Holy_Renew", welcome = "INV_Misc_Gift_01", congratulate = "INV_Misc_Gift_02",
    nod = "Spell_Holy_SealOfMight", no = "Spell_Holy_Silence", apologize = "INV_Misc_Flower_02",
    kiss = "INV_ValentinesCandy", flirt = "INV_Misc_Flower_02", highfive = "INV_Gauntlets_04",
    cheer = "Ability_Warrior_RallyingCry", angry = "Ability_Racial_BloodRage", cry = "Spell_Frost_FrostShock",
    gasp = "Spell_Holy_MindVision", mourn = "INV_Misc_Bone_HumanSkull_01", taunt = "Spell_Nature_Reincarnation",
    flex = "Spell_Nature_Strength", eat = "Spell_Misc_Food", drink = "Spell_Misc_Drink", sleep = "Spell_Nature_Sleep",
    lay = "Spell_Nature_Sleep", pray = "Spell_Holy_PrayerOfHealing", read = "INV_Misc_Book_09",
    think = "Spell_Holy_MindVision", ponder = "Spell_Holy_MindVision", shy = "Ability_Stealth", bashful = "Ability_Stealth",
    chicken = "Spell_Magic_PolymorphChicken", silly = "Spell_Nature_Polymorph", roar = "Ability_Druid_DemoralizingRoar",
    cackle = "Spell_Shadow_Charm", forthealliance = "INV_BannerPVP_02", forthehorde = "INV_BannerPVP_01",
}

local function displayName(command)
    return names[command] or (command:sub(1, 1):upper() .. command:sub(2))
end
local function kindOf(animated, voice)
    if animated and voice then return "sound" end
    if voice then return "voice" end
    if animated then return "animation" end
    return "text"
end
function E.IsAudible(action) return IC.Curation and IC.Curation.Observation(action.id).sound == "nearby" or false end

local function addEmote(command, aliases, animated, voice, fromCatalog)
    local action = {
        id = "emote:" .. command, type = "emote", command = command, aliases = aliases,
        label = "/" .. command, name = displayName(command), payload = command:upper(),
        animated = animated, audible = voice, kind = fromCatalog and kindOf(animated, voice) or "unknown",
        catalog = fromCatalog, categories = {}, verified = false,
    }
    action.icon = IC.EmoteIcons and IC.EmoteIcons[command] or (icons[command] and (I .. icons[command])) or "Interface\\Icons\\INV_Misc_Note_01"
    E.byID[action.id] = action
    E.list[#E.list + 1] = action
    return action
end

for _, row in ipairs(IC.EmoteCatalog or {}) do
    local words, flags = row:match("^([^|]+)|?(%a*)$")
    local commands = {}
    for word in words:gmatch("%S+") do commands[#commands + 1] = word end
    addEmote(commands[1], commands, flags:find("A") ~= nil, flags:find("V") ~= nil, true)
end
-- Older saved favorites used /joke, which the client treats as an alias of /silly.
if E.byID["emote:silly"] then
    table.insert(E.byID["emote:silly"].aliases, "joke"); E.byID["emote:joke"] = E.byID["emote:silly"]
end
for _, category in ipairs(E.categories) do
    E.byCategory[category] = {}
    for _, command in ipairs(curated[category]) do
        local action = E.byID["emote:" .. command]
        if action then
            action.categories[category] = true
            if not action.category then action.category = category end
            table.insert(E.byCategory[category], action)
        end
    end
end

function E.Validate()
    local tokens, aliases, primary, clientAliases = IC.Platform.EmoteCommands()
    -- Drop entries added by an earlier validation for emotes only that client knew.
    for i = #E.list, 1, -1 do
        local action = E.list[i]
        if action.clientOnly then table.remove(E.list, i); E.byID[action.id] = nil end
    end
    local claimed = {}
    for _, emote in ipairs(E.list) do
        local token
        for _, alias in ipairs(emote.aliases) do token = token or aliases[alias] end
        token = token or (tokens[emote.command:upper()] and emote.command:upper())
        emote.payload = token or emote.command:upper()
        emote.verified = token ~= nil
        emote.clientAliases = token and clientAliases[token] or nil
        if token then claimed[token] = true end
    end
    for token in pairs(tokens) do
        local command = primary[token] or token:lower()
        if not claimed[token] and not E.byID["emote:" .. command] then
            local action = addEmote(command, { command }, false, false, false)
            action.payload, action.verified, action.clientOnly = token, true, true
            action.clientAliases = clientAliases[token]
        end
    end
    table.sort(E.list, function(a, b) return a.command < b.command end)
end

function E.Matches(action, filter)
    if filter == "heard" or filter == "observed" or filter == "textChecked" then
        local seen = IC.Curation.Observation(action.id)
        if filter == "heard" then return seen.sound == "self" or seen.sound == "nearby" end
        if filter == "observed" then return seen.animation == "yes" end
        return seen.sound == "silent" and seen.animation == "no"
    end
    return true
end
function E.Visible(action, profile)
    if profile.hideUnverified and not action.verified then return false end
    if IC.Curation and not IC.Curation.Included(action, profile) then return false end
    return E.Matches(action, profile.emoteFilter)
end
function E.Search(action, text)
    text = IC.Trim(text or ""):lower():gsub("^/", "")
    if text == "" then return true end
    if action.name:lower():find(text, 1, true) then return true end
    for _, alias in ipairs(action.aliases) do if alias:find(text, 1, true) then return true end end
    for _, alias in ipairs(action.clientAliases or {}) do if alias:find(text, 1, true) then return true end end
    return false
end
function E.Badge(action)
    if IC.Curation then return IC.Curation.Badge(action) end
    return "Not checked", { help = "Sound and animation have not been checked on this character." }
end
