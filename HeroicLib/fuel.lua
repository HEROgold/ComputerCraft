-- HeroicLib/fuel.lua
-- A comprehensive fuel manager for ComputerCraft turtles

local fuelManager = {}

-- Table of known fuels and their fuel values
fuelManager.fuelValues = {
    -- gets filled dynamically by scanning inventory
}

-- Check current fuel level
function fuelManager.getCurrentFuel()
    return turtle.getFuelLevel()
end

-- Check maximum fuel capacity
function fuelManager.getMaxFuel()
    return turtle.getFuelLimit()
end

-- Get fuel percentage as a number (0-100)
function fuelManager.getFuelPercentage()
    local current = fuelManager.getCurrentFuel()
    local max = fuelManager.getMaxFuel()
    return math.floor((current / max) * 100)
end

-- Format fuel info as a string
function fuelManager.getFuelString()
    local current = fuelManager.getCurrentFuel()
    local max = fuelManager.getMaxFuel()
    local percent = fuelManager.getFuelPercentage()
    return string.format("Fuel: %d/%d (%d%%)", current, max, percent)
end

-- Calculate fuel needed for operations
function fuelManager.calculateFuelNeeded(moves, digs, places)
    moves = moves or 0
    digs = digs or 0
    places = places or 0
    
    -- In standard ComputerCraft, moves cost 1 fuel, digging and placing are free
    return moves
end

-- Check if we have enough fuel for planned operations
function fuelManager.hasEnoughFuel(moves, digs, places)
    local fuelNeeded = fuelManager.calculateFuelNeeded(moves, digs, places)
    return fuelManager.getCurrentFuel() >= fuelNeeded
end

-- Identify fuel in inventory and its value
function fuelManager.scanInventory()
    local fuelItems = {}
    
    for slot = 1, 16 do
        turtle.select(slot)
        local item = turtle.getItemDetail()
        
        if item then
            -- Try to get fuel value by testing with a small refuel
            if turtle.refuel(0) then
                -- If successful, this is fuel
                local startFuel = turtle.getFuelLevel()
                turtle.refuel(1)
                local fuelValue = turtle.getFuelLevel() - startFuel
                
                -- Store info about this fuel
                fuelItems[slot] = {
                    name = item.name,
                    count = item.count,
                    fuelPerItem = fuelValue
                }
                
                -- Add to known fuels if not already known
                if not fuelManager.fuelValues[item.name] then
                    fuelManager.fuelValues[item.name] = fuelValue
                end
            end
        end
    end
    
    return fuelItems
end

-- Refuel to meet a specific requirement
function fuelManager.refuelToLevel(targetLevel)
    local currentFuel = fuelManager.getCurrentFuel()
    
    if currentFuel >= targetLevel then
        return true -- Already have enough fuel
    end
    
    local fuelNeeded = targetLevel - currentFuel
    local fuelItems = fuelManager.scanInventory()
    
    -- Sort fuel items by efficiency (lowest value per item first)
    local sortedSlots = {}
    for slot, data in pairs(fuelItems) do
        table.insert(sortedSlots, slot)
    end
    
    table.sort(sortedSlots, function(a, b)
        return fuelItems[a].fuelPerItem < fuelItems[b].fuelPerItem
    end)
    
    -- Try to refuel with the minimum amount needed
    for _, slot in ipairs(sortedSlots) do
        local data = fuelItems[slot]
        local fuelPerItem = data.fuelPerItem
        
        turtle.select(slot)
        
        if fuelPerItem > 0 then
            local itemsToUse = math.ceil(fuelNeeded / fuelPerItem)
            itemsToUse = math.min(itemsToUse, data.count)
            
            turtle.refuel(itemsToUse)
            currentFuel = turtle.getFuelLevel()
            fuelNeeded = targetLevel - currentFuel
            
            if fuelNeeded <= 0 then
                return true -- Refueled successfully
            end
        end
    end
    
    return false -- Couldn't reach target fuel level
end

-- Refuel for specific operations
function fuelManager.refuelForOperations(moves, digs, places)
    local fuelNeeded = fuelManager.calculateFuelNeeded(moves, digs, places)
    return fuelManager.refuelToLevel(fuelManager.getCurrentFuel() + fuelNeeded)
end

return fuelManager