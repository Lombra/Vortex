local addonName, addon = ...

local Character = addon:NewModule("Character", {
	altUI = true,
})

function Character:OnInitialize()
	self:RegisterEvent("PLAYER_LOGIN")
end

function Character:PLAYER_LOGIN()
	self:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
end

function Character:PLAYER_EQUIPMENT_CHANGED()
	local character = DataStore:GetCharacter()
	self:ClearCache(character)
	if addon:GetSelectedModule() == self and addon:GetSelectedCharacter() == character then
		self:Update(character)
	end
end

function Character:BuildList(character)
	local list = {}
	local inventory = DataStore:GetInventory(character)
	for k, item in pairs(inventory) do
		local itemID = item
		local itemLink
		if type(item) == "string" then
			itemID = tonumber(item:match("item:(%d+)"))
			itemLink = item
		end
		tinsert(list, {
			id = itemID,
			link = itemLink,
		})
	end
	return list
end

function Character:GetItemCount(character, itemID)
	return DataStore:GetInventoryItemCount(character, itemID)
end

local CharacterUI = Character.ui

local slots = {
	"HeadSlot",
	"NeckSlot",
	"ShoulderSlot",
	"BackSlot",
	"ChestSlot",
	"ShirtSlot",
	"TabardSlot",
	"WristSlot",
	"HandsSlot",
	"WaistSlot",
	"LegsSlot",
	"FeetSlot",
	"Finger0Slot",
	"Finger1Slot",
	"Trinket0Slot",
	"Trinket1Slot",
	"MainHandSlot",
	"SecondaryHandSlot",
}

local modelFrame = CreateFrame("Frame", nil, CharacterUI)
modelFrame:SetSize(231, 320)
modelFrame:SetPoint("TOPLEFT", 48, -6)
CharacterUI.modelFrame = modelFrame

local function createTexture(template)
	local texture = modelFrame:CreateTexture(nil, "OVERLAY", template)
	texture:ClearAllPoints()
	return texture
end

local tl = createTexture("Char-Corner-UpperLeft")
tl:SetPoint("TOPLEFT", CharacterUI, 46, -4)

local tr = createTexture("Char-Corner-UpperRight")
tr:SetPoint("TOPRIGHT", CharacterUI, -47, -4)

local bl = createTexture("Char-Corner-LowerLeft")
bl:SetPoint("BOTTOMLEFT", CharacterUI, 46, 29)

local br = createTexture("Char-Corner-LowerRight")
br:SetPoint("BOTTOMRIGHT", CharacterUI, -47, 29)

local l = createTexture("Char-Inner-Left")
l:SetPoint("TOPLEFT", tl, "BOTTOMLEFT", -1, 0)
l:SetPoint("BOTTOMLEFT", bl, "TOPLEFT", -1, 0)

local r = createTexture("Char-Inner-Right")
r:SetPoint("TOPRIGHT", tr, "BOTTOMRIGHT", 1, 0)
r:SetPoint("BOTTOMRIGHT", br, "TOPRIGHT", 1, 0)

local t = createTexture("Char-Inner-Top")
t:SetPoint("TOPLEFT", tl, "TOPRIGHT", 0, 1)
t:SetPoint("TOPRIGHT", tr, "TOPLEFT", 0, 1)

local b = createTexture("Char-Inner-Bottom")
b:SetPoint("BOTTOMLEFT", bl, "BOTTOMRIGHT", 0, -1)
b:SetPoint("BOTTOMRIGHT", br, "BOTTOMLEFT", 0, -1)

local b = createTexture("Char-Inner-Bottom")
b:SetPoint("BOTTOMLEFT", CharacterUI, 0, 25)
b:SetPoint("BOTTOMRIGHT", CharacterUI, 0, 25)

local itemsFrame = CreateFrame("Frame", nil, CharacterUI)
itemsFrame:SetAllPoints()

local buttons = {}

for i, slot in ipairs(slots) do
	local id, textureName = GetInventorySlotInfo(slot)
	local button = addon:CreateItemButton(itemsFrame)
	button:SetID(id)
	button.bg = textureName
	button.tooltipText = _G[strupper(slot)]
	if i == 1 then
		button:SetPoint("TOPLEFT", 4, -2)
	elseif i == 9 then
		button:SetPoint("TOPRIGHT", -4, -2)
	elseif i == 17 then
		button:SetPoint("BOTTOMLEFT", 130, 16)
		button.bg2 = button:CreateTexture(nil, "BACKGROUND", "Char-Slot-Bottom-Left")
		button.bg2:ClearAllPoints()
		button.bg2:SetPoint("TOPRIGHT", button, "TOPLEFT", -4, 8)
	elseif i == 18 then
		button:SetPoint("LEFT", buttons[17], "RIGHT", 5, 0)
		button.bg2 = button:CreateTexture(nil, "BACKGROUND", "Char-Slot-Bottom-Right")
		button.bg2:ClearAllPoints()
		button.bg2:SetPoint("TOPLEFT", button, "TOPRIGHT", 1, 8)
	else
		button:SetPoint("TOP", buttons[i - 1], "BOTTOM", 0, -4)
	end
	if i <= 8 then
		button.bg1 = button:CreateTexture(nil, "BACKGROUND", "Char-LeftSlot", -1)
		button.bg1:ClearAllPoints()
		button.bg1:SetPoint("TOPLEFT", -4, 0)
	elseif i <= 16 then
		button.bg1 = button:CreateTexture(nil, "BACKGROUND", "Char-RightSlot", -1)
		button.bg1:ClearAllPoints()
		button.bg1:SetPoint("TOPRIGHT", 4, 0)
	else
		button.bg1 = button:CreateTexture(nil, "BACKGROUND", "Char-BottomSlot", -1)
		button.bg1:ClearAllPoints()
		button.bg1:SetPoint("TOPLEFT", -4, 8)
	end
	buttons[i] = button
end

local bankFrameBags = {}

local id, textureName = GetInventorySlotInfo("Bag1")

for i = 0, 4 do
	local button = addon:CreateBagButton(modelFrame)
	button:SetID(i)
	button.bg = textureName
	-- button.tooltipText = BANK_BAG
	if i == 0 then
		button:SetPoint("BOTTOMRIGHT", -12, 36)
	else
		button:SetPoint("TOPRIGHT", bankFrameBags[i - 1], "TOPLEFT", -6, 0)
	end
	addon:GetContainerFrame(i).containerButton = button
	local texture = button:CreateTexture(nil, "BORDER", "Bank-Slot-BG", -1)
	texture:SetPoint("TOPLEFT", -6, 5)
	texture:SetPoint("BOTTOMRIGHT", 6, -7)
	bankFrameBags[i] = button
end

bankFrameBags[0].tooltipText = BACKPACK_TOOLTIP

function Character:UpdateUI(character)
	for i, button in ipairs(buttons) do
		button:SetItem(DataStore:GetInventoryItem(character, button:GetID()))
	end
	for i = 0, 4 do
		local button = bankFrameBags[i]
		local icon, link, size, freeslots = DataStore:GetContainerInfo(character, button:GetID())
		button.icon:SetTexture(icon or button.bg)
		button.item = link
		button.size = size
	end
end

function Character:uiSearch(text)
	local character = addon:GetSelectedCharacter()
	for i, button in ipairs(buttons) do
		local item = DataStore:GetInventoryItem(character, button:GetID())
		local hasItem = (item ~= nil)
		local item = item and addon.ItemInfo[item]
		local match = not text or (item and strfind(item.name:lower(), text:lower(), nil, true))
		button.searchOverlay:SetShown(item and not match)
	end
end