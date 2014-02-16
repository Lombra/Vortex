local addonName, addon = ...

local Libra = LibStub("Libra")

local frame = CreateFrame("Frame")
frame.name = addonName
InterfaceOptions_AddCategory(frame)

local title = frame:CreateFontString(nil, nil, "GameFontNormalLarge")
title:SetPoint("TOPLEFT", 16, -16)
title:SetPoint("RIGHT", -16, 0)
title:SetJustifyH("LEFT")
title:SetJustifyV("TOP")
title:SetText(frame.name)

local function onClick(self)
	local checked = self:GetChecked() ~= nil
	PlaySound(checked and "igMainMenuOptionCheckBoxOn" or "igMainMenuOptionCheckBoxOff")
	addon.db[self.setting] = checked
	-- onSet(self, checked)
	if self.func then
		self.func()
	end
end

local function newCheckButton(data)
	local btn = CreateFrame("CheckButton", nil, frame, "OptionsBaseCheckButtonTemplate")
	btn:SetPushedTextOffset(0, 0)
	btn:SetScript("OnClick", onClick)
	-- btn.LoadSetting = btn.SetChecked
	
	local text = btn:CreateFontString(nil, nil, "GameFontHighlight")
	text:SetPoint("LEFT", btn, "RIGHT", 0, 1)
	btn:SetFontString(text)
	-- btn:SetText(data.label)
	
	return btn
end

local options = {
	{
		text = "Add tooltip info",
		key = "tooltip",
	},
	{
		text = "Add tooltip Battle.net info",
		key = "tooltipBNet",
	},
	{
		text = "Add tooltip guild info",
		key = "tooltipGuild",
	},
	{
		text = "Use list view",
		key = "useListView",
		func = function()
			if not addon.isSearching then
				addon:SelectModule(addon:GetSelectedModule().name)
				addon:CloseAllContainers()
			end
		end,
	},
	{
		text = "Search guild banks",
		key = "searchGuild",
	},
}

function addon:LoadSettings()
	for i, option in ipairs(options) do
		local button = newCheckButton()
		if i == 1 then
			button:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -16)
		else
			button:SetPoint("TOP", options[i - 1].button, "BOTTOM", 0, -8)
		end
		button:SetText(option.text)
		button:SetChecked(self.db[option.key])
		button.setting = option.key
		button.func = option.func
		option.button = button
	end
	
	local function onClick(self, module)
		addon.db.defaultModule = module
		self.owner:SetText(module)
	end
	
	local defaultModule = Libra:CreateDropdown(frame, true)
	defaultModule:SetWidth(128)
	defaultModule:SetPoint("TOPLEFT", options[#options].button, "BOTTOMLEFT", -12, -24)
	defaultModule:JustifyText("LEFT")
	defaultModule:SetLabel("Default module")
	defaultModule:SetText(self.db.defaultModule or "All")
	defaultModule.initialize = function(self)
		for i, v in pairs(addon.modules) do
			local info = UIDropDownMenu_CreateInfo()
			info.text = i
			info.func = onClick
			info.arg1 = i
			info.checked = (i == addon.db.defaultModule)
			info.owner = self
			self:AddButton(info)
		end
	end
	
	local scopes = {
		"Character",
		"Realm",
		"All",
	}
	
	local function onClick(self, module)
		addon.db.defaultSearch = module
		self.owner:SetText(module)
	end
	
	local defaultSearch = Libra:CreateDropdown(frame, true)
	defaultSearch:SetWidth(128)
	defaultSearch:SetPoint("TOP", defaultModule, "BOTTOM", 0, -16)
	defaultSearch:JustifyText("LEFT")
	defaultSearch:SetLabel("Default search scope")
	defaultSearch:SetText(self.db.defaultSearch)
	defaultSearch.initialize = function(self)
		for i, v in ipairs(scopes) do
			local info = UIDropDownMenu_CreateInfo()
			info.text = v
			info.func = onClick
			info.arg1 = v
			info.checked = (v == addon.db.defaultSearch)
			info.owner = self
			self:AddButton(info)
		end
	end
	
	self:SetSearchScope(self.db.defaultSearch)
end