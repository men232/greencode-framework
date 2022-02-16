--[[
	© 2013 GmodLive private project do not share
	without permission of its author (Andrew Mensky vk.com/men232).
--]]
local PLUGIN = PLUGIN or greenCode.plugin:Loader();

-- Called when a player's footstep sound should be played.
function PLUGIN:PlayerFootstep( player, position, foot, sound, volume, recipientFilter )		
	if (CLIENT) then return true; end;

	if ( player:IsRunning() or player:IsJogging() ) then
		local model = string.lower( player:GetModel() );

		if (string.find(model, "swat") or string.find(model, "metrocop") or string.find(model, "shockcp") or string.find(model, "ghostcp") or string.find(model, "police")) then
			if (foot == 0) then
				local randomSounds = {1, 3, 5};
				local randomNumber = math.random(1, 3);
				
				sound = "npc/metropolice/gear"..randomSounds[randomNumber]..".wav";
			else
				local randomSounds = {2, 4, 6};
				local randomNumber = math.random(1, 3);
				
				sound = "npc/metropolice/gear"..randomSounds[randomNumber]..".wav";
			end;
		elseif (string.find(model, "combine")) then
			if (foot == 0) then
				local randomSounds = {1, 3, 5};
				local randomNumber = math.random(1, 3);
				
				sound = "npc/combine_soldier/gear"..randomSounds[randomNumber]..".wav";
			else
				local randomSounds = {2, 4, 6};
				local randomNumber = math.random(1, 3);
				
				sound = "npc/combine_soldier/gear"..randomSounds[randomNumber]..".wav";
			end;
		end;
	end;

	player:EmitSound(sound);
	return true;
end;
