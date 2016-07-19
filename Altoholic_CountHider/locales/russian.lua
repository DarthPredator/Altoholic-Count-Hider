﻿local AceLocale = LibStub:GetLibrary("AceLocale-3.0");
local L = AceLocale:NewLocale("Altoholic_CountHider", "ruRU");
if not L then return; end

L["Altoholic_Hider_Desc"] = [[Эти опции позволят вам скрыть количество указанных предметов на ваших персонажах.
По умолчанию скрыты камень возвращения и камень возвращения в гарнизон.
Вы можете добавить свои предметы при помощи опции "Список игнорирования".]]
L["Hearthstone"] = "Камень возвращения"
L["Innkeeper's Daughter"] = "Дочь тавернщика"
L["Garrison Hearthstone"] = "Камень возвращения в гарнизон"
L["Ignore List"] = "Список игнорирования"
L["Altoholic_Hider_BL_Desc"] = [[Счетчик предметов, указанных здесь, не будет отображаться в подсказках.
Можно использовать как имена, так и ссылки. Предметы должны быть разделены запятыми БЕЗ пробелов.]]