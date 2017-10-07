--[[
	© 2013 GmodLive private project do not share
	without permission of its author (Andrew Mensky vk.com/men232).
--]]

local ATTRIBUTE = gc.attribute:New();
	ATTRIBUTE.name = "Сила";
	ATTRIBUTE.maximum = 75;
	ATTRIBUTE.uniqueID = "str";
	ATTRIBUTE.description = "Параметр влияет на физическую силу персонажа. Чем выше силовые\nпоказатели, тем больнее будет удар дубинкой или кулаком.";
	ATTRIBUTE.isOnCharScreen = true;
ATB_STRENGTH = gc.attribute:Register(ATTRIBUTE);