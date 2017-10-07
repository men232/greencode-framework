--[[
	© 2013 GmodLive private project do not share
	without permission of its author (Andrew Mensky vk.com/men232).
--]]

local greenCode = greenCode;
local table     = table;

local PLUGIN        = PLUGIN or greenCode.plugin:Loader();
local TER_PLUGIN    = greenCode.plugin:FindByID("territory");
local CATEGORY_NAME = "Territory";

if ( !TER_PLUGIN ) then
	PLUGIN_LOAD_ERROR_MSG = "Territory plug-in not found.";
	PLUGIN_LOAD_ERROR = true;
	return;
end;

function PLUGIN.Add( calling_ply, sName )
	local sLowName = string.utf8lower(sName);

	for uid, TERRITORY in pairs( TER_PLUGIN.stored ) do
		if ( string.utf8lower(TERRITORY:Name()) == sLowName ) then
			ULib.tsayError( calling_ply, "Name has been taken.", true );
			return;
		end;
	end;

	local TERRITORY = TERRITORY_CLASS:New( { uid = tonumber( greenCode.kernel:GetShortCRC("gc_"..os.time().."_territory_"..sName) ), name = sLowName } );
	
	if ( TERRITORY:Register() ) then
		ulx.fancyLogAdmin( calling_ply, "#A create new territory #s, unique id #s.", TERRITORY:GetName(), TERRITORY:UniqueID() );
	else
		ULib.tsayError( calling_ply, "Somting wrong.", true );
	end;
end;

local cmd = ulx.command( CATEGORY_NAME, "gc territory add", PLUGIN.Add );
cmd:addParam{ type=ULib.cmds.StringArg, hint="name" };
cmd:defaultAccess( ULib.ACCESS_SUPERADMIN );
cmd:help( "Add new territory." );

function PLUGIN.Remove( calling_ply, uid )
	local TERRITORY = TER_PLUGIN:FindByID( tonumber(uid) ) or TER_PLUGIN:FindByName( uid );

	if ( TERRITORY and TERRITORY:IsValid() ) then
		local sTerritoryName = TERRITORY:Name();

		if ( TERRITORY:Remove() ) then
			ulx.fancyLogAdmin( calling_ply, "#A remove territory #s, unique id #s.", sTerritoryName, tostring(uid) );
		else
			ULib.tsayError( calling_ply, "Somting wrong.", true );
		end;
	else
		ULib.tsayError( calling_ply, "Territory not fund.", true );
	end;
end;

local cmd = ulx.command( CATEGORY_NAME, "gc territory remove", PLUGIN.Remove );
cmd:addParam{ type=ULib.cmds.StringArg, completes=TER_PLUGIN.DoubleList, hint="uid or name" }
cmd:defaultAccess( ULib.ACCESS_SUPERADMIN );
cmd:help( "Remove territory." );

function PLUGIN.Goto( calling_ply, uid )
	local TERRITORY = TER_PLUGIN:FindByID( tonumber(uid) ) or TER_PLUGIN:FindByName( uid );

	if ( TERRITORY and TERRITORY:IsValid() ) then
		local sTerritoryName = TERRITORY:Name();
		calling_ply:SetPos(TERRITORY:GetCenter());
	else
		ULib.tsayError( calling_ply, "Territory not fund.", true );
	end;
end;

local cmd = ulx.command( CATEGORY_NAME, "gc territory goto", PLUGIN.Goto );
cmd:addParam{ type=ULib.cmds.StringArg, completes=TER_PLUGIN.DoubleList, hint="uid or name" }
cmd:defaultAccess( ULib.ACCESS_SUPERADMIN );
cmd:help( "Goto to territory." );

function PLUGIN.CleanPerm( calling_ply, uid, sCharterName )
	local TERRITORY = TER_PLUGIN:FindByID( tonumber(uid) ) or TER_PLUGIN:FindByName( uid );

	local TERRITORY;
	if ( uid == "^" ) then
		TERRITORY = TER_PLUGIN:GetLocation( calling_ply:GetShootPos() );
	elseif ( uid == "*" ) then
		for uid, TERRITORY in pairs( TER_PLUGIN.stored ) do
			PLUGIN.CleanPerm( calling_ply, TERRITORY:UniqueID(), sCharterName );
		end;
		
		return;
	else
		TERRITORY = TER_PLUGIN:FindByID( tonumber(uid) ) or TER_PLUGIN:FindByName( uid );
	end;
		
	if ( TERRITORY and TERRITORY:IsValid() ) then
		local tPermData = TERRITORY:GetPerm();
			tPermData[sCharterName] = {};
		if ( sCharterName == "private" ) then
			TERRITORY.data.permissions = tPermData;
			TERRITORY.data["owner"] = {};
			TERRITORY.data["coowner"] = {};
			TERRITORY.data["propSpawn"] = {};
			TERRITORY.data["ownerSession"] = 0;
			TERRITORY.data["_rent"] = 0;
			TERRITORY.data["lastBuyType"] = "";
		end;
		TER_PLUGIN:Save( TERRITORY:UniqueID() );
		TER_PLUGIN:SendData( TERRITORY:UniqueID(), true );
		
		ulx.fancyLogAdmin( calling_ply, "#A clean territory perm: #s > #s", TERRITORY:Name(), sCharterName );
	else
		ULib.tsayError( calling_ply, "Territory '"..uid.."'' not fund.", true );
	end;
end;

local cmd = ulx.command( CATEGORY_NAME, "gc territory cleanperm", PLUGIN.CleanPerm );
cmd:addParam{ type=ULib.cmds.StringArg, completes=TER_PLUGIN.DoubleList, hint="uid or name" }
cmd:addParam{ type=ULib.cmds.StringArg, completes=TER_PLUGIN.CHARTER.buffer, hint="charter", error="invalid charter \"%s\" specified", ULib.cmds.restrictToCompletes }
cmd:defaultAccess( ULib.ACCESS_SUPERADMIN );
cmd:help( "Goto to territory." );

function PLUGIN.AddCord( calling_ply, uid, vPosition )
	vPosition       = vPosition != "0" and greenCode.kernel:CovertValue( vPosition, "vector" ) or calling_ply:GetPos();
	local TERRITORY = TER_PLUGIN:FindByID( tonumber(uid) ) or TER_PLUGIN:FindByName( uid );

	if ( TERRITORY and TERRITORY:IsValid() ) then
		if ( TERRITORY:AddCord( vPosition ) ) then
			ulx.fancyLogAdmin( calling_ply, "#A add #s cord to territory #s, position: #s.", #TERRITORY:GetCords(), TERRITORY:Name(), tostring(vPosition) );
			
			undo.Create("Territory_Cords")
				undo.SetPlayer( calling_ply )
				undo.AddFunction(function(undo)			
					if ( TERRITORY and TERRITORY:IsValid() ) then
						PLUGIN.RemoveCord( calling_ply, TERRITORY:UniqueID(), #TERRITORY:GetCords() );
					end;
				end)
			undo.Finish()
		else
			ULib.tsayError( calling_ply, "Somting wrong.", true );
		end;
	else
		ULib.tsayError( calling_ply, "Territory not fund.", true );
	end
end;

function PLUGIN.SetPermission( calling_ply, target_ply, uid, sCharterName, sPermissionName, bValue, nTime, bNoMessage )
	local TERRITORY;
	if ( uid == "^" ) then
		TERRITORY = TER_PLUGIN:GetLocation( calling_ply:GetShootPos() );
	elseif ( uid == "*" ) then
		for uid, TERRITORY in pairs( TER_PLUGIN.stored ) do
			PLUGIN.SetPermission( calling_ply, target_ply, TERRITORY:UniqueID(), sCharterName, sPermissionName, bValue, nTime, true );
		end;
		return;
	else
		TERRITORY = TER_PLUGIN:FindByID( tonumber(uid) ) or TER_PLUGIN:FindByName( uid );
	end;
	
	local nTime = nTime != 0 and nTime or nil;

	if ( TERRITORY and TERRITORY:IsValid() ) then
		if (bValue > 0) then bValue = true elseif (bValue == 0) then bValue = false; else bValue = nil; end;
		local bSuccess, sMsg, SESSION = TERRITORY:SetPermission( sCharterName, sPermissionName, target_ply, bValue, nTime and (nTime*1) or nil );

		if ( bSuccess ) then
			local CHARTER = TER_PLUGIN.CHARTER:FindByID( sCharterName );
			local SID = CHARTER:GetPlayerSID( target_ply );

			if ( !SID ) then
				ulx.fancyLogAdmin( calling_ply, "#A set territory perm: #s > #s > #s = #s.", TERRITORY:Name(), sCharterName, sPermissionName, bValue );
			else
				ulx.fancyLogAdmin( calling_ply, "#A set territory perm: #s > #s > #s > #s = #s.", TERRITORY:Name(), sCharterName, sPermissionName, SID, bValue );
			end;

			return true;
		else
			ULib.tsayError( calling_ply, sMsg, true );
		end;
	else
		ULib.tsayError( calling_ply, "Territory '"..uid.."'' not fund.", true );
	end;
end;

local cmd = ulx.command( CATEGORY_NAME, "gc territory permission", PLUGIN.SetPermission )
cmd:addParam{ type=ULib.cmds.PlayerArg }
cmd:addParam{ type=ULib.cmds.StringArg, completes=TER_PLUGIN.DoubleList, hint="uid or name" }
cmd:addParam{ type=ULib.cmds.StringArg, completes=TER_PLUGIN.CHARTER.buffer, hint="charter", error="invalid charter \"%s\" specified", ULib.cmds.restrictToCompletes }
cmd:addParam{ type=ULib.cmds.StringArg, completes=TER_PLUGIN.PERMISSION.buffer, hint="permission", error="invalid permission \"%s\" specified", ULib.cmds.restrictToCompletes }
cmd:addParam{ type=ULib.cmds.NumArg, min=-1, max=1, default=0, hint="Allow", ULib.cmds.optional, ULib.cmds.round }
cmd:addParam{ type=ULib.cmds.NumArg, min=-1, max=2^32/2-1, hint="Time in min", ULib.cmds.round, ULib.cmds.optional }
cmd:defaultAccess( ULib.ACCESS_ADMIN )
cmd:help( "Set global territory permission." )

local cmd = ulx.command( CATEGORY_NAME, "gc territory addcord", PLUGIN.AddCord )
cmd:addParam{ type=ULib.cmds.StringArg, completes=TER_PLUGIN.DoubleList, hint="uid or name" }
cmd:addParam{ type=ULib.cmds.StringArg, hint="position" }
cmd:defaultAccess( ULib.ACCESS_SUPERADMIN )
cmd:help( "Add territory cord." )

function PLUGIN.RemoveCord( calling_ply, uid, nID )
	local TERRITORY = TER_PLUGIN:FindByID( tonumber(uid) ) or TER_PLUGIN:FindByName( uid );

	if ( TERRITORY and TERRITORY:IsValid() ) then
		if ( TERRITORY:RemoveCord( nID ) ) then
			ulx.fancyLogAdmin( calling_ply, "#A remove #s cord to territory #s.", nID, TERRITORY:Name() );
		else
			ULib.tsayError( calling_ply, "Somting wrong.", true );
		end
	else
		ULib.tsayError( calling_ply, "Territory not fund.", true );
	end;
end;

local cmd = ulx.command( CATEGORY_NAME, "gc territory removecord", PLUGIN.RemoveCord )
cmd:addParam{ type=ULib.cmds.StringArg, completes=TER_PLUGIN.DoubleList, hint="uid or name" }
cmd:addParam{ type=ULib.cmds.NumArg, min=1, default=1, hint="cord id", ULib.cmds.optional, ULib.cmds.round }
cmd:defaultAccess( ULib.ACCESS_SUPERADMIN )
cmd:help( "Remove territory cord." )

function PLUGIN.SetData( calling_ply, uid, key, value )
	local TERRITORY;
	if ( uid == "^" ) then
		TERRITORY = TER_PLUGIN:GetLocation( calling_ply:GetShootPos() );
	else
		TERRITORY = TER_PLUGIN:FindByID( tonumber(uid) ) or TER_PLUGIN:FindByName( uid );
	end;

	if ( TERRITORY and TERRITORY:IsValid() ) then
		local sType = type( TERRITORY(key) );

		if ( key == "color" ) then sType = "color";	end;

		value = greenCode.kernel:CovertValue( value, sType );

		if ( type( value ) == sType or ( key == "color" and type( value ) == "table" ) ) then
			TERRITORY:SetData( key, value );
			ulx.fancyLogAdmin( calling_ply, "#A set data #s = #s to territory #s.", key, tostring(value), TERRITORY:Name() );
		else
			ULib.tsayError( calling_ply, "Type conversion error.", true );
			return;
		end;
	else
		ULib.tsayError( calling_ply, "Territory not fund.", true );
	end;
end;

local cmd = ulx.command( CATEGORY_NAME, "gc territory data", PLUGIN.SetData )
cmd:addParam{ type=ULib.cmds.StringArg, completes=TER_PLUGIN.DoubleList, hint="name or uid" }
cmd:addParam{ type=ULib.cmds.StringArg, hint="key" }
cmd:addParam{ type=ULib.cmds.StringArg, hint="value" }
cmd:defaultAccess( ULib.ACCESS_SUPERADMIN )
cmd:help( "Set territory data." )

-- A command to save territory data.
function PLUGIN.Save( calling_ply )
	TER_PLUGIN:Save();
	ulx.fancyLogAdmin( calling_ply, "#A saved territory data for #s map.", game.GetMap() );
end;

local cmd = ulx.command( CATEGORY_NAME, "gc territory save", PLUGIN.Save )
cmd:defaultAccess( ULib.ACCESS_SUPERADMIN )
cmd:help( "Save territory data." )

-- A command to save territory data.
function PLUGIN.Load( calling_ply )
	TER_PLUGIN:Load()
	ulx.fancyLogAdmin( calling_ply, "#A loaded territory data for #s map.", game.GetMap() );
end;

local cmd = ulx.command( CATEGORY_NAME, "gc territory load", PLUGIN.Load )
cmd:defaultAccess( ULib.ACCESS_SUPERADMIN )
cmd:help( "Save territory data." )

-- A command to save territory data.
function PLUGIN.RemoveOwners( calling_ply, sName )
	local TERRITORY = TER_PLUGIN:FindByID(tonumber(sName)) or TER_PLUGIN:FindByName(sName);

	if ( TERRITORY and TERRITORY:IsValid() ) then
		TERRITORY:RemoveAllOwners();
		ulx.fancyLogAdmin( calling_ply, "#A remove all owners from #s (#s) territory.", TERRITORY:Name(), tostring(TERRITORY:UniqueID()) );
	else
		ULib.tsayError( calling_ply, "Territory not fund.", true );
	end;
end;

local cmd = ulx.command( CATEGORY_NAME, "gc territory removeowners", PLUGIN.RemoveOwners )
cmd:addParam{ type=ULib.cmds.StringArg, completes=TER_PLUGIN.DoubleList, hint="name or uid" }
cmd:defaultAccess( ULib.ACCESS_ADMIN )
cmd:help( "Remove all territory owners." )

-- A command to save territory data.
function PLUGIN.Optim( calling_ply )
	for uid, TERRITORY in pairs( TER_PLUGIN.stored ) do
		-- Z optimization.
		local tCords = TERRITORY:GetCords();

		for k, cord in pairs( tCords ) do
			tCords[k] = Vector(cord[1], cord[2], tCords[1][3]);
		end;

		TERRITORY:SetData("cords", tCords);
	end;
end;

local cmd = ulx.command( CATEGORY_NAME, "gc territory optim", PLUGIN.Optim )
cmd:defaultAccess( ULib.ACCESS_ADMIN )
cmd:help( "Optimization territory." )

-- A command to save territory data.
function PLUGIN.AddZ( calling_ply, sName, nAmount )
	local bDone, sReason;
	local TERRITORY = TER_PLUGIN:FindByID(tonumber(sName)) or TER_PLUGIN:FindByName(sName);

	if ( TERRITORY and TERRITORY:IsValid() ) then
		local tCords = TERRITORY:GetCords();

		for k, cord in pairs( tCords ) do
			tCords[k] = Vector(cord[1], cord[2], cord[3] + nAmount);
		end;

		TERRITORY:SetData("cords", tCords);
	else
		bDone, sReason = false, "Territory not fund."
	end;

	if ( bDone ) then
		ulx.fancyLogAdmin( calling_ply, "#A change territory price [#s (#s)] = #s).", TERRITORY:Name(), sPriceTypy, tostring(nAmount) );
	else
		ULib.tsayError( calling_ply, sReason, true );
	end;
end;

local cmd = ulx.command( CATEGORY_NAME, "gc territory addz", PLUGIN.AddZ )
cmd:addParam{ type=ULib.cmds.StringArg, completes=TER_PLUGIN.DoubleList, hint="name or uid" }
cmd:addParam{ type=ULib.cmds.NumArg, default=0, hint="amount", ULib.cmds.optional, ULib.cmds.round }
cmd:defaultAccess( ULib.ACCESS_ADMIN )
cmd:help( "Optimization territory." )

-- A command to save territory data.
function PLUGIN.Price( calling_ply, uid, nAmount1, nAmount2, nAmount3 )
	local bDone, sReason;
	local TERRITORY;
	if ( uid == "^" ) then
		TERRITORY = TER_PLUGIN:GetLocation( calling_ply:GetShootPos() );
	else
		TERRITORY = TER_PLUGIN:FindByID( tonumber(uid) ) or TER_PLUGIN:FindByName( uid );
	end;
	
	if ( TERRITORY and TERRITORY:IsValid() ) then
		bDone, sReason = TERRITORY:SetPrice("rent", nAmount1);
		bDone, sReason = TERRITORY:SetPrice("session", nAmount2);
		bDone, sReason = TERRITORY:SetPrice("perm", nAmount3);
	else
		bDone, sReason = false, "Territory not fund."
	end;

	if ( bDone ) then
		ulx.fancyLogAdmin( calling_ply, "#A change territory '#s' price [#s, #s, #s]).", TERRITORY:Name(), tostring(nAmount1), tostring(nAmount2), tostring(nAmount3) );
	else
		ULib.tsayError( calling_ply, sReason, true );
	end;
end;

local cmd = ulx.command( CATEGORY_NAME, "gc territory price", PLUGIN.Price )
cmd:addParam{ type=ULib.cmds.StringArg, completes=TER_PLUGIN.DoubleList, hint="name or uid" }
//cmd:addParam{ type=ULib.cmds.StringArg, hint="price type" }
cmd:addParam{ type=ULib.cmds.NumArg, min=1, default=1, hint="amount", ULib.cmds.optional, ULib.cmds.round }
cmd:addParam{ type=ULib.cmds.NumArg, min=1, default=1, hint="amount", ULib.cmds.optional, ULib.cmds.round }
cmd:addParam{ type=ULib.cmds.NumArg, min=1, default=1, hint="amount", ULib.cmds.optional, ULib.cmds.round }
cmd:defaultAccess( ULib.ACCESS_ADMIN )
cmd:help( "Remove all territory owners." )

-- A command to set territory data.
function PLUGIN.Info( calling_ply )
	local TERRITORY = TER_PLUGIN:GetLocation( calling_ply:GetPos() );
	
	if ( TERRITORY and TERRITORY:IsValid() ) then
		ULib.console( calling_ply, "\t" .. TERRITORY:Name() .. " | "..TERRITORY:UniqueID()..":" );
		for sCharter, value in pairs( TERRITORY:GetPerm() ) do
			ULib.console( calling_ply, "\t\t" .. string.upper( sCharter ) .. ":" );

			for name, value in pairs( value ) do
				if ( type( value ) == "table" ) then
					local SESSION = greenCode.session:FindByID(tonumber(name) or 0);
					if ( SESSION and SESSION:IsValid() ) then
						name = SESSION:Name().." ("..name..")";
					end;

					ULib.console( calling_ply, "\t\t\t" .. name .. ":" );
					
					for name, v in pairs(value) do
						ULib.console( calling_ply, "\t\t\t\t" .. name .. " = " .. tostring(v) );
					end;
				else
					ULib.console( calling_ply, "\t\t\t" .. name .. " = " .. tostring(value) );
				end;
			end;
		end;

		ULib.console( calling_ply, "\tYOUR:" );
		for _, sPermissionName in pairs( TER_PLUGIN.PERMISSION.buffer ) do
			ULib.console( calling_ply, "\t\t" .. sPermissionName .. " = " .. tostring( TERRITORY:GetPermission( sPermissionName, calling_ply, false )) );
		end;

		ULib.console( calling_ply, "\tCUSTOM:" );
		greenCode.plugin:Call( "OnTerritoryPrintInfo", calling_ply, TERRITORY );
	else
		ULib.tsayError( calling_ply, "Where are you?", true );
	end;
end;

local cmd = ulx.command( CATEGORY_NAME, "gc territory info", PLUGIN.Info )
cmd:defaultAccess( ULib.ACCESS_ALL )
cmd:help( "Get territory info." )