require("name")

local fuel_count = 0

local function find_fuel_slot()
    for i = 1, 16 do
        turtle.select(i)
        if turtle.refuel(0) then
            print(Prefix.."Found fuel in slot "..i)
            fuel_slot = i
            return i
        end
    end
    error(Prefix.."No fuel found")
end


function get_available_fuel()
    turtle.select(fuel_slot)
    local fuel_count = turtle.getItemCount(fuel_slot)
    if not turtle.refuel(0) then
        fuel_count = 0
    end
    print(Prefix.."Fuel count: "..fuel_count)
    return fuel_count
end

---@param target integer
---@return boolean
function refuel(target)
    while turtle.getFuelLevel() < target do
        fuel_count = get_available_fuel()
        if fuel_count == 0 then
            print(Prefix.."Out of fuel")
            return false
        end
        turtle.refuel(1)
        print(Prefix.."Refueled")
    end
    return true
end

FuelSlot = find_fuel_slot()
