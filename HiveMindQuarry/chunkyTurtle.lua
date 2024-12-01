ChunkyTurtle = {}

ChunkyTurtle.moveChunkyTurtle = function(chunkyTurtleID, size)
    local chunkSize = 16  -- Minecraft chunk size is 16x16
    local positions = {}

    -- Calculate positions within the chunk
    for x = 0, size, chunkSize do
        for y = 0, size, chunkSize do
            table.insert(positions, {x = x, y = y})
        end
    end

    -- Ensure the Chunky Turtle stays within the chunk boundaries
    for _, pos in ipairs(positions) do
        rednet.send(chunkyTurtleID, pos, "move")
        sleep(5)  -- Wait for the Chunky Turtle to move
    end
end