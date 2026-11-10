-- Geometry preview generated from the same pure models used by the installed addon.
-- No game frames, emote assets, interaction simulation, or claims about in-game appearance.
local IC = {}
for _, file in ipairs({ 'Models/Bar.lua', 'Models/Menu.lua', 'Services/WheelModel.lua' }) do assert(loadfile('InCharacter/' .. file))('InCharacter', IC) end
local function output(s) io.write(s, '\n') end
local function rect(x, y, w, h, color) output(string.format('<rect x="%.2f" y="%.2f" width="%.2f" height="%.2f" fill="%s" stroke="#8d8060"/>', x, y, w, h, color or '#302c24')) end
local function text(x, y, s, size) output(string.format('<text x="%.2f" y="%.2f" fill="#eadfbe" font-family="sans-serif" font-size="%d">%s</text>', x, y, size or 13, s)) end
output('<svg xmlns="http://www.w3.org/2000/svg" width="1060" height="760" viewBox="0 0 1060 760">')
rect(0, 0, 1060, 760, '#151412'); text(24, 28, 'In Character 0.14.0 — layout geometry at 1 UI unit per pixel', 18)
text(24, 51, 'Model output, not a screenshot. Blizzard fonts, textures and input still require an in-game test.', 12)
local nodes = {}; for i = 1, 10 do nodes[i] = { segment = 1 } end
for i, size in ipairs({ 28, 24, 12 }) do
    local g = IC.BarModel.Geometry({ size = size }, nodes, 1060, 760)
    local y = 90 + (i - 1) * 60; text(24, y, '10 buttons: ' .. g.width .. ' x ' .. g.height .. ' units')
    for n, p in ipairs(g.positions) do rect(24 + p.x, y + 10 + p.y, size, size); text(26 + p.x, y + 10 + p.y + size - 3, tostring(n), math.min(12, size - 2)) end
end
local fit = IC.BarModel.Geometry({ size = 24, fitWidth = 130, fitHeight = 60 }, nodes)
text(420, 90, 'Drag-fit area: 130 x 60; content hugs buttons')
rect(420, 100, 130, 60, '#20251e'); for _, p in ipairs(fit.positions) do rect(420 + p.x, 100 + p.y, fit.size, fit.size) end
local menu = IC.MenuModel.Geometry(120, true)
text(700, 90, '120 messages: ' .. menu.width .. ' x ' .. menu.height .. ', one scrolling column')
rect(700, 100, menu.width, menu.height)
for i = 1, menu.rows do text(726, 100 + (i - 1) * 20 + 16, 'Message ' .. i); rect(703, 102 + (i - 1) * 20, 18, 18, '#49412f') end
text(790, 100 + menu.height - 4, '1–20 / 120   >', 11)
local g = IC.WheelModel.Geometry(7, IC.WheelModel.ICON)
local cx, cy = 250, 500
text(24, 300, 'Ring: 7 slices, ' .. g.size .. ' units; a sub-level replaces the ring (no fans)')
for i = 1, 7 do
    local x, y, angle = IC.WheelModel.Position(i, 7, g.radius)
    rect(cx + x - g.icon / 2, cy - y - g.icon / 2, g.icon, g.icon)
    if i == 3 then
        local lx, ly, justify = IC.WheelModel.LabelPoint(angle, g)
        text(cx + lx, cy - ly + 4, 'label for slice 3 (' .. justify .. ')', 11)
    end
end
text(cx - 20, cy + 4, 'back', 11)
text(24, 724, 'Centre = back / close. Pointing names the slice outside the ring; only a click or key release sends.')
output('</svg>')
