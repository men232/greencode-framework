--[[
	© 2013 GmodLive private project do not share
	without permission of its author (Andrew Mensky vk.com/men232).
--]]
local PLUGIN = PLUGIN or greenCode.plugin:Loader();

local gc = gc;
local math = math;

gc.config:Add("stam_drain_scale", 0.2, true);
gc.config:Add("breathing_volume", 1, true);
gc.config:Add("stam_jump_cost", 15, true);

//greenCode.config:Get("stam_jump_cost"):Set(15)

-- Called when a player's character data should be saved.
function PLUGIN:PlayerSaveCharacterData( player, data )
	if (data["Stamina"]) then
		data["Stamina"] = math.Round(data["Stamina"]);
	end;
end;

-- Called when a player's character data should be restored.
function PLUGIN:PlayerRestoreCharacterData( player, data )
	if (!data["Stamina"]) then
		data["Stamina"] = 100;
	end;
end;

-- Called just after a player spawns.
function PLUGIN:PlayerSpawn( player, bFirstSpawn, bInitialized )
	if ( bInitialized ) then
		player:SetCharacterData("Stamina", 100);
		player.gcStamChange = true;
		gc.player:StopSound( player, "LowStamina" );
	end;
end;

-- Called when player death.
function PLUGIN:PlayerDeath( player )
	gc.player:StopSound( player, "LowStamina" );
end;

-- Called when a player's shared variables should be set.
function PLUGIN:PlayerSetPrivateVars( player, tPrivateData, curTime )
	/*local stamina = player:GetCharacterData("Stamina");
	local dif = stamina - (player.gcPrevStamina or 100);
	tPrivateData["Stamina"] = math.Round( dif > 0 and stamina or stamina + dif );
	player.gcPrevStamina = player:GetCharacterData("Stamina", 100);*/

	tPrivateData["Stamina"] = math.Round(player:GetCharacterData("Stamina", 100));
end;

-- Called when a player's stamina should regenerate.
function PLUGIN:PlayerShouldStaminaRegenerate( player )
	return true;
end;

-- Called at an interval while a player is connected.
function PLUGIN:PlayerThink( player, curTime, infoTable, bAlive )
	if ( !bAlive ) then
		return;
	end;
	
	local regeneration = 0;
	local attribute = gc.attributes:Fraction(player, ATB_STAMINA, 1, 0.25);
	local scale = gc.config:Get("stam_drain_scale"):Get(0.2);
	local bOnGround = player:IsOnGround();
	local bNoclip = gc.player:IsNoClipping(player);
	local jump_cost = gc.config:Get("stam_jump_cost"):Get(15);
	
	if ( bOnGround ) then
		player.gcJump = false;
	end;
	
	if ( !bNoclip and !bOnGround and !player.gcJump and ( player:KeyDown( IN_JUMP ) or player:KeyDownLast( IN_JUMP ) ) ) then
		local decrease = ( 1.2 - attribute )*jump_cost;
		player:SetCharacterData("Stamina", math.Clamp(player:GetCharacterData("Stamina") - decrease, 0, 100));
		player.gcStamChange = true;
		player.gcJump = true;
		
	elseif (infoTable.isRunning or infoTable.isJogging and !bNoclip ) then
		local nMaxHealth = player:GetMaxHealth()*5;
		local decrease = (scale + (scale - ( math.min(player:Health(),  nMaxHealth) / nMaxHealth ))) / (scale + attribute);

		player:SetCharacterData("Stamina", math.Clamp(player:GetCharacterData("Stamina") - decrease, 0, 100));
		
		if (player:GetCharacterData("Stamina") > 1) then
			if (infoTable.isRunning) then
				player:ProgressAttribute(ATB_STAMINA, 0.025, true);
			elseif (infoTable.isJogging) then
				player:ProgressAttribute(ATB_STAMINA, 0.0125, true);
			end;
		end;
	elseif (player:GetVelocity():Length() == 0 or player:InVehicle()) then
		if (player:Crouching()) then
			regeneration = scale * 0.3;
		elseif player:InVehicle() then
			regeneration = scale * 0.6;
		else
			regeneration = scale * 0.15;
		end;
	else
		regeneration = scale * 0.05;
	end;

	if (regeneration > 0 and gc.plugin:Call("PlayerShouldStaminaRegenerate", player)) then
		if ( player:GetCharacterData("Stamina") < 50 ) then regeneration = regeneration *0.5; end;
		player:SetCharacterData("Stamina", math.Clamp(player:GetCharacterData("Stamina") + regeneration, 0, 100));
	end;
	
	local newRunSpeed = infoTable.runSpeed * 2;
	local diffRunSpeed = newRunSpeed - infoTable.walkSpeed;
	local stamina = player:GetCharacterData("Stamina", 100);

	infoTable.runSpeed = math.Max( newRunSpeed - (diffRunSpeed - ((diffRunSpeed / 100) * stamina)), infoTable.walkSpeed );
	
	if ( stamina < 45 ) then
		infoTable.jumpPower = infoTable.jumpPower * ( stamina / 45 );
	end;
	
	if (infoTable.isJogging) then
		local walkSpeed = gc.config:Get("walk_speed"):Get();
		local newWalkSpeed = walkSpeed * 1.75;
		local diffWalkSpeed = newWalkSpeed - walkSpeed;

		infoTable.walkSpeed = newWalkSpeed - (diffWalkSpeed - ((diffWalkSpeed / 100) * stamina));
		
		if (player:GetCharacterData("Stamina") < 1) then
			player:SetSharedVar{ IsJogMode = false };
		end;
	end;
	
	local bPlayerBreathSnd = ( stamina < 30 );
	
	if (!player.nextBreathingSound or curTime >= player.nextBreathingSound) then
		if (!gc.player:IsNoClipping(player)) then
			player.nextBreathingSound = curTime + 1;
			
			if (bPlayerBreathSnd) then
				local volume = gc.config:Get("breathing_volume"):Get() - ( stamina / 30 );
				gc.player:StartSound( player, "LowStamina", "player/breathe1.wav", volume );
			else
				gc.player:StopSound( player, "LowStamina", 4 );
			end;
		end;
	end;
	
	if ( infoTable.isRunning or player.gcStamChange ) then
		player:SetPrivateVar{ Stamina = math.Round(stamina) };
		player.gcStamChange = false;
	end;
end;

-- Called when a player throws a punch.
function PLUGIN:PlayerPunchThrown( player )
	local attribute = greenCode.attributes:Fraction(player, ATB_STAMINA, 1.5, 0.25);
	local decrease = 5 / (1 + attribute);
	local stamina = math.Clamp(player:GetCharacterData("Stamina") - decrease, 0, 100);
	
	player:SetCharacterData("Stamina", stamina);
	player.gcStamChange = true;
end;

function PLUGIN:PlayerTakeDamage( player, inflictor, attacker, lastHitGroup, damageInfo, curTime )
	if (!player.nextEnduranceTime or curTime > player.nextEnduranceTime) then
		player:ProgressAttribute(ATB_STAMINA, math.Clamp(damageInfo:GetDamage(), 0, 75) / 10, true);
		player.nextEnduranceTime = curTime + 2;
	end;

	local stamina = math.Clamp(player:GetCharacterData("Stamina", 100) - damageInfo:GetDamage()*0.8, 0, 100);
	player:SetCharacterData("Stamina", stamina );
	player.gcStamChange = true;
end;

-- Called when an entity takes damage.
function PLUGIN:EntityTakeDamage( entity, inflictor, attacker, amount, damageInfo, curTime )
	if (attacker:IsPlayer()) then		
		if (damageInfo:IsDamageType(DMG_CLUB) or damageInfo:IsDamageType(DMG_SLASH)) then
			local stamina = math.Round(attacker:GetCharacterData("Stamina", 100));
			damageInfo:ScaleDamage( math.Clamp( stamina, 1, 50 ) / 50 );
		end;
	end;
end;

function PLUGIN:PlayerSilentDeath( player )
	-- Normal death, respawning.
	player.NextSpawnTime = CurTime() + (GAMEMODE.Config.respawntime or 2);
end;