local addonName, addon = ...

local Mail = addon:NewModule("Mail")

function Mail:OnInitialize()
	self:RegisterEvent("PLAYER_LOGIN")
end

local function OnMailInboxUpdate(self)
	-- process only one occurence of the event, right after MAIL_SHOW
	self:UnregisterEvent("MAIL_INBOX_UPDATE")
	self:Refresh()
end

local function OnMailClosed(self)
	self.isOpen = nil
	self:UnregisterEvent("MAIL_CLOSED")
	self:Refresh()
	
	-- self:UnregisterEvent("MAIL_SEND_INFO_UPDATE")
end

local function OnMailShow(self)
	-- the event may be triggered multiple times, exit if the mailbox is already open
	if self.isOpen then return end	
	
	self:Refresh()
	self:RegisterEvent("MAIL_CLOSED", OnMailClosed)
	self:RegisterEvent("MAIL_INBOX_UPDATE", "Refresh")
	-- self:RegisterEvent("MAIL_SEND_INFO_UPDATE", OnMailSendInfoUpdate)

	self.isOpen = true
end

function Mail:PLAYER_LOGIN()
	self:RegisterEvent("AUCTION_HOUSE_SHOW", OnAuctionHouseShow)
end

function Mail:Refresh()
	local character = DataStore:GetCharacter()
	self:ClearCache(character)
	if addon:GetSelectedModule() == self and addon:GetSelectedCharacter() == character then
		self:Update(character)
	end
end

function Mail:BuildList(character)
	local list = {}
	for i = 1, DataStore:GetNumMails(character) do
		local icon, count, link, money, text, returned = DataStore:GetMailInfo(character, i)
		local itemID = link and tonumber(link:match("item:(%d+)"))
		if itemID or money then
			tinsert(list, {
				id = itemID,
				link = link,
				count = count,
				money = money,
				sender = DataStore:GetMailSender(character, i),
				expiry = select(2, DataStore:GetMailExpiry(character, i)),
				index = i,
			})
		end
	end
	return list
end

function Mail:GetItemCount(character, itemID)
	return DataStore:GetMailItemCount(character, itemID)
end

function Mail:OnButtonUpdate(button, object, list)
	button.source:SetText("|cffffffff"..object.sender)
	if object.expiry >=  24 * 60 * 60 then
		-- daysLeft = format(DAYS_ABBR, floor(daysLeft)).." ";
		button.info:SetText(GREEN_FONT_COLOR_CODE..SecondsToTime(object.expiry)..FONT_COLOR_CODE_CLOSE)
	else
		button.info:SetText(RED_FONT_COLOR_CODE..SecondsToTime(object.expiry)..FONT_COLOR_CODE_CLOSE)
	end
	-- button.info:SetText(SecondsToTime(object.expiry))
end

function Mail.sort(a, b)
	if a.expiry ~= b.expiry then
		return a.expiry > b.expiry
	else
		return a.index < b.index
	end
end

hooksecurefunc("SendMail", function(recipient)
	for characterName, characterKey in pairs(DataStore:GetCharacters()) do
		if strlower(characterName) == strlower(recipient) then
			Mail:ClearCache(characterKey)
			break
		end
	end
end)

hooksecurefunc("ReturnInboxItem", function(index)
	local _, stationaryIcon, mailSender, mailSubject, mailMoney, _, _, numAttachments = GetInboxHeaderInfo(index)
	
	for characterName, characterKey in pairs(DataStore:GetCharacters()) do
		if strlower(characterName) == strlower(mailSender) then
			Mail:ClearCache(characterKey)
			break
		end
	end
end)