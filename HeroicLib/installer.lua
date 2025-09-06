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
    "turtle.lua",
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

-- Check and modify startup.lua file if not skipped
if not skipStartupModification then
    print("Checking for existing startup.lua file...")
    
    local startupContent = ""
    local requireLine = 'local heroicStartup = require("HeroicLib/startup")\nheroicStartup()'
    
    if fs.exists("startup.lua") then
        print(" - Found existing startup.lua")
        local handle = fs.open("startup.lua", "r")
        startupContent = handle.readAll()
        handle.close()
        
        -- Check if the file already has the require line
        if not string.find(startupContent, 'require%("HeroicLib/startup"%)', 1, false) and 
           not string.find(startupContent, "require%(\"HeroicLib/startup\"%)", 1, false) and
           not string.find(startupContent, 'require%("HeroicLib/startup"%)', 1, false) and
           not string.find(startupContent, "require'HeroicLib/startup'", 1, false) then
            
            print(" - Adding HeroicLib startup to existing startup.lua")
            startupContent = requireLine .. "\n\n" .. startupContent
            
            local handle = fs.open("startup.lua", "w")
            handle.write(startupContent)
            handle.close()
            print(" - Successfully updated startup.lua")
        else
            print(" - HeroicLib startup already in startup.lua")
        end
    else
        print(" - No startup.lua found, creating one")
        local handle = fs.open("startup.lua", "w")
        handle.write(requireLine .. "\n\n-- Your code can go here\n")
        handle.close()
        print(" - Created startup.lua with HeroicLib")
    end
end

if success then
    print("==================================")
    print("HeroicLib installed successfully!")
    print("Version: " .. VERSION)
    print("==================================")
    if skipStartupModification then
        print("To run the startup loader, add this to your startup.lua:")
        print('local heroicStartup = require("HeroicLib/startup")')
        print('heroicStartup()')
    else
        print("The startup.lua file has been modified to load HeroicLib on startup.")
        print("Your computer will now show the HeroicLib loading screen when it starts.")
    end
else
    print("==================================")
    print("Some files failed to download.")
    print("Please check your internet connection and try again.")
end
