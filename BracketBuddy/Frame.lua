BracketCountTable={};
ServerKeywords = {};

events = {};

function Initialize()
	print('BracketBuddy Initialized');
	BracketBuddyFrame:SetScript("OnEvent", function(self, event, ...)
		events[event](self, ...);
	end);

	Invite_Say_Checkbox:SetScript("OnClick", function(self)
		_G["BB_Invite_Say"] = Invite_Say_Checkbox:GetChecked();
	end);

	Invite_Whisper_Checkbox:SetScript("OnClick", function(self)
		_G["BB_Invite_Whisper"] = Invite_Whisper_Checkbox:GetChecked();
	end);

	ResetButton:SetScript("OnClick", function(self)
		BracketCountTable={};
		for keyword, label in pairs(ServerKeywords) do
			BracketCountTable[keyword] = {};
		end
		BracketCountTable["Total"] = {};
		BracketChampionTable = {};
		for k in pairs (BracketChampionTable) do
		    BracketChampionTable[k] = nil
		end
		UpdateLabels();
	end);

	ServerKeywords = {
		["Bigglesworth"] = Bigglesworth_Text,
		["Benediction"] = Benediction_Text,
		["Earthfury"] = Earthfury_Text,
		["Faerlina"] = Faerlina_Text,
		["Heartseeker"] = Heartseeker_Text,
		["Herod"] = Herod_Text,
		["Incendius"] = Incendius_Text,
		["Skeram"] = Skeram_Text,
		["Stalagg"] = Stalagg_Text,
		["Whitemane"] = Whitemane_Text
	};

	BracketCountTable={};
	for keyword, label in pairs(ServerKeywords) do
		BracketCountTable[keyword] = {};
	end
	BracketCountTable["Total"] = {};
	UpdateLabels();

	for k, v in pairs(events) do
		print("Registering Event: " .. k);
		BracketBuddyFrame:RegisterEvent(k);
	end

	BracketBuddyFrame:Hide();
end

function events:ADDON_LOADED(...)
	--print('BracketBuddy LOADED');
	if (_G["BB_Invite_Say"] ~= nil) then
		Invite_Say_Checkbox:SetChecked(_G["BB_Invite_Say"]);
	end
	
	if (_G["BB_Invite_Whisper"] ~= nil) then
		Invite_Whisper_Checkbox:SetChecked(_G["BB_Invite_Whisper"]);
	end

	for keyword, label in pairs(ServerKeywords) do
		if (BracketCountTable[keyword] == nil) then
			BracketCountTable[keyword] = {};
		end
	end
	if (BracketCountTable["Total"] == nil) then
		BracketCountTable["Total"] = {};
	end
	if (BracketChampionTable == nil) then
		BracketChampionTable = {}
	end
	UpdateLabels();
end

function events:CHAT_MSG_SAY(...)
	if (Invite_Say_Checkbox:GetChecked() == false) then
		return;
	end
	
	text, playerName, language, playerName2 = ...;
	HandleMessage(text, playerName, playerName2);
end

function events:CHAT_MSG_WHISPER(...)
	--BgTest();
	if (Invite_Whisper_Checkbox:GetChecked() == false) then
		return;
	end
	
	text, playerName, language, playerName2 = ...;
	HandleMessage(text, playerName, playerName2);
end

function compare(a,b)
  return b[1] < a[1]
end

function HandleMessage(text, playerName, playerName2) 
	text = text:lower();
	playerNameShort = gsub(playerName, "%-[^|]+", "")

	keyword = FindKeyword(ServerKeywords, text);
	if (keyword == nil) then
		print("Keyword not found.");
		return;
	end
	if UnitLevel(playerNameShort) > 14 then
		print(playerNameShort .. " is Level: " .. UnitLevel(playerNameShort) .. " and too high to join.")
		return;
	end
	--print(playerNameShort)
	--print(UnitLevel(playerNameShort))
	if (ArrayContains(BracketCountTable["Total"], playerName)) then
		print("Character already counted.");
	else


		-- TODO: get player details
		-- TODO: only invite players < level 15s -- done above
		--for w in text:gmatch("%S+") do print(w) end (%w+)(.+)
		local words = {}
		words[1] = nil; words[2] = nil
		words[1], words[2] = text:match("(%w+)(.+)")
		--print(words[2])
		--print(words[2])
		if words[2] and string.len(words[2]) > 2 then
			words[2] = words[2]:match( "^%s*(.-)%s*$" )
			if BracketChampionTable[words[2]] then
				BracketChampionTable[words[2]] = BracketChampionTable[words[2]] + 1
			else
				BracketChampionTable[words[2]] = 1
			end
			print("Champion: " .. words[2] .. " (x" .. BracketChampionTable[words[2]] .. ")")
			table.sort(BracketChampionTable, compare)
		else
			print("No Champion")
		end
		table.insert(BracketCountTable[keyword], playerName);
		table.insert(BracketCountTable["Total"], playerName);
		UpdateLabels();
	end

	if (IsInGroup() == false or UnitIsGroupLeader("PLAYER")) then
		if (GetNumGroupMembers() >= 38) then
			LeaveParty();
		end

		if (IsInRaid() == false) then
			ConvertToRaid();
		end
		InviteUnit(playerName);
	else
		print("Character can't invite to party.");
	end
end

function FindKeyword(keywords, text)
	--print("Checking for keywords " .. tostring(AssociativeTableSizeServerKeywords));
	for keyword, label in pairs(ServerKeywords) do
		--print("Checking for keyword: " .. keyword);
		if (string.find(text, keyword:lower())) then
			return keyword;
		end
	end
	return nil;
end

function RemoveOffline()
	for i = 1, GetNumGroupMembers(), 1 do
		local name, rank, subgroup, level, class, fileName, 
		status, online, isDead, role, isML = GetRaidRosterInfo(i);
		if (status == "Offline") then
			UninviteUnit(name);
			print("Removing offline party member " .. name);
		end
	end
end

function UpdateLabels()
	total = 0;
	for keyword, label in pairs(ServerKeywords) do
		splits = SplitString(label:GetText(), ":");

		count = #BracketCountTable[keyword];
		total = total + count;

		label:SetText(splits[1] .. ":  " .. tostring(count));
	end
	Total_Text:SetText("Total:  " .. tostring(#BracketCountTable["Total"]));
end

function ArrayContains(tab, val)
    for index, value in ipairs(tab) do
        if value == val then
            return true
        end
    end
    return false
end

function AssociativeTableSize(table)
	ret = 0;
	for keyword, label in pairs(table) do
		ret = ret + 1;
	end
	return ret;
end

function SplitString(inputstr, sep)
        if sep == nil then
			sep = "%s"
        end
        local t={}
        for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
			table.insert(t, str)
        end
        return t
end

function SetRaidTargets()
	if (UnitIsGroupLeader("PLAYER") == false and UnitIsGroupAssistant("PLAYER") == false) then
		SendChatMessage("ASSIST ME NERD", "WHISPER", nil, "Blc");
		return;
	end

	for i = 1, GetNumGroupMembers(), 1 do
		local name, rank, subgroup, level, class, fileName, 
		status, online, isDead, role, isML = GetRaidRosterInfo(i);
		if (name == "Blc") then 
			SetRaidTarget("raid"..i, 8);
			PromoteToAssistant("raid"..i);
		elseif (name == "Sweepy") then 
			SetRaidTarget("raid"..i, 7);
			PromoteToAssistant("raid"..i);
		elseif (name == "Spiceice") then 
			SetRaidTarget("raid"..i, 1);
			PromoteToAssistant("raid"..i);
		elseif (name == "Littlebrudda") then 
			SetRaidTarget("raid"..i, 4);
		elseif (name == "Vocalist") then 
			SetRaidTarget("raid"..i, 8);
		elseif (name == "Endifferent") then 
			--SetRaidTarget("raid"..i, 4);
		elseif (name == "Zet") then 
			SetRaidTarget("raid"..i, 2);
			PromoteToAssistant("raid"..i);
		elseif (name == "Lithex") then 
			SetRaidTarget("raid"..i, 3);
		elseif (name == "Terrien") then 
			SetRaidTarget("raid"..i, 6);
		elseif (name == "Zullock") then 
			SetRaidTarget("raid"..i, 6);
		elseif(string.find(name, "Bigthyme")) then
			SetRaidTarget("raid"..i, 2);
			PromoteToAssistant("raid"..i);
		elseif(string.find(name, "Triggermad")) then
			SetRaidTarget("raid"..i, 2);
		elseif(string.find(name, "Squiggies")) then
			SetRaidTarget("raid"..i, 5);
		elseif(string.find(name, "saka")) then
			SetRaidTarget("raid"..i, 2);
		elseif(string.find(name, "Peaceman")) then
			SetRaidTarget("raid"..i, 2);
		end
	end
end

function BgTest() 
	local aura_env = {
		["announce"] = true,
		["nextRez"] = 5,
		["announced"] = false
	};
    if (aura_env.announce == true) then
        if (aura_env.nextRez <= 10 and aura_env.announced == false) then
            aura_env.announced = true;
            SendChatMessage(string.format("RESURRECTION IN %.0f SECONDS", aura_env.nextRez) , "RAID_WARNING");
        elseif (aura_env.nextRez > 25 and aura_env.announced == true) then
            aura_env.announced = false;
        end
    end
end

-- register /bb chat command
SLASH_BB1 = '/bb';
function SlashCmdList.BB(msg, editbox) -- 4.
	table.sort(BracketChampionTable, compare)
	if (BracketBuddyFrame:IsVisible()) then
		BracketBuddyFrame:Hide();
		for key,value in pairs(BracketChampionTable) do
			print(value .. "x " .. key .. ".")
		end
	else
		BracketBuddyFrame:Show();
	end
	
end