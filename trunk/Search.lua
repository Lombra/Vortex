local addonName, addon = ...

local Libra = LibStub("Libra")

local ItemInfo = addon.ItemInfo

local myRealm = GetRealmName()

local BUTTON_HEIGHT = 26
local BUTTON_OFFSET = 3

local searchFilter = "Realm"

local strfind = string.find
local strlower = string.lower
local format = format
local gsub = gsub
local strsplit = strsplit

local function onEditFocusLost(self)
	self:SetFontObject("ChatFontSmall")
	self:SetTextColor(0.5, 0.5, 0.5)
	local text = self:GetText()
	if not addon:GetFilter("name") then
		if searchFilter == "UI" then
			local module = addon:GetSelectedModule()
			module:Search()
		elseif addon.isSearching then
			addon:SetList(nil)
		end
	end
end

local function onEditFocusGained(self)
	self:SetTextColor(1, 1, 1)
	if not addon:GetFilter("name") and searchFilter ~= "UI" then
	end
end

local searchBox = Libra:CreateEditbox(VortexFrameTab1.frame)
searchBox:SetSize(128, 20)
searchBox:SetPoint("TOPRIGHT", addon.frame, -16, -33)
searchBox:SetFontObject("ChatFontSmall")
searchBox:SetTextColor(0.5, 0.5, 0.5)
searchBox.clearFunc = function()
	addon:ClearFilter("name")
end
searchBox:HookScript("OnEditFocusLost", onEditFocusLost)
searchBox:HookScript("OnEditFocusGained", onEditFocusGained)
searchBox:SetScript("OnEnterPressed", EditBox_ClearFocus)
searchBox:SetScript("OnTextChanged", function(self, isUserInput)
	if not isUserInput then
		return
	end
	
	local text = self:GetText()
	if text ~= "" then
		addon:SetFilter("name", text:lower())
		if searchFilter ~= "UI" then
			addon:Search()
		end
	else
		addon:ClearFilter("name")
		if searchFilter ~= "UI" then
			addon:SetList(nil)
			return
		end
	end
	
	local module = addon:GetSelectedModule()
	if searchFilter == "UI" then
		module:Search(addon:GetFilter("name"))
	else
		local list = addon:GetCache()
		-- addon:SetList(list) -- don't UpdateList here
		addon.list = list or empty
		addon.filteredList = nil
	end
	
	addon:ApplyFilters()
end)

local searchMenuOptions = {
	-- "UI",
	"Character",
	"Realm",
	"All",
}

local function onClick(self, arg1)
	searchFilter = arg1
	addon:ClearSearchResultsCache()
	self.owner:SetText("|cffffd200Search:|r "..searchFilter)
	local module = addon:GetSelectedModule()
	local character = addon:GetSelectedCharacter()
	if searchFilter ~= "UI" then
		if addon:GetFilter("name") then
			addon:Search()
			local list = addon:GetCache()
			-- addon:SetList(list) -- don't UpdateList here
			addon.list = list or empty
			addon.filteredList = nil
			addon:ApplyFilters()
		end
	else
		addon:StopSearch()
		module:Search(addon:GetFilter("name"))
	end
end

local button = Libra:CreateDropdown(VortexFrameTab1.frame, true)
button:SetWidth(128)
button:SetPoint("RIGHT", searchBox, "LEFT", 0, -2)
-- button:SetLabel("Search in:")
-- button:JustifyText("LEFT")
button:SetText("|cffffd200Search:|r "..searchFilter)
button.initialize = function(self, level)
	for i, option in ipairs(searchMenuOptions) do
		local info = UIDropDownMenu_CreateInfo()
		info.text = option
		info.func = onClick
		info.arg1 = option
		info.checked = option == searchFilter
		info.owner = self
		UIDropDownMenu_AddButton(info, level)
	end
end

local filterBar = CreateFrame("Frame", nil, addon.frame.list)
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
filterBar.clear:SetNormalTexture([[Interface\FriendsFrame\ClearBroadcastIcon]])
filterBar.clear:SetAlpha(0.5)
filterBar.clear:SetScript("OnEnter", function(self)
	self:SetAlpha(1.0)
end)
filterBar.clear:SetScript("OnLeave", function(self)
	self:SetAlpha(0.5)
end)
filterBar.clear:SetScript("OnClick", function(self)
	searchBox:SetText(SEARCH)
	searchBox:ClearFocus()
	searchBox.clearButton:Hide()
	addon:ClearFilter("name")
	addon:StopSearch()
end)
filterBar.clear:SetScript("OnMouseDown", function(self)
	self:SetPoint("RIGHT", -1, -1)
end)
filterBar.clear:SetScript("OnMouseUp", function(self)
	self:SetPoint("RIGHT", -2, 0)
end)
filterBar.clear:SetScript("OnHide", function(self)
	self:SetPoint("RIGHT", -2, 0)
end)
addon.filterBar = filterBar

local function match(item, searchString)
	if not item then
		return
	end
	if not searchString then
		return true, true
	end
	local item = ItemInfo[item]
	if not item then
		doUpdateUI = true
	end
	if (item and strfind(lower(item.name), strlower(searchString), nil, true)) then
		return true, true
	end
	return false, true
end

function addon:SearchContainer(containerID, character)
	local character = addon:GetSelectedCharacter()
	local bag = DataStore:GetContainer(character, containerID)
	local bagFrame = self:GetContainerFrame(containerID)
	local buttons = self:GetContainerButtons(containerID)
	local foundInBag
	local searchString = addon:GetFilter("name")
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
	local heightLeft = offset
	
	for i, item in ipairs(addon:GetList()) do
		local buttonHeight = addon:GetItemSearchResultText(item.id or item.link)
		
		if heightLeft - buttonHeight <= 0 then
			return i - 1, heightLeft
		else
			heightLeft = heightLeft - buttonHeight
		end
	end
end

local LIST_PANEL_WIDTH = 128 - PANEL_INSET_RIGHT_OFFSET
function addon:Search()
	addon.isSearching = true
	self.filterBar:Show()
	self.filterBar.text:SetText("Searching in "..searchFilter)
	self.scroll:SetPoint("TOP", self.filterBar, "BOTTOM")
	self.scroll.dynamic = dynamic
	self.frame.ui:Hide()
	self.frame.list:Show()
	self.frame:SetWidth(PANEL_DEFAULT_WIDTH + LIST_PANEL_WIDTH)
	UpdateUIPanelPositions(self.frame)
	local module = addon:GetSelectedModule()
	module.button.highlight:SetDesaturated(true)
end

function addon:StopSearch()
	addon.isSearching = false
	self.filterBar:Hide()
	self.scroll:SetPoint("TOP", self.frame.Inset, 0, -4)
	self.scroll.dynamic = nil
	searchBox:SetText(SEARCH)
	searchBox:ClearFocus()
	searchBox.clearButton:Hide()
	addon:ClearFilter("name")
	local module = addon:GetSelectedModule()
	self:SelectModule(module.name)
	-- module:Search()
end

local resultsCache = {} -- list of results passed to SetList
local searchResults = {} -- details about each item, owners

local function mergeCharacterItems(list, character)
	local All = addon:GetModule("All")
	local items = All:GetList(character)
	for i = 1, #items do
		local v = items[i]
		local itemID = v.id or v.link
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
	local All = addon:GetModule("All")
	for k, character in pairs(DataStore:GetCharacters(realm)) do
		mergeCharacterItems(list, character)
	end
	if addon.db.searchGuildBanks then
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

function addon:GetCache()
	if doUpdateResults then
		doUpdateResults = nil
		wipe(resultsCache)
		wipe(searchResults)
		if searchFilter == "Character" then
			mergeCharacterItems(resultsCache, self:GetSelectedCharacter())
		elseif searchFilter == "Realm" then
			mergeItems(resultsCache)
		elseif searchFilter == "All" then
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

local c = {}
local c2 = {}
local c3 = {}

local dummy = addon.frame:CreateFontString(nil, nil, "GameFontHighlightSmallLeft")
dummy:SetSpacing(1)

function addon:GetItemSearchResultText(item)
	if not self.isSearching then
		return BUTTON_HEIGHT + BUTTON_OFFSET
	end
	-- return cached search info if available
	if c[item] then return c[item], c2[item], c3[item] end
	local result = searchResults[item]
	if not result then return BUTTON_HEIGHT + BUTTON_OFFSET end
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
				name = "|cffffd200<"..name..">|r"
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
	c[item] = buttonHeight
	c2[item] = owners
	c3[item] = total
	return buttonHeight, owners, total
end

function addon:ClearSearchResultsCache()
	doUpdateResults = true
	wipe(c)
	wipe(c2)
	wipe(c3)
end

addon.filterArgs = {}

local function FilterApproves(itemID)
	local filterArg = addon:GetFilter("name")
	if not filterArg then
		return true
	end
	if not itemID then return end
	local item = ItemInfo[itemID]
	if not item then
		addon:QueueListUpdate()
		return
	end
	return strfind(strlower(item.name), filterArg, nil, true) ~= nil
end

local filteredList = {}

function addon:ApplyFilters()
	local t = debugprofilestop()
	wipe(filteredList)
	for i, v in ipairs(self:GetList(true)) do
		if FilterApproves(v.id or v.link) then
			tinsert(filteredList, v)
		end
	end
	-- print("filter:", debugprofilestop() - t)
	self:SetFilteredList(filteredList)
end

function addon:SetFilter(filter, arg)
	self.filterArgs[filter] = arg
end

function addon:GetFilter(filter)
	return self.filterArgs[filter]
end

function addon:ClearFilter(filter)
	self.filterArgs[filter] = nil
end

function addon:SetFilteredList(list)
	self.filteredList = list
	self:UpdateList()
end

function addon:ClearFilters()
	wipe(self.filterArgs)
	self.filteredList = nil
	-- self:UpdateList()
end