local addonName, addon = ...

local Libra = LibStub("Libra")

local myCharacter = DataStore:GetCharacter()
local myRealm = GetRealmName()

BINDING_HEADER_VORTEX = "Vortex"
BINDING_NAME_VORTEX_TOGGLE = "Toggle Vortex"

SlashCmdList["VORTEX"] = function(msg)
	ToggleFrame(addon.frame)
end
SLASH_VORTEX1 = "/vortex"
SLASH_VORTEX2 = "/vx"

local dataobj = LibStub("LibDataBroker-1.1"):NewDataObject("Vortex", {
	type = "launcher",
	label = "Vortex",
	icon = [[Interface\Icons\Achievement_GuildPerk_MobileBanking]],
	OnClick = function(self, button)
		-- if button == "LeftButton" then
			ToggleFrame(addon.frame)
		-- else
		-- end
	end,
	-- OnTooltipShow = function()
		-- addon:ShowTooltip(k)
	-- end
})

addon = Libra:NewAddon("Vortex", addon)

Vortex = addon

local LIST_PANEL_WIDTH = 128 - PANEL_INSET_RIGHT_OFFSET

local defaults = {
	global = {
		tooltip = true,
		tooltipBNet = true,
		tooltipGuild = true,
		useListView = false,
		searchGuild = true,
		defaultModule = "All",
		defaultSearch = "Realm",
	},
}

function addon:OnInitialize()
	self.db = LibStub("AceDB-3.0"):New("VortexDB", defaults)
	self.db = self.db.global
	self:LoadSettings()
	local character = DataStore:GetCharacter()
	self.selectedCharacter = character
	local accountKey, realmKey, charKey = strsplit(".", character)
	self.characterMenu:SetText(charKey)
end

local function addUI(self)
	local ui = CreateFrame("Frame", nil, addon.frame.ui)
	ui:SetAllPoints()
	ui:Hide()
	self.ui = ui
	return ui
end

local moduleMethods = {
	Update = function(self, character)
		addon:UpdateModule(self, character)
	end,
	GetList = function(self, character)
		if not self.cache[character] then
			self.cache[character] = self:BuildList(character)
		end
		return self.cache[character]
	end,
	ClearCache = function(self, character)
		self.cache[character] = nil
		addon:GetModule("All").cache[character] = nil
		addon:ClearSearchResultsCache()
	end,
	IncludeContainer = function(self, containerID)
		tinsert(self.containers, containerID)
	end,
	BuildList = function(self, character)
		local list = {}
		for i, containerID in ipairs(self.containers) do
			local container = DataStore:GetContainer(character, containerID)
			for i = 1, DataStore:GetContainerSize(character, containerID) do
				local itemID, itemLink, count = DataStore:GetSlotInfo(container, i)
				if itemID or itemLink then
					tinsert(list, {
						id = itemID,
						link = itemLink,
						count = count,
					})
				end
			end
		end
		return list
	end,
	UpdateUI = function(self, character)
		for i, containerID in ipairs(self.containers) do
			addon:UpdateContainer(containerID, character)
		end
	end,
}

function addon:OnModuleCreated(name, table)
	local module = self:CreateUI(name, table.label)
	if table.altUI then
		addUI(table)
	end
	for k, v in pairs(moduleMethods) do table[k] = v end
	table.cache = {}
	table.containers = {}
end

function addon:SelectModule(moduleName)
	local selectedModule = self:GetSelectedModule()
	local module = self:GetModule(moduleName)
	if module == selectedModule then
		-- return
	end
	if selectedModule then
		selectedModule.button:UnlockHighlight()
		if selectedModule.altUI then
			selectedModule.ui:Hide()
		end
	end
	self.selectedModule = module
	module.button:LockHighlight()
	module.button.highlight:SetDesaturated(false)
	local selectedCharacter = self:GetSelectedCharacter()
	local showList = not module.altUI or self.db.useListView
	if showList then
		self:SetList(module:GetList(selectedCharacter))
	else
		module.ui:Show()
	end
	module:Update(selectedCharacter)
	self.frame.list:SetShown(showList)
	self.frame.ui:SetShown(not showList)
	self.frame:SetWidth((not showList and module.width or PANEL_DEFAULT_WIDTH) + LIST_PANEL_WIDTH)
	UpdateUIPanelPositions(self.frame)
end

function addon:GetSelectedModule()
	return self.selectedModule
end

function addon:UpdateModule(module, character)
	local showList = not module.altUI or self.db.useListView
	if showList then
		self:SetList(module:GetList(character))
		self:ApplyFilters()
	else
		module:UpdateUI(character)
	end
end

function addon:SelectCharacter(character)
	self.selectedCharacter = character
	local accountKey, realmKey, charKey = strsplit(".", character)
	self.characterMenu:SetText(charKey)
	self:GetSelectedModule():Update(character)
	self:CloseAllContainers()
	if self.isSearching then
		self:StopSearch()
	end
end

function addon:GetSelectedCharacter()
	return self.selectedCharacter
end

local sortedCharacters = {}

function addon:GetCharacters(realm)
	realm = realm or myRealm
	if sortedCharacters[realm] then
		return sortedCharacters[realm]
	end
	local chars = {}
	sortedCharacters[realm] = chars
	local characters = DataStore:GetCharacters(realm)
	for characterName, characterKey in pairs(characters) do
		if characterKey ~= myCharacter then
			tinsert(chars, characterKey)
		end
	end
	sort(chars)
	if realm == myRealm then
		tinsert(chars, 1, myCharacter)
	end
	return chars
end