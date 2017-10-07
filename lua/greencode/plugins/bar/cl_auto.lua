--[[
	© 2013 GmodLive private project do not share
	without permission of its author (Andrew Mensky vk.com/men232).
--]]

local greenCode = greenCode;
local math = math;

local PLUGIN = PLUGIN or greenCode.plugin:Loader();
PLUGIN.stored = {};
PLUGIN.buffer = {};
PLUGIN.alpha = 0;

local rightBarToLeft = CreateClientConVar( "cl_gc_rightbar_toleft", 0, true );
local rightBarToDown = CreateClientConVar( "cl_gc_rightbar_down", 0, true );
local barHide = CreateClientConVar( "cl_gc_barhide", 1, true );

BAR_ALPHA = 255;

--[[ Define the bar class metatable. --]]
BAR_CLASS = BAR_CLASS or {__index = BAR_CLASS};

function BAR_CLASS:__call( parameter, failSafe )
	return self:Query( parameter, failSafe );
end;

function BAR_CLASS:__tostring()
	return "BAR ["..self("name").."]";
end;

function BAR_CLASS:IsValid()
	return self.data != nil;
end;

function BAR_CLASS:Query( key, failSafe )
	if ( self.data and self.data[key] != nil ) then
		return self.data[key];
	else
		return failSafe;
	end;
end;

function BAR_CLASS:New( tMergeTable )
	local object = { 
			data = {
				name = "Unknown",
				text = "",
				color = Color(255,255,255),
				alpha = 255;
				x = ScrW(),
				y = ScrH(),
				idealX = ScrW(),
				idealY = ScrH(),
				width = 350,
				height = 10,
				value = 100,
				maximum = 100,
				delay = 5,
				hide = true,
				required = false,
				flash = false
			}
		};

		if ( tMergeTable ) then
			table.Merge( object.data, tMergeTable );
		end;

		setmetatable( object, self );
		self.__index = self;
	return object;
end;

function BAR_CLASS:SetData( key, value )
	if ( self:IsValid() and self.data[key] != nil ) then
		self.data[key] = value;
		return true;
	end;
end;

function BAR_CLASS:SetPos( x, y, quick, org )
	self:SetData("idealX", x);
	self:SetData("idealY", y);
	
	if ( quick ) then
		self:SetData("x", x);
		self:SetData("y", y);
	end;
	
	if ( org ) then
		self.orgX, self.orgY = x, y;
	end;
end;

function BAR_CLASS:GetOrgPos()
	return self.orgX or self("idealX", 0), self.orgY or self("idealY", 0);
end;

function BAR_CLASS:Hide()
	local x = self:GetOrgPos();
	self:SetPos( x, ScrH() );
	self.showDelay = 0;
	self.hide = true;
end;

function BAR_CLASS:Show()
	self:SetPos( self:GetOrgPos() );
	self.showDelay = CurTime() + self("delay", 5);
	self.hide = false;
end;

function BAR_CLASS:IsHide() return self.hide; end;

function BAR_CLASS:Think() return end;
function BAR_CLASS:Register() return PLUGIN:RegisterBAR(self); end;

function PLUGIN:RegisterBAR( BAR )
	if ( BAR and BAR:IsValid() ) then
		if ( !table.HasValue(  self.stored, BAR ) ) then
			table.insert( self.stored, BAR );
			return self.stored[#self.stored];
		end;
	end;
end;

function PLUGIN:HUDPaint()
	if ( IsValid(greenCode.Client) ) then
		local frameTime = FrameTime();		
		local BAR_COUNT = #self.stored;
		local scrW, scrH = ScrW(), ScrH();
		local curTime = CurTime();
		local bHideEnable = barHide:GetBool();
		
		self.alpha = math.Approach(self.alpha, BAR_ALPHA, frameTime * 140);

		for i=1, BAR_COUNT do
			local BAR = self.stored[i];
			
			if ( BAR:IsValid() ) then
				local x = BAR("x", 0);
				local y = BAR("y", 0);
				local curValue = BAR("value", 0);
				local maximum = BAR("maximum", 0);
				local delay = BAR("delay", 5);
				local bHide = BAR("hide");
				local bRequired = BAR("required");
				local bHiden = BAR:IsHide();
				
				BAR.progress = math.Approach( BAR.progress or 0, curValue, frameTime*50);
				
				if ( bHide ) then
					if ( !bHideEnable or BAR.progress != curValue ) then
						BAR:Show();		
					elseif ( !bHiden and (BAR.showDelay or 0) < curTime and ( bRequired and BAR.progress == maximum or !bRequired ) ) then
						BAR:Hide();
					end;
				end;
				
				if ( x < scrW or y < scrH ) then
					local c = BAR("color", Color(255,255,255))
					greenCode.kernel:DrawBar(
						x, y, BAR("width", 350), BAR("height", 15), Color( c.r, c.g, c.b, math.min(self.alpha, BAR("alpha", 255)) ),
						BAR("text"), BAR.progress, BAR("maximum", 100), BAR("flash", false)
					);
				end;
				
				BAR:SetData( "x", math.Approach( x, BAR("idealX", 0), frameTime*500) );
				BAR:SetData( "y", math.Approach( y, BAR("idealY", 0), frameTime*500) );
			end;
		end;
	end;
end;

function PLUGIN:CreateGroup( id, x, y, align, padding )
	self.buffer[id] = { x = x, y = y, align = align, padding = padding, bars = {} };
end;

function PLUGIN:AddToHroup( id, BAR )
	if ( self.buffer[id] ) then
		table.insert( self.buffer[id].bars, BAR );
		BAR:SetData("x", self.buffer[id].x);
		BAR:SetData("y", ScrH());
	end;
end;

function PLUGIN:Think()
	if ( IsValid(greenCode.Client) ) then
		local BAR_COUNT = #self.stored;
		for i=1, BAR_COUNT do
			local BAR = self.stored[i];

			if ( BAR and BAR:IsValid() ) then
				BAR:Think();
			end;
		end;
		
		for k, v in pairs(self.buffer) do
			local count = 0;
			local padding = 0;
			
			for k, BAR in pairs(v.bars) do
				if ( !BAR:IsHide() ) then
					local height = BAR("height");
					padding = (height*(1-count)) + (padding + v.padding + height)*count; //( v.padding*count );
					BAR:SetPos( v.x, v.y + (v.align == 1 and padding or -padding), false, true );
					count = 1;
				end;
			end;
		end;
	end;
end;

PLUGIN:CreateGroup( 1, ScrW()-355, ScrH()-5, 2, 2 );
PLUGIN:CreateGroup( 2, 5, ScrH()-5, 2, 5 );

-- Stamina
BAR_STAMINA = BAR_CLASS:New{ height = 10, required = true, name = "Stamina", color = Color(255,255,0) };
	function BAR_STAMINA:Think()
		 self:SetData("value", greenCode.Client:GetSharedVar("Stamina", 100));
	end;
BAR_STAMINA:Register();

-- Oxygen
BAR_OXYGEN = BAR_CLASS:New{ height = 10, name = "Oxygen", color = Color(0,255,255) };
	function BAR_OXYGEN:Think()
		 self:SetData("value", greenCode.Client:GetSharedVar("Oxygen", 100));
	end;
BAR_OXYGEN:Register();
	
-- Health
BAR_HEALTH = BAR_CLASS:New{ height = 20, required = true, flash = true, name = "Health", color = Color(255,0,0) };
	function BAR_HEALTH:Think()
		 self:SetData("value", greenCode.Client:Health());
		 self:SetData("maximum", greenCode.Client:GetMaxHealth());
	end;
BAR_HEALTH:Register();

-- Armor
BAR_ARMOR = BAR_CLASS:New{ height = 20, name = "Armor", color = Color(0,200,255) };
	function BAR_ARMOR:Think()
		 self:SetData("value", greenCode.Client:Armor());
		 self:SetData("maximum", greenCode.Client:GetMaxArmor());
	end;
BAR_ARMOR:Register();

-- Hunger
BAR_HUNGER = BAR_CLASS:New{ height = 20, name = "Hunger", color = Color(0,255,0) };
	function BAR_HUNGER:Think()
		 self:SetData("value", math.ceil(greenCode.kernel:GetRpVar("Energy", 100)));
	end;
BAR_HUNGER:Register();

local id = rightBarToLeft:GetBool() and 2 or 1;

if ( !rightBarToDown:GetBool() ) then
	PLUGIN:AddToHroup( id, BAR_STAMINA );
	PLUGIN:AddToHroup( id, BAR_OXYGEN );
end;

PLUGIN:AddToHroup( 2, BAR_HUNGER );
PLUGIN:AddToHroup( 2, BAR_ARMOR );
PLUGIN:AddToHroup( 2, BAR_HEALTH );

if ( rightBarToDown:GetBool() ) then
	PLUGIN:AddToHroup( id, BAR_STAMINA );
	PLUGIN:AddToHroup( id, BAR_OXYGEN );
end;

greenCode.command:Add( "showbar", 0, function( player, command, args )
	curTime = CurTime();

	local BAR_COUNT = #PLUGIN.stored;

	for i=1, BAR_COUNT do
		local BAR = PLUGIN.stored[i];
		BAR:Show();
	end;
end);

greenCode.command:Add( "hidebar", 0, function( player, command, args )
	curTime = CurTime();

	local BAR_COUNT = #PLUGIN.stored;

	for i=1, BAR_COUNT do
		local BAR = PLUGIN.stored[i];
		BAR:Hide();
	end;
end);