-- Create a new turtle from the current turtle
-- requirements, crafty turtle

if turtle.craft(1) then
    print("Crafted turtle")
else
    print("Failed to craft turtle")
end

-- Place the turtle in the world
if not turtle.place() then
    print("Failed to place turtle")
end
