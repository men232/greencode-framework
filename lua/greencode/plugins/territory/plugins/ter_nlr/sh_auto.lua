--[[
	© 2013 GmodLive private project do not share
	without permission of its author (Andrew Mensky vk.com/men232).
--]]

local greenCode = greenCode;
local os        = os;
local CurTime   = CurTime;
local math      = math;

local PLUGIN     = PLUGIN or greenCode.plugin:Loader();
local TER_PLUGIN = greenCode.plugin:Get("territory");

local playerMeta = FindMetaTable("Player");

function PLUGIN:TerritorySystemInitialized()
	TERRITORY_PERMISSION_CLASS:New{ name = "nlr", desc = "Access to ignore nlr", default = false }:Register();
end;

if SERVER then
	-- A function to set nlr.
	function playerMeta:IsNLR() return self:GetCharacterData("NLRTime", 0) > os.time() and self:GetCharacterData("NLRZone", -1) == self:GetSharedVar("territory") end;

	function PLUGIN:PlayerThink( player, curTime, infoTable, bAlive )
		if ( player:GetCharacterData("NLRTime", 0) > os.time() ) then
			
			if ( player:GetCharacterData("NLRZone", -1) == player:GetSharedVar("territory") ) then
				infoTable.DSP = 16;
			end;
		end;
	end;

	function PLUGIN:PlayerCharacterInitialized( player )
		greenCode.datastream:Start( player, "TerNLRData", {
			uid = player:GetCharacterData("NLRZone", -1),
			time = player:GetCharacterData("NLRTime", 0) - os.time()
		});
	end;

	-- Called when a player dies.
	function PLUGIN:PlayerDeath( player, inflictor, attacker, damageInfo )
		local TERRITORY = TER_PLUGIN:GetLocation( player:GetShootPos() );
		local tSendData = { uid = -1, time = 0 };

		if ( TERRITORY and TERRITORY:IsValid() and TERRITORY != WORLD_TERRITORY ) then
			if ( !TERRITORY:GetPermission( "nlr", player, false ) ) then
				tSendData = {
					uid = TERRITORY:UniqueID(),
					time = CurTime() + gc.config:Get("nlr_time"):Get(5*60)
				};
			end
		end;

		player:SetCharacterData("NLRZone", tSendData.uid);
		player:SetCharacterData("NLRTime", os.time() + gc.config:Get("nlr_time"):Get(5*60));

		greenCode.datastream:Start( player, "TerNLRData", tSendData);
	end;
else
	PLUGIN.NLRZone  = PLUGIN.NLRZone or -1;
	PLUGIN.NLRTime  = PLUGIN.NLRTime or 0;
	PLUGIN.Alpha    = PLUGIN.Alpha or 0;
	PLUGIN.Material = PLUGIN.Material or Material( "models/props_combine/stasisshield_sheet" );

	greenCode.datastream:Hook( "TerNLRData", function(tData)
		PLUGIN.NLRZone = tData.uid;
		PLUGIN.NLRTime = tData.time;
	end);

	function PLUGIN:Tick( curTime )
		if ( self.NLRTime > curTime ) then
			local player = greenCode.Client;
			self.Alive   = player:Alive();
			self.IsNLR   = self.Alive and TER_PLUGIN:GetLocation( player:GetShootPos() ):UniqueID() == self.NLRZone;
			self.BanTime = self.IsNLR and self.BanTime or curTime + 10;
		else
			self.IsNLR = false;
			self.BanTime = curTime;
		end;
	end;

	function PLUGIN:TickSecond( curTime )
		if ( self.IsNLR and self.BanTime < curTime ) then
			RunConsoleCommand("gc_ter_nlrban");
		end;
	end;

	function PLUGIN:RenderScreenspaceEffects( tPPData )
		if ( self.Alpha > 0 ) then
			tPPData["enable"] = true;
			tPPData["$pp_colour_colour"] = tPPData["$pp_colour_colour"] - (self.Alpha / 300);
		end;
	end;

	function PLUGIN:HUDPaint()
		self.Alpha = math.Clamp(self.Alpha + ( (self.IsNLR and 150 or -150) *FrameTime()), 0, 255);

		if ( self.Alpha > 0 ) then
			local curTime = CurTime();
			local nPastTime = math.Round(self.NLRTime - curTime);
			local nBanTime = math.Round(self.BanTime - curTime);

			local sWarningText = "Вернитесь!\nВы умерли здесь, не нарушайте правило NLR: "..
				greenCode.kernel:ConvertTime( nPastTime > 0 and nPastTime or 0 ).."\n"..
				"Автоматический бан через: "..(nBanTime > 0 and nBanTime or 0).." сек.";

			surface.SetDrawColor( 0, 0, 0, math.Clamp(self.Alpha, 0, 200) );
			surface.DrawRect(0 , 0, ScrW(), ScrH() );
			draw.DrawText( sWarningText, "gcMenuTextBig", ScrW() / 2, ScrH() / 2 - 73, Color(0,0,0,self.Alpha), TEXT_ALIGN_CENTER );
			draw.DrawText( sWarningText, "gcMenuTextBig", ScrW() / 2, ScrH() / 2 - 75, Color(255,0,0,self.Alpha), TEXT_ALIGN_CENTER );
		end;
	end;

	-- Called when drawing territory.
	function PLUGIN:OnTerritoryDraw( TERRITORY, tCords, nVertex, bDraw )
		if ( self.NLRTime > CurTime() and self.NLRZone == TERRITORY:UniqueID() ) then
			cam.Start3D(EyePos(), EyeAngles());
				render.SetMaterial( self.Material );
				local count = #tCords;
				for i, vPos1 in pairs( tCords ) do
					local vPos2 = ( i == count ) and tCords[1] or tCords[i+1];
					render.DrawQuad( vPos1 + Vector(0,0, nVertex), vPos2 + Vector(0,0, nVertex), vPos2, vPos1 );
				end;
			cam.End3D();

			return true;
		end;
	end;
end;

if SERVER then
	greenCode.command:Add( "ter_nlrban", 0, function( player, command, args )
		if ( !player:IsAdmin() ) then
			ULib.kickban( player, 10, "Нарушение правила NLR.", nil );
		end;
	end);
end;