--[[

  ReturnMail Addon for World of Warcraft

  Author: Verlange

--]]

--[[
TODO
--rate limit auto sending
--]]

ReturnMailLocale = {}
local L = ReturnMailLocale;
ReturnMail = {};
local rm = ReturnMail;
ReturnMailVars = {};

rm.EventHandler = {};
rm.jobs = {};
rm.lastAH = {};
rm.mailcounts = {};
rm.work = {};
rm.returnDays = 7;
local eh = rm.EventHandler;
local _G = getfenv(0)
rm.skip_cod = true;
rm.isdebug = false;
rm.sender = "";
rm.syncerror = false;
rm.endTime = 0;

local RED = "|cffff8080";
local CLOSE = "|r";
rm.MAX_SHOWN_MAILS = 50;
rm.RECHECK_TIMER = 5;


L.TEXT_NOT_VISIBLE = "You need a post open to send mails!";
L.TEXT_WAITING_FOR_REFRESH = "Waiting for refresh...";
L.TOOLTIP_FORWARD_TO_BUTTON = RED.."Return to sender!"..CLOSE;
L.TITLE_FORWARD_TO_BUTTON = "Force Return";
L.TITLE_FORWARD_ALL_BUTTON = "Return expiring";
L.TITLE_SHORT_FORWARD_TO_BUTTON = "R";


function rm.Print(text)
   ChatFrame1:AddMessage(RED.."[ReturnMail] "..CLOSE..text, 1.0, 1.0, 1.0);
end

function rm.Debug(text)
   if rm.isdebug then
      ChatFrame1:AddMessage("[ReturnMail] "..text, 1.0, 1.0, 0.0);
   end
end

function rm.capital(str)
   return str:sub(1,1):upper()..str:sub(2):lower();
end


function rm.NextJob()
   table.remove(rm.jobs, 1);
   rm.isWaitingFor = nil;
   if rm.jobs[1] then
      rm.ResumeJobOnEvent(nil);
   end
end

function rm.ResumeJobOnEvent(event)
	--rm.Debug("ResumeJobOnEvent")
	if rm.isWaitingFor == event then
		rm.isWaitingFor = nil;
		if rm.jobs[1] then
			rm.Debug("Resuming on : "..(event or "nil"));
			local cont = rm.jobs[1]();
			if not cont then
				rm.NextJob();
			end
		end
	end
end

function rm.SuspendJobOnEvent(event, error)
	rm.Debug("SuspendJobOnEvent", event, error);
	if rm.jobs[1] then
		rm.Debug(event);
		print(event)
		print(error)
		-- todo get this to keep retrying to send
		if error == "Internal mail database error." then
			rm.syncerror = true;
		end
		if rm.is_ClickSendMailItemButton then
			rm.iserror = true;
		elseif rm.is_ClickSend then
			rm.iserror = true;
		else
			rm.NextJob();
		end
	end
end

function rm.SuspendJobOnEvent2(event, error)
	rm.Debug("SuspendJobOnEvent", event, error);
	if rm.syncerror then
		rm.SyncError()
	end
	if rm.jobs[1] then
		rm.Debug(event);
		print(event)
		print(error)
		-- todo get this to keep retrying to send
		if error == "Internal mail database error." then
			rm.syncerror = true;
		end
		if rm.is_ClickSendMailItemButton then
			rm.iserror = true;
		elseif rm.is_ClickSend then
			rm.iserror = true;
		else
			rm.NextJob();
		end
	end
end

function rm.SyncError()
	print("Mail sync issue detected");
	local is_SendMailFrame_Shown = SendMailFrame:IsShown();
	if not is_SendMailFrame_Shown then
		MailFrameTab2:Click();
	end
	print(rm.endTime);
	if rm.endTime ~= 0 then
		local endLoop = false;
		repeat
			print("checking times")
			local currentTime = time();
			print(rm.endTime);
			print(currentTime);
			if currentTime >= rm.endTime then
				print("send")
				
				SendMailMailButton:Click()
				endLoop = true;
			else
				print("extend")
				--rm.endTime = rm.endTime + 2;
			end
		until (endLoop ==true)
	end
	return --SendMailMailButton:Click()
end

eh.MAIL_INBOX_UPDATE = function(event)
	rm.ResumeJobOnEvent(event);
	local numItems, totalItems = GetInboxNumItems();
	if rm.overflowMails ~= (totalItems - numItems) then
		if rm.longWaitJob and not rm.jobs[1] then
			rm.Debug("Restarting rm.longWaitJob");

			rm.longWaitJob(rm.longWaitMsg);
			rm.longWaitJob = nil;
			rm.longWaitMsg = nil;
		end
	end
	if totalItems > numItems then
		rm.overflowMails = totalItems - numItems;
	else
		rm.overflowMails = nil;
	end
end
eh.MAIL_SEND_SUCCESS = rm.ResumeJobOnEvent;
eh.MAIL_SEND_INFO_UPDATE = rm.ResumeJobOnEvent;
eh.MAIL_SUCCESS = rm.ResumeJobOnEvent;
eh.BAG_UPDATE = rm.ResumeJobOnEvent;
eh.ITEM_UNLOCKED = rm.ResumeJobOnEvent;
eh.PLAYER_MONEY = rm.ResumeJobOnEvent;
eh.ITEM_PUSH = function(event, bagId, itemTexture)
   if rm.itemTexture == itemTexture then
      rm.ResumeJobOnEvent(event, bagId, itemTexture);
   end
end
rm.OnUpdate = function(self, elapsed)
   rm.InboxFrame_Update();
   rm.ResumeJobOnEvent("OnUpdate");
   self.timer = self.timer - elapsed;
   if self.timer <= 0 then
      self.timer = rm.RECHECK_TIMER;
      local numItems, totalItems = GetInboxNumItems();
      if numItems < totalItems and numItems < rm.MAX_SHOWN_MAILS then
	 CheckInbox();
	 rm.Debug("CheckInbox");
      end
   end
end
eh.MAIL_FAILED = rm.SuspendJobOnEvent2;
eh.UI_ERROR_MESSAGE = rm.SuspendJobOnEvent;
eh.MAIL_CLOSED = function()
   table.wipe(rm.jobs);
   rm.isWaitingFor = nil;
   rm.longWaitJob = nil;
   rm.longWaitMsg = nil;

   for k,v in pairs(eh) do
      rm.JobFrame:UnregisterEvent(k);
   end
   rm.JobFrame:SetScript("OnEvent", rm.MAIL_SHOW);
   rm.JobFrame:SetScript("OnUpdate", nil);
end

function rm.MAIL_SHOW()
	for k,v in pairs(eh) do
		rm.JobFrame:RegisterEvent(k);
	end
	rm.JobFrame:SetScript("OnEvent", function(self, event, ...)
         if eh[event] then eh[event](event, ...); end;
   end);
	rm.JobFrame:SetScript("OnUpdate", rm.OnUpdate);
end

function rm.PushJob(f)
   table.insert(rm.jobs, coroutine.wrap(f));
   rm.ResumeJobOnEvent(nil);
end

function rm.WaitFor(event)
   rm.isWaitingFor = event;
   rm.iserror = nil;
   coroutine.yield(true);
end

function rm.WaitForRefresh(f, msg)
   local numItems, totalItems = GetInboxNumItems();
   if numItems < totalItems and numItems < rm.MAX_SHOWN_MAILS then
      rm.longWaitJob = f;
      rm.longWaitMsg = msg;

      -- Check if we have another job after current one.
      if not rm.jobs[2] then
	 rm.Print(L.TEXT_WAITING_FOR_REFRESH);
      end
   end
end

function rm.OnLoad(self)
   rm.JobFrame = _G["ReturnMailJobFrame"] or CreateFrame("FRAME", "ReturnMailJobFrame");
   rm.JobFrame:RegisterEvent("VARIABLES_LOADED");
   rm.JobFrame:SetScript("OnEvent", rm.VARIABLES_LOADED);
    -- Create the icons
	for i = 1, 7 do
		local c = _G["MailItem"..i.."ExpireTime"]
		if not c.forcereturnicon then
			c.forcereturnicon = CreateFrame("BUTTON", nil, c)
			c.forcereturnicon:SetPoint("TOPRIGHT", c, "BOTTOMRIGHT", -5, -1)
			c.forcereturnicon:SetWidth(16)
			c.forcereturnicon:SetHeight(16)
			c.forcereturnicon.texture = c.forcereturnicon:CreateTexture(nil, "BACKGROUND")
			c.forcereturnicon.texture:SetAllPoints()
			c.forcereturnicon.texture:SetTexCoord(1, 0, 0, 1) -- flips image left/right
			c.forcereturnicon.id = i
			c.forcereturnicon:SetScript("OnClick", rm.Click)
			c.forcereturnicon:SetScript("OnEnter", c:GetScript("OnEnter"))
			c.forcereturnicon:SetScript("OnLeave", c:GetScript("OnLeave"))
		end
		-- For enabling after a disable
		c.forcereturnicon:Show()
	end
end

function rm:returnDaysSet(days)
	rm.returnDays = tonumber(days) or 7
end

function rm.VARIABLES_LOADED(self)
	rm.JobFrame:UnregisterEvent("VARIABLES_LOADED");

	rm.JobFrame.timer = rm.RECHECK_TIMER;
	rm.JobFrame:RegisterEvent("MAIL_SHOW");
	rm.JobFrame:SetScript("OnEvent", rm.MAIL_SHOW);

	ReturnMailForwardToButton = ReturnMailForwardToButton or
	CreateFrame("Button", "ReturnMailForwardToButton", OpenMailCancelButton, "UIPanelButtonTemplate");
	rm.ForwardToButton = ReturnMailForwardToButton;
	rm.ForwardToButton:SetAllPoints(OpenMailCancelButton);
	rm.ForwardToButton:SetText(L.TITLE_FORWARD_TO_BUTTON);
	rm.ForwardToButton:SetScript("OnClick", rm.ForwardToButton_OnClick);
	rm.ForwardToButton:SetScript("OnEnter", rm.ForwardToButton_OnEnter);
	rm.ForwardToButton:SetScript("OnLeave", rm.OnLeave);

	ReturnMailForwardAllButton = ReturnMailForwardAllButton or
	CreateFrame("Button", "ReturnMailForwardAllButton", InboxFrame, "UIPanelButtonTemplate");
	rm.ForwardAllButton = ReturnMailForwardAllButton;
	rm.ForwardAllButton:SetPoint("TOPLEFT", InboxCloseButton ,"TOPLEFT", -280, -10);
	rm.ForwardAllButton:SetWidth(120)
	rm.ForwardAllButton:SetHeight(20)
	rm.ForwardAllButton:SetText(L.TITLE_FORWARD_ALL_BUTTON);
	rm.ForwardAllButton:SetScript("OnClick", rm.DoOpenMail);
	rm.ForwardAllButton:SetScript("OnLeave", rm.OnLeave);


	ReturnMailDays = ReturnMailDays or
	CreateFrame("EditBox", "ReturnMailDays",
							  InboxFrame, "InputBoxTemplate")
	rm.ForwardAllDays = ReturnMailDays;
	rm.ForwardAllDays:SetPoint("TOPLEFT", ReturnMailForwardAllButton ,"TOPLEFT", 180, 0);
	rm.ForwardAllDays:SetWidth(20)
	rm.ForwardAllDays:SetHeight(20)
	rm.ForwardAllDays:SetText(rm.returnDays);
	rm.ForwardAllDays:SetAutoFocus(false);
	-- todo fix clear focus
	--rm.ForwardAllDays:SetScript("OnEnter", ClearFocus());
	--rm.ForwardAllDays:SetScript("OnLeave", ReturnMailDays:ClearFocus());
   
	local ForwardAllText=CreateFrame("Frame","FrameName",InboxFrame);--    Our frame
	ForwardAllText:SetPoint("TOPLEFT", ReturnMailDays ,"TOPLEFT", 17, 0);
	ForwardAllText:SetSize(40,20);
 
--  FontStrings only need a position set. By default, they size automatically according to the text shown.
	local text=ForwardAllText:CreateFontString(nil,"OVERLAY","GameFontNormal");--    Our text area
	text:SetPoint("CENTER");
	text:SetText("days");
   



   	if ElvUI then
		local E, L, V, P, G = unpack(ElvUI)
		local S = E:GetModule("Skins")
		
		if E:GetModule("AddOnSkins", true) then
			local AS = E:GetModule("AddOnSkins")

			local ipairs = ipairs
			local select = select
			local unpack = unpack
			S:HandleButton(ReturnMailForwardToButton)
			S:HandleButton(ReturnMailForwardAllButton)
			S:HandleEditBox(ReturnMailDays)
		end	
	end


	
		if ReturnMailVars[rm.ForwardToButton:GetName()] == "HIDE" then
		rm.ForwardToButton:Hide();
	end
end

function rm.TakeItemStr(itemargs)
	local itemName, rest, quantity;
	quantity, rest = itemargs:match("^%s*(%d+)%s*(.-)$");
	if quantity then
		itemargs = rest;
		quantity = tonumber(quantity);
	end

	itemName, rest = itemargs:match("^%s*%[([^][]+)%]%s*(.-)$");
	if itemName then
		return itemName, rest, quantity;
	end
	itemName, rest = itemargs:match("^%s*%S*(item:%d+)[^[%s]*%[.-%]|[^[%s]*%s*(.-)$");
	if itemName then
		return itemName, rest, quantity;
	end
	itemName, rest = itemargs:match("^%s*(item:%d+)%s*(.-)$");
	if itemName then
		return itemName, rest, quantity;
	end
	itemName = itemargs:match("^%s*([^][%s][^][]-)%s*$");
	if itemName then
		return itemName, "", quantity;
	end
	return nil;
end

function rm.SplitContainerItem(bagFrom,slotFrom,moveCount,bagTo,slotTo)
	rm.Debug(string.format("rm.SplitContainerItem(%d,%d,%d,%d,%d)", bagFrom,slotFrom,moveCount,bagTo,slotTo));
	local from_itemCount = select(2, GetContainerItemInfo(bagFrom, slotFrom));
	ClearCursor(); -- For safty
	if from_itemCount > moveCount then
		rm.Debug(string.format("SplitContainerItem(%d,%d,%d)", bagFrom,slotFrom,moveCount));
		SplitContainerItem(bagFrom,slotFrom,moveCount);
	elseif from_itemCount == moveCount then
		rm.Debug(string.format("PickupContainerItem(%d,%d)", bagFrom,slotFrom));
		PickupContainerItem(bagFrom,slotFrom);
	else
		-- Suspending now since something is wrong.
		coroutine.yield(nil);
	end
	PickupContainerItem(bagTo,slotTo);
	rm.WaitFor("ITEM_UNLOCKED");
	local expected = from_itemCount - moveCount;
	rm.Debug(string.format("SplitContainerItem expected = from_itemCount - moveCount = %d - %d", from_itemCount, moveCount));
	repeat
		rm.WaitFor("BAG_UPDATE");
		local new_itemCount = select(2, GetContainerItemInfo(bagFrom, slotFrom)) or 0;
		local new_itemCount2 = select(2, GetContainerItemInfo(bagTo, slotTo)) or 0;
		rm.Debug(string.format("Waiting for BAG_UPDATE: (%d,%d) itemCount=%d, expected=%d", bagFrom,slotFrom,new_itemCount, expected));
		rm.Debug(string.format("Waiting for BAG_UPDATE: (%d,%d) itemCount=%d, expected=%d", bagTo,slotTo,new_itemCount2, moveCount));
	until new_itemCount == expected;
	repeat
		rm.WaitFor("BAG_UPDATE");
		local new_itemCount2 = select(2, GetContainerItemInfo(bagTo, slotTo)) or 0;
	until new_itemCount2 == moveCount;
end

function rm.FindEmptyBagSlot(srcBag)
	local function f()
		for bag = 0, 4 do
			local numberOfFreeSlots, BagType = GetContainerNumFreeSlots(bag);
			if bag == srcBag or BagType == 0 then
				for slot = 1, GetContainerNumSlots(bag) do
					local texture, itemCount, locked, quality, readable, lootable, itemLink = GetContainerItemInfo(bag, slot)
					if not itemLink then
						coroutine.yield(bag, slot);
					end
				end
			end
		end
	end
	return coroutine.wrap(f);
end

function rm.SendLoop(itemName, quantity,sender,count2)
   --rm.ResetPost();
   local sendcount = 0;
   local lastcount = 0;
   rm.Debug(string.format("rm.SendLoop(quantity=%d)", quantity));
   repeat
      lastcount = sendcount;
      for bag,slot,itemCount in rm.FindInBag(itemName) do
	 if quantity <= 0 then
	    break;
	 end
	 if itemCount > quantity then
	    for bag2,slot2 in rm.FindEmptyBagSlot(bag) do
	       local moveCount = itemCount - quantity;
	       rm.SplitContainerItem(bag,slot,moveCount,bag2,slot2);
	       itemCount = itemCount - moveCount;
	       break;
	    end
	 end
	 rm.AddToSendMailItems(bag,slot,sender,count2)
	    sendcount = sendcount + itemCount;
	    quantity = quantity - itemCount;
	 --end
      end
   until (sendcount == lastcount)
   --if not rm.SendNow() then return 0; end
   
   return sendcount;
end

function rm.InboxIter()
	local numItems, totalItems = GetInboxNumItems();
	local function f()
		for mailID = numItems, 1, -1 do
			local packageIcon, stationeryIcon, sender, subject, money, CODAmount, daysLeft, itemCount, wasRead, x, y, z, isGM, firstItemQuantity = GetInboxHeaderInfo(mailID);
			local skipped = false
			if CODAmount and CODAmount > 0 then
				rm.Debug("Skipping CoD");
				skipped = true;
			end
			if isGM then
				rm.Debug("Skipping GM");
				skipped = true;
			end
			if not skipped then
				coroutine.yield(mailID, daysLeft, subject);
			end
		end
	end
	return coroutine.wrap(f);
end

function rm.InboxIterEasy()
	local numItems, totalItems = GetInboxNumItems();
	for mailID = numItems, 1, -1 do
		local packageIcon, stationeryIcon, sender, subject, money, CODAmount, daysLeft, itemCount, wasRead, x, y, z, isGM, firstItemQuantity = GetInboxHeaderInfo(mailID);
		local skipped = false
		if CODAmount and CODAmount > 0 then
			rm.Debug("Skipping CoD");
			skipped = true;
		end
		if isGM then
			rm.Debug("Skipping GM");
			skipped = true;
		end
		local easy = InboxItemCanDelete(mailID)

		if not skipped and not easy then
			--todo
			if tonumber(daysLeft) < tonumber(rm.ForwardAllDays:GetText()) then
				rm.Debug("easy return");
				rm.DoForwardToEasy(mailID)
			end
		end
	end
end

local SubjectPatterns = {
	AHCancelled = gsub(AUCTION_REMOVED_MAIL_SUBJECT, "%%s", ".*"),
	AHExpired = gsub(AUCTION_EXPIRED_MAIL_SUBJECT, "%%s", ".*"),
	AHOutbid = gsub(AUCTION_OUTBID_MAIL_SUBJECT, "%%s", ".*"),
	AHSuccess = gsub(AUCTION_SOLD_MAIL_SUBJECT, "%%s", ".*"),
	AHWon = gsub(AUCTION_WON_MAIL_SUBJECT, "%%s", ".*"),
	Mana = gsub("You got Manabonked!", "%%s", ".*"),
}

function rm.GetMailType(msgSubject)
	if msgSubject then
		for k, v in pairs(SubjectPatterns) do
			if msgSubject:find(v) then return k end
		end
	end
	return "NonAHMail"
end

function rm.DoOpenMail()
	rm.InboxIterEasy()
	rm.DoOpenMailForce()
end

function rm.DoOpenMailForce()
	print("Openmail")
	print(rm.ForwardAllDays:GetText())
	for mailID, daysLeft, subject in rm.InboxIter() do
		local mailType = rm.GetMailType(subject);
		if mailType == "NonAHMail" then
			if tonumber(daysLeft) < tonumber(rm.ForwardAllDays:GetText()) then
				rm.DoForwardTo(mailID,true);
			end
		end
	end
	return rm.WaitForRefresh(rm.DoOpenMailForce);
end

function rm.MatchItem(itemLink, itemarg)
	if not itemLink or not itemarg then
		return false;
	elseif itemLink:match("%[(.+)%]"):lower() == itemarg:lower() then
		return true;
	elseif itemLink:match("item:%d+") == itemarg then
		return true;
	elseif rm.RemoveUniqueId(itemLink) == itemarg then
		return true;
	end
	return false;
end

function rm.FindInBag(name)
	local function f()
	for bag = 0, 4 do
		for slot = 1, GetContainerNumSlots(bag) do
			local texture, itemCount, locked, quality, readable, lootable, itemLink = GetContainerItemInfo(bag, slot)
			if itemLink and not locked then
				if rm.MatchItem(itemLink, name) then
					coroutine.yield(bag, slot, itemCount);
				end
				end
			end
		end
	end
	return coroutine.wrap(f);
end

function rm.ResetPost()
	rm.title = nil;
	for i = 1, 12 do
		local name, tex, cnt, qual = GetSendMailItem(i);
		if name then
			rm.Debug("ResetPost:ClickSendMailItemButton");
			ClickSendMailItemButton(i, true);
			rm.Debug("ResetPost:Done ClickSendMailItemButton");

			local name, tex, cnt, qual = GetSendMailItem(i);
			if name then
				rm.WaitFor("MAIL_SEND_INFO_UPDATE");
				rm.WaitFor("OnUpdate");
			else
				rm.WaitFor("OnUpdate");
			end
		end
	end
	rm.mailitems = 0;
	table.wipe(rm.mailcounts);
end

function rm.SendNow2(sender, sure)
	local is_SendMailFrame_Shown = SendMailFrame:IsShown();
	if not is_SendMailFrame_Shown then
		MailFrameTab2:Click();
	end
	SendMailMailButton:Click()
	rm.is_ClickSend = true;
	rm.sender = sender;
	SendMail(sender, ("Return"), "");
	if rm.syncerror == true then
		print("Trying");
	end
end

function rm.SendNow(sender, sure)
	if not MailFrame:IsShown() then
		rm.Print(L.TEXT_NOT_VISIBLE);
		rm.ResetPost();
		return false;
	end
	if rm.mailitems > 0 and sure then 
		local is_SendMailFrame_Shown = SendMailFrame:IsShown();
		if not is_SendMailFrame_Shown then
			MailFrameTab2:Click();
		end
		rm.is_ClickSend = true;
		rm.sender = sender;
		rm.endTime = time();
		SendMail(sender, ("Return"), "");

		rm.WaitFor("MAIL_SEND_SUCCESS");
		rm.WaitFor("MAIL_SUCCESS");
		rm.WaitFor("OnUpdate");
		rm.syncerror = false;
		rm.endTime = 0;
		rm.ResetPost();
		rm.is_ClickSend = nil;
		if not is_SendMailFrame_Shown then
			MailFrameTab1:Click();
		end
	end
	return true;
end

--[[
   Removes random uniqueId to make it correctly equate
   when reporting item list. 
   Ref: http://www.wowpedia.org/ItemString
--]]
function rm.RemoveUniqueId(itemLink)
	if not itemLink then
		return nil;
	end
	local linkType, itemId, enchantId, jewelId1, jewelId2, jewelId3, jewelId4, suffixId, uniqueId, linkLevel, reforgeId, extra1 = strsplit(":", itemLink);
	suffixId = tonumber(suffixId) or 0;
	uniqueId = tonumber(uniqueId) or 0;
	if suffixId >= 0 and uniqueId ~= 0 then
		itemLink = string.gsub(itemLink, '^(.*item:[^:]*:[^:]*:[^:]*:[^:]*:[^:]*:[^:]*:[^:]*):[^:]*:(.*)$', '%1:0:%2');
	end
	return itemLink;
end

function rm.AddToSendMailItems(itemLink, quantity,sender,counter)
	if rm.mailitems == counter then
		if not rm.SendNow(sender) then return false; end
	end

	idx = rm.mailitems + 1;
	ClearCursor();
	local _, _, _, _, _, _, _, maxStack = GetItemInfo(itemLink)
	itemName = rm.RemoveUniqueId(itemLink);
	if maxStack == 1 then
		for bag,slot,itemCount in rm.FindInBag(itemName) do
			PickupContainerItem(bag,slot);
			break;
		end
	else
		bag2, slot2 = rm.SendLoop(itemName, quantity, sender, count2);
		print("new item at " .. bag2 .. " " .. slot2)
		PickupContainerItem(bag2,slot2);
	end
   
	rm.Debug("ClickSendMailItemButton");
	rm.is_ClickSendMailItemButton = true;
	ClickSendMailItemButton(idx, false);
	rm.is_ClickSendMailItemButton = nil;
	rm.Debug("Done ClickSendMailItemButton");
	if rm.iserror then
		rm.iserror = nil;
		ClearCursor();
		-- Suspending now because an error happened while calling ClickSendMailItemButton.
		coroutine.yield(nil);
	end
	local name, tex, cnt, qual = GetSendMailItem(idx);
	if name then
		rm.WaitFor("OnUpdate");
	else
		rm.WaitFor("MAIL_SEND_INFO_UPDATE");
	end

	ClearCursor();

	local name, tex, cnt, qual = GetSendMailItem(idx);
	local itemLink = rm.RemoveUniqueId(GetSendMailItemLink(idx));
	if itemLink then
		rm.mailitems = idx;
		rm.mailcounts[itemLink] = (rm.mailcounts[itemLink] or 0) + cnt;
		rm.title = rm.title or name;
		return true;
	else
		return false;
	end
end

function rm.TakeInboxItem(mailID, attachment)
   local name, itemTexture, count, quality, canUse = GetInboxItem(mailID, attachment);
   TakeInboxItem(mailID, attachment);
   rm.WaitFor("MAIL_SUCCESS");
   rm.itemTexture = itemTexture;
   -- todo buggy
   --rm.WaitFor("ITEM_PUSH");
   return count;
end

function rm.freespace()
	local space = 0;
	for bag = 0, 4 do
		local numberOfFreeSlots, BagType = GetContainerNumFreeSlots(bag);
		if BagType == 0 then
			space = space + numberOfFreeSlots;
		end
	end
	return space;
end

function rm.CountAttachments(mailID)
	local count = 0;
	for attachment = 1, 12 do
		local itemLink = GetInboxItemLink(mailID, attachment);
		if itemLink then
			count = count + 1;
		end
	end
	return count;
end

function rm.DoForwardTo(mailID, sure)
	local function f()
		local count = rm.CountAttachments(mailID);
		local count2 = rm.CountAttachments(mailID);
		local itemReturns = {};
		local packageIcon, stationeryIcon, sender, subject, money, CODAmount, daysLeft, itemCount, wasRead, x, y, z, isGM, firstItemQuantity = GetInboxHeaderInfo(mailID);
		if rm.freespace() < count then
			rm.Print("Not enough bag space");
			return;
		end
		rm.ResetPost();
		for attachment = 1, 12 do
			local itemLink = GetInboxItemLink(mailID, attachment);
			if itemLink then
				local _, _, _, _, _, _, _, maxStack = GetItemInfo(itemLink)
				local qtyold = GetItemCount(itemLink)
				local ccoouunntt = rm.TakeInboxItem(mailID, attachment);
				if qtyold == 0 or maxStack == 1 then
					rm.WaitFor("BAG_UPDATE");
				end
				--if itemReturns[rm.RemoveUniqueId(itemLink)] then
				--	itemReturns[rm.RemoveUniqueId(itemLink)] = itemReturns[rm.RemoveUniqueId(itemLink)] + ccoouunntt;
				--else
					itemReturns[attachment] = {}
					itemReturns[attachment]['id'] = rm.RemoveUniqueId(itemLink);
					itemReturns[attachment]['qty'] = ccoouunntt;
				--end
				count = count - 1;
				if count == 0 then
					break;
				end
			end
		end
		
		for id,v in pairs(itemReturns) do
			local itemLink = v['id'] 
			local quan = v['qty']
			print(itemLink, quan);
		end
		
		for id,v in pairs(itemReturns) do
			local itemLink = v['id'] 
			local quan = v['qty']
			print(itemLink, quan);
			if itemLink then
				rm.AddToSendMailItems(itemLink,quan,sender,count2);
			end
		end
		rm.SendNow(sender, sure)
		if sure then
			MailFrameTab1:Click();
		else
			MailFrameTab2:Click();
		end
	end
	return rm.PushJob(f);
end

function rm.DoForwardToEasy(mailID)
	local function f()
		--todo
		ReturnInboxItem(mailID)
		rm.WaitFor("MAIL_SUCCESS");
		rm.WaitFor("OnUpdate");
	end
	return rm.PushJob(f);
end

function rm.GetForwardItemargs()
	table.wipe(rm.work);
	for idx = 1, 12, 1 do 
		local itemLink = GetSendMailItemLink(idx);
		if itemLink then
			rm.work[rm.RemoveUniqueId(itemLink)] = true;
		end
	end
	local itemargs = "";
	for k,v in pairs(rm.work) do
		itemargs = itemargs.." "..k;
	end
	return itemargs;
end

function rm.SendFrame_OnEvent(self)
	local recipient = SendMailNameEditBox:GetText()
	local items = false;
	for idx = 1, 12, 1 do 
		local itemLink = GetSendMailItemLink(idx);
		if itemLink then
			items = true;
			break;
		end
	end
	if recipient and recipient ~= "" and items then
	rm.ForwardAllButton:Enable();
	else
	rm.ForwardAllButton:Disable();
	end
end

function rm.OnLeave()
	GameTooltip:Hide();
end

function rm.OpenButton_OnEnter(self)
	GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
	GameTooltip:SetText(L.TOOLTIP_OPEN_BUTTON, 1.0, 1.0, 1.0, 1, 1);
end

function rm.ForwardToButton_OnEnter(self)
	GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
	GameTooltip:SetText(L.TOOLTIP_FORWARD_TO_BUTTON, 1.0, 1.0, 1.0, 1, 1);
end

function rm.ForwardToButton_OnClick(self)
	local mailID = InboxFrame.openMailID;
	if IsShiftKeyDown() or IsAltKeyDown() then
		rm.DoForwardTo(mailID,false);
	else
		rm.DoForwardTo(mailID,true);
	end
end

function rm.Click(self, button, down)
	mailID = self.id + (InboxFrame.pageNum-1)*7
	local f = InboxItemCanDelete(mailID)
	if f then
		if IsShiftKeyDown() or IsAltKeyDown() then
			rm.DoForwardTo(mailID,false);
		else
			rm.DoForwardTo(mailID,true);
		end
	else
		ReturnInboxItem(mailID)
	end
	mailID = nil
end

function rm.InboxFrame_Update()
	for i = 1, 7 do
		local index = i + (InboxFrame.pageNum-1)*7
		local c = _G["MailItem"..i.."ExpireTime"].forcereturnicon
		if index > GetInboxNumItems() then
			c:Hide()
		else
			local f = InboxItemCanDelete(index)
			c.texture:SetTexture(f and "Interface\\ChatFrame\\ChatFrameExpandArrow" or "Interface\\ChatFrame\\ChatFrameExpandArrow")
			c.tooltip = f and "Force Return" or MAIL_RETURN
			c:SetScript("OnClick", rm.Click)

			c:Show()
		end
	end
end

-- There is no xml to call OnLoad yet!
rm.OnLoad();
