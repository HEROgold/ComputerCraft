-- Reset Mining Turtle
-- This script completely resets the mining turtle operation,
-- deleting all saved state so it can start fresh

local SAVED_DATA_FILE = "mining_state.data"

local function printHeader()
    term.clear()
    term.setCursorPos(1, 1)
    print("=================================")
    print("  Mining Turtle Reset Utility")
    print("=================================")
    print("")
end

local function resetMiningOperation()
    if fs.exists(SAVED_DATA_FILE) then
        print("Found existing mining operation data.")
        print("Are you sure you want to delete all mining progress?")
        print("This cannot be undone. (y/n)")
        
        local response = read():lower()
        
        if response == "y" or response == "yes" then
            fs.delete(SAVED_DATA_FILE)
            print("Mining operation data has been deleted.")
            print("The turtle will start fresh the next time you run 'start'.")
        else
            print("Reset cancelled. No changes were made.")
        end
    else
        print("No existing mining operation data found.")
        print("Nothing to reset.")
    end
end

-- Run the reset utility
printHeader()
resetMiningOperation()
