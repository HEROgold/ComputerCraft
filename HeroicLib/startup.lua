-- HeroicLib/startup.lua
-- Startup script with progress bar that runs for 5 seconds

local display = require("HeroicLib/display")
local versionInfo = require("HeroicLib/version")
local time = 1
local time_ms = time * 1000

-- Function to check for updates
local function checkForUpdates()
    -- Only check once per day
    if versionInfo.lastChecked == os.day() then
        return false, "Already checked today"
    end
    
    -- Update lastChecked
    local version = versionInfo.version
    local branch = versionInfo.branch or "main"
    
    -- Check version from GitHub
    local versionUrl = "https://raw.githubusercontent.com/HEROgold/ComputerCraft/" .. branch .. "/HeroicLib/version.lua"
    local response = http.get(versionUrl)
    
    if not response then
        return false, "Failed to connect to GitHub"
    end
    
    local content = response.readAll()
    response.close()
    
    -- Extract version from content
    local remoteVersion = string.match(content, 'version%s*=%s*"([^"]+)"')
    
    if not remoteVersion then
        return false, "Failed to parse version information"
    end
    
    -- Update lastChecked date in the local version file
    local handle = fs.open("HeroicLib/version.lua", "w")
    handle.write("-- HeroicLib version information\n")
    handle.write("-- This file is automatically updated by the installer\n\n")
    handle.write("return {\n")
    handle.write('    version = "' .. version .. '",\n')
    handle.write('    branch = "' .. branch .. '",\n')
    handle.write('    lastChecked = ' .. os.day() .. '\n')
    handle.write("}")
    handle.close()
    
    -- Compare versions
    if remoteVersion ~= version then
        return true, remoteVersion
    end
    
    return false, "Up to date"
end

-- Function to install updates
local function installUpdates()
    local branch = versionInfo.branch or "main"
    shell.run("wget", "run", "https://raw.githubusercontent.com/HEROgold/ComputerCraft/" .. branch .. "/HeroicLib/installer.lua", branch)
    return true
end

-- Function to run the startup sequence
local function runStartup(customTime, skipUpdateCheck)
    -- Use custom time if provided, otherwise default to 5 seconds
    local loadTime = customTime or time
    local loadTime_ms = loadTime * 1000
    
    -- Clear the terminal
    term.clear()
    term.setCursorPos(1, 1)
    
    -- Display header
    local width, height = term.getSize()
    local headerText = "HeroicLib Loading..."
    local centerX = math.floor((width - #headerText) / 2) + 1
    term.setCursorPos(centerX, 2)
    term.write(headerText)
    
    -- Display version
    local versionText = "Version: " .. versionInfo.version
    local centerVersion = math.floor((width - #versionText) / 2) + 1
    term.setCursorPos(centerVersion, 3)
    term.write(versionText)
    
    -- Check for updates if not skipped
    if not skipUpdateCheck and http then
        local updateAvailable, newVersion = checkForUpdates()
        
        if updateAvailable then
            local updateText = "Update available: " .. newVersion
            local centerUpdate = math.floor((width - #updateText) / 2) + 1
            term.setCursorPos(centerUpdate, 4)
            term.write(updateText)
            
            term.setCursorPos(1, 6)
            print("Would you like to update HeroicLib? (y/n)")
            local input = read():lower()
            
            if input == "y" or input == "yes" then
                print("Installing update...")
                if installUpdates() then
                    print("Update completed. Restarting...")
                    os.sleep(1)
                    return runStartup(loadTime, true) -- Restart with update check skipped
                else
                    print("Update failed. Continuing with current version...")
                    os.sleep(1)
                end
            else
                print("Update skipped. Continuing with current version...")
                os.sleep(1)
            end
            
            -- Clear terminal again after update choice
            term.clear()
            term.setCursorPos(1, 1)
            term.setCursorPos(centerX, 2)
            term.write(headerText)
            term.setCursorPos(centerVersion, 3)
            term.write(versionText)
        end
    end
    
    -- Check rednet capability
    local hasRednet, modemSide, modemType = display.checkRednetCapability()
    local rednetMessage = "Rednet: "
    if hasRednet then
        rednetMessage = rednetMessage .. "Available (" .. modemType .. " modem)"
    else
        rednetMessage = rednetMessage .. "Not Available"
    end
    local centerRednet = math.floor((width - #rednetMessage) / 2) + 1
    term.setCursorPos(centerRednet, 5)
    term.write(rednetMessage)
    
    -- Create a progress bar
    display.createProgressBar("startup", 7, 100, "System Initialization")
    
    -- Run the progress bar for the specified time
    local startTime = os.epoch("local")
    local endTime = startTime + loadTime_ms
    
    while os.epoch("local") < endTime do
        local elapsed = os.epoch("local") - startTime
        local progressPercent = math.floor((elapsed / loadTime_ms) * 100)
    
        -- Update progress bar
        display.updateProgress("startup", progressPercent)
        
        -- Sleep for a small amount to not hog resources
        os.sleep(0.05)
    end
    
    -- Make sure we show 100% at the end
    display.updateProgress("startup", 100)
    os.sleep(0.2) -- Short pause to show the completed progress
    
    -- Clear screen and return to normal ComputerCraft environment
    term.clear()
    term.setCursorPos(1, 1)
    print("HeroicLib loaded successfully!")
    
    return true
end

-- If this file is run directly with shell.run, execute the startup sequence
if not package.loaded["HeroicLib/startup"] then
    runStartup()
end

-- Return the function so it can be required by other scripts
return runStartup
