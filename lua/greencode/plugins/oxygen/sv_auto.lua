--[[
	© 2013 GmodLive private project do not share
	without permission of its author (Andrew Mensky vk.com/men232).
--]]
local PLUGIN = PLUGIN or greenCode.plugin:Loader();

-- Called when a player's character data should be saved.
function PLUGIN:PlayerSaveCharacterData( player, data )
	if (data["Oxygen"]) then
		data["Oxygen"] = math.Round(data["Oxygen"]);
	end;
end;

-- Called when a player's character data should be restored.
function PLUGIN:PlayerRestoreCharacterData( player, data )
	if (!data["Oxygen"]) then
		data["Oxygen"] = 100;
	end;
end;

-- Called just after a player spawns.
function PLUGIN:PlayerSpawn( player, bFirstSpawn, bInitialized )
	if ( bInitialized ) then
		player:SetCharacterData("Oxygen", 100);
	end;
end;

-- Called when a player's shared variables should be set.
function PLUGIN:PlayerSetPrivateVars( player, tPrivateData, curTime )
	/*local oxygen = player:GetCharacterData("Oxygen");
	local dif = oxygen - (player.gcPrevOxygen or 100);
	tPrivateData["Oxygen"] = math.Round( dif > 0 and oxygen or oxygen + dif );
	player.gcPrevOxygen = player:GetCharacterData("Oxygen", 100);*/

	tPrivateData["Oxygen"] = math.Round(player:GetCharacterData("Oxygen", 100));
end;

function PLUGIN:PlayerThink( player, curTime, infoTable, bAlive )
	if ( !bAlive ) then return; end;
	
	local bUnderWater;

	if ( !player:InVehicle() ) then
		bUnderWater = player:WaterLevel() > 2;
	else
		bUnderWater = player:GetVehicle():WaterLevel() > 2
	end;
	local decrease = !bUnderWater and 2 or -0.5;

	player:SetCharacterData("Oxygen", math.Clamp(player:GetCharacterData("Oxygen", 100) + decrease, 0, 100));

	local nOxygen = player:GetCharacterData("Oxygen", 100);
	
	if ( !player.gcLastAirTakeDamage ) then
		player.gcLastAirTakeDamage = curTime + 1;
	end;
	
	if ( player.gcLastAirTakeDamage < curTime and nOxygen < 1 ) then
		local dmginfo = DamageInfo()
		dmginfo:SetDamage( 1 );
		dmginfo:SetDamageType( DMG_FALL );
		dmginfo:SetDamageForce( Vector( 0, 0, -500 ) );
		dmginfo:SetAttacker( player );
		player:TakeDamageInfo( dmginfo );
		player.gcLastAirTakeDamage = nil;
	end;
	
	if ( bUnderWater ) then
		player:SetPrivateVar{ Oxygen = math.Round(nOxygen) };
	end;
end;