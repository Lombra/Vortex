local addonName, addon = ...

local Bags = addon:NewModule("Bags")

for i = 0, 4 do	
	Bags:IncludeContainer(i)
end

function Bags:OnInitialize()
	self:RegisterEvent("PLAYER_LOGIN")
end

function Bags:PLAYER_LOGIN()
	self:RegisterEvent("BAG_UPDATE_DELAYED", "Refresh")
end

function Bags:Refresh()
	local character = DataStore:GetCharacter()
	self:ClearCache(character)
	if addon:GetSelectedModule() == self and addon:GetSelectedCharacter() == character then
		self:Update(character)
		for i, containerID in ipairs(self.containers) do
			addon:UpdateContainer(containerID, character, buttons)
		end
	end
end

function Bags:GetItemCount(character, itemID)
	return DataStore:GetContainerItemCount(character, itemID)
end