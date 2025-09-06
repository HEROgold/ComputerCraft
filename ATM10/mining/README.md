# Mining Turtle Scripts

This folder contains scripts for an efficient mining turtle system that uses a knight's move pattern to mine efficiently.

## Files

- `miner.lua` - The main mining algorithm script
- `start.lua` - Launcher to start or continue mining operations
- `reset.lua` - Utility to reset mining progress

## Setup

1. Place a mining turtle directly on top of a chest
2. The turtle will use this chest to deposit mined items and collect fuel

## Usage

### Starting Mining

Run:

```
start
```

This will:

- If first time: Ask you for the mining area size (1-10)
- If continuing: Let you choose to resume or start fresh

### Size Parameter

The size parameter defines how far from the chest the turtle will mine:

- Size 1: 3x3 area around the chest
- Size 2: 5x5 area around the chest
- And so on...

### Resetting

If you want to completely restart:

```
reset
```

This will delete all saved progress after confirmation.

## Features

- Uses an efficient knight's move pattern to maximize coverage
- Automatically detects and mines valuable ores
- Returns to chest when inventory is nearly full
- Manages fuel requirements and can refuel from inventory or chest
- Avoids bedrock and creates new mining shafts when needed
- Resumes from where it left off if the turtle is rebooted
- Never mines the storage chest it works with

## Fuel Requirements

The turtle requires fuel to move. It will:

- Use coal/charcoal from its inventory
- Check the chest for fuel when needed
- Return home if fuel is too low

Place coal or other fuel items in the chest to keep the turtle running.

## Tips

- For maximum efficiency, use a Diamond Mining Turtle
- Place the turtle on a chest with some coal for initial fuel
- Periodically check on your turtle to ensure it has enough fuel
- For larger operations, consider using ender chests
