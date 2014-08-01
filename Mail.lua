local _, Vortex = ...

local Mail = Vortex:NewModule("Mail")

function Mail:OnInitialize()
	DataStore_Mails.RegisterMessage(self, "DATASTORE_MAILBOX_UPDATED", "Refresh")
end

function Mail:BuildList(character)
	local list = {}
	for i = 1, (DataStore:GetNumMails(character) or 0) do
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
		button.info:SetText(GREEN_FONT_COLOR_CODE..SecondsToTime(object.expiry, nil, nil, 1)..FONT_COLOR_CODE_CLOSE)
	elseif object.expiry > 0 then
		button.info:SetText(RED_FONT_COLOR_CODE..SecondsToTime(object.expiry)..FONT_COLOR_CODE_CLOSE)
	else
		button.info:SetText(RED_FONT_COLOR_CODE.."Expired"..FONT_COLOR_CODE_CLOSE)
	end
end

function Mail.sort(a, b)
	if a.expiry ~= b.expiry then
		return a.expiry > b.expiry
	else
		return a.index < b.index
	end
end

hooksecurefunc("SendMail", function(recipient)
	local name, realm = strsplit("-", recipient)
	if realm then
		for k in pairs(DataStore:GetRealms()) do
			if strlower(gsub(k, "[ -]", "")) == strlower(gsub(realm, "[ -]", "")) then
				realm = k
				break
			end
		end
	end
	
	for characterName, characterKey in pairs(DataStore:GetCharacters()) do
		if strlower(characterName) == strlower(recipient) then
			Mail:ClearCache(characterKey)
			break
		end
	end
end)

hooksecurefunc("ReturnInboxItem", function(index)
	local _, stationaryIcon, mailSender, mailSubject, mailMoney, _, _, numAttachments = GetInboxHeaderInfo(index)
	
	local name, realm = strsplit("-", mailSender)
	if realm then
		for k in pairs(DataStore:GetRealms()) do
			if strlower(gsub(k, "[ -]", "")) == strlower(gsub(realm, "[ -]", "")) then
				realm = k
				break
			end
		end
	end
	
	for characterName, characterKey in pairs(DataStore:GetCharacters()) do
		if strlower(characterName) == strlower(mailSender) then
			Mail:ClearCache(characterKey)
			break
		end
	end
end)