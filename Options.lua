local addonName, addon = ...

local Libra = LibStub("Libra")

local frame = CreateFrame("Frame")
frame.name = addonName
InterfaceOptions_AddCategory(frame)
addon.config = frame

local title = frame:CreateFontString(nil, nil, "GameFontNormalLarge")
title:SetPoint("TOPLEFT", 16, -16)
title:SetPoint("RIGHT", -16, 0)
title:SetJustifyH("LEFT")
title:SetJustifyV("TOP")
title:SetText(frame.name)

local function onClick(self)
	local checked = self:GetChecked() ~= nil
	PlaySound(checked and "igMainMenuOptionCheckBoxOn" or "igMainMenuOptionCheckBoxOff")
	addon.db[self.setting] = checked
	if self.func then
		self.func()
	end
end

local function newCheckButton(data)
	local btn = CreateFrame("CheckButton", nil, frame, "OptionsBaseCheckButtonTemplate")
	btn:SetPushedTextOffset(0, 0)
	btn:SetScript("OnClick", onClick)
	
	local text = btn:CreateFontString(nil, nil, "GameFontHighlight")
	text:SetPoint("LEFT", btn, "RIGHT", 0, 1)
	btn:SetFontString(text)
	
	return btn
end

local options = {
	{
		text = "Add tooltip info",
		key = "tooltip",
		tooltipText = "Shows on item tooltips which characters or guilds has the item",
	},
	{
		text = "Tooltip modifier",
		key = "tooltipModifier",
		tooltipText = "Adds tooltip info only when any modifier key is pressed",
	},
	{
		text = "Add tooltip Battle.net info",
		key = "tooltipBNet",
		tooltipText = "Includes characters from other realms for Battle.net account bound items",
	},
	{
		text = "Add tooltip guild info",
		key = "tooltipGuild",
		tooltipText = "Includes guild bank",
	},
	{
		text = "Use list view",
		key = "useListView",
		func = function()
			if not addon.isSearching then
				addon:SelectModule(addon:GetSelectedModule().name)
				addon:CloseAllContainers()
			end
		end,
		tooltipText = "Shows all modules as lists instead of their default UI"
	},
	{
		text = "Search guild banks",
		key = "searchGuild",
		tooltipText = "Includes guild banks in search results"
	},
}

function addon:LoadSettings()
	for i, option in ipairs(options) do
		local button = newCheckButton()
		if i == 1 then
			button:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -16)
		else
			button:SetPoint("TOP", options[i - 1].button, "BOTTOM", 0, -8)
		end
		button:SetText(option.text)
		button:SetChecked(self.db[option.key])
		button.setting = option.key
		button.tooltipText = option.tooltipText
		button.func = option.func
		option.button = button
	end
	
	local function onClick(self, module)
		addon.db.defaultModule = module
		self.owner:SetText(module)
	end
	
	local defaultModule = Libra:CreateDropdown(frame, true)
	defaultModule:SetWidth(128)
	defaultModule:SetPoint("TOPLEFT", options[#options].button, "BOTTOMLEFT", -12, -24)
	defaultModule:JustifyText("LEFT")
	defaultModule:SetLabel("Default module")
	defaultModule:SetText(self.db.defaultModule or "All")
	defaultModule.initialize = function(self)
		for i, v in ipairs(addon.modulesSorted) do
			local info = UIDropDownMenu_CreateInfo()
			info.text = v
			info.func = onClick
			info.arg1 = v
			info.checked = (v == addon.db.defaultModule)
			info.owner = self
			self:AddButton(info)
		end
	end
	
	local scopes = {
		"Character",
		"Realm",
		"All",
	}
	
	local function onClick(self, searchScope)
		addon.db.defaultSearch = searchScope
		self.owner:SetText(searchScope)
	end
	
	local defaultSearch = Libra:CreateDropdown(frame, true)
	defaultSearch:SetWidth(128)
	defaultSearch:SetPoint("TOP", defaultModule, "BOTTOM", 0, -16)
	defaultSearch:JustifyText("LEFT")
	defaultSearch:SetLabel("Default search scope")
	defaultSearch:SetText(self.db.defaultSearch)
	defaultSearch.initialize = function(self)
		for i, v in ipairs(scopes) do
			local info = UIDropDownMenu_CreateInfo()
			info.text = v
			info.func = onClick
			info.arg1 = v
			info.checked = (v == addon.db.defaultSearch)
			info.owner = self
			self:AddButton(info)
		end
	end
	
	self:SetSearchScope(self.db.defaultSearch)
	
	local sortedGuilds = {}
	
	local function onClickCharacter(self, character)
		local accountKey, realmKey, characterKey = strsplit(".", character)
		StaticPopup_Show("VORTEX_DELETE_CHARACTER", characterKey, realmKey, character)
	end
	
	local function onClickGuild(self, guild)
		local accountKey, realmKey, guildKey = strsplit(".", guild)
		StaticPopup_Show("VORTEX_DELETE_GUILD", guildKey, realmKey, guild)
	end
	
	local menu = Libra:CreateDropdown()
	menu:SetDisplayMode("MENU")
	menu.initialize = function(self, level)
		for i, characterKey in ipairs(addon:GetCharacters(UIDROPDOWNMENU_MENU_VALUE)) do
			if characterKey ~= DataStore:GetCharacter() then
				local accountKey, realmKey, characterName = strsplit(".", characterKey)
				local info = UIDropDownMenu_CreateInfo()
				info.text = characterName
				info.func = onClickCharacter
				info.arg1 = characterKey
				info.notCheckable = true
				UIDropDownMenu_AddButton(info, level)
			end
		end
		wipe(sortedGuilds)
		local guilds = DataStore:GetGuilds(UIDROPDOWNMENU_MENU_VALUE)
		for guildName, guildKey in pairs(guilds) do
			if DataStore:GetGuildBankFaction(guildKey) then
				tinsert(sortedGuilds, guildName)
			end
		end
		sort(sortedGuilds)
		for i, guildName in ipairs(sortedGuilds) do
			local guildKey = guilds[guildName]
			local info = UIDropDownMenu_CreateInfo()
			info.text = "<"..guildName..">"
			info.func = onClickGuild
			info.arg1 = guildKey
			info.colorCode = "|cff56a3ff"
			info.notCheckable = true
			UIDropDownMenu_AddButton(info, level)
		end
		local sortedRealms = {}
		if level == 1 then
			for realm in pairs(DataStore:GetRealms()) do
				if realm ~= GetRealmName() then
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
	
	local button = CreateFrame("Button", "VortexPurgeDataButton", frame, "UIMenuButtonStretchTemplate")
	button:SetWidth(96)
	button:SetPoint("TOP", defaultSearch, "BOTTOM", 0, -16)
	button.rightArrow:Show()
	button:SetText("Purge data")
	button:SetScript("OnClick", function(self)
		menu:ToggleMenu()
	end)
	
	menu.relativeTo = button
	menu.relativePoint = "TOPRIGHT"
	menu.xOffset = 0
	menu.yOffset = 0
end

StaticPopupDialogs["VORTEX_DELETE_CHARACTER"] = {
	text = "Really delete data for |cffffd200%s - %s|r?",
	button1 = YES,
	button2 = NO,
	OnAccept = function(self, character)
		addon:DeleteCharacter(character)
	end,
	hideOnEscape = true,
}

StaticPopupDialogs["VORTEX_DELETE_GUILD"] = {
	text = "Really delete data for |cffffd200%s - %s|r?",
	button1 = YES,
	button2 = NO,
	OnAccept = function(self, guild)
		addon:DeleteGuild(guild)
	end,
	hideOnEscape = true,
}