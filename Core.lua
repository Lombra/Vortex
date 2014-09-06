local Libra = LibStub("Libra")

local Vortex = Libra:NewAddon(...)
_G.Vortex = Vortex
Libra:EmbedWidgets(Vortex)

local myCharacter = DataStore:GetCharacter()
local myRealm = GetRealmName()

local connectedRealms = {}
local sortedCharacters = {}
local sortedGuilds = {}

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

Vortex.sortedModules = {}

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
	defaultModule = "Character",
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
	local account, realm, charKey = strsplit(".", character)
	self.characterMenu:SetText(charKey)
	self:RegisterEvent("PLAYER_LOGIN")
	self:RegisterEvent("PLAYER_GUILD_UPDATE")
end

function Vortex:PLAYER_LOGIN()
	local _, realm = UnitFullName("player")
	for i, v in ipairs(GetAutoCompleteRealms() or {}) do
		if v ~= realm then
			connectedRealms[v] = true
		end
	end
end

function Vortex:PLAYER_GUILD_UPDATE()
	-- guild array for this realm will need to be rebuilt
	sortedGuilds[myRealm] = nil
end

function Vortex:IsConnectedRealm(realm)
	return connectedRealms[realm:gsub("[ -]", "")]
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
		-- Vortex:GetModule("All").cache[character] = nil
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
	self:CreateUI(name, table.label)
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
	tinsert(self.sortedModules, name)
end

function Vortex:SelectModule(moduleName)
	local selectedModule = self:GetSelectedModule()
	-- fall back to first module if the given one doesn't exist
	local module = self:GetModule(moduleName) or self:GetModule(self.sortedModules[1])
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

function Vortex:GetModuleTitle(moduleName)
	local module = Vortex:GetModule(moduleName)
	return module and module.label or moduleName
end

function Vortex:SelectCharacter(character)
	self.selectedCharacter = character
	local accountKey, realmKey, charKey = strsplit(".", character)
	if realmKey == myRealm then
		self.characterMenu:SetText(charKey)
	else
		self.characterMenu:SetText(charKey.." - "..realmKey)
	end
	self:CloseAllContainers()
	self:StopSearch()
	-- self:UpdateModule(self:GetSelectedModule(), character)
	self:SelectModule(self:GetSelectedModule().name)
end

function Vortex:GetSelectedCharacter()
	return self.selectedCharacter
end

local function sortCharacters(a, b)
	local accountKeyA, realmKeyA, charKeyA = strsplit(".", a)
	local accountKeyB, realmKeyB, charKeyB = strsplit(".", b)
	if realmKeyA ~= realmKeyB then
		-- your own realm gets sorted before others
		if realmKeyA == myRealm then
			return true
		end
		if realmKeyB == myRealm then
			return false
		end
		return realmKeyA < realmKeyB
	else
		return charKeyA < charKeyB
	end
end

function Vortex:GetCharacters(realm)
	realm = realm or myRealm
	if sortedCharacters[realm] then
		return sortedCharacters[realm]
	end
	local chars = {}
	sortedCharacters[realm] = chars
	for k in pairs(DataStore:GetRealms()) do
		if k == realm or (realm == myRealm and self:IsConnectedRealm(k)) then
			for characterName, characterKey in pairs(DataStore:GetCharacters(k)) do
				if characterKey ~= myCharacter then
					tinsert(chars, characterKey)
				end
			end
		end
	end
	sort(chars, sortCharacters)
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
	-- self:GetModule("All").cache[character] = nil
	self:ClearSearchResultsCache(character)
	-- character array for this realm will need to be rebuilt
	sortedCharacters[realmKey] = nil
end

local function sortGuilds(a, b)
	local accountKeyA, realmKeyA, charKeyA = strsplit(".", a)
	local accountKeyB, realmKeyB, charKeyB = strsplit(".", b)
	if realmKeyA ~= realmKeyB then
		-- your own realm gets sorted before others
		if realmKeyA == myRealm then
			return true
		end
		if realmKeyB == myRealm then
			return false
		end
		return realmKeyA < realmKeyB
	else
		return charKeyA < charKeyB
	end
end

function Vortex:GetGuilds(realm)
	realm = realm or myRealm
	if sortedGuilds[realm] then
		return sortedGuilds[realm]
	end
	local guilds = {}
	sortedGuilds[realm] = guilds
	local myGuild = DataStore:GetGuild()
	for k in pairs(DataStore:GetRealms()) do
		if k == realm or (realm == myRealm and self:IsConnectedRealm(k)) then
			for guildName, guildKey in pairs(DataStore:GetGuilds(k)) do
				if guildKey ~= myGuild then
					tinsert(guilds, guildKey)
				end
			end
		end
	end
	sort(guilds, sortGuilds)
	if realm == myRealm and GetGuildInfo("player") then
		tinsert(guilds, 1, myGuild)
	end
	return guilds
end

function Vortex:DeleteGuild(guild)
	local accountKey, realmKey, guildKey = strsplit(".", guild)
	DataStore:DeleteGuild(guildKey, realmKey, accountKey)
	if guild == self:GetSelectedGuild() then
		self:SelectGuild(DataStore:GetGuild())
	end
	self:ClearSearchResultsCache()
	-- character array for this realm will need to be rebuilt
	sortedGuilds[realmKey] = nil
end

function Vortex:AddSlashCommand(command, handler)
	slashCmdHandlers[command] = handler
end