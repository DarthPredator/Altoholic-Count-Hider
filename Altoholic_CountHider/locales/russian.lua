local AceLocale = LibStub:GetLibrary("AceLocale-3.0");
local L = AceLocale:NewLocale("Altoholic_CountHider", "ruRU");
if not L then return; end

L["Altoholic_Hider_Desc"] = [[Эти опции позволят вам скрыть количество указанных предметов на ваших персонажах.
По умолчанию скрыты камень возвращения и камень возвращения в гарнизон.
Вы можете добавить свои предметы при помощи опции "Список игнорирования".]]
L["Hearthstone"] = "Камень возвращения"
L["Garrison Hearthstone"] = "Камень возвращения в гарнизон"
L["Dalaran Hearthstone"] = "Камень в Даларан"
L["Flight Master's Whistle"] = "Свисток распорядителя полетов"
L["Ignore List"] = "Список игнорирования"
L["Altoholic_Hider_BL_Desc"] = [[Счетчик предметов, указанных здесь, не будет отображаться в подсказках.
Можно использовать как имена, так и ссылки. Предметы должны быть разделены запятыми БЕЗ пробелов.]]
L["Ignore all quipped"] = "Игнорировать надетое"
L['Hides all "Equipped" lines for the item even if it is not included in ignore list.'] = "Скрыть количество надетых предметов, даже если их нет в списке игнорирования."