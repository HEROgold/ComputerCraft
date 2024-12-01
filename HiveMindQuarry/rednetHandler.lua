RednetHandler = {}

local turtles = {}
local subChunks = {}
local currentSubChunk = 1
local maxDepth = nil
local masterX, masterY, masterZ = nil, nil, nil
local S = nil

RednetHandler.initialize = function(size, controllerX, controllerY, controllerZ)
    S = size
    masterX, masterY, masterZ = controllerX, controllerY, controllerZ
    subChunks = TurtleManagement.calculateSubChunks(size, controllerX, controllerY, controllerZ, maxDepth or 0)
    print("initialized with " .. #subChunks .. " sub-chunks" .. " at Y: " .. controllerY)
end

RednetHandler.handleEvent = function(event, id, message)
    print("Received event: " .. event .. " from ID: " .. id .. " with message: " .. textutils.serialize(message))
    if event == "rednet_message" then
        if message.type == "register" then
            table.insert(turtles, {id = id, x = message.x, y = message.y, z = message.z})
            print("Turtle " .. id .. " registered at (" .. message.x .. ", " .. message.y .. ", " .. message.z .. ")")
            RednetHandler.assignSubChunk(id)
        elseif message.type == "request_sub_chunk" then
            RednetHandler.assignSubChunk(id)
        elseif message.type == "max_depth" then
            if not maxDepth or message.depth < maxDepth then
                maxDepth = message.depth
                print("Turtle " .. id .. " reported new max depth: " .. message.depth)
                subChunks = TurtleManagement.calculateSubChunks(S, masterX, masterY, masterZ, maxDepth)
            end
        end
    end
end

RednetHandler.assignSubChunk = function(turtleID)
    if currentSubChunk <= #subChunks then
        rednet.send(turtleID, {
            subChunk = subChunks[currentSubChunk],
            maxDepth = maxDepth,
            masterX = masterX,
            masterY = masterY,
            masterZ = masterZ
        }, "assign")
        print("Assigned sub-chunk " .. currentSubChunk .. " to Turtle " .. turtleID)
        currentSubChunk = currentSubChunk + 1
    else
        print("No more sub-chunks to assign.")
    end
end