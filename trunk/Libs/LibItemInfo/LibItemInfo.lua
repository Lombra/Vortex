local lib = LibStub:NewLibrary("LibItemInfo", 1)

if not lib then return end

local GetItemInfo = GetItemInfo

lib.callbacks = lib.callbacks or LibStub("CallbackHandler-1.0"):New(lib)

lib.cache = lib.cache or {}
lib.queue = lib.queue or {}

setmetatable(lib, {__index = lib.cache})

local function onUpdate(self)
	for itemID in pairs(lib.queue) do
		if lib.cache[itemID] then
			lib.callbacks:Fire("GetItemInfoReceived", itemID)
			lib.queue[itemID] = nil
		end
	end
	lib.callbacks:Fire("GetItemInfoReceivedAll")
	if not next(lib.queue) then
		self:UnregisterEvent("GET_ITEM_INFO_RECEIVED")
		self:Hide()
	end
end

lib.frame = lib.frame or CreateFrame("Frame")
lib.frame:SetScript("OnEvent", lib.frame.Show)
lib.frame:SetScript("OnUpdate", onUpdate)
lib.frame:Hide()

setmetatable(lib.cache, {
	__index = function(self, itemID)
		if type(itemID) == "string" then
			local itemID2 = itemID
			itemID = strmatch(itemID, "item:(%d+)")
			if not itemID then return end
			itemID = tonumber(itemID)
			if rawget(self, itemID) then
				self[itemID2] = self[itemID]
				return self[itemID]
			end
		end
		local name, link, quality, itemLevel, reqLevel, class, subclass, maxStack, equipSlot, texture, vendorPrice = GetItemInfo(itemID)
		if not name then
			lib.queue[itemID] = true
			lib.frame:RegisterEvent("GET_ITEM_INFO_RECEIVED")
			return
		end
		local item = {
			name = name,
			quality = quality,
			itemLevel = itemLevel,
			reqLevel = requiredLevel,
			type = subclass,
			slot = equipSlot,
			stackSize = maxStack,
		}
		self[itemID] = item
		return item
	end,
})