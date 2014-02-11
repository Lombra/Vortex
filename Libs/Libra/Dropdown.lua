local Libra = LibStub("Libra")
local Dropdown = Libra:GetModule("Dropdown", 1)
if not Dropdown then return end

Dropdown.objects = Dropdown.objects or {}
Dropdown.Prototype = Dropdown.Prototype or CreateFrame("Frame")
local mt = {__index = Dropdown.Prototype}

local DropdownPrototype = Dropdown.Prototype

local function setHeight() end

local function constructor(self, parent, createListFrame)
	local dropdown
	if createListFrame then
		local name = self:GetWidgetName(name)
		dropdown = CreateFrame("Frame", name, parent, "UIDropDownMenuTemplate")
		dropdown.label = dropdown:CreateFontString(name.."Label", "BACKGROUND", "GameFontNormalSmall")
		dropdown.label:SetPoint("BOTTOMLEFT", dropdown, "TOPLEFT", 16, 3)
	else
		-- adding a SetHeight dummy lets us use a simple table instead of a frame, no side effects noticed so far
		dropdown = {}
		dropdown.SetHeight = setHeight
	end
	
	setmetatable(dropdown, mt)
	Dropdown.objects[dropdown] = true
	
	return dropdown
end

Dropdown.constructor = constructor
Libra.CreateDropdown = constructor

local methods = {
	Enable = UIDropDownMenu_EnableDropDown,
	Disable = UIDropDownMenu_DisableDropDown,
	IsEnabled = UIDropDownMenu_IsEnabled,
	JustifyText = UIDropDownMenu_JustifyText,
	SetSelectedValue = UIDropDownMenu_SetSelectedValue,
	SetText = UIDropDownMenu_SetText,
	GetText = UIDropDownMenu_GetText,
	Refresh = UIDropDownMenu_Refresh,
}

for k, v in pairs(methods) do
	DropdownPrototype[k] = v
end

function DropdownPrototype:ToggleMenu(value, level, ...)
	ToggleDropDownMenu(level, value, self, ...)
end

function DropdownPrototype:HideMenu(level)
	if UIDropDownMenu_GetCurrentDropDown() == self then
		HideDropDownMenu(level)
	end
end

function DropdownPrototype:CloseMenus(level)
	if UIDropDownMenu_GetCurrentDropDown() == self then
		CloseDropDownMenus(level)
	end
end

function DropdownPrototype:AddButton(info, level)
	self.displayMode = self._displayMode
	self.selectedValue = self._selectedValue
	UIDropDownMenu_AddButton(info, level)
	self.displayMode = nil
	self.selectedValue = nil
end

function DropdownPrototype:SetSelectedValue(value, useValue)
	self._selectedValue = value
	self.selectedValue = value
	self:Refresh(useValue)
	self.selectedValue = nil
end

function DropdownPrototype:GetSelectedValue()
	return self._selectedValue
end

function DropdownPrototype:Rebuild()
	if UIDropDownMenu_GetCurrentDropDown() == self then
		level = level or 1
		local listFrame = _G["DropDownList"..level]
		local point, relativeTo, relativePoint, xOffset, yOffset = listFrame:GetPoint()
		self:HideMenu(level)
		self:ToggleMenu(listFrame.value, level)
		listFrame:SetPoint(point, relativeTo, relativePoint, xOffset, yOffset)
	end
end

local setWidth = DropdownPrototype.SetWidth

function DropdownPrototype:SetWidth(width, padding)
	_G[self:GetName().."Middle"]:SetWidth(width)
	local defaultPadding = 25
	if padding then
		setWidth(self, width + padding)
		_G[self:GetName().."Text"]:SetWidth(width)
	else
		setWidth(self, width + defaultPadding + defaultPadding)
		_G[self:GetName().."Text"]:SetWidth(width - defaultPadding)
	end
	self.noResize = 1
end

function DropdownPrototype:SetLabel(text)
	self.label:SetText(text)
end

function DropdownPrototype:SetEnabled(enable)
	if enable then
		self:Enable()
	else
		self:Disable()
	end
end

function DropdownPrototype:SetDisplayMode(mode)
	self._displayMode = mode
end

local function createScrollButtons(listFrame)
	local scrollUp = listFrame.scrollUp or CreateFrame("Button", nil, listFrame)
	scrollUp:SetSize(16, 16)
	scrollUp:SetPoint("TOP")
	scrollUp:SetScript("OnClick", scroll)
	scrollUp.delta = -1
	scrollUp._owner = listFrame
	listFrame.scrollUp = scrollUp

	local scrollUpTex = scrollUp:CreateTexture()
	scrollUpTex:SetAllPoints()
	scrollUpTex:SetTexture([[Interface\Calendar\MoreArrow]])
	scrollUpTex:SetTexCoord(0, 1, 1, 0)

	local scrollDown = listFrame.scrollDown or CreateFrame("Button", nil, listFrame)
	scrollDown:SetSize(16, 16)
	scrollDown:SetPoint("BOTTOM")
	scrollDown:SetScript("OnClick", scroll)
	scrollDown.delta = 1
	scrollDown._owner = listFrame
	listFrame.scrollDown = scrollDown

	local scrollDownTex = scrollDown:CreateTexture()
	scrollDownTex:SetAllPoints()
	scrollDownTex:SetTexture([[Interface\Calendar\MoreArrow]])
end

local scrollButtons = setmetatable({}, {
	__index = function(self, listFrame)
		createScrollButtons(listFrame)
		self[listFrame] = {
			up = listFrame.scrollUp,
			down = listFrame.scrollDown,
		}
		return self[listFrame]
	end,
})

local numShownButtons

local function update(self, level)
	for i = 1, UIDROPDOWNMENU_MAXBUTTONS do
		local button = _G["DropDownList"..level.."Button"..i]
		local _, _, _, x, y = button:GetPoint()
		local y = -((button:GetID() - 1 - self._scroll) * UIDROPDOWNMENU_BUTTON_HEIGHT) - UIDROPDOWNMENU_BORDER_HEIGHT
		button:SetPoint("TOPLEFT", x, y)
		button:SetShown(i > self._scroll and i <= (numShownButtons + self._scroll))
	end
	scrollButtons[_G["DropDownList"..level]].up:SetShown(self._scroll > 0)
	scrollButtons[_G["DropDownList"..level]].down:SetShown(self._scroll < _G["DropDownList"..level].numButtons - numShownButtons)
end

local function scroll(self, delta)
	self._owner._scroll = self._owner._scroll - (delta or self.delta)
	self._owner._scroll = min(self._owner._scroll, self.numButtons - numShownButtons)
	self._owner._scroll = max(self._owner._scroll, 0)
	update(self._owner, self:GetID())
end

hooksecurefunc("ToggleDropDownMenu", function(level, value, dropdownFrame, anchorName, xOffset, yOffset, menuList, button, autoHideDelay)
	level = level or 1
	if level ~= 1 then
		dropdownFrame = dropdownFrame or UIDROPDOWNMENU_OPEN_MENU
	end
	if not Dropdown.objects[dropdownFrame] then return end
	local listFrameName = "DropDownList"..level
	local listFrame = _G[listFrameName]
	if dropdownFrame and dropdownFrame._displayMode == "MENU" then
		_G[listFrameName.."Backdrop"]:Hide()
		_G[listFrameName.."MenuBackdrop"]:Show()
	end
	
	listFrame.value = value
	numShownButtons = floor((UIParent:GetHeight() - UIDROPDOWNMENU_BORDER_HEIGHT * 2) / UIDROPDOWNMENU_BUTTON_HEIGHT)
	local scrollable = numShownButtons < listFrame.numButtons
	if scrollable then
		-- make scrollable
		dropdownFrame._scroll = 0
		listFrame._owner = dropdownFrame
		listFrame:SetScript("OnMouseWheel", scroll)
		listFrame:SetHeight((numShownButtons * UIDROPDOWNMENU_BUTTON_HEIGHT) + (UIDROPDOWNMENU_BORDER_HEIGHT * 2))
		local point, anchorFrame, relativePoint, x, y = listFrame:GetPoint()
		local offTop = (GetScreenHeight() - listFrame:GetTop())-- / listFrame:GetScale()
		listFrame:SetPoint(point, anchorFrame, relativePoint, x, y + offTop)
		update(dropdownFrame, level)
	else
		listFrame:SetScript("OnMouseWheel", nil)
		scrollButtons[listFrame].up:Hide()
		scrollButtons[listFrame].down:Hide()
	end
end)