--[[
	© 2013 GmodLive private project do not share
	without permission of its author (Andrew Mensky vk.com/men232).
--]]

local greenCode = greenCode;

local PLUGIN     = PLUGIN or greenCode.plugin:Loader();
local TER_PLUGIN = greenCode.plugin:Get("territory");

function PLUGIN:TerritorySystemInitialized()
	TERRITORY_PERMISSION_CLASS:New{ name = "spawnobject", desc = "Permission for spawn object", default = false }:Register();
end;

if CLIENT then return end;

function PLUGIN:PlayerSpawnObject( player )
	local TERRITORY = TER_PLUGIN:GetLocation( player:GetEyeTrace().HitPos + Vector( 0,0,5 ) );

	if ( TERRITORY and TERRITORY:IsValid() ) then
		if ( !TERRITORY:GetPermission( "spawnobject", player, false ) ) then
			player:ShowAlert( "На этой территории запрещен spawnobject.", Color(255,150,150,255) );
			return false;
		end;
	end;
end;

function PLUGIN:PlayerSpawnSENT( player ) return self:PlayerSpawnObject( player ); end;
function PLUGIN:PlayerSpawnSWEP( player ) return self:PlayerSpawnObject( player ); end;
function PLUGIN:PlayerSpawnVehicle( player ) return self:PlayerSpawnObject( player ); end;
function PLUGIN:PlayerSpawnProp( player ) return self:PlayerSpawnObject( player ); end;
function PLUGIN:PlayerSpawnEffect( player ) return self:PlayerSpawnObject( player ); end;
function PLUGIN:PlayerSpawnRagdoll( player ) return self:PlayerSpawnObject( player ); end;
function PLUGIN:PlayerSpawnNPC( player ) return self:PlayerSpawnObject( player ); end;