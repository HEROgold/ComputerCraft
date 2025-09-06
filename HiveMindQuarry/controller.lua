-- HiveMindQuarry/controller.lua
-- Central controller for HiveMind Quarry
-- Responsibilities:
--  * Register turtles & assign partitions (sections) of the quarry
--  * Track progress & fuel / idle states using HeroicLib
--  * Reassign sections when turtles finish or new turtles join
--  * Provide idle stacking positions for unassigned turtles

local displayOk, display = pcall(require,'HeroicLib.display')
local fuelOk, fuel = pcall(require,'HeroicLib.fuel')
local storageOk, storage = pcall(require,'HeroicLib.storage')
require('HeroicLib.turtle') -- direction constants for reuse if needed

-- Configuration load
local function loadConfig()
  if storageOk and storage.exists('HMQ_CONFIG') then
    return storage.load('HMQ_CONFIG')
  elseif fs.exists('hmq_config.lua') then
    local ok, data = pcall(dofile,'hmq_config.lua')
    if ok then return data end
  end
  return nil
end

local cfg = loadConfig()
if not cfg or not cfg.region then
  print('[HMQ] Missing config/region. Run installer again.')
  return
end

local region = cfg.region -- {x1,y1,z1,x2,y2,z2}
local label = cfg.controllerLabel or 'HiveMindQuarry'
os.setComputerLabel(label)

-- Region normalization
local function norm(a,b) if a<b then return a,b else return b,a end end
local x1,x2 = norm(region[1],region[4])
local y1,y2 = norm(region[2],region[5])
local z1,z2 = norm(region[3],region[6])

-- Derived sizes
local sizeX = (x2-x1)+1
local sizeY = (y2-y1)+1
local sizeZ = (z2-z1)+1
local totalBlocks = sizeX*sizeY*sizeZ

-- Partition strategy: slice along X/Z plane into columns or small prisms (16x16 columns by default)
local prism = 8 -- dimension of square prism in X/Z for each turtle
local function genSections()
  local sections = {}
  for sx = x1, x2, prism do
    local ex = math.min(sx+prism-1,x2)
    for sz = z1, z2, prism do
      local ez = math.min(sz+prism-1,z2)
      table.insert(sections, {
        startX=sx,endX=ex,
        startY=y2,endY=y1, -- dig downward
        startZ=sz,endZ=ez,
        assigned=nil, progress=0, done=false, id=#sections+1
      })
    end
  end
  return sections
end

local sections = genSections()
local turtles = {} -- id -> turtle state {id, label, fuel, sectionId, status, lastUpdate, pos={x,y,z}}
local sectionQueue = {}
for i=1,#sections do sectionQueue[i]=i end

-- Networking
local function findModem()
  for _, side in ipairs({'left','right','top','bottom','front','back'}) do if peripheral.getType(side)=='modem' then return side end end
  return nil
end
local modemSide = findModem()
if not modemSide then print('[HMQ] No modem found. Attach modem.'); return end
rednet.open(modemSide)
rednet.host('HMQ','controller')
print('[HMQ] Controller online at '..modemSide)

-- Idle stacking positions (circle around controller position) requires GPS
local controllerX,controllerY,controllerZ = gps.locate(2,true)
if not controllerX then print('[HMQ] GPS not available; idle stacking disabled.') end

local function idlePositions(n)
  local positions = {}
  if not controllerX then return positions end
  local r = cfg.stackRadius or 2
  local angleStep = (math.pi*2)/math.max(1,n)
  for i=1,n do
    local a = (i-1)*angleStep
    positions[i] = {x=controllerX+math.floor(math.cos(a)*r), y=controllerY, z=controllerZ+math.floor(math.sin(a)*r)}
  end
  return positions
end

-- Assignment logic
local function assignSection(turtleId)
  for _, sid in ipairs(sectionQueue) do
    local s = sections[sid]
    if not s.assigned and not s.done then
      s.assigned = turtleId
      turtles[turtleId].sectionId = sid
      turtles[turtleId].status = 'assigned'
      rednet.send(turtleId, {type='assign', section=s, fuelTarget=5000}, 'HMQ_ASSIGN')
      return true
    end
  end
  -- none left, send idle
  rednet.send(turtleId,{type='idle', stackAround={controllerX,controllerY,controllerZ}, radius=cfg.stackRadius or 2},'HMQ_IDLE')
  turtles[turtleId].status='idle'
  return false
end

local function reclaimSection(sectionId)
  local s = sections[sectionId]
  if s and not s.done then
    s.assigned=nil
  end
end

-- Update display summary
local function drawSummary()
  term.clear() term.setCursorPos(1,1)
  print('HiveMind Quarry Controller')
  print(('Region: (%d,%d,%d) -> (%d,%d,%d) Size:%dx%dx%d'):format(x1,y1,z1,x2,y2,z2,sizeX,sizeY,sizeZ))
  local doneBlocks = 0
  local active = 0
  for _, s in ipairs(sections) do
    doneBlocks = doneBlocks + math.floor(((s.progress or 0)/1000) * ((s.endX-s.startX+1)*(s.startY-s.endY+1)*(s.endZ-s.startZ+1)))
    if s.assigned and not s.done then active=active+1 end
  end
  print(('Sections: %d  Active:%d  Turtles:%d'):format(#sections, active, (function() local c=0 for _ in pairs(turtles) do c=c+1 end return c end)()))
  print(('Fuel: %s'):format(fuelOk and fuel.getFuelString() or 'n/a'))
  local complete = 0
  for _,s in ipairs(sections) do if s.done then complete=complete+1 end end
  print(('Progress: %d/%d sections'):format(complete,#sections))
  print('--- Turtles ---')
  for id,t in pairs(turtles) do
    print(('%d %s %s %s'):format(id, t.label or '?', t.status or '?', t.sectionId and ('S'..t.sectionId) or ''))
  end
end

-- Event handling
local function handleMessage(id,msg,proto)
  if msg.type=='register' then
    turtles[id] = turtles[id] or {id=id}
    turtles[id].label = msg.label
    turtles[id].fuel = msg.fuel
    turtles[id].status = 'new'
    turtles[id].lastUpdate = os.clock()
    assignSection(id)
  elseif msg.type=='progress' then
    local t = turtles[id]; if t then
      t.lastUpdate=os.clock()
      t.fuel = msg.fuel
      if msg.sectionId and sections[msg.sectionId] then
        local s = sections[msg.sectionId]
        s.progress = msg.progress
        if msg.done then s.done=true; s.assigned=nil; t.sectionId=nil; t.status='requesting'; assignSection(id) end
      end
    end
  elseif msg.type=='request' then
    local t = turtles[id]; if t then t.status='requesting'; assignSection(id) end
  elseif msg.type=='lost' then
    local t = turtles[id]; if t and t.sectionId then reclaimSection(t.sectionId) end
    turtles[id]=nil
  end
end

-- Main loop
local tick = 0
while true do
  local timer = os.startTimer(1)
  local id,msg,proto
  while true do
    local e,p1,p2,p3,p4 = os.pullEvent()
    if e=='rednet_message' then id,p2,p3 = p1,p2,p3; msg,proto = p2,p3; handleMessage(id,msg,proto)
    elseif e=='timer' and p1==timer then break end
  end
  tick = tick + 1
  if tick % 2 ==0 then drawSummary() end
end
