-- Launcher for Mining Turtle
-- This script is used to start a new mining operation or continue an existing one

local MINER_SCRIPT = "miner"
local SAVED_DATA_FILE = "mining_state.data"

local function printHeader()
    term.clear()
    term.setCursorPos(1, 1)
    print("=================================")
    print("  Mining Turtle Launcher v1.0")
    print("=================================")
    print("")
end

local function checkForExistingOperation()
    return fs.exists(SAVED_DATA_FILE)
end

local function startNewOperation()
    printHeader()
    print("Starting new mining operation...")
    shell.run(MINER_SCRIPT)
end

local function continueOperation()
    printHeader()
    print("Continuing existing mining operation...")
    shell.run(MINER_SCRIPT)
end

-- Main function
local function main()
    printHeader()
    
    if checkForExistingOperation() then
        print("An existing mining operation was found.")
        print("Options:")
        print("1. Continue mining operation")
        print("2. Start new mining operation (will lose current progress)")
        print("3. Exit")
        
        io.write("Enter choice (1-3): ")
        local choice = tonumber(read())
        
        if choice == 1 then
            continueOperation()
        elseif choice == 2 then
            fs.delete(SAVED_DATA_FILE)
            startNewOperation()
        else
            print("Exiting...")
        end
    else
        print("No existing mining operation found.")
        print("Options:")
        print("1. Start new mining operation")
        print("2. Exit")
        
        io.write("Enter choice (1-2): ")
        local choice = tonumber(read())
        
        if choice == 1 then
            startNewOperation()
        else
            print("Exiting...")
        end
    end
end

-- Run the main function
main()
