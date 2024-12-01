-- Initialize Rednet with the built-in modem
-- rednet.open("back")

-- Locate the Chunky Turtle using GPS
local turtleX, turtleY, turtleZ = gps.locate(5, true)
if not turtleX then
    print("Unable to locate GPS position. Ensure GPS is running.")
    return
end
print("Chunky Turtle located at: ", turtleX, turtleY, turtleZ)

-- Send registration message to "HiveQuarry" with position
rednet.send(0, {type = "chunky", x = turtleX, y = turtleY, z = turtleZ})

-- Wait for move commands
while true do
    local id, message, protocol = rednet.receive("move")
    os.setComputerLabel("Turtle " .. id)
    if protocol == "move" then
        local position = message
        print("Moving to position: " .. textutils.serialize(position))
        -- Move to the specified position
        -- Implement movement logic here
    end
end
