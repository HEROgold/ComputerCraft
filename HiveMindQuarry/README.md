# HiveMind Quarry (HeroicLib Integrated)

Parallel multi-turtle quarry system managed by a single controller computer.

## Features

- Controller partitions quarry volume into prism sections (default 8x8 columns)
- Unlimited turtle registration (practical limits: rednet & performance)
- Dynamic section assignment & re-assignment
- Progress & fuel tracking via HeroicLib
- Idle stacking behavior when no work available
- Simple installer for controller or turtle clients

## Installation

1. Ensure `HeroicLib` folder is present at root (as in repo).
2. Place `HiveMindQuarry` folder on both controller computer and turtles.
3. Run installer:
   - Controller: `shell.run("HiveMindQuarry/installer.lua")` choose Controller
   - Turtle: `shell.run("HiveMindQuarry/installer.lua")` choose Turtle
4. For controller you will be guided to select two opposite quarry corners (GPS required).

After install, a `startup.lua` is written to auto-run controller or turtle client.

## Requirements

- Wireless modem on all machines (controller + turtles)
- GPS network for accurate movement & assignment preferred (without GPS some behavior degrades)
- Fuel in turtle inventories.

## Workflow

1. Controller boots, loads region & waits for turtles.
2. Turtle boots, registers with controller.
3. Controller assigns a section; turtle mines & reports progress.
4. Upon completion turtle requests another section; if none left it idles.

## Notes

- Movement / pathing is simplified; improvements (A* path, better return path) are future work.
- Section prism size configurable by editing `controller.lua` (variable `prism`).
- Persistence uses HeroicLib storage when available else fallback file.

## Future Enhancements

- Better fuel budgeting & guaranteed return path calculation.
- Smarter idle stacking with collision avoidance.
- Automatic chest placement / ender chest integration for dumping.

Enjoy efficient large-scale quarries!
