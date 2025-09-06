-- Simple cubic quarry script using HeroicLib
-- Based on concepts from https://github.com/Equbuxu/mine
local display = require("HeroicLib.display")
local fuel = require("HeroicLib.fuel")
local storage = require("HeroicLib.storage")
require("HeroicLib.turtle")

-- Constants
local REFUEL_THRESHOLD = 100  -- Refuel when below this level
local CHEST_SLOT = 1          -- Where to keep chests
local FUEL_SLOT = 2           -- Where to keep fuel
local BLOCK_SLOT = 3          -- Where to keep building blocks (for plugging fluids)
local MISC_SLOT = 4           -- First slot for storing mined items

-- Direction constants are already defined in turtle.lua
-- Forward, Back, Left, Right, Up, Down

-- Configuration
local config = {
    plugFluidsOnly = true,    -- Only place blocks when encountering fluids
    maxDigRadius = 20,        -- Maximum size of the quarry in any dimension
}

-- Utility functions
local function printInfo(message)
    term.setTextColor(colors.lime)
    print(message)
    term.setTextColor(colors.white)
end

local function printWarning(message)
    term.setTextColor(colors.yellow)
    print("[WARNING] " .. message)
    term.setTextColor(colors.white)
end

local function printError(message)
    term.setTextColor(colors.red)
    print("[ERROR] " .. message)
    term.setTextColor(colors.white)
end

-- Check if the block is a fluid (lava or water)
local function isFluid(inspectFunction)
    local success, data = inspectFunction()
    if success and (data.name == "minecraft:lava" or data.name == "minecraft:water") then
        return true
    end
    return false
end

-- Helper to execute a function with a specific slot selected
local function execWithSlot(func, slot)
    local oldSlot = turtle.getSelectedSlot()
    turtle.select(slot)
    local result = func()
    turtle.select(oldSlot)
    return result
end

-- Drop off items into a chest below
local function dropInventory()
    local oldSlot = turtle.getSelectedSlot()
    local dropped = true
    
    for i = MISC_SLOT, 16 do
        if turtle.getItemCount(i) > 0 then
            turtle.select(i)
            dropped = turtle.dropDown() and dropped
        end
    end
    
    turtle.select(oldSlot)
    return dropped
end

-- Check and refuel if needed
local function checkFuel(distance)
    local fuelLevel = fuel.getCurrentFuel()
    
    if fuelLevel < REFUEL_THRESHOLD or (distance and fuelLevel < distance + 50) then
        printInfo("Fuel low, attempting to refuel...")
        return fuel.refuelToLevel(distance and distance + 100 or REFUEL_THRESHOLD + 100)
    end
    
    return true
end

-- Function to generate a cube pattern of blocks to mine
local function generateCube(width, height, depth)
    local blocks = {}
    local counter = 1
    
    for y = 0, height - 1 do
        for x = 0, width - 1 do
            for z = 0, depth - 1 do
                blocks[counter] = {x = x, y = -y, z = z}  -- Negative y to dig down
                counter = counter + 1
            end
        end
    end
    
    return blocks
end

-- Handle digging in a specific direction
local function digInDirection(direction)
    if direction == Down then
        if isFluid(turtle.inspectDown) and config.plugFluidsOnly then
            execWithSlot(turtle.placeDown, BLOCK_SLOT)
        end
        return turtle.digDown()
    elseif direction == Up then
        if isFluid(turtle.inspectUp) and config.plugFluidsOnly then
            execWithSlot(turtle.placeUp, BLOCK_SLOT)
        end
        return turtle.digUp()
    else
        -- For horizontal directions, we just dig forward
        if isFluid(turtle.inspect) and config.plugFluidsOnly then
            execWithSlot(turtle.place, BLOCK_SLOT)
        end
        return turtle.dig()
    end
end

-- Move to a position with digging if needed
local function moveToPosition(target)
    -- First handle vertical movement
    while target.y > 0 do
        if not turtle.up() then
            digInDirection(Up)
            if not turtle.up() then
                printWarning("Cannot move up")
                return false
            end
        end
        target.y = target.y - 1
    end
    
    while target.y < 0 do
        if not turtle.down() then
            digInDirection(Down)
            if not turtle.down() then
                printWarning("Cannot move down")
                return false
            end
        end
        target.y = target.y + 1
    end
    
    -- Handle x and z movement in a smarter way
    -- First determine which direction to face based on target coordinates
    local direction
    
    -- First move in x direction
    if target.x > 0 then
        direction = Right
    elseif target.x < 0 then
        direction = Left
    end
    
    if direction then
        -- Turn to face the correct direction
        turtle.move(direction, 0)
        
        -- Move the required number of blocks
        local steps = math.abs(target.x)
        for i = 1, steps do
            if not turtle.forward() then
                -- If blocked, try to dig
                turtle.dig()
                if not turtle.forward() then
                    printWarning("Cannot move forward (x direction)")
                    return false
                end
            end
        end
    end
    
    -- Then move in z direction
    if target.z > 0 then
        direction = Forward
    elseif target.z < 0 then
        direction = Back
    end
    
    if direction then
        -- Turn to face the correct direction
        turtle.move(direction, 0)
        
        -- Move the required number of blocks
        local steps = math.abs(target.z)
        for i = 1, steps do
            if not turtle.forward() then
                -- If blocked, try to dig
                turtle.dig()
                if not turtle.forward() then
                    printWarning("Cannot move forward (z direction)")
                    return false
                end
            end
        end
    end
    
    target.x = 0
    target.z = 0
    
    return true
end

-- Sort inventory to consolidate items
local function sortInventory()
    -- Ensure all items of same type are stacked together
    for i = MISC_SLOT, 16 do
        if turtle.getItemCount(i) > 0 then
            local detail = turtle.getItemDetail(i)
            if detail then
                for j = i + 1, 16 do
                    if turtle.getItemCount(j) > 0 then
                        local otherDetail = turtle.getItemDetail(j)
                        if otherDetail and otherDetail.name == detail.name then
                            turtle.select(j)
                            turtle.transferTo(i)
                        end
                    end
                end
            end
        end
    end
    
    -- Special handling for fuel and building materials
    for i = MISC_SLOT, 16 do
        if turtle.getItemCount(i) > 0 then
            local detail = turtle.getItemDetail(i)
            
            -- Move coal to fuel slot if empty
            if detail and detail.name == "minecraft:coal" and turtle.getItemCount(FUEL_SLOT) == 0 then
                turtle.select(i)
                turtle.transferTo(FUEL_SLOT)
            end
            
            -- Move stone/cobblestone to block slot if empty
            if detail and (detail.name == "minecraft:cobblestone" or detail.name == "minecraft:stone") 
               and turtle.getItemCount(BLOCK_SLOT) == 0 then
                turtle.select(i)
                turtle.transferTo(BLOCK_SLOT)
            end
        end
    end
    
    turtle.select(MISC_SLOT)
end

-- Function to place a chest and drop items
local function dropOffItems()
    if not turtle.getItemDetail(16) then
        return true  -- Inventory not full
    end
    
    -- Try to place chest
    if turtle.getItemCount(CHEST_SLOT) == 0 then
        printWarning("Out of chests! Please add a chest to slot " .. CHEST_SLOT)
        return false
    end
    
    -- Turn around to place chest
    turtle.move(Back, 0)
    
    execWithSlot(turtle.place, CHEST_SLOT)
    
    -- Drop items
    for i = MISC_SLOT, 16 do
        if turtle.getItemCount(i) > 0 then
            turtle.select(i)
            if not turtle.drop() then
                printWarning("Couldn't drop items into chest")
                turtle.move(Forward, 0)  -- Turn back
                return false
            end
        end
    end
    
    -- Turn back
    turtle.move(Forward, 0)
    
    return true
end

-- Main quarry function
local function quarry(width, height, depth)
    -- Validate input
    if width > config.maxDigRadius or height > config.maxDigRadius or depth > config.maxDigRadius then
        printError("Dimensions too large! Maximum allowed is " .. config.maxDigRadius)
        return false
    end
    
    if width < 1 or height < 1 or depth < 1 then
        printError("Dimensions must be greater than 0")
        return false
    end
    
    -- Store the starting position
    local startPos = {x = 0, y = 0, z = 0}
    
    -- Calculate total blocks to mine
    local totalBlocks = width * height * depth
    
    -- Create progress bar
    display.createProgressBar("quarry", 10, totalBlocks, "Quarry Progress")
    
    -- Calculate return distance for fuel check
    local returnDistance = math.abs(width) + math.abs(height) + math.abs(depth)
    
    -- Check if we have enough fuel
    if not checkFuel(returnDistance + totalBlocks) then
        printError("Not enough fuel for the operation")
        return false
    end
    
    -- Generate the pattern
    printInfo("Generating mining pattern...")
    local blocks = generateCube(width, height, depth)
    
    -- Start mining
    printInfo("Starting quarry operation...")
    printInfo("Size: " .. width .. "x" .. height .. "x" .. depth .. " blocks (" .. totalBlocks .. " total)")
    
    -- Mine each block
    local blocksCompleted = 0
    for i, block in ipairs(blocks) do
        -- Check inventory and fuel every 10 blocks
        if i % 10 == 0 then
            sortInventory()
            checkFuel(returnDistance)
            
            -- Check if inventory is full
            if turtle.getItemCount(16) > 0 then
                printInfo("Inventory full, dropping off items...")
                dropOffItems()
            end
        end
        
        -- Move to position
        local relativePos = {x = block.x, y = block.y, z = block.z}
        if not moveToPosition(relativePos) then
            printWarning("Failed to move to position: " .. block.x .. "," .. block.y .. "," .. block.z)
            -- Try to continue with next block
        else
            -- Successfully moved to position, update progress
            blocksCompleted = blocksCompleted + 1
            display.updateProgress("quarry", blocksCompleted)
        end
        
        -- Yield to prevent "Too long without yielding" error
        if i % 50 == 0 then
            os.sleep(0)
        end
    end
    
    -- Return to start
    printInfo("Returning to starting position...")
    moveToPosition(startPos)
    
    -- Final inventory check
    if turtle.getItemCount(16) > 0 then
        printInfo("Dropping off final items...")
        dropOffItems()
    end
    
    printInfo("Quarry operation complete!")
    display.updateProgress("quarry", totalBlocks)
    
    return true
end

-- Function to show help information
local function showHelp()
    term.clear()
    term.setCursorPos(1, 1)
    
    printInfo("===== Simple Quarry Program =====")
    print("Usage: quarry <width> <height> <depth>")
    print("")
    print("This program will dig a rectangular hole of")
    print("the specified dimensions.")
    print("")
    print("Required items:")
    print("- Slot " .. CHEST_SLOT .. ": Chests for storage")
    print("- Slot " .. FUEL_SLOT .. ": Fuel (coal, etc.)")
    print("- Slot " .. BLOCK_SLOT .. ": Blocks (cobblestone, etc.) for handling fluids")
    print("")
    print("The turtle will start at the current position")
    print("and dig in the positive x, negative y, and positive z")
    print("directions (right, down, forward).")
    print("")
    print("Commands:")
    print("  quarry help - Show this help message")
    print("  quarry 5 5 5 - Dig a 5x5x5 quarry")
    print("===================================")
end

-- Main function
local function main(...)
    local args = {...}
    
    if #args == 0 or args[1] == "help" then
        showHelp()
        return
    end
    
    -- Parse dimensions
    local width = tonumber(args[1])
    local height = tonumber(args[2])
    local depth = tonumber(args[3])
    
    if not width or not height or not depth then
        printError("Invalid dimensions")
        showHelp()
        return
    end
    
    -- Show turtle status
    display.showTurtleInfo()
    
    -- Start the quarry
    quarry(width, height, depth)
end

-- Run the program
main(...)
