local VORTEX, Vortex = ...

local frame = Vortex:CreateOptionsFrame(VORTEX)
Vortex.config = frame

local options = {
	{
		type = "CheckButton",
		text = "Add tooltip info",
		tooltip = "Shows on item tooltips which characters or guilds has the item",
		key = "tooltip",
	},
	{
		type = "CheckButton",
		text = "Tooltip modifier",
		tooltip = "Adds tooltip info only when any modifier key is pressed",
		key = "tooltipModifier",
	},
	{
		type = "CheckButton",
		text = "Add tooltip Battle.net info",
		tooltip = "Includes characters from other realms for Battle.net account bound items",
		key = "tooltipBNet",
	},
	{
		type = "CheckButton",
		text = "Add tooltip guild info",
		tooltip = "Includes guild bank",
		key = "tooltipGuild",
	},
	{
		type = "CheckButton",
		text = "Use list view",
		tooltip = "Shows all modules as lists instead of their default UI",
		key = "useListView",
		func = function()
			if not Vortex.isSearching and Vortex:GetSelectedModule() then
				Vortex:SelectModule(Vortex:GetSelectedModule().name)
				Vortex:CloseAllContainers()
			end
		end,
	},
	{
		type = "CheckButton",
		text = "Search guild banks",
		tooltip = "Includes guild banks in search results",
		key = "searchGuild",
	},
	{
		type = "Dropdown",
		text = "Default module",
		tooltip = "Module to be selected each time you login.",
		key = "defaultModule",
		menuList = Vortex.sortedModules,
		properties = {
			text = function(value) return Vortex:GetModuleTitle(value) end,
		},
	},
}

frame:CreateOptions(options)

local function onClickCharacter(self, character)
	local accountKey, realmKey, characterKey = strsplit(".", character)
	StaticPopup_Show("VORTEX_DELETE_CHARACTER", characterKey, realmKey, character)
	CloseDropDownMenus()
end

local function onClickGuild(self, guild)
	local accountKey, realmKey, guildKey = strsplit(".", guild)
	StaticPopup_Show("VORTEX_DELETE_GUILD", guildKey, realmKey, guild)
	CloseDropDownMenus()
end

StaticPopupDialogs["VORTEX_DELETE_CHARACTER"] = {
	text = "Really delete data for |cffffd200%s - %s|r?",
	button1 = YES,
	button2 = NO,
	OnAccept = function(self, character)
		Vortex:DeleteCharacter(character)
	end,
	hideOnEscape = true,
}

StaticPopupDialogs["VORTEX_DELETE_GUILD"] = {
	text = "Really delete data for |cffffd200%s - %s|r?",
	button1 = YES,
	button2 = NO,
	OnAccept = function(self, guild)
		Vortex:DeleteGuild(guild)
	end,
	hideOnEscape = true,
}

local button = Vortex:CreateButton(frame)
button:SetWidth(96)
button:SetPoint("TOP", frame.controls[#frame.controls], "BOTTOM", 0, -16)
button.rightArrow:Show()
button:SetText("Purge data")
button:SetScript("OnClick", function(self)
	self.menu:Toggle()
end)

button.menu = Vortex:CreateDropdown("Menu")
button.menu.relativeTo = button
button.menu.relativePoint = "TOPRIGHT"
button.menu.xOffset = 0
button.menu.yOffset = 0
button.menu.initialize = function(self, level)
	for i, characterKey in ipairs(Vortex:GetCharacters(UIDROPDOWNMENU_MENU_VALUE)) do
		if characterKey ~= DataStore:GetCharacter() then
			local account, realm, characterName = strsplit(".", characterKey)
			local info = UIDropDownMenu_CreateInfo()
			if Vortex:IsConnectedRealm(realm) then
				info.text = characterName.." - "..realm
			else
				info.text = characterName
			end
			info.func = onClickCharacter
			info.arg1 = characterKey
			info.notCheckable = true
			self:AddButton(info, level)
		end
	end
	for i, guildKey in ipairs(Vortex:GetGuilds(UIDROPDOWNMENU_MENU_VALUE)) do
		if guildKey ~= DataStore:GetGuild() and DataStore:GetGuildBankFaction(guildKey) then
			local account, realm, guildName = strsplit(".", guildKey)
			local info = UIDropDownMenu_CreateInfo()
			if Vortex:IsConnectedRealm(realm) then
				info.text = "<"..guildName.."> - "..realm
			else
				info.text = "<"..guildName..">"
			end
			info.func = onClickGuild
			info.arg1 = guildKey
			info.colorCode = "|cff56a3ff"
			info.notCheckable = true
			self:AddButton(info, level)
		end
	end
	if level == 1 then
		local sortedRealms = {}
		for realm in pairs(DataStore:GetRealms()) do
			if not (realm == GetRealmName() or Vortex:IsConnectedRealm(realm)) then
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
			self:AddButton(info, level)
		end
	end
end

function Vortex:LoadSettings()
	frame:SetDatabase(self.db)
	frame:SetupControls()
	-- self:SetSearchScope(self.db.defaultSearch)
end