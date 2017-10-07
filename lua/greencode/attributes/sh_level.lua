--[[
	© 2013 GmodLive private project do not share
	without permission of its author (Andrew Mensky vk.com/men232).
--]]

local ATTRIBUTE = gc.attribute:New();
	ATTRIBUTE.name = "Уровень";
	ATTRIBUTE.maximum = 75;
	ATTRIBUTE.uniqueID = "lvl";
	ATTRIBUTE.description = "Этот атрибут отображает твой навык игры. Чем лучше ты\nсправляешься с различными ситуациями и профессиональными\nобязанностями, тем выше уроень.\n\nВлияет на доступ к важным профессиям..";
	ATTRIBUTE.isOnCharScreen = true;
	ATTRIBUTE.isShared = true;
	ATTRIBUTE.default = 1;
ATB_LEVEL = gc.attribute:Register(ATTRIBUTE);