local _, Vortex = ...

local Bags = Vortex:NewModule("Bags")

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
	if Vortex:GetSelectedCharacter() == character then
		for i, containerID in ipairs(self.containers) do
			Vortex:UpdateContainer(containerID, character)
		end
		if Vortex:GetSelectedModule() == self then
			self:Update(character)
		end
	end
end

function Bags:GetItemCount(character, itemID)
	return DataStore:GetContainerItemCount(character, itemID)
end