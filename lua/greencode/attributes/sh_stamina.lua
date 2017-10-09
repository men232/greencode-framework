--[[
	© 2013 GmodLive private project do not share
	without permission of its author (Andrew Mensky vk.com/men232).
--]]

local ATTRIBUTE = gc.attribute:New();
	ATTRIBUTE.name = "Выносливость";
	ATTRIBUTE.maximum = 75;
	ATTRIBUTE.uniqueID = "stam";
	ATTRIBUTE.description = "Позволяет дольше бежать и испытывать разные нагрузки.\nМожно развить силовыми и беговыми упражнениями.";
	ATTRIBUTE.isOnCharScreen = true;
	ATTRIBUTE.isShared = false;
ATB_STAMINA = gc.attribute:Register(ATTRIBUTE);