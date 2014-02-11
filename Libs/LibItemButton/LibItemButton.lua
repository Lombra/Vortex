local lib = LibStub:NewLibrary("LibItemButton", 1)

if not lib then return end

local GetItemInfo = GetItemInfo

lib.callbacks = lib.callbacks or LibStub("CallbackHandler-1.0"):New(lib)

lib.frame = lib.frame or CreateFrame("Frame")
lib.frame:SetScript("OnEvent", lib.frame.Show)
lib.frame:SetScript("OnUpdate", onUpdate)
lib.frame:Hide()

lib.buttonRegistry = lib.buttonRegistry or {}

function lib:RegisterButton(button)
	self.buttonRegistry[button] = true
end

function lib:UpdateButton(button, itemID)
	self.callbacks:Fire("OnButtonUpdate", button, itemID)
end