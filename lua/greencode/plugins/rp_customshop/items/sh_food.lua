local ITEM = CSHOP_ITEM_CLASS:New{
	name = "Банан",
	class = "spawned_food",
	model = "models/props/cs_italy/bananna.mdl",
	price = 10,
	category = "Продукты",
	data = {FoodEnergy = 5},
	license = "food",
	allowed = {TEAM_TRADER, TEAM_COOK},
	description = "Обыкновенная пища\nВосстановление голода: 5.",
}:Register();

local ITEM = CSHOP_ITEM_CLASS:New{
	name = "Связка бананов",
	class = "spawned_food",
	model = "models/props/cs_italy/bananna_bunch.mdl",
	price = 30,
	category = "Продукты",
	data = {FoodEnergy = 20},
	license = "food",
	allowed = {TEAM_TRADER, TEAM_COOK},
	description = "Обыкновенная пища\nВосстановление голода: 20.",
}:Register();

local ITEM = CSHOP_ITEM_CLASS:New{
	name = "Арбуз",
	class = "spawned_food",
	model = "models/props_junk/watermelon01.mdl",
	price = 15,
	category = "Продукты",
	data = {FoodEnergy = 25},
	license = "food",
	allowed = {TEAM_TRADER, TEAM_COOK},
	description = "Обыкновенная пища\nВосстановление голода: 25.",
}:Register();

local ITEM = CSHOP_ITEM_CLASS:New{
	name = "Вода",
	class = "spawned_food",
	model = "models/props_junk/GlassBottle01a.mdl",
	price = 15,
	category = "Продукты",
	data = {FoodEnergy = 20, StaminaEnergy = 65},
	license = "food",
	allowed = {TEAM_TRADER, TEAM_COOK},
	description = "Обыкновенная пища\nВосстановление голода: 20.\nВосстановление выносливости: 65.",
}:Register();

local ITEM = CSHOP_ITEM_CLASS:New{
	name = "Сода",
	class = "spawned_food",
	model = "models/props_junk/PopCan01a.mdl",
	price = 10,
	category = "Продукты",
	data = {FoodEnergy = 5, StaminaEnergy = 35},
	license = "food",
	allowed = {TEAM_TRADER, TEAM_COOK},
	description = "Обыкновеная пища\nВосстановление голода: 5.\nВосстановление выносливости: 35.",
}:Register();

local ITEM = CSHOP_ITEM_CLASS:New{
	name = "Молоко",
	class = "spawned_food",
	model = "models/props_junk/garbage_milkcarton002a.mdl",
	price = 40,
	category = "Продукты",
	data = {FoodEnergy = 35},
	license = "food",
	allowed = {TEAM_TRADER, TEAM_COOK},
	description = "Обыкновенная пища\nВосстановление голода: 35.",
}:Register();

local ITEM = CSHOP_ITEM_CLASS:New{
	name = "Апельсин",
	class = "spawned_food",
	model = "models/props/cs_italy/orange.mdl",
	price = 15,
	category = "Продукты",
	data = {FoodEnergy = 15},
	license = "food",
	allowed = {TEAM_TRADER, TEAM_COOK},
	description = "Обыкновенная пища\nВосстановление голода: 15.",
}:Register();

local ITEM = CSHOP_ITEM_CLASS:New{
	name = "Бургер",
	class = "spawned_food",
	model = "models/food/burger.mdl",
	price = 35,
	category = "Продукты",
	data = {FoodEnergy = 60},
	license = "food",
	allowed = {TEAM_TRADER, TEAM_COOK},
	description = "Обыкновенная пища\nВосстановление голода: 60.",
}:Register();

local ITEM = CSHOP_ITEM_CLASS:New{
	name = "Хот-Дог",
	class = "spawned_food",
	model = "models/food/hotdog.mdl",
	price = 45,
	category = "Продукты",
	data = {FoodEnergy = 65},
	license = "food",
	allowed = {TEAM_TRADER, TEAM_COOK},
	description = "Обыкновенная пища\nВосстановление голода: 65.\n\nP.S. В честь великого игрока, шестерки и ручной зверины.",
}:Register();