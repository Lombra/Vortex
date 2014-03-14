local _, Vortex = ...

local Void = Vortex:NewModule("Void storage", {
	altUI = true,
	width = 491,
})

Void:IncludeContainer("VoidStorage")

function Void:OnInitialize()
	self:RegisterEvent("PLAYER_LOGIN")
end

local function OnVoidStorageClosed(self)
	self:UnregisterEvent("VOID_STORAGE_CLOSE")
	self:UnregisterEvent("VOID_STORAGE_UPDATE")
	self:UnregisterEvent("VOID_STORAGE_CONTENTS_UPDATE")
	self:UnregisterEvent("VOID_TRANSFER_DONE")
end

local function OnVoidStorageOpened(self)
	self:Refresh()
	self:RegisterEvent("VOID_STORAGE_CLOSE", OnVoidStorageClosed)
	self:RegisterEvent("VOID_STORAGE_UPDATE", "Refresh")
	self:RegisterEvent("VOID_STORAGE_CONTENTS_UPDATE", "Refresh")
	self:RegisterEvent("VOID_TRANSFER_DONE", "Refresh")
end

function Void:PLAYER_LOGIN()
	self:RegisterEvent("VOID_STORAGE_OPEN", OnVoidStorageOpened)
end

function Void:GetItemCount(character, itemID)
	return select(3, DataStore:GetContainerItemCount(character, itemID))
end

local bg = Void.ui:CreateTexture(nil, "BACKGROUND", nil, -4)
bg:SetPoint("TOPLEFT", 3, -3)
bg:SetPoint("BOTTOMRIGHT", -3, 2)
bg:SetTexture([[Interface\VoidStorage\VoidStorage]])
bg:SetTexCoord(0.00195313, 0.47265625, 0.16601563, 0.50781250)

local buttons = {}

for i = 1, 80 do
	local button = Vortex:CreateItemButton(Void.ui)
	button:SetID(i)
	button:SetNormalTexture(nil)
	if i == 1 then
		button:SetPoint("TOPLEFT", 10, -8 - 6)
	elseif i % 8 == 1 then
		if i % 16 == 1 then
			button:SetPoint("LEFT", buttons[i - 8], "RIGHT", 14, 0)
		else
			button:SetPoint("LEFT", buttons[i - 8], "RIGHT", 7, 0)
		end
	else
		button:SetPoint("TOP", buttons[i - 1], "BOTTOM", 0, -5)
	end
	button.bg = button:CreateTexture(nil, "BACKGROUND")
	button.bg:SetSize(41, 41)
	button.bg:SetPoint("CENTER")
	button.bg:SetTexture([[Interface\VoidStorage\VoidStorage]])
	button.bg:SetTexCoord(0.66406250, 0.74414063, 0.00195313, 0.08203125)
	buttons[i] = button
end

for i = 1, 4 do
	local texture = Void.ui:CreateTexture()
	texture:SetWidth(2)
	texture:SetPoint("TOP", 0, -2)
	texture:SetPoint("BOTTOM", 0, 2)
	texture:SetPoint("LEFT", 2 + i * 95, 0)
	texture:SetTexture(0.1451, 0.0941, 0.1373, 0.8)
end

Vortex:RegisterContainerButtons("VoidStorage", buttons)