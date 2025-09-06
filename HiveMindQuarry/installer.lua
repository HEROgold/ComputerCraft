-- Unified installer for HiveMind Quarry controller or turtle clients
-- Uses HeroicLib for display, fuel and storage persistence
-- Run this on either a ComputerCraft Computer (controller) or a Turtle.
-- NOTE: We no longer pcall() HeroicLib modules. Instead we ensure the directory
-- exists, optionally run its installer, then hard-require the modules.

local function ensureHeroicLib()
  if not fs.isDir('HeroicLib') then
    print('[Installer] HeroicLib directory not found.')
    -- Attempt to locate a bundled installer (fallback names) or abort.
    -- If repository includes HeroicLib, user likely forgot to copy folder.
    if fs.exists('HeroicLib/installer.lua') then
      -- (Edge case: folder wasn't a dir but a file; safeguard)
      shell.run('HeroicLib/installer.lua')
    else
      print('Please copy the HeroicLib folder into the root alongside HiveMindQuarry and re-run.')
      return false
    end
  else
    -- Run HeroicLib installer if present to ensure it's initialized / updated.
    if fs.exists('HeroicLib/installer.lua') then
      print('[Installer] Running HeroicLib installer to ensure library is up to date...')
      pcall(function() shell.run('HeroicLib/installer.lua') end)
    end
  end
  return true
end

if not ensureHeroicLib() then return end

-- Hard requires (will error loudly if something is missing, which is desired now)
local storage = require('HeroicLib.storage')
local display = require('HeroicLib.display')
local fuel = require('HeroicLib.fuel')

local function centerPrint(txt)
  local w,h = term.getSize()
  local x = math.max(1, math.floor((w - #txt)/2)+1)
  term.setCursorPos(x, select(2, term.getCursorPos()))
  print(txt)
end

local function findModem()
  for _, side in ipairs({'left','right','top','bottom','front','back'}) do
    if peripheral.getType(side) == 'modem' then return side end
  end
  return nil
end

local function writeFile(path, content)
  local f = fs.open(path,'w')
  f.write(content)
  f.close()
end

local function ensureDir(path)
  if not fs.isDir(path) then fs.makeDir(path) end
end

local function ask(prompt, default)
  term.write(prompt .. (default and (' ['..default..']') or '') .. ': ')
  local input = read()
  if input == '' and default then return default end
  return input
end

local function detectGPS()
  local x,y,z = gps.locate(2,true)
  return x,y,z
end

local function saveConfig(cfg)
  storage.save('HMQ_CONFIG', cfg)
end

local function loadConfig()
  if storage.exists('HMQ_CONFIG') then
    return storage.load('HMQ_CONFIG')
  elseif fs.exists('hmq_config.lua') then
    local ok, data = pcall(dofile,'hmq_config.lua')
    if ok then return data end
  end
  return nil
end

local function installController()
  print('Installing HiveMind Quarry Controller...')
  local modem = findModem()
  if not modem then
    print('ERROR: No modem found. Attach a wireless modem and re-run installer.')
    return
  end
  -- Quarry region config
  print('\nEnter quarry opposite corner coordinates (absolute GPS).')
  print('Leave blank to reuse previous config if present.')
  local existing = loadConfig()
  local x1,y1,z1,x2,y2,z2
  if existing then
    print('Found previous config: '..textutils.serialize(existing.region))
  end
  local reuse = existing and ask('Reuse previous quarry region? (y/n)','y') or 'n'
  if reuse:lower() == 'y' and existing then
    x1,y1,z1,x2,y2,z2 = table.unpack(existing.region)
  else
    print('Stand at first corner now (or enter manually). Press Enter to auto-detect.')
    if ask('Auto-detect first corner? (y/n)','y'):lower()=='y' then
      x1,y1,z1 = detectGPS()
      if not x1 then print('GPS failed, abort.'); return end
      centerPrint(('Corner1: %d %d %d'):format(x1,y1,z1))
    else
      x1 = tonumber(ask('x1')) y1=tonumber(ask('y1')) z1=tonumber(ask('z1'))
    end
    print('Move to opposite corner. Press Enter when ready for auto-detect.')
    if ask('Auto-detect second corner? (y/n)','y'):lower()=='y' then
      x2,y2,z2 = detectGPS()
      if not x2 then print('GPS failed, abort.'); return end
      centerPrint(('Corner2: %d %d %d'):format(x2,y2,z2))
    else
      x2 = tonumber(ask('x2')) y2=tonumber(ask('y2')) z2=tonumber(ask('z2'))
    end
  end
  local region = {x1,y1,z1,x2,y2,z2}
  local cfg = existing or {}
  cfg.region = region
  cfg.controllerLabel = ask('Controller label','HiveMindQuarry')
  cfg.stackRadius = tonumber(ask('Idle stack radius','2')) or 2
  saveConfig(cfg)
  -- Install runtime files (controller + startup)
  local controllerSourcePath = 'HiveMindQuarry/controller.lua'
  if not fs.exists(controllerSourcePath) then
    print('ERROR: controller.lua missing in HiveMindQuarry folder.')
    return
  end
  writeFile('startup.lua','shell.run("HiveMindQuarry/controller.lua")')
  print('\nController installed. Rebooting in 3s...')
  sleep(3)
  os.reboot()
end

local function installTurtle()
  print('Installing HiveMind Quarry Turtle Client...')
  if not turtle then print('ERROR: This is not a turtle.'); return end
  local modem = findModem()
  if not modem then print('ERROR: No modem (wireless) found.'); return end
  local label = ask('Turtle label (blank to auto)','')
  if label ~= '' then os.setComputerLabel(label) end
  -- create startup
  writeFile('startup.lua','shell.run("HiveMindQuarry/turtle_client.lua")')
  print('Turtle client installed. Rebooting in 3s...')
  sleep(3)
  os.reboot()
end

term.clear() term.setCursorPos(1,1)
centerPrint('HiveMind Quarry Installer')
print('Uses HeroicLib for display, fuel & persistence.')
print('Detected: '..(turtle and 'Turtle' or 'Computer'))
print('\nSelect installation type:')
print('  1) Controller (quarry manager)')
print('  2) Turtle (worker)')
print('  3) Abort')
term.write('Choice [1/2/3]: ')
local c = read()
if c=='1' then installController()
elseif c=='2' then installTurtle()
else print('Aborted.') end
