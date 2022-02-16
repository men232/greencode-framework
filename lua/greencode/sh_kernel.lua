--[[
	© 2013 GmodLive private project do not share
	without permission of its author (Andrew Mensky vk.com/men232).
--]]

greenCode.kernel = {};
greenCode.libs = {};

--[[ Define the class metatable. --]]
function greenCode.kernel:CreateBasicClass()
	local BASIC_CLASS = {__index = BASIC_CLASS};

	function BASIC_CLASS:__call( parameter, failSafe )
		return self:Query( parameter, failSafe );
	end;

	function BASIC_CLASS:__tostring()
		return self("className", "BasicGC").." ["..self("uid", -1).."]["..self("name", "Unknown").."]";
	end;

	function BASIC_CLASS:IsValid()
		return self.data != nil;
	end;

	function BASIC_CLASS:Query( key, failSafe )
		if ( self.data and self.data[key] != nil ) then
			return self.data[key];
		else
			return failSafe;
		end;
	end;

	function BASIC_CLASS:SetData( key, value )
		if ( self:IsValid() and self.data[key] != nil ) then
			self.data[key] = value;
			return true;
		end;
	end;

	function BASIC_CLASS:New( tMergeTable )
		local object = {data = {}};

			if ( tMergeTable ) then
				table.Merge( object.data, tMergeTable );
			end;

			setmetatable( object, self );
			self.__index = self;
		return object;
	end;

	return BASIC_CLASS;
end;

local LIBRARY = {};

-- A function to add a library function to a metatable.
function LIBRARY:AddToMetaTable( metaName, funcName, newName )
	local metaTable = FindMetaTable( metaName );
	
	metaTable[ newName or funcName ] = function(...)
		return self[ funcName ](self, ...)
	end;
end;

-- A function to create a new library.
function greenCode.kernel:NewLibrary( libName )
	if ( !greenCode.libs[ libName ] ) then
		greenCode.libs[ libName ] = self:NewMetaTable( LIBRARY );
	end;
	
	return greenCode.libs[ libName ];
end;

-- A function find a library by its name.
function greenCode.kernel:FindLibrary( libName )
	return greenCode.libs[ libName ];
end;

-- A function to get kernel version.
function greenCode.kernel:GetKernelVersion()
	return greenCode.KernelVersion;
end;

-- A function to get the path to GMod.
function greenCode.kernel:GetPathToGMod()
	return util.RelativePathToFull("."):sub( 1, -2 );
end;

-- Convert number of seconds remaining to something more legible (Thanks JamminR!)
function greenCode.kernel:ConvertTime( seconds )
	local years = math.floor( seconds / 31536000 )
	seconds = seconds - ( years * 31536000 )
	local days = math.floor( seconds / 86400 )
	seconds = seconds - ( days * 86400 )
	local hours = math.floor( seconds/3600 )
	seconds = seconds - ( hours * 3600 )
	local minutes = math.floor( seconds/60 )
	seconds = seconds - ( minutes * 60 )
	local curtime = ""
	if years ~= 0 then curtime = curtime .. years .. " year" .. ( ( years > 1 ) and "s, " or ", " ) end
	if days ~= 0 then curtime = curtime .. days .. " day" .. ( ( days > 1 ) and "s, " or ", " ) end
	curtime = curtime .. ( ( hours < 10 ) and "0" or "" ) .. hours .. ":"
	curtime = curtime .. ( ( minutes < 10 ) and "0" or "" ) .. minutes .. ":"
	return curtime .. ( ( seconds < 10 and "0" or "" ) .. seconds )
end

--Thanks to Megiddo for this code! :D
function greenCode.kernel:TextWarp( text, width, font )
	surface.SetFont( font )
	if not surface.GetTextSize( "" ) then
		surface.SetFont( "default" ) --Set font to default if specified font does not return a size properly.
	end
	text = text:Trim()
	local output = ""
	local pos_start, pos_end = 1, 1
	while true do
		local begin, stop = text:find( "%s+", pos_end + 1 )
		
		if (surface.GetTextSize( text:sub( pos_start, begin or -1 ):Trim() ) > width and pos_end - pos_start > 0) then -- If it's not going to fit, split into a newline
			output = output .. text:sub( pos_start, pos_end ):Trim() .. "\n"
			pos_start = pos_end + 1
			pos_end = pos_end + 1
		else
			pos_end = stop
		end

		if not stop then -- We've hit our last word
			output = output .. text:sub( pos_start ):Trim()
			break
		end
	end
	return output
end;

-- A function to serialize a table.
function greenCode.kernel:Serialize( tData )
	local bSuccess, value = pcall( von.serialize, tData );
  
	if ( !bSuccess ) then
		print(value);
		return "";
	end;
  
	return value;
end;

-- A function to deserialize a string.
function greenCode.kernel:Deserialize( sData )
	local bSuccess, value = pcall( von.deserialize, sData );
  
	if ( !bSuccess ) then
		print(value);
		return {}; 
	end;
  
	return value;
end;

-- A function to scale a font size to the screen.
function greenCode.kernel:FontScreenScale( size )
	return ScreenScale(size);
end;

-- A function to get the 3D font size.
function greenCode.kernel:GetFontSize3D()
	return self:FontScreenScale(32);
end;

-- A function to get a cached text size.
function greenCode.kernel:GetCachedTextSize(font, text)
	if (!greenCode.CachedTextSizes) then
		greenCode.CachedTextSizes = {};
	end;
	
	if (!greenCode.CachedTextSizes[font]) then
		greenCode.CachedTextSizes[font] = {};
	end;
	
	if (!greenCode.CachedTextSizes[font][text]) then
		surface.SetFont(font);
		
		greenCode.CachedTextSizes[font][text] = { surface.GetTextSize(text) };
	end;
	
	return greenCode.CachedTextSizes[font][text][1], greenCode.CachedTextSizes[font][text][2];
end;

-- A function to create subfolders
function greenCode.kernel:CreateSubFolders( sPath )
	local tFolderds = string.Explode( "/", sPath );
	local sLastFolder = tFolderds[ #tFolderds ];
	tFolderds[ #tFolderds ] = sLastFolder != "" and sLastFolder or nil;

	local sTempPath = "";

	for i = 1, #tFolderds do
		local sPath = sTempPath .. ( i != 1 and "/" or "" ) .. tFolderds[i];

		if ( !_file.IsDir( sPath, "DATA" ) ) then
			_file.CreateDir( sPath );
		end;

		sTempPath = sPath;
	end;
end;

-- A function to retrieve the file directory from a string.
function greenCode.kernel:SplitDirectory( directory )
	local explodedDirectory = string.Explode("/", directory);
	local splitDirectory = nil;

	explodedDirectory[#explodedDirectory] = nil;
	splitDirectory = table.concat(explodedDirectory, "/");

	return splitDirectory;
end;

-- A function to check if game data exists.
function greenCode.kernel:GameDataExists( sFilePath )
	return _file.Exists( GC_GAMEDATA_FOLDER .. sFilePath .. ".txt", "DATA" );
end;

-- A function to delete game data.
function greenCode.kernel:DeleteGameData( sFilePath )
	_file.Delete(GC_GAMEDATA_FOLDER .. sFilePath .. ".txt", "DATA");
end;

-- A function to save game data.
function greenCode.kernel:SaveGameData( sFilePath, tData )
	local sPath = self:SplitDirectory( sFilePath );

	if ( !_file.IsDir( sFilePath, "DATA" ) ) then
		self:CreateSubFolders( GC_GAMEDATA_FOLDER .. sPath );
	end;

	_file.Write( GC_GAMEDATA_FOLDER .. sFilePath .. ".txt", self:Serialize( tData ), "DATA" );
end;

-- A function to restore game data.
function greenCode.kernel:RestoreGameData( sFilePath, tDefault )
	if ( self:GameDataExists( sFilePath ) ) then
		local sData = _file.Read( GC_GAMEDATA_FOLDER .. sFilePath .. ".txt", "DATA" );
		
		return self:Deserialize( sData ) or tDefault or {};
	end;

	return tDefault or {};
end;

-- A function to get a short CRC from a value.
function greenCode.kernel:GetShortCRC( value )
	return math.ceil( util.CRC( value ) / 100000 );
end;

-- A function to get CRC of table
function greenCode.kernel:GetTableCRC( baseTable, bShort )
	local sTableSerialize = self:Serialize( baseTable );
	return bShort and self:GetShortCRC( sTableSerialize ) or util.CRC( sTableSerialize );
end;

-- A function to check if the server is shutting down.
function greenCode.kernel:IsShuttingDown()
	return greenCode.ShuttingDown;
end;

-- A function to create a new meta table.
function greenCode.kernel:NewMetaTable( baseTable )
	local object = {};
		setmetatable(object, baseTable);
		baseTable.__index = baseTable;
	return object;
end;

-- A function to find a player.
function greenCode.kernel:FindPlayer( info )
	if ( !info or info == "" ) then
		return nil
	end;

	local players = _player:GetAll();
	local nInfo = tonumber( info );

	for i = 1, #players do
		local v = players[i];

		if nInfo == v:UserID() or nInfo == tonumber( v:UniqueID() ) or nInfo == v:SteamID() then
			return v;
		elseif string.find( string.lower(v:Name()) , string.lower(tostring(info)) , 1, true ) != nil then
			return v;
		end
	end

	return nil;
end;

-- A function to convert a force.
function greenCode.kernel:ConvertForce(force, limit)
	local forceLength = force:Length();
	
	if (forceLength == 0) then
		return Vector(0, 0, 0);
	end;
	
	if (!limit) then
		limit = 800;
	end;
	
	if (forceLength > limit) then
		return force / (forceLength / limit);
	else
		return force;
	end;
end;

-- A function to get whether a weapon is a default weapon.
function greenCode.kernel:IsDefaultWeapon( weapon )
	if !IsValid(weapon) then return false; end;
	local class = string.lower( weapon:GetClass() );
	return (class == "weapon_physgun" or class == "gmod_physcannon"	or class == "gmod_tool" or class == "gmod_camera");
end;

-- A function to set whether a string should be in camel case.
function greenCode.kernel:SetCamelCase(text, bCamelCase)
	if (bCamelCase) then
		return string.gsub(text, "^.", string.lower);
	else
		return string.gsub(text, "^.", string.upper);
	end;
end;

-- A function to covert config value.
function greenCode.kernel:CovertValue( value, type )
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

-- A function to calculate alpha from a distance.
function greenCode.kernel:CalculateAlphaFromDistance(maximum, start, finish)
	if (type(start) == "Player") then
		start = start:GetShootPos();
	elseif (type(start) == "Entity") then
		start = start:GetPos();
	end;
	
	if (type(finish) == "Player") then
		finish = finish:GetShootPos();
	elseif (type(finish) == "Entity") then
		finish = finish:GetPos();
	end;
	
	return math.Clamp(255 - ((255 / maximum) * (start:Distance(finish))), 0, 255);
end;

function greenCode.kernel:FormatNumber(n)
	n = tonumber(n);

	if (!n) then return 0; end;
	if n >= 1e14 then return tostring(n) end;
    n = tostring(n);
    sep = sep or ",";
    local dp = string.find(n, "%.") or #n+1;
	for i=dp-4, 1, -3 do
		n = n:sub(1, i) .. sep .. n:sub(i+1);
    end;
    return n;
end;

function greenCode.kernel:PointNumber(value, point)
	return math.floor(value * point)/point;
end;

-- A function to check valid arguments.
function IsValids( ... )
	local args = {...};

	for i=1, #args do
		if ( !IsValid( args[i] ) ) then
			return false;
		end;
	end;
	
	return true;
end;

greenCode:ReserveFunc( hook, "Call" );
hook.Timings = {};

function hook.Call( sName, gamemode, ... )
	if ( gamemode == nil && gmod != nil ) then
		gamemode = gmod.GetGamemode();
	end;

	if ( CLIENT and !IsValid(gc.Client) ) then
		gc.Client = LocalPlayer();
	end;

	local a, b, c, d, e, f;

	local startTime = SysTime();

	if ( !greenCode.hooks.stored[ sName ] ) then
		a, b, c, d, e, f = greenCode.plugin:RunHooks( sName, false, ... );
	end;
		
	if ( a == nil && b == nil && c == nil && d == nil && e == nil && f == nil ) then
		a, b, c, d, e, f =  hook._Call( sName, gamemode or greenCode, ... );
	end;

	hook.Timings[ sName ] = SysTime() - startTime;

	return a, b, c, d, e, f;
end;

if SERVER then
	// This hijack need because drp speed fucking broken game.
	function greenCode:SetPlayerSpeed( player, runSpeed, sprintSpeed )
		player:SetWalkSpeed(runSpeed);
		player:SetRunSpeed(sprintSpeed);
	end;
else
	gc.SpawnIconMaterial = Material("vgui/spawnmenu/hover");
	gc.DefaultGradient = surface.GetTextureID("gui/gradient_down");
	gc.GradientTexture = Material("gui/gradient_up.png");
	gc.FishEyeTexture = Material("models/props_c17/fisheyelens");
	gc.GradientCenter = surface.GetTextureID("gui/center_gradient");
	gc.GradientRight = surface.GetTextureID("gui/gradient");
	gc.GradientUp = surface.GetTextureID("gui/gradient_up");
	gc.ScreenBlur = Material("pp/blurscreen");
	gc.Gradients = {
		[GRADIENT_CENTER] = gc.GradientCenter;
		[GRADIENT_RIGHT] = gc.GradientRight;
		[GRADIENT_DOWN] = gc.DefaultGradient;
		[GRADIENT_UP] = gc.GradientUp;
	};
	
	-- A function to get whether the local player is using the camera.
	function greenCode.kernel:IsUsingCamera()
		if (IsValid(greenCode.Client:GetActiveWeapon())
		and greenCode.Client:GetActiveWeapon():GetClass() == "gmod_camera") then
			return true;
		else
			return false;
		end;
	end;

	-- A function to get the screen's center.
	function greenCode.kernel:GetScreenCenter()
		return ScrW() / 2, (ScrH() / 2) + 32;
	end;
	
	-- A function to draw some simple text.
	function greenCode.kernel:DrawSimpleText(text, x, y, color, alignX, alignY, shadowless, shadowDepth, font)
		local mainTextFont = font or "gcMainText";//"gcChatSyntax";//"gcMainText";
		local realX = math.Round(x);
		local realY = math.Round(y);
		
		if (!shadowless) then
			local outlineColor = Color(25, 25, 25, math.min(225, color.a));
			
			for i = 1, (shadowDepth or 1) do
				draw.SimpleText(text, mainTextFont, realX + -i, realY + -i, outlineColor, alignX, alignY);
				draw.SimpleText(text, mainTextFont, realX + -i, realY + i, outlineColor, alignX, alignY);
				draw.SimpleText(text, mainTextFont, realX + i, realY + -i, outlineColor, alignX, alignY);
				draw.SimpleText(text, mainTextFont, realX + i, realY + i, outlineColor, alignX, alignY);
			end;
		end;
		
		draw.SimpleText(text, mainTextFont, realX, realY, color, alignX, alignY);
		local width, height = self:GetCachedTextSize(mainTextFont, text);
		
		return realY + height + 2, width;
	end;

	-- A function to draw information at a position.
	function greenCode.kernel:DrawInfo( text, x, y, color, alpha, bAlignLeft, Callback, shadowDepth, alignX, alignY )
		local mainTextFont = "gcMainText";
		local width, height = self:GetCachedTextSize(mainTextFont, text);
		
		if (width and height) then
			if (!bAlignLeft) then
				x = x - (width / 2);
			end;
			
			if (Callback) then
				x, y = Callback(x, y, width, height);
			end;
		
			return self:DrawSimpleText(text, x, y, Color(color.r, color.g, color.b, alpha or color.a), alignX, alignY, nil, shadowDepth);
		end;
	end;

	-- A function to draw a gradient.
	function greenCode.kernel:DrawGradient(gradientType, x, y, width, height, color)
		if (!greenCode.Gradients[gradientType]) then
			return;
		end;
		
		surface.SetDrawColor(color.r, color.g, color.b, color.a);
		surface.SetTexture(greenCode.Gradients[gradientType]);
		surface.DrawTexturedRect(x, y, width, height);
	end;
	
	-- A function to draw a simple gradient box.
	function greenCode.kernel:DrawSimpleGradientBox(cornerSize, x, y, width, height, color, maxAlpha)
		local gradientAlpha = math.min(color.a, maxAlpha or 100);
		draw.RoundedBox(cornerSize, x, y, width, height, Color(color.r, color.g, color.b, color.a * 0.75));
		
		if (x + cornerSize < x + width and y + cornerSize < y + height) then
			surface.SetDrawColor(gradientAlpha, gradientAlpha, gradientAlpha, gradientAlpha);
			surface.SetTexture(greenCode.DefaultGradient);
			surface.DrawTexturedRect(x + cornerSize, y + cornerSize, width - (cornerSize * 2), height - (cornerSize * 2));
		end;
	end;

	-- A function to draw a textured gradient.
	function greenCode.kernel:DrawTexturedGradientBox(cornerSize, x, y, width, height, color, maxAlpha)
		local gradientAlpha = math.min(color.a, maxAlpha or 100);
		draw.RoundedBox(cornerSize, x, y, width, height, Color(color.r, color.g, color.b, color.a * 0.75));
		
		if (x + cornerSize < x + width and y + cornerSize < y + height) then
			surface.SetDrawColor(gradientAlpha, gradientAlpha, gradientAlpha, gradientAlpha);
			surface.SetTexture(greenCode.DefaultGradient);
			surface.DrawTexturedRect(x + cornerSize, y + cornerSize, width - (cornerSize * 2), height - (cornerSize * 2));
		end;
	end;

	-- A function to draw a bar with a value and a maximum.
	function greenCode.kernel:DrawBar(x, y, width, height, color, text, value, maximum, flash, barInfo)
		local backgroundColor = Color(0, 0, 0, 125);
		local foregroundColor = Color(50, 50, 50, 125);
		local progressWidth = math.Clamp(((width - 4) / maximum) * value, 0, width - 4);
		local colorWhite = Color(255, 255, 255, 255);
		local newBarInfo = {
			progressWidth = progressWidth,
			drawBackground = true,
			drawForeground = true,
			drawProgress = true,
			cornerSize = 2,
			maximum = maximum,
			height = height,
			width = width,
			color = color,
			value = value,
			flash = flash,
			text = text,
			x = x,
			y = y
		};
		
		if (barInfo) then
			for k, v in pairs(newBarInfo) do
				if (!barInfo[k]) then
					barInfo[k] = v;
				end;
			end;
		else
			barInfo = newBarInfo;
		end;
		
		if (!greenCode.plugin:Call("PreDrawBar", barInfo)) then
			if (barInfo.drawBackground) then
				self:DrawTexturedGradientBox(
					barInfo.cornerSize, barInfo.x, barInfo.y, barInfo.width, barInfo.height, backgroundColor, 50
				);
			end;
			
			if (barInfo.drawForeground) then
				self:DrawTexturedGradientBox(
					barInfo.cornerSize, barInfo.x + 2, barInfo.y + 2, barInfo.width - 4, barInfo.height - 4, foregroundColor, 50
				);
			end;
			
			if (barInfo.drawProgress) then
				self:DrawTexturedGradientBox(
					0, barInfo.x + 2, barInfo.y + 2, barInfo.progressWidth, barInfo.height - 4, barInfo.color, 150
				);
			end;
			
			if (barInfo.flash) then
				local alpha = math.Clamp(math.abs(math.sin(UnPredictedCurTime()) * 50), 0, 50);
				
				if (alpha > 0) then
					draw.RoundedBox(0, barInfo.x + 2, barInfo.y + 2, barInfo.width - 4, barInfo.height - 4,
					Color(colorWhite.r, colorWhite.g, colorWhite.b, alpha));
				end;
			end;
		end;
		
		if (!greenCode.plugin:Call("PostDrawBar", barInfo)) then
			if (barInfo.text and barInfo.text != "") then
				self:DrawSimpleText(
					barInfo.text, barInfo.x + (barInfo.width / 2), barInfo.y + (barInfo.height / 2) - 1,
					Color(colorWhite.r, colorWhite.g, colorWhite.b, alpha), 1, 1, nil, nil, "gcIntroTextTiny"
				);
			end;
		end;
		
		return barInfo.y;
	end;

	function greenCode.kernel:GetRpVar( key, default )
		local value = greenCode.Client.DarkRPVars and greenCode.Client:getDarkRPVar(key);

		if ( value != nil ) then
			return value;
		else
			return default;
		end;
	end;

	-- Opa Induse stype.
	function greenCode:SetClipboardText( txt )
		local _,count=txt:gsub("\n","\n")
		txt=txt..('_'):rep(count)

		local b=vgui.Create('DTextEntry',nil,'ClipboardCopyHelper')
			b:SetVisible(false)
			b:SetText(txt)
			b:SelectAllText()
			b:CutSelected()
			b:Remove()
	end;
end