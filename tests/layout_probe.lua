-- Layout probe: loads the addon in the mocked client, opens every surface in realistic states,
-- resolves every anchor into a screen rectangle and writes an SVG wireframe per state plus a
-- findings report (truncated text, text outside its panel, overlapping controls, padding).
-- These are wireframes computed from the layout code, NOT game screenshots: fonts and art are
-- approximated (Friz Quadrata widths are estimated per character).
-- Usage: lua tests/layout_probe.lua <output directory>
local OUT = arg[1] or "probe"
os.execute("mkdir -p '" .. OUT .. "'")

local function chunk(path, environment)
    if setfenv then return setfenv(assert(loadfile(path)), environment) end
    return assert(loadfile(path, "t", environment))
end
local function fixture()
    local env = setmetatable({}, { __index = _G }); env._G = env
    local Stub = chunk("tests/wow_stub.lua", env)(); Stub.Install()
    -- A realistic client: every emote in the generated catalog exists (the stub only has seven).
    local index = 0
    for line in io.lines("InCharacter/Data/EmoteCatalog.lua") do
        local entry = line:match('^%s*"([^"]+)",')
        if entry then
            index = index + 1
            local words = {}; for word in entry:gsub("|.*$", ""):gmatch("%S+") do words[#words + 1] = word end
            env["EMOTE" .. index .. "_TOKEN"] = words[1]:upper()
            for n, word in ipairs(words) do if n <= 4 then env["EMOTE" .. index .. "_CMD" .. n] = "/" .. word end end
        end
    end
    -- A recording tooltip so hover text can be drawn and measured.
    local tip = { lines = {} }
    function tip:SetOwner(owner, anchor) self.owner, self.anchor, self.lines = owner, anchor or "ANCHOR_TOP", {} end
    function tip:SetText(text) self.lines = { { tostring(text or ""), "GameTooltipHeaderText" } } end
    function tip:AddLine(text, _, _, _, wrap) self.lines[#self.lines + 1] = { tostring(text or ""), "GameTooltipText", wrap } end
    function tip:Show() self.visible = true end
    function tip:Hide() self.visible = false end
    env.GameTooltip = tip
    local IC = {}
    for line in io.lines("InCharacter/InCharacter.toc") do
        if line:match("%.lua$") then chunk("InCharacter/" .. line, env)("InCharacter", IC) end
    end
    local function event(name, ...)
        local frames = {}; for i, frame in ipairs(Stub.frames) do frames[i] = frame end
        for _, frame in ipairs(frames) do if frame.events[name] then frame:Fire("OnEvent", name, ...) end end
    end
    event("ADDON_LOADED", "InCharacter")
    return IC, Stub, env, tip
end

-- Fonts ---------------------------------------------------------------------------------------
local FONTS = {
    GameFontNormal = { 12, "gold" }, GameFontHighlight = { 12, "white" }, GameFontNormalLarge = { 16, "gold" },
    GameFontNormalSmall = { 10, "gold" }, GameFontHighlightSmall = { 10, "white" }, GameFontDisableSmall = { 10, "gray" },
    GameFontDisable = { 12, "gray" }, GameTooltipHeaderText = { 14, "white" }, GameTooltipText = { 12, "white" },
}
local COLORS = { gold = "#ffd100", white = "#ffffff", gray = "#808080" }
local function font(region) return FONTS[region.font or "GameFontHighlight"] or FONTS.GameFontHighlight end
local function strip(text) return (tostring(text or ""):gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""):gsub("||", "|")) end
-- Estimated Friz Quadrata advance per character, as a fraction of the font size.
local function charWidth(c, size)
    if c:match("[iljI%.,;:'!|%(%)%[%]]") then return size * 0.28 end
    if c == " " then return size * 0.3 end
    if c:match("[MWmw@]") then return size * 0.82 end
    if c:match("[A-Z]") then return size * 0.66 end
    if c:match("%d") then return size * 0.56 end
    if c:byte() and c:byte() > 127 then return size * 0.3 end
    return size * 0.52
end
local function textWidth(text, size)
    local w = 0; for c in strip(text):gmatch(".") do w = w + charWidth(c, size) end
    return math.ceil(w)
end
-- What WoW shows when a single line does not fit: as many characters as fit, then "...".
local function fit(text, size, width)
    text = strip(text)
    if textWidth(text, size) <= width then return text, false end
    local dots = textWidth("...", size)
    local shown, w = "", 0
    for c in text:gmatch(".") do
        local cw = charWidth(c, size)
        if w + cw + dots > width then break end
        shown, w = shown .. c, w + cw
    end
    return shown .. "...", true
end
local function wrapLines(text, size, width)
    local lines = {}
    for paragraph in (strip(text) .. "\n"):gmatch("(.-)\n") do
        local line = ""
        for word in paragraph:gmatch("%S+") do
            local candidate = line == "" and word or (line .. " " .. word)
            if line ~= "" and textWidth(candidate, size) > width then lines[#lines + 1] = line; line = word else line = candidate end
        end
        lines[#lines + 1] = line
    end
    return lines
end

-- Geometry ------------------------------------------------------------------------------------
local SCREEN_W, SCREEN_H = 1920, 1080
local function parts(point)
    local v = point:match("^TOP") and "TOP" or point:match("^BOTTOM") and "BOTTOM" or "CENTER"
    local h = point:match("LEFT$") and "LEFT" or point:match("RIGHT$") and "RIGHT" or "CENTER"
    return h, v
end
local rectCache, UIPARENT
local function rect(region)
    if rectCache[region] then return rectCache[region] end
    if region == UIPARENT or not region.parent and region.kind ~= "FontString" and region.kind ~= "Texture" and not region.points then
        local r = { l = 0, r = SCREEN_W, b = 0, t = SCREEN_H }; rectCache[region] = r; return r
    end
    rectCache[region] = { l = 0, r = 0, b = 0, t = 0, pending = true }
    -- A scroll child is placed at its scroll frame's top-left, shifted by the scroll offset.
    if not region.points or next(region.points) == nil then
        local parent = region.parent
        if parent and parent.kind == "ScrollFrame" and parent.scrollChild == region then
            local pr = rect(parent)
            local top = pr.t + (parent.scroll or 0)
            local r = { l = pr.l, r = pr.l + (region.width or 0), t = top, b = top - (region.height or 0) }
            rectCache[region] = r; return r
        end
    end
    local hc, vc = {}, {}
    for point, spec in pairs(region.points or {}) do
        local relative = spec[1] or region.parent or UIPARENT
        local rr = rect(relative)
        local h, v = parts(point); local rh, rv = parts(spec[2])
        local ax = rh == "LEFT" and rr.l or rh == "RIGHT" and rr.r or (rr.l + rr.r) / 2
        local ay = rv == "BOTTOM" and rr.b or rv == "TOP" and rr.t or (rr.b + rr.t) / 2
        hc[h] = ax + (spec[3] or 0); vc[v] = ay + (spec[4] or 0)
    end
    local natural, naturalH
    if region.kind == "FontString" then
        local size = font(region)[1]
        natural = textWidth(region.text or "", size); naturalH = size + 2
    end
    local w = region.width or natural or 0
    local h = region.height or naturalH or 0
    if region.kind == "FontString" and region.width and region.wordWrap ~= false and not (hc.LEFT and hc.RIGHT) then
        local size = font(region)[1]
        naturalH = #wrapLines(region.text or "", size, region.width) * (size + 2); h = region.height or naturalH
    end
    local l, r
    if hc.LEFT and hc.RIGHT then l, r = hc.LEFT, hc.RIGHT
    elseif hc.LEFT then l, r = hc.LEFT, hc.LEFT + w
    elseif hc.RIGHT then l, r = hc.RIGHT - w, hc.RIGHT
    elseif hc.CENTER then l, r = hc.CENTER - w / 2, hc.CENTER + w / 2
    else l, r = nil, nil end
    local b, t
    if vc.TOP and vc.BOTTOM then b, t = vc.BOTTOM, vc.TOP
    elseif vc.TOP then t, b = vc.TOP, vc.TOP - h
    elseif vc.BOTTOM then b, t = vc.BOTTOM, vc.BOTTOM + h
    elseif vc.CENTER then b, t = vc.CENTER - h / 2, vc.CENTER + h / 2 end
    local result = l and b and { l = l, r = r, b = b, t = t } or nil
    rectCache[region] = result or { l = 0, r = 0, b = 0, t = 0, unplaced = true }
    return rectCache[region]
end

-- Drawing -------------------------------------------------------------------------------------
local STRATA = { BACKGROUND = 1, LOW = 2, MEDIUM = 3, HIGH = 4, DIALOG = 5, FULLSCREEN = 6, FULLSCREEN_DIALOG = 7, TOOLTIP = 8 }
local LAYER = { BACKGROUND = 1, BORDER = 2, ARTWORK = 3, OVERLAY = 4, HIGHLIGHT = 5 }
local function strata(region)
    local node = region
    while node do if node.strata then return STRATA[node.strata] or 3 end; node = node.parent end
    return 3
end
local function depth(region) local d, node = 0, region; while node.parent do d = d + 1; node = node.parent end; return d end
local function esc(s) return (tostring(s):gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;"):gsub('"', "&quot;")) end
local function rgb(c, alpha)
    if not c then return "none" end
    return string.format("rgba(%d,%d,%d,%.2f)", math.floor((c[1] or 0) * 255), math.floor((c[2] or 0) * 255), math.floor((c[3] or 0) * 255), alpha or c[4] or 1)
end
local function iconColor(path)
    local h = 0; for c in tostring(path):gmatch(".") do h = (h * 31 + c:byte()) % 360 end
    return string.format("hsl(%d,35%%,38%%)", h)
end
local function visible(region) return region:IsShown() end
local function owner(region) return region.parent end
local function isBackdropped(region) return region.backdrop ~= nil end

local function snapshot(Stub, tip, name, focus, note, env)
    rectCache, UIPARENT = {}, env.UIParent
    local items = {}
    for index, region in ipairs(Stub.frames) do
        if region ~= UIPARENT and visible(region) then
            local r = rect(region)
            local clipped = false
            local node = region.parent
            while node do
                if node.kind == "ScrollFrame" then
                    local sr = rect(node)
                    if r.b >= sr.t - 1 or r.t <= sr.b + 1 then clipped = true end
                end
                node = node.parent
            end
            if not clipped and not r.unplaced and r.r - r.l >= 0 then items[#items + 1] = { region = region, r = r, index = index } end
        end
    end
    table.sort(items, function(a, b)
        local sa, sb = strata(a.region), strata(b.region)
        if sa ~= sb then return sa < sb end
        local fa, fb = a.region.frameLevel or depth(a.region), b.region.frameLevel or depth(b.region)
        if a.region.kind ~= "FontString" and a.region.kind ~= "Texture" and b.region.kind ~= "FontString" and b.region.kind ~= "Texture" and fa ~= fb then return fa < fb end
        return a.index < b.index
    end)
    local findings = {}
    local function finding(kind, region, r, text) findings[#findings + 1] = { kind = kind, region = region, r = r, text = text } end
    local svg = {}
    -- Focus box: the union of the named roots (or the whole screen).
    local fx1, fy1, fx2, fy2 = math.huge, math.huge, -math.huge, -math.huge
    local function include(r) fx1, fy1, fx2, fy2 = math.min(fx1, r.l), math.min(fy1, r.b), math.max(fx2, r.r), math.max(fy2, r.t) end
    for _, root in ipairs(focus or {}) do if root and visible(root) then include(rect(root)) end end
    local texts = {}
    for _, item in ipairs(items) do
        local region, r = item.region, item.r
        local x, y, w, h = r.l, SCREEN_H - r.t, r.r - r.l, r.t - r.b
        if region.kind == "FontString" then
            local text = region.text or ""
            if strip(text) ~= "" then
                local size, colour = font(region)[1], font(region)[2]
                local fill = region.textColor and rgb(region.textColor) or COLORS[colour]
                local natural = textWidth(text, size)
                local allotted = (region.width or (region.points and region.points.LEFT and region.points.RIGHT)) and w or nil
                local lines
                if allotted and region.wordWrap ~= false and not (region.points.LEFT and region.points.RIGHT) then
                    lines = wrapLines(text, size, allotted)
                    if region.height and #lines * (size + 2) > region.height + 2 then finding("text overflows its height", region, r, strip(text)) end
                elseif allotted then
                    local shown, cut = fit(text, size, allotted)
                    lines = { shown }
                    if cut then finding("truncated", region, r, strip(text) .. "  →  shows: " .. shown) end
                else lines = { strip(text) } end
                local justify = region.justifyH or "CENTER"
                if region.points and (region.points.TOPLEFT or region.points.LEFT or region.points.BOTTOMLEFT) and not region.justifyH and not allotted then justify = "LEFT" end
                local baseY = y + (h - #lines * (size + 2)) / 2 + size
                for n, line in ipairs(lines) do
                    local anchor, tx = "start", x
                    if justify == "CENTER" then anchor, tx = "middle", x + w / 2 elseif justify == "RIGHT" then anchor, tx = "end", x + w end
                    svg[#svg + 1] = string.format('<text x="%.1f" y="%.1f" font-size="%d" fill="%s" text-anchor="%s" font-family="Georgia, serif">%s</text>',
                        tx, baseY + (n - 1) * (size + 2), size, fill, anchor, esc(line))
                end
                local inkW = math.min(natural, allotted or natural)
                local inkL = justify == "CENTER" and (r.l + r.r - inkW) / 2 or justify == "RIGHT" and r.r - inkW or r.l
                texts[#texts + 1] = { region = region, l = inkL, r = inkL + inkW, b = r.b, t = r.t, text = strip(text) }
                -- Text that spills outside the panel that contains it.
                local node = region.parent
                while node and not isBackdropped(node) do node = node.parent end
                if node and node.kind ~= "Button" then
                    local pr = rect(node)
                    if inkL + inkW > pr.r + 1 or inkL < pr.l - 1 then finding("text outside its panel", region, r, strip(text)) end
                end
            end
        elseif region.kind == "Texture" or region.kind == "MaskTexture" then
            if region.kind == "Texture" and w > 0 and h > 0 then
                local layer = region.layer or "ARTWORK"
                if layer ~= "HIGHLIGHT" then
                    if region.colorTexture then
                        svg[#svg + 1] = string.format('<rect x="%.1f" y="%.1f" width="%.1f" height="%.1f" fill="%s"/>', x, y, w, h, rgb(region.colorTexture))
                    elseif region.texture and tostring(region.texture):find("WHITE8X8") then
                        local round = region.mask ~= nil
                        if round then svg[#svg + 1] = string.format('<ellipse cx="%.1f" cy="%.1f" rx="%.1f" ry="%.1f" fill="%s"/>', x + w / 2, y + h / 2, w / 2, h / 2, rgb(region.vertexColor or { 1, 1, 1, 1 }))
                        else svg[#svg + 1] = string.format('<rect x="%.1f" y="%.1f" width="%.1f" height="%.1f" fill="%s"/>', x, y, w, h, rgb(region.vertexColor or { 1, 1, 1, 1 })) end
                    elseif region.texture then
                        local path = tostring(region.texture)
                        if path:find("Quickslot") then
                            svg[#svg + 1] = string.format('<rect x="%.1f" y="%.1f" width="%.1f" height="%.1f" fill="none" stroke="#555" stroke-width="1"/>', x + w * 0.2, y + h * 0.2, w * 0.6, h * 0.6)
                        elseif path:find("Arrow") then
                            svg[#svg + 1] = string.format('<path d="M%.1f %.1f L%.1f %.1f L%.1f %.1f Z" fill="#ffd100"/>', x + w * 0.2, y + h * 0.75, x + w * 0.8, y + h * 0.75, x + w / 2, y + h * 0.25)
                        elseif path:find("native%-panel") then
                            -- drawn with the button
                        else
                            local round = region.mask ~= nil
                            if round then svg[#svg + 1] = string.format('<ellipse cx="%.1f" cy="%.1f" rx="%.1f" ry="%.1f" fill="%s"/>', x + w / 2, y + h / 2, w / 2, h / 2, iconColor(path))
                            else svg[#svg + 1] = string.format('<rect x="%.1f" y="%.1f" width="%.1f" height="%.1f" fill="%s" stroke="#000" stroke-width="0.5"/>', x, y, w, h, iconColor(path)) end
                        end
                    end
                end
            end
        else
            if region.backdrop then
                local fill = region.backdropColor or { 0.1, 0.1, 0.1, 0.95 }
                if region.backdrop.bgFile and tostring(region.backdrop.bgFile):find("DialogBox") then fill = { 0.08, 0.08, 0.1, 0.96 } end
                svg[#svg + 1] = string.format('<rect x="%.1f" y="%.1f" width="%.1f" height="%.1f" fill="%s" stroke="%s" stroke-width="%d"/>', x, y, w, h,
                    rgb(fill), rgb(region.backdropBorder or { 0.5, 0.5, 0.5, 1 }), (region.backdrop.edgeSize or 1) >= 10 and 3 or 1)
            end
            if region.template and region.template:find("UIPanelButton") then
                local enabled = region.enabled ~= false
                svg[#svg + 1] = string.format('<rect x="%.1f" y="%.1f" width="%.1f" height="%.1f" rx="3" fill="%s" stroke="#2a0000"/>', x, y, w, h, enabled and "#7a1a12" or "#4a3a38")
            elseif region.template == "UICheckButtonTemplate" then
                svg[#svg + 1] = string.format('<rect x="%.1f" y="%.1f" width="%.1f" height="%.1f" fill="#222" stroke="#999"/>', x + 3, y + 3, w - 6, h - 6)
                if region.checked then svg[#svg + 1] = string.format('<path d="M%.1f %.1f l5 5 l9 -11" stroke="#ffd100" stroke-width="3" fill="none"/>', x + 6, y + h / 2) end
            elseif region.template == "InputBoxTemplate" then
                svg[#svg + 1] = string.format('<rect x="%.1f" y="%.1f" width="%.1f" height="%.1f" fill="#111" stroke="#777"/>', x - 5, y + 3, w + 5, h - 6)
                local text = region.text or ""
                if text ~= "" then
                    local shown = fit(text, 12, w - 4)
                    svg[#svg + 1] = string.format('<text x="%.1f" y="%.1f" font-size="12" fill="#fff" font-family="Georgia, serif">%s</text>', x, y + h / 2 + 4, esc(shown))
                end
            elseif region.kind == "EditBox" then
                local text = region.text or ""
                for n, line in ipairs(wrapLines(text, 12, w)) do
                    if n > 12 then break end
                    svg[#svg + 1] = string.format('<text x="%.1f" y="%.1f" font-size="12" fill="#fff" font-family="Georgia, serif">%s</text>', x, y + 14 * n, esc(line))
                end
            elseif region.template == "UISliderTemplate" then
                svg[#svg + 1] = string.format('<rect x="%.1f" y="%.1f" width="%.1f" height="4" fill="#444"/>', x, y + h / 2 - 2, w)
                local low, high, value = region.low or 0, region.high or 1, region.value or 0
                local px = x + (high > low and (value - low) / (high - low) or 0) * w
                svg[#svg + 1] = string.format('<rect x="%.1f" y="%.1f" width="10" height="%.1f" fill="#bbb"/>', px - 5, y, h)
            end
        end
    end
    -- Overlapping text ink (two labels drawn over each other).
    for i = 1, #texts do for j = i + 1, #texts do
        local a, b = texts[i], texts[j]
        if a.region.parent ~= b.region and b.region.parent ~= a.region and a.l < b.r - 2 and b.l < a.r - 2 and a.b < b.t - 3 and b.b < a.t - 3 then
            finding("text overlaps text", a.region, a, a.text .. "  ×  " .. b.text)
        end
    end end
    -- Overlapping interactive controls that are siblings.
    local controls = {}
    for _, item in ipairs(items) do
        local k = item.region.kind
        if (k == "Button" or k == "CheckButton" or k == "EditBox" or k == "Slider") and item.region.mouseEnabled ~= false then controls[#controls + 1] = item end
    end
    for i = 1, #controls do for j = i + 1, #controls do
        local a, b = controls[i], controls[j]
        if a.region.parent == b.region.parent and a.r.l < b.r.r - 2 and b.r.l < a.r.r - 2 and a.r.b < b.r.t - 2 and b.r.b < a.r.t - 2 then
            local la = a.region.GetText and a.region:GetText() or a.region.kind
            local lb = b.region.GetText and b.region:GetText() or b.region.kind
            finding("controls overlap", a.region, a.r, tostring(la) .. "  ×  " .. tostring(lb))
        end
    end end
    -- Tooltip.
    if tip.visible and tip.owner then
        local o = rect(tip.owner)
        local width, height, lines = 0, 10, {}
        for _, line in ipairs(tip.lines) do
            local size = FONTS[line[2]][1]
            local wrapped = line[3] and wrapLines(line[1], size, 300) or { strip(line[1]) }
            for _, l in ipairs(wrapped) do lines[#lines + 1] = { l, size }; width = math.max(width, textWidth(l, size)); height = height + size + 4 end
        end
        width = width + 20
        local l, t
        if tip.anchor == "ANCHOR_RIGHT" then l, t = o.r, o.t elseif tip.anchor == "ANCHOR_LEFT" then l, t = o.l - width, o.t
        else l, t = (o.l + o.r) / 2 - width / 2, o.t + height + 2 end
        local tr = { l = l, r = l + width, t = t, b = t - height }
        svg[#svg + 1] = string.format('<rect x="%.1f" y="%.1f" width="%.1f" height="%.1f" fill="rgba(5,5,20,0.95)" stroke="#aaa"/>', l, SCREEN_H - t, width, height)
        local yy = SCREEN_H - t + 4
        for n, line in ipairs(lines) do
            yy = yy + line[2] + 4
            svg[#svg + 1] = string.format('<text x="%.1f" y="%.1f" font-size="%d" fill="%s" font-family="Georgia, serif">%s</text>', l + 10, yy - 3, line[2], n == 1 and "#fff" or "#c8c8c8", esc(line[1]))
        end
        include(tr)
    end
    if fx1 == math.huge then fx1, fy1, fx2, fy2 = 0, 0, SCREEN_W, SCREEN_H end
    local margin = 24
    fx1, fy1, fx2, fy2 = math.max(0, fx1 - margin), math.max(0, fy1 - margin), math.min(SCREEN_W, fx2 + margin), math.min(SCREEN_H, fy2 + margin)
    -- Number findings on the drawing.
    local listed = {}
    for n, f in ipairs(findings) do
        local r = f.r
        svg[#svg + 1] = string.format('<rect x="%.1f" y="%.1f" width="%.1f" height="%.1f" fill="none" stroke="#ff00ff" stroke-width="1.5" stroke-dasharray="3 2"/>', r.l, SCREEN_H - r.t, math.max(4, r.r - r.l), math.max(4, r.t - r.b))
        svg[#svg + 1] = string.format('<text x="%.1f" y="%.1f" font-size="10" fill="#ff66ff" font-family="Menlo, monospace">%d</text>', r.r + 1, SCREEN_H - r.t + 8, n)
        listed[#listed + 1] = string.format("  %d. [%s] %s", n, f.kind, f.text or "")
    end
    local vw, vh = fx2 - fx1, fy2 - fy1
    local header = 34
    local file = io.open(OUT .. "/" .. name .. ".svg", "w")
    file:write(string.format('<svg xmlns="http://www.w3.org/2000/svg" width="%d" height="%d" viewBox="%.1f %.1f %.1f %.1f">', math.floor(vw * 1.5), math.floor((vh + header) * 1.5), fx1, SCREEN_H - fy2 - header, vw, vh + header))
    file:write(string.format('<rect x="%.1f" y="%.1f" width="%.1f" height="%.1f" fill="#3b4a3a"/>', fx1, SCREEN_H - fy2 - header, vw, vh + header))
    file:write(string.format('<text x="%.1f" y="%.1f" font-size="11" fill="#fff" font-family="Menlo, monospace">%s — wireframe from layout code, not a game screenshot (%dx%d px)</text>', fx1 + 6, SCREEN_H - fy2 - header + 14, esc(name), math.floor(vw - 2 * margin), math.floor(vh - 2 * margin)))
    if note then file:write(string.format('<text x="%.1f" y="%.1f" font-size="10" fill="#ddd" font-family="Menlo, monospace">%s</text>', fx1 + 6, SCREEN_H - fy2 - header + 28, esc(note))) end
    file:write(table.concat(svg, "\n")); file:write("</svg>"); file:close()
    os.execute(string.format("rsvg-convert -o '%s/%s.png' '%s/%s.svg' 2>/dev/null", OUT, name, OUT, name))
    return { name = name, findings = listed, size = { math.floor(vw - 2 * margin), math.floor(vh - 2 * margin) } }
end

-- Scenarios -----------------------------------------------------------------------------------
local report = {}
local function run(name, setup, note)
    local IC, Stub, env, tip = fixture()
    local ok, focus = pcall(setup, IC, Stub, env, tip)
    if not ok then report[#report + 1] = { name = name, findings = { "  SCENARIO ERROR: " .. tostring(focus) }, size = { 0, 0 } }; return end
    report[#report + 1] = snapshot(Stub, tip, name, focus, note, env)
end
local function stanley(IC) IC.Library.Load("office-stanley") end
local function barButton(IC, predicate)
    for _, b in ipairs(IC.Bars.frames[1].actionButtons) do if b:IsShown() and predicate(b.node) then return b end end
end
local function wheelFocus(IC) local f = { IC.Wheel.frame }; for _, s in ipairs(IC.Wheel.fanSlots) do f[#f + 1] = s end; return f end
local function hover(frame) if frame then frame:Fire("OnEnter") end end

run("01-play-fresh", function(IC) return { IC.Bars.frames[1], IC.Launcher.button } end, "Fresh install: main bar and launcher")
run("02-play-stanley-hover-rp", function(IC)
    stanley(IC)
    local b = barButton(IC, function(n) return n.type == "group" and n.collection == "rp" end); hover(b)
    return { IC.Bars.frames[1] }
end, "Stanley loaded, pointing at the RP group on the main bar")
run("03-play-stanley-hover-pool", function(IC)
    stanley(IC); IC.Collections.Add("favorites", "pool:" .. IC.Personas.Pools()[1])
    local b = barButton(IC, function(n) return n.type == "pool" end); hover(b)
    return { IC.Bars.frames[1] }
end, "Stanley's Greetings pool pinned to favorites, pointing at it")
run("04-flyout-rp", function(IC)
    stanley(IC)
    local b = barButton(IC, function(n) return n.type == "group" and n.collection == "rp" end)
    IC.Flyout.Open(b, b.node); local level = IC.Flyout.levels[1]; hover(level.rows[1])
    return { IC.Bars.frames[1], IC.Flyout.levels[1], IC.Flyout.levels[2] }
end, "RP group flyout, pointing at the first pool (its lines open beside it)")
run("05-flyout-category", function(IC)
    local b = barButton(IC, function(n) return n.type == "group" and n.collection == "Social" end)
    IC.Flyout.Open(b, b.node); hover(IC.Flyout.levels[1].rows[2])
    return { IC.Bars.frames[1], IC.Flyout.levels[1] }
end, "Greetings & manners category flyout")
run("05b-flyout-switcher", function(IC)
    stanley(IC)
    local b = barButton(IC, function(n) return n.type == "group" and n.collection == "rp" end)
    IC.Flyout.Open(b, b.node); hover(IC.Flyout.levels[1].rows[1])
    return { IC.Bars.frames[1], IC.Flyout.levels[1], IC.Flyout.levels[2] }
end, "RP list, pointing at the character switcher")
run("06-menu-launcher", function(IC)
    stanley(IC); IC.Menu.Open(IC.Launcher.button)
    local level = IC.Flyout.levels[1]
    for _, row in ipairs(level.rows) do if row:IsShown() and row.node.collection == "rp" then hover(row) end end
    return { IC.Launcher.button, IC.Flyout.levels[1], IC.Flyout.levels[2], IC.Flyout.levels[3] }
end, "Launcher menu, pointing at the RP group")
local function wheelFocus(IC) return { IC.Wheel.frame, IC.Wheel.label, IC.Wheel.sub } end
local function wheelSlot(IC, test) for _, s in ipairs(IC.Wheel.slots) do if s:IsShown() and test(s.node) then return s end end end
run("07-wheel-root", function(IC) stanley(IC); IC.Wheel.Open(false); return wheelFocus(IC) end, "Radial wheel just opened (7 slices)")
run("08-wheel-hover-group", function(IC)
    stanley(IC); IC.Wheel.Open(false); IC.Wheel.SetHover(wheelSlot(IC, function(n) return n.collection == "Social" end))
    return wheelFocus(IC)
end, "Wheel: pointing at Greetings & manners (label outside the ring)")
run("09-wheel-rp", function(IC)
    stanley(IC); IC.Wheel.Open(false); IC.Wheel.Enter(wheelSlot(IC, function(n) return n.collection == "rp" end).node)
    IC.Wheel.zoomFrom = nil; IC.Wheel.frame:SetScale(1)
    IC.Wheel.SetHover(wheelSlot(IC, function(n) return n.id == "role:quotes" end))
    return wheelFocus(IC)
end, "Wheel: inside Stanley Hudson, pointing at Quote")
run("09b-wheel-category", function(IC)
    stanley(IC); IC.Wheel.Open(false); IC.Wheel.Enter(wheelSlot(IC, function(n) return n.collection == "Combat" end).node)
    IC.Wheel.zoomFrom = nil; IC.Wheel.frame:SetScale(1)
    IC.Wheel.SetHover(IC.Wheel.slots[3])
    return wheelFocus(IC)
end, "Wheel: inside Combat callouts (page 1), pointing at the third slice")
run("10-editmode", function(IC) IC.Bars.SetEditing(true); return { IC.Bars.inspector, IC.Bars.frames[1], IC.Launcher.button } end, "Move & edit bars")
run("11-editmode-launcher", function(IC) IC.Bars.SetEditing(true); IC.Bars.SelectLauncher(); return { IC.Bars.inspector } end, "Move & edit bars, launcher selected")
run("12-settings-lists", function(IC) IC.Editor.Open("Lists"); return { IC.Editor.frame } end, "Settings: Emotes & lists (favorites)")
run("13-settings-lists-emote", function(IC)
    IC.Editor.Open("Lists"); IC.Editor.list = "Social"; IC.Editor.selected = "emote:wave"; IC.Editor.RefreshLists(); return { IC.Editor.frame }
end, "Settings: Emotes & lists, Social list, wave selected")
run("14-settings-lists-rp", function(IC)
    stanley(IC); IC.Editor.Open("Lists"); IC.Editor.list = "favorites"; IC.Editor.RefreshLists()
    local p = IC.Editor.pages.Lists; p.category:Choose("rp"); IC.Editor.selected = "role:greetings"; IC.Editor.RefreshDetail()
    return { IC.Editor.frame }
end, "Settings: RP list with Stanley, library filtered to pools")
run("15-settings-lines", function(IC) stanley(IC); IC.Editor.Open("Lines"); return { IC.Editor.frame } end, "Settings: RP lines with Stanley")
run("16-settings-lines-messages", function(IC) stanley(IC); IC.Editor.Open("Lines"); IC.Editor.SetMessageView(true); return { IC.Editor.frame } end, "Settings: RP lines, individual messages")
run("17-settings-lists-advanced", function(IC)
    IC.Editor.Open("Lists"); local p = IC.Editor.pages.Lists; p.advanced:SetChecked(true); p.advanced:Click()
    IC.Editor.selected = "emote:wave"; IC.Editor.RefreshLists(); return { IC.Editor.frame }
end, "Settings: Emotes & lists with Advanced on")
run("18-settings-layout", function(IC) IC.Editor.Open("Layout"); return { IC.Editor.frame } end, "Settings: Layout & keys")
run("19-settings-profiles", function(IC) IC.Editor.Open("Profiles"); return { IC.Editor.frame } end, "Settings: Profiles")
run("20-icon-picker", function(IC) IC.Editor.Open("Lists"); IC.Editor.PickIcon(nil, function() end); return { IC.Editor.picker } end, "Icon picker")
run("21-character-dropdown", function(IC, Stub, env)
    stanley(IC); IC.Editor.Open("Lines"); IC.Editor.pages.Lines.character:Click(); return { IC.Editor.frame, env.InCharacterDropdownList }
end, "RP character dropdown open")
run("22-options-panel", function(IC, Stub, env) Stub.settingsPanel:Show(); Stub.settingsPanel:SetPoint("TOPLEFT", env.UIParent, "TOPLEFT", 300, -200); Stub.settingsPanel:Fire("OnShow"); return { Stub.settingsPanel } end, "Options > AddOns > In Character")
run("23-play-separate-bars", function(IC)
    stanley(IC); IC.Bars.SetMode("separate"); IC.Bars.Refresh()
    local f = {}; for _, frame in ipairs(IC.Bars.frames) do f[#f + 1] = frame end; return f
end, "Layout: separate bars")
run("24-play-labels", function(IC) stanley(IC); IC.Layout().bars[1].labels = true; IC.Bars.Refresh(); return { IC.Bars.frames[1] } end, "Main bar with names under icons")

local out = io.open(OUT .. "/report.txt", "w")
for _, entry in ipairs(report) do
    out:write(string.format("%s  (%dx%d)\n", entry.name, entry.size[1], entry.size[2]))
    for _, line in ipairs(entry.findings) do out:write(line .. "\n") end
    if #entry.findings == 0 then out:write("  (no mechanical findings)\n") end
end
out:close()
print("wrote " .. #report .. " wireframes and report.txt to " .. OUT)
