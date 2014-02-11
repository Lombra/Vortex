local addonName, addon = ...

local Bank = addon:NewModule("Bank", {
	altUI = true,
	width = 398,
})

Bank:IncludeContainer(100)
for i = 1, NUM_BANKBAGSLOTS do
	Bank:IncludeContainer(i + ITEM_INVENTORY_BANK_BAG_OFFSET)
end

function Bank:OnInitialize()
	self:RegisterEvent("PLAYER_LOGIN")
end

local function OnBankFrameClosed(self)
	self:UnregisterEvent("BANKFRAME_CLOSED")
	self:UnregisterEvent("PLAYERBANKSLOTS_CHANGED")
end

local function OnPlayerBankSlotsChanged(self, event, slotID)
	self:Refresh()
end

local function OnBankFrameOpened(self)
	self:Refresh()
	self:RegisterEvent("BANKFRAME_CLOSED", OnBankFrameClosed)
	self:RegisterEvent("PLAYERBANKSLOTS_CHANGED", OnPlayerBankSlotsChanged)
end

function Bank:PLAYER_LOGIN()
	self:RegisterEvent("BAG_UPDATE_DELAYED", "Refresh")
	self:RegisterEvent("BANKFRAME_OPENED", OnBankFrameOpened)
end

function Bank:Refresh()
	local character = DataStore:GetCharacter()
	self:ClearCache(character)
	if addon:GetSelectedModule() == self and addon:GetSelectedCharacter() == character then
		self:Update(character)
	end
end

function Bank:GetItemCount(character, itemID)
	return select(2, DataStore:GetContainerItemCount(character, itemID))
end


local BankUI = Bank.ui

local bg = BankUI:CreateTexture(nil, "BACKGROUND")
bg:SetSize(256, 256)
bg:SetPoint("TOPLEFT")
bg:SetPoint("BOTTOMRIGHT")
bg:SetTexture([[Interface\BankFrame\Bank-Background]], true)
bg:SetHorizTile(true)
bg:SetVertTile(true)

local function createTexture(template)
	local texture = BankUI:CreateTexture(nil, "BORDER", template, 5)
	texture:ClearAllPoints()
	return texture
end

local tl = createTexture("UI-Frame-InnerTopLeft")
tl:SetPoint("TOPLEFT")

local tr = createTexture("UI-Frame-InnerTopRight")
tr:SetPoint("TOPRIGHT")

local bl = createTexture("UI-Frame-InnerBotLeftCorner")
bl:SetPoint("BOTTOMLEFT", 0, -1)

local br = createTexture("UI-Frame-InnerBotRight")
br:SetPoint("BOTTOMRIGHT", 0, -1)

local t = createTexture("_UI-Frame-InnerTopTile")
t:SetPoint("TOPLEFT", tl, "TOPRIGHT")
t:SetPoint("TOPRIGHT", tr, "TOPLEFT")

local b = createTexture("_UI-Frame-InnerBotTile")
b:SetPoint("BOTTOMLEFT", bl, "BOTTOMRIGHT")
b:SetPoint("BOTTOMRIGHT", br, "BOTTOMLEFT")

local l = createTexture("!UI-Frame-InnerLeftTile")
l:SetPoint("TOPLEFT", tl, "BOTTOMLEFT")
l:SetPoint("BOTTOMLEFT", bl, "TOPLEFT")

local r = createTexture("!UI-Frame-InnerRightTile")
r:SetPoint("TOPRIGHT", tr, "BOTTOMRIGHT")
r:SetPoint("BOTTOMRIGHT", br, "TOPRIGHT")

local v = {
	"TOP",
	"BOTTOM",
}

local h = {
	"LEFT",
	"RIGHT",
}

local cornerSize = 44

local edgeOffsets = {
	LEFT = 2,
	RIGHT = -3,
	TOP = -2,
	BOTTOM = 2,
}

local texCoords = {
	TOPLEFT     = {t = 0.00390625, b = 0.17578125},
	TOPRIGHT    = {t = 0.36328125, b = 0.53515625},
	BOTTOMLEFT  = {t = 0.18359375, b = 0.35546875},
	BOTTOMRIGHT = {t = 0.54296875, b = 0.71484375},
}

local corners = {}

for i, v in ipairs(v) do
	for i, h in ipairs(h) do
		local corner = v..h
		local texture = BankUI:CreateTexture(nil, "BORDER")
		texture:SetSize(cornerSize, cornerSize)
		texture:SetPoint(corner, edgeOffsets[h], edgeOffsets[v])
		texture:SetTexture([[Interface\BankFrame\CornersShadow]])
		-- local texCoords = texCoords[corner]
		texture:SetTexCoord(0.01562500, 0.70312500, texCoords[corner].t, texCoords[corner].b)
		corners[corner] = texture
	end
end

local texCoords = {
	LEFT   = {l = 0.31250000, r = 0.57812500},
	RIGHT  = {l = 0.01562500, r = 0.28125000},
	TOP    = {t = 0.31250000, b = 0.57812500},
	BOTTOM = {t = 0.01562500, b = 0.28125000},
}

for i, h in ipairs(h) do
	local texture = BankUI:CreateTexture(nil, "BORDER")
	texture:SetSize(17, 256)
	texture:SetTexture([[Interface\BankFrame\VertShadow]])
	-- local texCoords = texCoords[corner]
	texture:SetTexCoord(texCoords[h].l, texCoords[h].r, 0, 1)
	local c1 = v[1]..h
	local c2 = v[2]..h
	texture:SetPoint(c1, corners[c1], c2)
	texture:SetPoint(c2, corners[c2], c1)
end

for i, v in ipairs(v) do
	local texture = BankUI:CreateTexture(nil, "BORDER")
	texture:SetSize(256, 17)
	texture:SetTexture([[Interface\BankFrame\HorizShadow]])
	-- local texCoords = texCoords[corner]
	texture:SetTexCoord(0, 1, texCoords[v].t, texCoords[v].b)
	local c1 = v..h[1]
	local c2 = v..h[2]
	texture:SetPoint(c1, corners[c1], c2)
	texture:SetPoint(c2, corners[c2], c1)
end

local itemSlots = BankUI:CreateFontString(nil, "BORDER", "GameFontNormal")
itemSlots:SetPoint("TOP", -3, -46)
itemSlots:SetText(ITEMSLOTTEXT)

local bagSlots = BankUI:CreateFontString(nil, "BORDER", "GameFontNormal")
bagSlots:SetPoint("TOP", -3, -246)
bagSlots:SetText(BAGSLOTTEXT)

local bankFrameItems = {}
local bankFrameBags = {}

local id, textureName = GetInventorySlotInfo("Bag1")

for i = 1, NUM_BANKGENERIC_SLOTS do
	local button = addon:CreateItemButton(BankUI)
	button:SetID(i)
	if i == 1 then
		button:SetPoint("TOPLEFT", 28, -64)
	elseif i % 7 == 1 then
		button:SetPoint("TOPLEFT", bankFrameItems[i - 7], "BOTTOMLEFT", 0, -7)
	else
		button:SetPoint("TOPLEFT", bankFrameItems[i - 1], "TOPRIGHT", 12, 0)
	end
	local texture = button:CreateTexture(nil, "BORDER", "Bank-Slot-BG", -1)
	texture:SetPoint("TOPLEFT", -6, 5)
	texture:SetPoint("BOTTOMRIGHT", 6, -7)
	bankFrameItems[i] = button
end

for i = 1, NUM_BANKBAGSLOTS do
	local button = addon:CreateBagButton(BankUI)
	button:SetID(i + ITEM_INVENTORY_BANK_BAG_OFFSET)
	button.bg = textureName
	button.tooltipText = BANK_BAG
	if i == 1 then
		button:SetPoint("TOPLEFT", bankFrameItems[1], "BOTTOMLEFT", 0, -164)
	else
		button:SetPoint("TOPLEFT", bankFrameBags[i - 1], "TOPRIGHT", 12, 0)
	end
	addon:GetContainerFrame(i + ITEM_INVENTORY_BANK_BAG_OFFSET).containerButton = button
	local texture = button:CreateTexture(nil, "BORDER", "Bank-Slot-BG", -1)
	texture:SetPoint("TOPLEFT", -6, 5)
	texture:SetPoint("BOTTOMRIGHT", 6, -7)
	bankFrameBags[i] = button
end

for i = 1, 20 do
	if i % 7 ~= 0 then
		local texture = BankUI:CreateTexture(nil, "BORDER", "Bank-Rivet")
		texture:SetPoint("TOPLEFT", bankFrameItems[i], "BOTTOMRIGHT", 0, 2)
		texture:SetPoint("BOTTOMRIGHT", bankFrameItems[i], "BOTTOMRIGHT", 12, -10)
	end
end

addon:RegisterContainerButtons(100, bankFrameItems)

function Bank:UpdateUI(character)
	addon:UpdateContainer(100, character)
	for i = 1, NUM_BANKBAGSLOTS do
		local button = bankFrameBags[i]
		local icon, link, size, freeslots = DataStore:GetContainerInfo(character, button:GetID())
		button.icon:SetTexture(icon or button.bg)
		button.item = link
		button.size = size
	end
end