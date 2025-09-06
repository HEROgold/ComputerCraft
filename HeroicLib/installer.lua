-- HeroicLib Installer
-- Created by HEROgold
-- GitHub: https://github.com/HEROgold/ComputerCraft

local args = {...}
local branch = args[1] or "main"
local basePath = "https://raw.githubusercontent.com/HEROgold/ComputerCraft/" .. branch .. "/HeroicLib/"

-- Current version information
local VERSION = "1.0.0" -- Update this when you release new versions
local VERSION_FILE = "HeroicLib/version.lua"

local files = {
    "display.lua",
    "fuel.lua",
    "movement.lua",
    "storage.lua",
    "startup.lua",
    "version.lua" -- Add version file to the list
}

-- Create HeroicLib directory if it doesn't exist
if not fs.exists("HeroicLib") then
    fs.makeDir("HeroicLib")
end

print("Installing HeroicLib from branch: " .. branch)
print("Version: " .. VERSION)
print("==================================")

-- Download all files
local success = true
for _, file in ipairs(files) do
    print("Downloading " .. file .. "...")
    local response = http.get(basePath .. file)
    
    if response then
        local content = response.readAll()
        response.close()
        
        local handle = fs.open("HeroicLib/" .. file, "w")
        handle.write(content)
        handle.close()
        
        print(" - Success!")
    else
        print(" - Failed to download " .. file)
        success = false
    end
end

-- Create version file if it wasn't downloaded
if not fs.exists(VERSION_FILE) then
    local handle = fs.open(VERSION_FILE, "w")
    handle.write("return {\n    version = \"" .. VERSION .. "\",\n    branch = \"" .. branch .. "\"\n}")
    handle.close()
    print("Created version file")
end

if success then
    print("==================================")
    print("HeroicLib installed successfully!")
    print("Version: " .. VERSION)
    print("To use it in your code, add: ")
    print('local display = require("HeroicLib/display")')
    print('local fuel = require("HeroicLib/fuel")')
    print('local movement = require("HeroicLib/movement")')
    print('local storage = require("HeroicLib/storage")')
    print("==================================")
    print("To run the startup loader, add this to your startup.lua:")
    print('shell.run("HeroicLib/startup.lua")')
else
    print("==================================")
    print("Some files failed to download.")
    print("Please check your internet connection and try again.")
end
