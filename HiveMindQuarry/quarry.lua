-- Import functions from other files
require("turtleUtils")
require("chunkyTurtle")
require("turtleManagement")
require("rednetHandler")

local tArgs = { ... }

if #tArgs < 1 then
    print("Usage: quarry <size> <totalTurtles>")
    return
end

local size = tonumber(tArgs[1])
local maxTurtles = tonumber(tArgs[2])

-- Initialize Rednet with a wireless modem and set hostname
local modemSide = "top"  -- Change this to the side where your modem is attached
rednet.open(modemSide)
rednet.host("HiveQuarry", "main")

-- Locate the quarry computer using GPS
local quarryX, quarryY, quarryZ = gps.locate(5, true)
if not quarryX then
    print("Unable to locate GPS position. Ensure GPS is running.")
    return
end
print("Quarry computer located at: ", quarryX, quarryY, quarryZ)

-- Initialize Rednet handler
RednetHandler.initialize(size, quarryX, quarryY, quarryZ)

-- Main event loop
while true do
    local event, id, message, protocol = os.pullEvent("rednet_message")
    RednetHandler.handleEvent(event, id, message)
end
