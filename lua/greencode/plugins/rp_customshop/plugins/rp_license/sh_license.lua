--[[
	© 2013 GmodLive private project do not share
	without permission of its author (Andrew Mensky vk.com/men232).
--]]
local PLUGIN = PLUGIN or greenCode.plugin:Loader();

-- License list.
PLUGIN:AddLicense("weapon", {
	name = "Оружие",
	description = "Лицензия на продажу или ношение пистолета",
	job = {TEAM_POLICE, TEAM_SWAT, TEAM_SPY, TEAM_MAYOR, TEAM_CHIEF},
	need_lvl = 3,
	lvl_token = 5,
});

PLUGIN:AddLicense("weapon2", {
	name = "Оружие",
	description = "Лицензия на продажу или ношение авто. оружия",
	job = {TEAM_SWAT, TEAM_SPY, TEAM_CHIEF},
	need_lvl = 10,
	lvl_token = 15,
});

PLUGIN:AddLicense("weapon3", {
	name = "Оружие",
	description = "Лицензия на продажу или ношение винтовок",
	job = {TEAM_SWAT, TEAM_CHIEF},
	need_lvl = 25,
	lvl_token = 35,
});

PLUGIN:AddLicense("food", {
	name = "Еда",
	description = "Лицензия на продажу еды",
	job = {TEAM_COOK}
});

PLUGIN:AddLicense("veihicle", {
	name = "Транспорт",
	description = "Права на вождение автомобиля",
	need_lvl = 3,
	lvl_token = 5,
});