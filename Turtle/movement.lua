local starting_height = nil
local starting_point = {x = 0, y = 0, z = 0}
local offset = {x = 0, y = 0, z = 0}

local rotation = 0
local FRONT = 0
local RIGHT = 1
local BACK = 2
local LEFT = 3

function move_down()
    offset.y = offset.y - 1
    turtle.down()
end

function move_up()
    offset.y = offset.y + 1
    turtle.up()
end

function turn_left()
    if rotation == 0 then
        rotation = 4
    end
    rotation = rotation - 1
    turtle.turnLeft()
end

function turn_right()
    rotation = rotation + 1
    turtle.turnRight()
    if rotation == 4 then
        rotation = 0
    end
end

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

---@param x integer
---@param y integer
---@param z integer
function go_to(x, y, z)
    
end


if starting_height == nil then
    local coords = get_coords()
    if coords.y ~= 0 then
        starting_height = coords.y
        return
    end

    print("No starting height provided")
    print("Starting Y coordinate?")
    starting_height = tonumber(read("Starting height: "))
end