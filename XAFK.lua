local XAFK = {
	version = 1.0,
}
_G.XAFK = XAFK
local version = string.format("%.1f", tostring(XAFK.version))
local timer
local update = 0
local loading = 0
local chat = {"SAY", "GUILD", "PARTY", "ZONE", "YELL", "WHISPER", "CHANNEL"}
local p_ch = {}
local whM, whN = "", ""
local def={
	["Mode"] = 0,
	["Send1"] = "<AFK> I'm away from keyboard.",
	["Send2"] = "<DND> Please do not disturb.",
	["Send0"] = "I'm back!",
	["Auto1"] = false,
	["Timer1"] = "120000",
	["Auto2"] = false,
	["Timer2"] = "600",
	["WhReply"] = true,
	["WhRec"] = false,
	["SaveMode"] = false,
	["SaveMsg"] = false,
	["ChSend"] = {
		["SAY"] = false,
		["GUILD"] = false,
		["PARTY"] = false,
	},
	["ChRec"] = {
		["SAY"] = false,
		["GUILD"] = false,
		["PARTY"] = false,
		["ZONE"] = false,
		["YELL"] = false,
	},
	["PChSend"] = {},
	["PChRec"] = {},
	["Keyword"] = "",
	["Msg"] = {},
	["Mode_X"] = 720,
	["Mode_Y"] = 40,
}
XAFKSet = {}

SLASH_XAFK1 = "/xafk"
SlashCmdList["XAFK"] = function()
	XAFK.Status(1)
	XAFKGUI_Status1:SetChecked(true)
end

SLASH_XDND1 = "/xdnd"
SlashCmdList["XDND"] = function()
	XAFK.Status(2)
	XAFKGUI_Status2:SetChecked(true)
end

SLASH_XGUI1 = "/xgui"
SlashCmdList["XGUI"] = function()
	XAFK.GUIOpen()
end

local function Print(str, ...)
	DEFAULT_CHAT_FRAME:AddMessage(str:format(...), 1, 1, 1)
end

local function PopClick(key)
	if key=="RBUTTON" then
		XAFK.GUIOpen()
	else
		XAFK.Toggle()
	end
end

local function AutoOn()
	if (XAFKSet["Auto1"] or XAFKSet["Auto2"]) and XAFKSet["Mode"]==0 then
		if not XAFKFrame:IsVisible() then
			XAFKFrame:Show()
		end
	elseif XAFKFrame:IsVisible() then
		XAFKFrame:Hide()
	end
	if XAFKSet["Auto2"] and XAFKSet["Mode"]==0 then
		if not timer then
			XAFKFrame:RegisterEvent("UPDATE_MOUSE_LEAVE")
			XAFKFrame:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
			timer = GetTime()
		end
	elseif timer then
		XAFKFrame:UnregisterEvent("UPDATE_MOUSE_LEAVE")
		XAFKFrame:UnregisterEvent("UPDATE_MOUSEOVER_UNIT")
		timer = nil
	end
end

local function Start()
	if XAFKSet["Mode"]>0 then
		if XAFKSet["Mode"]==2 then
			XAFKMode_Text:SetText("|cffFFFF00[DND]|r")
		else
			XAFKMode_Text:SetText("|cff76FF00[AFK]|r")
		end
		XAFKMode:Show()
		for i, v in ipairs(chat) do
			XAFKFrame:RegisterEvent("CHAT_MSG_"..v)
		end
	else
		XAFKMode:Hide()
		for i, v in ipairs(chat) do
			XAFKFrame:UnregisterEvent("CHAT_MSG_"..v)
		end
	end
	for k, v in pairs(XAFKSet["ChSend"]) do
		if v then
			if ((GetNumPartyMembers()>0 or GetNumRaidMembers()>0) and k=="PARTY") or k~="PARTY" then
				SendChatMessage(XAFKSet["Send"..XAFKSet["Mode"]], k)
			end
		end
	end
	for k, v in pairs(XAFKSet["PChSend"]) do
		if v then
			for i, w in ipairs(p_ch) do
				if w==k then
					SendChatMessage(XAFKSet["Send"..XAFKSet["Mode"]], "CHANNEL", 0, i/2)
				end
			end
		end
	end
	AutoOn()
end

local function AddMsg(v)
	local x = 1
	local text = ""
	if v then
		x = #XAFKSet["Msg"]
	end
	for i = x, 1, -1 do
		if XAFKSet["Msg"][i] then
			text = "|cff7676FC"..XAFKSet["Msg"][i]["name"].."|r |cffFFE855"..XAFKSet["Msg"][i]["time"].."|r\n"
			text = text..XAFKSet["Msg"][i]["text"].."\n\n"
			XAFKMsg_Frame:AddMessage(text, XAFKSet["Msg"][i].r, XAFKSet["Msg"][i].g, XAFKSet["Msg"][i].b)
		end
	end
end

local function PChMenu(a)
	if #p_ch<1 then
		UIDropDownMenu_AddButton({text = C_NO.." "..CHAT_EDIT_CHANNEL, notCheckable = 1})
	end
	for i, v in ipairs(p_ch) do
		if i%2==0 then
			UIDropDownMenu_AddButton({
				text = v,
				func = function()
					if XAFKSet["PCh"..a][v] then
						XAFKSet["PCh"..a][v] = false
					else
						XAFKSet["PCh"..a][v] = true
					end
				end,
				checked = XAFKSet["PCh"..a][v],
				keepShownOnClick = 1,
			})
		end
	end
end

function XAFK.OnLoad(this)
	this:RegisterEvent("VARIABLES_LOADED")
	local lang = GetLanguage():upper()
	local _, err = loadfile("Interface/Addons/XAFK/Locales/"..lang..".lua")
	if err then
		Print("|cff993333XAFK can't find translation, ENUS.lua loaded.|r")
		dofile("Interface/Addons/XAFK/Locales/ENUS.lua")
	else
		dofile("Interface/Addons/XAFK/Locales/"..lang..".lua")
	end
end

function XAFK.OnEvent(this, event)
	if event=="VARIABLES_LOADED" then
		for k, v in pairs(def) do
			if XAFKSet[k]==nil then
				XAFKSet[k] = v
			end
		end
		SaveVariablesPerCharacter("XAFKSet")
		this:RegisterEvent("LOADING_END")
		this:RegisterEvent("CHAT_MSG_CHANNEL_JOIN")
		this:RegisterEvent("CHAT_MSG_CHANNEL_LEAVE")
		if XAFKSet["SaveMsg"] then
			AddMsg(true)
		else
			XAFK.Clear()
		end
		if not XAFKSet["SaveMode"] then
			XAFKSet["Mode"] = 0
		end
		XAFKMode:ClearAllAnchors()
		XAFKMode:SetAnchor("TOPLEFT", "TOPLEFT", "UIParent", XAFKSet["Mode_X"], XAFKSet["Mode_Y"])
		Print("|cff798FB8XAFK %s|r %s |cff798FB8/xgui|r %s\n|cff798FB8/xafk|r - AFK, |cff798FB8/xdnd|r - DND.", version, XAFK.Lang["Load"], XAFK.Lang["ToConfig"])
		if XBARVERSION and XBARVERSION>=1.51 then
			XAddon_Register({
				gui={{
					name = "XAFK",
					version = version,
					window = "XAFKGUI",
				}},
				popup={{
					GetText = function() return "XAFK "..version end,
					GetTooltip = function()
						return "/xafk, /xdnd, /xgui\n\n"..XAFK.Lang["TipX"].."\n"..XAFK.Lang["Tip2"] end,
					OnClick = function(this, key) PopClick(key) end,
			}}})
		end
	end
	if loading==0 and event=="LOADING_END" then
		if XAFKSet["Keyword"]=="" then
			XAFKSet["Keyword"] = UnitName("player")
		end
		if XAFKSet["Mode"]>0 then
			Start()
		else
			AutoOn()
		end
		loading = nil
	end
	if event=="CHAT_MSG_CHANNEL_JOIN" or event=="CHAT_MSG_CHANNEL_LEAVE" then
		p_ch = {GetChannelList()}
	end
	for i, v in ipairs(chat) do
		if XAFKSet["Mode"]>0 and event=="CHAT_MSG_"..v then
			local add
			if string.find(arg1:lower(), XAFKSet["Keyword"]:lower()) then
				if XAFKSet["ChRec"][v] and i<6 then
					add = 1
				end
				if i==7 then
					for k, w in pairs(XAFKSet["PChRec"]) do
						if w then
							for j, x in ipairs(p_ch) do
								if x==k and arg3*2==j then
									add = 1
									break
								end
							end
						end
					end
				end
			end
			if XAFKSet["WhRec"] and i==6 then
				add = 1
			end
			if (arg1~=whM or arg4~=whN) and XAFKSet["WhReply"] and i==6 then
				SendChatMessage(XAFKSet["Send"..XAFKSet["Mode"]], "WHISPER", 0, arg4)
				whM, whN = arg1, arg4
			end
			if add then
				local value = {time = os and os.date("%H:%M %m-%b") or "", name = arg2, text = arg1}
				if value.name~="" or value.name~=nil then
					if i==7 then
						value.r, value.g, value.b = GetChannelColor(v..arg3)
					else
						value.r, value.g, value.b = GetChannelColor(v)
					end
					table.insert(XAFKSet["Msg"], 1, value)
					AddMsg()
				end
			end
			if #XAFKSet["Msg"]>100 then
				table.remove(XAFKSet["Msg"], 101)
			end
			break
		end
	end
	if event=="UPDATE_MOUSEOVER_UNIT" or event=="UPDATE_MOUSE_LEAVE" then
		timer = GetTime()
	end
end

function XAFK.OnUpdate(elapsedTime)
	update = update + elapsedTime
	if update>=1 then
		update = 0
		if XAFKSet["Mode"]==0 then
			if XAFKSet["Auto1"] then
				if os and string.match(XAFKSet["Timer1"], os.date("%H%M%S")) then
					XAFKSet["Mode"] = 1
					Print("|cff798FB8XAFK|r - %s|cff798FB8%s|r.", XAFK.Lang["Start"], os.date("%H:%M.%S"))
				end
			end
			if XAFKSet["Auto2"] then
				if tostring(math.floor(GetTime() - timer))==XAFKSet["Timer2"] then
					XAFKSet["Mode"] = 1
					timer = GetTime()
					Print("|cff798FB8XAFK|r - %s|cff798FB8%s|r.", XAFK.Lang["Start"], os.date("%H:%M.%S"))
				end
			end
		end
		if XAFKSet["Mode"]==1 and not XAFKMode:IsVisible() then
			Start()
			XAFKGUI_Status1:SetChecked(true)
		end
	end
end

function XAFK.Status(n)
	if XAFKSet["Mode"]~=n then
		XAFKSet["Mode"] = n
		Start()
	end
end

function XAFK.Toggle(c)
	if c then
		XAFKSet["Mode"] = 0
	else
		if XAFKSet["Mode"]==1 then
			XAFKSet["Mode"] = 2
		else
			XAFKSet["Mode"] = 1
		end
	end
	_G["XAFKGUI_Status"..XAFKSet["Mode"]]:SetChecked(true)
	Start()
end

function XAFK.Clear()
	XAFKSet["Msg"] = {}
	XAFKMsg_Frame:ClearText()
end

function XAFK.GUIShow(this)
	_G["XAFKGUI_Status"..XAFKSet["Mode"]]:SetChecked(true)
	XAFKGUI_Send1:SetText(XAFKSet["Send1"])
	XAFKGUI_Send2:SetText(XAFKSet["Send2"])
	XAFKGUI_Send0:SetText(XAFKSet["Send0"])
	XAFKGUI_Auto1:SetChecked(XAFKSet["Auto1"])
	XAFKGUI_Timer1:SetText(XAFKSet["Timer1"])
	XAFKGUI_Auto2:SetChecked(XAFKSet["Auto2"])
	XAFKGUI_Timer2:SetText(XAFKSet["Timer2"])
	XAFKGUI_WhReply:SetChecked(XAFKSet["WhReply"])
	XAFKGUI_WhRec:SetChecked(XAFKSet["WhRec"])
	XAFKGUI_SaveMode:SetChecked(XAFKSet["SaveMode"])
	XAFKGUI_SaveMsg:SetChecked(XAFKSet["SaveMsg"])
	for i, v in ipairs(chat) do
		if i<6 then
			_G["XAFKGUI_"..v]:SetChecked(XAFKSet["ChRec"][v])
		end
	end
	for i, v in ipairs(chat) do
		if i<4 then
			_G["XAFKGUI_"..v.."2"]:SetChecked(XAFKSet["ChSend"][v])
		end
	end
	XAFKGUI_Keyword:SetText(XAFKSet["Keyword"])
	XAFKGUI_Send1_Name:SetText("|cff00FF00AFK|r / "..XAFK.Lang["Send1"])
	XAFKGUI_Send2_Name:SetText("|cff00FF00DND|r / "..XAFK.Lang["Send2"])
	XAFKGUI_Send0_Name:SetText("|cff00FF00"..NORMAL.."|r / "..XAFK.Lang["Send0"])
	XAFKGUI_Auto1_Name:SetText(XAFK.Lang["Auto1"])
	XAFKGUI_Timer1_Name:SetText(XAFK.Lang["Timer1"])
	XAFKGUI_Auto2_Name:SetText(XAFK.Lang["Auto2"])
	XAFKGUI_Timer2_Name:SetText(XAFK.Lang["Timer2"])
	XAFKGUI_WhReply_Name:SetText(XAFK.Lang["WhReply"])
	XAFKGUI_WhRec_Name:SetText(XAFK.Lang["WhRec"])
	XAFKGUI_SaveMode_Name:SetText(XAFK.Lang["SaveMode"])
	XAFKGUI_SaveMsg_Name:SetText(XAFK.Lang["SaveMsg"])
	XAFKGUI_Send:SetText(XAFK.Lang["Send"])
	XAFKGUI_Rec:SetText(XAFK.Lang["Rec"])
	for i, v in ipairs(chat) do
		if i<6 then
			_G["XAFKGUI_"..v.."_Name"]:SetText(TEXT("CHAT_MSG_"..v))
		end
	end
	XAFKGUI_Keyword_Name:SetText(XAFK.Lang["Keyword"])
	XAFKGUI_Version:SetText("XAFK "..version)
	if XBARVERSION and XBARVERSION>=1.51 then
		XAddon_Page(this)
	end
end

function XAFK.PChMenuShow(this, a)
	local f = function() PChMenu(a) end
	UIDropDownMenu_Initialize(this, f)
	UIDropDownMenu_SetWidth(this, 200)
	UIDropDownMenu_SetText(this, XAFK.Lang["PCh"..a])
end

function XAFK.Save()
	XAFKSet["Send1"] = XAFKGUI_Send1:GetText()
	XAFKSet["Send2"] = XAFKGUI_Send2:GetText()
	XAFKSet["Send0"] = XAFKGUI_Send0:GetText()
	XAFKSet["Auto1"] = XAFKGUI_Auto1:IsChecked()
	XAFKSet["Timer1"] = XAFKGUI_Timer1:GetText()
	XAFKSet["Auto2"] = XAFKGUI_Auto2:IsChecked()
	XAFKSet["Timer2"] = XAFKGUI_Timer2:GetText()
	XAFKSet["WhReply"] = XAFKGUI_WhReply:IsChecked()
	XAFKSet["WhRec"] = XAFKGUI_WhRec:IsChecked()
	XAFKSet["SaveMode"] = XAFKGUI_SaveMode:IsChecked()
	XAFKSet["SaveMsg"] = XAFKGUI_SaveMsg:IsChecked()
	for i, v in ipairs(chat) do
		if i<6 then
			XAFKSet["ChRec"][v] = _G["XAFKGUI_"..v]:IsChecked()
		end
	end
	for i, v in ipairs(chat) do
		if i<4 then
			XAFKSet["ChSend"][v] = _G["XAFKGUI_"..v.."2"]:IsChecked()
		end
	end
	XAFKSet["Keyword"] = XAFKGUI_Keyword:GetText()
	AutoOn()
end

function XAFK.GUIOpen()
	if XBARVERSION and XBARVERSION>=1.51 then
		XAddon_ShowPage("XAFKGUI")
	else
		ToggleUIFrame(XAFKGUI)
	end
end

function XAFK.GUIClose(this)
	if XBARVERSION and XBARVERSION>=1.51 then
		XAddonMngr:Hide()
	end
	this:GetParent():Hide()
end

function XAFK.ModeTip(this)
	GameTooltip:SetOwner(this, "ANCHOR_BOTTOM")
	GameTooltip:SetText("- "..XAFK.Lang["Tip1"].."\n- "..XAFK.Lang["Tip2"].."\n- "..UIPANELANCHORFRAME_TOOLTIP, 0, .7, .9)
	if XAFKSet["Mode"]>0 then
		if XAFKSet["Msg"][1] then
			GameTooltip:AddSeparator()
			GameTooltip:AddLine("|cff8DE668"..XAFK.Lang["Tip3"].."|r")
			for i = 1, 3 do if (XAFKSet["Msg"][i]) then
			local text = "|cffFFE855"..i..">|r |cff7676FC"..XAFKSet["Msg"][i]["name"]
			text = text.."|r |cffFFE855"..XAFKSet["Msg"][i]["time"].."|r\n"
			text = text..XAFKSet["Msg"][i]["text"] GameTooltip:AddLine("") GameTooltip:AddLine(text) end end
		end
	end
end

function XAFK.ModeDown(this, key)
	if key=="RBUTTON" then
		if IsShiftKeyDown() then
			this:StartMoving()
		else
			XAFK.GUIOpen()
		end
	end
end

function XAFK.MsgScroll(this, delta)
	if delta>0 then
		this:ScrollUp()
	else
		this:ScrollDown()
	end
end

