local _, IC = ...
-- Pure flyout geometry: one bounded column. Width follows the widest name when the client can
-- measure it (between MIN and the cap), so short lists stay narrow and names are not cut.
IC.MenuModel = {}
local M = IC.MenuModel
local WIDTH, LINE_WIDTH, MAX_ROWS, ROW, PAD = 168, 300, 20, 20, 2
local MIN, CAP, LINE_CAP, CHROME = 110, 240, 360, 18 + 5 + 14 + 4
function M.Geometry(count, lines, screenWidth, screenHeight, textWidth)
    local width = lines and LINE_WIDTH or WIDTH
    if textWidth and textWidth > 0 then width = math.max(MIN, math.min(lines and LINE_CAP or CAP, math.ceil(textWidth) + CHROME)) end
    width = math.min(width, math.max(80, (screenWidth or 1920) - 24))
    local limit = math.max(1, math.min(MAX_ROWS, math.floor(((screenHeight or 1080) - 44) / ROW)))
    local rows = math.max(1, math.min(count, limit))
    local footer = count > rows and 16 or 0
    return { rows = rows, columns = 1, rowWidth = width, width = width + PAD * 2, height = rows * ROW + PAD * 2 + footer, footer = footer }
end
