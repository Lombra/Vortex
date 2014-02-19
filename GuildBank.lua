local addonName, addon = ...

local Libra = LibStub("Libra")
local LIB = LibStub("LibItemButton")

local frame = addon.frame.guild

local selectedGuild
local selectedTab

frame:SetScript("OnShow", function(self)
	local myGuild = GetGuildInfo("player")
	if not selectedGuild and myGuild and DataStore:GetGuildBankMoney(DataStore:GetGuild()) then
		addon:SelectGuild(DataStore:GetGuild())
	else
		addon:SelectGuild()
	end
end)
frame:SetScript("OnEvent", function(self, event, ...)
	self[event](self, ...)
end)

local function OnGuildBankFrameClosed(self)
	self:UnregisterEvent("GUILDBANKFRAME_CLOSED")
	self:UnregisterEvent("GUILDBANKBAGSLOTS_CHANGED")
end

local function OnGuildBankBagSlotsChanged()
	-- ScanContainer(GetCurrentGuildBankTab(), GUILDBANK)
	-- ScanGuildBankInfo()
end

local function OnGuildBankFrameOpened()
	self:RegisterEvent("GUILDBANKFRAME_CLOSED", OnGuildBankFrameClosed)
	self:RegisterEvent("GUILDBANKBAGSLOTS_CHANGED", OnGuildBankBagSlotsChanged)
	
	local thisGuild = GetThisGuild()
	if thisGuild then
		thisGuild.money = GetGuildBankMoney()
		thisGuild.faction = UnitFactionGroup("player")
	end
end

-- hooksecurefunc(addon, "OnInitialize", function(self)
	-- self:RegisterEvent("GUILDBANKFRAME_OPENED", OnGuildBankFrameOpened)
-- end)

frame.GUILDBANKFRAME_OPENED = OnGuildBankFrameOpened
frame.GUILDBANKFRAME_CLOSED = OnGuildBankFrameClosed
frame.GUILDBANKBAGSLOTS_CHANGED = OnGuildBankBagSlotsChanged

local columns = {}
local buttons = {}

for i = 1, 7 do
	local column = frame:CreateTexture(nil, "BACKGROUND", nil, 1)
	column:SetSize(100, 311)
	column:SetTexture([[Interface\GuildBankFrame\UI-GuildBankFrame-Slots]])
	column:SetTexCoord(0, 0.78125, 0, 0.607421875)
	if i == 1 then
		column:SetPoint("TOPLEFT", 18, -59)
	else
		column:SetPoint("LEFT", columns[i - 1], "RIGHT", 3, 0)
	end
	columns[i] = column
	
	local c = i - 1
	for i = 1, 14 do
		local button = addon:CreateItemButton(frame)
		if i == 1 then
			button:SetPoint("TOPLEFT", column, 7, -3)
		elseif i % 7 == 1 then
			button:SetPoint("LEFT", buttons[c * 14 + i - 7], "RIGHT", 12, 0)
		else
			button:SetPoint("TOP", buttons[c * 14 + i - 1], "BOTTOM", 0, -7)
		end
		tinsert(buttons, button)
		-- buttons[i] = button
	end
end

local titleBg = frame:CreateTexture(nil, "OVERLAY")
titleBg:SetSize(10, 18)
titleBg:SetPoint("TOP", 0, -30)
titleBg:SetTexture([[Interface\GuildBankFrame\UI-TabNameBorder]])
titleBg:SetTexCoord(0.0625, 0.546875, 0, 0.5625)

local titleBgL = frame:CreateTexture(nil, "OVERLAY")
titleBgL:SetSize(8, 18)
titleBgL:SetPoint("RIGHT", titleBg, "LEFT")
titleBgL:SetTexture([[Interface\GuildBankFrame\UI-TabNameBorder]])
titleBgL:SetTexCoord(0, 0.0625, 0, 0.5625)

local titleBgR = frame:CreateTexture(nil, "OVERLAY")
titleBgR:SetSize(8, 18)
titleBgR:SetPoint("LEFT", titleBg, "RIGHT")
titleBgR:SetTexture([[Interface\GuildBankFrame\UI-TabNameBorder]])
titleBgR:SetTexCoord(0.546875, 0.609375, 0, 0.5625)

local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
title:SetPoint("CENTER", titleBg, 0, 1)

local function createCorner(tT, tB)
	local texture = frame:CreateTexture(nil, "BORDER")
	texture:SetSize(32, 32)
	texture:SetTexture([[Interface\GuildBankFrame\Corners]])
	texture:SetTexCoord(0.01562500, 0.51562500, tT, tB)
	return texture
end

local function setPoints(texture, point1, point2, texture1, texture2, xOffset, yOffset)
	texture:SetPoint(point1, texture1, point2, xOffset, yOffset)
	texture:SetPoint(point2, texture2, point1, xOffset, yOffset)
end

local function createVertEdge(side, offset, topCorner, bottomCorner)
	local texture = frame:CreateTexture(nil, "BORDER")
	setPoints(texture, "TOP"..side, "BOTTOM"..side, topCorner, bottomCorner, offset, 0)
	texture:SetTexture([[Interface\GuildBankFrame\VertTile]])
	texture:SetVertTile(true)
	return texture
end

local function createHorizEdge(side, offset, leftCorner, rightCorner)
	local texture = frame:CreateTexture(nil, "BORDER")
	setPoints(texture, side.."LEFT", side.."RIGHT", leftCorner, rightCorner, 0, offset)
	texture:SetTexture([[Interface\GuildBankFrame\HorizTile]])
	texture:SetHorizTile(true)
	return texture
end

local blo = createCorner(0.00390625, 0.12890625)
blo:SetPoint("BOTTOMLEFT", -2, 21)

local bro = createCorner(0.13671875, 0.26171875)
bro:SetPoint("BOTTOMRIGHT", 0, 21)

local tro = createCorner(0.26953125, 0.39453125)
tro:SetPoint("TOPRIGHT", 0, -18)

local tlo = createCorner(0.40234375, 0.52734375)
tlo:SetPoint("TOPLEFT", -2, -18)

local lo = createVertEdge("LEFT", -3, tlo, blo)
local ro = createVertEdge("RIGHT", 4, tro, bro)
local to = createHorizEdge("TOP", 3, tlo, tro)
local bo = createHorizEdge("BOTTOM", -5, blo, bro)

local bli = createCorner(0.00390625, 0.12890625)
bli:SetPoint("BOTTOMLEFT", blo, 14, 28)

local bri = createCorner(0.13671875, 0.26171875)
bri:SetPoint("BOTTOMRIGHT", bro, -9, 28)

local tri = createCorner(0.26953125, 0.39453125)
tri:SetPoint("TOPRIGHT", tro, -9, -35)

local tli = createCorner(0.40234375, 0.52734375)
tli:SetPoint("TOPLEFT", tlo, 14, -35)

local li = createVertEdge("LEFT", -3, tli, bli)
local ri = createVertEdge("RIGHT", 4, tri, bri)
local ti = createHorizEdge("TOP", 3, tli, tri)
local bi = createHorizEdge("BOTTOM", -5, bli, bri)

local bg = frame:CreateTexture(nil, "BACKGROUND")
bg:SetSize(256, 256)
bg:SetPoint("TOPLEFT", 2, -20)
bg:SetPoint("BOTTOMRIGHT", -2, 20)
bg:SetTexture([[Interface\GuildBankFrame\GuildVaultBG]], true)
bg:SetHorizTile(true)
bg:SetVertTile(true)

local moneyFrameBg = CreateFrame("Frame", nil, frame, "ThinGoldEdgeTemplate")
moneyFrameBg:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", 1, 25)
moneyFrameBg:SetPoint("BOTTOMRIGHT", -4, 2)

local moneyFrame = CreateFrame("Frame", "VortexGuildBankMoneyFrame", frame, "SmallMoneyFrameTemplate")
moneyFrame:SetPoint("BOTTOMRIGHT", -2, 6)
MoneyFrame_SetType(moneyFrame, "STATIC")

local tabs = {}

local ItemInfo = addon.ItemInfo

local function Find(text)
	for i = 1, 8 do
		local tab = DataStore:GetGuildBankTab(selectedGuild, i)
		tabs[i].button.searchOverlay:Show()
		for j = 1, 98 do
			local button = buttons[j]
			local itemID, itemLink = DataStore:GetSlotInfo(tab, j)
			local item = (itemID or itemLink) and ItemInfo[itemID or itemLink]
			local match = text == "" or text == SEARCH or (item and strfind(item.name:lower(), text:lower(), nil, true))
			if i == selectedTab then
				button.searchOverlay:SetShown((itemID or itemLink) and not match)
				if (itemID or itemLink) and match then
					tabs[i].button.searchOverlay:Hide()
				end
			elseif match then
				tabs[i].button.searchOverlay:Hide()
				break
			end
		end
	end
end

local function onClick(self, guildKey)
	addon:SelectGuild(guildKey)
	CloseDropDownMenus()
end

local sortedGuilds = {}

local button = Libra:CreateDropdown(frame, true)
button:SetWidth(128)
button:SetPoint("TOPLEFT", -2, -27)
button:JustifyText("LEFT")
button.initialize = function(self, level)
	wipe(sortedGuilds)
	local guilds = DataStore:GetGuilds(UIDROPDOWNMENU_MENU_VALUE)
	for guildName, guildKey in pairs(guilds) do
		if guildKey ~= DataStore:GetGuild() then
			tinsert(sortedGuilds, guildName)
		end
	end
	sort(sortedGuilds)
	if level == 1 then
		tinsert(sortedGuilds, 1, (GetGuildInfo("player")))
	end
	for i, guildName in ipairs(sortedGuilds) do
		local guildKey = guilds[guildName]
		local info = UIDropDownMenu_CreateInfo()
		info.text = guildName
		info.func = onClick
		info.arg1 = guildKey
		info.checked = guildKey == selectedGuild
		info.disabled = not DataStore:GetGuildBankFaction(guildKey)
		UIDropDownMenu_AddButton(info, level)
	end
	if level == 1 then
		wipe(sortedGuilds)
		for realm in pairs(DataStore:GetRealms()) do
			if realm ~= GetRealmName() then
				tinsert(sortedGuilds, realm)
			end
		end
		sort(sortedGuilds)
		for i, realm in ipairs(sortedGuilds) do
			local info = UIDropDownMenu_CreateInfo()
			info.text = realm
			info.notCheckable = true
			info.hasArrow = true
			info.keepShownOnClick = true
			UIDropDownMenu_AddButton(info, level)
		end
	end
end

local function onEditFocusLost(self)
	self:SetFontObject("ChatFontSmall")
	self:SetTextColor(0.5, 0.5, 0.5)
end

local function onEditFocusGained(self)
	self:SetTextColor(1, 1, 1)
end

local searchBox = Libra:CreateEditbox(frame)
searchBox:SetSize(128, 20)
searchBox:SetPoint("TOPRIGHT", -16, -33)
searchBox:SetFontObject("ChatFontSmall")
searchBox:SetTextColor(0.5, 0.5, 0.5)
searchBox:HookScript("OnEditFocusLost", onEditFocusLost)
searchBox:HookScript("OnEditFocusGained", onEditFocusGained)
searchBox:SetScript("OnEnterPressed", EditBox_ClearFocus)
searchBox:SetScript("OnEscapePressed", function(self)
	self:SetText("")
	self:ClearFocus()
end)
searchBox:SetScript("OnTextChanged", function(self, isUserInput)
	if not isUserInput then
		return
	end
	
	Find(self:GetText())
end)

local function UpdateGuildBank()
	for i = 1, 8 do
		local tabIcon = DataStore:GetGuildBankTabIcon(selectedGuild, i)
		tabs[i].button.icon:SetTexture(tabIcon)
		tabs[i]:SetShown(tabIcon ~= nil)
	end
	local tab = DataStore:GetGuildBankTab(selectedGuild, selectedTab)
	for i = 1, 98 do
		buttons[i]:SetItem(DataStore:GetSlotInfo(tab, i))
	end
	tabs[selectedTab].button:SetChecked(true)
	title:SetText(DataStore:GetGuildBankTabName(selectedGuild, selectedTab))
	titleBg:SetWidth(title:GetWidth() + 20)
	MoneyFrame_Update(moneyFrame, DataStore:GetGuildBankMoney(selectedGuild) or 0)
	Find(searchBox:GetText())
end

function addon:SelectGuild(guild)
	if selectedTab then
		tabs[selectedTab].button:SetChecked(false)
	end
	selectedGuild = guild
	selectedTab = 1
	UpdateGuildBank()
	local accountKey, realmKey, guildKey = strsplit(".", guild or "")
	button:SetText(guildKey or "Select guild")
end

function addon:GetSelectedGuild()
	return selectedGuild
end

local function onClick(self)
	if self:GetID() ~= selectedTab then
		PlaySound("GuildBankOpenBag")
	end
	tabs[selectedTab].button:SetChecked(false)
	self:SetChecked(true)
	selectedTab = self:GetID()
	UpdateGuildBank()
end

local function onEnter(self)
	GameTooltip:SetOwner(self, "ANCHOR_LEFT")
	GameTooltip:SetText(DataStore:GetGuildBankTabName(selectedGuild, self:GetID()))--, nil, nil, nil, nil, 1)
end

for i = 1, 8 do
	local tab = CreateFrame("Frame", nil, frame)
	tab:SetSize(42, 50)
	tab:EnableMouse(true)
	tab:SetID(i)
	if i == 1 then
		tab:SetPoint("TOPLEFT", frame, "TOPRIGHT", -1, -17)
	else
		tab:SetPoint("TOP", tabs[i - 1], "BOTTOM")
	end
	tabs[i] = tab
	
	local bg = tab:CreateTexture(nil, "BACKGROUND")
	bg:SetSize(64, 64)
	bg:SetPoint("TOPLEFT")
	bg:SetTexture([[Interface\GuildBankFrame\UI-GuildBankFrame-Tab]])
	
	local tabButton = CreateFrame("CheckButton", nil, tab, "ItemButtonTemplate")
	tabButton:SetSize(36, 34)
	tabButton:SetPoint("TOPLEFT", 2, -8)
	tabButton:SetCheckedTexture([[Interface\Buttons\CheckButtonHilight]], "ADD")
	tabButton:GetNormalTexture():SetSize(60, 60)
	tabButton:SetScript("OnClick", onClick)
	tabButton:SetScript("OnEnter", onEnter)
	tabButton:SetScript("OnLeave", GameTooltip_Hide)
	tabButton:SetID(i)
	tab.button = tabButton
end