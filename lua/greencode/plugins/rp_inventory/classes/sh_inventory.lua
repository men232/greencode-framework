--[[
	© 2013 gmodlive.com commissioned by Leonid Sahnov
	private source
--]]

local greenCode = greenCode;
local gc        = gc;
local table     = table;
local pairs     = pairs;

local entityMeta = FindMetaTable("Entity");
local rp_inventory = greenCode.plugin:FindByID("rp_inventory");

--[[ Define the inventory inventory class metatable. --]]
INVENTORY_CLASS = greenCode.kernel:CreateBasicClass();

function INVENTORY_CLASS:New( tMergeTable )
	local object = { 
		data = {
			uid = -1,
			className = "InventoryClass",
			items = {},
			owner = Entity(0),
			weight = 0,
		},
	};

	if ( tMergeTable ) then
		table.Merge( object.data, tMergeTable );
	end;

	setmetatable( object, self );
	self.__index = self;

	return object;
end;

-- A function to serialize items
function INVENTORY_CLASS:Serialize()
	return greenCode.kernel:Serialize( self.data.items )
end;

-- A function to deserialize items
function INVENTORY_CLASS:Deserialize( sData )
	self.data.items = greenCode.kernel:Deserialize( sData );
	self:CalculateWeight();
end;

-- A function to add item
function INVENTORY_CLASS:AddItem( uid, count, tUserData )
	local ITEM = self:GetPlugin():FindByID( uid );
	local count = tonumber(count) or 1;

	if ( not ITEM ) then
		return false, "Item not exists.";
	end;

	if ( ITEM:IsStackable() ) then
		local current = tonumber(self.data.items[uid]) or 0;
		self.data.items[uid] = current + count;
	else
		local tItems = type(self.data.items[uid]) != "table" and {} or self.data.items[uid];
		
		for i=1, count do
			local index = gc.kernel:GetShortCRC(uid.."_"..i.."_"..CurTime());
			tItems[index] = tUserData or {};
		end;

		self.data.items[uid] = tItems;
	end;

	gc.plugin:Call("OnInventoryAddItem", self, ITEM, count, tUserData);
	self:CalculateWeight();

	return count;
end;

-- A function to remove item
function INVENTORY_CLASS:RemoveItem( uid, count )
	local count = tonumber(count) or 1;
	local index, tUserData;

	if (!self.data.items[uid]) then
		return false, "Item not exists.";
	elseif (type(self.data.items[uid]) == "table") then
		index = count;
		count = 1;

		if (!index or !self.data.items[uid][index]) then
			return false, "Incorrect index.";
		end;

		tUserData = table.Copy(self.data.items[uid][index]);
		self.data.items[uid][index] = nil;

		if (table.Count(self.data.items[uid]) == 0) then
			self.data.items[uid] = nil;
		end;
	else
		local a = self.data.items[uid];
		self.data.items[uid] = math.Max(self.data.items[uid] - count, 0);
		count = a - self.data.items[uid];

		if (self.data.items[uid] == 0) then
			self.data.items[uid] = nil;
		end;
	end;

	gc.plugin:Call("OnInventoryRemoveItem", self, uid, count, tUserData);
	self:CalculateWeight();

	return count, tUserData;
end;

-- A function to use item from inventory
function INVENTORY_CLASS:UseItem(uid, count)
	return self:DropItem(uid, count, true);
end;

-- A function to drop item from inventory
function INVENTORY_CLASS:DropItem(uid, count, bUse)
	if (!self:IsExist(uid, count)) then
		return false, "Item not exists.";
	end;

	local item = self:GetPlugin().buffer[uid];
	local owner = self("owner");
	local bSuccess, sReason = item:OnDrop(owner);

	if (bSuccess != false) then
		bSuccess, sReason = gc.plugin:Call("OnInventoryDropItem", self, item);
	end;

	if (bSuccess == false and sReason and owner:IsPlayer()) then
		return owner:ShowHint(tostring(sReason), 5, Color(255,100,100), nil, true)
	end;

	local nRemoved, bReason = self:RemoveItem(uid, count);
	local position;
	local sClass = item:GetClass();

	if (!nRemoved) then
		return false, bReason;
	end;

	for i=1, nRemoved do
		timer.Simple(0.2 * i, function()
			local ent = self:GetPlugin():SpawnItem( owner, item );
			if (bUse && ent.Use && IsValid(owner)) then
				ent:Use(owner, owner, USE_ON, USE_ON);
			end;
		end)
	end;

	return nRemoved;
end;

-- A function to check item exsisting
function INVENTORY_CLASS:IsExist(uid, index)
	local item = self:GetPlugin().buffer[uid];
	local bStackable = item and item:IsStackable();

	if (!item or (!bStackable and !index)) then
		return false;
	elseif (!bStackable and self.data.items[uid]) then
		return self.data.items[uid][index] != nil;
	end;

	return self.data.items[uid] and self.data.items[uid] > 0;
end;

-- A function to get items count
function INVENTORY_CLASS:GetItemsCount(uid)
	local items = self.data.items[uid];
	if (!items) then return 0 end;

	if (type(items) == "table") then
		return table.Count(items);
	end;

	return tonumber(items);
end;

-- A function to calculate weight
function INVENTORY_CLASS:CalculateWeight()
	local weight = 0;
	local plugin_buffer = self:GetPlugin().buffer;

	for k,v in pairs(self.data.items) do
		local item = plugin_buffer[k];
		if (!item) then continue end;

		local count = type(v) == "table" and table.Count(v) or v;
		weight = weight + (item:GetWeight() * count);
	end;

	self.data.weight = weight;
	return weight;
end;

-- A function to clean inventory
function INVENTORY_CLASS:Clean()
	self.data.items = {};
	self.data.weight = 0;
	gc.plugin:Call("OnInventoryClean", self);
end;

-- A function to set inventory owner
function INVENTORY_CLASS:SetOwner( entity )
	entity.gc_inventory = self;
	self.data.owner = entity;
end;

-- A function to set inventory researcher
function INVENTORY_CLASS:SetResearcher( researcher )
	local owner = self:GetOwner();
	gc.entity:SetSharedVar( owner, {InvR = researcher:EntIndex()}, nil, false );
end;

-- A function to validate researcher player
function INVENTORY_CLASS:ValidateResearcher( researcher )
	local owner = self:GetOwner();
	local nMaxDist = gc.config:Get("inv_research_dist"):Get(150);
	return IsValid(researcher) and researcher:GetPos():Distance(owner:GetPos()) < nMaxDist;
end;

-- Get Methods
function INVENTORY_CLASS:GetOwner() return self.data.owner end;
function INVENTORY_CLASS:GetItems() return self.data.items end;
function INVENTORY_CLASS:UniqueID() return self.data.uid end;
function INVENTORY_CLASS:GetPlugin() return rp_inventory end;
function INVENTORY_CLASS:GetWeight() return self.data.weight end;
function INVENTORY_CLASS:IsEmpty() return self:CalculateWeight() == 0 end;
function INVENTORY_CLASS:GetResearcher()
	local owner = self:GetOwner();
	return IsValid(owner) and Entity(owner:GetSharedVar("InvR", -1));
end;