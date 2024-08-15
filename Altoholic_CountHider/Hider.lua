local AddOnName, Engine = ...;
local AddOn = LibStub("AceAddon-3.0"):NewAddon("Altoholic_CountHider", "AceConsole-3.0", "AceEvent-3.0")
--GLOBALS: CreateFrame, hooksecurefunc, LibStub
local AceGUI = LibStub("AceGUI-3.0")
local MVC = LibStub("LibMVC-1.0")

AddOn.DF = {};
AddOn.DF["profile"] = {
	["DarkmoonGuide"] = true,
	["blacklist"] = "",
	["ignoreAllEquipped"] = false,
};

local L = LibStub("AceLocale-3.0"):GetLocale(AddOnName, false);

Engine[1] = AddOn;
Engine[2] = Locale;
Engine[3] = AddOn.DF["profile"];

_G[AddOnName] = Engine;

-- AddOn.hookModules = 2;

local _G = _G
local pairs, next = pairs, next
local tonumber = tonumber
local setmetatable, getmetatable = setmetatable, getmetatable
local string_sub = string.sub
local strSplit = string.split
local type = type
local table = table
local twipe = table.wipe
local select = select
local C_Item_GetItemInfo = C_Item.GetItemInfo
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

AddOn.Version = C_AddOns.GetAddOnMetadata("Altoholic_CountHider", "Version")
AddOn.myname = UnitName("player")
AddOn.myrealm = GetRealmName()

local AC = LibStub("AceConfig-3.0")
local ACD = LibStub("AceConfigDialog-3.0")

AddOn.Options = {
	type = "group",
	name = "Altoholic Count Hider"..format(" v|cff99ff33%s|r",AddOn.Version),
	args = {},
}

AddOn.ItemsToFind = {
	[71634] = true,
}
AddOn.ItemNames = {}
AddOn.InfoQueued = {}

local IgnoreThis = {}
local function BuildBlacklist(...)
	twipe(IgnoreThis)
	for index = 1, select('#', ...) do
		local name = select(index, ...)
		local isLink = C_Item_GetItemInfo(name)
		if isLink then
			IgnoreThis[isLink] = true
		end
	end
end

local function BLPrepare(value)
	BuildBlacklist(strSplit(",", value))
	AddOn.AltoholicTooltipService:RefreshTooltip()
end

local function CleanUpProfile()
	if AddOn.db.HS ~= nil then AddOn.db.HS = nil end
	if AddOn.db.garHS ~= nil then AddOn.db.garHS = nil end
	if AddOn.db.dalHS ~= nil then AddOn.db.dalHS = nil end
	if AddOn.db.whistle ~= nil then AddOn.db.whistle = nil end
end

local MAIN_BANK_SLOTS = 100
local function HookContainers()
	function DataStore:GetContainerItemCount(character, searchedID)
		-- if not DataStore_Containers then return 0, 0, 0 ,0 end
		local bagCount = 0
		local bankCount = 0
		local voidCount = 0
		local reagentBankCount = 0
		local id

		local characterDB = _G.DataStore:GetCharacterDB("DataStore_Containers_Characters") --Mod to account for altoholc passing string for some reason

		-- old voidstorage, simply delete it, might still be listed if players haven't logged on all their alts
		characterDB.Containers["VoidStorage"] = nil

		--This is modified part checking for general ignored items
		if AddOn.db.DarkmoonGuide and searchedID == 71634 then return bagCount, bankCount, voidCount, reagentBankCount end
		local searchedItem = C_Item_GetItemInfo(searchedID)
		if searchedItem and IgnoreThis[searchedItem] then return bagCount, bankCount, voidCount, reagentBankCount end
		--End of modified part

		for containerID, container in pairs(characterDB.Containers) do
			-- get the container count
			count = _G.DataStore:GetItemCountByID(container, searchedID)
			-- count = _G.DataStore:GetItemCountByID(_G.DataStore:GetContainer(character, containerID), searchedID)
			
			if containerID <= 4 then
				bagCount = bagCount + count
			elseif containerID == 5 and isRetail then
				reagentBagCount = reagentBagCount + count
			else
				bankCount = bankCount + count
			end
		end
	
		return bagCount, bankCount, reagentBagCount
	end
end

local function HookInventory()
	function DataStore:GetInventoryItemCount(character, searchedID)
	-- print(character, searchID)
		if AddOn.db.ignoreAllEquipped or not DataStore_Inventory then return 0 end

		local characterDB = _G.DataStore:GetCharacterDB("DataStore_Containers_Characters") --Mod to account for altoholc passing string for some reason

		local searchedItem = C_Item_GetItemInfo(searchedID)
		
		local count = 0
		for _, item in pairs(characterDB.Inventory) do
			if searchedItem and not IgnoreThis[searchedItem] then
				if type(item) == "number" then		-- saved as a number ? this is the itemID
					if (item == searchedID) then
						count = count + 1
					end
				elseif tonumber(item:match("item:(%d+)")) == searchedID then		-- otherwise it's the item link
					count = count + 1
				end
			end
		end

		return count
	end
end

local function SetupOptions()
	if ACD.BlizOptions["Altoholic_CountHider"] or next(AddOn.InfoQueued) or next(AddOn.ItemsToFind) then return end
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
			DarkmoonGuide = {
				order = 6,
				type = "toggle",
				name = AddOn.ItemNames[71634],
				get = function(info) return AddOn.db[ info[#info] ] end,
				set = function(info, value) AddOn.db[ info[#info] ] = value end,
			},
			blacklist = {
				order = 20,
				name = L["Ignore List"],
				desc = L["Altoholic_Hider_BL_Desc"],
				type = 'input',
				width = 'full',
				multiline = true,
				get = function(info) return AddOn.db[ info[#info] ] end,
				set = function(info, value) AddOn.db[ info[#info] ] = value; BLPrepare(value) end,
			},
			ignoreAllEquipped = {
				order = 21,
				type = "toggle",
				name = L["Ignore all quipped"],
				desc = L['Hides all "Equipped" lines for the item even if it is not included in ignore list.'],
				get = function(info) return AddOn.db[ info[#info] ] end,
				set = function(info, value) AddOn.db[ info[#info] ] = value end,
			},
		},
	}

	AddOn.Options.args.profiles = LibStub("AceDBOptions-3.0"):GetOptionsTable(AddOn.data);
	AddOn.Options.args.profiles.order = -10
	AC:RegisterOptionsTable("Altoholic_CountHider_Profiles", AddOn.Options.args.profiles)

	AC:RegisterOptionsTable("Altoholic_CountHider", AddOn.Options)
	ACD:AddToBlizOptions("Altoholic_CountHider", "Altoholic |cff9482c9Count Hider|r")

	_G["SlashCmdList"].ALTOHOLIC_COUNTHIDER_CONFIG = AddOn.ToggleConfig
	SLASH_ALTOHOLIC_COUNTHIDER_CONFIG1 = "/altcount"
	SLASH_ALTOHOLIC_COUNTHIDER_CONFIG2 = "/фдесщгте"
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
end

function AddOn:PLAYER_LOGIN()
	BLPrepare(AddOn.db.blacklist)
end

local function GetItemNames(id)
	local name = C_Item_GetItemInfo(id)
	if not name then
		AddOn.InfoQueued[id] = true
		return
	end
	AddOn.ItemNames[id] = name
	AddOn.ItemsToFind[id] = nil
	-- print(id,name)
end

function AddOn:GET_ITEM_INFO_RECEIVED(event, id)
	if AddOn.InfoQueued[id] then 
		AddOn.InfoQueued[id] = nil
		GetItemNames(id)
		if not ACD.BlizOptions["Altoholic_CountHider"] and not next(AddOn.InfoQueued) and not next(AddOn.ItemsToFind) then SetupOptions() end
	end
end

function AddOn:OnInitialize()
	if not Altoholic_CountHiderDB then
		Altoholic_CountHiderDB = {}
	end
	AddOn.AltoholicTooltipService = MVC:GetService("AltoholicUI.Tooltip")

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

	BLPrepare(AddOn.db.blacklist)
	self:RegisterEvent("PLAYER_LOGIN")
	self:RegisterEvent("GET_ITEM_INFO_RECEIVED")
	
	--Build item names list
	for id,_ in pairs(AddOn.ItemsToFind) do GetItemNames(id) end
	SetupOptions()
	CleanUpProfile()

	HookInventory()
	HookContainers()
end