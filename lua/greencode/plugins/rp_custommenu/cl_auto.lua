--[[
	© 2013 GmodLive private project do not share
	without permission of its author (Andrew Mensky vk.com/men232).
--]]

local greenCode = greenCode;
local math = math;

local PLUGIN = PLUGIN or greenCode.plugin:Loader();

PLUGIN.stored = {};
PLUGIN.buffer = {};
PLUGIN.tmpls = PLUGIN.tmpls or {};

--[[ Define the custom menu class metatable. --]]
CM_CAT_CLASS = CM_CAT_CLASS or {__index = CM_CAT_CLASS};

function CM_CAT_CLASS:__call( parameter, failSafe ) return self:Query( parameter, failSafe ); end;
function CM_CAT_CLASS:__tostring() return "MENU_CATEGORY ["..self("title").."]"; end;
function CM_CAT_CLASS:IsValid() return self.data != nil; end;

function CM_CAT_CLASS:Query( key, failSafe )
	if ( self.data and self.data[key] != nil ) then
		return self.data[key];
	else
		return failSafe;
	end;
end;

function CM_CAT_CLASS:New( tMergeTable )
	local object = { 
			data = {
				title = "Unknown",
				priority = 1,
				uid = -1,
			}
		};

		if ( tMergeTable ) then table.Merge( object.data, tMergeTable ); end;

		setmetatable( object, self );
		self.__index = self;
	return object;
end;

function CM_CAT_CLASS:GetTitle() return self("title", "#Empty"); end;
function CM_CAT_CLASS:GetText() return self:GetTitle(); end;
function CM_CAT_CLASS:GetPriority() return self("priority", 1); end;
function CM_CAT_CLASS:GetCallBack() return self("callback"); end;
function CM_CAT_CLASS:Register() return PLUGIN:RegisterCategory(self); end;

--[[ Define the custom menu class metatable. --]]
CM_TMPL_CLASS = CM_TMPL_CLASS or {__index = CM_TMPL_CLASS};

function CM_TMPL_CLASS:__call( parameter, failSafe ) return self:Query( parameter, failSafe ); end;
function CM_TMPL_CLASS:__tostring() return "MENU_TMPL ["..self("name", "Unknown").."]"; end;
function CM_TMPL_CLASS:IsValid() return self.data != nil; end;

function CM_TMPL_CLASS:Query( key, failSafe )
	if ( self.data and self.data[key] != nil ) then
		return self.data[key];
	else
		return failSafe;
	end;
end;

function CM_TMPL_CLASS:New( tMergeTable )
	local object = { 
			data = {
				name = "Unknown",
				callback = function() return true end;
			}
		};

		if ( tMergeTable ) then table.Merge( object.data, tMergeTable ); end;

		setmetatable( object, self );
		self.__index = self;
	return object;
end;

function CM_TMPL_CLASS:GetName() return self("name", "Unknown"); end;
function CM_TMPL_CLASS:GetCallBack() return self("callback"); end;

function CM_TMPL_CLASS:Register() return PLUGIN:RegisterTemplate(self); end;

function PLUGIN:RegisterCategory( CM_CATEGORY )
	if ( CM_CATEGORY and CM_CATEGORY:IsValid() ) then
		CM_CATEGORY.data["uid"] = tonumber( greenCode.kernel:GetShortCRC( CM_CATEGORY:GetTitle() ) );
		self.stored[CM_CATEGORY("uid")] = CM_CATEGORY

		local CM_CATEGORY_COUNT = #self.stored;
		self.buffer = {};
		
		for uid, CM_CATEGORY in pairs( self.stored ) do
			if ( CM_CATEGORY and CM_CATEGORY:IsValid() ) then
				local priority = CM_CATEGORY:GetPriority();

				if ( !self.buffer[priority] ) then
					self.buffer[priority] = {};
				end;

				table.insert( self.buffer[priority], CM_CATEGORY );
			end;
		end;

		return CM_CATEGORY, CM_CATEGORY("uid");
	end;
end;

function PLUGIN:RegisterTemplate( CM_TMPL )
	self.tmpls[ CM_TMPL:GetName() ] = CM_TMPL:GetCallBack();
end;

function PLUGIN:ApplyTemplate( BLOCK, sName, t )
	if ( self.tmpls[ sName ] ) then
		return self.tmpls[ sName ]( BLOCK, t or {} );
	end;

	return false;
end;

function PLUGIN:IsOpen() return ValidPanel( self.TextMenu ), ValidPanel( self.BlockMenu ); end;

function PLUGIN:TickSecond()
	if ( self:IsOpen() ) then
		RunConsoleCommand( "cl_gc_showbar" );
	end;
end;

function PLUGIN:Open( args )
	self:Close();

	TOPHUD_ALPHA = 100;

	self.TextMenu = vgui.Create("gcTextMenu");
	self.BlockMenu = vgui.Create("gcBlockMenu", self.TextMenu);

	function self.TextMenu:OnMousePressed()
		PLUGIN:Close();
	end;

	local tCatFilter;
	local uid = tonumber(args[1] or 42027);
	self.args = args or nil;

	if ( args[2] and args[2] != "" ) then
		tCatFilter = string.Explode(",", args[2]);
	end;
	
	local bTextMenu, bBlockMenu = self:IsOpen();
	local BlockMenu = self.BlockMenu;

	for k, v in pairs(self.buffer) do
		for _, CM_CATEGORY in pairs(v) do
			local callback = CM_CATEGORY:GetCallBack();
			local catUID = CM_CATEGORY("uid");
			
			if ( !CM_CATEGORY("hide") and (!tCatFilter or table.HasValue( tCatFilter, tostring(catUID) )) ) then
				local item = self.TextMenu:AddItem{ title = CM_CATEGORY:GetTitle(), callback = callback };
				
				item.DoClick = function()
					surface.PlaySound("ui/buttonclick.wav");
					callback( CM_CATEGORY, self, BlockMenu, bTextMenu, bBlockMenu );
				end;
			end;

			if ( uid and catUID == uid and callback ) then
				callback( CM_CATEGORY, self, BlockMenu, bTextMenu, bBlockMenu );
			end;
		end;
	end;
end;

function PLUGIN:Close()
	local bTextMenu, bBlockMenu = self:IsOpen();
	if ( bTextMenu ) then self.TextMenu:Close(); end;
	if ( bBlockMenu ) then self.BlockMenu:Close(); end;

	TOPHUD_ALPHA = 255;
end;

function PLUGIN:Think( curTime )	
	if input.IsKeyDown(KEY_F4) and curTime > (self.prevF4 or 0) then
		RunConsoleCommand("cl_gc_custommenu_toogle");
		self.prevF4 = curTime + 0.3;
	end;
end;

greenCode:IncludeDirectory( PLUGIN:GetBaseDir().. "/templates/", false );
greenCode:IncludeDirectory( PLUGIN:GetBaseDir().. "/category/", false );

greenCode.command:Add( "custommenu_toogle", 0, function( player, command, args )
	if ( PLUGIN:IsOpen() ) then
		RunConsoleCommand("cl_gc_custommenu_close");
	else
		RunConsoleCommand("cl_gc_custommenu_open");
	end;
end);

greenCode.command:Add( "custommenu_open", 0, function( player, command, args )
	PLUGIN:Open(args);
end);

greenCode.command:Add( "custommenu_close", 0, function( player, command, args )
	PLUGIN:Close();
end);

greenCode.command:Add( "custommenu_update", 0, function( player, command, args )
	if #args >= 1 and PLUGIN:IsOpen() then
		local uid = tonumber(args[1]);

		for _, CM_CATEGORY in pairs(PLUGIN.stored) do
			if ( CM_CATEGORY("uid") == uid ) then
				local callback = CM_CATEGORY:GetCallBack();
				local bTextMenu, bBlockMenu = PLUGIN:IsOpen();
				local BlockMenu = PLUGIN.BlockMenu;
				callback( CM_CATEGORY, PLUGIN, BlockMenu, bTextMenu, bBlockMenu );
				break;
			end;
		end;
	end;
end);

greenCode.command:Add( "custommenu_calist", 0, function( player, command, args )
	for _, CM_CATEGORY in pairs(PLUGIN.stored) do
		print(CM_CATEGORY("uid", -1).."\t-\t"..CM_CATEGORY:GetTitle());
	end;
end);

/*
27980	-	Атрибуты
42027	-	Действия
42729	-	Профессии
25772	-	Магазин
T
*/