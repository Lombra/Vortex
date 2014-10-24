local lib = LibStub:NewLibrary("LibItemButton", 1)

if not lib then return end

local GetItemInfo = GetItemInfo

lib.callbacks = lib.callbacks or {}

lib.frame = lib.frame or CreateFrame("Frame")
lib.frame:SetScript("OnEvent", lib.frame.Show)
lib.frame:SetScript("OnUpdate", onUpdate)
lib.frame:Hide()

lib.buttonRegistry = lib.buttonRegistry or {}
lib.buttonCategory = lib.buttonCategory or {}
lib.buttonItems = lib.buttonItems or {}

function lib:RegisterButton(button, category)
	self.buttonRegistry[button] = true
	self.buttonCategory[button] = category
	self:Fire("OnButtonRegistered", button, category)
end

function lib:UpdateButton(button, item)
	-- if item == self.buttonItems[button] then return end
	self.buttonItems[button] = item
	self:Fire("OnButtonUpdate", button, item, self.buttonCategory[button])
end

function lib:GetRegisteredButtons(category)
	return self.buttonRegistry
end

function lib:GetButtonCategory(button)
	return self.buttonCategory[button]
end

function lib:Fire(event, ...)
	if not self.callbacks[event] then return end
	for k, v in pairs(self.callbacks[event]) do
		v(k, ...)
	end
end

function lib:RegisterInitCallback(target, callback, category)
	if type(callback) == "string" then
		callback = target[callback]
	end
	
	for button in pairs(self:GetRegisteredButtons()) do
		local category2 = self.buttonCategory[button]
		if not category or category2 == category then
			callback(target, button, category2)
		end
	end
	
	self.callbacks["OnButtonRegistered"] = self.callbacks["OnButtonRegistered"] or {}
	self.callbacks["OnButtonRegistered"][target] = callback
end

function lib:RegisterUpdateCallback(target, callback, category)
	if type(callback) == "string" then
		callback = target[callback]
	end
	
	self.callbacks["OnButtonUpdate"] = self.callbacks["OnButtonUpdate"] or {}
	self.callbacks["OnButtonUpdate"][target] = callback
end


local frame = CreateFrame("Frame")
frame:SetScript("OnEvent", function(self, event, ...)
	self[event](self, ...)
end)

do	-- inventory
	local INVENTORY_BUTTONS = {
		[INVSLOT_HEAD] 		= CharacterHeadSlot,
		[INVSLOT_NECK]		= CharacterNeckSlot,
		[INVSLOT_SHOULDER]	= CharacterShoulderSlot,
		[INVSLOT_BACK]		= CharacterBackSlot,
		[INVSLOT_CHEST]		= CharacterChestSlot,
		[INVSLOT_BODY]		= CharacterShirtSlot,
		[INVSLOT_TABARD]	= CharacterTabardSlot,
		[INVSLOT_WRIST]		= CharacterWristSlot,
		[INVSLOT_HAND]		= CharacterHandsSlot,
		[INVSLOT_WAIST]		= CharacterWaistSlot,
		[INVSLOT_LEGS]		= CharacterLegsSlot,
		[INVSLOT_FEET]		= CharacterFeetSlot,
		[INVSLOT_FINGER1]	= CharacterFinger0Slot,
		[INVSLOT_FINGER2]	= CharacterFinger1Slot,
		[INVSLOT_TRINKET1]	= CharacterTrinket0Slot,
		[INVSLOT_TRINKET2]	= CharacterTrinket1Slot,
		[INVSLOT_MAINHAND]	= CharacterMainHandSlot,
		[INVSLOT_OFFHAND]	= CharacterSecondaryHandSlot,
	}
	
	for i, button in pairs(INVENTORY_BUTTONS) do
		lib:RegisterButton(button, "INVENTORY", true)
	end
	
	frame:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
	function frame:PLAYER_EQUIPMENT_CHANGED(slot, hasItem)
		lib:UpdateButton(INVENTORY_BUTTONS[slot], GetInventoryItemLink("player", slot))
	end
end

do	-- bags
	for bag = 1, NUM_CONTAINER_FRAMES do
		for slot = 1, MAX_CONTAINER_ITEMS do
			lib:RegisterButton(_G[format("ContainerFrame%dItem%d", bag, slot)], "BAG", true)
		end
	end
	
	frame:RegisterEvent("BAG_UPDATE_DELAYED")
	function frame:BAG_UPDATE_DELAYED()
		for button in pairs(lib:GetRegisteredButtons()) do
			if lib.buttonCategory[button] == "BAG" then
				lib:UpdateButton(button, GetContainerItemLink(button:GetParent():GetID(), button:GetID()))
			end
		end
	end
	
	hooksecurefunc("ContainerFrame_GenerateFrame", function(frame, size, id)
		local frameName = frame:GetName()
		if not frameName:match("^ContainerFrame%d+$") then return end
		for i = 1, size do
			local button = _G[frameName.."Item"..i]
			lib:UpdateButton(button, GetContainerItemLink(id, button:GetID()))
		end
	end)
end

do	-- bank
	local bankButtons = {}
	
	for slot = 1, NUM_BANKGENERIC_SLOTS do
		lib:RegisterButton(BankSlotsFrame["Item"..slot], "BANK", true)
		bankButtons[slot] = BankSlotsFrame["Item"..slot]
	end
	
	frame:RegisterEvent("PLAYERBANKSLOTS_CHANGED")
	function frame:PLAYERBANKSLOTS_CHANGED(slot)
		lib:UpdateButton(bankButtons[slot], GetContainerItemLink(BANK_CONTAINER, slot))
	end
	
	frame:RegisterEvent("BANKFRAME_OPENED")
	function frame:BANKFRAME_OPENED()
		for slot, button in ipairs(bankButtons) do
			lib:UpdateButton(button, GetContainerItemLink(BANK_CONTAINER, slot))
		end
	end
	
	
	local reagentBankButtons = {}
	
	local reagentSlotsRegistered
	
	ReagentBankFrame:HookScript("OnShow", function(self)
		if not reagentSlotsRegistered then
			for slot = 1, 98 do
				local button = ReagentBankFrame["Item"..slot]
				lib:RegisterButton(button, "REAGENTBANK", true)
				lib:UpdateButton(button, GetContainerItemLink(REAGENTBANK_CONTAINER, slot))
				reagentBankButtons[slot] = button
			end
			reagentSlotsRegistered = true
		end
	end)
	
	frame:RegisterEvent("PLAYERREAGENTBANKSLOTS_CHANGED")
	function frame:PLAYERREAGENTBANKSLOTS_CHANGED(slot)
		lib:UpdateButton(reagentBankButtons[slot], GetContainerItemLink(REAGENTBANK_CONTAINER, slot))
	end
end

do	-- void storage
	frame:RegisterEvent("VOID_STORAGE_OPEN")
	function frame:VOID_STORAGE_OPEN()
		for slot = 1, 80 do
			local button = _G["VoidStorageStorageButton"..slot]
			-- button.Count = button:CreateFontString(nil, nil, "NumberFontNormal", 2)
			-- button.Count:SetPoint("BOTTOMRIGHT", -5, 2)
			-- button.Count:SetJustifyH("RIGHT")
			-- button.Count:Hide()
			-- button.Stock = button:CreateFontString(nil, nil, "NumberFontNormalYellow", 2)
			-- button.Stock:SetPoint("TOPLEFT", 0, -2)
			-- button.Stock:SetJustifyH("LEFT")
			-- button.Stock:Hide()
			lib:RegisterButton(button, "VOIDSTORAGE", true)
			lib:UpdateButton(button, GetVoidItemHyperlinkString((VoidStorageFrame.page - 1) * 80 + slot))
		end
		
		hooksecurefunc("VoidStorage_ItemsUpdate", function(doDeposit, doContents)
			for slot = 1, 80 do
				lib:UpdateButton(_G["VoidStorageStorageButton"..slot], GetVoidItemHyperlinkString((VoidStorageFrame.page - 1) * 80 + slot))
			end
		end)
		
		self:UnregisterEvent("VOID_STORAGE_OPEN")
		self.VOID_STORAGE_OPEN = nil
	end
end

do	-- guild bank
	frame:RegisterEvent("GUILDBANKFRAME_OPENED")
	function frame:GUILDBANKFRAME_OPENED()
		for column = 1, NUM_GUILDBANK_COLUMNS do
			for i = 1, NUM_SLOTS_PER_GUILDBANK_GROUP do
				lib:RegisterButton(_G["GuildBankColumn"..column.."Button"..i], "GUILDBANK", true)
			end
		end
		
		hooksecurefunc("GuildBankFrame_Update", function()
			local tab = GetCurrentGuildBankTab()
			for column = 1, NUM_GUILDBANK_COLUMNS do
				for i = 1, NUM_SLOTS_PER_GUILDBANK_GROUP do
					local slot = column * NUM_SLOTS_PER_GUILDBANK_GROUP + i
					lib:UpdateButton(_G["GuildBankColumn"..column.."Button"..i], GetGuildBankItemLink(tab, slot))
				end
			end
		end)
		
		self:UnregisterEvent("GUILDBANKFRAME_OPENED")
		self.GUILDBANKFRAME_OPENED = nil
	end
end

do	-- mail
	-- for i = 1, INBOXITEMS_TO_DISPLAY do
		-- lib:RegisterButton(_G["MailItem"..i.."Button"], "MAIL", true)
	-- end
	
	-- frame:RegisterEvent("MAIL_INBOX_UPDATE")
	-- function frame:MAIL_INBOX_UPDATE()
		-- for slot = 1, INBOXITEMS_TO_DISPLAY do
			-- lib:UpdateButton(voidButtons[slot], GetVoidItemInfo(tab, slot))
		-- end
	-- end
end

do	-- merchant
	for i = 1, MERCHANT_ITEMS_PER_PAGE do
		lib:RegisterButton(_G["MerchantItem"..i.."ItemButton"], "MERCHANT", true)
	end
	
	hooksecurefunc("MerchantFrame_UpdateMerchantInfo", function()
		for i = 1, min(MERCHANT_ITEMS_PER_PAGE, GetMerchantNumItems()) do
			local slot = MERCHANT_ITEMS_PER_PAGE * (MerchantFrame.page - 1) + i
			lib:UpdateButton(_G["MerchantItem"..i.."ItemButton"], GetMerchantItemLink(slot))
		end
	end)
	
	for i = 1, BUYBACK_ITEMS_PER_PAGE do
		lib:RegisterButton(_G["MerchantItem"..i.."ItemButton"], "MERCHANT", true)
	end
	
	hooksecurefunc("MerchantFrame_UpdateBuybackInfo", function()
		for i = 1, GetMerchantNumItems() do
			lib:UpdateButton(_G["MerchantItem"..i.."ItemButton"], GetBuybackItemLink(i))
		end
	end)
end

do	-- auction
	frame:RegisterEvent("AUCTION_HOUSE_SHOW")
	function frame:AUCTION_HOUSE_SHOW()
		for i = 1, NUM_BROWSE_TO_DISPLAY do
			local buttonName = "BrowseButton"..i.."Item"
			local button = _G[buttonName]
			button.icon = _G[buttonName.."IconTexture"]
			button.Count = _G[buttonName.."Count"]
			-- button.Stock = _G[buttonName.."Stock"]
			-- button.searchOverlay = button:CreateTexture(nil, "OVERLAY")
			-- button.searchOverlay:SetAllPoints()
			-- button.searchOverlay:SetTexture(0, 0, 0, 0.8)
			-- button.searchOverlay:Hide()
			lib:RegisterButton(button, "AUCTION_BROWSE", true)
		end
		
		hooksecurefunc("AuctionFrameBrowse_Update", function()
			for i = 1, NUM_BROWSE_TO_DISPLAY do
				local link = GetAuctionItemLink("list", BrowseScrollFrame.offset + i)
				lib:UpdateButton(_G["BrowseButton"..i.."Item"], link)
			end
		end)
		
		for i = 1, NUM_BIDS_TO_DISPLAY do
			local buttonName = "BidButton"..i.."Item"
			local button = _G[buttonName]
			button.icon = _G[buttonName.."IconTexture"]
			button.Count = _G[buttonName.."Count"]
			-- button.Stock = _G[buttonName.."Stock"]
			-- button.searchOverlay = button:CreateTexture(nil, "OVERLAY")
			-- button.searchOverlay:SetAllPoints()
			-- button.searchOverlay:SetTexture(0, 0, 0, 0.8)
			-- button.searchOverlay:Hide()
			lib:RegisterButton(button, "AUCTION_BID", true)
		end
		
		hooksecurefunc("AuctionFrameBid_Update", function()
			for i = 1, NUM_BIDS_TO_DISPLAY do
				local link = GetAuctionItemLink("bidder", BidScrollFrame.offset + i)
				lib:UpdateButton(_G["BidButton"..i.."Item"], link)
			end
		end)
		
		for i = 1, NUM_AUCTIONS_TO_DISPLAY do
			local buttonName = "AuctionsButton"..i.."Item"
			local button = _G[buttonName]
			button.icon = _G[buttonName.."IconTexture"]
			button.Count = _G[buttonName.."Count"]
			-- button.Stock = _G[buttonName.."Stock"]
			-- button.searchOverlay = button:CreateTexture(nil, "OVERLAY")
			-- button.searchOverlay:SetAllPoints()
			-- button.searchOverlay:SetTexture(0, 0, 0, 0.8)
			-- button.searchOverlay:Hide()
			lib:RegisterButton(button, "AUCTION_BID", true)
		end
		
		hooksecurefunc("AuctionFrameAuctions_Update", function()
			for i = 1, NUM_AUCTIONS_TO_DISPLAY do
				local link = GetAuctionItemLink("owner", AuctionsScrollFrame.offset + i)
				lib:UpdateButton(_G["AuctionsButton"..i.."Item"], link)
			end
		end)
		
		self:UnregisterEvent("AUCTION_HOUSE_SHOW")
		self.AUCTION_HOUSE_SHOW = nil
	end
end

do	-- black market
	frame:RegisterEvent("BLACK_MARKET_OPEN")
	function frame:BLACK_MARKET_OPEN()
		local button = BlackMarketFrame.HotDeal.Item
		button.icon = button.IconTexture
		-- button.searchOverlay = button:CreateTexture(nil, "OVERLAY")
		-- button.searchOverlay:SetAllPoints()
		-- button.searchOverlay:SetTexture(0, 0, 0, 0.8)
		-- button.searchOverlay:Hide()
		-- button.IconBorder = button:CreateTexture(nil, "OVERLAY")
		-- button.IconBorder:SetSize(37, 37)
		-- button.IconBorder:SetPoint("CENTER")
		-- button.IconBorder:SetTexture([[Interface\Common\WhiteIconFrame]])
		-- button.IconBorder:Hide()
		lib:RegisterButton(button, "BLACKMARKET_HOT", true)
		
		hooksecurefunc("BlackMarketFrame_UpdateHotItem", function(self)
			local link = select(15,  C_BlackMarket.GetHotItem())
			lib:UpdateButton(BlackMarketFrame.HotDeal.Item, link)
		end)
		
		for i, button in ipairs(BlackMarketScrollFrame.buttons) do
			button.icon = button.IconTexture
			-- button.searchOverlay = button:CreateTexture(nil, "OVERLAY")
			-- button.searchOverlay:SetAllPoints()
			-- button.searchOverlay:SetTexture(0, 0, 0, 0.8)
			-- button.searchOverlay:Hide()
			-- button.IconBorder = button:CreateTexture(nil, "OVERLAY")
			-- button.IconBorder:SetSize(37, 37)
			-- button.IconBorder:SetPoint("CENTER")
			-- button.IconBorder:SetTexture([[Interface\Common\WhiteIconFrame]])
			-- button.IconBorder:Hide()
			lib:RegisterButton(button.Item, "BLACKMARKET", true)
		end
		
		hooksecurefunc("BlackMarketScrollFrame_Update", function()
			local buttons = BlackMarketScrollFrame.buttons
			for i = 1, min(#buttons, C_BlackMarket.GetNumItems()) do
				local link = select(15,  C_BlackMarket.GetItemInfoByIndex(BlackMarketScrollFrame.offset + i))
				lib:UpdateButton(buttons[i].Item, link)
			end
		end)
		
		self:UnregisterEvent("BLACK_MARKET_OPEN")
		self.BLACK_MARKET_OPEN = nil
	end
end

do	-- loot
	for i = 1, LOOTFRAME_NUMBUTTONS do
		lib:RegisterButton(_G["LootButton"..i], "LOOT", true)
	end
	
	hooksecurefunc("LootFrame_UpdateButton", function(index)
		local slot = LOOTFRAME_NUMBUTTONS * (LootFrame.page - 1) + index
		lib:UpdateButton(_G["LootButton"..index], GetLootSlotLink(slot))
	end)
	
	for i=1, NUM_GROUP_LOOT_FRAMES do
		local frame = _G["GroupLootFrame"..i]
		local button = frame.IconFrame
		button.icon = button.Icon
		-- button.Stock = button:CreateFontString(nil, nil, "NumberFontNormalYellow", 2)
		-- button.Stock:SetPoint("TOPLEFT", 0, -2)
		-- button.Stock:SetJustifyH("LEFT")
		-- button.Stock:Hide()
		-- button.searchOverlay = button:CreateTexture(nil, "OVERLAY")
		-- button.searchOverlay:SetAllPoints()
		-- button.searchOverlay:SetTexture(0, 0, 0, 0.8)
		-- button.searchOverlay:Hide()
		-- button.IconBorder = button:CreateTexture(nil, "OVERLAY")
		-- button.IconBorder:SetSize(37, 37)
		-- button.IconBorder:SetPoint("CENTER")
		-- button.IconBorder:SetTexture([[Interface\Common\WhiteIconFrame]])
		-- button.IconBorder:Hide()
		lib:RegisterButton(button, "GROUPLOOT", true)
		frame:HookScript("OnShow", function(self)
			local link = GetLootRollItemLink(self.rollID)
			lib:UpdateButton(self.IconFrame, link)
		end)
	end
end