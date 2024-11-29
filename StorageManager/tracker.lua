-- Track items

local StorageManager = require("StorageManager")

-- Initialize the robot
local robot = peripheral.wrap("right")

-- Function to scan and track items in storage
local function trackItems()
    local items = {}
    for slot = 1, robot.getInventorySize() do
        local item = robot.getItemDetail(slot)
        if item then
            table.insert(items, item)
        end
    end
    return items
end

-- Main loop to continuously track items
while true do
    local trackedItems = trackItems()
    StorageManager.update(trackedItems)
    os.sleep(10) -- Wait for 10 seconds before the next scan
end
