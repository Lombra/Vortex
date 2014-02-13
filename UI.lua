local addonName, addon = ...

local Libra = LibStub("Libra")
local LII = LibStub("LibItemInfo")
local LIB = LibStub("LibItemButton")

local myCharacter
local myRealm = GetRealmName()

local widgetIndex = 1
local function getWidgetName()
	local name = addonName.."Widget"..widgetIndex
	widgetIndex = widgetIndex + 1
	return name
end

local LIST_PANEL_WIDTH = 128 - PANEL_INSET_RIGHT_OFFSET

local frame = Libra:CreateUIPanel(addonName.."Frame")
addon.frame = frame
frame:SetWidth(PANEL_DEFAULT_WIDTH + LIST_PANEL_WIDTH)
frame:SetPoint("CENTER")
frame:SetToplevel(true)
frame:EnableMouse(true)
frame:SetTitleText("Vortex")
frame:HidePortrait(frame)
frame:HideButtonBar(frame)
frame:SetScript("OnShow", function(self)
	PlaySound("igCharacterInfoOpen")
	if not PanelTemplates_GetSelectedTab(self) then
		addon:SelectModule(addon.db.defaultModule or "All")
		PanelTemplates_SetTab(self, 1)
	end
end)
frame:SetScript("OnHide", function(self)
	PlaySound("igCharacterInfoClose")
end)

frame.Inset:SetPoint("TOPLEFT", PANEL_INSET_LEFT_OFFSET + LIST_PANEL_WIDTH, PANEL_INSET_ATTIC_OFFSET)

frame.list = CreateFrame("Frame", nil, frame.Inset)
frame.list:SetAllPoints()
-- frame.list:Hide()
frame.list:SetFrameLevel(frame.Inset:GetFrameLevel() + 1)

frame.ui = CreateFrame("Frame", nil, frame.Inset)
frame.ui:SetAllPoints()
frame.ui:Hide()

local inset = CreateFrame("Frame", nil, frame, "InsetFrameTemplate")
inset:SetPoint("TOPLEFT", PANEL_INSET_LEFT_OFFSET, PANEL_INSET_ATTIC_OFFSET)
inset:SetPoint("BOTTOM", 0, PANEL_INSET_BOTTOM_OFFSET + 2)
inset:SetPoint("RIGHT", frame.Inset, "LEFT", PANEL_INSET_RIGHT_OFFSET, 0)

local tabs = {}

local function onClick(self)
	frame.selectedTab = self:GetID()
	PanelTemplates_UpdateTabs(frame)
	PlaySound("igCharacterInfoTab")
end

local function onEnable(self)
	local frame = self.frame
	frame:Hide()
end

local function onDisable(self)
	local frame = self.frame
	frame:Show()
	
	local module = addon:GetSelectedModule()
	addon.frame:SetWidth(frame.width or (module.altUI and module.width or PANEL_DEFAULT_WIDTH) + LIST_PANEL_WIDTH)
	UpdateUIPanelPositions(addon.frame)
end

local function createTab()
	local numTabs = #tabs + 1
	local tab = CreateFrame("Button", addonName.."FrameTab"..numTabs, frame, "CharacterFrameTabButtonTemplate")
	if numTabs == 1 then
		tab:SetPoint("BOTTOMLEFT", 19, -30)
	else
		tab:SetPoint("LEFT", tabs[numTabs - 1], "RIGHT", -15, 0)
	end
	tab:SetID(numTabs)
	tab:SetScript("OnClick", onClick)
	tab:SetScript("OnEnable", onEnable)
	tab:SetScript("OnDisable", onDisable)
	tabs[numTabs] = tab
	frame.numTabs = numTabs
	return tab
end

local charTab = createTab()
charTab:SetText("Character")
-- charTab.frame = CreateFrame("Frame", nil, frame)
-- charTab.frame:SetAllPoints()
-- charTab.frame:Hide()
-- frame.Inset:SetParent(charTab.frame)
charTab.frame = frame.Inset
inset:SetParent(charTab.frame)

local guildTab = createTab()
guildTab:SetText("Guild")
guildTab.frame = CreateFrame("Frame", nil, frame)
guildTab.frame:SetAllPoints()
guildTab.frame:Hide()
guildTab.frame.width = 750
frame.guild = guildTab.frame

local Prototype = addon.prototype

local currentHighlight

local function onClick(self)
	if addon.isSearching then
		addon:StopSearch()
	end
	addon:SelectModule(self.module)
end

local buttons = {}
addon.moduleButtons = buttons

function addon:CreateUI(name, label)
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

-- function addon:GetSelectedTab()
	-- return self:GetModule(currentHighlight.module)
-- end

local ItemInfo = setmetatable({}, {
	__index = function(self, objectID)
		if type(objectID) == "string" and objectID:match("battlepet:%d+") then
			local _, speciesID, level, breedQuality, maxHealth, power, speed, battlePetID = strsplit(":", objectID)
			local name, icon, petType = C_PetJournal.GetPetInfoBySpeciesID(speciesID)
			local object = {
				name = name,
				quality = tonumber(breedQuality),
				icon = icon,
			}
			self[objectID] = object
			return object
		end
		
		local object = LII[objectID]
		self[objectID] = object
		return object
	end
})
addon.ItemInfo = ItemInfo

local doUpdateList
local doUpdateUI

LII.RegisterCallback(addon, "GetItemInfoReceivedAll", function()
	if doUpdateList then
		doUpdateList = nil
		addon:UpdateList()
	end
	if doUpdateUI then
		doUpdateUI = nil
		local module = addon:GetSelectedModule()
		if module.uiSearch then
			module:uiSearch(addon:GetFilter("name"))
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

local function isSoulboundItem(item)
    tooltip:SetOwner(UIParent, "ANCHOR_NONE")
    tooltip:SetItemByID(item)
	for i = 1, #tooltip.rows do
		if tooltip.rows[i]:GetText() == ITEM_BIND_ON_PICKUP then
			return true
		end
	end
	return false
end

local function isBNetBoundItem(item)
    tooltip:SetOwner(UIParent, "ANCHOR_NONE")
    tooltip:SetItemByID(item)
	for i = 1, #tooltip.rows do
		if tooltip.rows[i]:GetText() == ITEM_BIND_TO_BNETACCOUNT then
			return true
		end
	end
	return false
end

-- ITEM_BIND_TO_ACCOUNT = "Binds to account";
-- ITEM_BIND_TO_BNETACCOUNT = "Binds to Battle.net account";
-- ITEM_BNETACCOUNTBOUND = "Battle.net Account Bound";

local lol, again

GameTooltip:HookScript("OnTooltipSetItem", function(self)
	if lol and not again then
		return
	end
	if not addon.db.tooltip then
		return
	end
	lol = true
	local itemName, itemLink = self:GetItem()
	local itemID = itemLink and tonumber(itemLink:match("item:(%d+)"))
	if not itemID then return end
	-- don't add tooltip info for unstackable soulbound items
	if (not ItemInfo[itemID] or ItemInfo[itemID].stackSize == 1) and isSoulboundItem(itemID) then
		return
	end
	local numChars = 0
	local total = 0
	for i, character in ipairs(addon:GetCharacters()) do
		local _, _, charKey = strsplit(".", character)
		local where = "("
		local count = 0
		for k, module in addon:IterateModules() do
			if not module.noSearch then
				local moduleCount = module:GetItemCount(character, itemID) or 0
				if moduleCount > 0 then
					count = count + moduleCount
					where = format("%s%d %s, ", where, moduleCount, k)
				end
			end
		end
		if count > 0 then
			self:AddLine("|cffffffff"..count.."|r "..charKey.." "..gsub(where, ", $", ")"))
			numChars = numChars + 1
		end
		total = total + count
	end
	if addon.db.tooltipBNet and isBNetBoundItem(itemID) then
		for realm in pairs(DataStore:GetRealms()) do
			if realm ~= myRealm then
				for i, character in ipairs(addon:GetCharacters(realm)) do
					local _, _, charKey = strsplit(".", character)
					local where = "("
					local count = 0
					for k, module in addon:IterateModules() do
						if not module.noSearch then
							local moduleCount = module:GetItemCount(character, itemID) or 0
							if moduleCount > 0 then
								count = count + moduleCount
								where = format("%s%d %s, ", where, moduleCount, k)
							end
						end
					end
					if count > 0 then
						self:AddLine("|cffffffff"..count.."|r "..charKey.." - "..realm.." "..gsub(where, ", $", ")"))
						numChars = numChars + 1
					end
					total = total + count
				end
			end
		end
	end
	if addon.db.tooltipGuildBanks then
		for guild, guildKey in pairs(DataStore:GetGuilds()) do
			local count = DataStore:GetGuildBankItemCount(guildKey, itemID)
			if count > 0 then
				self:AddLine("|cffffffff"..count.."|r <"..guild..">")
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
	lol = nil
	again = nil
end)

local onTooltipAddMoney = GameTooltip_OnTooltipAddMoney

function GameTooltip_OnTooltipAddMoney(self, cost, maxcost)
	if not maxcost and self.stackSize then
		cost = cost * self.stackSize
	end
	onTooltipAddMoney(self, cost, maxcost)
end

do
	local All = addon:NewModule("All", {
		label = "All items",
		noSearch = true,
	})
	
	function All:BuildList(character)
		local added = {}
		local list = {}
		for k, module in addon:IterateModules() do
			if not module.noSearch then
				for i, v in ipairs(module:GetList(character)) do
					local item = v.link or v.id
					if not added[item] then
						tinsert(list, v)
						if item then
							added[item] = #list
						end
					else
						local item = list[added[item]]
						item.count = (item.count or v.count) and (item.count or 0) + (v.count or 0)
					end
				end
			end
		end
		return list
	end
end

local scrollFrame

local bagFrames = {}
local containerButtons = {}

frame:SetScript("OnHide", function(self)
	addon:CloseAllContainers()
end)

local itemButtonMethods = {
	SetItem = function(self, itemID, itemLink, count)
		self.item = itemLink or itemID
		self.icon:SetTexture(GetItemIcon(itemID) or self.bg)
		-- self.icon:SetShown(itemID ~= nil)
		if count and count > 1 then
			self.count:SetText(count)
			self.count:Show()
			self.stackSize = count
		else
			self.count:Hide()
			self.stackSize = nil
		end
		LIB:UpdateButton(self, itemID)
	end,
	
	OnClick = function(self, button)
		if self.isBag then
			self:SetChecked(false)
		end
		if self.isBag then
			if not self.item and self:GetID() ~= 0 then return end
			local bag = bagFrames[self:GetID()]
			local isOpen = addon:IsBagOpen(self:GetID())
			if isOpen then
				bag:Hide()
			else
				ContainerFrame_GenerateFrame(bag, self.size, self:GetID())
				local icon, link, size = DataStore:GetContainerInfo(addon:GetSelectedCharacter(), self:GetID())
				_G[bag:GetName().."Name"]:SetText(link and GetItemInfo(link) or BACKPACK_TOOLTIP)
				SetPortraitToTexture(_G[bag:GetName().."Portrait"], icon)
				addon:UpdateContainer(self:GetID(), addon:GetSelectedCharacter(), bag.buttons)
			end
			self:SetChecked(not isOpen)
		elseif self.item then
			HandleModifiedItemClick(select(2, GetItemInfo(self.item)))
		end
	end,

	OnUpdate = function(self)
		if GameTooltip:IsOwned(self) then
			if IsModifiedClick("COMPAREITEMS") or (GetCVarBool("alwaysCompareItems") and not IsEquippedItem(self.item)) then
				GameTooltip_ShowCompareItem()
			else
				ShoppingTooltip1:Hide()
				ShoppingTooltip2:Hide()
				ShoppingTooltip3:Hide()
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
			self.showingTooltip = true
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
		self.showingTooltip = false
		ResetCursor()
		self:SetScript("OnUpdate", nil)
	end,
}

function addon:SetupItemButton(button)
	for k, v in pairs(itemButtonMethods) do
		button[k] = v
	end
	button:SetScript("OnClick", button.OnClick)
	button:SetScript("OnEnter", button.OnEnter)
	button:SetScript("OnLeave", button.OnLeave)
	button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
end

function addon:CreateItemButton(parent)
	local button = CreateFrame("Button", nil, parent, "ItemButtonTemplate")
	self:SetupItemButton(button)
	LIB:RegisterButton(button)
	return button
end

function addon:CreateBagButton(parent)
	local button = CreateFrame("CheckButton", nil, parent, "ItemButtonTemplate")
	button:SetCheckedTexture([[Interface\Buttons\CheckButtonHilight]])
	button.isBag = true
	self:SetupItemButton(button)
	return button
end

function addon:UpdateContainer(container, character, buttons)
	buttons = buttons or self:GetContainerButtons(container, buttons)
	local bag = DataStore:GetContainer(character, container)
	for i = 1, DataStore:GetContainerSize(character, container) do
		buttons[i]:SetItem(DataStore:GetSlotInfo(bag, buttons[i]:GetID()))
	end
end

function addon:RegisterContainerButtons(container, buttons)
	containerButtons[container] = buttons
end

function addon:GetContainerButtons(container)
	return containerButtons[container]
end

function addon:GetContainerFrame(id)
	return bagFrames[id]
end

function addon:IsBagOpen(id)
	return bagFrames[id]:IsShown()
end

function addon:CloseAllContainers()
	for i, frame in ipairs(bagFrames) do
		frame:Hide()
	end
end

local function onEnter(self)
	GameTooltip:SetOwner(self, "ANCHOR_LEFT")
	if self:GetID() == 0 then
		GameTooltip:SetText(BACKPACK_TOOLTIP, 1.0, 1.0, 1.0)
	else
		local icon, link, size, freeslots = DataStore:GetContainerInfo(addon:GetSelectedCharacter(), self:GetID())
		GameTooltip:SetHyperlink(link)
	end
end

local function onShow(self)
	ContainerFrame1.bags[ContainerFrame1.bagsShown + 1] = self:GetName()
	ContainerFrame1.bagsShown = ContainerFrame1.bagsShown + 1
	PlaySound("igBackPackOpen")
	addon:SearchContainer(self:GetID())
end

local function onHide(self)
	ContainerFrame1.bagsShown = ContainerFrame1.bagsShown - 1
	-- Remove the closed bag from the list and collapse the rest of the entries
	tDeleteItem(ContainerFrame1.bags, self:GetName())
	UpdateContainerFrameAnchors()
	PlaySound("igBackPackClose")
	self.containerButton:SetChecked(false)
end

-- create backpack and bank bag frames
for i = 0, 11 do
	local frameName = "VortexContainerFrame"..i
	local bag = CreateFrame("Frame", frameName, UIParent, "ContainerFrameTemplate")
	bag:SetScript("OnShow", onShow)
	bag:SetScript("OnHide", onHide)
	_G[frameName.."CloseButton"]:SetScript("OnClick", HideParentPanel)
	_G[frameName.."PortraitButton"]:SetScript("OnEnter", onEnter)
	bagFrames[i] = bag
	bag.buttons = {}
	for slot = 1, 36 do
		local button = _G[frameName.."Item"..slot]
		addon:SetupItemButton(button)
		button:RegisterForDrag(nil)
		button:SetScript("OnHide", nil)
		button:SetScript("OnDragStart", nil)
		button:SetScript("OnReceiveDrag", nil)
		button.SplitStack = nil
		button.UpdateTooltip = nil
		button.anchor = "ANCHOR_LEFT"
		_G[frameName.."Item"..slot.."NewItemTexture"]:Hide()
		bag.buttons[slot] = button
	end
	addon:RegisterContainerButtons(i, bag.buttons)
end

do
	local BUTTON_HEIGHT = 26
	local BUTTON_OFFSET = 3
	
	local function createButton(frame)
		local button = CreateFrame("Button", nil, frame)
		addon:SetupItemButton(button)
		button.x = 28
		button:SetHeight(BUTTON_HEIGHT)
		button:SetPoint("RIGHT", -5, 0)
		button:SetHighlightTexture([[Interface\QuestFrame\UI-QuestTitleHighlight]])
		button:SetPushedTextOffset(0, 0)

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
	
	local function updateButton(button, object)
		local money = object.money
		if money then
			button.label:SetText(GetCoinText(money))
			button.label:SetTextColor(1, 1, 1)
			button.icon:SetTexture(GetCoinIcon(money))
		else
			local item = ItemInfo[object.id or object.link]
			button.icon:SetTexture(GetItemIcon(object.id) or item.icon)
			if item then
				local r, g, b = GetItemQualityColor(item.quality)
				local buttonHeight, owners, count = addon:GetItemSearchResultText(object.id)
				local count = count or object.count
				if (count and count > 1) then
					button.label:SetFormattedText("%s |cffffffff(%d)|r", item.name, count)
				else
					button.label:SetText(item.name)
				end
				button.label:SetTextColor(r, g, b)
				button.source:SetText(owners)
				button:SetHeight(max(BUTTON_HEIGHT, 15 + button.source:GetHeight() + 1))
			else
				button.label:SetText(RETRIEVING_ITEM_INFO)
				doUpdateList = true
			end
		end
		button.item = object.link or object.id
		
		if button.showingTooltip then
			if not isHeader then
				button:OnEnter()
			else
				GameTooltip:Hide()
			end
		end
	end
	
	local function update(self)
		local list = addon:GetList()
		local offset = HybridScrollFrame_GetOffset(self)
		local buttons = self.buttons
		local numButtons = #buttons
		for i = 1, numButtons do
			local index = offset + i
			local object = list[index]
			local button = buttons[i]
			if object then
				button.source:SetText(nil)
				button.info:SetText(nil)
				button.info2:SetText(nil)
				button.label:SetTextColor(NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b)
				button.label:SetPoint("TOPLEFT", button.icon, "TOPRIGHT", 4, 0)
				button.source:SetPoint("TOPLEFT", button.icon, "RIGHT", 6, -2)
				button.item = nil
				local selectedModule = addon:GetSelectedModule()
				if not addon.isSearching and selectedModule.UpdateButton then
					button.icon:SetTexture(nil)
					button:SetHeight(BUTTON_HEIGHT)
					selectedModule:UpdateButton(button, object)
				else
					updateButton(button, object)
					if not addon.isSearching and selectedModule and selectedModule.OnButtonUpdate then
						selectedModule:OnButtonUpdate(button, object)
					end
				end
			end
			button:SetShown(object ~= nil)
		end
		
		local totalHeight = #list * self.buttonHeight
		local displayedHeight = numButtons * self.buttonHeight
		
		if addon.isSearching then
			totalHeight = 0
			for i, item in ipairs(list) do
				totalHeight = totalHeight + addon:GetItemSearchResultText(item.id or item.link)
			end
			displayedHeight = displayedHeight - 20
		end
		
		HybridScrollFrame_Update(self, totalHeight, displayedHeight)
	end
	
	local name = getWidgetName()
	scrollFrame = CreateFrame("ScrollFrame", name, frame.list, "HybridScrollFrameTemplate")
	scrollFrame:SetPoint("TOP", frame.Inset, 0, -4)
	scrollFrame:SetPoint("LEFT", frame.Inset, 4, 0)
	scrollFrame:SetPoint("BOTTOMRIGHT", frame.Inset, -23, 4)
	scrollFrame.update = function()
		update(scrollFrame)
	end
	_G[name] = nil
	addon.scroll = scrollFrame
	
	local scrollBar = CreateFrame("Slider", nil, scrollFrame, "HybridScrollBarTemplate")
	scrollBar:ClearAllPoints()
	scrollBar:SetPoint("TOP", frame.Inset, 0, -16)
	scrollBar:SetPoint("BOTTOMLEFT", scrollFrame, "BOTTOMRIGHT", 0, 11)
	scrollBar.doNotHide = true
	
	local buttons = {}
	scrollFrame.buttons = buttons
	
	for i = 1, (ceil(scrollFrame:GetHeight() / BUTTON_HEIGHT) + 1) do
		local button = createButton(scrollFrame.scrollChild)
		if i == 1 then
			button:SetPoint("TOPLEFT", 1, -2)
		else
			button:SetPoint("TOPLEFT", buttons[i - 1], "BOTTOMLEFT", 0, -BUTTON_OFFSET)
		end
		buttons[i] = button
	end
	
	HybridScrollFrame_CreateButtons(scrollFrame, nil, nil, nil, nil, nil, nil, -BUTTON_OFFSET)
end

local function onClick(self, characterKey)
	addon:SelectCharacter(characterKey)
	CloseDropDownMenus()
end

local button = Libra:CreateDropdown(charTab.frame, true)
button:SetWidth(96)
button:JustifyText("LEFT")
button:SetPoint("TOPLEFT", frame, 0, -29)
button.initialize = function(self, level)
	for i, characterKey in ipairs(addon:GetCharacters(UIDROPDOWNMENU_MENU_VALUE)) do
		local accountKey, realmKey, characterName = strsplit(".", characterKey)
		local info = UIDropDownMenu_CreateInfo()
		info.text = characterName
		info.func = onClick
		info.arg1 = characterKey
		info.checked = characterKey == addon:GetSelectedCharacter()
		UIDropDownMenu_AddButton(info, level)
	end
	local sortedRealms = {}
	if level == 1 then
		for realm in pairs(DataStore:GetRealms()) do
			if realm ~= myRealm then
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
addon.characterMenu = button


local empty = {}

function addon:SetList(list)
	self.list = list or empty
	self.filteredList = nil
	self:UpdateList()
end

function addon:GetList(getRaw)
	return not getRaw and self.filteredList or self.list
end

local function listSort(a, b)
	-- if either is a money entry and the other isn't, sort by this
	if (a.money ~= nil) ~= (b.money ~= nil) then
		return a.money
	end
	local itemA = ItemInfo[a.id or a.link]
	local itemB = ItemInfo[b.id or b.link]
	-- if either item is not cached, break and wait for item info update
	if not (itemA and itemB) then
		doUpdateList = true
		return
	end
	if itemA.quality ~= itemB.quality then
		return itemA.quality > itemB.quality
	else
		return itemA.name < itemB.name
	end
end

addon.defaultSort = listSort

function addon:UpdateList()
	local module = self:GetSelectedModule()
	if not module.noSort then
		sort(self:GetList(), not addon.isSearching and module.sort or listSort)
	end
	self:UpdateScrollFrame()
end

function addon:UpdateScrollFrame()
	scrollFrame:update()
end

function addon:QueueListUpdate()
	doUpdateList = true
end