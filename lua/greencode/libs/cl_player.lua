--[[
	© 2013 GmodLive private project do not share
	without permission of its author (Andrew Mensky vk.com/men232).
--]]

local greenCode = greenCode;
local tostring = tostring;
local tonumber = tonumber;
local IsValid = IsValid;
local CurTime = CurTime;
local Vector = Vector;
local Angle = Angle;
local Color = Color;
local pairs = pairs;
local type = type;
local player = player;
local string = string;
local table = table;
local ents = ents;
local math = math;
local util = util;

greenCode.player = greenCode.kernel:NewLibrary("Player");

--[[ We need the datastream library to add the hooks! --]]
if (!greenCode.datastream) then include("sh_datastream.lua"); end;

local playerMeta = FindMetaTable("Player");

-- A function to get whether a player is noclipping.
function greenCode.player:IsNoClipping( player )
	return ( player:GetMoveType() == MOVETYPE_NOCLIP and !player:InVehicle() );
end;

-- A function to get whether the local player is drunk.
function greenCode.player:GetDrunk()
	local isDrunk = greenCode.Client:GetSharedVar("IsDrunk");
	
	if (isDrunk and isDrunk > 0) then
		return isDrunk;
	end;
end;

-- A function return gender of player
function greenCode.player:GetGender( entity )
	if ( entity ) then
		local model = entity:GetModel();
		return string.find( string.lower(model), "female" ) and "female" or "male";
	end;
end;

-- A function to get whether a player has initialized.
function playerMeta:HasInitialized() return IsValid( self ) and self:GetSharedVar("initialized"); end;

-- A function to get whether a player is noclipping.
function playerMeta:IsNoClipping() return gc.player:IsNoClipping(self); end;

-- A function to get a player's maximum armor.
function playerMeta:GetMaxArmor( armor )
	local maxArmor = self:GetSharedVar("MaxAP", 100);
	return maxArmor > 0 and maxArmor or 100;
end;

-- A function to get a player's maximum health.
function playerMeta:GetMaxHealth( health )
	local maxHealth = self:GetSharedVar("MaxHP", 100);
	return maxHealth > 0 and maxHealth or 100;
end;

function playerMeta:GetRpVar( key, default )
	local value = self:getDarkRPVar(key);

	if ( value != nil ) then
		return value;
	else
		return default;
	end;
end;

-- A function to get a player's forced animation.
function playerMeta:GetForcedAnimation()
	local forcedAnimation = self:GetSharedVar("ForceAnim");
	
	if (forcedAnimation != 0) then
		return {animation = forcedAnimation};
	end;
end;

-- A function to get whether a player is running.
function playerMeta:IsRunning()
	if (self:Alive() and !self:InVehicle() and !self:Crouching()
	and self:GetSharedVar("IsRunMode")) then
		if (self:GetVelocity():Length() >= self:GetWalkSpeed()
		or bNoWalkSpeed) then
			return true;
		end;
	end;
	
	return false;
end;

-- A function to get whether a player is jogging.
function playerMeta:IsJogging( bTestSpeed )
	if (!self:IsRunning() and (self:GetSharedVar("IsJogMode") or bTestSpeed)) then
		if (self:Alive() and !self:InVehicle() and !self:Crouching()) then
			if (self:GetVelocity():Length() > 0) then
				return true;
			end;
		end;
	end;
	
	return false;
end;

greenCode.datastream:Hook( "gcPlayURL", function( tSoundData )
	if (!gc.ClientSounds) then
		gc.ClientSounds = {};
	end;
	
	if ( !gc.ClientSoundsParent ) then
		gc.ClientSoundsParent = {};
	end;
	
	if ( gc.ClientSounds[ tSoundData.uid ] ) then
		gc.ClientSounds[ tSoundData.uid ]:Stop();
	end;
	
	if ( tSoundData.url == "" ) then
		return;
	end;
	
	if ( tSoundData.parent ) then
		tSoundData.pos = tSoundData.parent:GetPos();
	end;

	sound.PlayURL( tSoundData.url, tSoundData.mode or "3d mono", function( sound )
		if ( IsValid(sound) ) then
			gc.ClientSounds[ tSoundData.uid ] = sound;
			gc.ClientSoundsParent[ tSoundData.uid ] = tSoundData.parent;
			
			sound:SetPos( tSoundData.pos or gc.Client:GetShootPos() );
			sound:SetVolume( tSoundData.volume or 1 );
			sound:Play();
		else
			greenCode:Error("PlayURLSound", tSoundData.url);
		end;
	end);
end);

function greenCode.player:TickSecond()
	for k, v in pairs( gc.ClientSoundsParent or {} ) do
		if ( !v or !v:IsValid() ) then
			if ( gc.ClientSounds[ k ] ) then
				gc.ClientSounds[ k ]:Stop();
				gc.ClientSounds[ k ] = nil;
			end;
			gc.ClientSoundsParent[ k ] = nil;
			continue;
		end;
		
		local sound = gc.ClientSounds[ k ];
		
		if ( sound ) then
			sound:SetPos(v:GetPos());
		end;
	end;
end;

function greenCode.player:PlayerBindPress( player, bind, pressed )
	if ( bind == "+walk" ) then
		timer.Simple(0.00001, function()
			RunConsoleCommand("-walk");
		end);
	end;
end;

greenCode.datastream:Hook("StartSound", function(data)
	if (IsValid(gc.Client)) then
		local uid = data.uid;
		local sound = data.sound;
		local volume = data.volume;
		
		if (!gc.ClientSounds) then
			gc.ClientSounds = {};
		end;
		
		if (gc.ClientSounds[ uid ]) then
			gc.ClientSounds[ uid ]:Stop();
		end;
		
		gc.ClientSounds[ uid ] = CreateSound(gc.Client, sound);
		gc.ClientSounds[ uid ]:PlayEx(volume, 100);
	end;
end);

greenCode.datastream:Hook("SoundVolume", function(data)
	local uid = data.uid;
	local volume = data.volume;
	
	if (!gc.ClientSounds) then
		gc.ClientSounds = {};
	end;
	
	if (gc.ClientSounds[ uid ]) then
		gc.ClientSounds[ uid ]:PlayEx(volume, 100);
	end;
end);

greenCode.datastream:Hook("StopSound", function(data)
	local uid = data.uid;
	local fadeOut = data.fadeOut;
	
	if (!gc.ClientSounds) then
		gc.ClientSounds = {};
	end;
	
	if (gc.ClientSounds[ uid ]) then
		if (fadeOut != 0) then
			gc.ClientSounds[ uid ]:FadeOut(fadeOut);
		else
			gc.ClientSounds[ uid ]:Stop();
		end;
		
		gc.ClientSounds[ uid ] = nil;
	end;
end);

concommand.Add("cl_gc_sharedvars", function(ply, cmd, args)
	PrintTable( ply.gcSharedVars );
end);