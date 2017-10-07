--[[
	© 2013 GmodLive private project do not share
	without permission of its author (Andrew Mensky vk.com/men232).
--]]
if SERVER then return end;

local gc = gc;
local math = math;
local surface = surface;

local PLUGIN = PLUGIN or greenCode.plugin:Loader();

local SCREEN_DAMAGE_OVERLAY = Material("greencode/vgui/screendamagev2.png");
local VIGNETTE_OVERLAY = Material("greencode/vgui/vignette.png");
local SCREEN_DAMAGE_OVERLAY_EXIST = SCREEN_DAMAGE_OVERLAY_EXIST or false;
local VIGNETTE_OVERLAY_EXIST = VIGNETTE_OVERLAY_EXIST or false;

CREEN_DAMAG_ALPHA = 0;

function PLUGIN:DrawPlayerScreenDamage(damageFraction)
	if ( SCREEN_DAMAGE_OVERLAY_EXISTS ) then
		local scrW, scrH = ScrW(), ScrH();
		surface.SetDrawColor(255, 255, 255, math.Clamp(255 * damageFraction, 0, 255));
		surface.SetMaterial(SCREEN_DAMAGE_OVERLAY);
		surface.DrawTexturedRect(0, 0, scrW, scrH);
	end;
end;

function PLUGIN:DrawPlayerVignette()
	if ( VIGNETTE_OVERLAY_EXIST ) then
		if (!gc.gcVignetteAlpha) then
			gc.gcVignetteAlpha = 150;
			gc.gcVignetteAlphaDelta = gc.gcVignetteAlpha;
		end;

		local data = {};
			data.start = gc.Client:GetShootPos();
			data.endpos = data.start + (gc.Client:GetUp() * 512);
			data.filder = gc.Client;
		local trace = util.TraceLine(data);

		gc.gcVignetteAlpha = (!trace.HitWorld and !trace.HitNonWorld) and 150 or 255;
		gc.gcVignetteAlphaDelta = math.Approach(gc.gcVignetteAlphaDelta, gc.gcVignetteAlpha, FrameTime() * 70);

		local scrW, scrH = ScrW(), ScrH();

		surface.SetDrawColor(0, 0, 0, gc.gcVignetteAlphaDelta);
		surface.SetMaterial(VIGNETTE_OVERLAY);
		surface.DrawTexturedRect(0, 0, scrW, scrH);
	end;
end;

function PLUGIN:PostHUDPaint()
	//if (gc.Client:Alive()) then		
		if (CREEN_DAMAG_ALPHA > 0) then
			CREEN_DAMAG_ALPHA = math.Approach(CREEN_DAMAG_ALPHA, 0, FrameTime() * 70);
			gc.plugin:Call("DrawPlayerScreenDamage", CREEN_DAMAG_ALPHA/255);
		end;
	//end;
	
	if (gc.config:Get("enable_vignette"):Get()) then
		gc.plugin:Call("DrawPlayerVignette");
	end;
end;

-- Called when an entity takes damage.
function PLUGIN:Think()
	local curHealth = gc.Client:Health();

	if ( !self.hp ) then
		self.hp = gc.Client:Health();
	end;

	local amount = curHealth - self.hp;

	if ( amount < 0 ) then
		CREEN_DAMAG_ALPHA = math.Clamp( CREEN_DAMAG_ALPHA + amount*-10, 0, 255 );
		self.hp = curHealth;
	else
		self.hp = curHealth;
	end;
end;

function PLUGIN:InitPostEntity()
	timer.Simple(1, function()
		SCREEN_DAMAGE_OVERLAY_EXIST = file.Exists( "materials/greencode/vgui/screendamagev2.png", "GAME" ) ;
		VIGNETTE_OVERLAY_EXIST = file.Exists( "materials/greencode/vgui/vignette.png", "GAME" ) ;
	end);
end;