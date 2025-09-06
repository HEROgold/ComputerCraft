-- Efficient Mining Turtle Script
-- This script makes a turtle mine in an efficient knight's move pattern
-- and handles fuel management, inventory management, and ore detection

-- Globals and Constants
local FUEL_THRESHOLD = 100 -- Minimum fuel level to continue mining
local INVENTORY_THRESHOLD = 14 -- Return to chest when inventory has this many slots filled
local HOME = {x = 0, y = 0, z = 0, facing = 0} -- Home position (will be set on start)
local MAX_DEPTH = 128 -- Maximum depth to mine to
local BEDROCK_LAYER = -64 -- Approximate level of bedrock
local SIZE = 1 -- Size of the mining area (will be set by user input)
local SAVED_DATA_FILE = "mining_state.data" -- File to save state data
local isRunning = true -- Control flag for the mining operation

-- Current state
local pos = {x = 0, y = 0, z = 0, facing = 0} -- Current position
local chestContents = {} -- Contents of the chest above
local miningGrid = {} -- Grid of positions to mine
local currentGridIndex = 1 -- Current position in the mining grid
local returnToChest = false -- Flag to indicate if we should return to chest
local miningInProgress = false -- Flag to indicate if mining is in progress

-- Direction constants
local DIRECTIONS = {
    NORTH = 0,
    EAST = 1,
    SOUTH = 2,
    WEST = 3
}

-- Helper Functions
local function saveState()
    local data = {
        pos = pos,
        HOME = HOME,
        SIZE = SIZE,
        miningGrid = miningGrid,
        currentGridIndex = currentGridIndex,
        miningInProgress = miningInProgress
    }
    
    local f = fs.open(SAVED_DATA_FILE, "w")
    f.write(textutils.serialize(data))
    f.close()
    print("Mining state saved")
end

local function loadState()
    if not fs.exists(SAVED_DATA_FILE) then
        return false
    end
    
    local f = fs.open(SAVED_DATA_FILE, "r")
    local data = textutils.unserialize(f.readAll())
    f.close()
    
    if data then
        pos = data.pos
        HOME = data.HOME
        SIZE = data.SIZE
        miningGrid = data.miningGrid
        currentGridIndex = data.currentGridIndex
        miningInProgress = data.miningInProgress
        return true
    end
    
    return false
end

local function clearState()
    if fs.exists(SAVED_DATA_FILE) then
        fs.delete(SAVED_DATA_FILE)
        print("Mining state cleared")
        return true
    end
    return false
end

-- Check if a block is a chest
local function isChest(blockName)
    if not blockName then return false end
    return string.find(blockName, "chest") ~= nil
end

-- Movement Functions with position tracking
local function turnLeft()
    turtle.turnLeft()
    pos.facing = (pos.facing - 1) % 4
end

local function turnRight()
    turtle.turnRight()
    pos.facing = (pos.facing + 1) % 4
end

local function turnToFace(direction)
    while pos.facing ~= direction do
        turnRight()
    end
end

local function moveForward()
    if turtle.forward() then
        if pos.facing == DIRECTIONS.NORTH then
            pos.z = pos.z - 1
        elseif pos.facing == DIRECTIONS.EAST then
            pos.x = pos.x + 1
        elseif pos.facing == DIRECTIONS.SOUTH then
            pos.z = pos.z + 1
        elseif pos.facing == DIRECTIONS.WEST then
            pos.x = pos.x - 1
        end
        return true
    end
    return false
end

local function moveUp()
    if turtle.up() then
        pos.y = pos.y + 1
        return true
    end
    return false
end

local function moveDown()
    if turtle.down() then
        pos.y = pos.y - 1
        return true
    end
    return false
end

-- Inventory Management
local function countFilledSlots()
    local count = 0
    for i = 1, 16 do
        if turtle.getItemCount(i) > 0 then
            count = count + 1
        end
    end
    return count
end

local function depositItems()
    print("Depositing items into chest...")
    for i = 1, 16 do
        turtle.select(i)
        if turtle.getItemCount() > 0 then
            -- Attempt to place items in chest above
            turtle.dropUp()
        end
    end
    turtle.select(1)
end

-- Fuel Management
local function refuelFromInventory()
    local currentFuel = turtle.getFuelLevel()
    
    if currentFuel == "unlimited" then
        return true
    end
    
    -- First try to use coal/charcoal from inventory
    for i = 1, 16 do
        turtle.select(i)
        if turtle.getItemCount() > 0 then
            local itemDetail = turtle.getItemDetail()
            if itemDetail and (itemDetail.name == "minecraft:coal" or 
                               itemDetail.name == "minecraft:charcoal" or
                               string.find(itemDetail.name, "coal")) then
                print("Refueling with " .. itemDetail.name)
                if turtle.refuel(64) then  -- Try to refuel with entire stack if available
                    print("Refueled to " .. turtle.getFuelLevel())
                    turtle.select(1)
                    return true
                end
            end
        end
    end
    
    -- If we didn't find coal/charcoal specifically, try to refuel with anything
    for i = 1, 16 do
        turtle.select(i)
        if turtle.getItemCount() > 0 then
            print("Attempting to refuel with item in slot " .. i)
            if turtle.refuel(1) then
                print("Successfully refueled with item in slot " .. i)
                print("New fuel level: " .. turtle.getFuelLevel())
                turtle.select(1)
                return true
            end
        end
    end
    
    turtle.select(1)
    return false
end

local function refuelFromChest()
    print("Checking chest for fuel...")
    turtle.select(1)
    
    -- Try to get fuel from chest above
    local itemsChecked = 0
    while itemsChecked < 16 do
        if turtle.suckUp(1) then
            local itemDetail = turtle.getItemDetail()
            if itemDetail then
                if itemDetail.name == "minecraft:coal" or 
                   itemDetail.name == "minecraft:charcoal" or
                   string.find(itemDetail.name, "coal") then
                    print("Refueling with " .. itemDetail.name .. " from chest")
                    if turtle.refuel(64) then  -- Try to refuel with entire stack
                        local newFuel = turtle.getFuelLevel()
                        print("Refueled to " .. newFuel)
                        
                        -- If we have more than needed, put the rest back
                        if turtle.getItemCount() > 0 then
                            turtle.dropUp()
                        end
                        
                        return true
                    end
                else
                    -- Not fuel, put it back
                    turtle.dropUp()
                end
            else
                -- Empty slot, put it back
                turtle.dropUp()
            end
            
            itemsChecked = itemsChecked + 1
        else
            -- No more items to suck
            break
        end
    end
    
    -- If we couldn't find coal, try anything that might be fuel
    itemsChecked = 0
    while itemsChecked < 16 do
        if turtle.suckUp(1) then
            print("Trying to use item from chest as fuel...")
            if turtle.refuel(1) then
                print("Successfully refueled with item from chest")
                print("New fuel level: " .. turtle.getFuelLevel())
                
                -- If we have more than needed, keep using it
                if turtle.getItemCount() > 1 then
                    turtle.refuel(63)  -- Refuel with the rest of the stack
                    if turtle.getItemCount() > 0 then
                        turtle.dropUp()  -- Return any leftovers
                    end
                end
                
                return true
            else
                -- Not fuel, put it back
                turtle.dropUp()
            end
            
            itemsChecked = itemsChecked + 1
        else
            -- No more items to suck
            break
        end
    end
    
    return false
end

local function ensureFuel()
    local currentFuel = turtle.getFuelLevel()
    
    if currentFuel == "unlimited" then
        return true
    end
    
    if currentFuel < FUEL_THRESHOLD then
        print("Fuel low: " .. currentFuel)
        
        -- Try to refuel from inventory first
        if refuelFromInventory() then
            return true
        end
        
        print("Need to return to chest for fuel")
        return false
    end
    
    return true
end

local function isValuableBlock(blockName)
    if not blockName then return false end
    
    -- List of valuable blocks to mine
    local valuableBlocks = {
        "ore",         -- Any ore
        "diamond",     -- Diamond blocks
        "emerald",     -- Emerald blocks
        "gold",        -- Gold blocks
        "lapis",       -- Lapis lazuli
        "redstone",    -- Redstone
        "quartz",      -- Nether quartz
        "ancient_debris" -- Netherite
    }
    
    -- Check if the block name contains any of the valuable keywords
    for _, valuable in ipairs(valuableBlocks) do
        if string.find(blockName, valuable) then
            return true
        end
    end
    
    return false
end

-- Mining Functions
local function scanForOres()
    -- Check all 4 sides for ores
    local oresFound = false
    
    -- Save current facing
    local startFacing = pos.facing
    
    -- Check front
    if turtle.detect() then
        local success, data = turtle.inspect()
        if success and isValuableBlock(data.name) then
            turtle.dig()
            oresFound = true
        end
    end
    
    -- Check left
    turnLeft()
    if turtle.detect() then
        local success, data = turtle.inspect()
        if success and isValuableBlock(data.name) then
            turtle.dig()
            oresFound = true
        end
    end
    
    -- Check right (need to turn around from current position)
    turnRight()
    turnRight()
    if turtle.detect() then
        local success, data = turtle.inspect()
        if success and isValuableBlock(data.name) then
            turtle.dig()
            oresFound = true
        end
    end
    
    -- Check back
    turnRight()
    if turtle.detect() then
        local success, data = turtle.inspect()
        if success and isValuableBlock(data.name) then
            turtle.dig()
            oresFound = true
        end
    end
    
    -- Restore original facing
    turnToFace(startFacing)
    
    -- Check up
    if turtle.detectUp() then
        local success, data = turtle.inspectUp()
        if success and isValuableBlock(data.name) then
            turtle.digUp()
            oresFound = true
        end
    end
    
    -- Check down
    if turtle.detectDown() then
        local success, data = turtle.inspectDown()
        if success and isValuableBlock(data.name) then
            turtle.digDown()
            oresFound = true
        end
    end
    
    return oresFound
end

-- Calculate knight's move pattern mining grid
local function generateMiningGrid()
    local grid = {}
    local maxDistance = SIZE * 2 + 1  -- Convert size to actual grid size
    
    -- Calculate the mining sequence using knight's move pattern
    -- A knight's move is 2 steps in one direction, then 1 step perpendicular
    local x, z = 0, 0
    table.insert(grid, {x=x, z=z})
    
    -- Knight's move offsets
    local moves = {
        {x=2, z=1}, {x=1, z=2}, {x=-1, z=2}, {x=-2, z=1},
        {x=-2, z=-1}, {x=-1, z=-2}, {x=1, z=-2}, {x=2, z=-1}
    }
    
    -- Start from center and spiral outward with knight's moves
    local visited = {}
    visited[x..","..z] = true
    
    local function isInBounds(x, z)
        return math.abs(x) <= maxDistance and math.abs(z) <= maxDistance
    end
    
    local function visit(x, z)
        local key = x..","..z
        if not visited[key] and isInBounds(x, z) then
            visited[key] = true
            table.insert(grid, {x=x, z=z})
            return true
        end
        return false
    end
    
    local keepGoing = true
    while keepGoing do
        keepGoing = false
        for _, pos in ipairs(grid) do
            for _, move in ipairs(moves) do
                local newX, newZ = pos.x + move.x, pos.z + move.z
                if visit(newX, newZ) then
                    keepGoing = true
                end
            end
        end
    end
    
    return grid
end

-- Navigation
local function navigateToPosition(targetX, targetY, targetZ)
    -- First, move to the correct Y level
    while pos.y > targetY do
        if not moveDown() then
            -- Try to dig down
            turtle.digDown()
            if not moveDown() then
                print("Cannot move down further")
                return false
            end
        end
    end
    
    while pos.y < targetY do
        if not moveUp() then
            -- Try to dig up
            turtle.digUp()
            if not moveUp() then
                print("Cannot move up further")
                return false
            end
        end
    end
    
    -- Then navigate in the X-Z plane
    -- First align with X coordinate
    if pos.x ~= targetX then
        if pos.x < targetX then
            turnToFace(DIRECTIONS.EAST)
        else
            turnToFace(DIRECTIONS.WEST)
        end
        
        while pos.x ~= targetX do
            if not moveForward() then
                turtle.dig()
                if not moveForward() then
                    print("Cannot move to target X")
                    return false
                end
            end
        end
    end
    
    -- Then align with Z coordinate
    if pos.z ~= targetZ then
        if pos.z < targetZ then
            turnToFace(DIRECTIONS.SOUTH)
        else
            turnToFace(DIRECTIONS.NORTH)
        end
        
        while pos.z ~= targetZ do
            if not moveForward() then
                turtle.dig()
                if not moveForward() then
                    print("Cannot move to target Z")
                    return false
                end
            end
        end
    end
    
    return true
end

local function returnHome()
    print("Returning to home position...")
    
    -- First go up to make navigation easier
    while pos.y < HOME.y do
        if not moveUp() then
            turtle.digUp()
            moveUp()
        end
    end
    
    -- Navigate to home X and Z
    navigateToPosition(HOME.x, pos.y, HOME.z)
    
    -- Then adjust Y to match home exactly
    navigateToPosition(HOME.x, HOME.y, HOME.z)
    
    -- Face the correct direction
    turnToFace(HOME.facing)
    
    return true
end

local function mineDownward()
    print("Starting downward mining operation...")
    
    -- Choose a column to mine based on our grid
    for i = currentGridIndex, #miningGrid do
        currentGridIndex = i
        local target = miningGrid[i]
        print("Mining column at offset: " .. target.x .. ", " .. target.z)
        
        -- Navigate to the column position
        if not navigateToPosition(HOME.x + target.x, pos.y, HOME.z + target.z) then
            print("Could not navigate to next mining position")
            return false
        end
        
        -- Check if we're at the chest position (0,0) and skip if we are
        if target.x == 0 and target.z == 0 then
            print("Skipping home position to protect chest")
            saveState()
            goto continue_column
        end
        
        -- Check if there's a chest directly below and skip if there is
        do
            local success, blockData = turtle.inspectDown()
            if success and isChest(blockData.name) then
                print("Detected chest below, skipping this position")
                goto continue_column
            end
        end
        
        -- Mine straight down in this column
        local currentDepth = 0
        local targetDepth = math.min(MAX_DEPTH, math.abs(BEDROCK_LAYER - HOME.y))
        local completedOneRun = false
        
        while currentDepth < targetDepth and isRunning do
            -- Try to move down
            if not turtle.detectDown() or turtle.digDown() then
                if moveDown() then
                    currentDepth = currentDepth + 1
                    completedOneRun = true
                    
                    -- Check if we've hit bedrock
                    do
                        local success, data = turtle.inspectDown()
                        if success and data.name == "minecraft:bedrock" then
                            print("Hit bedrock at depth " .. currentDepth)
                            break
                        end
                    end
                    
                    -- Scan for valuable blocks around this position
                    scanForOres()
                    
                    -- Check if we need to return to chest
                    if countFilledSlots() >= INVENTORY_THRESHOLD then
                        print("Inventory getting full, returning to deposit items")
                        returnToChest = true
                        break
                    end
                    
                    -- Check fuel level
                    if not ensureFuel() then
                        print("Low on fuel, returning to get more")
                        returnToChest = true
                        break
                    end
                else
                    print("Could not move down further")
                    break
                end
            else
                print("Could not dig down further")
                break
            end
        end
        
        -- Return to the surface before moving to the next column
        while pos.y < HOME.y do
            if not moveUp() then
                turtle.digUp()
                if not moveUp() then
                    print("Cannot move up! Trying to break through...")
                    turtle.digUp()
                    if not moveUp() then
                        print("Failed to return to surface. Emergency protocol activated.")
                        -- Emergency protocol - try to get back home
                        returnHome()
                        return false
                    end
                end
            end
        end
        
        -- Return to home if inventory is full or fuel is low
        if returnToChest then
            returnHome()
            depositItems()
            
            -- Refuel if needed
            if turtle.getFuelLevel() < FUEL_THRESHOLD * 2 then
                refuelFromChest()
            end
            
            returnToChest = false
            saveState()
            return true  -- End this mining cycle, will continue from next column on next run
        end
        
        -- Save progress after each column
        saveState()
        
        ::continue_column::
    end
    
    -- Return to the home position when all columns are done
    returnHome()
    print("Mining operation completed!")
    miningInProgress = false
    saveState()
    
    return true
end

-- Safely move to the first mining position to avoid mining the chest
local function moveToFirstMiningPosition()
    print("Moving to first mining position...")
    
    -- Check fuel level before moving
    local fuelLevel = turtle.getFuelLevel()
    if fuelLevel == 0 then
        print("ERROR: No fuel available. Cannot move.")
        return false
    elseif fuelLevel ~= "unlimited" and fuelLevel < 10 then
        print("WARNING: Very low fuel (" .. fuelLevel .. "). May not be able to complete operations.")
    end
    
    -- First move forward one block to get off the chest
    print("Attempting to move forward...")
    if not moveForward() then
        print("Cannot move forward. Checking for obstacles...")
        if turtle.detect() then
            print("Obstacle detected. Attempting to clear...")
            turtle.dig() -- Clear any obstacles
        else
            print("No obstacle detected. Might be a fuel issue.")
            print("Current fuel level: " .. tostring(turtle.getFuelLevel()))
        end
        
        if not moveForward() then
            print("Still cannot move forward from starting position")
            return false
        end
    end
    
    -- Then move to the first grid position (should be offset from home)
    if #miningGrid > 1 then
        local firstTarget = miningGrid[2] -- Skip the center position (0,0)
        return navigateToPosition(HOME.x + firstTarget.x, pos.y, HOME.z + firstTarget.z)
    end
    
    return true
end

-- Main program
local function start()
    -- Check if we're continuing a previous mining operation
    local continued = loadState()
    
    if not continued then
        -- First run, set up initial state
        print("Setting up new mining operation")
        print("Please enter the size of the mining area (1-10):")
        SIZE = tonumber(read()) or 1
        
        if SIZE < 1 then SIZE = 1 end
        if SIZE > 10 then SIZE = 10 end
        
        -- Set home position
        HOME = {x = 0, y = 0, z = 0, facing = 0}
        pos = {x = 0, y = 0, z = 0, facing = 0}
        
        print("Mining area size set to " .. SIZE)
        print("Generating mining grid...")
        miningGrid = generateMiningGrid()
        print("Mining grid generated with " .. #miningGrid .. " positions")
        
        -- Move away from the chest before starting to mine
        if not moveToFirstMiningPosition() then
            print("Failed to move to first mining position")
            return
        end
        
        miningInProgress = true
        saveState()
    else
        print("Continuing previous mining operation")
        print("Mining area size: " .. SIZE)
        print("Current grid position: " .. currentGridIndex .. " of " .. #miningGrid)
    end
    
    -- Start the mining operation
    local success = mineDownward()
    
    if success then
        if currentGridIndex >= #miningGrid then
            print("Mining operation completed!")
            miningInProgress = false
        else
            print("Mining paused, will continue from position " .. currentGridIndex .. " on next run")
        end
    else
        print("Mining operation encountered an issue and was paused")
    end
    
    saveState()
end

-- Entry point
local function main()
    print("Efficient Mining Turtle v1.0")
    
    -- Check initial fuel level and try to refuel if necessary
    local fuelLevel = turtle.getFuelLevel()
    print("Current fuel level: " .. tostring(fuelLevel))
    
    if fuelLevel == 0 or (fuelLevel ~= "unlimited" and fuelLevel < FUEL_THRESHOLD * 2) then
        print("Fuel level is low or zero. Attempting to refuel...")
        
        -- First try to get fuel from inventory
        if refuelFromInventory() then
            print("Successfully refueled from inventory.")
        else
            -- Then try to get fuel from the chest above
            print("Trying to get fuel from chest...")
            if refuelFromChest() then
                print("Successfully refueled from chest.")
            else
                print("WARNING: Could not find fuel. The turtle needs fuel to move!")
                print("Please add coal, charcoal, or other fuel to the turtle's inventory.")
                print("Press any key to continue once fuel has been added...")
                os.pullEvent("key")
                
                -- Try one more time after user intervention
                if not refuelFromInventory() then
                    print("Still no fuel found. The turtle may not be able to move.")
                    print("Continuing anyway, but movement might fail.")
                else
                    print("Refueled successfully after manual intervention.")
                end
            end
        end
    end
    
    start()
end

main()
