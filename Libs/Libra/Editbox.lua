local Libra = LibStub("Libra")
local Editbox = Libra:GetModule("Editbox", 1)
if not Editbox then return end

local function constructor(self, parent)
	local name = self:GetWidgetName()
	local editbox = CreateFrame("EditBox", name, parent, "SearchBoxTemplate")
	_G[name] = nil
	return editbox
end

Editbox.constructor = constructor
Libra.CreateEditbox = constructor