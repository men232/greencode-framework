--[[
	© 2013 GmodLive private project do not share
	without permission of its author (Andrew Mensky vk.com/men232).
--]]

local AddCSLuaFile = AddCSLuaFile;
local IsValid      = IsValid;
local pairs        = pairs;
local pcall        = pcall;
local string       = string;
local table        = table;
local game         = game;
local greenCode = greenCode;

greenCode.DebugMode = true;
greenCode.FirstBooting = greenCode.FirstBooting == nil;
greenCode.KernelVersion = 0.31;

_player, _team, _file, _ents = player, team, file, ents;

function greenCode:IsFirst() return self.FirstBooting; end;
function greenCode:GetVersion() return self.KernelVersion; end;
function greenCode:GetKernelVersion() return self:GetVersion(); end;
function greenCode:IsDebug() return self.DebugMode end;

function greenCode:Split( source, split, bSpace )
	local sType = source and type( source ) or type( split );
	local result;

	if ( !split ) then
		result = source;
	elseif ( sType == "string" ) then
		result = (source or "") .. ( bSpace and " " or "" ) .. split;
	elseif ( sType == "number" ) then
		result = tonumber( tostring( source or "0" ) .. tostring( split ) );
	end;

	return result;
end;

if greenCode:IsFirst() then
	greenCode.Name = greenCode:Split( greenCode.Name, "ext. Green Code", true );
	greenCode.Email = greenCode:Split( greenCode.Email, "men232@bigmir.net", true );
	greenCode.Author = greenCode:Split( greenCode.Author, "men232", true );
	greenCode.Website = greenCode:Split( greenCode.Website, "www.gmodlive.com", true );
end;

-- A function to reserver function :)
function greenCode:ReserveFunc( tTable, sName, nReservName )
	local nReservName = nReservName and nReservName or "_" .. sName;
	local tTable = tTable or _G;

	if ( tTable and !tTable[ nReservName ] ) then
		tTable[ nReservName ] = tTable[sName];
	end;
end;

greenCode:ReserveFunc( nil, "IsValid" );

function IsValid( object )
	if ( !object ) then
		return false;
	end;
	
	local bSuccess, value = pcall( _IsValid, object );
	return bSuccess or value or false;  	
end;

function IsType( object, sType )return type( object ) == sType; end;

if ( !game.GetWorld ) then
	function game.GetWorld() return Entity(0); end;
end;

if SERVER then
	function greenCode:AddDirectory(directory, bRecursive)
		local files, folders = _file.Find(directory.."*.*", "GAME", "namedesc");
		
		for k, v in pairs(files) do
			resource.AddFile(directory..v);
		end;
		
		if (bRecursive) then
			for k, v in pairs(folders) do
				if (v != ".." and v != ".") then
					self:AddDirectory(directory..v.."/", true);
				end;
			end;
		end;
	end;
end;

-- A function to include a prefixed _file.
function greenCode:IncludePrefixed( sFilePath )
	local bShared = (string.find(sFilePath, "sh_") or string.find(sFilePath, "shared.lua"));
	local bClient = (string.find(sFilePath, "cl_") or string.find(sFilePath, "cl_init.lua"));
	local bServer = (string.find(sFilePath, "sv_") or string.find(sFilePath, "init.lua"));

	if ( ( bShared or bClient ) and SERVER ) then
		AddCSLuaFile( sFilePath );
	end;
	
	if ( !bShared and tobool(bClient) == SERVER ) then
		return;
	end;
	
	include( sFilePath );
end;

-- A function to include files in a directory.
function greenCode:IncludeDirectory( sDirectory, bFromBase )
	if ( bFromBase ) then
		sDirectory = "greencode/"..sDirectory;
	end;

	if ( string.sub( sDirectory, -1 ) != "/" ) then
		sDirectory = sDirectory.."/";
	end;
	
	for k, v in pairs( _file.Find( sDirectory.."*.lua", "LUA", "namedesc" ) ) do
		self:IncludePrefixed( sDirectory..v );
	end;
end;

-- A function to include plugins in a directory.
function greenCode:IncludePlugins( directory, bFromBase )
	if ( bFromBase ) then
		directory = "greenCode/"..directory;
	end;
	
	if ( string.sub(directory, -1) != "/" ) then
		directory = directory.."/";
	end;
	
	local files, pluginFolders = _file.Find( directory.."*", "LUA", "namedesc" );
	
	for k, v in pairs( pluginFolders ) do
		if ( v != ".." and v != "." ) then
			greenCode.plugin:Include( directory..v );
		end;
	end;
	
	return true;
end;

if SERVER then
	greenCode:AddDirectory("materials/greencode/", true);
	greenCode:AddDirectory("sound/greencode/", true);
end;

greenCode.StartTime = SysTime();

greenCode:IncludePrefixed( "libs/sh_console.lua" ); -- wee need this.

local bSuccess, value = pcall( function()
	greenCode:MsgN( "Green Code", "Initialization kernel: v." .. greenCode:GetVersion() );

	greenCode:IncludePrefixed( "sh_enum.lua" );
	greenCode:IncludePrefixed( "sh_kernel.lua" );

	greenCode:IncludeDirectory( "libs/", true );
	greenCode:IncludeDirectory( "derma/", true );
	greenCode:IncludeDirectory( "attributes/", true );
	greenCode:IncludeDirectory( "derma/", true );
	greenCode:IncludePlugins( "plugins/", true );
end);

if ( bSuccess ) then
	greenCode.plugin:RunHooks( "GreenCodeInitialized", false );

	greenCode:Success( "Green Code", "initialized: ".. (SysTime() - greenCode.StartTime) .." m.sec." );

	greenCode.command:Add( "reloadents", 0, function() 
		_gc_init();
	end);
else
	greenCode:Error( "Green Code", "initialized error:\n\t" .. value );
end;