--[[
	© 2013 GmodLive private project do not share
	without permission of its author (Andrew Mensky vk.com/men232).
--]]

local gc = gc;
local tostring = tostring;
local CurTime = CurTime;
local pairs = pairs;
local type = type;
local math = math;

gc.attributes = gc.attributes or gc.kernel:NewLibrary("Attributs");

if !gc.datastream then include( "sh_datastream.lua" ); end;

if (SERVER) then
	function gc.attributes:Progress(player, attribute, amount, gradual)
		local attributeTable = gc.attribute:FindByID(attribute);
		local attributes = player:GetAttributes();
		
		if (attributeTable) then
			attribute = attributeTable.uniqueID;
			
			if (gradual and attributes[attribute]) then
				if (amount > 0) then
					amount = math.max(amount - ((amount / attributeTable.maximum) * attributes[attribute].amount), amount / attributeTable.maximum);
				else
					amount = math.min((amount / attributeTable.maximum) * attributes[attribute].amount, amount / attributeTable.maximum);
				end;
			end;
			
			amount = amount * gc.config:Get("scale_attribute_progress"):Get();
			
			if (attributes[attribute]) then
				if (attributes[attribute].amount == attributeTable.maximum) then
					if (amount > 0) then
						return false, "Vous avez atteint le maximum de attribute!";
					end;
				end;
			else
				attributes[attribute] = {amount = attributeTable.default or 0, progress = 0};
			end;
			
			local progress = attributes[attribute].progress + amount;
			local remaining = math.max(progress - 100, 0);
			
			if (progress >= 100) then
				attributes[attribute].progress = 0;
				
				player:UpdateAttribute(attribute, 1);
				
				if (remaining > 0) then
					return player:ProgressAttribute(attribute, remaining);
				end;
			elseif (progress < 0) then
				attributes[attribute].progress = 100;
				
				player:UpdateAttribute(attribute, -1);
				
				if (progress < 0) then
					return player:ProgressAttribute(attribute, progress);
				end;
			else
				attributes[attribute].progress = progress;
			end;
			
			if (attributes[attribute].amount == 0 and attributes[attribute].progress == 0) then
				attributes[attribute] = nil;
			end;
			
			if (player:HasInitialized()) then
				if (!player.gcCachedAttrProgress) then
					player.gcCachedAttrProgress = {};
				end;

				if (attributes[attribute]) then
					player.gcAttrProgress[attribute] = math.floor(attributes[attribute].progress);
				else
					player.gcAttrProgress[attribute] = 0;
				end;

				local progressDifferent = math.abs((player.gcCachedAttrProgress[attribute] or 0) - player.gcAttrProgress[attribute]);

				if ( progressDifferent > 1 ) then
					player.gcAttrProgressTime = 0;
					player.gcCachedAttrProgress[attribute] =  player.gcAttrProgress[attribute];
				end;

				gc.plugin:Call("PlayerAttributeProgress", player, attributeTable, amount );
			end;
		else
			return false, "That is not a valid attribute!";
		end;
	end;
	
	-- A function to update a player's attribute.
	function gc.attributes:Update(player, attribute, amount)
		local attributeTable = gc.attribute:FindByID(attribute);
		local attributes = player:GetAttributes();
		
		if (attributeTable) then
			attribute = attributeTable.uniqueID;
			
			if (!attributes[attribute]) then
				attributes[attribute] = {amount = attributeTable.default or 0, progress = 0};
			elseif (attributes[attribute].amount == attributeTable.maximum) then
				if (amount and amount > 0) then
					return false, "Vous avez atteint le maximum de attribute!";
				end;
			end;
			
			attributes[attribute].amount = math.Clamp(attributes[attribute].amount + (amount or 0), 0, attributeTable.maximum);
			
			if (amount and amount > 0) then
				attributes[attribute].progress = 0;
				
				if (player:HasInitialized()) then
					player.gcAttrProgress[attribute] = 0;
					player.gcAttrProgressTime = 0;
				end;
			end;
			
			gc.datastream:Start(player, "AttrUpdate", {
				index = attributeTable.index, amount = attributes[attribute].amount, progress = attributes[attribute].progress
			});
			
			if (attributes[attribute].amount == 0
			and attributes[attribute].progress == 0) then
				attributes[attribute] = nil;
			end;
			
			gc.plugin:Call("PlayerAttributeUpdated", player, attributeTable, amount);
			
			return true;
		else
			return false, "Ce n'est pas un attribut valide!";
		end;
	end;
	
	-- A function to clear a player's attribute boosts.
	function gc.attributes:ClearBoosts(player)
		gc.datastream:Start(player, "AttrBoostClear", true);
		player.gcAttrBoosts = {};
	end;
	
	--- A function to get whether a boost is active for a player.
	function gc.attributes:IsBoostActive(player, identifier, attribute, amount, duration)
		if (player.gcAttrBoosts) then
			local attributeTable = gc.attribute:FindByID(attribute);
			
			if (attributeTable) then
				attribute = attributeTable.uniqueID;
				
				if (player.gcAttrBoosts[attribute]) then
					local attributeBoost = player.gcAttrBoosts[attribute][identifier];
					
					if (attributeBoost) then
						if (amount and duration) then
							return attributeBoost.amount == amount and attributeBoost.duration == duration;
						elseif (amount) then
							return attributeBoost.amount == amount;
						elseif (duration) then
							return attributeBoost.duration == duration;
						else
							return true;
						end;
					end;
				end;
			end;
		end;
	end;
	
	-- A function to boost a player's attribute.
	function gc.attributes:Boost(player, identifier, attribute, amount, duration)
		local attributeTable = gc.attribute:FindByID(attribute);
		
		if (attributeTable) then
			attribute = attributeTable.uniqueID;
			
			if (amount) then
				if (!identifier) then
					identifier = tostring({});
				end;
				
				if (!player.gcAttrBoosts[attribute]) then
					player.gcAttrBoosts[attribute] = {};
				end;
				
				if (duration) then
					player.gcAttrBoosts[attribute][identifier] = {
						duration = duration,
						endTime = CurTime() + duration,
						default = amount,
						amount = amount,
					};
				else
					player.gcAttrBoosts[attribute][identifier] = {
						amount = amount
					};
				end;
				
				local gcIndex = attributeTable.index;
				local gcAmount = player.gcAttrBoosts[attribute][identifier].amount;
				local gcDuration = player.gcAttrBoosts[attribute][identifier].duration;
				local gcEndTime = player.gcAttrBoosts[attribute][identifier].endTime;
				local gcIdentifier = identifier;
				
				gc.datastream:Start(player, "AttrBoost", {
					index = gcIndex, amount = gcAmount, duration = gcDuration, endTime = gcEndTime, identifier = gcIdentifier
				});
				
				return identifier;
			elseif (identifier) then
				if (self:IsBoostActive(player, identifier, attribute)) then
					if (player.gcAttrBoosts[attribute]) then
						player.gcAttrBoosts[attribute][identifier] = nil;
					end;
					
					gc.datastream:Start(player, "AttrBoostClear", {
						index = attributeTable.index, identifier = identifier
					});
				end;
				
				return true;
			elseif (player.gcAttrBoosts[attribute]) then
				gc.datastream:Start(player, "AttrBoostClear", {
					index = attributeTable.index
				});
				
				player.gcAttrBoosts[attribute] = {};
				
				return true;
			end;
		else
			self:ClearBoosts(player);
			
			return true;
		end;
	end;
	
	-- A function to get a player's attribute as a fraction.
	function gc.attributes:Fraction(player, attribute, fraction, negative)
		local attributeTable = gc.attribute:FindByID(attribute);
		
		if (attributeTable) then
			local maximum = attributeTable.maximum;
			local amount = self:Get(player, attribute, nil, negative) or 0;
			
			if (amount < 0 and type(negative) == "number") then
				fraction = negative;
			end;
			
			if (!attributeTable.cache[amount][fraction]) then
				attributeTable.cache[amount][fraction] = (fraction / maximum) * amount;
			end;
			
			return attributeTable.cache[amount][fraction];
		end;
	end;
	
	-- A function to get whether a player has an attribute.
	function gc.attributes:Get(player, attribute, boostless, negative)
		local attributeTable = gc.attribute:FindByID(attribute);
		
		if (attributeTable) then
			attribute = attributeTable.uniqueID;
			
			local maximum = attributeTable.maximum;
			local default = player:GetAttributes()[attribute];
			local boosts = player.gcAttrBoosts[attribute];

			if ( !default and attributeTable.default ) then
				default = { amount = attributeTable.default, progress = 0 };
			end;
			
			if (boostless) then
				if (default) then
					return default.amount, default.progress;
				end;
			else
				local progress = 0;
				local amount =  0;
				
				if (default) then
					amount = amount + default.amount;
					progress = progress + default.progress;
				end;
				
				if (boosts) then
					for k, v in pairs(boosts) do
						amount = amount + v.amount;
					end;
				end;
				
				if (negative) then
					amount = math.Clamp(amount, -maximum, maximum);
				else
					amount = math.Clamp(amount, 0, maximum);
				end;
				
				return math.ceil(amount), progress;
			end;
		end;
	end;

	function gc.attributes:PlayerSpawn( player, bFirstSpawn, bInitialized )
		player.gcAttrBoosts = {};
	end;
	
	function gc.attributes:PlayerDeath( player, inflictor, attacker, damageInfo )
		for k, v in pairs(gc.attribute:GetAll()) do
			player:ProgressAttribute( k, -15,  false );
		end;
	end;

	function gc.attributes:PlayerCharacterLoaded( player )
		player.gcAttrProgress = {};
		player.gcAttrProgressTime = 0;
		
		for k, v in pairs(gc.attribute:GetAll()) do
			player:UpdateAttribute(k);
		end;
		
		for k, v in pairs(player:GetAttributes()) do
			player.gcAttrProgress[k] = math.floor(v.progress);
		end;
	end;

	function gc.attributes:PlayerAttributeUpdated( player, attributeTable, amount )
		if ( attributeTable.isShared ) then
			local attribute = attributeTable.uniqueID;
			local attributes = player:GetAttributes()[attribute] or {};
			player:SetSharedVar{ ["atb_"..attribute] = attributes.amount or attributeTable.default or 0 };
		end;

		if ( player:HasInitialized() and amount and amount != 0 ) then
			player:SaveCharacter();
		end;
	end;

	-- Called at an interval while a player is connected.
	function gc.attributes:PlayerThink( player, curTime, infoTable, bAlive )
		if ( bAlive and player:WaterLevel() == 0 ) then
			if ( !player:InVehicle() and player:GetMoveType() == MOVETYPE_WALK ) then
				if ( player:IsInWorld() ) then
					if ( !player:IsOnGround() ) then
						player:ProgressAttribute(ATB_ACROBATICS, 0.25, true);
					elseif ( infoTable.isRunning ) then
						player:ProgressAttribute(ATB_AGILITY, 0.125, true);
					elseif ( infoTable.isJogging ) then
						player:ProgressAttribute(ATB_AGILITY, 0.0625, true);
					end;
				end;
			end;
		end;
		
		local acrobatics = gc.attributes:Fraction(player, ATB_ACROBATICS, 100, 50);
		local agility = gc.attributes:Fraction(player, ATB_AGILITY, 50, 25);
				
		infoTable.jumpPower = infoTable.jumpPower + acrobatics;
		infoTable.runSpeed = infoTable.runSpeed + agility;
	end;

	function greenCode.attributes:PlayerSetSharedVars( player, tSharedData, curTime )
		player:HandleAttributeProgress( curTime );
		player:HandleAttributeBoosts( curTime );
	end;
else
	gc.attributes.stored = gc.attributes.stored or {};
	gc.attributes.boosts = gc.attributes.boosts or {};

	-- A function to get the local player's attribute as a fraction.
	function gc.attributes:Fraction(attribute, fraction, negative)
		local attributeTable = gc.attribute:FindByID(attribute);
		
		if (attributeTable) then
			local maximum = attributeTable.maximum;
			local amount = self:Get(attribute, nil, negative) or 0;
			
			if (amount < 0 and type(negative) == "number") then
				fraction = negative;
			end;
			
			if (!attributeTable.cache[amount][fraction]) then
				attributeTable.cache[amount][fraction] = (fraction / maximum) * amount;
			end;
			
			return attributeTable.cache[amount][fraction];
		end;
	end;
	
	-- A function to get whether the local player has an attribute.
	function gc.attributes:Get(attribute, boostless, negative)
		local attributeTable = gc.attribute:FindByID(attribute);
		
		if (attributeTable) then
			attribute = attributeTable.uniqueID;
			
			local maximum = attributeTable.maximum;
			local default = self.stored[attribute];
			local boosts = self.boosts[attribute];

			if ( !default and attributeTable.default ) then
				default = { amount = attributeTable.default, progress = 0 };
			end;
			
			if (boostless) then
				if (default) then
					return default.amount, default.progress;
				end;
			else
				local progress = 0;
				local amount = 0;
				
				if (default) then
					amount = amount + default.amount;
					progress = progress + default.progress;
				end;
				
				if (boosts) then
					for k, v in pairs(boosts) do
						amount = amount + v.amount;
					end;
				end;
				
				if (negative) then
					amount = math.Clamp(amount, -maximum, maximum);
				else
					amount = math.Clamp(amount, 0, maximum);
				end;
				
				return math.ceil(amount), progress;
			end;
		end;
	end;
	
	gc.datastream:Hook("AttrBoostClear", function(data)
		local index = nil;
		local identifier = nil;
		
		if (type(data) == "table") then
			index = data.index;
			identifier = data.identifier;
		end;
		
		local attributeTable = gc.attribute:FindByID(index);
		
		if (attributeTable) then
			local attribute = attributeTable.uniqueID;
			
			if (identifier and identifier != "") then
				if (gc.attributes.boosts[attribute]) then
					gc.attributes.boosts[attribute][identifier] = nil;
				end;
			else
				gc.attributes.boosts[attribute] = nil;
			end;
		else
			gc.attributes.boosts = {};
		end;
	end);
	
	gc.datastream:Hook("AttrBoost", function(data)
		local index = data.index;
		local amount = data.amount;
		local duration = data.duration;
		local endTime = data.endTime;
		local identifier = data.identifier;
		local attributeTable = gc.attribute:FindByID(index);
		
		if (attributeTable) then
			local attribute = attributeTable.uniqueID;
			
			if (!gc.attributes.boosts[attribute]) then
				gc.attributes.boosts[attribute] = {};
			end;
			
			if (amount and amount == 0) then
				gc.attributes.boosts[attribute][identifier] = nil;
			elseif (duration and duration > 0 and endTime and endTime > 0) then
				gc.attributes.boosts[attribute][identifier] = {
					duration = duration,
					endTime = endTime,
					default = amount,
					amount = amount
				};
			else
				gc.attributes.boosts[attribute][identifier] = {
					default = amount,
					amount = amount
				};
			end;
		end;
	end);
	
	gc.datastream:Hook("AttributeProgress", function(data)
		local index = data.index;
		local amount = data.amount;
		local attributeTable = gc.attribute:FindByID(index);
		
		if (attributeTable) then
			local attribute = attributeTable.uniqueID;
			
			if (gc.attributes.stored[attribute]) then
				gc.attributes.stored[attribute].progress = amount;
			else
				gc.attributes.stored[attribute] = {amount = attributeTable.default or 0, progress = amount};
			end;
		end;
	end);
	
	gc.datastream:Hook("AttrUpdate", function(data)
		local index = data.index;
		local amount = data.amount;
		local progress = data.progress;
		local attributeTable = gc.attribute:FindByID(index);
		
		if (attributeTable) then
			local attribute = attributeTable.uniqueID;	
			gc.attributes.stored[attribute] = {amount = amount or attributeTable.default or 0, progress = progress or 0};
		end;
	end);
	
	gc.datastream:Hook("AttrClear", function(data)
		gc.attributes.stored = {};
		gc.attributes.boosts = {};
	end);
end;