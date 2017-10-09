local greenCode = greenCode;
local table     = table;
local pairs     = pairs;

--[[ Define the territory class metatable. --]]
TERRITORY_CLASS = TERRITORY_CLASS or {__index = TERRITORY_CLASS};

function TERRITORY_CLASS:__call( parameter, failSafe )
	return self:Query( parameter, failSafe );
end;

function TERRITORY_CLASS:__tostring()
	return "TERRITORY ["..self("uid").."]["..self("name").."]";
end;

function TERRITORY_CLASS:IsValid()
	return self.data != nil;
end;

function TERRITORY_CLASS:Query( key, failSafe )
	if ( self.data and self.data[key] != nil ) then
		return self.data[key];
	else
		return failSafe;
	end;
end;

function TERRITORY_CLASS:SetData( key, value )
	if ( self:IsValid() and self.data[key] != nil ) then
		self.data[key] = value;
		greenCode.plugin:Call( "OnTerrytoryChangeData", self, key, value );
		return true;
	end;
end;

function TERRITORY_CLASS:GetPlayerData( uid )
	if ( self:IsValid() ) then
		return self("plyData", {})[uid];
	end;
end;

function TERRITORY_CLASS:SetPlayerData( uid, tData )
	if ( self:IsValid() ) then
		 local tPlayerData = self("plyData", {});
			tPlayerData[uid] = tData;
		self:SetData("plyData", tPlayerData);
	end;
end;

function TERRITORY_CLASS:IsInside( vPointPosition )
	if ( self:IsValid() and vPointPosition ) then
		return greenCode.math:IsInPolygon( vPointPosition, self:GetCords(), self( "vertex", 150 ) );
	else
		return false;
	end;
end;

function TERRITORY_CLASS:AddCord( vPosition )
	if ( self:IsValid() ) then
		table.insert( self.data.cords, vPosition );
		greenCode.plugin:Call( "OnTerrytoryChangeData", self, "cords", vPosition );
		return true;
	end;
end;

function TERRITORY_CLASS:RemoveCord( nCordID )
	if ( self:IsValid() and self.data.cords[ nCordID ] ) then
		self.data.cords[ nCordID ] = nil;
		table.ClearKeys( self.data.cords );
		greenCode.plugin:Call( "OnTerrytoryChangeData", self, "cords", nil );
		return true;
	end;
end;

function TERRITORY_CLASS:Remove()
	local PLUGIN  = gc.plugin.stored["Territory"];

	if ( self:IsValid() and PLUGIN and PLUGIN.stored[ self("uid") ] ) then
		local uid = self("uid");
		local name = self("name");

		PLUGIN.stored[ uid ] = nil;
		greenCode.plugin:Call( "OnTerrytoryRemove", uid, name );
		return true;
	end;
end;

function TERRITORY_CLASS:GetName() return self( "name", "Unknown" ); end;
TERRITORY_CLASS.Name = TERRITORY_CLASS.GetName;
function TERRITORY_CLASS:UniqueID() return self( "uid", -1 ); end;
function TERRITORY_CLASS:GetColor() return self( "color", Color(255,255,255,255) ); end;
function TERRITORY_CLASS:GetCords() return self( "cords", {} ); end;
function TERRITORY_CLASS:GetPerm() return self( "permissions", {} ); end;
function TERRITORY_CLASS:IsGlobal() return self( "global", false ); end;
function TERRITORY_CLASS:GetCenter() return greenCode.math:GetPolygonCenter( self:GetCords() ); end;
function TERRITORY_CLASS:GetVertex() return self("vertex", 150); end;

function TERRITORY_CLASS:SetName( sNewName ) return self:SetData( "name", sNewName ); end;
function TERRITORY_CLASS:SetColor( cNewColor ) return self:SetData( "color", cNewColor ); end;
function TERRITORY_CLASS:SetGlobal( bGlobal ) return self:SetData( "global", bGlobal ); end;
function TERRITORY_CLASS:Register() return gc.plugin.stored["Territory"]:RegisterTerritory( self ); end;

function TERRITORY_CLASS:SetPermission( sCharterName, sPermissionName, player, bValue, nTime  )
	local PLUGIN  = gc.plugin.stored["Territory"];
	local PERM    = PLUGIN.PERMISSION:FindByID( sPermissionName );
	local CHARTER = PLUGIN.CHARTER:FindByID( sCharterName );

	if ( !PERM or !PERM:IsValid() ) then
		return false, "Permission is not valid.";
	elseif ( !CHARTER or !CHARTER:IsValid() ) then
		return false, "Charter is not valid.";
	end;

	local tPermissions = self:GetPerm();

	if ( !tPermissions[ sCharterName ] ) then
		tPermissions[ sCharterName ] = {};
	end;

	local sessionID, sessionName, SID;

	if ( CHARTER:StoreID() != 0 ) then
		SID = CHARTER:GetPlayerSID( player );

		if ( !tPermissions[ sCharterName ][ SID ] ) then
			tPermissions[ sCharterName ][ SID ] = {};
		end;

		sessionName = sCharterName.."_"..SID.."_"..sPermissionName.."_"..self:UniqueID();
		tPermissions[ sCharterName ][ SID ][ sPermissionName ] = bValue;
	else
		sessionName = sCharterName.."_"..sPermissionName.."_"..self:UniqueID();
		tPermissions[ sCharterName ][ sPermissionName ] = bValue;
	end;

	sessionID = tonumber(util.CRC(sessionName));
	local SESSION = greenCode.session:FindByID( sessionID );
	local bSessionIsExist = (SESSION and SESSION:IsValid());

	if ( (!nTime or !bValue) and bSessionIsExist ) then
		SESSION:Close( nil, "Permission change to false or time not set", false );
	elseif ( nTime and !bSessionIsExist ) then
		SESSION = SESSION_CLASS:New{
			uid = sessionID,
			name = sessionName,
			timeout = nTime,
			territoryData = { uid = self:UniqueID(), charter = sCharterName, permission = sPermissionName, sid = SID },
			returnValue = !bValue
		}:Register();
	elseif ( nTime and bSessionIsExist ) then
		SESSION:SetTimeOut(nTime);
		SESSION:SetData("returnValue", !bValue);
	end;

	greenCode.plugin:Call("OnTerritoryChangePermission", self, sPermissionName, sCharterName, player, bValue );

	return true, "All done :)", SESSION;
end;

function TERRITORY_CLASS:GetPermission( sPermissionName, player, bDefault )
	local bSuccess, sMsg = greenCode.plugin:Call("OnTerritoryGetPermission", self, sPermissionName, player );

	if ( bSuccess != nil ) then
		return bSuccess, sMsg or "Pre getting return value.";
	end;

	local PLUGIN       = gc.plugin.stored["Territory"];
	local PERM         = PLUGIN.PERMISSION:FindByID( sPermissionName );

	if ( !PERM or !PERM:IsValid() ) then
		return bDefault or false, "Permission is not valid.";
	end;

	local tPermissions = self:GetPerm();
	local tCharter     = PLUGIN.CHARTER:SortByPriority();

	local bSuccess;

	for nPriority = 1, #tCharter do
		for sCharterName, CHARTER in pairs( tCharter[ nPriority ] ) do
			if ( CHARTER:StoreID() != 0 ) then
				local SID = CHARTER:GetPlayerSID( player );

				bSuccess = ( tPermissions[ sCharterName ][ SID ] or {} )[ sPermissionName ];
			else
				bSuccess = tPermissions[ sCharterName ][ sPermissionName ];
			end;

			if ( bSuccess != nil ) then
				return bSuccess, nPriority, sCharterName;
			end;
		end;
	end;

	if ( bDefault != nil ) then
		return bDefault;
	else
		return PERM:GetDefault();
	end;
end;

function TERRITORY_CLASS:New( tMergeTable )
	local object = { 
			data = {
				uid = -1;
				name = "Unknown",
				cords = {},
				vertex = 150,
				color = Color(math.random(0,255), math.random(0,255), math.random(0,255), 255),
				global = false,
				permissions = {},
				plyData = {}
			}
		};

		greenCode.plugin:Call( "OnTerrytoryCreate", object.data );

		if ( tMergeTable ) then
			table.Merge( object.data, tMergeTable );
		end;

		setmetatable( object, self );
		self.__index = self;
	return object;
end;