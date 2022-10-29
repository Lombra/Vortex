local _, Vortex = ...

local Void = Vortex:NewModule("Void storage", {
	altUI = true,
	width = 491,
})

local bg = Void.ui:CreateTexture(nil, "BACKGROUND", nil, -4)
bg:SetPoint("TOPLEFT", 3, -3)
bg:SetPoint("BOTTOMRIGHT", -3, 2)
bg:SetTexture([[Interface\VoidStorage\VoidStorage]])
bg:SetTexCoord(0.00195313, 0.47265625, 0.16601563, 0.50781250)

local buttons = {}

for i = 1, 80 do
	local button = Vortex:CreateItemButton(Void.ui)
	button:SetID(i)
	button:ClearNormalTexture()
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
	texture:SetColorTexture(0.1451, 0.0941, 0.1373, 0.8)
end

local selectedTab = 1

local tabs = {}

local function onClick(self)
	tabs[selectedTab]:SetChecked(false)
	tabs[self:GetID()]:SetChecked(true)
	selectedTab = self:GetID()
	Void:Update(Vortex:GetSelectedCharacter())
end

for i = 1, 2 do
	local tab = CreateFrame("CheckButton", nil, Void.ui)
	tab:SetSize(32, 32)
	if i == 1 then
		tab:SetPoint("LEFT", Vortex.frame, "TOPRIGHT", 1, -60)
	else
		tab:SetPoint("TOP", tabs[i - 1], "BOTTOM", 0, -16)
	end
	tab:SetHighlightTexture([[Interface\Buttons\ButtonHilight-Square]])
	tab:SetCheckedTexture([[Interface\Buttons\CheckButtonHilight]])
	tab:SetScript("OnClick", onClick)
	tab:SetID(i)
	
	local bg = tab:CreateTexture(nil, "BACKGROUND")
	bg:SetSize(64, 64)
	bg:SetPoint("TOPLEFT", -3, 11)
	bg:SetTexture([[Interface\SpellBook\SpellBook-SkillLineTab]])
	
	tabs[i] = tab
end

tabs[1]:SetNormalTexture([[Interface\Icons\INV_Enchant_EssenceCosmicGreater]])
tabs[2]:SetNormalTexture([[Interface\Icons\INV_Enchant_EssenceArcaneLarge]])

tabs[1]:SetChecked(true)

function Void:OnInitialize()
	DataStore_Inventory.RegisterMessage(self, "DATASTORE_VOIDSTORAGE_UPDATED", "Refresh")
end

function Void:GetItemCount(character, itemID)
	return select(3, DataStore:GetContainerItemCount(character, itemID))
end

function Void:UpdateUI(character)
	Vortex:UpdateContainer("VoidStorage.Tab"..selectedTab, character)
end

Vortex:RegisterContainerButtons("VoidStorage.Tab1", buttons)
Vortex:RegisterContainerButtons("VoidStorage.Tab2", buttons)

Void:IncludeContainer("VoidStorage.Tab1")
Void:IncludeContainer("VoidStorage.Tab2")