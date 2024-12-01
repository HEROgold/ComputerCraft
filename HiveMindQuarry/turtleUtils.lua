TurtleUtils = {}

TurtleUtils.findBedrock = function()
    print("Finding bedrock...")
    local depth = 0
    while true do
        if turtle.detectDown() then
            if turtle.inspectDown() then
                local success, data = turtle.inspectDown()
                if success then
                    for k, v in pairs(data) do
                        print(k, v)
                    end
                end
                if data.name == "minecraft:bedrock" then
                    print("Bedrock found at depth: " .. depth)
                    return depth
                end
            end
        end
        turtle.digDown()
        turtle.down()
        depth = depth + 1
    end
end

TurtleUtils.moveTo = function(targetX, targetY, targetZ)
    local x, y, z = gps.locate(5, true)
    if not x then
        print("Unable to locate GPS position. Ensure GPS is running.")
        return false
    end

    -- Determine the current direction by moving forward and checking the new coordinates
    local function determineDirection()
        local initialX, initialY, initialZ = gps.locate(5, true)
        turtle.forward()
        local newX, newY, newZ = gps.locate(5, true)
        turtle.back()

        if newX > initialX then
            return "east"
        elseif newX < initialX then
            return "west"
        elseif newZ > initialZ then
            return "south"
        elseif newZ < initialZ then
            return "north"
        end
    end

    local direction = determineDirection()

    local function faceDirection(targetDirection)
        if direction == targetDirection then
            return
        end

        local turns = {
            north = { east = "right", west = "left", south = "right", north = "none" },
            east = { north = "left", west = "right", south = "right", east = "none" },
            south = { north = "right", east = "left", west = "right", south = "none" },
            west = { north = "right", east = "right", south = "left", west = "none" }
        }

        local direction = turns[direction]
        local turn = direction[targetDirection]
        if turn == "right" then
            turtle.turnRight()
        elseif turn == "left" then
            turtle.turnLeft()
        end

        direction = targetDirection
    end

    local function moveToAxis(current, target, positiveDirection, negativeDirection)
        while current ~= target do
            if current < target then
                faceDirection(positiveDirection)
                while not turtle.forward() do
                    turtle.dig()
                end
                current = current + 1
            else
                faceDirection(negativeDirection)
                while not turtle.forward() do
                    turtle.dig()
                end
                current = current - 1
            end
        end
    end

    local function moveToVerticalAxis(current, target)
        while current ~= target do
            if current < target then
                while not turtle.up() do
                    turtle.digUp()
                end
                current = current + 1
            else
                while not turtle.down() do
                    turtle.digDown()
                end
                current = current - 1
            end
        end
    end

    moveToAxis(x, targetX, "east", "west")
    moveToAxis(z, targetZ, "south", "north")
    moveToVerticalAxis(y, targetY)

    return true
end

TurtleUtils.checkAndMineBlock = function()
    local success, data = turtle.inspect()
    if not (success and data.name == "computercraft:turtle") then
        turtle.dig()
    end

    success, data = turtle.inspectUp()
    if not (success and data.name == "computercraft:turtle") then
        turtle.digUp()
    end

    success, data = turtle.inspectDown()
    if not (success and data.name == "computercraft:turtle") then
        turtle.digDown()
    end
end

TurtleUtils.checkInventoryAndRefuel = function(fuelSlot, masterX, masterY, masterZ)
    if TurtleUtils.emptySlots() <= 1 then
        print("Inventory full, returning to dump items and refuel.")
        local currentX, currentY, currentZ = gps.locate(5, true)
        TurtleUtils.returnToBaseAndRefuel(fuelSlot, masterX, masterY, masterZ)
        TurtleUtils.moveTo(currentX, currentY, currentZ)
    end
end

TurtleUtils.mineSubChunk = function(subChunk, fuelSlot, masterX, masterY, masterZ)
    local startX = subChunk.startX
    local endX = subChunk.endX
    local startY = subChunk.startY
    local endY = subChunk.endY
    local startZ = subChunk.startZ
    local endZ = subChunk.endZ

    -- Start at the initial position
    local x, y, z = startX, startY, startZ

    -- Move to the correct starting Y position
    if y > masterY - 1 then
        TurtleUtils.moveTo(x, masterY - 1, z)
        y = masterY - 1
    end

    for x = startX, endX do
        for z = startZ, endZ do
            for y = startY, endY, -1 do
                -- Check and mine the current block
                TurtleUtils.checkAndMineBlock()

                -- Check inventory slots and refuel if necessary
                TurtleUtils.checkInventoryAndRefuel(fuelSlot, masterX, masterY, masterZ)

                -- Move down
                if y > endY then
                    while not turtle.down() do
                        turtle.digDown()
                    end
                end
            end
            -- Move to the next column
            if z < endZ then
                turtle.turnRight()
                while not turtle.forward() do
                    turtle.dig()
                end
                turtle.turnLeft()
            end
        end
        -- Move to the next row
        if x < endX then
            turtle.turnLeft()
            while not turtle.forward() do
                turtle.dig()
            end
            turtle.turnRight()
        end
    end
end

TurtleUtils.calculateRequiredFuel = function(subChunk)
    local startX = subChunk.startX
    local endX = subChunk.endX
    local startY = subChunk.startY
    local endY = subChunk.endY
    local startZ = subChunk.startZ
    local endZ = subChunk.endZ

    local distance = math.abs(endX - startX) + math.abs(endZ - startZ) + math.abs(startY - endY)
    local miningOperations = (endX - startX + 1) * (endZ - startZ + 1) * (startY - endY + 1)

    if distance + miningOperations > 20000 then
        return 20000
    end
    return distance + miningOperations
end

TurtleUtils.refuelTurtle = function(requiredFuel, fuelSlot)
    if turtle.getFuelLevel() >= requiredFuel then
        return true
    end

    turtle.select(fuelSlot)
    turtle.refuel(requiredFuel - turtle.getFuelLevel())
    print("Required fuel: " .. requiredFuel)
    print("Refueled from slot " .. fuelSlot)
    print("Fuel level: " .. turtle.getFuelLevel())
    if turtle.getFuelLevel() >= requiredFuel then
        return true
    end
    print("No fuel found!")
    return false
end

TurtleUtils.emptySlots = function()
    local empty = 0
    for i = 1, 16 do
        if turtle.getItemCount(i) == 0 then
            empty = empty + 1
        end
    end
    return empty
end

TurtleUtils.returnToBaseAndRefuel = function(fuelSlot, masterX, masterY, masterZ)
    -- Move to base (master's GPS location)
    TurtleUtils.moveTo(masterX, masterY, masterZ)

    -- Drop all items except fuel
    for i = 1, 16 do
        if i ~= fuelSlot then
            turtle.select(i)
            turtle.drop()
        end
    end

    -- Refuel
    TurtleUtils.refuelTurtle(20000, fuelSlot)
end
