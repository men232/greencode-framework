--[[
	© 2013 gmodlive.com commissioned by Leonid Sahnov
	private source
--]]

local PLUGIN = PLUGIN or greenCode.plugin:Loader();
PLUGIN.stored = {};
PLUGIN.buffer = {};

local greenCode = greenCode;
local gc = gc;
local tonumber = tonumber;
local IsValid = IsValid;
local pairs = pairs;
local string = string;
local table = table;

local entityMeta = FindMetaTable("Entity");

ENUM_INV_CMD_OPEN = 1;
ENUM_INV_CMD_CLOSE = 2;
ENUM_INV_CMD_RESEARCH = 3;

-- A function called when plugin is initialized
function PLUGIN:Initialized()
	local debugMsg = "InvItem Registred:\n";
	for i=1, #self.stored do
		debugMsg = debugMsg.."\t\t"..tostring(self.stored[i]).."\n";
	end;

	gc:Debug(debugMsg);
end;

if SERVER then
	function PLUGIN:PlayerCharacterInitialized( player )
		local items = player:GetCharacterData("_inv");
		local inventory = player:CreateInventory();

		if (!items) then
			player:SetCharacterData("_inv", inventory:Serialize());
		else
			inventory:Deserialize(items);
		end;

		-- TO DOO: Validation
		-- player:SetPrivateVar{_inv = inventory};
		gc.plugin:Call("OnPlayerInventoryLoaded", player, inventory);
	end;

	-- Called when player inventory loaded
	function PLUGIN:OnPlayerInventoryLoaded( player, inventory )
		self:Sync(inventory);
		gc.hint:Send( player, "Ваш инвентарь был загружен.", 5, Color(100,255,100), nil, true );
	end;

	-- Called when inventory created
	function PLUGIN:OnInventoryCreate( inventory, entity )
		gc.datastream:Start( !entity:IsPlayer() or entity, "gcInvCreate", {i = entity:EntIndex()});
	end;

	-- Called when inventory removed
	function PLUGIN:OnInventoryRemove( inventory, entity )
		gc.datastream:Start( !entity:IsPlayer() or entity, "gcInvRemove", {i = entity:EntIndex()});
	end;

	-- Called when player death.
	function PLUGIN:PlayerDeath( player )
		local inventory = player:GetInventory();

		if (not gc.config:Get("inv_death_drop"):Get(true) or
			not inventory or
			inventory:IsEmpty()) then
			return;
		end;

		local pos = player:GetShootPos();
		local ent = self:SpawnInventory(inventory);
		ent:SetAngles(player:GetAngles());
		--ent:SetTitle(player:GetName());
		ent.RemoveIsEmpty = true;

		self:Sync(inventory);
		self:Sync(ent:GetInventory());
	end;

	function PLUGIN:EntityRemoved( ent )
		if (not ent.gc_inventory) then
			return;
		end;

		local inventory = ent:GetInventory();

		if (inventory:IsEmpty()) then
			return;
		end;

		local inv = PLUGIN:SpawnInventory(inventory, ent:GetPos());
		inv.RemoveIsEmpty = true;
	end;

	-- A function to spawn inventory
	function PLUGIN:SpawnInventory( inventory, position )
		local owner = inventory:GetOwner();
		local pos = position or owner:IsPlayer() and owner:GetShootPos() or owner:GetPos();
		local ent = ents.Create("prop_physics");
		
		ent:SetModel("models/props_c17/BriefCase001a.mdl");
		ent:SetPos(pos);
		ent:Spawn();
		ent:Activate();
		ent:CreateInventory();

		ent:GetInventory():SetData("items", inventory:GetItems());
		inventory:SetData("items", {});

		self:Sync(inventory);
		self:Sync(ent:GetInventory());

		return ent;
	end;


	-- Called when inventory item adds
	function PLUGIN:OnInventoryAddItem( inventory, item, count, tUserData )
		local owner = inventory:GetOwner();
		local bIsPlayer = owner:IsPlayer();

		if (bIsPlayer) then
			owner:SetCharacterData("_inv", inventory:Serialize());
			owner:SaveCharacter();

			greenCode.hint:Send( owner, "Добавлено в инвентарь: "..item("name").." x"..count, 5, Color(100,255,100), nil, true );
			gc.plugin:Call("OnPlayerInventoryAddItem", inventory, item, count, tUserData);
		end;

		-- Send data to client
		self:Sync( inventory );
	end;

	-- Called when inventory has been cleaned
	function PLUGIN:OnInventoryClean( inventory )
		local owner = inventory:GetOwner();
		self:Sync(inventory);

		if (owner:IsPlayer()) then
			greenCode.hint:Send( owner, "Ваш инвентарь был обнулен.", 5, Color(255,100,255), nil, true );
		end;
	end;

	-- A function to sync inventory between server and client
	function PLUGIN:Sync( inventory, player, tUserData )
		local owner = inventory:GetOwner();
		local bIsPlayer = owner:IsPlayer();
		local tPlayers = {};

		if (!player and !bIsPlayer) then
			for k,v in pairs(_player.GetAll()) do
				local nDistance = v:GetShootPos():Distance(owner:GetPos());

				if (nDistance < gc.config:Get("inv_sync_dist"):Get(300)) then
					table.insert(tPlayers, v);
				end;
			end;
		elseif (player) then
			bIsPlayer = false;
			table.insert(tPlayers, player);
		end;

		greenCode.datastream:Start( bIsPlayer and owner or tPlayers, "gcInvUpdate", {
			data = inventory:Serialize(),
			index = owner:EntIndex(),
			userdata = tUserData,
		});
	end;

	-- A function to spawn entity based of item information
	function PLUGIN:SpawnItem( owner, item )
		-- Calculate position
		if (owner:IsPlayer() or owner:IsNPC()) then
			local trace = {};

			trace.start = owner:EyePos();
			trace.endpos = trace.start + owner:GetAimVector() * 85;
			trace.filter = owner;
			local tr = util.TraceLine(trace);

			position = gc.player:GetSafePosition(owner, tr.HitPos - Vector(0, 0, 32));
		else
			local trace = {};

			trace.start = owner:GetPos();
			trace.endpos = trace.start + Vector(0, 0, owner:OBBMaxs() + owner:OBBMins() + 15);
			trace.filter = owner;
			local tr = util.TraceLine(trace);

			position = tr.HitPos;
		end;

		local tUserData = item("data", {});
		local amountGiven = tUserData.amountGiven;
		local ammoType = tUserData.ammoType;
		local sClass = item:GetClass();

		-- Spawn entity
		local ent = ents.Create(sClass);
		ent.onlyremover = true;
		ent.dt = ent.dt or {};
		
		-- Set owner
		if (owner and owner:IsPlayer()) then
			ent.dt.owning_ent = owner;
			if ent.Setowning_ent then ent:Setowning_ent(owner) end;
			ent.SID = owner.SID;
		end;

		ent:SetPos(position or tr.HitPos);
		ent:SetModel(item:GetModel());

		-- Apply user data.
		for k, v in pairs(tUserData) do
			ent[k] = v;
		end;

		-- Ammo darkrp fixing
		if (amountGiven && ammoType) then
			function ent:Use( player, ... )
				player:GiveAmmo( amountGiven, ammoType );
				self:Remove();
				return true;
			end;
		end;

		ent:Spawn();
		ent:Activate();

		-- Fixing limit
		if (owner) then
			if (!owner["max"..sClass]) then
				owner["max"..sClass] = 0;
			end;

			owner["max"..sClass] = owner["max"..sClass] + 1;
		end;

		return ent;
	end;

	-- Called when from inventory drop item
	function PLUGIN:OnInventoryDropItem( inventory, item )
		local owner = inventory:GetOwner();
		if (!owner:IsPlayer()) then return end;

		local team = owner:Team();
		local tAllowed = item.data.allow_drop;

		if ( owner:isArrested() ) then
			return false, "Вы не доставать вещи пока сидите в тюрьме.";
		end;

		if (tAllowed and (type(tAllowed) == "table" and !table.HasValue(tAllowed, team) or tAllowed != team)) then
			return false, "Не доступно для вашей професии.";
		end;
	end;

	-- Called when inventory item remove
	function PLUGIN:OnInventoryRemoveItem( inventory, uid, count, tUserData )
		local item = self.buffer[uid];
		local owner = inventory:GetOwner();
		local bIsPlayer = owner:IsPlayer();

		if (item and bIsPlayer) then
			owner:SetCharacterData("_inv", inventory:Serialize());
			owner:SaveCharacter();

			greenCode.hint:Send( owner, "Удалено из инвентаря: "..item("name").." x"..count, 5, Color(255,100,100), nil, true );
			gc.plugin:Call("OnPlayerInventoryRemoveItem", inventory, item, count, tUserData);
		end;

		if (inventory:IsEmpty() and !bIsPlayer and owner.RemoveIsEmpty) then
			owner:Remove();
		end;

		-- Send data to client
		self:Sync( inventory );
	end;

	-- Called when player put item to inventory
	function PLUGIN:OnPlayerInventoryPutItem( player, rm_inventory, item )
		local pl_inventory = player:GetInventory();
		local nOwerload = self:CalcOverloadLevel(pl_inventory, true);
		local rm_owner = rm_inventory:GetOwner();
		local rm_phys = rm_owner:GetPhysicsObject();
		local itemW = item:GetWeight();

		if (pl_inventory:UniqueID() == rm_inventory:UniqueID()
			and nOwerload > 1.85) then
				return false, "Не лезет.";
		elseif (IsValid(rm_phys)
			and rm_owner:GetClass() == "prop_physics"
			and (rm_inventory:CalculateWeight() + itemW) > (rm_phys:GetMass() * 0.25)) then
				return false, "Не лезет в это.";
		end;
	end;

	hook.Add( "PlayerUse", "gc_inv_ply_use", function( player, entity )
		return PLUGIN:PlayerUse( player, entity );
	end)

	-- Prop inventory avilible
	function PLUGIN:KeyPress( player, key )
		if (key == IN_USE and player:KeyDown(IN_SPEED)) then
			local tr = player:GetEyeTrace();
			local entity = tr.Entity;

			if (!IsValid(entity) or entity:GetClass() != "prop_physics") then
				return;
			end;

			if (player:GetPos():Distance(entity:GetPos()) > 150) then
				return false;
			end;

			self:PlayerUse( player, entity );
		end;
	end;

	-- Called when player user some entity
	function PLUGIN:PlayerUse( player, entity )
		if not player:KeyDown(IN_SPEED) then
			return;
		end;

		local curTime = CurTime();
		local pl_inventory = player:GetInventory();
		local rm_inventory = entity:GetInventory();

		if (not pl_inventory) then
			player:ShowHint("У вас нет инвентаря.", 5, Color(255,100,100), nil, true)
			player.gcLastPickUp = curTime;
			return false;
		end;

		player.gcLastPickUp = player.gcLastPickUp or 0;

		if (curTime - player.gcLastPickUp < gc.config:Get("inv_pickup_interval"):Get(0.4)) then
			return false;
		end;

		if (not rm_inventory) then
			print("pick");
			self:PlayerPickUp( player, entity );
			player.gcLastPickUp = curTime;
		else
			self:PlayerResearchInventory(player, rm_inventory);
			player.gcLastPickUp = curTime + 2;
		end;

		return false;
	end;

	-- Called when player pick uping item
	function PLUGIN:OnPlayerItemPickUp( player, item, entity )
		if (entity:IsOnFire()) then
			if (gc.config:Get("inv_fire_dmg"):Get(true) and IsValid(player)) then
				local dmginfo = DamageInfo()
				dmginfo:SetDamage( 1 );
				dmginfo:SetDamageType( DMG_BURN );
				dmginfo:SetDamageForce( player:GetPos() - entity:GetPos() );
				dmginfo:SetAttacker( player );
				player:TakeDamageInfo( dmginfo );
			end;

			return false, "АЙ. Горячо!";
		end;

		local owner = entity.Getowning_ent and entity:Getowning_ent() or nil;
		local nOwerload = self:CalcOverloadLevel(player:GetInventory());

		if (nOwerload > 1.85) then
			return false, "Не лезет.";
		elseif (IsValid(owner) and player != owner) then
			local nStealDisntance = gc.config:Get("inv_steal_dist"):Get(1200);

			if (owner:GetPos():Distance(entity:GetPos()) < nStealDisntance) then
				return false, "Это не ваша вешь. Владелец где-то рядом...";
			end;
		end;
	end;

	-- A function to open inventory by player
	function PLUGIN:PlayerResearchInventory( player, rm_inventory )
		local rm_owner = rm_inventory:GetOwner();
		if (!IsValid(rm_owner)) then return end;

		local researcher = rm_inventory:GetResearcher();
		local bOneResearch = gc.config:Get("inv_one_research"):Get(false);

		if (bOneResearch and player != researcher and IsValid(researcher)
			and rm_inventory:ValidateResearcher(researcher)) then
				return false, "Этот инвентарь уже иследуют.";
		elseif (not rm_inventory:ValidateResearcher(player)) then
			return false, "Вы склишком далеко.";
		end;

		rm_inventory:SetResearcher(player);
		self:Sync(rm_inventory, player, ENUM_INV_CMD_RESEARCH);
	end;

	-- A function to player pick up item
	function PLUGIN:PlayerPickUp( player, entity )
		local inventory = player:GetInventory();

		if (not inventory) then
			return false;
		end;

		local class = entity:GetClass();
		local model = entity:GetModel();
		local result = self:FindByClass(class);
		local bFinded = false;

		if (#result == 1) then
			result = result[1];
			bFinded = true;
		else
			for i=1, #result do
				if (result[i]:Compliance(entity)) then
					result = result[i];
					bFinded = true;
					break;
				end;
			end;
		end;

		print(player, "attempt to pick up", class, "allow =", bFinded);

		if (!bFinded) then
			player:ShowHint("Невозможно поместить в инвентарь.", 5, Color(255,100,100), nil, true)
			return;
		end;

		local bSuccess, sReason = result:OnPickup( entity, player );

		if (bSuccess == false) then
			if (sReason) then
				player:ShowHint(tostring(sReason), 5, Color(255,100,100), nil, true);
			end;

			return;
		end;

		bSuccess, sReason = gc.plugin:Call("OnPlayerItemPickUp", player, result, entity);

		if (bSuccess == false) then
			if (sReason) then
				player:ShowHint(tostring(sReason), 5, Color(255,100,100), nil, true);
			end;

			return;
		end;

		if ( player:GetInventory():AddItem(result:UniqueID(), 1) == 1 ) then
			player:EmitSound("items/ammo_pickup.wav");
			entity:Remove();
		end;

		return true;
	end;

	-- A function to create inventory on entity
	function entityMeta:CreateInventory()
		local uid = self:IsPlayer() and self:UniqueID() or self:EntIndex();
		local inventory = INVENTORY_CLASS:New({uid = uid});
		inventory:SetOwner(self);

		gc.plugin:Call("OnInventoryCreate", self.gc_inventory, self);
		return self.gc_inventory;
	end;

	-- A function to remove inventory
	function entityMeta:RemoveInventory()
		if (not self.gc_inventory) then
			return true;
		end;

		gc.plugin:Call("OnInventoryRemove", self.gc_inventory, self);
		self.gc_inventory = nil;

		return true;
	end;

	-- A function to clean inventory on entity
	function entityMeta:CleanInventory() self.gc_inventory:Clean(); end;

else
	-- Local create inveitory function
	local function CreateInventory(entity)
		local uid = entity:IsPlayer() and entity:UniqueID() or entity:EntIndex();
		local inventory = INVENTORY_CLASS:New({uid = uid});
		inventory:SetOwner(entity);

		gc.plugin:Call("OnInventoryCreate", entity.gc_inventory, entity);
		return entity.gc_inventory;
	end;

	greenCode.datastream:Hook("gcInvUpdate", function( tData )
		local entity = Entity(tData.index);
		local userdata = tData.userdata;

		if (!IsValid(entity)) then
			return;
		end;

		local inventory = entity:GetInventory();

		if (!inventory) then
			inventory = CreateInventory(entity);
		end;

		inventory:Deserialize( tData.data );
		inventory:CalculateWeight();

		gc:Debug("Update iventory: "..tostring(entity).." = "..tData.data);

		-- CMD
		if (userdata == ENUM_INV_CMD_RESEARCH) then
			gc.Client.gcInventoryResearch = inventory;
			RunConsoleCommand("cl_gc_custommenu_open", 4667, 0);
		end;
	end);

	greenCode.datastream:Hook("gcInvCreate", function( tData )
		local entity = Entity(tData.i);

		if (!IsValid(entity)) then
			return;
		end;

		CreateInventory(entity);
		gc:Debug("Create iventory: "..tostring(entity));
	end);

	greenCode.datastream:Hook("gcInvRemove", function( tData )
		local entity = Entity(tData.i);

		if (!IsValid(entity) or !entity.gc_inventory) then
			return;
		end;

		gc.plugin:Call("OnInventoryRemove", entity.gc_inventory, entity);
		entity.gc_inventory = nil;
		gc:Debug("Remove iventory: "..tostring(entity));
	end);
end;

-- A function to calc overload level
function PLUGIN:CalcOverloadLevel( inventory, bCalcWeight )
	local owner = inventory:GetOwner();
	if (!owner:IsPlayer()) then return 0; end;

	local attrName = "str";
	local minWeight = gc.config:Get("inv_min_weight"):Get(15);
	local maxWeight = gc.config:Get("inv_max_weight"):Get(150);
	local attributeTable = gc.attribute:FindByID(attrName);
	local coeficient = (maxWeight) / attributeTable.maximum;
	local attribute = 1;
	local curWeight = (bCalcWeight and inventory:CalculateWeight() or inventory:GetWeight());

	if (SERVER) then
		attribute = gc.attributes:Get(owner, attrName, false);
	else
		attribute = gc.attributes:Get(attrName, false);
	end;

	local sCfgName = "inv_factor_"..string.lower(owner:GetUserGroup());
	local allowWeight = minWeight + (coeficient * math.Max(attribute, 1));

	return math.Clamp(gc.config:Get(sCfgName):Get(1.0) * (curWeight / allowWeight), 0.0, 2.0), curWeight;
end;

-- A function to register inventory item
function PLUGIN:RegisterItem( INV_ITEM )
	local class = INV_ITEM:GetClass();

	-- Update data by class name
	if ( class ) then
		local entity = scripted_ents.Get( class ) or weapons.Get( class );
		if ( entity ) then
			local name = INV_ITEM:GetName();
			if ( name == "UnknownItem" || name == "" ) then
				INV_ITEM:SetData("name", entity.PrintName);
			end;
			if ( INV_ITEM:GetModel() == "" ) then
				INV_ITEM:SetData("model", entity.WorldModel);
			end;
		else
			return false, "Entity class not exists.";
		end;
	end;

	-- Calc unique id
	local uid = tonumber(gc.kernel:GetShortCRC(INV_ITEM:GetName().."_"..INV_ITEM:GetClass()));

	if (INV_ITEM("uid", -1) > 0) then
		uid = INV_ITEM("uid", -1);
	end;

	-- Validate duplicates
	for _, v in pairs(self.stored) do
		if ( uid == v("uid") ) then
			return false, "Item already registered.";
		end;
	end;

	-- Registration new item
	INV_ITEM:SetData( "uid", uid );
	util.PrecacheModel( INV_ITEM:GetModel() );

	table.insert( self.stored, INV_ITEM );
	self.buffer[uid] = INV_ITEM;

	return uid;
end;

-- A function to find item by unique id
function PLUGIN:FindByID( uid )
	local INV_ITEM = (self.stored[id] or self.buffer[id]);

	if (!INV_ITEM) then
		for _, item in pairs(self.stored) do
			if (item("uid") == uid) then
				INV_ITEM = item;
				break;
			end;
		end;
	end;

	return INV_ITEM;
end;

-- A function to find item by class name
function PLUGIN:FindByClass( sClass )
	local result = {};

	for i=1, #self.stored do
		if (self.stored[i]:GetClass() == sClass) then
			table.insert (result, self.stored[i]);
		end;
	end

	return result;
end;

-- A function to get inventory from entity
function entityMeta:GetInventory() return self.gc_inventory end;

if SERVER then
	greenCode.command:Add( "inv_clean", 2, function( player, command, args )
		--local inventory = player:GetInventory();
		--local items = inventory and inventory:GetItems();
		player:RemoveInventory();
		player:CreateInventory();
		--player:GetInventory():SetData("items", items or {});
	end);

	greenCode.chat:AddCommand( "inv", function( player, tArguments )
		local tr = player:GetEyeTrace();
		local entity = tr.Entity;

		if (!IsValid(entity)) then
			return;
		end;

		if (entity:GetClass() != "prop_physics") then
			return;
		end;

		local phys = entity:GetPhysicsObject();

		if (!IsValid(phys)) then
			return;
		end;

		if (player:GetPos():Distance(entity:GetPos()) > 150) then
			return;
		end;

		local sid = player:SteamID();
		if (entity._SID == sid and entity.SID == sid and entity.FPPOwnerID == sid) then
			player:Message( "Ты не владелец этого..." );
			return;
		end;

		local afford = phys:GetMass() * 0.25;

		if ( player:CanAfford(afford) ) then
			player:AddMoney(-afford);
		else
			player:Message( "Нужно " .. afford .. "$" );
			return;
		end;

		player:Message( "Инвентарь создан." );
		entity:CreateInventory();
	end);

	greenCode.command:Add( "inv", 2, function( player, command, args )
		local inventory = player:GetInventory();
		if (inventory) then
			player:PrintMsg(2, "Weight: "..inventory:CalculateWeight());
			for i, v in pairs(inventory:GetItems()) do
				if (!PLUGIN.buffer[i]) then continue end;

				if (type(v) == "table") then
					player:PrintMsg(2, "\t"..PLUGIN.buffer[i]:GetName() .. " #"..i);
					for h, t in pairs(v) do
						player:PrintMsg(2, "\t\t "..h.." = "..gc.kernel:Serialize(t));
					end;
				else 
					player:PrintMsg(2, "\t"..tostring(PLUGIN.buffer[i]) .. " #"..i.." x"..v);
				end;
			end;
		else
			player:PrintMsg(2, "Inventory not exist.");
		end;
	end);

	greenCode.command:Add( "inv_add", 2, function( player, command, args )
		if ( #args < 1 ) then
			player:PrintMsg(2, "Invalid arguments");
			return;
		end;

		player:PrintMsg(2, tostring(player:GetInventory():AddItem(tonumber(args[1]), args[2] or 1)));
	end);

	greenCode.command:Add( "inv_rm", 2, function( player, command, args )
		if ( #args < 2 ) then
			player:PrintMsg(2, "Invalid arguments");
			return;
		end;

		player:PrintMsg(2, tostring(player:GetInventory():RemoveItem(tonumber(args[1]), args[2] or 1)));
	end);

	greenCode.command:Add( "inv_drop", 0, function( player, command, args )
		if ( #args < 2 ) then
			player:PrintMsg(2, "Invalid arguments");
			return;
		end;

		local uid = tonumber(args[1]);
		local count = tonumber(args[2]);
		local inventory = player:GetInventory();

		if (!inventory) then return; end;
		inventory:DropItem(uid, count, tobool(args[3]));
	end);

	greenCode.command:Add( "inv_list", 0, function( player, command, args )
		player:PrintMsg(2, "Inventory item list:\n\tUID\tNAME");
		for _, ITEM in pairs(PLUGIN.buffer) do
			player:PrintMsg(2, " -\t"..tostring(ITEM:UniqueID()).."\t"..ITEM:GetName());
		end;
	end);

	greenCode.command:Add( "inv_sync", 0, function( player, command, args )
		local inventory = player:GetInventory();
		local curTime = CurTime();
		player.gcLastInvSync = player.gcLastInvSync or 0;

		if (!inventory or curTime - player.gcLastInvSync < 5.0) then return; end;
		player.gcLastInvSync = curTime;
		PLUGIN:Sync(inventory);
	end);

	greenCode.command:Add( "inv_set", 0, function( player, command, args )
		local tr = player:GetEyeTrace();
		local entity = tr.Entity;

		if (!IsValid(entity)) then
			return;
		end;

		local inventory = entity:CreateInventory();
		inventory:AddItem(17883, 5);
	end);

	greenCode.command:Add( "inv_fulldrop", 0, function( player, command, args )
		local inventory = player:GetInventory();
		local bAllow = gc.config:Get("inv_allow_fulldrop", true);
		if (not bAllow or not inventory or inventory:IsEmpty()) then return; end;

		local ent = PLUGIN:SpawnInventory(inventory);
		ent:SetAngles(player:GetAngles());
		ent:SetTitle(player:GetName());
		ent.RemoveIsEmpty = true;

		PLUGIN:Sync(inventory);
		PLUGIN:Sync(ent:GetInventory());
	end);

	greenCode.command:Add( "inv_put", 0, function( player, command, args )
		if ( #args < 3 ) then
			player:PrintMsg(2, "Invalid arguments");
			return;
		end;

		local rm_entity    = Entity(tonumber(args[1]));
		local uid          = tonumber(args[2]);
		local item         = PLUGIN:FindByID(uid);
		local index        = tonumber(args[3]);
		local rm_inventory = rm_entity:GetInventory();
		local inventory    = player:GetInventory();
		local bRevers      = tobool(args[4]);
		local bOneResearch = gc.config:Get("inv_one_research"):Get(false);

		if ( !IsValid(rm_entity) or not item or not rm_inventory or not inventory ) then
			player:PrintMsg(2, "Invalid data");
			return;
		elseif ((bOneResearch and rm_inventory:GetResearcher() != player) or not rm_inventory:ValidateResearcher(player)) then
			player:PrintMsg(2, "You are not researcher of inventory.");
			return;
		elseif (bRevers and 
			not inventory:IsExist(uid, index) or not bRevers and
			not rm_inventory:IsExist(uid, index)) then
				player:PrintMsg(2, "Item not exist in inventory.");
				return;
		end;

		-- Awsome realse revers action :)
		if (bRevers) then
			local t = rm_inventory;
			rm_inventory = inventory;
			inventory = t;
		end;

		local bSuccess, sReason = gc.plugin:Call("OnPlayerInventoryPutItem", player, inventory, item);

		if (bSuccess == false) then
			if (sReason) then
				player:ShowHint(tostring(sReason), 5, Color(255,100,100), nil, true);
			end;

			return;
		end;

		local count, tUserData = rm_inventory:RemoveItem(uid, index);
		inventory:AddItem(uid, count, tUserData);
	end);
end;

greenCode.command:Add( "inv", 0, function( player, command, args )
	local inventory;

	if (args[1]) then
		inventory = player:GetEyeTrace().Entity:GetInventory();
	else
		inventory = player:GetInventory();
	end;
	
	if (inventory) then
		print("Weight: "..inventory:CalculateWeight());
		for i, v in pairs(inventory:GetItems()) do
			if (!PLUGIN.buffer[i]) then continue end;

			if (type(v) == "table") then
				print("\t"..PLUGIN.buffer[i]:GetName() .. " #"..i);
				for h, t in pairs(v) do
					print("\t\t "..h.." = "..gc.kernel:Serialize(t));
				end;
			else 
				print("\t"..tostring(PLUGIN.buffer[i]) .. " #"..i.." x"..v);
			end;
		end;
	end;
end);