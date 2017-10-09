--[[
	© 2013 GmodLive private project do not share
	without permission of its author (Andrew Mensky vk.com/men232).
--]]
local PLUGIN = PLUGIN or greenCode.plugin:Loader();
CSHOP_PLUGIN = PLUGIN;
PLUGIN.stored = {};
PLUGIN.buffer = {};
PLUGIN.max = PLUGIN.max or {};

local playerMeta = FindMetaTable("Player");

function PLUGIN:RegisterItem( CSHOP_ITEM )
	local bShouldRegister = true;

	local class = CSHOP_ITEM("data", {}).weaponclass or CSHOP_ITEM:GetClass();
	if ( class ) then
		local entity = scripted_ents.Get( class ) or weapons.Get( class );
		if ( entity ) then
			if ( CSHOP_ITEM.data.name == "UnknownItem" ) then
				CSHOP_ITEM.data.name = entity.PrintName;
			end;
			if ( CSHOP_ITEM.data.model == "" ) then
				CSHOP_ITEM.data.model = entity.WorldModel;
			end;
		else
			bShouldRegister = false;
		end;
	end;

	local uid = tonumber(greenCode.kernel:GetShortCRC(CSHOP_ITEM:GetName()));

	for _, v in pairs(self.stored) do
		if ( uid == v("uid") ) then
			bShouldRegister = false;
			break;
		end;
	end;

	if ( bShouldRegister ) then
		CSHOP_ITEM:SetData( "uid", uid );

		util.PrecacheModel( CSHOP_ITEM:GetModel() );
		
		table.insert( self.stored, CSHOP_ITEM );
		self.buffer[uid] = CSHOP_ITEM;
		
		if ( CSHOP_ITEM("license") ) then
			local BLACK_ITEM = CSHOP_ITEM_CLASS:New( table.Copy(CSHOP_ITEM.data) );
			BLACK_ITEM:SetData( "name", BLACK_ITEM:Name().." (Black)" );
			BLACK_ITEM.data.licIgnore = BLACK_ITEM("license");
			BLACK_ITEM:SetData( "license", nil );
			BLACK_ITEM:SetData( "price", BLACK_ITEM:GetPrice()*2 );
			BLACK_ITEM:SetData( "category", "Черный рынок ("..BLACK_ITEM:GetCategory()..")" );
			BLACK_ITEM:Register();
		end;
		
		return uid;
	end;

	return bShouldRegister;
end;

function PLUGIN:FindByID( id )
	local CSHOP_ITEM = (self.stored[id] or self.buffer[id]);
	
	if (!CSHOP_ITEM) then
		for id, item in pairs(self.stored) do
			if (item("ent") == id) then
				CSHOP_ITEM = item;
				break;
			end;
		end;
	end;
	
	return CSHOP_ITEM;
end;

function PLUGIN:SortItems()
	if (!self.buffer.sorted) then
		local tSorted = {};
		
		for id, CSHOP_ITEM in SortedPairs(self.stored) do
			local sCategory = CSHOP_ITEM:GetCategory();

			if (!tSorted[sCategory]) then
				tSorted[sCategory] = {};
			end;
			
			table.insert(tSorted[sCategory], CSHOP_ITEM);
		end;
		
		self.buffer.sorted = tSorted;
	end;
	
	return self.buffer.sorted
end;

if SERVER then
	-- Called when entity removed.
	function PLUGIN:EntityRemoved( entity )
		if entity._SID then
			local uid = util.CRC("gm_"..entity._SID.."_gm");
			local sClass = entity:GetClass();
			
			if ( self.max[uid] and self.max[uid]["max"..sClass] ) then
				self.max[uid]["max"..sClass] = self.max[uid]["max"..sClass] - 1;
			end;
		end;
	end;

	function PLUGIN:ShouldBuyCShop( player, CSHOP_ITEM )
		local nMax = CSHOP_ITEM:GetMax();
		local sClass = CSHOP_ITEM:GetClass();
		local tAllowed = CSHOP_ITEM("allowed");
		local nPrice = CSHOP_ITEM:GetPrice();
		local fCanAfford = CSHOP_ITEM("canAfford");
		local fCustomCheck = CSHOP_ITEM("customCheck");
		local nLocation = CSHOP_ITEM("location");
		local uid = player:UniqueID();
		
		if ( player:isArrested() ) then
			return false, "Вы не покупать пока сидите в тюрьме.";
		end;

		if ( nMax > 0 ) then
			if (!self.max[uid]) then
				self.max[uid] = {};
			end;
			
			if ((self.max[uid]["max"..sClass] or 0) >= nMax) then				
				return false, "Вы достигли лимита покупок.";
			end;
		end;

		if (fCanAfford and !fCanAfford(player, nPrice) or !player:CanAfford(nPrice)) then
			return false, "Вы не можете себе позволить это.";
		end;

		if (type(tAllowed) == "table" and !table.HasValue(tAllowed, player:Team())) then
			return false, "Не доступно для вашей професии.";
		end;
		
		if ( nLocation ) then
			local TER_PLUGIN = TER_PLUGIN or greenCode.plugin:Get("territory");
			
			if ( nLocation != "^" ) then
				local TERRITORY = TER_PLUGIN:FindByID(nLocation);
				
				if ( TERRITORY and TERRITORY:IsValid() and player:GetTerritoryLocation() != TERRITORY ) then
					return false, "Для покупи этого, вы должи находится на территории '"..TERRITORY:Name().."'."
				end;
			else
				if ( player:GetTerritoryLocation():GetOwnerLevel(player) < 1 ) then
					return false, "Для покупи этого, вы должи находится на своей территории."
				end;
			end;
		end;

		if (fCustomCheck) then
			local bShouldBuy, sReason = fCustomCheck(player);
			
			if (!bShouldBuy) then
				return false, sReason;
			end;
		end;
	end;

	function PLUGIN:SpawnItem( player, CSHOP_ITEM )
		local bSuccess, value = pcall( function()
			local trace = {};
			local sClass = CSHOP_ITEM:GetClass();

			local tData = CSHOP_ITEM("data", {});
			local amountGiven = tData.amountGiven;
			local ammoType = tData.ammoType;

			trace.start = player:EyePos();
			trace.endpos = trace.start + player:GetAimVector() * 85;
			trace.filter = player;
			local tr = util.TraceLine(trace);

			local vehicle = list.Get("Vehicles")[sClass];
			local ent = ents.Create(vehicle and vehicle.Class or sClass);

			local position = greenCode.plugin:Call("CShopSpawnPosition", player, CSHOP_ITEM, ent);

			if (!position) then
				position = greenCode.player:GetSafePosition(player, tr.HitPos - Vector(0, 0, 32));
			end;

			if (vehicle) then
				ent.VehicleName = sClass;
				ent.VehicleTable = vehicle;

				if vehicle.KeyValues then
					for k, v in pairs(vehicle.KeyValues) do
						ent:SetKeyValue(k, v)
					end;
				end;

				ent.ClassOverride = vehicle.Class;
				if vehicle.Members then table.Merge(ent, vehicle.Members); end;
				ent:Own(player);

			elseif ( amountGiven ) then
				function ent:Use( player, ... )
					player:GiveAmmo( amountGiven, ammoType );
					self:Remove();
					return true;
				end;
			end;

			ent.onlyremover = true;
			ent.dt = ent.dt or {};
			ent.dt.owning_ent = player;
			if ent.Setowning_ent then ent:Setowning_ent(player) end;
			ent:SetPos(position or tr.HitPos);
			ent:SetModel(CSHOP_ITEM:GetModel());
			ent.SID = player.SID;
			ent._SID = player:SteamID();

			for k, v in pairs(tData) do
				ent[k] = v;
			end;

			ent:Spawn();
			ent:Activate();

			if ( CSHOP_ITEM:GetMax() > 0 ) then
				local uid = player:UniqueID();
				
				if (!self.max[uid]) then
					self.max[uid] = {};			
				end;
				
				self.max[uid]["max"..sClass] = (self.max[uid]["max"..sClass] or 0) + 1;
			end;

		end);

		return bSuccess, value;
	end;

	function PLUGIN:Buy( player, itemID )
		local CSHOP_ITEM = self:FindByID( itemID );

		if ( CSHOP_ITEM and CSHOP_ITEM:IsValid() ) then
			local bShouldBuy, sReason = greenCode.plugin:Call( "ShouldBuyCShop", player, CSHOP_ITEM );

			if ( bShouldBuy == nil or bShouldBuy ) then
				local bSpawned, sSpawnError = self:SpawnItem( player, CSHOP_ITEM );

				if ( bSpawned ) then
					local fRemoveMoney = CSHOP_ITEM("removeMoney");
					local nPrice = CSHOP_ITEM:GetPrice();

					if ( fRemoveMoney ) then
						fRemoveMoney( player, nPrice );
					else
						player:AddMoney(-nPrice);
					end;

					greenCode.plugin:Call( "OnBuyCShop", player, CSHOP_ITEM );
					
					return true;
				end;

				greenCode:Error("SpawnCItem", sSpawnError);

				return false, "Что то не так."
			else
				return false, sReason;
			end;
		else
			return false, "Предмет не найден"
		end;
	end;

	function PLUGIN:OnBuyCShop( player, CSHOP_ITEM )
		player:ShowHint( "Вы купили: "..CSHOP_ITEM:Name(), 5, Color(120,255,120), nil, true );
	end;
	
	-- Clean player ents when session is close.
	function PLUGIN:OnSessionClose( SESSION, sReason )
		local sid = SESSION("sid");
		
		if ( sid ) then
			local tCleanItemsDebug = { "Diconnect "..SESSION:Name().." player clean ents:" };
			
			for k, v in pairs( _ents.GetAll() ) do
				if ( IsValid(v) and v._SID == sid or v.SID == sid or v.FPPOwnerID == sid ) then
					table.insert( tCleanItemsDebug, "["..v:EntIndex().."] ["..v:GetClass().."] ["..v:GetModel().."]" );
					v:Remove();
				end;
			end;
			
			if ( #tCleanItemsDebug > 1 ) then greenCode:Debug( table.concat(tCleanItemsDebug, "\n\t\t") ); end;
		end;
	end;
	
	greenCode.command:Add( "ent_count", 2, function( player, command, args )
		if ( args[1] ) then
			local nCount = #ents.FindByClass(args[1]);
			player:PrintMsg( 2, args[1]..": "..nCount );
		end;
	end);
	
	greenCode.command:Add( "ent_goto", 2, function( player, command, args )
		if ( #args == 2 ) then
			local ents = ents.FindByClass(args[1]);
			
			if ( ents[tonumber(args[2])] ) then
				player:SetPos( ents[tonumber(args[2])]:GetPos() );
			end;
		end;
	end);

	greenCode.command:Add( "buy_item", 0, function( player, command, args )
		local bBuy, sReason = PLUGIN:Buy( player, tonumber(args[1] or -1) );

		if ( !bBuy ) then
			player:ShowHint( sReason, 5, Color(255,120,120), nil, true );
		end;
	end);

	greenCode.command:Add( "itemlist", 0, function( player, command, args )
		player:PrintMessage( HUD_PRINTCONSOLE, "Item List:" );

		for catName, tCategory in pairs( PLUGIN:SortItems() ) do
			player:PrintMessage( HUD_PRINTCONSOLE, "\t"..catName..":" );
			for _, CSHOP_ITEM in pairs( tCategory ) do
				player:PrintMessage( HUD_PRINTCONSOLE, "\t\t"..CSHOP_ITEM:UniqueID().."\t-\t"..CSHOP_ITEM:Name() );
			end;
		end;
	end);
end