return function(test, eq, page)
    test("review Try is explicit and never marks sound animation or artwork automatically", function(IC, Stub)
        IC.EmoteReview.Open(); local frame = IC.EmoteReview.frame
        assert(frame:IsShown()); eq(#Stub.emotes, 0); local id = frame.id
        frame.try:Click(); eq(#Stub.emotes, 1); eq(IC.Curation.Observation(id).sound, nil)
        assert(not IC.Curation.Record(id).iconReviewed); assert(Stub.KeyDown("W"))
        frame.skip:Click(); eq(#Stub.emotes, 1)
    end)
    test("review Save advances a stable queue and records self sound without claiming nearby audio", function(IC, Stub)
        IC.EmoteReview.Open(); local frame = IC.EmoteReview.frame; local first, second = frame.ids[1], frame.ids[2]
        frame.sound:Choose("self"); frame.animation:Choose("yes"); frame.notes:SetText("Only I checked it")
        Stub.Button(frame, "Keep & next"):Click(); eq(frame.id, second); eq(frame.index, 2)
        eq(IC.Curation.Record(first).choice, "keep"); eq(IC.Curation.Observation(first).sound, "self")
        assert(not IC.Emotes.IsAudible(IC.Actions.Resolve(first))); eq(#Stub.emotes + #Stub.sends, 0)
    end)
    test("hiding and restoring an emote is reversible and does not remove its favorite position", function(IC, Stub)
        local first = IC.Profile().favorites[1]; IC.EmoteReview.Open(first); local frame = IC.EmoteReview.frame
        Stub.Button(frame, "Hide & next"):Click(); eq(IC.Profile().favorites[1], first)
        for _, action in ipairs(IC.Actions.List("favorites")) do assert(action.id ~= first) end
        frame.previous:Click(); eq(frame.id, first); Stub.Button(frame, "Keep & next"):Click()
        eq(IC.Actions.List("favorites")[1].id, first); eq(#Stub.emotes + #Stub.sends, 0)
    end)
    test("invalid duplicate references keep the current review open for correction", function(IC, Stub)
        IC.EmoteReview.Open("emote:wave"); local frame = IC.EmoteReview.frame
        frame.choice:Choose("duplicate"); frame.duplicate:SetText("/wave"); Stub.Button(frame, "Save & next"):Click()
        eq(frame.id, "emote:wave"); eq(frame.index, 1); assert(frame.notice:GetText():find("another known", 1, true))
        frame.duplicate:SetText("/joke"); Stub.Button(frame, "Save & next"):Click()
        eq(IC.Curation.Record("emote:wave").duplicateOf, "emote:silly"); eq(#Stub.emotes + #Stub.sends, 0)
    end)
    test("review icon changes apply to the selected action and need a deliberate choice", function(IC, Stub)
        IC.EmoteReview.Open("emote:wave"); local frame = IC.EmoteReview.frame; assert(not frame.iconReviewed:GetChecked())
        frame.icon:Click(); IC.Editor.picker.path:SetText("765432"); Stub.Button(IC.Editor.picker, "Use icon"):Click()
        eq(IC.Actions.Resolve("emote:wave").icon, 765432); assert(frame.iconReviewed:GetChecked())
        Stub.Button(frame, "Keep & next"):Click(); assert(IC.Curation.Record("emote:wave").iconReviewed)
        eq(#Stub.emotes + #Stub.sends, 0)
    end)
    test("full command view restores hidden emotes without re-enabling them automatically", function(IC, Stub)
        IC.Curation.Save("emote:wave", "hide", "unknown", "unknown")
        local p = page(IC, "Emotes"); IC.Editor.emoteCategory = "all"; p.search:SetText("wave")
        eq(#p.shown, 1); p.tiles[1]:Click(); eq(p.dKeep:GetText(), "Keep in everyday use")
        p.dKeep:Click(); eq(IC.Curation.Record("emote:wave").choice, "keep"); eq(#Stub.emotes + #Stub.sends, 0)
    end)
    test("review completion is safe and changing a review set never performs anything", function(IC, Stub)
        IC.EmoteReview.Open(); local frame = IC.EmoteReview.frame
        local count = #frame.ids
        for _ = 1, count do frame.skip:Click() end
        assert(frame.complete:IsShown()); assert(not frame.form:IsShown()); assert(not frame.skip:IsEnabled())
        frame.previous:Click(); assert(frame.form:IsShown())
        frame.mode:Choose("all"); eq(frame.index, 1); eq(#Stub.emotes + #Stub.sends, 0)
    end)
    test("review refuses combat and closes with the editor while quick actions stay usable", function(IC, Stub, env, event)
        IC.EmoteReview.Open(); local frame = IC.EmoteReview.frame
        Stub.combat = true; event("PLAYER_REGEN_DISABLED"); assert(not frame:IsShown())
        IC.EmoteReview.Open(); assert(not frame:IsShown()); assert(Stub.KeyDown("W")); eq(#Stub.emotes + #Stub.sends, 0)
    end)
end
