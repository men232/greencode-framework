--[[
	© 2013 GmodLive private project do not share
	without permission of its author (Andrew Mensky vk.com/men232).
--]]

local gc = gc;
local Material = Material;
local Color = Color;
local pairs = pairs;
local type = type;
local table = table;
local math = math;

gc.limb = gc.kernel:NewLibrary("Limb");
gc.limb.bones = {
	["ValveBiped.Bip01_R_UpperArm"] = HITGROUP_RIGHTARM,
	["ValveBiped.Bip01_R_Forearm"] = HITGROUP_RIGHTARM,
	["ValveBiped.Bip01_L_UpperArm"] = HITGROUP_LEFTARM,
	["ValveBiped.Bip01_L_Forearm"] = HITGROUP_LEFTARM,
	["ValveBiped.Bip01_R_Thigh"] = HITGROUP_RIGHTLEG,
	["ValveBiped.Bip01_R_Calf"] = HITGROUP_RIGHTLEG,
	["ValveBiped.Bip01_R_Foot"] = HITGROUP_RIGHTLEG,
	["ValveBiped.Bip01_R_Hand"] = HITGROUP_RIGHTARM,
	["ValveBiped.Bip01_L_Thigh"] = HITGROUP_LEFTLEG,
	["ValveBiped.Bip01_L_Calf"] = HITGROUP_LEFTLEG,
	["ValveBiped.Bip01_L_Foot"] = HITGROUP_LEFTLEG,
	["ValveBiped.Bip01_L_Hand"] = HITGROUP_LEFTARM,
	["ValveBiped.Bip01_Pelvis"] = HITGROUP_STOMACH,
	["ValveBiped.Bip01_Spine2"] = HITGROUP_CHEST,
	["ValveBiped.Bip01_Spine1"] = HITGROUP_CHEST,
	["ValveBiped.Bip01_Head1"] = HITGROUP_HEAD,
	["ValveBiped.Bip01_Neck1"] = HITGROUP_HEAD
};

-- A function to convert a bone to a hit group.
function gc.limb:BoneToHitGroup(bone)
	return self.bones[bone] or HITGROUP_CHEST;
end;

-- A function to get whether limb damage is active.
function gc.limb:IsActive()
	return true; //gc.config:Get("limb_damage_system"):Get();
end;

if (SERVER) then
	function gc.limb:TakeDamage(player, hitGroup, damage)
		local newDamage = math.ceil(damage);
		local limbData = player:GetCharacterData("LimbData");
		
		if (limbData) then
			limbData[hitGroup] = math.min((limbData[hitGroup] or 0) + newDamage, 100);
			
			gc.datastream:Start(player, "TakeLimbDamage", {
				hitGroup = hitGroup, damage = newDamage
			});
			
			gc.plugin:Call("PlayerLimbTakeDamage", player, hitGroup, newDamage);
		end;
	end;
	
	-- A function to heal a player's body.
	function gc.limb:HealBody(player, amount)
		local limbData = player:GetCharacterData("LimbData");
		
		if (limbData) then
			for k, v in pairs(limbData) do
				self:HealDamage(player, k, amount);
			end;
		end;
	end;
	
	-- A function to heal a player's limb damage.
	function gc.limb:HealDamage(player, hitGroup, amount)
		local newAmount = math.ceil(amount);
		local limbData = player:GetCharacterData("LimbData");
		
		if (limbData and limbData[hitGroup]) then
			limbData[hitGroup] = math.max(limbData[hitGroup] - newAmount, 0);
			
			if (limbData[hitGroup] == 0) then
				limbData[hitGroup] = nil;
			end;
			
			gc.datastream:Start(player, "HealLimbDamage", {
				hitGroup = hitGroup, amount = newAmount
			});
			
			gc.plugin:Call("PlayerLimbDamageHealed", player, hitGroup, newAmount);
		end;
	end;
	
	-- A function to reset a player's limb damage.
	function gc.limb:ResetDamage(player)
		player:SetCharacterData("LimbData", {});
		gc.datastream:Start(player, "ResetLimbDamage", true);
		gc.plugin:Call("PlayerLimbDamageReset", player);
	end;
	
	-- A function to get whether any of a player's limbs are damaged.
	function gc.limb:IsAnyDamaged(player)
		local limbData = player:GetCharacterData("LimbData");
		
		if (limbData and table.Count(limbData) > 0) then
			return true;
		else
			return false;
		end;
	end
	
	-- A function to get a player's limb health.
	function gc.limb:GetHealth(player, hitGroup, asFraction)
		return 100 - self:GetDamage(player, hitGroup, asFraction);
	end;
	
	-- A function to get a player's limb damage.
	function gc.limb:GetDamage(player, hitGroup, asFraction)
		if (!gc.config:Get("limb_damage_system"):Get()) then
			return 0;
		end;
		
		local limbData = player:GetCharacterData("LimbData");
		
		if (type(limbData) == "table") then
			if (limbData and limbData[hitGroup]) then
				if (asFraction) then
					return limbData[hitGroup] / 100;
				else
					return limbData[hitGroup];
				end;
			end;
		end;
		
		return 0;
	end;
	
	-- Called when a player's character data should be restored.
	function gc.limb:PlayerRestoreCharacterData( player, data )
		if (!data["LimbData"]) then
			data["LimbData"] = {};
		end;
	end;
	
	-- Called when a player has spawned.
	function gc.limb:PlayerSpawn( player, bFirstSpawn, bInitialized )
		if ( bInitialized ) then
			self:ResetDamage(player);
		end;
	end;
	
	-- Called at an interval while a player is connected.
	function gc.limb:PlayerThink( player, curTime, infoTable )
		local leftLeg = self:GetDamage(player, HITGROUP_LEFTLEG, true);
		local rightLeg = self:GetDamage(player, HITGROUP_RIGHTLEG, true);
		local legDamage = math.Clamp(math.max(leftLeg, rightLeg) * 15, 0, 0.9);
		
		if (legDamage > 0) then
			infoTable.walkSpeed = infoTable.walkSpeed * (1 - legDamage);
			infoTable.runSpeed = infoTable.runSpeed * (1 - legDamage);
			infoTable.jumpPower = infoTable.jumpPower * (1 - legDamage);
		end;
	end;
else
	gc.limb.stored = {};
	gc.limb.names = {
		[HITGROUP_RIGHTARM] = "Правая рука",
		[HITGROUP_RIGHTLEG] = "Правая нога",
		[HITGROUP_LEFTARM] = "Левая рука",
		[HITGROUP_LEFTLEG] = "Левая нога",
		[HITGROUP_STOMACH] = "Желудок",
		[HITGROUP_CHEST] = "Грудь",
		[HITGROUP_HEAD] = "Голова"
	};
	
	-- A function to get a limb's name.
	function gc.limb:GetName(hitGroup)
		return self.names[hitGroup] or "Generic";
	end;
	
	-- A function to get a limb color.
	function gc.limb:GetColor(health)
		if (health > 75) then
			return Color(166, 243, 76, 255);
		elseif (health > 50) then
			return Color(233, 225, 94, 255);
		elseif (health > 25) then
			return Color(233, 173, 94, 255);
		else
			return Color(222, 57, 57, 255);
		end;
	end;
	
	-- A function to get the local player's limb health.
	function gc.limb:GetHealth(hitGroup, asFraction)
		return 100 - self:GetDamage(hitGroup, asFraction);
	end;
	
	-- A function to get the local player's limb damage.
	function gc.limb:GetDamage(hitGroup, asFraction)
		if (!gc.config:Get("limb_damage_system"):Get()) then
			return 0;
		end;
		
		if (type(self.stored) == "table") then
			if (self.stored[hitGroup]) then
				if (asFraction) then
					return self.stored[hitGroup] / 100;
				else
					return self.stored[hitGroup];
				end;
			end;
		end;
		
		return 0;
	end;
	
	-- A function to get whether any of the local player's limbs are damaged.
	function gc.limb:IsAnyDamaged()
		return table.Count(self.stored) > 0;
	end;
	
	gc.datastream:Hook("ReceiveLimbDamage", function(data)
		gc.limb.stored = data;
		gc.plugin:Call("PlayerLimbDamageReceived");
	end);

	gc.datastream:Hook("ResetLimbDamage", function(data)
		gc.limb.stored = {};
		gc.plugin:Call("PlayerLimbDamageReset");
	end);
	
	gc.datastream:Hook("TakeLimbDamage", function(data)
		local hitGroup = data.hitGroup;
		local damage = data.damage;
		
		gc.limb.stored[hitGroup] = math.min((gc.limb.stored[hitGroup] or 0) + damage, 100);
		gc.plugin:Call("PlayerLimbTakeDamage", hitGroup, damage);
	end);
	
	gc.datastream:Hook("HealLimbDamage", function(data)
		local hitGroup = data.hitGroup;
		local amount = data.amount;
		
		if (gc.limb.stored[hitGroup]) then
			gc.limb.stored[hitGroup] = math.max(gc.limb.stored[hitGroup] - amount, 0);
			
			if (gc.limb.stored[hitGroup] == 100) then
				gc.limb.stored[hitGroup] = nil;
			end;
			
			gc.plugin:Call("PlayerLimbDamageHealed", hitGroup, amount);
		end;
	end);
end;