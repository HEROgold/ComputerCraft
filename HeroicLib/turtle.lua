Down = 0
Up = 1
Forward = 2
Back = 3
Left = 4
Right = 5

turtle = turtle or {}

local looking = Forward

local function TurnTo(direction)
    while looking ~= direction do
        if (looking == Forward and direction == Right) or
           (looking == Right and direction == Back) or
           (looking == Back and direction == Left) or
           (looking == Left and direction == Forward) then
            turtle.turnRight()
            looking = (looking + 1) % 4
        else
            turtle.turnLeft()
            looking = (looking - 1) % 4
        end
    end
end

local function GoHorizontal(direction, amount)
    amount = amount or 1
    TurnTo(direction)
    for i = 1, amount do
        turtle.forward()
    end
end

local function GoUp(amount)
    amount = amount or 1
    for i = 1, amount do
        turtle.up()
    end
end

local function GoDown(amount)
    amount = amount or 1
    for i = 1, amount do
        turtle.down()
    end
end

-- Use the generic function for the four horizontal directions
local function GoLeft(amount) return GoHorizontal(Left, amount) end
local function GoRight(amount) return GoHorizontal(Right, amount) end
local function GoForward(amount) return GoHorizontal(Forward, amount) end
local function GoBack(amount) return GoHorizontal(Back, amount) end

local movement = {
    [Down] = GoDown,
    [Up] = GoUp,
    [Forward] = GoForward,
    [Back] = GoBack,
    [Left] = GoLeft,
    [Right] = GoRight
}

-- Move the turtle in a specified direction for a given distance
turtle.move = function (direction, distance)
    distance = distance or 1
    local steps = movement[direction]
    if not steps then return false, "Invalid direction" end

    steps(distance)
end

turtle.getDirection = function()
    return looking
end
