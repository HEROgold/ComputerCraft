TurtleManagement = {}

TurtleManagement.adjustTurtleCount = function (size)
    local maxTurtles = 16  -- Maximum number of turtles that can be deployed
    local minSizePerTurtle = 16  -- Minimum size of the area each turtle should handle (16x16x16)
    local requiredTurtles = math.ceil(size / minSizePerTurtle)
    return math.min(requiredTurtles, maxTurtles)
end

TurtleManagement.calculateSubChunks = function(size, controllerX, controllerY, controllerZ, maxDepth)
    local subChunks = {}
    local chunkSize = 16
    local halfSize = math.floor(size / 2)

    for x = -halfSize, halfSize, chunkSize do
        for z = -halfSize, halfSize, chunkSize do
            for y = 0, size - 1, chunkSize do
                local startY = controllerY - y - chunkSize
                local endY = controllerY - y - 1
                if endY >= maxDepth then
                    table.insert(subChunks, {
                        startX = controllerX + x,
                        endX = controllerX + x + chunkSize - 1,
                        startY = startY,
                        endY = endY,
                        startZ = controllerZ + z,
                        endZ = controllerZ + z + chunkSize - 1
                    })
                end
            end
        end
    end

    return subChunks
end

TurtleManagement.assignSubChunks = function(turtles, subChunks)
    for i, turtleID in ipairs(turtles) do
        rednet.send(turtleID, subChunks[i], "assign")
    end
end