local addonName, Vortex = ...

local LII = LibStub("LibItemInfo-1.0")
local LIB = LibStub("LibItemButton")
local LBI = LibStub("LibBabble-Inventory-3.0"):GetUnstrictLookupTable()

local myRealm = GetRealmName()

local t = {
	["Bows"] = "Bow",
	["Crossbows"] = "Crossbow",
	["Daggers"] = "Dagger",
	["Fist Weapons"] = "Fist Weapon",
	["Guns"] = "Gun",
	["One-Handed Axes"] = "Axe",
	["One-Handed Maces"] = "Mace",
	["One-Handed Swords"] = "Sword",
	["Polearms"] = "Polearm",
	["Shields"] = "Shield",
	["Staves"] = "Staff",
	["Two-Handed Axes"] = "Axe",
	["Two-Handed Maces"] = "Mace",
	["Two-Handed Swords"] = "Sword",
	["Wands"] = "Wand",
}

local weaponTypes = {}

for k, v in pairs(t) do
	weaponTypes[LBI[k]] = LBI[v]
end

-- do not display an armor type for items that go into these slots
local noArmor = {
	INVTYPE_BODY = true,
	INVTYPE_CLOAK = true,
	INVTYPE_FINGER = true,
	INVTYPE_HOLDABLE = true,
	INVTYPE_NECK = true,
	INVTYPE_TABARD = true,
	INVTYPE_TRINKET = true,
}

-- do not display a slot for items of these types
local noSlot = {
	[LBI["Polearms"]] = true,
	[LBI["Staves"]] = true,
	[LBI["Wands"]] = true,
	[LBI["Guns"]] = true,
	[LBI["Crossbows"]] = true,
	[LBI["Bows"]] = true,
	[LBI["Shields"]] = true,
}

local noType = {
	[LBI["Junk"]] = true,
	[LBI["Miscellaneous"]] = true,
	[LBI["Other"]] = true,
}

local yesType = {
	[LBI["Consumable"]] = true,
	[LBI["Gem"]] = true,
	[LBI["Trade Goods"]] = true,
}

local LIST_PANEL_WIDTH = 128 - PANEL_INSET_RIGHT_OFFSET

local frame = Vortex:CreateUIPanel("VortexFrame")
Vortex.frame = frame
frame:SetWidth(PANEL_DEFAULT_WIDTH + LIST_PANEL_WIDTH)
frame:SetPoint("CENTER")
frame:SetToplevel(true)
frame:EnableMouse(true)
frame:HidePortrait()
frame:HideButtonBar()
frame:SetTitleText("Vortex")
frame:SetScript("OnShow", function(self)
	PlaySound(SOUNDKIT.IG_CHARACTER_INFO_OPEN)
	if not self:GetSelectedTab() then
		Vortex:SelectModule(Vortex.db.defaultModule)
		self:SelectTab(1)
	end
end)
frame:SetScript("OnHide", function(self)
	PlaySound(SOUNDKIT.IG_CHARACTER_INFO_CLOSE)
	Vortex:CloseAllContainers()
end)

frame.Inset:SetPoint("TOPLEFT", PANEL_INSET_LEFT_OFFSET + LIST_PANEL_WIDTH, PANEL_INSET_ATTIC_OFFSET)

local inset = CreateFrame("Frame", nil, frame, "InsetFrameTemplate")
inset:SetPoint("TOPLEFT", PANEL_INSET_LEFT_OFFSET, PANEL_INSET_ATTIC_OFFSET)
inset:SetPoint("BOTTOM", 0, PANEL_INSET_BOTTOM_OFFSET + 2)
inset:SetPoint("RIGHT", frame.Inset, "LEFT", PANEL_INSET_RIGHT_OFFSET, 0)

frame.list = CreateFrame("Frame", nil, frame.Inset)
frame.list:SetAllPoints()

frame.ui = CreateFrame("Frame", nil, frame.Inset)
frame.ui:SetAllPoints()

function frame:OnTabSelected(id)
	local frame = self.tabs[id].frame
	frame:Show()
	local module = Vortex:GetSelectedModule()
	Vortex.frame:SetWidth(frame.width or (not Vortex.db.useListView and module.altUI and module.width or PANEL_DEFAULT_WIDTH) + LIST_PANEL_WIDTH)
	Vortex.frame:SetAttribute("UIPanelLayout-extraWidth", frame.extraWidth)
	UpdateUIPanelPositions(Vortex.frame)
end

function frame:OnTabDeselected(id)
	self.tabs[id].frame:Hide()
end

local characterTab = frame:CreateTab()
characterTab:SetText("Character")
characterTab.frame = frame.Inset
inset:SetParent(characterTab.frame)
frame.character = characterTab.frame

local function onClick(self)
	if self.module ~= Vortex:GetSelectedModule().name or Vortex:IsSearching() then
		Vortex:ClearSearch()
		Vortex:SelectModule(self.module)
	end
end

local buttons = {}

function Vortex:CreateUI(name, label)
	local button = CreateFrame("Button", nil, inset)
	button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	button:SetHighlightTexture([[Interface\QuestFrame\UI-QuestTitleHighlight]])
	button.highlight = button:GetHighlightTexture()
	
	button:SetHeight(18)
	button:SetPoint("RIGHT", -5, 0)
	button:SetScript("OnClick", onClick)
	button:SetPushedTextOffset(0, 0)
	
	button.label = button:CreateFontString(nil, nil, "GameFontHighlightLeft")
	button.label:SetPoint("LEFT", 11, 0)
	button:SetFontString(button.label)
	button.module = name
	button:SetText(label or name)
	self:GetModule(name).button = button
	
	local i = #buttons + 1
	if i == 1 then
		button:SetPoint("TOPLEFT", 1+4, -2-4)
	else
		button:SetPoint("TOPLEFT", buttons[i - 1], "BOTTOMLEFT", 0, -1)
	end
	buttons[i] = button
end

function Vortex:GetSelectedFrame()
	local tab = frame:GetSelectedTab()
	return tab and frame.tabs[tab].frame
end

local objectTypes = {
	battlepet = function(link)
		local _, speciesID, level, breedQuality, maxHealth, power, speed, battlePetID = strsplit(":", link)
		local name, icon, petType = C_PetJournal.GetPetInfoBySpeciesID(speciesID)
		return {
			name = name,
			quality = tonumber(breedQuality),
			icon = icon,
		}
	end,
}

function Vortex:AddObjectType(objectType, func)
	objectTypes[objectType] = func
end

local ItemInfo = setmetatable({}, {
	__index = function(self, objectID)
		if type(objectID) == "string" and not strmatch(objectID, "item:%d+") then
			for objectType, func in pairs(objectTypes) do
				if strmatch(objectID, objectType..":%d+") then
					local object = func(objectID)
					self[objectID] = object
					return object
				end
			end
		end
		
		local object = LII[objectID]
		self[objectID] = object
		return object
	end
})
Vortex.ItemInfo = ItemInfo

local doUpdateList
local doUpdateUI

LII.RegisterCallback(Vortex, "OnItemInfoReceivedBatch", function()
	if doUpdateList then
		doUpdateList = nil
		-- Vortex:UpdateList()
		Vortex:ApplyFilters()
	end
	if doUpdateUI then
		doUpdateUI = nil
		local module = Vortex:GetSelectedModule()
		if module.uiSearch then
			module:uiSearch(Vortex:GetFilter("name"))
		end
	end
end)

local tooltip = CreateFrame("GameTooltip")
tooltip.rows = {}
for i = 1, 4 do
	local L, R = tooltip:CreateFontString(), tooltip:CreateFontString()
	tooltip:AddFontStrings(L, R)
	tooltip.rows[i] = L
end

local bindPickupStrings = {
	[ITEM_BIND_ON_PICKUP] = true, --"Binds when picked up"
	[ITEM_BIND_QUEST] = true, -- "Quest Item"
}

local function isSoulboundItem(item)
    tooltip:SetOwner(UIParent, "ANCHOR_NONE")
    tooltip:SetItemByID(item)
	for i = 1, #tooltip.rows do
		if bindPickupStrings[tooltip.rows[i]:GetText()] then
			return true
		end
	end
	return false
end

local bindAccountStrings = {
	[ITEM_BIND_TO_ACCOUNT] = true, --"Binds to account"
	[ITEM_BIND_TO_BNETACCOUNT] = true, -- "Binds to Battle.net account"
}

local function isBNetBoundItem(item)
    tooltip:SetOwner(UIParent, "ANCHOR_NONE")
    tooltip:SetItemByID(item)
	for i = 1, #tooltip.rows do
		if bindAccountStrings[tooltip.rows[i]:GetText()] then
			return true
		end
	end
	return false
end

local TOOLTIP_LINE_CHARACTER = "|cffffffff%d|r %s %s"
local TOOLTIP_LINE_CHARACTER_REALM = "|cffffffff%d|r %s - %s %s"
local TOOLTIP_LINE_GUILD = "|cffffffff%d|r |cff56a3ff<%s>"
local TOOLTIP_LINE_GUILD_REALM = "|cffffffff%d|r |cff56a3ff<%s> - %s"

local function getItem(tooltip, item, realm)
	local realmTotal = 0
	local realmNumChars = 0
	for i, character in ipairs(Vortex:GetCharacters(realm)) do
		local _, realm, charKey = strsplit(".", character)
		local where = "("
		local count = 0
		for i, module in Vortex:IterateModules() do
			if module.items then
				local moduleCount = module:GetItemCount(character, item) or 0
				if moduleCount > 0 then
					count = count + moduleCount
					where = format("%s%d %s, ", where, moduleCount, module.name)
				end
			end
		end
		if count > 0 then
			where = gsub(where, ", $", ")")
			if realm ~= myRealm then
				tooltip:AddLine(format(TOOLTIP_LINE_CHARACTER_REALM, count, charKey, realm, where))
			else
				tooltip:AddLine(format(TOOLTIP_LINE_CHARACTER, count, charKey, where))
			end
			realmNumChars = realmNumChars + 1
		end
		realmTotal = realmTotal + count
	end
	return realmTotal, realmNumChars
end

local tooltipInfoAdded

GameTooltip:HookScript("OnTooltipSetItem", function(self)
	if tooltipInfoAdded then
		return
	end
	if not Vortex.db.tooltip then
		return
	end
	if Vortex.db.tooltipModifier and not IsModifierKeyDown() then
		return
	end
	tooltipInfoAdded = true
	local itemName, itemLink = self:GetItem()
	local itemID = itemLink and tonumber(itemLink:match("item:(%d+)"))
	if not itemID then return end
	-- don't add tooltip info for unstackable soulbound items
	if (not ItemInfo[itemID] or ItemInfo[itemID].stackSize == 1) and isSoulboundItem(itemID) then
		return
	end
	local total, numChars = getItem(self, itemID)
	if Vortex.db.tooltipBNet and isBNetBoundItem(itemID) then
		for realm in pairs(DataStore:GetRealms()) do
			if not (realm == myRealm or Vortex:IsConnectedRealm(realm)) then
				local realmTotal, realmNumChars = getItem(self, itemID, realm)
				total = total + realmTotal
				numChars = numChars + realmNumChars
			end
		end
	end
	if Vortex.db.tooltipGuild then
		for i, guildKey in ipairs(Vortex:GetGuilds()) do
			local account, realm, guildName = strsplit(".", guildKey)
			local count = DataStore:GetGuildBankItemCount(guildKey, itemID)
			if count > 0 then
				if realm ~= myRealm then
					self:AddLine(format(TOOLTIP_LINE_GUILD_REALM, count, guildName, realm))
				else
					self:AddLine(format(TOOLTIP_LINE_GUILD, count, guildName))
				end
				numChars = numChars + 1
			end
			total = total + count
		end
	end
	-- don't bother displaying total amount if only one character has it
	if numChars > 1 then
		self:AddLine("Total: |cffffffff"..total)
	end
end)

GameTooltip:HookScript("OnTooltipCleared", function(self)
	tooltipInfoAdded = nil
end)

local onTooltipAddMoney = GameTooltip_OnTooltipAddMoney

function GameTooltip_OnTooltipAddMoney(self, cost, maxcost)
	if not maxcost and self.stackSize then
		cost = cost * self.stackSize
	end
	onTooltipAddMoney(self, cost, maxcost)
end

local bagFrames = {}
local containerButtons = {}

local itemButtonMethods = {
	SetItem = function(self, itemID, itemLink, count)
		self.item = itemLink or itemID
		self.icon:SetTexture(GetItemIcon(itemID) or self.bg)
		-- self.icon:SetShown(itemID ~= nil)
		if count and count > 1 then
			self.Count:SetText(count)
			self.Count:Show()
			self.stackSize = count
		else
			self.Count:Hide()
			self.stackSize = nil
		end
		LIB:UpdateButton(self, itemID)
	end,
	
	OnClick = function(self, button)
		if self.isBag then
			self:SetChecked(false)
		end
		if self.isBag then
			local bagID = self:GetID()
			if not self.item and bagID ~= 0 then return end
			local bag = bagFrames[bagID]
			local isOpen = Vortex:IsBagOpen(bagID)
			if isOpen then
				bag:Hide()
			else
				-- use the ID of a regular bag for the backpack so it doesn't have the extra stuff
				ContainerFrame_GenerateFrame(bag, self.size, bagID == 0 and 1 or bagID)
				bag:SetID(bagID)
				bag.PortraitButton:SetID(bagID)
				local icon, link, size = DataStore:GetContainerInfo(Vortex:GetSelectedCharacter(), bagID)
				bag:SetTitle(link and GetItemInfo(link) or BACKPACK_TOOLTIP)
				bag:SetPortraitTextureRaw(icon)
				Vortex:UpdateContainer(bagID, Vortex:GetSelectedCharacter())
			end
			self:SetChecked(not isOpen)
		elseif self.item then
			local link = self.item
			if type(link) == "number" or link:match("item:%d+") then
				link = select(2, GetItemInfo(self.item))
			end
			HandleModifiedItemClick(link)
		end
	end,

	OnUpdate = function(self)
		if GameTooltip:IsOwned(self) then
			if IsModifiedClick("COMPAREITEMS") or (GetCVarBool("alwaysCompareItems") and not IsEquippedItem(self.item)) then
				GameTooltip_ShowCompareItem()
			else
				ShoppingTooltip1:Hide()
				ShoppingTooltip2:Hide()
			end

			if IsModifiedClick("DRESSUP") then
				ShowInspectCursor()
			else
				ResetCursor()
			end
		end
	end,

	OnEnter = function(self)
		GameTooltip:SetOwner(self, self.anchor or "ANCHOR_RIGHT", self.x, self.y)
		if self.item then
			GameTooltip.stackSize = self.stackSize
			if type(self.item) == "string" and self.item:match("battlepet:%d+") then
				local _, speciesID, level, breedQuality, maxHealth, power, speed, battlePetID = strsplit(":", self.item)
				BattlePetToolTip_Show(tonumber(speciesID), tonumber(level), tonumber(breedQuality), tonumber(maxHealth), tonumber(power), tonumber(speed))
			else
				if type(self.item) == "number" then
					GameTooltip:SetItemByID(self.item)
				else
					GameTooltip:SetHyperlink(self.item)
				end
			end
			if self.PostEnter then
				self:PostEnter()
			end
			if IsModifiedClick("DRESSUP") then
				ShowInspectCursor()
			end
			self:SetScript("OnUpdate", self.OnUpdate)
		elseif self.tooltipText then
			GameTooltip:SetText(self.tooltipText)
		end
	end,

	OnLeave = function(self)
		GameTooltip:Hide()
		GameTooltip.stackSize = nil
		ResetCursor()
		self:SetScript("OnUpdate", nil)
	end,
}

function Vortex:SetupItemButton(button)
	for k, v in pairs(itemButtonMethods) do
		button[k] = v
	end
	button:SetScript("OnClick", button.OnClick)
	button:SetScript("OnEnter", button.OnEnter)
	button:SetScript("OnLeave", button.OnLeave)
	button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	button.UpdateTooltip = button.OnEnter
	LIB:RegisterButton(button)
end

function Vortex:CreateItemButton(parent)
	local button = CreateFrame("ItemButton", nil, parent)
	self:SetupItemButton(button)
	return button
end

local function setChecked(self, checked)
	self.checkedTexture:SetShown(checked)
end

function Vortex:CreateBagButton(parent)
	local button = CreateFrame("ItemButton", nil, parent)
	button.SetChecked = setChecked
	button.checkedTexture = button:CreateTexture(nil, "OVERLAY")
	button.checkedTexture:SetTexture([[Interface\Buttons\CheckButtonHilight]])
	button.checkedTexture:SetBlendMode("ADD")
	button.checkedTexture:SetAllPoints()
	button.checkedTexture:Hide()
	button.isBag = true
	self:SetupItemButton(button)
	return button
end

function Vortex:UpdateContainer(container, character)
	local bag = DataStore:GetContainer(character, container)
	for i, button in ipairs(self:GetContainerButtons(container)) do
		button:SetItem(DataStore:GetSlotInfo(bag, button:GetID()))
	end
end

function Vortex:RegisterContainerButtons(container, buttons)
	containerButtons[container] = buttons
end

function Vortex:GetContainerButtons(container)
	return containerButtons[container]
end

function Vortex:GetContainerFrame(id)
	return bagFrames[id]
end

function Vortex:IsBagOpen(id)
	return bagFrames[id]:IsShown()
end

function Vortex:CloseAllContainers()
	for i, frame in pairs(bagFrames) do
		frame:Hide()
	end
end

local function onEnter(self)
	GameTooltip:SetOwner(self, "ANCHOR_LEFT")
	if self:GetID() == 0 then
		GameTooltip:SetText(BACKPACK_TOOLTIP, 1.0, 1.0, 1.0)
	else
		local icon, link, size, freeslots = DataStore:GetContainerInfo(Vortex:GetSelectedCharacter(), self:GetID())
		GameTooltip:SetHyperlink(link)
	end
end

local function onShow(self)
	ContainerFrame1.bags[ContainerFrame1.bagsShown + 1] = self:GetName()
	ContainerFrame1.bagsShown = ContainerFrame1.bagsShown + 1
	PlaySound(SOUNDKIT.IG_BACKPACK_OPEN)
	UpdateContainerFrameAnchors()
	-- Vortex:SearchContainer(self:GetID())
end

local function onHide(self)
	ContainerFrame1.bagsShown = ContainerFrame1.bagsShown - 1
	-- Remove the closed bag from the list and collapse the rest of the entries
	tDeleteItem(ContainerFrame1.bags, self:GetName())
	UpdateContainerFrameAnchors()
	PlaySound(SOUNDKIT.IG_BACKPACK_CLOSE)
	self.containerButton:SetChecked(false)
end

-- create backpack and bank bag frames
for i = 0, 11 do
	local frameName = "VortexContainerFrame"..i
	local bag = CreateFrame("Frame", frameName, UIParent, "ContainerFrameTemplate")
	bag:SetScript("OnShow", onShow)
	bag:SetScript("OnHide", onHide)
	bag.PortraitButton:SetScript("OnEnter", onEnter)
	bag.PortraitButton:SetScript("OnLeave", GameTooltip_Hide)
	bag.PortraitButton:SetScript("OnClick", nil)
	bag.CloseButton:SetScript("OnClick", HideParentPanel)
	bagFrames[i] = bag
	bag.buttons = {}
	for slot = 1, 36 do
		local button = _G[frameName.."Item"..slot]
		Vortex:SetupItemButton(button)
		button:RegisterForDrag()
		button:SetScript("OnHide", nil)
		button:SetScript("OnDragStart", nil)
		button:SetScript("OnReceiveDrag", nil)
		button.SplitStack = nil
		button.UpdateTooltip = button.OnEnter
		button.anchor = "ANCHOR_LEFT"
		-- button.flash:Hide()
		-- button.NewItemTexture:Hide()
		button.BattlepayItemTexture:Hide()
		bag.buttons[slot] = button
	end
	Vortex:RegisterContainerButtons(i, bag.buttons)
end

do
	local BUTTON_HEIGHT = 26
	
	local scrollFrame = Vortex:CreateScrollFrame("Hybrid", frame.list)
	scrollFrame:SetPoint("TOP", frame.Inset, 0, -4)
	scrollFrame:SetPoint("LEFT", frame.Inset, 4, 0)
	scrollFrame:SetPoint("BOTTOMRIGHT", frame.Inset, -20, 4)
	scrollFrame:SetButtonHeight(BUTTON_HEIGHT)
	scrollFrame.initialOffsetX = 1
	scrollFrame.initialOffsetY = -2
	scrollFrame.offsetY = -3
	scrollFrame.getNumItems = function()
		return #Vortex:GetList()
	end
	scrollFrame.updateButton = function(button, index)
		local list = Vortex:GetList()
		local object = list[index]
		button.source:SetText(nil)
		button.info:SetText(nil)
		button.info2:SetText(nil)
		button.label:SetTextColor(NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b)
		button.label:SetPoint("TOPLEFT", button.icon, "TOPRIGHT", 4, 0)
		button.source:SetPoint("TOPLEFT", button.icon, "RIGHT", 6, -2)
		button.PostEnter = nil
		button.item = nil
		local selectedModule = Vortex:GetSelectedModule()
		if not Vortex:IsSearching() and selectedModule.UpdateButton then
			button.icon:SetTexture(nil)
			button:ResetHeight()
			selectedModule:UpdateButton(button, object)
		else
			local id = object.linkType and (object.linkType..":"..object.id)
			local money = object.money
			if money then
				button.label:SetText(GetCoinText(money))
				button.label:SetTextColor(1, 1, 1)
				button.icon:SetTexture(GetCoinIcon(money))
			else
				local item = ItemInfo[id or object.id or object.link]
				button.icon:SetTexture(not object.linkType and GetItemIcon(object.id) or item.icon)
				if item then
					local r, g, b = GetItemQualityColor(item.quality or 1)
					local buttonHeight, owners, count = Vortex:GetItemSearchResultText(id or object.id or object.link)
					local count = count or object.count
					if (count and count > 1) then
						button.label:SetFormattedText("%s |cffffffff(%d)|r", item.name, count)
					else
						button.label:SetText(item.name)
					end
					button.label:SetTextColor(r, g, b)
					if Vortex:IsSearching() then
						button.source:SetText(owners)
					else
						-- button.info:SetText(strjoin(", ", item.type, item.subType, _G[item.invType] or ""))
						
						local slot = not noSlot[item.subType] and _G[item.invType]
						local type = yesType[item.type] and item.type
						local itemType = not (noArmor[item.invType] or noType[item.subType]) and (weaponTypes[item.subType] or item.subType)
						-- in some cases itemType is the same as slot, no need to show both
						if type and itemType and type ~= itemType then
							button.source:SetText(type..", "..itemType)
						elseif itemType and slot and itemType ~= slot then
							button.source:SetText(slot..", "..itemType)
						elseif itemType ~= LBI["Consumable"] then
							button.source:SetText(slot or itemType or "")
						end
					end
					button:SetHeight(max(BUTTON_HEIGHT, 15 + button.source:GetHeight() + 1))
				else
					button.label:SetText(RETRIEVING_ITEM_INFO)
					button.label:SetTextColor(RED_FONT_COLOR.r, RED_FONT_COLOR.g, RED_FONT_COLOR.b)
					doUpdateList = true
				end
			end
			button.item = id or object.link or object.id
			
			if GetMouseFocus() == button then
				button:OnEnter()
			end
			
			if not Vortex:IsSearching() and selectedModule and selectedModule.OnButtonUpdate then
				selectedModule:OnButtonUpdate(button, object)
			end
		end
	end
	scrollFrame.createButton = function(parent)
		local button = CreateFrame("Button", nil, parent)
		Vortex:SetupItemButton(button)
		button:SetPoint("RIGHT", -5, 0)
		button:SetHighlightTexture([[Interface\QuestFrame\UI-QuestTitleHighlight]])
		button:SetPushedTextOffset(0, 0)
		button.x = 28

		button.icon = button:CreateTexture()
		button.icon:SetPoint("TOPLEFT", 3, -1)
		button.icon:SetSize(24, 24)
		
		button.label = button:CreateFontString(nil, nil, "GameFontHighlightLeft")
		button.label:SetJustifyH("LEFT")
		button.label:SetJustifyV("TOP")
		button.label:SetPoint("TOPLEFT", button.icon, "TOPRIGHT", 4, 0)
		button.label:SetPoint("BOTTOMRIGHT", -4, 3)
		button.label:SetWordWrap(false)
		button:SetFontString(button.label)
		
		button.source = button:CreateFontString(nil, nil, "GameFontHighlightSmallLeft")
		button.source:SetPoint("TOPLEFT", button.icon, "RIGHT", 6, -2)
		button.source:SetSpacing(1)
		
		button.info = button:CreateFontString(nil, nil, "GameFontHighlightSmallRight")
		button.info:SetPoint("BOTTOM", button.icon)
		button.info:SetPoint("RIGHT", -3, 0)
		
		button.info2 = button:CreateFontString(nil, nil, "GameFontHighlightSmallRight")
		button.info2:SetPoint("TOP", button.icon)
		button.info2:SetPoint("RIGHT", -3, 0)
		
		return button
	end
	scrollFrame:CreateButtons()
	
	Vortex.scroll = scrollFrame
	
	local scrollBar = scrollFrame.scrollBar
	scrollBar:ClearAllPoints()
	scrollBar:SetPoint("TOPRIGHT", frame.Inset, 0, -18)
	scrollBar:SetPoint("BOTTOMRIGHT", frame.Inset, 0, 16)
	scrollBar.doNotHide = true
end

local function onClick(self, characterKey)
	Vortex:SelectCharacter(characterKey)
	CloseDropDownMenus()
end

local characterMenu = Vortex:CreateDropdown("Frame", characterTab.frame)
characterMenu:SetWidth(128)
characterMenu:JustifyText("LEFT")
characterMenu:SetPoint("TOPLEFT", frame, 0, -29)
characterMenu.initialize = function(self, level)
	for i, characterKey in ipairs(Vortex:GetCharacters(UIDROPDOWNMENU_MENU_VALUE)) do
		local accountKey, realmKey, characterName = strsplit(".", characterKey)
		local info = UIDropDownMenu_CreateInfo()
		if Vortex:IsConnectedRealm(realmKey) then
			info.text = characterName.." - "..realmKey
		else
			info.text = characterName
		end
		info.func = onClick
		info.arg1 = characterKey
		info.checked = (characterKey == Vortex:GetSelectedCharacter())
		UIDropDownMenu_AddButton(info, level)
	end
	if level == 1 then
		local sortedRealms = {}
		for realm in pairs(DataStore:GetRealms()) do
			if not (realm == myRealm or Vortex:IsConnectedRealm(realm)) then
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
Vortex.characterMenu = characterMenu


local empty = {}

function Vortex:SetList(list)
	self.list = list or empty
	self.filteredList = nil
	self:UpdateList()
end

function Vortex:GetList(getRaw)
	return not getRaw and self.filteredList or self.list
end

local function listSort(a, b)
	-- if either is a money entry and the other isn't, sort by this
	if (a.money ~= nil) ~= (b.money ~= nil) then
		return a.money
	end
	local itemA = ItemInfo[(a.linkType and a.linkType..":"..a.id) or a.id or a.link]
	local itemB = ItemInfo[(b.linkType and b.linkType..":"..b.id) or b.id or b.link]
	-- if either item is not cached, break and wait for item info update
	if not (itemA and itemB) then
		doUpdateList = true
		return
	end
	if itemA.quality ~= itemB.quality then
		if not (itemA.quality and itemB.quality) then
			return not itemA.quality
		end
		return itemA.quality > itemB.quality
	else
		return itemA.name < itemB.name
	end
end

Vortex.defaultSort = listSort

function Vortex:UpdateList()
	local module = self:GetSelectedModule()
	if not module.noSort then
		sort(self:GetList(), not self.isSearching and module.sort or listSort)
	end
	self:UpdateScrollFrame()
end

function Vortex:UpdateScrollFrame()
	self.scroll:update()
end

function Vortex:QueueListUpdate()
	doUpdateList = true
end

function Vortex:QueueUIUpdate()
	doUpdateUI = true
end