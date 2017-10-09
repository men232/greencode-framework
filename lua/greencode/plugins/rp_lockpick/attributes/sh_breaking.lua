--[[
	© 2013 GmodLive private project do not share
	without permission of its author (Andrew Mensky vk.com/men232).
--]]

local ATTRIBUTE = gc.attribute:New();
	ATTRIBUTE.name = "Взлом";
	ATTRIBUTE.maximum = 75;
	ATTRIBUTE.uniqueID = "brk";
	ATTRIBUTE.description = "Параметр влияет на скорость взлома замков. Чем выше показатль,\nтем проще вам будет взломать сложные замки и тем тише вы будете\nэто делать.";
	ATTRIBUTE.isOnCharScreen = true;
ATB_BREAK = gc.attribute:Register(ATTRIBUTE);