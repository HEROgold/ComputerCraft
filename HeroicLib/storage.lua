local dataStore = {}
local fileName = "heroic_storage.dat"

-- Try to load existing data when module loads
local function loadFromFile()
    if fs.exists(fileName) then
        local file = fs.open(fileName, "r")
        local serializedData = file.readAll()
        file.close()
        
        if serializedData and serializedData ~= "" then
            dataStore = textutils.unserialize(serializedData) or {}
        end
    end
end

-- Save all data to file
local function saveToFile()
    local file = fs.open(fileName, "w")
    file.write(textutils.serialize(dataStore))
    file.close()
end

loadFromFile() -- Load data when module is required

storage = {}

function storage.save(key, value)
    dataStore[key] = value
    saveToFile()
end

function storage.load(key)
    return dataStore[key]
end

function storage.delete(key)
    dataStore[key] = nil
    saveToFile()
end

function storage.exists(key)
    return dataStore[key] ~= nil
end

-- Optional: Set a custom filename
function storage.setFileName(name)
    fileName = name
    loadFromFile()
end

return storage