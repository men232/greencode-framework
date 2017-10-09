--[[
	© 2013 GmodLive private project do not share
	without permission of its author (Andrew Mensky vk.com/men232).
--]]

local greenCode = greenCode;
local tonumber = tonumber;
local tostring = tostring;
local IsValid = IsValid;
local pairs = pairs;
local pcall = pcall;
local type = type;
local string = string;
local table = table;
local game = game;

greenCode.config = greenCode.config or greenCode.kernel:NewLibrary("Config");
greenCode.config.indexes = greenCode.config.indexes or {};
greenCode.config.stored = greenCode.config.stored or {};
greenCode.config.cache = {};

--[[ Set the __index meta function of the class. --]]
local CLASS_TABLE = {__index = CLASS_TABLE};

-- Called when the config is invoked as a function.
function CLASS_TABLE:__call(parameter, failSafe)
	return self:Query(parameter, failSafe);
end;

-- Called when the config is converted to a string.
function CLASS_TABLE:__tostring()
	return "CONFIG["..self.key.."]";
end;

-- A function to create a new config object.
function CLASS_TABLE:Create(key)
	local config = greenCode.kernel:NewMetaTable(CLASS_TABLE);
		config.data = greenCode.config.stored[key];
		config.key = key;
	return config;
end;

-- A function to check if the config is valid.
function CLASS_TABLE:IsValid()
	return self.data != nil;
end;

-- A function to query the config.
function CLASS_TABLE:Query(key, failSafe)
	if (self.data and self.data[key] != nil) then
		return self.data[key];
	else
		return failSafe;
	end;
end;

-- A function to get the config's value as a boolean.
function CLASS_TABLE:GetBool(failSafe)
	if (self.data) then
		return (self.data.value == true or self.data.value == "true"
		or self.data.value == "yes" or self.data.value == "1" or self.data.value == 1);
	elseif (failSafe != nil) then
		return failSafe;
	else
		return false;
	end;
end;

-- A function to get a config's value as a number.
function CLASS_TABLE:GetInt(failSafe)
	if (self.data) then
		return tonumber(self.data.value) or failSafe or 0;
	else
		return failSafe or 0;
	end;
end;

-- A function to get a config's value as a string.
function CLASS_TABLE:GetString(failSafe)
	if (self.data) then
		return tostring(self.data.value);
	else
		return failSafe or "";
	end;
end;

-- A function to get a config's default value.
function CLASS_TABLE:GetDefault(failSafe)
	if (self.data) then
		return self.data.default;
	else
		return failSafe;
	end;
end;

-- A function to get the config's next value.
function CLASS_TABLE:GetNext(failSafe)
	if (self.data and self.data.nextValue != nil) then
		return self.data.nextValue;
	else
		return failSafe;
	end;
end;

-- A function to get the config's value.
function CLASS_TABLE:Get(failSafe)
	if (self.data and self.data.value != nil) then
		return self.data.value;
	else
		return failSafe;
	end;
end;

-- A function to set the config's value.
function CLASS_TABLE:Set(value, forceSet)
	if ( tostring(value) == "-1.#IND" ) then
		value = 0;
	end;
	
	if ( self.data and gc.config:IsValidValue(value) ) then
		if ( self.data.value != value ) then
			local previousValue = self.data.value;
			local default = (value == "!default");
			
			if (!default) then
				if (type(self.data.value) == "number") then
					value = tonumber(value) or self.data.value;
				elseif (type(self.data.value) == "boolean") then
					value = (value == true or value == "true"
					or value == "yes" or value == "1" or value == 1);
				end;
			else
				value = self.data.default;
			end;

			if (!self.data.isStatic or forceSet) then
				//if ( (!gc.config:HasInitialized() and self.data.value == self.data.default) or forceSet ) then
					self.data.value = value;
				//end;
				
				//if (gc.config:HasInitialized()) then
				//	self.data.temporary = temporary;
				//	self.data.forceSet = forceSet;
				//end;
			end;
			
			if ( self.data.value != previousValue and gc.config:HasInitialized() ) then
				gc.plugin:Call("GreenCodeConfigChanged", self.key, self.data, previousValue, self.data.value);
			end;
		end;
		
		return value;
	end;
end;

-- A function to set whether the config has initialized.
function greenCode.config:SetInitialized(bInitalized)
	self.gcInitialized = bInitalized;
end;

-- A function to get whether the config has initialized.
function greenCode.config:HasInitialized()
	return self.gcInitialized;
end;

-- A function to get whether a config value is valid.
function greenCode.config:IsValidValue(value)
	return type(value) == "string" or type(value) == "number" or type(value) == "boolean";
end;

-- A function to get the stored config.
function greenCode.config:GetStored()
	return self.stored;
end;

-- A function to get a config object.
function greenCode.config:Get(key)
	if (!self.cache[key]) then
		local configObject = CLASS_TABLE:Create(key);
		
		if (configObject.data) then
			self.cache[key] = configObject;
		end;
		
		return configObject;
	else
		return self.cache[key];
	end;
end;

-- A function to add a new config key.
function greenCode.config:Add( key, value, isStatic, isPrivate, needsRestart )
	if (self:IsValidValue(value)) then
		if (!self.stored[key]) then
			self.stored[key] = {
				needsRestart = needsRestart,
				isPrivate = isPrivate,
				isStatic = isStatic,
				default = value,
				value = value
			};
			
			local configObject = CLASS_TABLE:Create(key);

			return configObject;
		end;
	end;
end;

-- A function to import a config file.
function greenCode.config:Import(fileName)
	local data = _file.Read(fileName, "GAME") or "";
	
	for k, v in pairs(string.Explode("\n", data)) do
		if (v != "" and !string.find(v, "^%s$")) then
			if (!string.find(v, "^%[.+%]$") and !string.find(v, "^//")) then
				local class, key, value = string.match(v, "^(.-)%s(.-)%s=%s(.+);");
				
				if (class and key and value) then
					if (string.find(class, "boolean")) then
						value = (value == "true" or value == "yes" or value == "1");
					elseif (string.find(class, "number")) then
						value = tonumber(value);
					end;
					
					local forceSet = string.find(class, "force") != nil;
					local isStatic = string.find(class, "static") != nil;
					local isPrivate = string.find(class, "private") != nil;
					local needsRestart = string.find(class, "restart") != nil;
					
					if (value) then
						local config = self:Get(key);
						
						if (!config:IsValid()) then
							self:Add(key, value, isStatic, isPrivate, needsRestart);
						else
							config:Set(value, forceSet, nil);
						end;
					end;
				end;
			end;
		end;
	end;
end;

-- A function to covert config value.
function greenCode.config:CovertValue( value, type )
	if type == "bool" or type == "boolean" then
		value = tobool(value);
	elseif type == "int" or type == "number" then
		value = tonumber(value);
	elseif type == "string" then
		value = tostring(value);
	elseif type == "vector" then
		local tbl = string.Explode(",", value);
		value = Vector(tbl[1] or 0, tbl[2] or 0, tbl[3] or 0);
	elseif type == "color" then
		local tbl = string.Explode(",", value);
		value = Color(tbl[1] or 0, tbl[2] or 0, tbl[3] or 0, tbl[4] or 255);
	end;
	return value;
end;

if SERVER then
	greenCode.config:Import("lua/greencode/greencode.cfg");
end;

greenCode:IncludeDirectory( "config/", true );

greenCode.config:SetInitialized(true);

greenCode.command:Add( "changeconfig", SERVER and 2 or 0, function( player, command, args )
	if ( #args < 2 ) then
		return;
	end;

	local sMessage = "Somting wrong.";
	local CONFIG = greenCode.config:Get(args[1]);

	if ( CONFIG and CONFIG:IsValid() ) then
		local curValue = CONFIG:Get();

		if ( curValue != nil ) then
			local value = greenCode.config:CovertValue( args[2], type(curValue) );
			CONFIG:Set( value );
			sMessage = "Change "..args[1].." = "..tostring(value);
		end;
	else
		sMessage = "Incorrect config."
	end;

	if SERVER then
		player:PrintMsg(2, sMessage)
	else
		print(sMessage);
	end;
end);