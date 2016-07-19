local AddOnName, Engine = ...;
local AddOn = LibStub("AceAddon-3.0"):NewAddon("Altoholic_CountHider", "AceConsole-3.0", "AceEvent-3.0")
--GLOBALS: CreateFrame, hooksecurefunc, LibStub
local AceGUI = LibStub("AceGUI-3.0")

AddOn.DF = {};
AddOn.DF["profile"] = {
	["HS"] = true,
	["innkeeper"] = true,
	["garHS"] = true,
	["blacklist"] = "",
};

local L = LibStub("AceLocale-3.0"):GetLocale(AddOnName, false);

Engine[1] = AddOn;
Engine[2] = Locale;
Engine[3] = AddOn.DF["profile"];

_G[AddOnName] = Engine;

local _G = _G
local pairs = pairs
local tonumber = tonumber
local setmetatable, getmetatable = setmetatable, getmetatable
local string_sub = string.sub
local strSplit = string.split
local type = type
local table = table
local twipe = table.wipe
local select = select
local GetItemInfo = GetItemInfo
local SETTINGS = SETTINGS

local function tcopy(t, deep, seen)
	seen = seen or {}
	if t == nil then return nil end
	if seen[t] then return seen[t] end

	local nt = {}
	for k, v in pairs(t) do
		if deep and type(v) == 'table' then
			nt[k] = tcopy(v, deep, seen)
		else
			nt[k] = v
		end
	end
	setmetatable(nt, tcopy(getmetatable(t), deep, seen))
	seen[t] = nt
	return nt
end

AddOn.Version = GetAddOnMetadata("Altoholic_CountHider", "Version")
AddOn.myname = UnitName("player")
AddOn.myrealm = GetRealmName()

local AC = LibStub("AceConfig-3.0")
local ACD = LibStub("AceConfigDialog-3.0")

AddOn.Options = {
	type = "group",
	name = "Altoholic Count Hider"..format(" v|cff99ff33%s|r",AddOn.Version),
	args = {},
}

local IgnoreThis = {}
local function BuildBlacklist(...)
	twipe(IgnoreThis)
	for index = 1, select('#', ...) do
		local name = select(index, ...)
		local isLink = GetItemInfo(name)
		if isLink then
			IgnoreThis[isLink] = true
		end
	end
end
local function BLPrepare(value)
	BuildBlacklist(strSplit(",", value))
end

local MAIN_BANK_SLOTS = 100
function DataStore:GetContainerItemCount(character, searchedID)
	local bagCount = 0
	local bankCount = 0
	local voidCount = 0
	local reagentBankCount = 0
	local id

	character = _G["DataStore_ContainersDB"].global.Characters[character] --Mod to account for altoholc passing string for some reason

	-- old voidstorage, simply delete it, might still be listed if players haven't logged on all their alts
	character.Containers["VoidStorage"] = nil

	--This is modified part checking for general ignored items
	if AddOn.db.HS and searchedID == 6948 then return bagCount, bankCount, voidCount, reagentBankCount end
	if AddOn.db.innkeeper and searchedID == 64488 then return bagCount, bankCount, voidCount, reagentBankCount end
	if AddOn.db.garHS and searchedID == 110560 then return bagCount, bankCount, voidCount, reagentBankCount end
	local searchedItem = GetItemInfo(searchedID)
	if searchedItem and IgnoreThis[searchedItem] then return bagCount, bankCount, voidCount, reagentBankCount end
	--End of modified part

	for containerName, container in pairs(character.Containers) do
		for slotID = 1, container.size do
			id = container.ids[slotID]
			
			if (id) and (id == searchedID) then
				local itemCount = container.counts[slotID] or 1
				if (containerName == "VoidStorage.Tab1") or (containerName == "VoidStorage.Tab2") then
					voidCount = voidCount + 1
				elseif (containerName == "Bag"..MAIN_BANK_SLOTS) then
					bankCount = bankCount + itemCount
				elseif (containerName == "Bag-2") then
					bagCount = bagCount + itemCount
				elseif (containerName == "Bag-3") then
					reagentBankCount = reagentBankCount + itemCount
				else
					local bagNum = tonumber(string_sub(containerName, 4))
					if (bagNum >= 0) and (bagNum <= 4) then
						bagCount = bagCount + itemCount
					else
						bankCount = bankCount + itemCount
					end
				end
			end
		end
	end

	return bagCount, bankCount, voidCount, reagentBankCount
end

local function SetupOptions()
	AddOn.Options.args.general = {
		order = 1,
		type = "group",
		name = SETTINGS,
		args = {
			info = {
				order = 1,
				type = "description",
				name = L["Altoholic_Hider_Desc"],
			},
			HS = {
				order = 2,
				type = "toggle",
				name = L["Hearthstone"],
				get = function(info) return AddOn.db[ info[#info] ] end,
				set = function(info, value) AddOn.db[ info[#info] ] = value end,
			},
			innkeeper = {
				order = 3,
				type = "toggle",
				name = L["Innkeeper's Daughter"],
				get = function(info) return AddOn.db[ info[#info] ] end,
				set = function(info, value) AddOn.db[ info[#info] ] = value end,
			},
			garHS = {
				order = 4,
				type = "toggle",
				name = L["Garrison Hearthstone"],
				get = function(info) return AddOn.db[ info[#info] ] end,
				set = function(info, value) AddOn.db[ info[#info] ] = value end,
			},
			blacklist = {
				order = 5,
				name = L["Ignore List"],
				desc = L["Altoholic_Hider_BL_Desc"],
				type = 'input',
				width = 'full',
				multiline = true,
				get = function(info) return AddOn.db[ info[#info] ] end,
				set = function(info, value) AddOn.db[ info[#info] ] = value; BLPrepare(value) end,
			},
		},
	}

	AddOn.Options.args.profiles = LibStub("AceDBOptions-3.0"):GetOptionsTable(AddOn.data);
	AddOn.Options.args.profiles.order = -10
	AC:RegisterOptionsTable("Altoholic_CountHider_Profiles", AddOn.Options.args.profiles)

	AC:RegisterOptionsTable("Altoholic_CountHider", AddOn.Options)
	ACD:AddToBlizOptions("Altoholic_CountHider", "Altoholic |cff9482c9Count Hider|r")
end

function AddOn:CopyTable(currentTable, defaultTable)
	if type(currentTable) ~= "table" then currentTable = {} end

	if type(defaultTable) == 'table' then
		for option, value in pairs(defaultTable) do
			if type(value) == "table" then
				value = self:CopyTable(currentTable[option], value)
			end

			currentTable[option] = value
		end
	end

	return currentTable
end

function AddOn:ToggleConfig()
	local mode = 'Close'
	if not ACD.OpenFrames[AddOnName] then
		mode = 'Open'
	end

	ACD[mode](ACD, AddOnName)
	_G["GameTooltip"]:Hide() --Just in case you're mouseovered something and it closes.
end

function AddOn:UpdateAll()
	self.db = self.data.profile;
	BLPrepare(AddOn.db.blacklist)

	collectgarbage('collect');
end

function AddOn:PLAYER_LOGIN()
	BLPrepare(AddOn.db.blacklist)
end

function AddOn:OnInitialize()
	if not Altoholic_CountHiderDB then
		Altoholic_CountHiderDB = {}
	end

	self.db = tcopy(self.DF.profile, true);
	if Altoholic_CountHiderDB then
		local profileKey
		if Altoholic_CountHiderDB.profileKeys then
			profileKey = Altoholic_CountHiderDB.profileKeys[self.myname..' - '..self.myrealm]
		end

		if profileKey and Altoholic_CountHiderDB.profiles and Altoholic_CountHiderDB.profiles[profileKey] then
			self:CopyTable(self.db, Altoholic_CountHiderDB.profiles[profileKey])
		end
	end

	self.data = LibStub("AceDB-3.0"):New("Altoholic_CountHiderDB", self.DF, "Default");
	self.data.RegisterCallback(self, "OnProfileChanged", "UpdateAll")
	self.data.RegisterCallback(self, "OnProfileCopied", "UpdateAll")
	self.data.RegisterCallback(self, "OnProfileReset", "UpdateAll")
	self.db = self.data.profile;

	SetupOptions()
	BLPrepare(AddOn.db.blacklist)
	self:RegisterEvent("PLAYER_LOGIN")

	_G["SlashCmdList"].ALTOHOLIC_COUNTHIDER_CONFIG = AddOn.ToggleConfig
	SLASH_ALTOHOLIC_COUNTHIDER_CONFIG1 = "/altcount"
	SLASH_ALTOHOLIC_COUNTHIDER_CONFIG2 = "/фдесщгте"
end