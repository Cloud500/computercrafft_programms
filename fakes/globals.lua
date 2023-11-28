peripheral = {}

---@param data string
---@return table
function peripheral.wrap(data)
    return {}
end

mounter = {}

---@param lPath string
---@param rPath string
---@param type string
---@return nil
function mounter.mount(lPath, rPath, type)
end

---@param name string
---@return nil
function os.loadAPI(name)
end

---@param time integer
---@return integer
function os.startTimer(time)
    return 0
end

---@param filter string | nil
---@return string
function os.pullEvent(filter)
    return ""
end

fs = {}

---@param path string
---@return boolean
function fs.exists(path)
    return false
end

json = {}

---@param path string
---@return table
function json.decodeFromFile(path)
    return {}
end