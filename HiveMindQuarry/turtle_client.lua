-- HiveMindQuarry/turtle_client.lua
-- Turtle worker client for HiveMind Quarry
-- Responsibilities:
--  * Register with controller
--  * Receive section assignment and mine it efficiently
--  * Periodically send progress updates
--  * Return to controller for dumping/refuel when inventory near full or fuel low
--  * Idle stack when no work

local displayOk, display = pcall(require,'HeroicLib.display')
local fuelOk, fuel = pcall(require,'HeroicLib.fuel')
local storageOk, storage = pcall(require,'HeroicLib.storage')
require('HeroicLib.turtle')

-- Utility
local function modemSide()
  for _, s in ipairs({'left','right','top','bottom','front','back'}) do if peripheral.getType(s)=='modem' then return s end end
end
local mSide = modemSide()
if not mSide then print('No modem. Attach wireless modem.'); return end
rednet.open(mSide)

local function gpsPos()
  return gps.locate(2,true)
end

local function refuelTo(level)
  if not fuelOk then return true end
  if fuel.getCurrentFuel() >= level then return true end
  local ok = fuel.refuelToLevel(level)
  return ok
end

local function dumpInventory()
  for slot=1,16 do
    turtle.select(slot)
    turtle.drop()
  end
end

local controllerId = nil
local function resolveController()
  controllerId = rednet.lookup('HMQ','controller')
  return controllerId
end

while not resolveController() do
  print('Searching controller...')
  sleep(3)
end

local label = os.getComputerLabel() or ('HMQ_Turtle_'..os.getComputerID())
os.setComputerLabel(label)

local function register()
  rednet.send(controllerId,{type='register', label=label, fuel=fuelOk and fuel.getCurrentFuel() or turtle.getFuelLevel()},'HMQ_REG')
end
register()

-- Mining Implementation
local activeSection = nil
local sectionId = nil
local controllerX,controllerY,controllerZ = nil,nil,nil
local progressBlocks = 0
local totalSectionBlocks = 0

local function sectionVolume(s)
  return (s.endX-s.startX+1)*(s.startY-s.endY+1)*(s.endZ-s.startZ+1)
end

local function moveAxis(current, target, positive, negative)
  while current ~= target do
    local dir = (current < target) and positive or negative
    -- face using simple heuristic: use turtle.move utility with direction constants if horizontal
    if dir=='up' then while not turtle.up() do turtle.digUp() end current=current+1
    elseif dir=='down' then while not turtle.down() do turtle.digDown() end current=current-1
    else
      -- horizontal cardinal via GPS orientation guess: we brute force by trying moves and checking gps delta
      local x1,y1,z1 = gpsPos()
      if not x1 then turtle.dig() turtle.forward() else
        local moved=false
        for i=1,4 do
          local bx,by,bz = gpsPos()
          if not bx then turtle.dig() turtle.forward() moved=true break end
          turtle.forward()
          local ax,ay,az = gpsPos()
          if ax and bx and ((dir=='east' and ax>bx) or (dir=='west' and ax<bx) or (dir=='south' and az>bz) or (dir=='north' and az<bz)) then
            moved=true; current = (dir=='east' or dir=='south') and current+1 or current-1; break
          else turtle.back(); turtle.turnRight() end
        end
        if not moved then turtle.dig() turtle.forward() end
      end
    end
  end
  return current
end

local function gotoPos(tx,ty,tz)
  local x,y,z = gpsPos()
  if not x then return false end
  x = moveAxis(x,tx,'east','west')
  z = moveAxis(z,tz,'south','north')
  y = moveAxis(y,ty,'up','down')
  return true
end

local function ensureFuelFor(rem)
  if not fuelOk then return true end
  local needed = rem + 500
  refuelTo(needed)
end

local function mineSection(s)
  activeSection=s
  sectionId=s.id
  totalSectionBlocks = sectionVolume(s)
  progressBlocks=0
  controllerX,controllerY,controllerZ = controllerX or nil,controllerY or nil,controllerZ or nil
  -- start at top northwest corner
  gotoPos(s.startX,s.startY,s.startZ)
  for y = s.startY, s.endY, -1 do
    local invert = false
    for x = s.startX, s.endX do
      for z = (invert and s.endZ or s.startZ), (invert and s.startZ or s.endZ), (invert and -1 or 1) do
        if not gpsPos() then end
        if z ~= (invert and s.startZ or s.endZ) then
          while not turtle.forward() do turtle.dig() end
        end
        progressBlocks=progressBlocks+1
        if progressBlocks % 100 ==0 then
          rednet.send(controllerId,{type='progress', sectionId=sectionId, progress=progressBlocks/totalSectionBlocks, fuel=fuelOk and fuel.getCurrentFuel() or turtle.getFuelLevel()},'HMQ_PROG')
        end
        if turtle.getItemCount(16)>0 then -- inventory full
          -- Return to controller position to dump (we assume controller at first corner top)
          rednet.send(controllerId,{type='progress', sectionId=sectionId, progress=progressBlocks/totalSectionBlocks, fuel=fuelOk and fuel.getCurrentFuel()},'HMQ_PROG')
          gotoPos(s.startX,s.startY,s.startZ) -- simplistic return path
          dumpInventory()
          gotoPos(x,y,z)
        end
      end
      if x < s.endX then
        turtle.turnRight(); while not turtle.forward() do turtle.dig() end; turtle.turnLeft()
        invert = not invert
      end
    end
    if y > s.endY then
      while not turtle.down() do turtle.digDown() end
      gotoPos(s.startX,y-1,s.startZ)
    end
  end
  rednet.send(controllerId,{type='progress', sectionId=sectionId, progress=1, fuel=fuelOk and fuel.getCurrentFuel(), done=true},'HMQ_PROG')
end

-- Idle stacking
local function idleLoop(params)
  print('Idle: awaiting work.')
  if params and params.stackAround then
    -- simple spin
  end
end

-- Main event loop
while true do
  local id,msg,proto = rednet.receive(nil,5)
  if id and id==controllerId and type(msg)=='table' then
    if msg.type=='assign' then
      mineSection(msg.section)
      rednet.send(controllerId,{type='request'},'HMQ_REQ')
    elseif msg.type=='idle' then
      idleLoop(msg)
      rednet.send(controllerId,{type='request'},'HMQ_REQ')
    end
  else
    -- heartbeat
    rednet.send(controllerId,{type='progress', sectionId=sectionId, progress=progressBlocks/totalSectionBlocks, fuel=fuelOk and fuel.getCurrentFuel()},'HMQ_HB')
  end
end
