local _, IC = ...
-- Pure, bounded layout. A fit rectangle is a budget; normal bars hug their visible icons.
IC.BarModel = { GAP = 2, SEGMENT = 6 }
local M = IC.BarModel
function M.Size(c) return math.max(12, math.min(64, math.floor(tonumber(c.size) or 28))) end
function M.Geometry(c, nodes, screenWidth, screenHeight)
    local size, label = M.Size(c), c.labels and 12 or 0
    local width = math.max(size, math.min(tonumber(c.fitWidth) or math.huge, (screenWidth or 1920) - 32))
    local height = math.max(size + label, math.min(tonumber(c.fitHeight) or math.huge, (screenHeight or 1080) - 48))
    local vertical = c.vertical == true
    local alongLimit, acrossLimit = vertical and height or width, vertical and width or height
    local alongCell, acrossCell = size + (vertical and label or 0), size + (vertical and 0 or label)
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
        page.positions[#page.positions + 1] = { x = x, y = y, index = index }
        page.width = math.max(page.width, x + size)
        page.height = math.max(page.height, y + size + label)
        inLine = inLine + 1
    end
    local page = math.max(1, math.min(#pages, math.floor(tonumber(c.page) or 1)))
    local g = pages[page]
    g.width, g.height = math.max(size, g.width), math.max(size, g.height)
    g.size, g.page, g.pages = size, page, #pages
    return g
end
