local _, Vortex = ...

local Bags = Vortex:NewModule("Bags")

for i = 0, 4 do	
	Bags:IncludeContainer(i)
end

function Bags:OnInitialize()
	DataStore_Inventory.RegisterMessage(self, "DATASTORE_CONTAINER_UPDATED")
end

function Bags:DATASTORE_CONTAINER_UPDATED(event, bagID)
	if self:HasContainer(bagID) then
		self:Refresh()
	end
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