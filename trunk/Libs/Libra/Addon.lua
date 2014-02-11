local Libra = LibStub("Libra")
local object = Libra:GetModule("Addon", 1)
if not object then return end

object.frame = object.frame or CreateFrame("Frame")
object.addons = object.addons or {}
object.events = object.events or {}
object.onUpdates = object.onUpdates or {}

local function safecall(object, method, ...)
	if object[method] then
		object[method](object, ...)
	end
end

object.frame:RegisterEvent("ADDON_LOADED")
object.frame:SetScript("OnEvent", function(self, event, ...)
	if event == "ADDON_LOADED" then
		local addon = object.addons[...]
		if addon then
			safecall(addon, "OnInitialize")
			for k, module in pairs(addon.modules) do
				safecall(module, "OnInitialize")
				module.OnInitialize = nil
			end
		end
	end
	for module, eventHandler in pairs(object.events[event]) do
		eventHandler(module, ...)
	end
end)

local function onUpdate(self, elapsed)
	for module, update in pairs(object.onUpdates) do
		update(module, elapsed)
	end
end

setmetatable(object.events, {
	__index = function(table, key)
		local newTable = {}
		table[key] = newTable
		return newTable
	end
})

local AddonPrototype = {}
local ObjectPrototype = {}

local function embed(target)
	for k, v in pairs(ObjectPrototype) do
		target[k] = v
	end
end

function Libra:NewAddon(name, addonObject)
	if object.addons[name] then
		error(format("Addon '%s' already exists.", name), 2)
	end
	
	local addon = addonObject or {}
	embed(addon)
	for k, v in pairs(AddonPrototype) do
		addon[k] = v
	end
	addon.modules = {}
	object.addons[name] = addon
	return addon
end

function AddonPrototype:NewModule(name, table)
	local module = table or {}
	embed(module)
	module.name = name
	self.modules[name] = module
	safecall(self, "OnModuleCreated", name, module)
	return module
end

function AddonPrototype:GetModule(name)
	return self.modules[name]
end

function AddonPrototype:IterateModules()
	return pairs(self.modules)
end

function ObjectPrototype:RegisterEvent(event, handler)
	if not next(object.events[event]) then
		object.frame:RegisterEvent(event)
	end
	if type(handler) ~= "function" then
		handler = self[handler] or self[event]
	end
	object.events[event][self] = handler
end

function ObjectPrototype:UnregisterEvent(event)
	object.events[event][self] = nil
	if not next(object.events[event]) then
		object.frame:UnregisterEvent(event)
	end
end

function ObjectPrototype:SetOnUpdate(handler)
	if not next(object.onUpdates) then
		object.frame:SetScript("OnUpdate", onUpdate)
	end
	if type(handler) ~= "function" then
		handler = self[handler]
	end
	object.onUpdates[self] = handler
end

function ObjectPrototype:RemoveOnUpdate()
	object.onUpdates[self] = nil
	if not next(object.onUpdates) then
		object.frame:SetScript("OnUpdate", nil)
	end
end