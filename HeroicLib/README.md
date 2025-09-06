# HeroicLib for ComputerCraft

A collection of utility modules for ComputerCraft turtles.

## Features

- **Display Module**: Progress bars and turtle status information with rednet capability detection
- **Fuel Module**: Fuel management and monitoring
- **Movement Module**: Advanced movement controls for turtles
- **Storage Module**: Inventory management utilities
- **Startup Script**: Loading screen with progress bar and system information
- **Auto-Update System**: Checks for updates during startup and prompts for installation
- **Automatic Startup Integration**: Modifies or creates startup.lua to include HeroicLib

## Installation

### Option 1: One-line installer

Run this command in your ComputerCraft computer or turtle:

```lua
wget run https://raw.githubusercontent.com/HEROgold/ComputerCraft/main/HeroicLib/installer.lua
```

The installer will automatically:

1. Download all HeroicLib files
2. Check for an existing startup.lua file
3. Either modify the existing startup.lua or create a new one
4. Configure your computer to show the HeroicLib loading screen on startup

If you don't want the installer to modify your startup.lua, add "skipStartup" as the third parameter:

```lua
wget run https://raw.githubusercontent.com/HEROgold/ComputerCraft/main/HeroicLib/installer.lua main "" skipStartup
```

## Usage

### Basic Usage

Import the modules you need:

```lua
local display = require("HeroicLib/display")
local fuel = require("HeroicLib/fuel")
local movement = require("HeroicLib/movement")
local storage = require("HeroicLib/storage")
```

### Running the Startup Screen

Add this to your startup.lua file:

```lua
shell.run("HeroicLib/startup.lua")
-- Your code continues here after the startup animation
```

Or for better integration, require it:

```lua
local heroicStartup = require("HeroicLib/startup")
-- Run with custom loading time (3 seconds) and enable update check
heroicStartup(3)
-- Your code continues here
```

### Automatic Updates

The startup sequence automatically checks for updates once per day and prompts the user to install them if available. You can skip the update check by passing true as the second parameter:

```lua
local heroicStartup = require("HeroicLib/startup")
-- Run with update check skipped (for headless operation)
heroicStartup(5, true)
```

### Display Module

```lua
-- Show turtle information (includes rednet capability)
display.showTurtleInfo()

-- Check rednet capability
local hasRednet, modemSide, modemType = display.checkRednetCapability()
if hasRednet then
    print("Rednet available on " .. modemSide .. " side (" .. modemType .. " modem)")
end

-- Create a progress bar
display.createProgressBar("mining", 10, 100, "Mining Progress")

-- Update progress
display.updateProgress("mining", 50) -- 50%
```

### Fuel Module

```lua
-- Get current fuel level
local level = fuel.getFuelLevel()

-- Get formatted fuel string
local fuelInfo = fuel.getFuelString()
```

### Movement Module

```lua
-- Move in specific directions
turtle.move(Forward, 3) -- Move forward 3 blocks
turtle.move(Up) -- Move up 1 block
```

## Contributing

Feel free to submit pull requests or issues on GitHub.

## License

MIT License
