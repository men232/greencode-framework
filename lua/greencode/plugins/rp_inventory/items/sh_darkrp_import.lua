-- DarkRP Entities
for _, v in pairs(DarkRPEntities or {}) do
	local ITEM = INV_ITEM_CLASS:New{
		name = v.name,
		class = v.ent,
		model = v.model,
		description = v.name,
		stackable = v.stackable or false,
		weight = v.weight or 5,
		allow_drop = v.allow_drop,
	}:Register();
end;

-- Custom Shipments
for _, v in pairs(CustomShipments or {}) do
	local ITEM = INV_ITEM_CLASS:New{
		name = v.name,
		class = "spawned_weapon",
		model = v.model,
		description = v.name,
		stackable = v.stackable or false,
		weight = v.weight or 10,
		data = {weaponclass = v.entity, ammoadd = 0},
		allow_drop = v.allow_drop,
	}

	function ITEM:Compliance( entity )
		return self("data").weaponclass == entity.weaponclass;
	end;

	ITEM:Register();
end;

-- Food Items
for name, v in pairs(FoodItems or {}) do
	local ITEM = INV_ITEM_CLASS:New{
		name = name,
		class = v.entity,
		model = v.model,
		description = name,
		stackable = true,
		weight = 2,
		data = {FoodEnergy = v.amount or 10},
		allow_drop = v.allow_drop,
	};

	function ITEM:Compliance( entity )
		return self("model") == entity:GetModel();
	end;
	
	ITEM:Register();
end;

-- Drink botle
local WATER_BOTTLE = INV_ITEM_CLASS:New{
	name = "Water Bottle",
	class = "spawned_food",
	model = "models/props/cs_office/water_bottle.mdl",
	description = "Drink could water...",
	stackable = true,
	weight = 2,
	data = {FoodEnergy = 7, StaminaEnergy = 50}
};

function WATER_BOTTLE:Compliance( entity )
	return self("model") == entity:GetModel();
end;

WATER_BOTTLE:Register();