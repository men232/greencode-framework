--[[
	© 2013 gmodlive.com commissioned by Leonid Sahnov
	private source
--]]

local greenCode = greenCode;
local table     = table;
local pairs     = pairs;
local PLUGIN    = greenCode.plugin:FindByID("rp_inventory");
local cBGColor  = Color(0,0,0);

--[[ Define the inventory item class metatable. --]]
INV_ITEM_CLASS = greenCode.kernel:CreateBasicClass()

function INV_ITEM_CLASS:New( tMergeTable )
	local object = { 
		data = {
			uid = -1,
			className = "InvItemClass",
			weight = 5,
			model = "",
			class = "prop_physics",
			category = "",
			description = "Unknown item",
			stackable = true,
			color = cBGColor,
		},
	};

	if ( tMergeTable ) then
		table.Merge( object.data, tMergeTable );
	end;

	setmetatable( object, self );
	self.__index = self;

	return object;
end;

function INV_ITEM_CLASS:__tostring()
	return "InvItemClass ["..self("uid").."]["..self("name").."]["..self("class").."]";
end;

-- Get Methods
function INV_ITEM_CLASS:UniqueID() return self( "uid", -1 ); end;
function INV_ITEM_CLASS:GetName() return self( "name", "UnknownItem" ); end;
function INV_ITEM_CLASS:GetModel() return self( "model", "models/props_junk/watermelon01.mdl" ); end;
function INV_ITEM_CLASS:GetPlugin() return PLUGIN; end;
function INV_ITEM_CLASS:Register() return self:GetPlugin():RegisterItem( self ); end;
function INV_ITEM_CLASS:IsStackable() return self("stackable", true) end;
function INV_ITEM_CLASS:GetDescription() return self("description", "Unknown item") end;
function INV_ITEM_CLASS:GetWeight() return self("weight", 5) end;
function INV_ITEM_CLASS:GetClass() return self("class", "prop_physics") end;
function INV_ITEM_CLASS:GetColor() return self("color", cBGColor) end;
function INV_ITEM_CLASS:Compliance(entity) return false; end;

-- Event Methods
function INV_ITEM_CLASS:OnPickup( entity, player ) end;
function INV_ITEM_CLASS:OnDrop( owner ) end;