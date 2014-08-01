local _, Vortex = ...

local Auctions = Vortex:NewModule("Auctions")

function Auctions:OnInitialize()
	DataStore_Auctions.RegisterMessage(self, "DATASTORE_AUCTIONS_UPDATED", "Refresh")
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