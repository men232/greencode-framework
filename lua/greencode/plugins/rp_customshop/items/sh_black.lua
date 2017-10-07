local ITEM = CSHOP_ITEM_CLASS:New{ name = "Наркостанция (Drug Lab)",
	class = "drug_lab",
	model = "models/props_lab/crematorcase.mdl",
	price = 450,
	category = "Черный рынок",
	max = 3,
	description = [[Этому городу не помешает немного веселья.
	Владеть этим незаконно!]],
	allowed = {TEAM_GANG, TEAM_MOB},
	location = "^",
}:Register();

local ITEM = CSHOP_ITEM_CLASS:New{ name = "Money printer",
	class = "money_printer",
	model = "models/props_c17/consolebox01a.mdl",
	price = 1000,
	category = "Черный рынок",
	description = [[Владеть этим незаконно!]],
	max = 2,
	allowed = { TEAM_TRADER, TEAM_CITIZEN, TEAM_SPY, TEAM_BIS, TEAM_MEDIC, TEAM_COOK, TEAM_THIEF, TEAM_GANG, TEAM_MOB},
	location = "^",
}:Register();

local ITEM = CSHOP_ITEM_CLASS:New{ name = "Keypad Cracker",
	class = "keypad_cracker",
	model = "models/weapons/w_c4.mdl",
	price = 1000,
	category = "Черный рынок",
	description = [[Инструмент для взлома цифровых замков.]],
	allowed = { TEAM_THIEF },
	location = "^",
}:Register();

/*local ITEM = CSHOP_ITEM_CLASS:New{ name = "Normal Printer",
	class = "money_normal_printer",
	model = "models/props_lab/reciever01a.mdl",
	price = 1999,
	category = "Черный рынок",
	description = [[Владеть этим незаконно!]],
	max = 2
}:Register();

local ITEM = CSHOP_ITEM_CLASS:New{ name = "Coal Money Printer",
	class = "money_coal_printer",
	model = "models/props_lab/reciever01a.mdl",
	price = 4999,
	category = "Черный рынок",
	description = [[Владеть этим незаконно!]],
	max = 2
}:Register();

local ITEM = CSHOP_ITEM_CLASS:New{ name = "Ruby Money Printer",
	class = "money_ruby_printer",
	model = "models/props_lab/reciever01a.mdl",
	price = 9999,
	category = "Черный рынок",
	description = [[Владеть этим незаконно!]],
	max = 2
}:Register();

local ITEM = CSHOP_ITEM_CLASS:New{ name = "Sapphire Money Printer",
	class = "money_sapphire_printer",
	model = "models/props_lab/reciever01a.mdl",
	price = 24999,
	category = "Черный рынок",
	description = [[Владеть этим незаконно!]],
	max = 2
}:Register();

local ITEM = CSHOP_ITEM_CLASS:New{ name = "Coolant Cell",
	class = "coolant_cell",
	model = "models/items/battery.mdl",
	price = 999,
	category = "Черный рынок",
	description = [[Владеть этим незаконно!]],
	max = 2
}:Register();*/