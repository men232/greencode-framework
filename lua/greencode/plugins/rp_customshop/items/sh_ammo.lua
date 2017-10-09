local ITEM = CSHOP_ITEM_CLASS:New{
	class = "ent_mad_ammo_9mm",
	model = "models/Items/BoxSRounds.mdl",
	price = 300,
	category = "Патроны",
	license = "weapon",
	allowed = {TEAM_TRADER},
	description = "Паторны.",
	location = "^",
}:Register();

local ITEM = CSHOP_ITEM_CLASS:New{
	class = "ent_mad_ammo_45",
	model = "models/Items/BoxSRounds.mdl",
	price = 350,
	category = "Патроны",
	license = "weapon",
	allowed = {TEAM_TRADER},
	description = "Паторны.",
	location = "^",
}:Register();

local ITEM = CSHOP_ITEM_CLASS:New{
	class = "ent_mad_ammo_46mm",
	model = "models/Items/BoxSRounds.mdl",
	price = 450,
	category = "Патроны",
	license = "weapon",
	allowed = {TEAM_TRADER},
	description = "Паторны.",
	location = "^",
}:Register();

local ITEM = CSHOP_ITEM_CLASS:New{
	class = "ent_mad_ammo_50",
	model = "models/Items/BoxSRounds.mdl",
	price = 450,
	category = "Патроны",
	license = "weapon",
	allowed = {TEAM_TRADER},
	description = "Паторны.",
	location = "^",
}:Register();

local ITEM = CSHOP_ITEM_CLASS:New{
	class = "ent_mad_ammo_57mm",
	model = "models/Items/BoxSRounds.mdl",
	price = 550,
	category = "Патроны",
	license = "weapon",
	allowed = {TEAM_TRADER},
	description = "Паторны.",
	location = "^",
}:Register();

local ITEM = CSHOP_ITEM_CLASS:New{
	class = "ent_mad_ammo_357",
	model = "models/Items/357ammo.mdl",
	price = 550,
	category = "Патроны",
	license = "weapon",
	allowed = {TEAM_TRADER},
	description = "Паторны.",
	location = "^",
}:Register();

local ITEM = CSHOP_ITEM_CLASS:New{
	class = "ent_mad_ammo_556mm",
	model = "models/Items/BoxMRounds.mdl",
	price = 620,
	category = "Патроны",
	license = "weapon",
	allowed = {TEAM_TRADER},
	description = "Паторны.",
	location = "^",
}:Register();

local ITEM = CSHOP_ITEM_CLASS:New{
	class = "ent_mad_ammo_762mm",
	model = "models/Items/BoxMRounds.mdl",
	price = 720,
	category = "Патроны",
	license = "weapon",
	allowed = {TEAM_TRADER},
	description = "Паторны.",
	location = "^",
}:Register();

for k, v in pairs(CSHOP_PLUGIN.stored) do
	if ( v.data.category == "Патроны" ) then
		local ITEM = CSHOP_ITEM_CLASS:New{
			name = v.data.name.." - CP",
			class = v.data.class,
			model = v.data.model,
			price = math.ceil(v.data.price/4),
			category = v.data.category.." - CP",
			license = v.data.license,
			allowed = {TEAM_POLICE, TEAM_CHIEF, TEAM_SWAT, TEAM_MAYOR},
			description = v.data.description,
			location = 2129,
		}:Register();
	end;
end;

-- CP Weapons.
local ITEM = CSHOP_ITEM_CLASS:New{
	class = "spawned_weapon",
	data = {ammoadd = 0, weaponclass = "weapon_mad_deagle"},
	price = 1200,
	category = "Пистолеты",
	allowed = {TEAM_MAYOR},
	description = "Мелкокалиберное оружие.",
	location = 2129,
}:Register();
-- end