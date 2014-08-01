local _, Vortex = ...

local ItemInfo = Vortex.ItemInfo

local myRealm = GetRealmName()

local BUTTON_HEIGHT = 26
local BUTTON_OFFSET = 3

local searchFilter = "realm"

local strfind = string.find
local strlower = string.lower
local format = format
local gsub = gsub
local strsplit = strsplit

local function onEditFocusLost(self)
	if Vortex:GetFilter("name") then
		self:SetTextColor(1, 1, 1)
		self.searchIcon:SetVertexColor(1, 1, 1)
	end
	-- local text = self:GetText()
	-- if not Vortex:GetFilter("name") then
		-- if searchFilter == "UI" then
			-- local module = Vortex:GetSelectedModule()
			-- module:Search()
		-- elseif Vortex.isSearching then
			-- Vortex:SetList(nil)
		-- end
	-- end
end

local function onEditFocusGained(self)
	if not Vortex:GetFilter("name") and searchFilter ~= "UI" then
	end
end

local searchBox = Vortex:CreateEditbox(Vortex.frame.character, true)
searchBox:SetWidth(128)
searchBox:SetPoint("TOPRIGHT", Vortex.frame, -16, -33)
searchBox.clearFunc = function()
	-- Vortex:ClearFilter("name")
	-- Vortex:SetList(nil)
	Vortex:StopSearch()
	Vortex:SelectModule(Vortex:GetSelectedModule().name)
end
searchBox:HookScript("OnEditFocusLost", onEditFocusLost)
-- searchBox:HookScript("OnEditFocusGained", onEditFocusGained)
searchBox:SetScript("OnEnterPressed", EditBox_ClearFocus)
searchBox:SetScript("OnTextChanged", function(self, isUserInput)
	if not isUserInput then
		return
	end
	
	local text = self:GetText()
	if text ~= "" then
		Vortex:SetFilter("name", text:lower())
		if searchFilter ~= "UI" then
			Vortex:Search()
		end
	else
		Vortex:ClearFilter("name")
		if searchFilter ~= "UI" then
			Vortex:StopSearch(true)
			Vortex:SelectModule(Vortex:GetSelectedModule().name)
			return
		end
	end
	
	local module = Vortex:GetSelectedModule()
	if searchFilter == "UI" then
		module:Search(Vortex:GetFilter("name"))
	else
		local list = Vortex:GetCache()
		-- Vortex:SetList(list) -- don't UpdateList here
		Vortex.list = list or empty
		Vortex.filteredList = nil
	end
	
	Vortex:ApplyFilters()
end)

SlashCmdList["VORTEX_SEARCH"] = function(msg)
	if msg:trim() == "" then return end
	ShowUIPanel(Vortex.frame)
	searchBox:SetText(msg)
	searchBox.clearButton:Show()
	Vortex:SetFilter("name", msg)
	Vortex:Search()
	Vortex.list = Vortex:GetCache() or empty
	Vortex.filteredList = nil
	Vortex:ApplyFilters()
end

SLASH_VORTEX_SEARCH1 = "/vxs"

local searchMenuOptions = {
	-- "UI",
	"char",
	"realm",
	"all",
}

local searchMenuText = {
	char = format("Current character (%s)", UnitName("player")),
	realm = format("Current realm (%s)", myRealm),
	all = "All realms",
}

local searchMenuText2 = {
	char = "Character",
	realm = "Realm",
	all = "All realms",
}

local function onClick(self, arg1)
	Vortex:SetSearchScope(arg1)
end

local searchScopeMenu = Vortex:CreateDropdown("Frame", Vortex.frame.character)
searchScopeMenu:SetWidth(128)
searchScopeMenu:SetPoint("RIGHT", searchBox, "LEFT", 0, -2)
searchScopeMenu:SetText("|cffffd200Search:|r "..searchFilter)
searchScopeMenu.initialize = function(self, level)
	for i, option in ipairs(searchMenuOptions) do
		local info = UIDropDownMenu_CreateInfo()
		info.text = searchMenuText[option]
		info.func = onClick
		info.arg1 = option
		info.checked = (option == searchFilter)
		self:AddButton(info, level)
	end
end

local filterBar = CreateFrame("Frame", nil, Vortex.frame.list)
filterBar:SetPoint("TOP", 0, -4)
filterBar:SetPoint("LEFT", 4, 0)
filterBar:SetPoint("RIGHT", -26, 0)
filterBar:SetHeight(16)
filterBar:SetBackdrop({
	bgFile = [[Interface\Buttons\UI-Listbox-Highlight2]],
})
filterBar:SetBackdropColor(0.6, 0.75, 1.0, 0.5)
filterBar:Hide()

filterBar.text = filterBar:CreateFontString(nil, nil, "GameFontHighlightSmall")
filterBar.text:SetPoint("LEFT", 5, 0)

filterBar.clear = CreateFrame("Button", nil, filterBar)
filterBar.clear:SetSize(16, 16)
filterBar.clear:SetPoint("RIGHT", -2, 0)
filterBar.clear:SetAlpha(0.5)
filterBar.clear:SetScript("OnEnter", function(self)
	self:SetAlpha(1.0)
end)
filterBar.clear:SetScript("OnLeave", function(self)
	self:SetAlpha(0.5)
end)
filterBar.clear:SetScript("OnClick", function(self)
	-- searchBox:SetText(SEARCH)
	-- searchBox:ClearFocus()
	-- searchBox.clearButton:Hide()
	-- Vortex:ClearFilter("name")
	Vortex:StopSearch()
	Vortex:SelectModule(Vortex:GetSelectedModule().name)
end)
filterBar.clear:SetScript("OnMouseDown", function(self)
	self.texture:SetPoint("CENTER", 1, -1)
end)
filterBar.clear:SetScript("OnMouseUp", function(self)
	self.texture:SetPoint("CENTER", 0, 0)
end)
filterBar.clear:SetScript("OnHide", function(self)
	self.texture:SetPoint("CENTER", 0, 0)
end)

filterBar.clear.texture = filterBar.clear:CreateTexture()
filterBar.clear.texture:SetSize(16, 16)
filterBar.clear.texture:SetPoint("CENTER")
filterBar.clear.texture:SetTexture([[Interface\FriendsFrame\ClearBroadcastIcon]])

local function match(item, searchString)
	if not item then
		return
	end
	if not searchString then
		return true, true
	end
	local item = ItemInfo[item]
	if not item then
		Vortex:QueueUIUpdate()
	end
	if (item and strfind(lower(item.name), strlower(searchString), nil, true)) then
		return true, true
	end
	return false, true
end

function Vortex:SearchContainer(containerID, character)
	local character = self:GetSelectedCharacter()
	local bag = DataStore:GetContainer(character, containerID)
	local bagFrame = self:GetContainerFrame(containerID)
	local buttons = self:GetContainerButtons(containerID)
	local foundInBag
	local searchString = self:GetFilter("name")
	for i = 1, DataStore:GetContainerSize(character, containerID) do
		local itemID, itemLink = DataStore:GetSlotInfo(bag, bagFrame and bagFrame:IsShown() and buttons[i]:GetID() or i)
		local match, hasItem = match(itemID or itemLink, searchString)
		if match then
			foundInBag = true
		end
		if not bagFrame or bagFrame:IsShown() then
			buttons[i].searchOverlay:SetShown(hasItem and not match)
		elseif foundInBag then
			break
		end
	end
	if bagFrame and bagFrame.containerButton.item then
		bagFrame.containerButton.searchOverlay:SetShown(not foundInBag)
	end
end

local function dynamic(offset)
	local height = 0
	
	for i, item in ipairs(Vortex:GetList()) do
		local buttonHeight = Vortex:GetItemSearchResultText((item.linkType and item.linkType..":"..item.id) or item.id or item.link)
		
		if offset and height + buttonHeight >= offset then
			return i - 1, offset - height
		else
			height = height + buttonHeight
		end
	end
	return height
end

local LIST_PANEL_WIDTH = 128 - PANEL_INSET_RIGHT_OFFSET
function Vortex:Search()
	self.isSearching = true
	filterBar:Show()
	self.scroll:SetPoint("TOP", filterBar, "BOTTOM")
	self.scroll.dynamic = dynamic
	searchBox:SetTextColor(1, 1, 1)
	searchBox.searchIcon:SetVertexColor(1, 1, 1)
	self.frame.ui:Hide()
	self.frame.list:Show()
	self.frame:SetWidth(PANEL_DEFAULT_WIDTH + LIST_PANEL_WIDTH)
	UpdateUIPanelPositions(self.frame)
	local module = self:GetSelectedModule()
	module.button.highlight:SetDesaturated(true)
end

function Vortex:StopSearch(keepFocus)
	if not self:IsSearching() then return end
	self.isSearching = false
	filterBar:Hide()
	self.scroll:SetPoint("TOP", self.frame.Inset, 0, -4)
	self.scroll.dynamic = nil
	if not keepFocus then
		searchBox:SetText(SEARCH)
		searchBox:ClearFocus()
		searchBox.clearButton:Hide()
		searchBox:SetTextColor(0.5, 0.5, 0.5)
		searchBox.searchIcon:SetVertexColor(0.6, 0.6, 0.6)
	end
	self:ClearFilter("name")
	-- local module = self:GetSelectedModule()
	-- module:Search()
end

function Vortex:IsSearching()
	return self.isSearching
end

function Vortex:SetSearchScope(scope)
	searchFilter = scope
	self:ClearSearchResultsCache()
	searchScopeMenu:SetText("|cffffd200Search:|r "..searchMenuText2[scope])
	local module = self:GetSelectedModule()
	local character = self:GetSelectedCharacter()
	if scope ~= "UI" then
		if self:GetFilter("name") then
			self:Search()
			self.list = self:GetCache()
			self:ApplyFilters()
		end
	else
		self:StopSearch()
		module:Search(self:GetFilter("name"))
	end
end

local cache = {}

local function getCache(character)
	if not cache[character] then
		local added = {}
		local list = {}
		for k, module in Vortex:IterateModules() do
			if module.search then
				for i, v in ipairs(module:GetList(character)) do
					local item = (v.linkType and v.linkType..":"..v.id) or v.id or v.link
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
		cache[character] = list
	end
	return cache[character]
end

local resultsCache = {} -- list of results passed to SetList
local searchResults = {} -- details about each item, owners

local function mergeCharacterItems(list, character)
	local items = getCache(character)
	for i = 1, #items do
		local v = items[i]
		local itemID = (v.linkType and v.linkType..":"..v.id) or v.id or v.link
		if itemID then
			local item = searchResults[itemID]
			if not item then
				item = {}
				tinsert(list, v)
				searchResults[itemID] = item
			end
			item[character] = (item[character] or 0) + (v.count or 1)
		end
	end
end

local function mergeItems(list, realm)
	for k, character in pairs(DataStore:GetCharacters(realm)) do
		mergeCharacterItems(list, character)
	end
	if Vortex.db.searchGuild then
		for k, guild in pairs(DataStore:GetGuilds(realm)) do
			for i = 1, 8 do
				local tab = DataStore:GetGuildBankTab(guild, i)
				for j = 1, 98 do
					local itemID, itemLink, count = DataStore:GetSlotInfo(tab, j)
					local itemID2 = itemID or itemLink
					if itemID2 then
						local item = searchResults[itemID2]
						if not item then
							item = {}
							tinsert(list, {
								id = itemID,
								link = itemLink,
							})
							searchResults[itemID2] = item
						end
						-- add a special character so we can distinguish the entry as a guild
						item[guild.."|"] = (item[guild.."|"] or 0) + count
					end
				end
			end
		end
	end
end

local doUpdateResults = true

function Vortex:GetCache()
	if doUpdateResults then
		doUpdateResults = nil
		wipe(resultsCache)
		wipe(searchResults)
		if searchFilter == "char" then
			mergeCharacterItems(resultsCache, self:GetSelectedCharacter())
		elseif searchFilter == "realm" then
			mergeItems(resultsCache)
		elseif searchFilter == "all" then
			for realm in pairs(DataStore:GetRealms()) do
				mergeItems(resultsCache, realm)
			end
		end
	end
	return resultsCache
end

local function sortItemResults(a, b)
	-- guilds gets sorted after characters
	local a, countA = gsub(a, "|$", "")
	local b, countB = gsub(b, "|$", "")
	if countA ~= countB then
		if countA > 0 then
			return false
		end
		if countB > 0 then
			return true
		end
	end
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

local itemButtonHeight = {}
local itemOwners = {}
local itemAmount = {}

local dummy = Vortex.frame:CreateFontString(nil, nil, "GameFontHighlightSmallLeft")
dummy:SetSpacing(1)

function Vortex:GetItemSearchResultText(item)
	if not self.isSearching then
		return BUTTON_HEIGHT + BUTTON_OFFSET
	end
	-- return cached search info if available
	if itemButtonHeight[item] then
		return itemButtonHeight[item], itemOwners[item], itemAmount[item]
	end
	local result = searchResults[item]
	-- if not result then
		-- return BUTTON_HEIGHT + BUTTON_OFFSET
	-- end
	local owners = ""
	local total = 0
	if result then
		local sorted = {}
		for k, v in pairs(result) do
			tinsert(sorted, k)
			total = total + v
		end
		sort(sorted, sortItemResults)
		
		for i, v in ipairs(sorted) do
			local accountKey, realm, name = strsplit(".", v)
			local name, count = gsub(name, "|$", "")
			if count > 0 then
				name = "|cff56a3ff<"..name..">|r"
			end
			if realm == myRealm then
				sorted[i] = format("|cffffffff%d|r %s", result[v], name)
			else
				sorted[i] = format("|cffffffff%d|r %s - %s", result[v], name, realm)
			end
		end
		owners = table.concat(sorted, "\n")
	end
	dummy:SetText(owners)
	local buttonHeight = max(BUTTON_HEIGHT, 15 + dummy:GetHeight() + 1) + BUTTON_OFFSET
	itemButtonHeight[item] = buttonHeight
	itemOwners[item] = owners
	itemAmount[item] = total
	return buttonHeight, owners, total
end

function Vortex:ClearSearchResultsCache(character)
	doUpdateResults = true
	wipe(itemButtonHeight)
	wipe(itemOwners)
	wipe(itemAmount)
	if character then
		cache[character] = nil
	end
end

Vortex.filterArgs = {}

local function filterApproves(itemID)
	local filterArg = Vortex:GetFilter("name")
	if not filterArg then
		return true
	end
	if not itemID then return end
	local item = ItemInfo[itemID]
	if not item then
		Vortex:QueueListUpdate()
		return
	end
	return strfind(strlower(item.name), filterArg, nil, true) ~= nil
end

local filteredList = {}

function Vortex:ApplyFilters()
	wipe(filteredList)
	for i, v in ipairs(self:GetList(true)) do
		if filterApproves((v.linkType and v.linkType..":"..v.id) or v.id or v.link) then
			tinsert(filteredList, v)
		end
	end
	self:SetFilteredList(filteredList)
	if self:IsSearching() then
		filterBar.text:SetText(#self:GetList().." search results")
	end
end

function Vortex:SetFilter(filter, arg)
	self.filterArgs[filter] = arg
end

function Vortex:GetFilter(filter)
	return self.filterArgs[filter]
end

function Vortex:ClearFilter(filter)
	self.filterArgs[filter] = nil
end

function Vortex:SetFilteredList(list)
	self.filteredList = list
	self:UpdateList()
end

function Vortex:ClearFilters()
	wipe(self.filterArgs)
	self.filteredList = nil
	-- self:UpdateList()
end