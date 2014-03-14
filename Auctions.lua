local _, Vortex = ...

local Auctions = Vortex:NewModule("Auctions")

function Auctions:OnInitialize()
	self:RegisterEvent("PLAYER_LOGIN")
end

local function OnAuctionHouseClosed(self)
	self:UnregisterEvent("AUCTION_MULTISELL_START")
	self:UnregisterEvent("AUCTION_MULTISELL_UPDATE")
	self:UnregisterEvent("AUCTION_HOUSE_CLOSED")
	self:Refresh()
end

local function OnAuctionHouseShow(self)
	-- when going to the AH, listen to multi-sell
	self:RegisterEvent("AUCTION_MULTISELL_START", "Refresh")
	self:RegisterEvent("AUCTION_MULTISELL_UPDATE", "Refresh")
	self:RegisterEvent("AUCTION_HOUSE_CLOSED", OnAuctionHouseClosed)
end

function Auctions:PLAYER_LOGIN()
	self:RegisterEvent("AUCTION_HOUSE_SHOW", OnAuctionHouseShow)
end

function Auctions:BuildList(character)
	local list = {}
	for i = 1, DataStore:GetNumAuctions(character) or 0 do
		local isGoblin, itemID, count, name, price1, price2, timeLeft = DataStore:GetAuctionHouseItemInfo(character, "Auctions", i)
		tinsert(list, {
			id = itemID,
			count = count,
		})
	end
	return list
end

function Auctions:GetItemCount(character, itemID)
	return DataStore:GetAuctionHouseItemCount(character, itemID)
end