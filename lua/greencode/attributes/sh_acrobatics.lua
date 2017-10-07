--[[
	© 2013 GmodLive private project do not share
	without permission of its author (Andrew Mensky vk.com/men232).
--]]

local ATTRIBUTE = gc.attribute:New();
	ATTRIBUTE.name = "Акробатика";
	ATTRIBUTE.maximum = 75;
	ATTRIBUTE.uniqueID = "acr";
	ATTRIBUTE.description = "Данный атрибут влияет на высоту вашего прыжка. В развитии этого\nнавыка помогут физические нагрузки, а именно бег и прыжки.";
	ATTRIBUTE.isOnCharScreen = true;
ATB_ACROBATICS = gc.attribute:Register(ATTRIBUTE);