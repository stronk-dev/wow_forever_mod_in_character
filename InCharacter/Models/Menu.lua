local _, IC = ...
IC.MenuModel = {}
local M = IC.MenuModel
local WIDTH, LINE_WIDTH, MAX_ROWS, ROW, PAD = 168, 300, 14, 20, 2
function M.Geometry(count, lines, screenWidth, screenHeight)
    local width = math.min(lines and LINE_WIDTH or WIDTH, math.max(80, (screenWidth or 1920) - 24))
    local limit = math.max(1, math.min(MAX_ROWS, math.floor(((screenHeight or 1080) - 44) / ROW)))
    local rows = math.max(1, math.min(count, limit))
    local footer = count > rows and 16 or 0
    return { rows = rows, columns = 1, rowWidth = width, width = width + PAD * 2, height = rows * ROW + PAD * 2 + footer, footer = footer }
end
