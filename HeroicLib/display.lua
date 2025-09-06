-- HeroicLib/display.lua
-- Display module for turtle information and progress bars

local movement = require("HeroicLib/movement")
local fuelManager = require("HeroicLib/fuel")

local display = {}

-- Store progress bars
local progressBars = {}

-- Check for rednet capability
function display.checkRednetCapability()
    local modemSide = nil
    for _, side in pairs({"left", "right", "top", "bottom", "front", "back"}) do
        if peripheral.getType(side) == "modem" then
            modemSide = side
            break
        end
    end
    
    if modemSide then
        local modem = peripheral.wrap(modemSide)
        -- Check if it's a wireless modem (has wireless capability)
        if modem.isWireless and modem.isWireless() then
            return true, modemSide, "wireless"
        else
            return true, modemSide, "wired"
        end
    end
    
    return false, nil, "none"
end

-- Display turtle information
function display.showTurtleInfo()
    term.clear()
    term.setCursorPos(1, 1)

    -- Get rednet capability information
    local hasRednet, modemSide, modemType = display.checkRednetCapability()
    local rednetStatus = "No"
    if hasRednet then
        rednetStatus = "Yes (" .. modemType .. " modem on " .. modemSide .. ")"
    end
    
    -- Convert direction number to string
    local direction = turtle.getDirection()
    local directionString = "Unknown"
    if direction == 0 then directionString = "North"
    elseif direction == 1 then directionString = "East"
    elseif direction == 2 then directionString = "South"
    elseif direction == 3 then directionString = "West"
    end

    print("===== Turtle Status =====")
    print(fuelManager.getFuelString())
    print("Direction: " .. directionString)
    print("Selected Slot: " .. turtle.getSelectedSlot())
    print("Rednet Capable: " .. rednetStatus)
    print("========================")
    
    return true
end

-- Create a new progress bar
function display.createProgressBar(id, y, maxValue, title)
    if progressBars[id] then
        return false -- Progress bar with this ID already exists
    end
    
    progressBars[id] = {
        y = y or 10, -- Default position
        value = 0,
        maxValue = maxValue or 100,
        title = title or id,
        width = 50 -- Default width
    }
    
    return true
end

-- Update progress bar value
function display.updateProgress(id, value)
    if not progressBars[id] then
        return false
    end
    
    progressBars[id].value = math.min(value, progressBars[id].maxValue)
    display.drawProgressBar(id)
    return true
end

-- Draw a progress bar
function display.drawProgressBar(id)
    local bar = progressBars[id]
    if not bar then
        return false
    end
    
    local termWidth, _ = term.getSize()
    local barWidth = math.min(bar.width, termWidth - 2)
    
    local filled = math.floor((bar.value / bar.maxValue) * barWidth)
    local percentage = math.floor((bar.value / bar.maxValue) * 100)
    
    term.setCursorPos(1, bar.y)
    term.clearLine()
    term.write(bar.title .. ": " .. percentage .. "%")
    
    term.setCursorPos(1, bar.y + 1)
    term.write("[")
    term.write(string.rep("=", filled))
    term.write(string.rep(" ", barWidth - filled))
    term.write("]")
    
    return true
end

-- Draw all progress bars
function display.drawAllProgressBars()
    for id, _ in pairs(progressBars) do
        display.drawProgressBar(id)
    end
    return true
end

-- Remove a progress bar
function display.removeProgressBar(id)
    if progressBars[id] then
        progressBars[id] = nil
        return true
    end
    return false
end

-- Update the display
function display.update()
    display.showTurtleInfo()
    display.drawAllProgressBars()
    return true
end

return display