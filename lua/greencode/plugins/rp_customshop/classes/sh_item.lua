local greenCode = greenCode;
local table     = table;
local pairs     = pairs;

--[[ Define the custom shop class metatable. --]]
CSHOP_ITEM_CLASS = greenCode.kernel:CreateBasicClass()

function CSHOP_ITEM_CLASS:GetPrice()
	local price = self("price", 0);
	local customPrice = greenCode.plugin:Call( "GetPrice", self("price", 0) );

	return customPrice or price;
end;

function CSHOP_ITEM_CLASS:GetName() return self( "name", "UnknownItem" ); end;
function CSHOP_ITEM_CLASS:Name() return self:GetName(); end;
function CSHOP_ITEM_CLASS:GetModel() return self( "model", "" ); end;
function CSHOP_ITEM_CLASS:GetMax() return self( "max", 0 ); end;
function CSHOP_ITEM_CLASS:GetClass() return self( "class", "spawned_weapon" ); end;
function CSHOP_ITEM_CLASS:GetCategory() return self( "category", "Основное" ); end;
function CSHOP_ITEM_CLASS:UniqueID() return self( "uid", -1 ); end;
function CSHOP_ITEM_CLASS:Register() return greenCode.plugin:FindByID("rp_customshop"):RegisterItem( self ); end;

function CSHOP_ITEM_CLASS:New( tMergeTable )
	local object = { 
		data = {
			uid = -1,
			className = "CShopItem",
			price = 0,
			max = 0,
			name = "UnknownItem",
			class = "spawned_weapon",
			model = "",
			category = "Основное",
			description = ""
		},
	};

	if ( tMergeTable ) then
		table.Merge( object.data, tMergeTable );
	end;

	setmetatable( object, self );
	self.__index = self;

	return object;
end;