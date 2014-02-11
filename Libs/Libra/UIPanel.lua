local Libra = LibStub("Libra")
local UIPanel = Libra:GetModule("UIPanel", 1)
if not UIPanel then return end

local UIPanelPrototype = CreateFrame("Frame")
local mt = {__index = UIPanelPrototype}

local function constructor(self, name)
	local panel = setmetatable(CreateFrame("Frame", name, UIParent, "ButtonFrameTemplate"), mt)
	
	tinsert(UISpecialFrames, name)
	UIPanelWindows[name] = {
		area = "left",
		pushable = 1,
		whileDead = true,
	}
	
	return panel
end

UIPanel.constructor = constructor
Libra.CreateUIPanel = constructor

local methods = {
	ShowPortrait = ButtonFrameTemplate_ShowPortrait,
	HidePortrait = ButtonFrameTemplate_HidePortrait,
	ShowAttic = ButtonFrameTemplate_ShowAttic,
	HideAttic = ButtonFrameTemplate_HideAttic,
	ShowButtonBar = ButtonFrameTemplate_ShowButtonBar,
}

for k, v in pairs(methods) do
	UIPanelPrototype[k] = v
end

function UIPanelPrototype:SetTitleText(text)
	self.TitleText:SetText(text)
end

function UIPanelPrototype:HideButtonBar()
	ButtonFrameTemplate_HideButtonBar(self)
	self.Inset:SetPoint("BOTTOMRIGHT", PANEL_INSET_RIGHT_OFFSET, PANEL_INSET_BOTTOM_OFFSET + 2)
end

--[[ functions to manage tab interfaces where only one tab of a group may be selected
function PanelTemplates_Tab_OnClick(self, frame)
	PanelTemplates_SetTab(frame, self:GetID())
end

function PanelTemplates_SetTab(frame, id)
	frame.selectedTab = id;
	PanelTemplates_UpdateTabs(frame);
end

function PanelTemplates_GetSelectedTab(frame)
	return frame.selectedTab;
end

function PanelTemplates_UpdateTabs(frame)
	if ( frame.selectedTab ) then
		local tab;
		for i=1, frame.numTabs, 1 do
			tab = _G[frame:GetName().."Tab"..i];
			if ( tab.isDisabled ) then
				PanelTemplates_SetDisabledTabState(tab);
			elseif ( i == frame.selectedTab ) then
				PanelTemplates_SelectTab(tab);
			else
				PanelTemplates_DeselectTab(tab);
			end
		end
	end
end

function PanelTemplates_GetTabWidth(tab)
	local tabName = tab:GetName();

	local sideWidths = 2 * _G[tabName.."Left"]:GetWidth();
	return tab:GetTextWidth() + sideWidths;
end

function PanelTemplates_TabResize(tab, padding, absoluteSize, minWidth, maxWidth, absoluteTextSize)
	local tabName = tab:GetName();
	
	local buttonMiddle = _G[tabName.."Middle"];
	local buttonMiddleDisabled = _G[tabName.."MiddleDisabled"];
	local sideWidths = 2 * _G[tabName.."Left"]:GetWidth();
	local tabText = _G[tab:GetName().."Text"];
	local width, tabWidth;
	local textWidth;
	if ( absoluteTextSize ) then
		textWidth = absoluteTextSize;
	else
		tabText:SetWidth(0);
		textWidth = tabText:GetWidth();
	end
	-- If there's an absolute size specified then use it
	if ( absoluteSize ) then
		if ( absoluteSize < sideWidths) then
			width = 1;
			tabWidth = sideWidths
		else
			width = absoluteSize - sideWidths;
			tabWidth = absoluteSize
		end
		tabText:SetWidth(width);
	else
		-- Otherwise try to use padding
		if ( padding ) then
			width = textWidth + padding;
		else
			width = textWidth + 24;
		end
		-- If greater than the maxWidth then cap it
		if ( maxWidth and width > maxWidth ) then
			if ( padding ) then
				width = maxWidth + padding;
			else
				width = maxWidth + 24;
			end
			tabText:SetWidth(width);
		else
			tabText:SetWidth(0);
		end
		if (minWidth and width < minWidth) then
			width = minWidth;
		end
		tabWidth = width + sideWidths;
	end
	
	if ( buttonMiddle ) then
		buttonMiddle:SetWidth(width);
	end
	if ( buttonMiddleDisabled ) then
		buttonMiddleDisabled:SetWidth(width);
	end
	
	tab:SetWidth(tabWidth);
	local highlightTexture = _G[tabName.."HighlightTexture"];
	if ( highlightTexture ) then
		highlightTexture:SetWidth(tabWidth);
	end
end

function PanelTemplates_SetNumTabs(frame, numTabs)
	frame.numTabs = numTabs;
end

function PanelTemplates_DisableTab(frame, index)
	_G[frame:GetName().."Tab"..index].isDisabled = 1;
	PanelTemplates_UpdateTabs(frame);
end

function PanelTemplates_EnableTab(frame, index)
	local tab = _G[frame:GetName().."Tab"..index];
	tab.isDisabled = nil;
	-- Reset text color
	tab:SetDisabledFontObject(GameFontHighlightSmall);
	PanelTemplates_UpdateTabs(frame);
end

function PanelTemplates_DeselectTab(tab)
	local name = tab:GetName();
	_G[name.."Left"]:Show();
	_G[name.."Middle"]:Show();
	_G[name.."Right"]:Show();
	--tab:UnlockHighlight();
	tab:Enable();
	_G[name.."Text"]:SetPoint("CENTER", tab, "CENTER", (tab.deselectedTextX or 0), (tab.deselectedTextY or 2));
		
	_G[name.."LeftDisabled"]:Hide();
	_G[name.."MiddleDisabled"]:Hide();
	_G[name.."RightDisabled"]:Hide();
end

function PanelTemplates_SelectTab(tab)
	local name = tab:GetName();
	_G[name.."Left"]:Hide();
	_G[name.."Middle"]:Hide();
	_G[name.."Right"]:Hide();
	--tab:LockHighlight();
	tab:Disable();
	tab:SetDisabledFontObject(GameFontHighlightSmall);
	_G[name.."Text"]:SetPoint("CENTER", tab, "CENTER", (tab.selectedTextX or 0), (tab.selectedTextY or -3));
	
	_G[name.."LeftDisabled"]:Show();
	_G[name.."MiddleDisabled"]:Show();
	_G[name.."RightDisabled"]:Show();
	
	if ( GameTooltip:IsOwned(tab) ) then
		GameTooltip:Hide();
	end
end

function PanelTemplates_SetDisabledTabState(tab)
	local name = tab:GetName();
	_G[name.."Left"]:Show();
	_G[name.."Middle"]:Show();
	_G[name.."Right"]:Show();
	--tab:UnlockHighlight();
	tab:Disable();
	tab.text = tab:GetText();
	-- Gray out text
	tab:SetDisabledFontObject(GameFontDisableSmall);
	_G[name.."LeftDisabled"]:Hide();
	_G[name.."MiddleDisabled"]:Hide();
	_G[name.."RightDisabled"]:Hide();
end

]]