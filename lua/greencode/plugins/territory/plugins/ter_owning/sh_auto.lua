--[[
	© 2013 GmodLive private project do not share
	without permission of its author (Andrew Mensky vk.com/men232).
--]]

local greenCode = greenCode;

local PLUGIN     = PLUGIN or greenCode.plugin:Loader();
PLUGIN.class = {};

local TER_PLUGIN = greenCode.plugin:Get("territory");

greenCode.config:Add( "rent_time", 15, false, false, false );

function PLUGIN:TerritorySystemInitialized()
	TERRITORY_PERMISSION_CLASS:New{ name = "owner", desc = "Permission for owning", default = false }:Register();
	TERRITORY_PERMISSION_CLASS:New{ name = "coowner", desc = "Permission for co-owning", default = false }:Register();
	TERRITORY_PERMISSION_CLASS:New{ name = "canowning", desc = "Permission allow owning", default = false }:Register();
end;

local playerMeta = FindMetaTable("Player");

function playerMeta:HoldingCount() return PLUGIN:HoldingCount( self ); end;

function PLUGIN:HoldingCount( player )
	local nCount = 0;
	
	for _, TERRITORY in pairs(TER_PLUGIN:GetStored()) do
		if ( TERRITORY:GetOwnerLevel(player) > 0 ) then
			nCount = nCount + 1;
		end;
	end;
	
	return nCount;
end;

-- A function to register class.
function PLUGIN:RegisterPrice( sName, sDesc, funcAfford, funcAdd, cur )
	self.class[ sName ] = { desc = sDesc, funcAfford = funcAfford, funcAdd = funcAdd, cur = cur };
end;

function PLUGIN:P_CanAfford( sName, player, nAmount )
	if ( self.class[sName] ) then
		return self.class[sName].funcAfford( player, nAmount );
	end;
	
	return false, "Incorrect price type.";
end;

function PLUGIN:P_AddMoney( sName, player, nAmount )
	if ( self.class[sName] ) then
		local bDone = self.class[sName].funcAdd(player, nAmount);
		if ( bDone != nil ) then return bDone; end;
		return true;
	end;
	
	return false, "Incorrect price type.";
end;

PLUGIN:RegisterPrice( "session", "Покупка на 1 игровой сеанс", playerMeta.CanAfford, playerMeta.AddMoney, "$" );
PLUGIN:RegisterPrice( "rent", "Аренда на "..greenCode.config:Get("rent_time"):Get(15).." мин", playerMeta.CanAfford, playerMeta.AddMoney, "$" );
PLUGIN:RegisterPrice( "perm", "Покупка на вечное владение", playerMeta.CanAfford, playerMeta.AddMoney, "$" );

---------------------
-- TERRITORY CLASS --
---------------------

function TERRITORY_CLASS:GetOwners() return self("owner", {}); end;
function TERRITORY_CLASS:GetCoOwners() return self("coowner", {}); end;
function TERRITORY_CLASS:IsOwned() return table.Count(self:GetOwners()) > 0 or table.Count(self:GetCoOwners()) > 0 end;
function TERRITORY_CLASS:GetPrice( sType ) 

	local nPrice = self("price",{})[sType] or 0;
	
	if ( sType == "session" or sType == "rent" ) then
		return greenCode.plugin:Call( "GetPrice", nPrice ) or nPrice;
	end;
	
	return nPrice;
end;

function TERRITORY_CLASS:GetOnlineOwners( bCoOwn )
	local tOwners = {};

	for uid, _ in pairs( self:GetOwners() ) do
		local player = _player.GetByUniqueID(tostring(uid));
		if ( player ) then
			table.insert( tOwners, player );
		end;
	end;

	if ( bCoOwn ) then
		for uid, _ in pairs( self:GetCoOwners() ) do
			local player = _player.GetByUniqueID(tostring(uid));
			if ( player ) then
				table.insert( tOwners, player );
			end;
		end;
	end;

	return tOwners;
end;

function TERRITORY_CLASS:GetAllPrice()
	local tPriceData = self("price",{});
	tPriceData.session = greenCode.plugin:Call( "GetPrice", tPriceData.session or 0 ) or tPriceData.session or 0;
	return tPriceData;
end;

-- A function to get all doors location in territory.
function TERRITORY_CLASS:GetDoors()
	local tDoors = {};

	for k, v in pairs(_ents.GetAll()) do
		if ( greenCode.entity:IsDoor( v ) and self:IsInside( v:GetPos() ) ) then
			table.insert( tDoors, v );
		end;
	end;

	return tDoors;
end;

if SERVER then
	function TERRITORY_CLASS:SetPrice( sType, nAmount )
		if ( PLUGIN.class[sType] ) then
			local tPriceData = self("price",{});
			tPriceData[sType] = nAmount;
			self:SetData( "price", tPriceData );
			return true;
		end;
		
		return false, "Incorrect price type.";
	end;

	function TERRITORY_CLASS:RemoveAllOwners()
		local tPermissionData = self:GetPerm().private;
		
		if ( tPermissionData ) then
			for uid, _ in pairs( tPermissionData ) do
				self:SetPermission( "private", "coowner", uid, nil  );
				self:SetPermission( "private", "owner", uid, nil  );
			end;
		end;
	end;

	function TERRITORY_CLASS:SetOwner( player )
		if ( self:GetPermission( "canowning", player, false ) ) then
			self:RemoveAllOwners();
			return self:SetPermission( "private", "owner", player, true, os.time() );
		else
			return false, "Вы не можете владеть этим.";
		end;
	end;

	function TERRITORY_CLASS:AddCoOwner( calling_ply, target_ply )
		local parentUID = self("ownerSession");
		
		if ( table.Count( self:GetOwners() ) > 0 and parentUID ) then
			local bDone, sReason, SESSION = self:SetPermission( "private", "coowner", target_ply, true, os.time() );
			
			if ( bDone ) then
				greenCode.plugin:Call( "OnTerritoryAddCoOwner", self, calling_ply, target_ply, SESSION );
			end;
			
			return bDone, sReason, SESSION;
		else
			return false, "Нет основного владельца.";
		end;
	end;
	
	function TERRITORY_CLASS:RemoveCoOwner( calling_ply, target_ply )		
		if ( self:GetOwnerLevel(target_ply) == 1 ) then
			local bDone, sReason, SESSION = self:SetPermission( "private", "coowner", target_ply, nil  );
			
			if ( bDone ) then
				greenCode.plugin:Call( "OnTerritoryRemoveCoOwner", self, calling_ply, target_ply, SESSION );
			end;
			
			return bDone, sReason, SESSION;
		else
			return false, "Нет прав."
		end;
	end;

	function TERRITORY_CLASS:GetOwnerLevel( player )
		if ( self:IsValid() ) then
			if ( self:GetPermission( "owner", player, false ) ) then
				return 2;
			elseif ( self:GetPermission( "coowner", player, false ) ) then
				return 1;
			end;  
		end;
		
		return 0;
	end;
	
	function TERRITORY_CLASS:Buy( player, sPriceType )
		local bDone, sReason = greenCode.plugin:Call( "PlayerCanBuyTerritory", self, player, sPriceType );
		
		if ( bDone != false ) then
			bDone, sReason, SESSION = self:SetOwner( player );
			
			if ( bDone ) then				
				PLUGIN:P_AddMoney( sPriceType, player, -self:GetPrice(sPriceType) );
				self:SetData("lastBuyType", sPriceType);
				greenCode.plugin:Call( "OnTerritoryBuy", self, player, sPriceType, SESSION );
			end;
		end;
		
		return bDone, sReason;
	end;
	
	-- A function to sell territory.
	function TERRITORY_CLASS:Sell( player )
		local bCanSell, sMsg = greenCode.plugin:Call( "PlayerCanSellTerritory", self, player );
		
		if ( bCanSell != false ) then
			local nPriceType = self("lastBuyType", "session");
			
			if ( !PLUGIN.class[nPriceType] ) then
				nPriceType = PLUGIN.class[1];
			end;
			
			bCanSell, sMsg = PLUGIN:P_AddMoney( nPriceType, player, math.ceil(self:GetPrice(nPriceType)/2) );
			
			if ( bCanSell ) then
				self.data.ownerSession = -1; -- Clean owner session.
				self:RemoveAllOwners();
				greenCode.plugin:Call( "OnTerritorySell", self, player );
				return true;
			end;
		end;
		
		return bCanSell, sMsg;
	end;
	
	function TERRITORY_CLASS:UpdateDoorOwner( player, bAllow )		
		local nOwnerLevel = self:GetOwnerLevel( player );
		
		for _, door in pairs( self:GetDoors() ) do
			if ( door and IsValid(door) ) then				
				if ( bAllow and door:IsOwnable() ) then
					if ( nOwnerLevel > 1 and !door:IsOwned() and !door:OwnedBy(player) ) then
						door:RemoveAllowed(player);
						door:Own(player);
						continue;
					elseif ( door:IsOwned() ) then
						door:AddAllowed(player);
					end;
					
					door:Own(player);
				else
					door:RemoveAllowed(player);
					door:UnOwn(player);
				end;
			end;
		end;
	end;
else
	function TERRITORY_CLASS:GetOwnerLevel( player )
		if ( self:IsValid() ) then
			local uid = tonumber(player:UniqueID());
			
			if ( self:GetOwners()[uid] ) then
				return 2;
			elseif ( self:GetCoOwners()[uid] ) then
				return 1;
			end;  
		end;
		
		return 0;
	end;
end;

--------------------
-- TERRITORY HOOK --
--------------------

if CLIENT then return end;

function PLUGIN:OnTerritoryGetPermission( TERRITORY, sPermissionName, player )
	if ( sPermissionName == "spawnobject" and TERRITORY:GetOwnerLevel(player) > 0 ) then
		return true, "Is owner!";
	end;
end;

function PLUGIN:PlayerCharacterInitialized( player )
	for _, TERRITORY in pairs(TER_PLUGIN:GetStored()) do
		if ( TERRITORY:GetOwnerLevel(player) > 0 ) then
			TERRITORY:UpdateDoorOwner(player, true);
		end;
	end;
end;

function PLUGIN:OnTerrytoryChangeOwners( TERRITORY, player, bValue )
	if ( type(player) == "number" ) then
		player = _player.GetByUniqueID(tostring(player));
	end;
	
	if ( player and type(player) == "Player" ) then
		timer.Simple(1, function()		
			if ( IsValid(player) ) then
				TERRITORY:UpdateDoorOwner(player, tobool(bValue));
			end;
		end);
	end;
end;

function PLUGIN:PlayerCanBuyTerritory( TERRITORY, player, sPriceType )
	local nPrice = TERRITORY:GetPrice( sPriceType );
	
	if ( !self.class[sPriceType] ) then
		return false, "Incorrect price type."
	elseif ( TERRITORY:GetOwnerLevel(player) > 0 ) then
		return false, "Вы уже владелец этой территорией.";
	elseif ( TERRITORY:IsOwned() ) then
		local tOwnerNames = {}
		
		for uid, v in pairs( TERRITORY:GetOwners() ) do
			table.insert( tOwnerNames, v.name )
		end;
		
		return false, "Эта территория уже занята: " .. table.concat( tOwnerNames, ", " )..".";
	elseif ( nPrice <= 0 ) then
		return false, "Эта территории бесценна =) Позовите админа, пусть исправит!";
	elseif ( !self:P_CanAfford( sPriceType, player, nPrice ) ) then
		return false, "Вам это не по корману!";
	end;
end;

function PLUGIN:PlayerCanSellTerritory( TERRITORY, player )
	if ( TERRITORY:GetOwnerLevel(player) < 2 ) then
		return false, "Вы не можете продать эту территорию.";
	end;
end;

function PLUGIN:OnTerritoryChangePermission( TERRITORY, sPermissionName, sCharterName, player, bValue )
	if ( sPermissionName == "owner" or sPermissionName == "coowner" ) then
		local uid, sid, sName = greenCode.session:GetPlayerData(player);
		local tData = sPermissionName == "owner" and TERRITORY:GetOwners() or TERRITORY:GetCoOwners();
		
		if ( bValue ) then
			tData[uid] = { name = sName, sid = sid };
		else
			tData[uid] = nil;
		end;
		
		TERRITORY:SetData( sPermissionName, tData );
		greenCode.plugin:Call( "OnTerrytoryChangeOwners", TERRITORY, player, bValue );
	elseif ( sPermissionName == "canowning" and sCharterName == "public" ) then
		TERRITORY:SetData( "forsale", bValue );
	elseif ( sPermissionName == "spawnobject" and sCharterName == "private" ) then
		local uid, _, sName = greenCode.session:GetPlayerData(player);
		local tPropSpawnData = TERRITORY("propSpawn", {});
		tPropSpawnData[uid] = bValue and sName or nil;
		TERRITORY:SetData( "propSpawn", tPropSpawnData );
	end;
end;

function PLUGIN:OnTerrytoryCreate( tTerritoryData )
	tTerritoryData["owner"] = {};
	tTerritoryData["coowner"] = {};
	tTerritoryData["price"] = { session = 0 };
	tTerritoryData["forsale"] = false;
	tTerritoryData["propSpawn"] = {};
	tTerritoryData["ownerSession"] = 0;
	tTerritoryData["_rent"] = 0;
	tTerritoryData["lastBuyType"] = "";
end;

-- Called when player try buy door.
function PLUGIN:PlayerBuyDoor( player, eDoor )
	local TERRITORY = TER_PLUGIN:GetLocation( eDoor:GetPos() );
	
	if ( TERRITORY and TERRITORY:IsValid() and !eDoor:AllowedToOwn( player ) and TERRITORY:GetOwnerLevel(player) < 2 ) then
		GAMEMODE:Notify( player, 1, 4, "Дверь часть территории '" .. TERRITORY:GetName().. "'." );
		return false;
	end;
end;

-- Called when player try buy door.
function PLUGIN:PlayerSellDoor( player, eDoor )
	local TERRITORY = TER_PLUGIN:GetLocation( eDoor:GetPos() );
	
	if ( TERRITORY and TERRITORY:IsValid() and TERRITORY:UniqueID() != 0 ) then
		GAMEMODE:Notify( player, 1, 4, "Дверь часть территории '" .. TERRITORY:GetName().. "'." );
		return false;
	end;
end;

function PLUGIN:OnTerritoryPrintInfo( player, TERRITORY )
	ULib.console( player, "\t\tOwner Level = " .. TERRITORY:GetOwnerLevel(player) );
	ULib.console( player, "\t\tFor sale = " .. tostring(TERRITORY("forsale",false)) );
	ULib.console( player, "\t\tLast Buy = " .. tostring(TERRITORY("lastBuyType","none")) );
	ULib.console( player, "\t\tPrice:" );
	for sType, nAmount in pairs( TERRITORY:GetAllPrice() ) do
		ULib.console( player, "\t\t\t"..sType.." = " .. nAmount );
	end;
end;

-- Called when player buy some territory.
function PLUGIN:OnTerritoryBuy( TERRITORY, player, sPriceType, SESSION )
	-- to session buy, parent session to player.
	if ( sPriceType == "session" ) then
		SESSION:SetParent( tonumber(player:UniqueID()) );
	elseif ( sPriceType == "rent" ) then
		SESSION:SetTimeOut( greenCode.config:Get("rent_time"):Get(15)*60 );
		SESSION:SetParent(-1); -- Clean parent if before playey buy in seesion.
	elseif ( sPriceType == "perm" ) then
		SESSION:SetParent(-1); -- Clean parent if before playey buy in seesion or rent.
	end;
	
	TERRITORY:SetData("ownerSession", SESSION:UniqueID());

	player:EmitSound( "greencode/mission_passed"..math.random(1,2)..".mp3" );
	greenCode.hint:SendAll( player:Name().." купил территорию ["..TERRITORY:GetName().."] "..sPriceType..".", 5, Color( 100, 255, 100 ) );
	player:ConCommand("cl_gc_custommenu_update 7920");
end;

-- This fix to shared.lua
GAMEMODE.DefaultTeam = TEAM_CITIZEN;

-- Called when player sell some territory.
function PLUGIN:OnTerritorySell( TERRITORY, player )
	-- Set default team
	if ( self:HoldingCount(player) < 1 ) then
		player:ChangeTeam(GAMEMODE.DefaultTeam, true);
	end;
	
	-- Remove props.
	local tRemovedProps = { "Territory "..TERRITORY:Name().." - "..TERRITORY:UniqueID().." sell removed props:" };
	
	for k, v in pairs( _ents.GetAll() ) do
		if ( v.FPPOwnerID and TER_PLUGIN:GetLocation( v:GetPos() ) == TERRITORY ) then
			table.insert( tRemovedProps, "["..v.FPPOwnerID.."] ["..v:EntIndex().." ["..v:GetClass().."]" );
			v:Remove();
		end;
	end;
	
	if ( #tRemovedProps > 1 ) then
		greenCode:Debug( table.concat(tRemovedProps, "\n\t\t") );
	end;
	
	-- Update info
	greenCode.hint:SendAll( player:Name().." продал территорию ["..TERRITORY:GetName().."] "..".", 5, Color( 100, 255, 100 ) );
	player:ConCommand("cl_gc_custommenu_update 7920");
end;

function PLUGIN:OnTerritorySendData( tTerritoryData )
	tTerritoryData.ownerSession = nil;
end;

function PLUGIN:OnSessionChangeTimeOut( SESSION, nValue, nPrev )
	local tData = SESSION("territoryData");

	if ( tData and tData.permission == "owner" ) then
		local TERRITORY = TER_PLUGIN:FindByID(tData.uid);

		if ( TERRITORY and TERRITORY:IsValid() and TERRITORY("lastBuyType") == "rent" ) then			
			local curTime = CurTime();
			local nEndTime = math.ceil( curTime + nValue );
			local difference = math.abs(TERRITORY("_rent", 0) - nEndTime);
			
			if ( difference > 1 ) then
				TERRITORY:SetData("_rent", nEndTime);
			end;

			if ( nValue == 300 or nValue == 180 or nValue == 180 ) then
				for _, player in pairs( TERRITORY:GetOnlineOwners() ) do
					greenCode.hint:Send( player, "До продления аренды '"..TERRITORY:Name().."' осталось "..math.Round(nValue/60).." мин.", 5, Color( 255, 255, 100 ), nil, true );
				end;
			end;
		end;
	end;
end;

function PLUGIN:GroupPay( tGroup, nPrice )
	local nGoodPrice = math.Round( nPrice / #tGroup );

	for k, player in pairs( tGroup ) do
		if ( !self:P_CanAfford( "rent", player, nGoodPrice ) and !player:DepositsCanAfford(nGoodPrice) ) then
			local nNotHave = nGoodPrice - (player:getDarkRPVar("money") or 0);
				player.gcGroupPay = player.gcGroupPay + (nGoodPrice - nNotHave);
				tGroup[k] = nil;
			return self:GroupPay( tGroup, nPrice - (nGoodPrice-nNotHave) );
		else
			player.gcGroupPay = player.gcGroupPay + nGoodPrice;
			nPrice = nPrice - nGoodPrice;
		end;
	end;

	return nPrice;
end;

function PLUGIN:PreSessionClose( SESSION, uid )
	local tData = SESSION("territoryData");

	if ( tData ) then
		local TERRITORY = TER_PLUGIN:FindByID(tData.uid);

		if ( TERRITORY and TERRITORY:IsValid() and TERRITORY("lastBuyType") == "rent" ) then
			local nPrice = TERRITORY:GetPrice("rent");
			local tOwners = TERRITORY:GetOnlineOwners();
			local nGoodPrice = math.Round( nPrice / #tOwners );

			for _, player in pairs( tOwners ) do
				player.gcGroupPay = 0;
			end;

			local nCost = self:GroupPay( tOwners, nPrice );

			if ( nCost <= 0 ) then
				for _, player in pairs( tOwners ) do
					local bShouldDeposit = false;
					local DEPOSIT;
					
					if ( self:P_CanAfford( "rent", player, player.gcGroupPay ) ) then
						self:P_AddMoney( "rent", player, -player.gcGroupPay );
					else
						DEPOSIT = player:DepositsCanAfford(-player.gcGroupPay);
						
						if ( DEPOSIT ) then
							DEPOSIT:AddMoney(-player.gcGroupPay);
							bShouldDeposit = true;
						end;
 					end;
					
					greenCode.hint:Send( player, "Автоматическое продление аренды '"..TERRITORY:Name().."' "..greenCode.kernel:FormatNumber(player.gcGroupPay).."$"..( bShouldDeposit and " Оплата со счета #"..DEPOSIT:UniqueID().." - "..DEPOSIT:Name().."." or "" ), 5, Color( 255, 255, 100 ), nil, true );
				end;

				SESSION:SetTimeOut( greenCode.config:Get("rent_time"):Get(15)*60 );
			end;
		end;
	end;
end;

--------------------
-- PLUGIN COMMAND --
--------------------

greenCode.command:Add( "ter_buy", 0, function( player, command, args )
	if ( #args < 2 ) then return; end;
	
	local bDone, sReason;
	local TERRITORY = TER_PLUGIN:FindByID(tonumber(args[1])) or TER_PLUGIN:FindByName(args[1]);
	
	if ( TERRITORY and TERRITORY:IsValid() ) then
		bDone, sReason = TERRITORY:Buy( player, args[2] );
	else
		bDone, sReason = false, "Territory not found.";
	end;
	
	if ( !bDone ) then
		greenCode.hint:Send( player, sReason, 5, Color( 255, 100, 100 ), nil, true );
	end
end);

greenCode.command:Add( "ter_sell", 0, function( player, command, args )
	if ( #args < 1 ) then return; end;
	
	local bDone, sReason;
	local TERRITORY = TER_PLUGIN:FindByID(tonumber(args[1])) or TER_PLUGIN:FindByName(args[1]);
	
	if ( TERRITORY and TERRITORY:IsValid() ) then
		bDone, sReason = TERRITORY:Sell( player, args[2] );
	else
		bDone, sReason = false, "Territory not found.";
	end;
	
	if ( !bDone ) then
		greenCode.hint:Send( player, sReason, 5, Color( 255, 100, 100 ), nil, true );
	end
end);

greenCode.command:Add( "ter_allowcoown", 0, function( player, command, args )
	if ( #args < 3 ) then return; end;
	
	local bDone, sReason;
	local TERRITORY = TER_PLUGIN:FindByID(tonumber(args[1])) or TER_PLUGIN:FindByName(args[1]);
	local bValue = tobool(args[3]) or nil;
	local TARGET_PLY_SESSION;
	
	if ( TERRITORY and TERRITORY:IsValid() ) then
		if ( TERRITORY:GetOwnerLevel(player) > 1 ) then
			local target_ply_uid, calling_ply_uid = tonumber(args[2]), tonumber(player:UniqueID());
			TARGET_PLY_SESSION = greenCode.session:FindByID(target_ply_uid or -1);
			
			if ( target_ply_uid != calling_ply_uid and TARGET_PLY_SESSION and TARGET_PLY_SESSION:IsValid() and TARGET_PLY_SESSION("sid")  ) then
				local sessionName = "private_"..calling_ply_uid.."_owner_"..TERRITORY:UniqueID();
				local sessionUID = tonumber(util.CRC(sessionName));
				local OWN_SESSION = greenCode.session:FindByID(sessionUID);
				
				if ( OWN_SESSION and OWN_SESSION:IsValid() and OWN_SESSION("territoryData") ) then
					local bShould, sError, PERM_SESSION;
					
					if ( bValue ) then
						 bShould, sError, PERM_SESSION = TERRITORY:AddCoOwner( player, target_ply_uid );
					else
						 bShould, sError, PERM_SESSION = TERRITORY:RemoveCoOwner( player, target_ply_uid );
					end;
					
					if ( bShould ) then
						PERM_SESSION:SetParent(OWN_SESSION:UniqueID()); -- Remove coowner when owner buy session in close.
						player:ConCommand("cl_gc_custommenu_update 7920");
						bDone, sReason = bValue, "Вы "..(bValue and "добавили в совладельци " or "удалили из совладельцев ")..TARGET_PLY_SESSION:Name().." на '"..TERRITORY:Name().."'.";
					else
						sReason = sError;
					end;
				else
					bDone, sReason = false, "Inccorect owner session uid.";
				end;
			else
				bDone, sReason = false, "Inccorect player uid.";
			end;
		else
			bDone, sReason = false, "У вас нет прав.";
		end;
	else
		bDone, sReason = false, "Territory not found.";
	end;
	
	if ( bDone ) then
		greenCode.hint:SendAll( player:Name()..(bValue and "добавил в совладельци " or "удалил из совладельцев ")..TARGET_PLY_SESSION:Name().." на '"..TERRITORY:Name().."'.", 5, bValue and Color(100,255,100) or Color(255,100,100), nil, true );
	else
		greenCode.hint:Send( player, sReason, 5, Color(255,100,100), nil, true );
	end;
end);

greenCode.command:Add( "ter_allowspawn", 0, function( player, command, args )
	if ( #args < 3 ) then return; end;
	
	local bDone, sReason;
	local TERRITORY = TER_PLUGIN:FindByID(tonumber(args[1])) or TER_PLUGIN:FindByName(args[1]);
	local bValue = tobool(args[3]) or nil;
	local PLY_SESSION
	
	if ( TERRITORY and TERRITORY:IsValid() ) then
		local nOwnerLevel = TERRITORY:GetOwnerLevel(player);
		
		if ( nOwnerLevel > 0 ) then
			local target_ply_uid, calling_ply_uid = tonumber(args[2]), tonumber(player:UniqueID());
			PLY_SESSION = greenCode.session:FindByID(target_ply_uid or -1);

			if ( target_ply_uid != calling_ply_uid and PLY_SESSION and PLY_SESSION:IsValid() and PLY_SESSION("sid") ) then
				local sessionName = "private_"..calling_ply_uid..( nOwnerLevel > 1 and "_owner_" or "_coowner_")..TERRITORY:UniqueID();
				
				local sessionUID = tonumber(util.CRC(sessionName));
				local OWN_SESSION = greenCode.session:FindByID(sessionUID);

				if ( OWN_SESSION and OWN_SESSION:IsValid() and OWN_SESSION("territoryData") ) then
					local bShould, sError, PERM_SESSION = TERRITORY:SetPermission( "private", "spawnobject", target_ply_uid, bValue, bValue and os.time() );
					
					if ( bShould ) then
						PERM_SESSION:SetParent(OWN_SESSION:UniqueID()); -- Remove propspawn when owner buy session in close.
						player:ConCommand("cl_gc_custommenu_update 7920");
						bDone, sReason = true, "Вы "..(bValue and "разрешили" or "запретили").." "..PLY_SESSION:Name().." spawn объектов на '"..TERRITORY:Name().."'.";
					else
						sReason = sError;
					end;
				else
					bDone, sReason = false, "Inccorect owner session uid.";
				end;
			else
				bDone, sReason = false, "Inccorect player uid.";
			end;
		else
			bDone, sReason = false, "У вас нет прав.";
		end;
	else
		bDone, sReason = false, "Territory not found.";
	end;
	
	if ( bDone ) then
		greenCode.hint:Send( player, sReason, 5, bValue and Color(100,255,100) or Color(255,100,100), nil, true );
	
		for _, v in pairs( TERRITORY:GetOnlineOwners(true) ) do
			if ( player == v ) then
				continue;
			end;
			
			greenCode.hint:Send( v, player:Name()..(bValue and " разрешили " or " запретили ")..PLY_SESSION:Name().." spawn объектов на '"..TERRITORY:Name().."'.", 5, bValue and Color(100,255,100) or Color(255,100,100), nil, true );
		end;
	else
		greenCode.hint:Send( player, sReason, 5, Color(255,100,100), nil, true );
	end;
end);