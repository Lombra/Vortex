local addonName, Vortex = ...

local LIB = LibStub("LibItemButton")

local myRealm = GetRealmName()

local ItemInfo = Vortex.ItemInfo

local guildTab = Vortex.frame:CreateTab()
guildTab:SetText(GUILD_BANK)
guildTab.frame = CreateFrame("Frame", nil, Vortex.frame)
guildTab.frame:SetAllPoints()
guildTab.frame:Hide()
guildTab.frame.width = 750
guildTab.frame.extraWidth = 43
Vortex.frame.guild = guildTab.frame

local frame = guildTab.frame

local selectedGuild
local selectedTab

frame:SetScript("OnShow", function(self)
	local myGuild = GetGuildInfo("player") and DataStore:GetGuild()
	Vortex:SelectGuild(DataStore:GetGuildBankMoney(myGuild) and myGuild)
	self:SetScript("OnShow", nil)
end)
frame:SetScript("OnEvent", function(self, event, ...)
	self[event](self, ...)
end)

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
		local button = Vortex:CreateItemButton(frame)
		if i == 1 then
			button:SetPoint("TOPLEFT", column, 7, -3)
		elseif i % 7 == 1 then
			button:SetPoint("LEFT", buttons[c * 14 + i - 7], "RIGHT", 12, 0)
		else
			button:SetPoint("TOP", buttons[c * 14 + i - 1], "BOTTOM", 0, -7)
		end
		tinsert(buttons, button)
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

local blackBG = frame:CreateTexture(nil, "BACKGROUND", nil, 1)
blackBG:SetPoint("TOPLEFT", tli, 4, -4)
blackBG:SetPoint("BOTTOMRIGHT", bri, -4, 3)
blackBG:SetTexture(0, 0, 0)

local moneyFrameBg = CreateFrame("Frame", nil, frame, "ThinGoldEdgeTemplate")
moneyFrameBg:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", 1, 25)
moneyFrameBg:SetPoint("BOTTOMRIGHT", -4, 2)

local moneyFrame = CreateFrame("Frame", "VortexGuildBankMoneyFrame", frame, "SmallMoneyFrameTemplate")
moneyFrame:SetPoint("BOTTOMRIGHT", -2, 6)
MoneyFrame_SetType(moneyFrame, "STATIC")

local tabs = {}

local function onClick(self)
	if self:GetID() ~= selectedTab then
		PlaySound("GuildBankOpenBag")
	end
	tabs[selectedTab].button:SetChecked(false)
	self:SetChecked(true)
	selectedTab = self:GetID()
	Vortex:UpdateGuildBank()
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

local function onClick(self, guildKey)
	Vortex:SelectGuild(guildKey)
	CloseDropDownMenus()
end

local guildMenu = Vortex:CreateDropdown("Frame", frame)
guildMenu:SetWidth(160)
guildMenu:SetPoint("TOPLEFT", -2, -27)
guildMenu:JustifyText("LEFT")
guildMenu.initialize = function(self, level)
	for i, guildKey in ipairs(Vortex:GetGuilds(UIDROPDOWNMENU_MENU_VALUE)) do
		local accountKey, realm, guildName = strsplit(".", guildKey)
		local info = UIDropDownMenu_CreateInfo()
		if Vortex:IsConnectedRealm(realm) then
			info.text = guildName.." - "..realm
		else
			info.text = guildName
		end
		info.func = onClick
		info.arg1 = guildKey
		info.checked = (guildKey == selectedGuild)
		info.disabled = not DataStore:GetGuildBankFaction(guildKey)
		UIDropDownMenu_AddButton(info, level)
	end
	if level == 1 then
		local sortedRealms = {}
		for realm in pairs(DataStore:GetRealms()) do
			if not (realm == myRealm or Vortex:IsConnectedRealm(realm)) and #Vortex:GetGuilds(realm) > 0 then
				tinsert(sortedRealms, realm)
			end
		end
		sort(sortedRealms)
		for i, realm in ipairs(sortedRealms) do
			local info = UIDropDownMenu_CreateInfo()
			info.text = realm
			info.notCheckable = true
			info.hasArrow = true
			info.keepShownOnClick = true
			UIDropDownMenu_AddButton(info, level)
		end
	end
end

local function filterItems(text)
	for i, tabButton in ipairs(tabs) do
		local tab = DataStore:GetGuildBankTab(selectedGuild, i)
		local tabOverlay = tabButton.button.searchOverlay
		tabOverlay:Show()
		if tab then
			for j, button in ipairs(buttons) do
				local itemID, itemLink = DataStore:GetSlotInfo(tab, j)
				local item = (itemID or itemLink) and ItemInfo[itemID or itemLink]
				local match = text == "" or (item and strfind(item.name:lower(), text:lower(), nil, true))
				if i == selectedTab then
					button.searchOverlay:SetShown((itemID or itemLink) and not match)
					if ((itemID or itemLink) and match) or text == "" then
						tabOverlay:Hide()
					end
				elseif match then
					-- while searching inactive tabs we only need to know if *any* item in that tab is a match
					tabOverlay:Hide()
					break
				end
			end
		end
	end
end

local searchBox = Vortex:CreateEditbox(frame, true)
searchBox:SetWidth(128)
searchBox:SetPoint("TOPRIGHT", -16, -33)
searchBox:SetScript("OnEscapePressed", function(self)
	self:ClearFocus()
	self:SetText("")
end)
searchBox:HookScript("OnTextChanged", function(self, isUserInput)
	filterItems(self:GetText())
end)

function Vortex:SelectGuild(guild)
	if selectedTab then
		tabs[selectedTab].button:SetChecked(false)
	end
	selectedGuild = guild
	selectedTab = 1
	self:UpdateGuildBank()
	local account, realm, guildKey = strsplit(".", guild or "")
	if guildKey and realm ~= myRealm then
		guildKey = guildKey.." - "..realm
	end
	guildMenu:SetText(guildKey or "Select guild")
end

function Vortex:GetSelectedGuild()
	return selectedGuild
end

function Vortex:UpdateGuildBank()
	local hasSelectedGuild = (selectedGuild ~= nil)
	for i, tabButton in ipairs(tabs) do
		local tabIcon = DataStore:GetGuildBankTabIcon(selectedGuild, i)
		tabButton.button.icon:SetTexture(tabIcon)
		tabButton:SetShown(tabIcon ~= nil)
	end
	local tab = DataStore:GetGuildBankTab(selectedGuild, selectedTab)
	for i, itemButton in ipairs(buttons) do
		if tab then
			itemButton:SetItem(DataStore:GetSlotInfo(tab, i))
		end
		itemButton:SetShown(hasSelectedGuild)
	end
	tabs[selectedTab].button:SetChecked(true)
	title:SetText(DataStore:GetGuildBankTabName(selectedGuild, selectedTab))
	titleBg:SetWidth(title:GetWidth() + 20)
	titleBg:SetShown(hasSelectedGuild)
	titleBgL:SetShown(hasSelectedGuild)
	titleBgR:SetShown(hasSelectedGuild)
	for i, v in ipairs(columns) do
		v:SetShown(hasSelectedGuild)
	end
	MoneyFrame_Update(moneyFrame, DataStore:GetGuildBankMoney(selectedGuild) or 0)
	filterItems(searchBox:GetText())
end