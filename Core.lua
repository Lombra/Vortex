local Libra = LibStub("Libra")

local Vortex = Libra:NewAddon(...)
_G.Vortex = Vortex
Libra:EmbedWidgets(Vortex)

local myCharacter = DataStore:GetCharacter()
local myRealm = GetRealmName()

BINDING_HEADER_VORTEX = "Vortex"
BINDING_NAME_VORTEX_TOGGLE = "Toggle Vortex"

local slashCmdHandlers = {
	config = function() InterfaceOptionsFrame_OpenToCategory(Vortex.config) end,
}

SlashCmdList["VORTEX"] = function(msg)
	msg = msg:trim():lower()
	local slashCmdHandler = slashCmdHandlers[msg]
	if not slashCmdHandler then
		ToggleFrame(Vortex.frame)
	else
		slashCmdHandler()
	end
end

SLASH_VORTEX1 = "/vortex"
SLASH_VORTEX2 = "/vx"

local dataobj = LibStub("LibDataBroker-1.1"):NewDataObject("Vortex", {
	type = "launcher",
	label = "Vortex",
	icon = [[Interface\Icons\Achievement_GuildPerk_MobileBanking]],
	OnClick = function(self, button)
		if button == "LeftButton" then
			ToggleFrame(Vortex.frame)
		else
			InterfaceOptionsFrame_OpenToCategory(Vortex.config)
		end
	end,
})

Vortex.modulesSorted = {}

local LIST_PANEL_WIDTH = 128 - PANEL_INSET_RIGHT_OFFSET

local function copyDefaults(src, dst)
	if not src then return {} end
	if not dst then dst = {} end
	for k, v in pairs(src) do
		if type(v) == "table" then
			dst[k] = copyDefaults(v, dst[k])
		elseif type(v) ~= type(dst[k]) then
			dst[k] = v
		end
	end
	return dst
end

local defaults = {
	tooltip = true,
	tooltipBNet = true,
	tooltipGuild = true,
	tooltipModifier = false,
	useListView = false,
	searchGuild = true,
	defaultModule = "All",
	defaultSearch = "realm",
}

function Vortex:OnInitialize()
	if VortexDB and VortexDB.profileKeys then
		wipe(VortexDB)
	end
	VortexDB = copyDefaults(defaults, VortexDB)
	self.db = VortexDB
	self:LoadSettings()
	local character = DataStore:GetCharacter()
	self.selectedCharacter = character
	local accountKey, realmKey, charKey = strsplit(".", character)
	self.characterMenu:SetText(charKey)
end

local function addUI(self)
	local ui = CreateFrame("Frame", nil, Vortex.frame.ui)
	ui:SetAllPoints()
	ui:Hide()
	self.ui = ui
	return ui
end

local moduleMethods = {
	Update = function(self, character)
		Vortex:UpdateModule(self, character)
	end,
	GetList = function(self, character)
		if not self.cache[character] then
			self.cache[character] = self:BuildList(character)
		end
		return self.cache[character]
	end,
	ClearCache = function(self, character)
		self.cache[character] = nil
		Vortex:GetModule("All").cache[character] = nil
		Vortex:ClearSearchResultsCache(character)
	end,
	IncludeContainer = function(self, containerID)
		tinsert(self.containers, containerID)
	end,
	HasContainer = function(self, containerID)
		for i, v in ipairs(self.containers) do
			if v == containerID then
				return true
			end
		end
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
	Refresh = function(self)
		local character = DataStore:GetCharacter()
		self:ClearCache(character)
		if Vortex:GetSelectedModule() == self and Vortex:GetSelectedCharacter() == character then
			self:Update(character)
		end
	end,
	UpdateUI = function(self, character)
		for i, containerID in ipairs(self.containers) do
			Vortex:UpdateContainer(containerID, character)
		end
	end,
}

function Vortex:OnModuleCreated(name, table)
	local module = self:CreateUI(name, table.label)
	if table.altUI then
		addUI(table)
	end
	if table.items == nil then
		table.items = true
	end
	if table.search == nil then
		table.search = true
	end
	for k, v in pairs(moduleMethods) do table[k] = v end
	table.cache = {}
	table.containers = {}
	tinsert(self.modulesSorted, name)
end

function Vortex:SelectModule(moduleName)
	local selectedModule = self:GetSelectedModule()
	local module = self:GetModule(moduleName)
	if selectedModule then
		selectedModule.button:UnlockHighlight()
		selectedModule.button.highlight:SetDesaturated(false)
		if selectedModule.altUI then
			selectedModule.ui:Hide()
		end
	end
	self.selectedModule = module
	module.button:LockHighlight()
	module.button.highlight:SetDesaturated(false)
	local selectedCharacter = self:GetSelectedCharacter()
	local showList = not module.altUI or self.db.useListView
	if not showList then
		module.ui:Show()
	end
	self.frame.list:SetShown(showList)
	self.frame.ui:SetShown(not showList)
	self.frame:SetWidth(self:GetSelectedFrame() and self:GetSelectedFrame().width or (not showList and module.width or PANEL_DEFAULT_WIDTH) + LIST_PANEL_WIDTH)
	UpdateUIPanelPositions(self.frame)
	module:Update(selectedCharacter)
end

function Vortex:GetSelectedModule()
	return self.selectedModule
end

function Vortex:UpdateModule(module, character)
	if self:IsSearching() then return end
	local showList = not module.altUI or self.db.useListView
	if showList then
		self:SetList(module:GetList(character))
		self:ApplyFilters()
	else
		module:UpdateUI(character)
	end
end

function Vortex:SelectCharacter(character)
	self.selectedCharacter = character
	local accountKey, realmKey, charKey = strsplit(".", character)
	self.characterMenu:SetText(charKey)
	self:CloseAllContainers()
	self:StopSearch()
	-- self:UpdateModule(self:GetSelectedModule(), character)
	self:SelectModule(self:GetSelectedModule().name)
end

function Vortex:GetSelectedCharacter()
	return self.selectedCharacter
end

local sortedCharacters = {}

function Vortex:GetCharacters(realm)
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

function Vortex:DeleteCharacter(character)
	local accountKey, realmKey, charKey = strsplit(".", character)
	DataStore:DeleteCharacter(charKey, realmKey, accountKey)
	if character == self:GetSelectedCharacter() then
		self:SelectCharacter(DataStore:GetCharacter())
	end
	self:GetModule("All").cache[character] = nil
	self:ClearSearchResultsCache(character)
	-- character array for this realm will need to be rebuilt
	sortedCharacters[realmKey] = nil
end

function Vortex:DeleteGuild(guild)
	local accountKey, realmKey, guildKey = strsplit(".", guild)
	DataStore:DeleteGuild(guildKey, realmKey, accountKey)
	if guild == self:GetSelectedGuild() then
		self:SelectGuild(DataStore:GetGuild())
	end
	self:ClearSearchResultsCache()
end

function Vortex:AddSlashCommand(command, handler)
	slashCmdHandlers[command] = handler
end