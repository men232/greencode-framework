--[[
	© 2013 GmodLive private project do not share
	without permission of its author (Andrew Mensky vk.com/men232).
--]]
local PLUGIN = PLUGIN or greenCode.plugin:Loader();
local gc = gc;

/*PLUGIN.HitGroupBonesCache = {
	{"ValveBiped.Bip01_R_UpperArm", HITGROUP_RIGHTARM},
	{"ValveBiped.Bip01_R_Forearm", HITGROUP_RIGHTARM},
	{"ValveBiped.Bip01_L_UpperArm", HITGROUP_LEFTARM},
	{"ValveBiped.Bip01_L_Forearm", HITGROUP_LEFTARM},
	{"ValveBiped.Bip01_R_Thigh", HITGROUP_RIGHTLEG},
	{"ValveBiped.Bip01_R_Calf", HITGROUP_RIGHTLEG},
	{"ValveBiped.Bip01_R_Foot", HITGROUP_RIGHTLEG},
	{"ValveBiped.Bip01_R_Hand", HITGROUP_RIGHTARM},
	{"ValveBiped.Bip01_L_Thigh", HITGROUP_LEFTLEG},
	{"ValveBiped.Bip01_L_Calf", HITGROUP_LEFTLEG},
	{"ValveBiped.Bip01_L_Foot", HITGROUP_LEFTLEG},
	{"ValveBiped.Bip01_L_Hand", HITGROUP_LEFTARM},
	{"ValveBiped.Bip01_Pelvis", HITGROUP_STOMACH},
	{"ValveBiped.Bip01_Spine2", HITGROUP_CHEST},
	{"ValveBiped.Bip01_Spine1", HITGROUP_CHEST},
	{"ValveBiped.Bip01_Head1", HITGROUP_HEAD},
	{"ValveBiped.Bip01_Neck1", HITGROUP_HEAD}
};*/

-- Called when a player's pain sound should be played.
function PLUGIN:PlayerPlayPainSound(player, gender, damageInfo, hitGroup)
	if (damageInfo:IsBulletDamage() and math.random() <= 0.5) then
		if (hitGroup == HITGROUP_HEAD) then
			return "vo/npc/"..gender.."01/ow0"..math.random(1, 2)..".wav";
		elseif (hitGroup == HITGROUP_CHEST or hitGroup == HITGROUP_GENERIC) then
			return "vo/npc/"..gender.."01/hitingut0"..math.random(1, 2)..".wav";
		elseif (hitGroup == HITGROUP_LEFTLEG or hitGroup == HITGROUP_RIGHTLEG) then
			return "vo/npc/"..gender.."01/myleg0"..math.random(1, 2)..".wav";
		elseif (hitGroup == HITGROUP_LEFTARM or hitGroup == HITGROUP_RIGHTARM) then
			return "vo/npc/"..gender.."01/myarm0"..math.random(1, 2)..".wav";
		elseif (hitGroup == HITGROUP_GEAR) then
			return "vo/npc/"..gender.."01/startle0"..math.random(1, 2)..".wav";
		end;
	end;
	
	return "vo/npc/"..gender.."01/pain0"..math.random(1, 9)..".wav";
end;

-- A function to scale damage by hit group.
function PLUGIN:PlayerScaleDamageByHitGroup(player, attacker, hitGroup, damageInfo, baseDamage)
	local strenght = greenCode.attributes:Fraction(player, ATB_STRENGTH, 0.75, 0.75);
	damageInfo:ScaleDamage(1.5 - strenght);

	if (attacker:IsVehicle() or (attacker:IsPlayer() and attacker:InVehicle())) then
		damageInfo:ScaleDamage(0.25);
	end;
end;

local BLACK_PUNCH_THROWN_LIST = {
	["test"] = true,
}

-- Called when an entity takes damage.
function PLUGIN:EntityTakeDamage( entity, inflictor, attacker, amount, damageInfo, curTime )
	if (attacker:IsPlayer()) then		
		if (damageInfo:IsDamageType(DMG_CLUB) or damageInfo:IsDamageType(DMG_SLASH)) then
			if ( greenCode.entity:IsDoor( entity ) or BLACK_PUNCH_THROWN_LIST[entity:GetClass()] ) then
				return;
			end;
			
			damageInfo:ScaleDamage(1 +  gc.attributes:Fraction(attacker, ATB_STRENGTH, 1, 0.5) );

			if ( attacker:GetCharacterData("Stamina", 100) > 5 ) then
				if (entity:IsPlayer() or entity:IsNPC()) then
					attacker:ProgressAttribute(ATB_STRENGTH, 1, true);
				else
					attacker:ProgressAttribute(ATB_STRENGTH, 0.5, true);
				end;
			end;
		end;
	end;
end;

-- Called when a player's fall damage is needed.
function PLUGIN:GetFallDamage(player, velocity)
	local acrobatics = gc.attributes:Fraction( player, ATB_ACROBATICS, 100, 50 );
	local position = player:GetPos();
	local damage = math.max((velocity - 464 - acrobatics) * 0.225225225, 0) * gc.config:Get("scale_fall_damage"):Get();
	local filter = {player};
	
	if (gc.config:Get("wood_breaks_fall"):Get()) then		
		local traceLine = util.TraceLine({
			endpos = position - Vector(0, 0, 64),
			start = position,
			filter = filter
		});

		if (IsValid(traceLine.Entity) and traceLine.MatType == MAT_WOOD) then
			if (string.find(traceLine.Entity:GetClass(), "prop_physics")) then
				traceLine.Entity:Fire("Break", "", 0);
				damage = damage * 0.25;
			end;
		end;
	end;
	
	return damage;
end;

-- Called when a player's limb damage is healed.
function PLUGIN:PlayerLimbDamageHealed(player, hitGroup, amount)
	if (hitGroup == HITGROUP_HEAD) then
		player:BoostAttribute("Перелом", ATB_MEDICAL, false);
	elseif (hitGroup == HITGROUP_CHEST or hitGroup == HITGROUP_STOMACH) then
		player:BoostAttribute("Перелом", ATB_ENDURANCE, false);
	elseif (hitGroup == HITGROUP_LEFTLEG or hitGroup == HITGROUP_RIGHTLEG) then
		player:BoostAttribute("Перелом", ATB_ACROBATICS, false);
		player:BoostAttribute("Перелом", ATB_AGILITY, false);
	elseif (hitGroup == HITGROUP_LEFTARM or hitGroup == HITGROUP_RIGHTARM) then
		player:BoostAttribute("Перелом", ATB_DEXTERITY, false);
		player:BoostAttribute("Перелом", ATB_STRENGTH, false);
	end;
end;

-- Called when a player's limb damage is reset.
function PLUGIN:PlayerLimbDamageReset(player)
	player:BoostAttribute("Перелом", nil, false);
end;

-- Called when a player's limb takes damage.
function PLUGIN:PlayerLimbTakeDamage(player, hitGroup, damage)
	local limbDamage = gc.limb:GetDamage(player, hitGroup);
	
	if (hitGroup == HITGROUP_HEAD) then
		player:BoostAttribute("Перелом", ATB_MEDICAL, -limbDamage);
	elseif (hitGroup == HITGROUP_CHEST or hitGroup == HITGROUP_STOMACH) then
		player:BoostAttribute("Перелом", ATB_ENDURANCE, -limbDamage);
	elseif (hitGroup == HITGROUP_LEFTLEG or hitGroup == HITGROUP_RIGHTLEG) then
		player:BoostAttribute("Перелом", ATB_ACROBATICS, -limbDamage);
		player:BoostAttribute("Перелом", ATB_AGILITY, -limbDamage);
	elseif (hitGroup == HITGROUP_LEFTARM or hitGroup == HITGROUP_RIGHTARM) then
		player:BoostAttribute("Перелом", ATB_DEXTERITY, -limbDamage);
		player:BoostAttribute("Перелом", ATB_STRENGTH, -limbDamage);
	end;
end;

function PLUGIN:PlayerThink( player, curTime, infoTable, bAlive )
	if ( bAlive and infoTable.state < 0.5 ) then
		local fVolume = math.Clamp(1 - infoTable.state, 0.1, 1);
		greenCode.player:StartSound( player, "HeartBeat", "player/heartbeat1.wav", fVolume );

		local agility = greenCode.attributes:Fraction(player, ATB_STAMINA, 0.35, 0);
		local strength = greenCode.attributes:Fraction(player, ATB_STRENGTH, 0.35, 0);

		local fractionHealth = math.Clamp(player.gcInfoTable.state + strength + agility, 0.1, 1.3 );

		infoTable.walkSpeed = infoTable.walkSpeed * fractionHealth;
		infoTable.jumpPower = infoTable.jumpPower * fractionHealth;
		infoTable.runSpeed = infoTable.runSpeed * fractionHealth;

		if ( !player.gcLastCough ) then
			player.gcLastCough = curTime + (fractionHealth * 30) + math.random(1, 4);
		end;

		if (curTime > player.gcLastCough) then
			player:EmitSound("ambient/voices/cough"..math.random(1, 4)..".wav");
			player.gcLastCough = nil;
		end;
	else
		gc.player:StopSound( player, "HeartBeat", 4 );
	end;

	infoTable.DSP = infoTable.state <= 0.25 and 16 or infoTable.state <= 0.5 and 15 or infoTable.state <= 0.75 and 14 or infoTable.DSP;
end;