--[[
	© 2013 GmodLive private project do not share
	without permission of its author (Andrew Mensky vk.com/men232).
--]]

local greenCode = greenCode;
local gc        = gc;
local table     = table;
local math      = math;
local SysTime = SysTime;

local PLUGIN     = PLUGIN or greenCode.plugin:Loader();
local playerMeta = FindMetaTable("Player");

PLUGIN.stored = PLUGIN.stored or {};
PLUGIN.buffer = PLUGIN.buffer or {};

function PLUGIN:RegisterTerritory( TERRITORY )
	if ( TERRITORY and TERRITORY:IsValid() and TERRITORY("uid") != -1 ) then
		local uid = TERRITORY( "uid" );

		if ( uid >= 0 and !self.stored[ uid ] ) then
			self.stored[ uid ] = TERRITORY;
			table.insert( self.buffer, TERRITORY("name") );

			greenCode.plugin:Call( "OnTerritoryRegistered", TERRITORY );

			return true;
		end;
	end;
end;

function PLUGIN:GetLocation( vPosition )
	local LOCATION;

	for _, TERRITORY in pairs( self.stored ) do
		if ( TERRITORY:IsInside( vPosition ) ) then
			if ( TERRITORY:IsGlobal() ) then
				LOCATION = TERRITORY;
			else
				return TERRITORY, TERRITORY:UniqueID();
			end
		end;
	end;

	if ( LOCATION ) then
		return LOCATION, LOCATION:UniqueID();
	else
		return self.stored[0], 0;
	end;
end;

function playerMeta:GetTerritoryLocation() return PLUGIN:GetLocation( self:GetShootPos() ); end;

function PLUGIN:GetStored() return self.stored end;

-- A function to find a plugin by an ID.
function PLUGIN:FindByID( identifier )
	return self.stored[ identifier ];
end;

-- A function to find a plugin by an ID.
function PLUGIN:FindByName( identifier )
	local territory;

	for _, TERRITORY in pairs( self.stored ) do
		if ( TERRITORY:UniqueID() == sName or TERRITORY:Name() == identifier ) then
			return TERRITORY;
		elseif ( string.find( string.lower(TERRITORY:Name() or ""), string.lower( identifier ) ) ) then
			if (territory) then
				if ( string.len(TERRITORY:Name()) < string.len(territory:Name()) ) then
					territory = TERRITORY;
				end;
			else
				territory = TERRITORY;
			end;
		end;
	end;
end;

PLUGIN.PERMISSION = PLUGIN.PERMISSION or {};
PLUGIN.PERMISSION.stored = PLUGIN.PERMISSION.stored or {};
PLUGIN.PERMISSION.buffer = PLUGIN.PERMISSION.buffer or {};

function PLUGIN.PERMISSION:Register( PERM )
	if ( PERM and PERM:IsValid() and !self.stored[ PERM("name") ] ) then
		self.stored[ PERM("name") ] = PERM;
		table.insert( self.buffer, PERM("name") );
	end;
end;

-- A function to find a plugin by an ID.
function PLUGIN.PERMISSION:FindByID( identifier )
	return self.stored[ identifier ];
end;

PLUGIN.CHARTER = PLUGIN.CHARTER or {};
PLUGIN.CHARTER.stored = PLUGIN.CHARTER.stored or {};
PLUGIN.CHARTER.buffer = PLUGIN.CHARTER.buffer or {};

function PLUGIN.CHARTER:Register( CHARTER )
	if ( CHARTER and CHARTER:IsValid() and !self.stored[ CHARTER("name") ] ) then
		self.stored[ CHARTER("name") ] = CHARTER;
		table.insert( self.buffer, CHARTER("name") );
	end;
end;

-- A function to find a plugin by an ID.
function PLUGIN.CHARTER:FindByID( identifier )
	return self.stored[ identifier ];
end;

function PLUGIN.CHARTER:SortByPriority()
	if ( !self.sortCached ) then
		local tSorted = {};

		for _, CHARTER in pairs( self.stored ) do
			local nPriority = CHARTER:GetPriority();

			if ( !tSorted[ nPriority ] ) then
				tSorted[ nPriority ] = {};
			end

			tSorted[ nPriority ][ CHARTER:GetName() ] = CHARTER;
		end;

		self.sortCached = tSorted;
		return tSorted;
	else
		return self.sortCached;
	end;
end;

function PLUGIN:Initialized()
	--[[ BASIC PERMISSIONS --]]
	TERRITORY_PERMISSION_CLASS:New{ name = "adminimmunity", desc = "Immunity for admins", default = true }:Register();

	TERRITORY_CHARTER_CLASS:New{ name = "private", storeID = "UniqueID", type = "int", priority = 1 }:Register();
	TERRITORY_CHARTER_CLASS:New{ name = "group", storeID = "GetUserGroup", type = "string", priority = 2 }:Register();
	TERRITORY_CHARTER_CLASS:New{ name = "team", storeID = "Team", type = "int", priority = 3 }:Register();
	TERRITORY_CHARTER_CLASS:New{ name = "public", storeID = 0, priority = 4 }:Register();

	greenCode.plugin:Call( "TerritorySystemInitialized" );
end;

function PLUGIN:RebuildBuffer()
	table.Empty( self.buffer );
	
	if CLIENT then
		table.Empty( self.DoubleList );
	end;

	for _, TERRITORY in pairs( self.stored ) do
		table.insert( self.buffer, TERRITORY:Name() );

		if CLIENT then
			table.insert( self.DoubleList, TERRITORY:Name() );
			table.insert( self.DoubleList, tostring(TERRITORY:UniqueID()) );
		end;
	end;
end;

if SERVER then
	function PLUGIN:PlayerSetSharedVars( player, tSharedData, curTime )
		local TERRITORY, uid = self:GetLocation( player:GetShootPos() );
		tSharedData.territory = uid;
	end;

	function PLUGIN:IsLoading() return self.LoadingMode end;
	function PLUGIN:SetLoading( bValue ) self.LoadingMode = bValue end;

	function PLUGIN:Save( uid )
		local sMap = string.lower( game.GetMap() );
		local tSavedList = { "Territory saved:" };

		if ( self.stored[ uid ] ) then
			greenCode.kernel:SaveGameData( "territory/"..sMap.."/"..tostring( uid ), self.stored[ uid ].data );
			table.insert( tSavedList, self.stored[ uid ]:Name() .. " - " .. uid );
		else
			for uid, _ in pairs( self.stored ) do
				greenCode.kernel:SaveGameData( "territory/"..sMap.."/"..tostring( uid ), self.stored[ uid ].data );
				table.insert( tSavedList, self.stored[ uid ]:Name() .. " - " .. uid );
			end;
		end;

		if ( #tSavedList > 1 ) then
			greenCode:Debug( table.concat(tSavedList, "\n\t\t") );
		end;
	end;

	function PLUGIN:Load()
		self:Clean();
		self:SetLoading( true );

		local sMap   = string.lower(game.GetMap());
		local Loaded = { "Loaded territory:" };
		local Errors = { "Loaded error territory:" };

		for id, v in pairs( _file.Find( GC_GAMEDATA_FOLDER.."/territory/"..sMap.."/*.txt", "DATA" ) ) do
			local uid   = tonumber(string.Replace(v, ".txt", ""));
			local tData = greenCode.kernel:RestoreGameData("territory/"..sMap.."/"..uid);
			tData.uid = uid;

			local TERRITORY = TERRITORY_CLASS:New( tData );
			if TERRITORY:Register() then
				table.insert( Loaded, TERRITORY:Name().." - "..TERRITORY:UniqueID() );
			else
				table.insert( Errors, TERRITORY:Name().." - "..TERRITORY:UniqueID() );
			end;
		end;

		if ( #Loaded > 1 ) then
			greenCode:Debug( table.concat(Loaded, "\n\t\t") );
		end;
		if ( #Errors > 1 ) then
			greenCode:Debug( table.concat(Errors, "\n\t\t") );
		end;

		WORLD_TERRITORY = self.stored[0];

		if ( !WORLD_TERRITORY or !WORLD_TERRITORY:IsValid() ) then
			self.stored[0] = nil;
			
			WORLD_TERRITORY = TERRITORY_CLASS:New( { uid = 0, name = "World", global = true } );
			WORLD_TERRITORY:Register();
		end;

		self:SetLoading( false );
		
		timer.Simple( 1, function()
			self:SendData( -1, true );
		end)
	end;

	function PLUGIN:InitPostEntity()
		self:Load();
	end;

	function PLUGIN:SendData( uid, player )
		local TERRITORY = self:FindByID( uid or -1 );
		local tSendData = {};
		local bShouldSend = false;

		if ( TERRITORY and TERRITORY:IsValid() ) then
			table.insert( tSendData, table.Copy( TERRITORY.data ) );
			bShouldSend = true;
		else
			for _, TERRITORY in pairs( self.stored ) do
				if ( TERRITORY:IsValid() ) then
					table.insert( tSendData, table.Copy( TERRITORY.data ) );
					bShouldSend = true;
				end;
			end;
		end;

		for _, tTerritoryData in pairs( tSendData ) do
			greenCode.plugin:Call( "OnTerritorySendData", tTerritoryData );
		end;

		greenCode.datastream:Start( player or true, "gcTerritorySync", tSendData );
	end;

	function PLUGIN:OnTerritorySendData( tTerritoryData )
		tTerritoryData.permissions = nil;
	end;

	function PLUGIN:OnTerrytoryCreate( tTerritoryData )
		for _, CHARTER in pairs( self.CHARTER.stored ) do
			local name = CHARTER:Name();
			tTerritoryData.permissions[ name ] = {};

			if ( name == "public" ) then
				for _, PERM in pairs( self.PERMISSION.stored ) do
					tTerritoryData.permissions[ name ][ PERM:Name() ] = PERM:GetDefault();
				end;
			end;
		end;
	end;

	function PLUGIN:OnTerrytoryRemove( uid, name )
		self:RebuildBuffer();
		
		local sMap = string.lower(game.GetMap());
			greenCode.kernel:DeleteGameData("territory/"..sMap.."/"..uid);

		greenCode.datastream:Start( true, "gcTerritoryRemove", { uid = uid } );
	end;

	function PLUGIN:OnTerritoryRegistered( TERRITORY )
		if ( !self:IsLoading() ) then
			self:Save( TERRITORY:UniqueID() );
			self:SendData( TERRITORY:UniqueID() );
		end;
	end;

	function PLUGIN:OnTerrytoryChangeData( TERRITORY, sKey, value )
		self:Save( TERRITORY:UniqueID() );
		
		greenCode.datastream:Start( true, "gcTerritoryData", {
			uid = TERRITORY:UniqueID(), name = TERRITORY:Name(), key = sKey, value = TERRITORY(sKey, value);
		} );
	end;

	function PLUGIN:OnTerritoryChangePermission( TERRITORY, sPermissionName, sCharterName, player, bValue )
		local SID = self.CHARTER:FindByID( sCharterName ):GetPlayerSID( player );

		if ( SID and table.Count( (TERRITORY:GetPerm()[sCharterName][SID] or {}) ) < 1 ) then
			TERRITORY:GetPerm()[sCharterName][SID] = nil;
		end;

		self:Save( TERRITORY:UniqueID() );
	end;

	local tBlackList = { "adminimmunity", "owner", "coowner", "canowning" };
	function PLUGIN:OnTerritoryGetPermission( TERRITORY, sPermissionName, player )
		if ( !table.HasValue( tBlackList, sPermissionName ) and TERRITORY:GetPermission( "adminimmunity", player, false ) ) then
			return player:IsAdmin() or nil;
		end;
	end;

	function PLUGIN:PlayerCharacterInitialized( player )
		self:SendData( nil, player );
	end;

	function PLUGIN:Clean()
		self.stored = {};
		table.Empty( self.buffer );
		greenCode.datastream:Start( true, "gcTerritoryClean" );
	end;

	function PLUGIN:OnSessionClose( SESSION, sReason )
		local tData = SESSION("territoryData");

		if ( tData ) then
			local TERRITORY = self:FindByID(tData.uid);

			if ( TERRITORY and TERRITORY:IsValid() ) then
				TERRITORY:SetPermission( tData.charter, tData.permission, tData.sid, SESSION("returnValue", false) or nil );
			end;
		end;
	end;

	PLUGIN.DoubleList = PLUGIN.buffer;
else
	PLUGIN.DoubleList = PLUGIN.DoubleList or {};

	greenCode.config:Add( "draw_territory", false, false, false, false );

	function PLUGIN:OnTerritoryDataReceive()
		WORLD_TERRITORY = self.stored[0];
		self:RebuildBuffer();
	end;

	function PLUGIN:Think( curTime )
		if ( !self.lastTick ) then
			self.lastTick = 0;
		end;

		if ( greenCode.Client:HasInitialized() and curTime > self.lastTick ) then
			greenCode.Client.gcLocation = self:GetLocation( greenCode.Client:GetShootPos() ) or self:FindByID( greenCode.Client:GetSharedVar( "territory", 0 ) )
			self.lastTick = curTime + 0.3;
		end;
	end;

	greenCode.datastream:Hook( "gcTerritorySync", function( tData )
		for _, tTerritoryData in pairs( tData ) do
			local TERRITORY = TERRITORY_CLASS:New( tTerritoryData );

			if TERRITORY:Register() then
				print( "Registered territory ["..TERRITORY:UniqueID().."]["..TERRITORY:Name().."]" );
			elseif( PLUGIN:FindByID( tTerritoryData.uid ) ) then
				TERRITORY = PLUGIN:FindByID( tTerritoryData.uid );
				TERRITORY.data = tTerritoryData;
				print( "Update territory ["..TERRITORY:UniqueID().."]["..TERRITORY:Name().."]" );
			end;
		end;

		hook.Call("OnTerritoryDataReceive", GAMEMODE);
	end);

	greenCode.datastream:Hook( "gcTerritoryClean", function()
		RunConsoleCommand("cl_gc_ter_clean");
	end);

	greenCode.datastream:Hook( "gcTerritoryData", function( tData )
		local TERRITORY = PLUGIN:FindByID( tData.uid );

		if ( !TERRITORY or !TERRITORY:IsValid() ) then
			RunConsoleCommand( "gc_ter_update", tData.uid );
		else
			TERRITORY:SetData( tData.key, tData.value );
			hook.Call("OnTerritoryDataReceive", GAMEMODE);
		end;
	end);

	greenCode.datastream:Hook( "gcTerritoryRemove", function( tData )
		PLUGIN.stored[ tData.uid ] = nil;
		hook.Call("OnTerritoryDataReceive", GAMEMODE);
	end);

	local Mat = Material("effects/laser_tracer");

	function PLUGIN:RenderScreenspaceEffects()
		local nSize = 5;
		local bShouldDraw;
		local bConfig = greenCode.config:Get("draw_territory"):GetBool();

		for key, TERRITORY in pairs( self.stored ) do
			local tCords = TERRITORY:GetCords();

			if ( tCords ) then
				local nCount  = #tCords;
				local nVertex = TERRITORY:GetVertex();
				local сСolor  = TERRITORY:GetColor();
				local vCenter = TERRITORY:GetCenter();
				
				bShouldDraw = greenCode.plugin:Call( "OnTerritoryDraw", TERRITORY, tCords, nVertex, bDraw ) or bConfig;

				if ( !bShouldDraw ) then continue; end;
				
				cam.Start3D(EyePos(), EyeAngles());
					render.SetMaterial( Mat );
					for i, vPos1 in pairs( tCords ) do
						local vPos2 = tCords[i+1] or tCords[1];
											
						render.DrawBeam( vCenter,  vCenter + Vector(0,0, nVertex), nSize, 0.25, 0.75, сСolor);
						render.DrawBeam( vPos1,  vPos1 + Vector(0,0, nVertex), nSize, 0.25, 0.75, сСolor );
						render.DrawBeam( vPos1, vPos2, nSize, 0.25, 0.75, сСolor );
						render.DrawBeam( vPos1 + Vector(0,0, nVertex), vPos2 + Vector(0,0, nVertex), nSize, 0.25, 0.75, сСolor );
						
						//local IDPos = vPos1:ToScreen();
						//draw.DrawText( i, "gcMainText", IDPos.x, IDPos.y - nVertex / 2, сСolor, 1);
					end;
				cam.End3D();
			end;
		end;
	end;
end;

if SERVER then
	greenCode.command:Add( "ter_update", 0, function( player, command, args )
		if ( !player.gcLastTerritorySync ) then
			player.gcLastTerritorySync = 0;
		end;

		if ( player.gcLastTerritorySync < CurTime() ) then
			PLUGIN:SendData( tonumber(args[1]) or -1, player );
			player.gcLastTerritorySync = CurTime() + 30;
		end;
	end);

else
	greenCode.command:Add( "ter_clean", 0, function( player, command, args )
		PLUGIN.stored = {};
		table.Empty( PLUGIN.buffer );
	end);
end;