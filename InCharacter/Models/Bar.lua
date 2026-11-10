local _, IC = ...
-- Pure, bounded layout. Bars hug their icons; a bar longer than the screen pages.
IC.BarModel = { GAP = 2, SEGMENT = 6, LABEL_W = 56 }
local M = IC.BarModel
function M.Size(c) return math.max(12, math.min(64, math.floor(tonumber(c.size) or 28))) end
function M.Geometry(c, nodes, screenWidth, screenHeight)
    local size, label = M.Size(c), c.labels and 12 or 0
    local width = math.max(size, (screenWidth or 1920) - 80)
    local height = math.max(size + label, (screenHeight or 1080) - 80)
    local vertical = c.vertical == true
    local alongLimit, acrossLimit = vertical and height or width, vertical and width or height
    -- With names on, each cell is wide enough for a short name under the icon.
    local cell = c.labels and math.max(size, M.LABEL_W) or size
    local inset = (cell - size) / 2
    local alongCell, acrossCell = vertical and (size + label) or cell, vertical and cell or (size + label)
    local perRow = math.floor(tonumber(c.perRow) or 0); if perRow <= 0 then perRow = math.huge end
    local pages = { { positions = {}, width = 0, height = 0 } }
    local along, across, inLine = 0, 0, 0
    for index, node in ipairs(nodes) do
        local gap = index > 1 and node.segment ~= nodes[index - 1].segment and M.SEGMENT or M.GAP
        local nextAlong = inLine > 0 and along + alongCell + gap or 0
        if inLine >= perRow or nextAlong + alongCell > alongLimit then
            along, inLine = 0, 0; across = across + acrossCell + M.GAP
        else along = nextAlong end
        if across + acrossCell > acrossLimit then
            pages[#pages + 1] = { positions = {}, width = 0, height = 0 }
            along, across, inLine = 0, 0, 0
        end
        local page = pages[#pages]
        local x, y = vertical and across or along, vertical and along or across
        page.positions[#page.positions + 1] = { x = x + inset, y = y, index = index }
        page.width = math.max(page.width, x + (vertical and cell or alongCell))
        page.height = math.max(page.height, y + size + label)
        inLine = inLine + 1
    end
    local page = math.max(1, math.min(#pages, math.floor(tonumber(c.page) or 1)))
    local g = pages[page]
    g.width, g.height = math.max(size, g.width), math.max(size, g.height)
    g.size, g.page, g.pages = size, page, #pages
    return g
end
-- The resize corner: how many icons fit in one row (one column when vertical) of the given
-- length in pixels. 0 means "all in one line", the default.
function M.PerRowFor(c, count, length)
    local size, label = M.Size(c), c.labels and 12 or 0
    local cell = c.vertical and (size + label) or (c.labels and math.max(size, M.LABEL_W) or size)
    local n = math.max(1, math.floor(((tonumber(length) or 0) + M.GAP) / (cell + M.GAP)))
    return n >= (count or 0) and 0 or n
end
