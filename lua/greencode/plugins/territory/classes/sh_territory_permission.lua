--[[ Define the territory permission class metatable. --]]
TERRITORY_PERMISSION_CLASS = TERRITORY_PERMISSION_CLASS or {__index = TERRITORY_PERMISSION_CLASS};

function TERRITORY_PERMISSION_CLASS:__call( parameter, failSafe )
	return self:Query( parameter, failSafe );
end;

function TERRITORY_PERMISSION_CLASS:__tostring()
	return "Territory perm ["..self("name").."]";
end;

function TERRITORY_PERMISSION_CLASS:IsValid()
	return self.data != nil;
end;

function TERRITORY_PERMISSION_CLASS:Query( key, failSafe )
	if ( self.data and self.data[key] != nil ) then
		return self.data[key];
	else
		return failSafe;
	end;
end;

function TERRITORY_PERMISSION_CLASS:GetName() return self( "name", "Unknown" ); end;
TERRITORY_PERMISSION_CLASS.Name = TERRITORY_PERMISSION_CLASS.GetName;
function TERRITORY_PERMISSION_CLASS:GetDescription() return self( "desc", "Unknown" ); end;
function TERRITORY_PERMISSION_CLASS:GetDefault() return self( "default", false ); end;
function TERRITORY_PERMISSION_CLASS:Register() return gc.plugin.stored["Territory"].PERMISSION:Register( self ); end;

function TERRITORY_PERMISSION_CLASS:New( tMergeTable )
	local object = { 
			data = {
				name = "Unknown",
				desc = "Unknown",
				default = false
			}
		};

		if ( tMergeTable ) then
			table.Merge( object.data, tMergeTable );
		end;

		setmetatable( object, self );
		self.__index = self;
	return object;
end;