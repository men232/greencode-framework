--[[ Define the territory permission class metatable. --]]
TERRITORY_CHARTER_CLASS = TERRITORY_CHARTER_CLASS or {__index = TERRITORY_CHARTER_CLASS};

function TERRITORY_CHARTER_CLASS:__call( parameter, failSafe )
	return self:Query( parameter, failSafe );
end;

function TERRITORY_CHARTER_CLASS:__tostring()
	return "Territory charter ["..self("name").."]["..self("priority").."]";
end;

function TERRITORY_CHARTER_CLASS:IsValid()
	return self.data != nil;
end;

function TERRITORY_CHARTER_CLASS:Query( key, failSafe )
	if ( self.data and self.data[key] != nil ) then
		return self.data[key];
	else
		return failSafe;
	end;
end;

function TERRITORY_CHARTER_CLASS:GetName() return self( "name", "Unknown" ); end;
TERRITORY_CHARTER_CLASS.Name = TERRITORY_CHARTER_CLASS.GetName;
function TERRITORY_CHARTER_CLASS:StoreID() return self( "storeID", "UniqueID" ); end;
function TERRITORY_CHARTER_CLASS:GetPriority() return self( "priority", 1 ); end;
function TERRITORY_CHARTER_CLASS:GetType() return self( "type", "number" ); end;
function TERRITORY_CHARTER_CLASS:Register() return gc.plugin.stored["Territory"].CHARTER:Register( self ); end;
function TERRITORY_CHARTER_CLASS:GetPlayerSID( player )
	local SID;
	if ( type( player ) == "Player" and player[ self:StoreID() ] ) then
		SID = player[ self:StoreID() ]( player );
	else
		SID = player;
	end;

	if ( SID != nil ) then
		local _type = self:GetType();

		if ( _type == "int" or _type == "number" ) then
			SID = tonumber( SID );
		elseif ( _type == "string" ) then
			SID = tostring( SID );
		end;

		return SID;
	end;
end;

function TERRITORY_CHARTER_CLASS:New( tMergeTable )
	local object = { 
			data = {
				name = "Unknown",
				storeID = "UniqueID",
				type = "number",
				priority = 1
			}
		};

		if ( tMergeTable ) then
			table.Merge( object.data, tMergeTable );
		end;

		setmetatable( object, self );
		self.__index = self;
	return object;
end;