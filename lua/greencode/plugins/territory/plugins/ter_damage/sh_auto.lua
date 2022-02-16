--[[
	© 2013 GmodLive private project do not share
	without permission of its author (Andrew Mensky vk.com/men232).
--]]

local greenCode = greenCode;

local PLUGIN     = PLUGIN or greenCode.plugin:Loader();
local TER_PLUGIN = greenCode.plugin:Get("territory");

function PLUGIN:TerritorySystemInitialized()
	TERRITORY_PERMISSION_CLASS:New{ name = "takedamage", desc = "Access to take damage", default = true }:Register();
end;

function PLUGIN:CheckDamage( entity, attacker )
	local curTime = CurTime();

	if ( !attacker:IsPlayer() or entity == attacker ) then
		return;
	end;

	if ( !entity.gcLastCheckDamage ) then
		entity.gcLastCheckDamage = 0;
	end;

	if ( entity.gcLastCheckDamage < curTime ) then
		local TERRITORY = TER_PLUGIN:GetLocation( entity:GetPos() );

		if ( TERRITORY and TERRITORY:IsValid() ) then			
			if ( !TERRITORY:GetPermission( "takedamage", attacker, false ) ) then
				entity.gcLastCheckDamage = curTime + 1.5;
				return false, "На этой собственности нельзя нанести урон.";
			end;
		end;
	else
		return false, "На этой собственности нельзя нанести урон.";
	end;
end;

function PLUGIN:PlayerShouldTakeDamage( entity, attacker ) return self:CheckDamage( entity, attacker ); end;
function PLUGIN:EntityShouldTakeDamage( player, attacker ) return self:CheckDamage( player, attacker ); end;