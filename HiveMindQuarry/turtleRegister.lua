require("turtleUtils")

-- Initialize Rednet with the built-in modem
rednet.open("left")

-- Locate the turtle using GPS
local x, y, z = gps.locate(5, true)
if not x then
    print("Unable to locate GPS position. Ensure GPS is running.")
    return
end
print("Turtle located at: ", x, y, z)

local function findMaster()
    print("Looking for nearby masters...")
    local masterId = rednet.lookup("HiveQuarry", "main")
    if masterId then
        print("Master " .. masterId)
    else
        print("No master found. Retrying...")
    end
    return masterId
end

local masterId = findMaster()
while not masterId do
    sleep(5)
    masterId = findMaster()
end

-- Track the slot where the fuel is located
local fuelSlot = nil

-- Try to refuel from each slot between 1 and 16
for slot = 1, 16 do
    turtle.select(slot)
    if turtle.refuel(0) then
        fuelSlot = slot
        break
    end
end

if not fuelSlot then
    print("No fuel found in any slot. Please add fuel to the turtle.")
    return
end

-- Send registration message to "HiveQuarry" with position
rednet.send(masterId, {type = "register", x = x, y = y, z = z})

-- Function to handle reconnection
local function reconnect()
    masterId = findMaster()
    while not masterId do
        sleep(5)
        masterId = findMaster()
    end
    rednet.send(masterId, {type = "register", x = x, y = y, z = z})
end

-- Wait for assignment
while true do
    local id, message, protocol = rednet.receive("assign", 10)
    if not id then
        print("Master not found. Attempting to reconnect...")
        reconnect()
    else
        os.setComputerLabel("Turtle " .. os.getComputerID())
        if protocol == "assign" then
            local subChunk = message.subChunk
            local knownMaxDepth = message.maxDepth
            local masterX = message.masterX
            local masterY = message.masterY
            local masterZ = message.masterZ
            print("Assigned sub-chunk: " .. textutils.serialize(subChunk))
            
            -- Calculate the required fuel
            local requiredFuel = TurtleUtils.calculateRequiredFuel(subChunk)

            -- Refuel the turtle if necessary
            if not TurtleUtils.refuelTurtle(requiredFuel, fuelSlot) then
                print("Unable to refuel, stopping operations.")
                break
            end

            -- Move to the starting position
            print("Moving to " .. subChunk.startX .. ", " .. subChunk.startY .. ", " .. subChunk.startZ)
            TurtleUtils.moveTo(subChunk.startX, subChunk.startY, subChunk.startZ)

            -- Mine the sub-chunk
            TurtleUtils.mineSubChunk(subChunk, fuelSlot, masterX, masterY, masterZ)

            -- Find bedrock and report the maximum depth if necessary
            if not knownMaxDepth or knownMaxDepth > subChunk.startY then
                local maxDepth = TurtleUtils.findBedrock()
                if not knownMaxDepth or maxDepth < knownMaxDepth then
                    rednet.send(masterId, {type = "max_depth", depth = maxDepth})
                end
            end

            -- After completing the sub-chunk, request a new one
            rednet.send(masterId, {type = "request_sub_chunk"})
        end
    end
end
