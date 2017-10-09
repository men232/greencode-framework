--[[
	© 2013 GmodLive private project do not share
	without permission of its author (Andrew Mensky vk.com/men232).
--]]

local greenCode = greenCode;
local Material = Material;
local surface = surface;
local draw = draw;
local util = util;

local PLUGIN = PLUGIN or greenCode.plugin:Loader();
PLUGIN.stored = {};
PLUGIN.buffer = {};
PLUGIN.alpha = 0;

TOPHUD_ALPHA = 255;

--[[ Define the territory class metatable. --]]
TOPHUD_CLASS = TOPHUD_CLASS or {__index = TOPHUD_CLASS};

function TOPHUD_CLASS:__call( parameter, failSafe )
	return self:Query( parameter, failSafe );
end;

function TOPHUD_CLASS:__tostring()
	return "TOPHUD ["..self("name").."]";
end;

function TOPHUD_CLASS:IsValid()
	return self.data != nil;
end;

function TOPHUD_CLASS:Query( key, failSafe )
	if ( self.data and self.data[key] != nil ) then
		return self.data[key];
	else
		return failSafe;
	end;
end;

function TOPHUD_CLASS:New( tMergeTable )
	local object = { 
			data = {
				name = "Unknown",
				priority = 1,
				text = "",
				icon = Material("icon16/user.png"),
				uid = util.CRC( os.time() .. CurTime() .. SysTime().."_tophud" )
			}
		};

		if ( tMergeTable ) then
			table.Merge( object.data, tMergeTable );
		end;

		setmetatable( object, self );
		self.__index = self;
	return object;
end;

function TOPHUD_CLASS:SetData( key, value )
	if ( self:IsValid() and self.data[key] != nil ) then
		self.data[key] = value;
		return true;
	end;
end;

function TOPHUD_CLASS:Think() return; end;
function TOPHUD_CLASS:GetPriority() return self("priority", 1); end;
function TOPHUD_CLASS:GetName() return self("name", "Unknown"); end;
function TOPHUD_CLASS:GetText() return self("text", ""); end;
function TOPHUD_CLASS:GetIcon() return self("icon", Material("icon16/user.png")); end;
function TOPHUD_CLASS:UniqueID() return self("uid", -1); end;
function TOPHUD_CLASS:Register() return PLUGIN:RegisterHUD(self); end;

function PLUGIN:RegisterHUD( TOPHUD )
	if ( TOPHUD and TOPHUD:IsValid() ) then
		if ( !table.HasValue(  self.stored, TOPHUD ) ) then
			table.insert( self.stored, TOPHUD );

			self.buffer = {};

			local TOPHUD_COUNT = #self.stored;
			
			for i=1, TOPHUD_COUNT do
				local TOPHUD = self.stored[i];

				if ( TOPHUD and TOPHUD:IsValid() ) then
					local priority = TOPHUD:GetPriority();

					if ( !self.buffer[priority] ) then
						self.buffer[priority] = {};
					end;

					table.insert( self.buffer[priority], TOPHUD );
				end;
			end;
		end;
	end;
end;

function PLUGIN:Think()
	if ( IsValid(greenCode.Client) ) then
		local TOPHUD_COUNT = #self.stored;
		local bAdmin = greenCode.Client:IsAdmin();

		for i=1, TOPHUD_COUNT do
			local TOPHUD = self.stored[i];

			if ( TOPHUD and TOPHUD:IsValid() and bAdmin or !TOPHUD("onlyadmin", false) ) then
				TOPHUD:Think();
			end;
		end;

		self.alpha = math.Approach(self.alpha, TOPHUD_ALPHA, FrameTime() * 140);
	end;
end;

function PLUGIN:HUDPaint()
	local POS = 0;
	local scrW = ScrW();
	local bAdmin = greenCode.Client:IsAdmin();

	for k, stored in pairs( self.buffer ) do
		local TOPHUD_COUNT = #stored;

		for i=1, TOPHUD_COUNT do
			local TOPHUD = self.buffer[k][i];

			if ( TOPHUD and TOPHUD:IsValid() and bAdmin or !TOPHUD("onlyadmin", false) ) then
				local text = TOPHUD:GetText();
				local icon = TOPHUD:GetIcon();
				POS = POS + greenCode.kernel:GetCachedTextSize("ChatFont", text) + 40;

				surface.SetDrawColor( Color(255, 255, 255, self.alpha) )
				surface.SetMaterial( icon )
				surface.DrawTexturedRect(scrW - POS, 4, 16, 16 );
				draw.DrawText(text, "ChatFont", scrW - POS + 25, 5, Color(255,255,255,self.alpha), 0)
			end;
		end;
	end;
end;

greenCode:IncludeDirectory( PLUGIN:GetBaseDir().. "/elements/", false );