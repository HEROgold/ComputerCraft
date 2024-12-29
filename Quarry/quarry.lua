
local prefix = "Turtle> "
local bedrock_y = -59
local starting_point = {x = 0, y = 0, z = 0}
local offset = {x = 0, y = 0, z = 0}
---@type integer
local rotation = 0
local fuel_count = 0
local fuel_slot = 0
local chest_slots = 36
local chest_inventory = {}
local starting_height = arg[1] or nil

local CHESTS = "forge:chests"
local ORES = "forge:ores"
local FRONT = 0
local RIGHT = 1
local BACK = 2
local LEFT = 3


if starting_height == nil then
    print(prefix.."No starting height provided")
    print(prefix.."Starting Y coordinate?")
    starting_height = read("Starting height: ")
end

starting_point.y = tonumber(starting_height)


---@returns table<integer, integer, integer>
local function get_coords()
    ---@type table<integer, integer, integer>
    local gps = gps.locate()
    if gps ~= nil then
        return {
            x = gps[1],
            y = gps[2],
            z = gps[3],
        }
    end
    return {
        x = starting_point.x + offset.x,
        y = starting_point.y + offset.y,
        z = starting_point.z + offset.z
    }
end

local function move_down()
    offset.y = offset.y - 1
    turtle.down()
end
local function move_up()
    offset.y = offset.y + 1
    turtle.up()
end
local function turn_left()
    if rotation == 0 then
        rotation = 4
    end
    rotation = rotation - 1
    turtle.turnLeft()
end
local function turn_right()
    rotation = rotation + 1
    turtle.turnRight()
    if rotation == 4 then
        rotation = 0
    end
end

local function get_chest_front()
    local exists, block = turtle.inspect()
    if exists then
        if block.tags[CHESTS] then
            print(prefix.."Chest found")
            return nil
        end
    end
    print(prefix.."No chest found, trying to place one")
    for i = 1, 16 do
        turtle.select(i)
        if turtle.getItemCount(i) > 0 then
            if turtle.getItemDetail(i).tags[CHESTS] then
                turtle.place()
                print(prefix.."Deployed chest")
                break
            end
        end
    end
    error(prefix.."No chest found and no chests in inventory")
end

local function find_fuel_slot()
    for i = 1, 16 do
        turtle.select(i)
        if turtle.refuel(0) then
            print(prefix.."Found fuel in slot "..i)
            fuel_slot = i
            return nil
        end
    end
    error(prefix.."No fuel found")
end

local function get_chest_slots()
    local exists, data = turtle.inspect()
    if exists and data.tags[CHESTS] then
        print(prefix.."Chest found")
    end
    local remaining = chest_slots - #data
    print(prefix.."Remaining slots: "..remaining)
end

local function has_free_slot()
    for i = 16, 1, -1 do
        if turtle.getItemCount(i) == 0 then
            return true
        end
    end
    return false
end

local function get_available_fuel()
    turtle.select(fuel_slot)
    fuel_count = turtle.getItemCount(fuel_slot)
    if not turtle.refuel(0) then
        fuel_count = 0
    end
    print(prefix.."Fuel count: "..fuel_count)
end

---comment
---@param target integer
---@return boolean
local function refuel(target)
    local fuel_level = turtle.getFuelLevel()
    if fuel_level < target then
        get_available_fuel()
        if fuel_count == 0 then
            print(prefix.."Out of fuel")
            return false
        end
        turtle.refuel(1)
        print(prefix.."Refueled")
    end
    return true
end

local function inspect_surroundings()
    local _, front = turtle.inspect()
    local _, up = turtle.inspectUp()
    local _, down = turtle.inspectDown()
    turn_left()
    local _, left = turtle.inspect()
    turn_left()
    local _, back = turtle.inspect()
    turn_left()
    local _, right = turtle.inspect()
    turn_left()
    return {
        front = front,
        up = up,
        down = down,
        left = left,
        back = back,
        right = right
    }
end


local function should_mine(block)
    if block == nil then
        return false
    end
    if block.tags == nil then
        return false
    end
    if block.tags[ORES] then
        return true
    end
    return false
end

local function to_surface()
    while offset.y < 0 do
        if turtle.detectUp() then
            turtle.digUp()
        end
        move_up()
    end
end

---comment Rotation is always relative to what it was FIRST looking towards.
---@param target integer
local function goto_rotation(target)
    if rotation == 3 then
        rotation = -1
    end
    while rotation < target do
        turn_right()
    end
    while rotation > target do
        turn_left()
    end
end


local function dump_inventory()
    for i = 1, 16 do
        if i ~= fuel_slot then
            turtle.select(i)
            turtle.drop()
        end
    end
end

local function mine_surroundings()
    local surroundings = inspect_surroundings()
    if should_mine(surroundings.front) then
        goto_rotation(FRONT)
        turtle.dig()
    end
    if should_mine(surroundings.right) then
        goto_rotation(RIGHT)
        turtle.dig()
    end
    if should_mine(surroundings.back) then
        goto_rotation(BACK)
        turtle.dig()
    end
    if should_mine(surroundings.left) then
        goto_rotation(LEFT)
        turtle.dig()
    end
    if should_mine(surroundings.up) then
        turtle.digUp()
    end
    if should_mine(surroundings.down) then
        turtle.digDown()
    end
    goto_rotation(FRONT)
end

local function mine_to_bedrock()
    while has_free_slot() do
        if refuel(300) == false then
            break
        end
        if get_coords().y <= bedrock_y then
            print(prefix.."Reached bedrock")
            break
        end
        turtle.digDown()
        move_down()
    end
end


---comment
---@param length integer
---@return integer
local function mine_tunnel(length)
    local fuel_needed = length*8
    local reached = 0

    refuel(fuel_needed)
    if turtle.getFuelLevel() < fuel_needed then
        print(prefix.."Not enough fuel to mine "..length.." blocks")
        return 0
    end
    for i = 1, length do
        goto_rotation(BACK)
        turtle.dig()
        turtle.forward()
        mine_surroundings()
        reached = i
        if not has_free_slot() then
            print(prefix.."Inventory full, returning...")
            break
        end
    end
    print(prefix.."Tunnel mined "..reached.." blocks, returning...")
    for i = 1, reached do
        goto_rotation(FRONT)
        turtle.forward()
    end
    return reached
end

local function mine_quarry(size)
    local reached = 0
    local height = 0
    local fuel_needed = size*size*2
    local to_return = false

    if turtle.getFuelLevel() < fuel_needed then
        print(prefix.."Not enough fuel to mine "..size.." blocks")
        return 0
    end

    for y = 1, size do
        if to_return then
            break
        end
        for i = 1, size do
            reached = mine_tunnel(size)
            if reached < size then
                to_return = true
                break
            end
            goto_rotation(RIGHT)
            turtle.dig()
            turtle.forward()
        end
        move_up()
        height = y
    end

    if to_return then
        print(prefix.."Quarry of size ".. size .. "unfinished. Returning...")
    else
        print(prefix.."Quarry of size ".. size .. "complete. Returning...")
    end

    for y=1, height do
        move_down()
    end
    goto_rotation(LEFT)
    for i=1, reached do
        turtle.forward()
    end
    goto_rotation(FRONT)
end

get_chest_front()
get_chest_slots()
find_fuel_slot()

mine_to_bedrock()
mine_quarry(8) -- TODO: use size arg
to_surface()
goto_rotation(FRONT)
while turtle.forward() do
end
dump_inventory()

print(prefix.."Done")

-- Hivemind:
-- columns should be 2, 1 away from the starting point. (like a chess horse)
-- get radius around the center. (chest column)
