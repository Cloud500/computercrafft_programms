local DEBUG = false
local fakePeripheralPath = ""

---@alias ItemJson {config: {logging: {enabled: boolean, logLevel: integer, path: string, outputToTerminal: boolean}}, items: {item: string, count: integer}[]}
---@alias MEBridge {isItemCraftable: fun(table):(boolean), isItemCrafting: fun(table):(boolean), getItem: fun(table):({name: string, amount: integer}), craftItem: fun(table):(boolean), getCraftingCPUs: fun():({name: string, storage: integer, coProcessors: integer, isBusy: boolean}[])}



---Helper Function for CraftOS Debugging/Testing
---@return nil
local function debugCreatePeripheral()
    mounter.mount("/lib", fakePeripheralPath .. "\\lib", "ro")
    mounter.mount("/", fakePeripheralPath .. "\\autoCrafter", "ro")
    mounter.mount("/", fakePeripheralPath .. "\\fakes", "ro")
end

---@class AutoCrafter The Class itself
---@field MEBridge MEBridge ME Bridge
---@field logger Logger | nil Logger object
---@field jsonObject ItemJson The loaded JSON Data
---@field timeBetweenRuns number Time between runs
local AutoCrafter = {}
AutoCrafter.__index = AutoCrafter

---@param path string | nil Path of the json file
---@return AutoCrafter AutoCrafter New AutoCrafter object
function AutoCrafter:new(path)
    ---@type AutoCrafter
    local o = {
        MEBridge = {},
        logger = nil,
        jsonObject = {},
        timeBetweenRuns = 0.5
    }
    setmetatable(o, self)
    if path == nil then
        path = "items.json"
    end

    o:loadColonyMEBride()
    o.jsonObject = o:loadJsonFile(path)
    o.logger = o:getLogger()

    return o
end

---Try to load the JSON API
---@return nil
function AutoCrafter.loadJsonAPI()
    if not fs.exists("lib/json") then
        error("JSON API not found.")
    end

    os.loadAPI("lib/json")
end

---Try to load the logger
---@return nil
function AutoCrafter:getLogger()
    if not fs.exists("lib/logger.lua") then
        error("Logger not found.")
    end

    ---@type Logger
    local logger = require("lib/logger")

    local logConfig = self:getLoggingInfo()

    return logger:new(logConfig.path,
        logConfig.logLevel,
        logConfig.outputToTerminal,
        logConfig.enabled)
end

--- Get the logger information
---@return {enabled: boolean, logLevel: integer, path: string, outputToTerminal: boolean} logging Logging information
function AutoCrafter:getLoggingInfo()
    return self.jsonObject.config.logging
end

---Try to load the ME Bridge,
---has some Debug options for CraftOS Debugging/Testing
---@return nil
function AutoCrafter:loadColonyMEBride()
    if DEBUG then
        self.MEBridge = require("fake_MEBridge")
    else
        self.MEBridge = peripheral.find("meBridge")
    end

    if not self.MEBridge then
        error("ME Bridge not found.")
    end
end

---Read the content from the JSON file
---@param path string Path to the JSON file
---@return ItemJson jsonObject Content of the JSON file
function AutoCrafter:loadJsonFile(path)
    os.loadAPI("lib/json")
    return json.decodeFromFile(path)
end

function AutoCrafter:canCraftItem(itemName)
    return self.MEBridge.isItemCraftable(
        { name = itemName }
    )
end

function AutoCrafter:isItemCrafting(itemName)
    return self.MEBridge.isItemCrafting(
        { name = itemName }
    )
end

function AutoCrafter:isFreeCPU()
    local cpus = self.MEBridge.getCraftingCPUs()

    for cpuNumber in pairs(cpus) do
        local cpu = cpus[cpuNumber]
        if not cpu.isBusy then
            return true
        end
    end
    return false
end

function AutoCrafter:tryToCraft(itemName)
    if self:canCraftItem(itemName)
        and not self:isItemCrafting(itemName)
        and self:isFreeCPU() then
        self.MEBridge.craftItem(
            {
                name = itemName,
                count = 1
            }
        )
        self.logger:logInfo("Craft " .. itemName)
    end
end

function AutoCrafter:getCurrentAmount(itemName)
    local result = self.MEBridge.getItem(
        { name = itemName }
    )
    local amount = result.amount
    if amount == nil then
        amount = 0
    end

    return amount
end

function AutoCrafter:itemNeedToCraft(itemName, itemTargetAmount)
    if self:isItemCrafting(itemName) then
        return false
    end

    local currentAmount = self:getCurrentAmount(itemName)

    if currentAmount < itemTargetAmount then
        return true
    end
    return false
end

function AutoCrafter:processItem(itemName, itemTargetAmount)
    if self:itemNeedToCraft(itemName, itemTargetAmount) then
        self:tryToCraft(itemName)
    end
end

function AutoCrafter:processItems()
    for itemNumber in pairs(self.jsonObject.items) do
        local itemData = self.jsonObject.items[itemNumber]
        self:processItem(itemData.item, itemData.count)
    end
end

---Main loop for the Programm
---@return nil
function AutoCrafter:init()
    self:processItems()
    local TIMER = os.startTimer(self.timeBetweenRuns)
    while true do
        local event = { os.pullEvent() }
        if event[1] == "timer" and event[2] == TIMER then
            self:processItems()
            TIMER = os.startTimer(self.timeBetweenRuns)
        end
    end
end


if DEBUG then
    debugCreatePeripheral()
end

local crafter = AutoCrafter:new("items.json")

crafter:init()
