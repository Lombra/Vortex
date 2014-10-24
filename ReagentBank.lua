local _, Vortex = ...

local ReagentBank = Vortex:NewModule("Reagent bank", {
	altUI = true,
	width = 750,
})

local ReagentBankUI = ReagentBank.ui

local bg = ReagentBankUI:CreateTexture(nil, "BACKGROUND")
bg:SetSize(256, 256)
bg:SetPoint("TOPLEFT")
bg:SetPoint("BOTTOMRIGHT")
bg:SetTexture([[Interface\BankFrame\Bank-Background]], true)
bg:SetHorizTile(true)
bg:SetVertTile(true)

local function createTexture(template)
	local texture = ReagentBankUI:CreateTexture(nil, "BORDER", template, 5)
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
		local texture = ReagentBankUI:CreateTexture(nil, "BORDER")
		texture:SetSize(cornerSize, cornerSize)
		texture:SetPoint(corner, edgeOffsets[h], edgeOffsets[v])
		texture:SetTexture([[Interface\BankFrame\CornersShadow]])
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
	local c1 = v[1]..h
	local c2 = v[2]..h
	local texture = ReagentBankUI:CreateTexture(nil, "BORDER")
	texture:SetSize(17, 256)
	texture:SetTexture([[Interface\BankFrame\VertShadow]])
	texture:SetTexCoord(texCoords[h].l, texCoords[h].r, 0, 1)
	texture:SetPoint(c1, corners[c1], c2)
	texture:SetPoint(c2, corners[c2], c1)
end

for i, v in ipairs(v) do
	local c1 = v..h[1]
	local c2 = v..h[2]
	local texture = ReagentBankUI:CreateTexture(nil, "BORDER")
	texture:SetSize(256, 17)
	texture:SetTexture([[Interface\BankFrame\HorizShadow]])
	texture:SetTexCoord(0, 1, texCoords[v].t, texCoords[v].b)
	texture:SetPoint(c1, corners[c1], c2)
	texture:SetPoint(c2, corners[c2], c1)
end

local columns = {}
local buttons = {}

do
	local NUMROWS = 7
	local NUMCOLUMNS = 7
	local NUMSUBCOLUMNS = 2
	
	for column = 1, NUMCOLUMNS do
		local texture = ReagentBankUI:CreateTexture()
		if column == 1 then
			texture:SetPoint("TOPLEFT", 12, -24)
		else
			texture:SetPoint("TOPLEFT", columns[column - 1], "TOPRIGHT", 5, 0)
		end
		texture:SetAtlas("bank-slots", true)
		local shadow = ReagentBankUI:CreateTexture(nil, "BACKGROUND")
		shadow:SetPoint("CENTER", texture)
		shadow:SetAtlas("bank-slots-shadow", true)
		columns[column] = texture
	end
	
	local SLOTOFFSETX = 49
	local SLOTOFFSETY = 44
	local id = 1
	for column = 1, NUMCOLUMNS do
		local leftOffset = 6
		for subColumn = 1, NUMSUBCOLUMNS do
			for row = 0, NUMROWS - 1 do
				local button = Vortex:CreateItemButton(ReagentBankUI)
				button:SetID(id)
				button:SetPoint("TOPLEFT", columns[column], leftOffset, -(3 + row * SLOTOFFSETY))
				buttons[id] = button
				id = id + 1
			end
			leftOffset = leftOffset + SLOTOFFSETX
		end
	end
end

function ReagentBank:OnInitialize()
	DataStore_Inventory.RegisterMessage(self, "DATASTORE_CONTAINER_UPDATED")
end

function ReagentBank:DATASTORE_CONTAINER_UPDATED(event, bagID)
	if self:HasContainer(bagID) then
		self:Refresh()
	end
end

function ReagentBank:GetItemCount(character, itemID)
	return select(4, DataStore:GetContainerItemCount(character, itemID))
end

Vortex:RegisterContainerButtons(REAGENTBANK_CONTAINER, buttons)

ReagentBank:IncludeContainer(REAGENTBANK_CONTAINER)