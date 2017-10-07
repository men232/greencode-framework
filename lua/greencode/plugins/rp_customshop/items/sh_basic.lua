local ITEM = CSHOP_ITEM_CLASS:New{
	name = "Микроволновка",
	max = 3,
	class = "microwave",
	model = "models/props/cs_office/microwave.mdl",
	price = 100,
	allowed = TEAM_COOK,
	description = [[Базовый элемент на кухне.]],
	location = "^",
}:Register();

local ITEM = CSHOP_ITEM_CLASS:New{
	name = "Гардероб",
	max = 3,
	class = "short_sell",
	model = "models/props/de_tides/Vending_tshirt.mdl",
	price = 300,
	allowed = TEAM_TRADER,
	description = [[Элемент для продажи одежды.]],
	location = "^",
}:Register();