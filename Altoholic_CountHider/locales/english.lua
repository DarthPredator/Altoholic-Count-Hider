local AceLocale = LibStub:GetLibrary("AceLocale-3.0");
local L = AceLocale:NewLocale("Altoholic_CountHider", "enUS", true, true);
if not L then return; end

L["Altoholic_Hider_Desc"] = [[These options will allow you to hide count lines on your characters for some items.
By default it hides counters for Hearthstone and Garrison Hearthstone.
You can also add your own items via "Ignore List" option.]]
L["Hearthstone"] = true
L["Garrison Hearthstone"] = true
L["Dalaran Hearthstone"] = true
L["Ignore List"] = true
L["Altoholic_Hider_BL_Desc"] = [[Count for items listed here will not be shown in tooltips.
Can be either name or link. Items need to be separated by comma WITHOUT spaces.]]
