--[[
	© 2013 GmodLive private project do not share
	without permission of its author (Andrew Mensky vk.com/men232).
--]]

greenCode.plugin = greenCode.kernel:NewLibrary("Plugin");
greenCode.plugin.stored = {};
greenCode.plugin.buffer = {};
greenCode.plugin.modules = {};

function greenCode.plugin:Loader()
	PLUGIN = {};
	
	greenCode:IncludePrefixed("sh_info.lua");
	
	if (PLUGIN.name) then
		greenCode:MsgN("Reloaded plug-in\t\t"..[["]]..(PLUGIN.name)..[["]].."\t\tDone...");

		local pluginTable = self:Get( PLUGIN.name );

		if ( pluginTable ) then
			timer.Simple(0, function()
				self:IncludeExtras( pluginTable:GetBaseDir() );
				self:IncludePlugins( pluginTable:GetBaseDir() );
				
				if ( pluginTable.Initialized ) then
					pluginTable:Initialized();
				end;
			end);
		end;

		PLUGIN = nil;
		return pluginTable;
	else
		greenCode:MsgN("Reloaded plug-in\t\t"..[["Unknown"]].."\t\tFailed...");
		PLUGIN = nil
	end;
end;

-- A function to register a new plugin.
function greenCode.plugin:Register( pluginTable )
	local files, pluginFolders = _file.Find(pluginTable.baseDir.."/plugins/*", "LUA", "namedesc");

	self.buffer[pluginTable.folderName] = pluginTable;
	self.stored[pluginTable.name] = pluginTable;
	self.stored[pluginTable.name].plugins = {};
	
	for k, v in pairs(pluginFolders) do
		if (v != ".." and v != ".") then
			table.insert(self.stored[pluginTable.name].plugins, v);
		end;
	end;
	
	self:IncludeExtras( pluginTable:GetBaseDir() );
	self:IncludePlugins( pluginTable:GetBaseDir() );

	if ( pluginTable.Initialized ) then
		pluginTable:Initialized();
	end;

	greenCode:MsgN("Installing plug-in", "\t\t"..[["]]..(pluginTable:GetName() or pluginTable.folderName )..[["]].."\t\t".."Done...");
end;

-- A function to find a plugin by an ID.
function greenCode.plugin:FindByID( identifier )
	return self.stored[ identifier ] or self.buffer[ identifier ];
end;

-- A function to include a plugin.
function greenCode.plugin:Include( directory )
	local explodeDir = string.Explode("/", directory);
	local folderName = string.lower(explodeDir[#explodeDir]);
	local pathCRC = util.CRC(string.lower(directory));
	
	PLUGIN_BASE_DIR = directory;
	PLUGIN_FOLDERNAME = folderName;
	PLUGIN_LOAD_ERROR = false;
	PLUGIN_LOAD_ERROR_MSG = nil;

	PLUGIN = self:New();
	local REGISTERFUNC_PRECTION = PLUGIN.Register;

	if ( _file.Exists(directory.."/sh_info.lua", "LUA") ) then
		greenCode:IncludePrefixed(directory.."/sh_info.lua");
	else
		PLUGIN_LOAD_ERROR_MSG = "The "..PLUGIN_FOLDERNAME.." plugin has no sh_info.lua. ["..directory.."]";
		PLUGIN_LOAD_ERROR = true;
	end;
	
	if ( _file.Exists(directory.."/sh_auto.lua", "LUA") ) then
		greenCode:IncludePrefixed(directory.."/sh_auto.lua");
	end;
	
	if ( _file.Exists(directory.."/sv_auto.lua", "LUA") ) then
		greenCode:IncludePrefixed(directory.."/sv_auto.lua");
	end;
	
	if ( _file.Exists(directory.."/cl_auto.lua", "LUA") ) then
		greenCode:IncludePrefixed(directory.."/cl_auto.lua");
	end;

	if ( PLUGIN.Register != REGISTERFUNC_PRECTION ) then
		PLUGIN_LOAD_ERROR = true;
		PLUGIN_LOAD_ERROR_MSG = "Register function be changed."
	end;

	if ( !PLUGIN_LOAD_ERROR ) then
		PLUGIN:Register();
	else
		greenCode:Error("Installing plug-in", "\t\t"..[["]]..(PLUGIN:GetName() or PLUGIN.folderName )..[["]].."\t\t".."Failed..."..( PLUGIN_LOAD_ERROR_MSG and ("\n\tERROR: "..PLUGIN_LOAD_ERROR_MSG) or "" ));
	end;

	PLUGIN = nil;
end;

-- A function to create a new plugin.
function greenCode.plugin:New()
	local pluginTable = {
		description = "An undescribed plugin or schema.",
		folderName = PLUGIN_FOLDERNAME,
		baseDir = PLUGIN_BASE_DIR,
		version = 1.0,
		author = "Unknown",
		name = "Unknown"
	};
	
	pluginTable.GetDescription = function(pluginTable)
		return pluginTable.description;
	end;
	
	pluginTable.GetBaseDir = function(pluginTable)
		return pluginTable.baseDir;
	end;
	
	pluginTable.GetVersion = function(pluginTable)
		return pluginTable.version;
	end;
	
	pluginTable.GetAuthor = function(pluginTable)
		return pluginTable.author;
	end;
	
	pluginTable.GetName = function(pluginTable)
		return pluginTable.name;
	end;
	
	pluginTable.Register = function(pluginTable)
		self:Register(pluginTable);
	end;
	
	return pluginTable;
end;

-- A function to run the plugin hooks.
function greenCode.plugin:RunHooks( name, bGamemode, ... )
	for k, v in pairs(self.modules) do
		if (v[name]) then
			local bSuccess, a, b, c, d, e, f = pcall(v[name], v, ...);
			
			if (!bSuccess) then
				greenCode:Error( "greenCode", "The '"..name.."' plugin hook has failed to run.\n\t"..a );
			elseif (a != nil || b != nil || c != nil || d != nil || e != nil || f != nil) then
				return a, b, c, d, e, f;
			end;
		end;
	end;
	
	for k, v in pairs(self.stored) do
		if ( v[name] ) then
			local bSuccess, a, b, c, d, e, f = pcall(v[name], v, ...);
			
			if (!bSuccess) then
				greenCode:Error( "greenCode", "The '"..name.."' plugin hook has failed to run.\n\t"..a );
			elseif (a != nil || b != nil || c != nil || d != nil || e != nil || f != nil) then
				return a, b, c, d, e, f;
			end;
		end;
	end;

	-- Testing
	for k, v in pairs( greenCode ) do			
		if (k != "BaseClass" and type(v) == "table" and type(v[name]) == "function") then
			local bSuccess, a, b, c, d, e, f = pcall(v[name], v, ...);

			if (!bSuccess) then
				greenCode:Error( "greenCode", "The '"..name.."' plugin hook has failed to run.\n\t"..a );
			elseif (a != nil || b != nil || c != nil || d != nil || e != nil || f != nil) then
				return a, b, c, d, e, f;
			end;
		end;
	end;
	
	if (bGamemode and greenCode[name]) then
		local bSuccess, a, b, c, d, e, f = pcall(greenCode[name], greenCode, ...);
		
		if (!bSuccess) then
			greenCode:Error( "greenCode", "The '"..name.."' greencode hook has failed to run.\n\t"..a );
		elseif (a != nil || b != nil || c != nil || d != nil || e != nil || f != nil) then
			return a, b, c, d, e, f;
		end;
	end;
end;

-- A function to include a plugin's entities.
function greenCode.plugin:IncludeEntities(directory)
	local sBaseFoled = directory.."/entities/entities/";
	local files, entityFolders = _file.Find(sBaseFoled.."*", "LUA", "namedesc");

	for k, v in pairs(entityFolders) do
		if (v != ".." and v != ".") then
			ENT = {Type = "anim", Folder = sBaseFoled..v};

			if ( _file.Exists( sBaseFoled..v.."/shared.lua", "LUA" ) ) then
				greenCode:IncludePrefixed( sBaseFoled..v.."/shared.lua" );
			end;

			if ( _file.Exists( sBaseFoled..v.."/init.lua", "LUA" ) ) then
				greenCode:IncludePrefixed( sBaseFoled..v.."/init.lua" );
			end;

			if ( _file.Exists( sBaseFoled..v.."/cl_init.lua", "LUA" ) ) then
				greenCode:IncludePrefixed( sBaseFoled..v.."/cl_init.lua" );
			end;
			
			scripted_ents.Register(ENT, v); ENT = nil;
		end;
	end;
end;

-- A function to include a plugin's effects.
function greenCode.plugin:IncludeEffects(directory)
	local files, effectFolders = _file.Find(directory.."/entities/effects/*", "LUA", "namedesc");
	
	for k, v in pairs(effectFolders) do
		if (v != ".." and v != ".") then
			if (SERVER) then
				if (_file.Exists("gamemodes/"..directory.."/entities/effects/"..v.."/cl_init.lua", "GAME")) then
					AddCSLuaFile(directory.."/entities/effects/"..v.."/cl_init.lua");
				elseif (_file.Exists("gamemodes/"..directory.."/entities/effects/"..v.."/init.lua", "GAME")) then
					AddCSLuaFile(directory.."/entities/effects/"..v.."/init.lua");
				end;
			elseif (_file.Exists(directory.."/entities/effects/"..v.."/cl_init.lua", "LUA")) then
				EFFECT = {Folder = directory.."/entities/effects/"..v};
					include(directory.."/entities/effects/"..v.."/cl_init.lua");
				effects.Register(EFFECT, v); EFFECT = nil;
			elseif (_file.Exists(directory.."/entities/effects/"..v.."/init.lua", "LUA")) then
				EFFECT = {Folder = directory.."/entities/effects/"..v};
					include(directory.."/entities/effects/"..v.."/init.lua");
				effects.Register(EFFECT, v); EFFECT = nil;
			end;
		end;
	end;
end;

-- A function to include a plugin's weapons.
function greenCode.plugin:IncludeWeapons(directory)
	local sBaseFoled = directory.."/entities/weapons/";
	local files, weaponFolders = _file.Find(sBaseFoled.."*", "LUA");

	for k, v in pairs(weaponFolders) do
		if (v != ".." and v != ".") then
			SWEP = { Folder = directory.."/entities/weapons/"..v, Base = "weapon_base", Primary = {}, Secondary = {} };

			if ( _file.Exists( sBaseFoled..v.."/shared.lua", "LUA" ) ) then
				greenCode:IncludePrefixed( sBaseFoled..v.."/shared.lua" );
			end;

			if ( _file.Exists( sBaseFoled..v.."/init.lua", "LUA" ) ) then
				greenCode:IncludePrefixed( sBaseFoled..v.."/init.lua" );
			end;

			if ( _file.Exists( sBaseFoled..v.."/cl_init.lua", "LUA" ) ) then
				greenCode:IncludePrefixed( sBaseFoled..v.."/cl_init.lua" );
			end;
			
			weapons.Register(SWEP, v); SWEP = nil;
		end;
	end;
end;

-- A function to include a plugin's plugins.
function greenCode.plugin:IncludePlugins(directory)
	local files, pluginFolders = _file.Find(directory.."/plugins/*", "LUA", "namedesc");
	
	for k, v in pairs(pluginFolders) do
		//self:Include(directory.."/plugins/"..string.lower(v).."/plugin");
		self:Include(directory.."/plugins/"..string.lower(v));
	end;
end;

-- A function to include a plugin's extras.
function greenCode.plugin:IncludeExtras(directory)
	self:IncludeEffects(directory);
	self:IncludeWeapons(directory);
	self:IncludeEntities(directory);
	
	for k, v in pairs(_file.Find(directory.."/libraries/*.lua", "LUA", "namedesc")) do
		greenCode:IncludePrefixed(directory.."/libraries/"..v);
	end;

	for k, v in pairs(_file.Find(directory.."/directory/*.lua", "LUA", "namedesc")) do
		greenCode:IncludePrefixed(directory.."/directory/"..v);
	end;
	
	for k, v in pairs(_file.Find(directory.."/system/*.lua", "LUA", "namedesc")) do
		greenCode:IncludePrefixed(directory.."/system/"..v);
	end;
	
	for k, v in pairs(_file.Find(directory.."/factions/*.lua", "LUA", "namedesc")) do
		greenCode:IncludePrefixed(directory.."/factions/"..v);
	end;
	
	for k, v in pairs(_file.Find(directory.."/classes/*.lua", "LUA", "namedesc")) do
		greenCode:IncludePrefixed(directory.."/classes/"..v);
	end;
	
	for k, v in pairs(_file.Find(directory.."/attributes/*.lua", "LUA", "namedesc")) do
		greenCode:IncludePrefixed(directory.."/attributes/"..v);
	end;
	
	for k, v in pairs(_file.Find(directory.."/items/*.lua", "LUA", "namedesc")) do
		greenCode:IncludePrefixed(directory.."/items/"..v);
	end;
	
	for k, v in pairs(_file.Find(directory.."/derma/*.lua", "LUA", "namedesc")) do
		greenCode:IncludePrefixed(directory.."/derma/"..v);
	end;
	
	for k, v in pairs(_file.Find(directory.."/commands/*.lua", "LUA", "namedesc")) do
		greenCode:IncludePrefixed(directory.."/commands/"..v);
	end;
end;

-- A function to call a function for all plugins.
function greenCode.plugin:Call( name, ... )
	return self:RunHooks( name, true, ... );
end;

-- A function to get a plugin.
function greenCode.plugin:Get(name)
	return self.stored[name] or self.buffer[name];
end;