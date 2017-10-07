--[[
	© 2013 GmodLive private project do not share
	without permission of its author (Andrew Mensky vk.com/men232).
--]]

local ATTRIBUTE = gc.attribute:New();
	ATTRIBUTE.name = "Ловкость";
	ATTRIBUTE.maximum = 75;
	ATTRIBUTE.uniqueID = "agt";
	ATTRIBUTE.description = "Влияет на скорость спринта. Постоянные беговые тренировки\nпомогут развить этот навык.";
	ATTRIBUTE.isOnCharScreen = true;
ATB_AGILITY = gc.attribute:Register(ATTRIBUTE);