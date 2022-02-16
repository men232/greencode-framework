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
local gc = greenCode;

greenCode.player = greenCode.kernel:NewLibrary("Player");

-- A function to play sound from url.
function greenCode.player:PlayURL( player, uid, url, mode, pos, volume )
	if (!player.gcSoundsPlaying) then
		player.gcSoundsPlaying = {};
	end;

	if (!player.gcSoundsPlaying[ uid ] or player.gcSoundsPlaying[ uid ] != url) then
		player.gcSoundsPlaying[ uid ] = url;

		greenCode.datastream:Start( player, "gcPlayURL", {
			uid = uid, url = url, mode = mode, pos = type(pos) == "vector" and pos, parent = type(pos) != "vector" and pos, volume = volume
		} );
	end;
end;

-- A function to start a sound for a player.
function greenCode.player:StartSound( player, uid, sound, fVolume )
	if (!player.gcSoundsPlaying) then
		player.gcSoundsPlaying = {};
	end;

	local sPlay = player.gcSoundsPlaying[ uid ];
	fVolume     = (fVolume or 0.75);
	
	if (!sPlay or sPlay.s != sound) then
		player.gcSoundsPlaying[ uid ] = { s = sound, v = fVolume };
		
		greenCode.datastream:Start(player, "StartSound", {
			uid = uid, sound = sound, volume = fVolume
		});
	elseif ( sPlay and sPlay.f != fVolume ) then
		greenCode.datastream:Start(player, "SoundVolume", {
			uid = uid, volume = (fVolume or 0.75)
		});
	end;
end;

-- A function to stop a sound for a player.
function greenCode.player:StopSound( player, uid, iFadeOut )
	if (!player.gcSoundsPlaying) then
		player.gcSoundsPlaying = {};
	end;
	
	if (player.gcSoundsPlaying[ uid ]) then
		player.gcSoundsPlaying[ uid ] = nil;
		
		greenCode.datastream:Start(player, "StopSound", {
			uid = uid, fadeOut = (iFadeOut or 0)
		});
	end;
end;

-- A function to set whether a player has intialized.
function greenCode.player:SetInitialized( player, initialized )
	player:SetSharedVar{ initialized = initialized };
end;

-- A function to get a player's character.
function greenCode.player:GetCharacter( player )
	player.gcCharacter = player.gcCharacter or {};
	return player.gcCharacter;
end;

-- A function to save a player's character.
function greenCode.player:SaveCharacter( player, character, Callback )	
	if ( character ) then
		character.lastPlayed = os.time();
		
		local tDataSave = {};
		local uniqueID = player:UniqueID();
		local playersTable = gc.config:Get("mysql_players_table"):Get("green_player");

		gc.plugin:Call("PlayerSaveCharacterData", player, character.data );

		for k, v in pairs( character ) do
			tDataSave[k] = ( type(v) == "table" ) and greenCode.kernel:Serialize( v ) or v;
		end;

		local tTempData = {
			name = player:Name(),
			ip = player:IPAddress(),
			sid = player:SteamID(),
		}

		local queryObj = greenCode.database:Select( playersTable );
			queryObj:AddWhere("_Uid = ?", uniqueID);
			queryObj:AddColumn("_Uid");
			queryObj:SetCallback(function(result)
				
				local queryObj;
				
				if (gc.database:IsResult(result)) then
					queryObj = gc.database:Update( playersTable );
					queryObj:AddWhere("_Uid = ?", uniqueID);
				else
					queryObj = gc.database:Insert( playersTable );
					queryObj:SetValue("_Uid", uniqueID);
				end;

				queryObj:SetValue("_LastPlayed", os.time());
				queryObj:SetValue("_SteamName", tTempData.name);
				queryObj:SetValue("_IPAddress", tTempData.ip);
				queryObj:SetValue("_SteamID", tTempData.sid);
				queryObj:SetValue("_Attributes", greenCode.kernel:Serialize(character.attributes or {}));
				queryObj:SetValue("_Data", greenCode.kernel:Serialize(character.data or {}));
				queryObj:Push();

				if ( Callback ) then
					Callback();
				end;

				gc:Success("Character", "save: " .. tTempData.name .. "!");
			end)
		queryObj:Pull();
	end;
end;

function greenCode.player:PlayerSaveCharacterData( player, data )
	data["HP"] = player:Health();
	data["MP"] = player:Armor();
end;

function greenCode.player:PlayerRestoreCharacterData( player, data )
	if ( data["HP"] and data["HP"] > 1 ) then
		player:SetHealth( math.Clamp( data["HP"], 1, player:GetMaxHealth() ) );
	end;

	if ( data["HP"] and data["MP"] > 1 ) then
		player:SetArmor( math.Clamp( data["MP"], 0, player:GetMaxArmor() ) );
	end;
end;

-- A function to load a player's character.
function greenCode.player:LoadCharacter( player, tMergeCreate, Callback )
	local character = {};
	local unixTime = os.time();
	local uniqueID = player:UniqueID();
	
	character = {};
	character.data = {};
	character.attributes = {};
	character.steamID = player:SteamID();
	character.lastPlayed = unixTime;

	local playersTable = gc.config:Get("mysql_players_table"):Get("green_player");

	if ( tMergeCreate ) then
		table.Merge( character, tMergeCreate );
	end;

	local queryObj = greenCode.database:Select( playersTable );
		queryObj:AddWhere("_Uid = ?", uniqueID);
		queryObj:SetCallback(function(result)

			if ( gc.database:IsResult(result) ) then
				for k, v in pairs( result[1] ) do
					if k == "_Data" then
						character.data = greenCode.kernel:Deserialize( v );
					elseif k == "_Attributes" then
						character.attributes = greenCode.kernel:Deserialize( v );
					end;
				end;

				player.gcCharacter = character;

				if (Callback) then
					Callback();
				end;

				gc.plugin:Call( "PlayerCharacterLoaded", player );

			else
				self:SaveCharacter( player, character, function()
					player.gcCharacter = character;

					if (Callback) then
						Callback();
					end;

					gc.plugin:Call( "PlayerCharacterLoaded", player );
				end);
			end;

		end)
	queryObj:Pull();
end;

--[[ TOODO: Replace this to plugin. ]]--
function greenCode.player:PlayerShouldSmoothSprint()
	return true;
end;

function greenCode.player:PlayerThink( player, curTime, infoTable, bAlive )
	if ( !player.gcNextSaveCharacter ) then
		player.gcNextSaveCharacter = curTime + gc.config:Get("character_save_interval"):Get(5)*60;
	end;

	if ( player.gcNextSaveCharacter <= curTime ) then
		player:SaveCharacter();
		player.gcNextSaveCharacter = nil;
	end;
	
	if ( player:KeyDown(IN_BACK) ) then
		infoTable.runSpeed = infoTable.runSpeed * 0.5;
	end;
	
	if (infoTable.isJogging) then
		infoTable.walkSpeed = infoTable.walkSpeed * 1.75;
	end;
	
	if (infoTable.runSpeed < infoTable.walkSpeed) then
		infoTable.runSpeed = infoTable.walkSpeed;
	end;

	if (gc.plugin:Call("PlayerShouldSmoothSprint", player, infoTable)) then
		if (!player.gcLastRunSpeed) then
			player.gcLastRunSpeed = infoTable.walkSpeed;
		end;
		
		if ( player:IsRunning(true) ) then
			player.gcLastRunSpeed = math.Approach(
				player.gcLastRunSpeed, infoTable.runSpeed, player.gcLastRunSpeed * 0.3
			);
		else
			player.gcLastRunSpeed = math.Approach(
				player.gcLastRunSpeed, infoTable.walkSpeed, player.gcLastRunSpeed * 0.3
			);
		end;
		
		infoTable.runSpeed = player.gcLastRunSpeed;
	end;
end;

-- Called when a player's character has loaded.
function greenCode.player:PlayerCharacterLoaded( player )
	player.crouchedSpeed = gc.config:Get("crouched_speed"):Get();
	player.jumpPower = gc.config:Get("jump_power"):Get();
	player.walkSpeed = gc.config:Get("walk_speed"):Get();
	player.runSpeed = gc.config:Get("run_speed"):Get();

	hook.Call("PlayerRestoreCharacterData", gc, player, player:QueryCharacter("Data"));

	timer.Simple( 5, function()
		if not IsValid( player ) then return end;
		
		gc.plugin:Call( "PlayerCharacterInitialized", player );
		gc.player:SetInitialized( player, true );

		gc:Success( "Character", "initialized: " .. player:Name() .. "!" );
		player:ShowHint( "Character initialized!", 5 );
	end );
end;

-- Called when the Lua system is about to shut down (when the map changes, server shuts down or the client disconnects). 
function greenCode.player:ShutDown()
	for k, v in pairs( _player:GetAll() ) do
		v:SaveCharacter();
	end;
end;

function greenCode.player:PlayerDisconnected( player )
	player:SaveCharacter();
end;

-- A function to get whether a player is noclipping.
function greenCode.player:IsNoClipping( player )
	return ( player:GetMoveType() == MOVETYPE_NOCLIP and !player:InVehicle() );
end;

-- A function to get whether a player can see a player.
function greenCode.player:CanSeePlayer(player, target, iAllowance, tIgnoreEnts)
	if (!player:GetEyeTraceNoCursor().Entity == target
	and !target:GetEyeTraceNoCursor().Entity == player) then
		local trace = {};
		
		trace.mask = CONTENTS_SOLID + CONTENTS_MOVEABLE + CONTENTS_OPAQUE + CONTENTS_DEBRIS + CONTENTS_HITBOX + CONTENTS_MONSTER;
		trace.start = player:GetShootPos();
		trace.endpos = target:GetShootPos();
		trace.filter = {player, target};
		
		if (tIgnoreEnts) then
			if (type(tIgnoreEnts) == "table") then
				table.Add(trace.filter, tIgnoreEnts);
			else
				table.Add(trace.filter, ents.GetAll());
			end;
		end;
		
		trace = util.TraceLine(trace);
		
		if (trace.Fraction >= (iAllowance or 0.75)) then
			return true;
		end;
	else
		return true;
	end;
end;

-- A function to get whether a player can see an entity.
function greenCode.player:CanSeeEntity(player, target, iAllowance, tIgnoreEnts)
	if (!player:GetEyeTraceNoCursor().Entity == target) then
		local trace = {};
		
		trace.mask = CONTENTS_SOLID + CONTENTS_MOVEABLE + CONTENTS_OPAQUE + CONTENTS_DEBRIS + CONTENTS_HITBOX + CONTENTS_MONSTER;
		trace.start = player:GetShootPos();
		trace.endpos = target:LocalToWorld(target:OBBCenter());
		trace.filter = {player, target};
		
		if (tIgnoreEnts) then
			if (type(tIgnoreEnts) == "table") then
				table.Add(trace.filter, tIgnoreEnts);
			else
				table.Add(trace.filter, ents.GetAll());
			end;
		end;
		
		trace = util.TraceLine(trace);
		
		if (trace.Fraction >= (iAllowance or 0.75)) then
			return true;
		end;
	else
		return true;
	end;
end;

-- A function to get whether a player can see a position.
function greenCode.player:CanSeePosition(player, position, iAllowance, tIgnoreEnts)
	local trace = {};
	
	trace.mask = CONTENTS_SOLID + CONTENTS_MOVEABLE + CONTENTS_OPAQUE + CONTENTS_DEBRIS + CONTENTS_HITBOX + CONTENTS_MONSTER;
	trace.start = player:GetShootPos();
	trace.endpos = position;
	trace.filter = {player};
	
	if (tIgnoreEnts) then
		if (type(tIgnoreEnts) == "table") then
			table.Add(trace.filter, tIgnoreEnts);
		else
			table.Add(trace.filter, ents.GetAll());
		end;
	end;
	
	trace = util.TraceLine(trace);
	
	if (trace.Fraction >= (iAllowance or 0.75)) then
		return true;
	end;
end;

-- A function to set a player to a safe position.
function greenCode.player:SetSafePosition(player, position, filter)
	position = self:GetSafePosition(player, position, filter);
	
	if (position) then
		player:SetMoveType(MOVETYPE_NOCLIP);
		player:SetPos(position);
		
		if (player:IsInWorld()) then
			player:SetMoveType(MOVETYPE_WALK);
		else
			player:Spawn();
		end;
	end;
end;

-- A function to get the safest position near a position.
function greenCode.player:GetSafePosition(player, position, filter)
	local closestPosition = nil;
	local distanceAmount = 8;
	local directions = {};
	local yawForward = player:EyeAngles().yaw;
	local angles = {
		math.NormalizeAngle(yawForward - 180),
		math.NormalizeAngle(yawForward - 135),
		math.NormalizeAngle(yawForward + 135),
		math.NormalizeAngle(yawForward + 45),
		math.NormalizeAngle(yawForward + 90),
		math.NormalizeAngle(yawForward - 45),
		math.NormalizeAngle(yawForward - 90),
		math.NormalizeAngle(yawForward)
	};
	
	position = position + Vector(0, 0, 32);
	
	if (!filter) then
		filter = {player};
	elseif (type(filter) != "table") then
		filter = {filter};
	end;
	
	if (!table.HasValue(filter, player)) then
		filter[#filter + 1] = player;
	end;
	
	for i = 1, 8 do
		for k, v in pairs(angles) do
			directions[#directions + 1] = {v, distanceAmount};
		end;
		
		distanceAmount = distanceAmount * 2;
	end;
	
	-- A function to get a lower position.
	local function GetLowerPosition(testPosition, ignoreHeight)
		local trace = {
			filter = filter,
			endpos = testPosition - Vector(0, 0, 256),
			start = testPosition
		};
		
		return util.TraceLine(trace).HitPos + Vector(0, 0, 32);
	end;
	
	local trace = {
		filter = filter,
		endpos = position + Vector(0, 0, 256),
		start = position
	};
	
	local safePosition = GetLowerPosition(util.TraceLine(trace).HitPos);
	
	if (safePosition) then
		position = safePosition;
	end;
	
    for k, v in pairs(directions) do
		local angleVector = Angle(0, v[1], 0):Forward();
		local testPosition = position + (angleVector * v[2]);
		
		local trace = {
			filter = filter,
			endpos = testPosition,
			start = position
		};
		
		local traceLine = util.TraceEntity(trace, player);
		
		if (traceLine.Hit) then
			trace = {
				filter = filter,
				endpos = traceLine.HitPos - (angleVector * v[2]),
				start = traceLine.HitPos
			};
			
			traceLine = util.TraceEntity(trace, player);
			
			if (!traceLine.Hit) then
				position = traceLine.HitPos;
			end;
		end;
		
		if (!traceLine.Hit) then
			break;
		end;
    end;
	
    for k, v in pairs(directions) do
		local angleVector = Angle(0, v[1], 0):Forward();
		local testPosition = position + (angleVector * v[2]);
		
		local trace = {
			filter = filter,
			endpos = testPosition,
			start = position
		};
		
		local traceLine = util.TraceEntity(trace, player);
		
		if (!traceLine.Hit) then
			return traceLine.HitPos;
		end;
    end;
	
	return position;
end;

-- A function to get the class of a player's active weapon.
function greenCode.player:GetWeaponClass(player, safe)
	if (IsValid(player:GetActiveWeapon())) then
		return player:GetActiveWeapon():GetClass();
	else
		return safe;
	end;
end;

-- A function return gender of player
function greenCode.player:GetGender( entity )
	if ( entity ) then
		local model = entity:GetModel();
		return string.find( string.lower(model), "female" ) and "female" or "male";
	end;
end;

-- A function to get a player's weapons list as a table.
function greenCode.player:GetWeapons( player, keep )
	local weapons = {};
	
	for k, v in pairs( player:GetWeapons() ) do
		local class = v:GetClass();
		local uniqueID = v:GetNetworkedString("uniqueID");
		
		weapons[#weapons + 1] = {class = class, uniqueID = uniqueID};
		
		if (!keep) then
			player:StripWeapon(class);
		end;
	end;
	
	return weapons;
end;

-- A function to set a player's weapons list from a table.
function greenCode.player:SetWeapons( player, weapons, forceReturn )
	for k, v in pairs(weapons) do
		if ( !player:HasWeapon( v["class"] ) ) then
			player:Give(v["class"]);
		end;
	end;
end;

-- A function to query a player's character.
function greenCode.player:Query(player, key, default)
	local character = player:GetCharacter();
	
	if (character) then
		key = gc.kernel:SetCamelCase(key, true);
		
		if (character[key] != nil) then
			return character[key];
		end;
	end;
	
	return default;
end;

-- A function to check super admin right.
function greenCode.player:HasAdminRight( player, nAdminLevel )
	if ( nAdminLevel ) then
		return player:EntIndex() == 0 or player:IsSuperAdmin();
	else
		return player:EntIndex() == 0 or player:IsAdmin();
	end;
end;

-----------------
-- META PREFIX --
-----------------

local entityMeta = FindMetaTable("Entity");
local playerMeta = FindMetaTable("Player");

-- A function to emit a hit sound for an entity.
function entityMeta:EmitHitSound(sound)
	self:EmitSound("weapons/crossbow/hitbod2.wav",
		math.random(100, 150), math.random(150, 170)
	);
	
	timer.Simple(FrameTime() * 8, function()
		if (IsValid(self)) then
			self:EmitSound(sound);
		end;
	end);
end;

function playerMeta:HasAdminRight( nAdminLevel )
	return greenCode.player:HasAdminRight( self, nAdminLevel )
end;

-- A function to get whether a player is running.
function playerMeta:IsRunning()
	if (self:Alive() and !self:InVehicle()
	and !self:Crouching() and self:KeyDown(IN_SPEED)) then
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

-- A function to get whether a player has initialized.
function playerMeta:HasInitialized() return IsValid( self ) and self:GetSharedVar("initialized"); end;

-- A function to get a player's last hit group.
gc:ReserveFunc( playerMeta, "LastHitGroup" );

function playerMeta:LastHitGroup()
	return self.gcLastHitGroup or self:_LastHitGroup();
end;

-- A function to get whether a player is alive.
gc:ReserveFunc( playerMeta, "Alive" );

function playerMeta:Alive() return ( !self.fakingDeath and self:_Alive() ); end;

-- A function to set whether a player is faking death.
function playerMeta:SetFakingDeath( fakingDeath, killSilent )
	self.fakingDeath = fakingDeath;
	
	if (!fakingDeath and killSilent) then
		self:KillSilent();
	end;
end;

-- A function to set a player's dsp effect.
gc:ReserveFunc( playerMeta, "SetDSP" );

function playerMeta:SetDSP( dspID, quickreset, bGreenCode )
	if ( !bGreenCode ) then self.gcDSP = dspID; end;
	self:_SetDSP( dspID, quickreset );
end;

-- A function to set a player's run speed.
gc:ReserveFunc( playerMeta, "SetRunSpeed" );

function playerMeta:SetRunSpeed( speed, bGreenCode )
	if ( !bGreenCode ) then self.gcRunSpeed = speed; end;
	self:_SetRunSpeed( speed );
end;

-- A function to set a player's walk speed.
gc:ReserveFunc( playerMeta, "SetWalkSpeed" );

function playerMeta:SetWalkSpeed( speed, bGreenCode )
	if ( !bGreenCode ) then self.gcWalkSpeed = speed; end;
	self:_SetWalkSpeed( speed );
end;

-- A function to set a player's jump power.
gc:ReserveFunc( playerMeta, "SetJumpPower" );

function playerMeta:SetJumpPower( power, bGreenCode )
	if ( !bGreenCode ) then self.gcJumpPower = power; end;
	self:_SetJumpPower( power );
end;

-- A function to set a player's crouched walk speed.
gc:ReserveFunc( playerMeta, "SetCrouchedWalkSpeed" );

function playerMeta:SetCrouchedWalkSpeed( speed, bGreenCode )
	if ( !bGreenCode ) then self.gcCrouchedSpeed = speed; end;
	self:_SetCrouchedWalkSpeed( speed );
end;

-- A function to set a shared variable for a player or entity.
function playerMeta:SetSharedVar( tData, private ) return gc.entity:SetSharedVar( self, tData, nil, private ); end;

-- A function to set a shared variable for a player or entity.
function playerMeta:SetPrivateVar( tData ) return self:SetSharedVar( tData, true ); end;

-- A function to set an entity's skin.
gc:ReserveFunc( entityMeta, "SetSkin" );

function entityMeta:SetSkin( skin )
	self:_SetSkin( skin );
	
	if ( self:IsPlayer() ) then
		gc.plugin:Call( "PlayerSkinChanged", self, skin );
	end;
end;

-- A function to set an entity's model.
gc:ReserveFunc( entityMeta, "SetModel" );

function entityMeta:SetModel( sModel )
	self:_SetModel( sModel );
	
	if ( self:IsPlayer() ) then
		gc.plugin:Call( "PlayerModelChanged", self, sModel );
	end;
end;

-- A function to set a player's health.
gc:ReserveFunc( entityMeta, "SetHealth" );

function playerMeta:SetHealth( health )
	local oldHealth = self:Health();
		self:_SetHealth( health );
	gc.plugin:Call( "PlayerHealthSet", self, health, oldHealth );
end;

-- A function to set a player's armor.
gCode:ReserveFunc( playerMeta, "SetArmor" );

function playerMeta:SetArmor( armor )
	local oldArmor = self:Armor();
		self:_SetArmor( armor );
	gc.plugin:Call("PlayerArmorSet", self, armor, oldArmor);
end;

-- A function to set a player's character data.
function playerMeta:SetCharacterData( key, value, bFromBase )
	local character = self:GetCharacter();
	
	if (!character) then
		return;
	end;
	
	if (bFromBase) then
		key = gc.kernel:SetCamelCase(key, true);
		
		if (character[key] != nil) then
			character[key] = value;
		end;
	else
		character.data[key] = value;
	end;
end;

-- A function to get a player's character data.
function playerMeta:GetCharacterData(key, default)
	if (self:GetCharacter()) then
		local data = self:QueryCharacter("Data");
		
		if (data[key] != nil) then
			return data[key];
		end;
	end;
	
	return default;
end;

function playerMeta:GetRpVar( key, default )
	local value = self:getDarkRPVar(key);

	if ( value != nil ) then
		return value;
	else
		return default;
	end;
end;

-- A function to get a player's data.
function playerMeta:GetData( key, default )
	if (self.gcData and self.gcData[key] != nil) then
		return self.gcData[key];
	else
		return default;
	end;
end;

-- A function to set a player's data.
function playerMeta:SetData( key, value )
	if (self.gcData) then
		self.gcData[key] = value;
	end;
end;

-- A function to query a player's character table.
function playerMeta:QueryCharacter(key, default)
	if (self:GetCharacter()) then
		return gc.player:Query(self, key, default);
	else
		return default;
	end;
end;

-- A function to get a player's attribute boosts.
function playerMeta:GetAttributeBoosts()
	return self.gcAttrBoosts;
end;

-- A function to update a player's attribute.
function playerMeta:UpdateAttribute(attribute, amount)
	return gc.attributes:Update(self, attribute, amount);
end;

-- A function to progress a player's attribute.
function playerMeta:ProgressAttribute(attribute, amount, gradual)
	return gc.attributes:Progress(self, attribute, amount, gradual);
end;

-- A function to boost a player's attribute.
function playerMeta:BoostAttribute(identifier, attribute, amount, duration)
	return gc.attributes:Boost(self, identifier, attribute, amount, duration);
end;

-- A function to get whether a boost is active for a player.
function playerMeta:IsBoostActive(identifier, attribute, amount, duration)
	return gc.attributes:IsBoostActive(self, identifier, attribute, amount, duration);
end;

-- A function to get a player's character table.
function playerMeta:GetCharacter() return gc.player:GetCharacter(self); end;

-- A function to get a player's character table.
function playerMeta:LoadCharacter( tMerge, callback ) gc.player:LoadCharacter( self, tMerge, callback ); end;

-- A function to save a player's character.
function playerMeta:SaveCharacter() gc.player:SaveCharacter(self, self:GetCharacter()); end;

-- A function to set a player's maximum armor.
function playerMeta:SetMaxArmor( armor ) self:SetSharedVar{ MaxAP = armor }; end;

-- A function to set a player's maximum health.
function playerMeta:SetMaxHealth( health ) self:SetSharedVar{ MaxHP = health }; end;

-- A function to send player hint.
function playerMeta:ShowHint( text, delay, color, bNoSound, bShowDuplicates )
	gc.hint:Send( self, text, delay, color, bNoSound, bShowDuplicates );
end;

-- A function to send player alert.
function playerMeta:ShowAlert( text, color )
	gc.alert:Send( self, text, color );
end;

-- A function to get a player's attributes.
function playerMeta:GetAttributes() return self:QueryCharacter("Attributes"); end;

-- A function return gender of player
function playerMeta:GetGender() return gc.player:GetGender( self ); end;

-- A function to get whether a player is noclipping.
function playerMeta:IsNoClipping() return gc.player:IsNoClipping( self ); end;

-- A function to handle a player's attribute progress.
function playerMeta:HandleAttributeProgress(curTime)
	if (self.gcAttrProgressTime and curTime >= self.gcAttrProgressTime) then
		self.gcAttrProgressTime = curTime + 30;

		//for k, v in pairs(gc.attribute:GetAll()) do
		//	self:UpdateAttribute(k);
		//end;
		for k, v in pairs(self.gcAttrProgress) do
			local attributeTable = gc.attribute:FindByID(k);
			
			if (attributeTable) then
				gc.datastream:Start(self, "AttributeProgress", {
					index = attributeTable.index, amount = v
				});
			end;
		end;
		
		if (self.gcAttrProgress) then
			self.gcAttrProgress = {};
		end;
	end;
end;

-- A function to handle a player's attribute boosts.
function playerMeta:HandleAttributeBoosts(curTime)
	for k, v in pairs(self.gcAttrBoosts) do
		for k2, v2 in pairs(v) do
			if (v2.duration and v2.endTime) then
				if (curTime > v2.endTime) then
					self:BoostAttribute(k2, k, false);
				else
					local timeLeft = v2.endTime - curTime;
					
					if (timeLeft >= 0) then
						if (v2.default < 0) then
							v2.amount = math.min((v2.default / v2.duration) * timeLeft, 0);
						else
							v2.amount = math.max((v2.default / v2.duration) * timeLeft, 0);
						end;
					end;
				end;
			end;
		end;
	end;
end;

-- A function to get a player's maximum armor.
function playerMeta:GetMaxArmor( armor )
	local maxArmor = self:GetSharedVar( "MaxAP" );
	return maxArmor > 0 and maxArmor or 100;
end;

-- A function to get a player's maximum health.
function playerMeta:GetMaxHealth( health )
	local maxHealth = self:GetSharedVar("MaxHP");
	return maxHealth > 0 and maxHealth or 100;
end;

function playerMeta:CanSee( ent )
	local trace = { };
	trace.start = self:EyePos();
	trace.endpos = ent:EyePos();
	trace.filter = { self, ent };
	trace.mask = MASK_VISIBLE;
	local tr = util.TraceLine( trace );
	
	if( tr.Fraction == 1.0 ) then
		return true;
	end
	
	return false;
end

function playerMeta:CanHear( ent )
	local trace = { };
	trace.start = self:EyePos();
	trace.endpos = ent:EyePos();
	trace.filter = self;
	trace.mask = MASK_SOLID;
	local tr = util.TraceLine( trace );
	
	if( IsValid( tr.Entity ) and tr.Entity:EntIndex() == ent:EntIndex() ) then
		return true;
	end
	
	return false;
end

function playerMeta:CanSeePos( pos )
	local trace = { };
	trace.start = self:EyePos();
	trace.endpos = pos;
	trace.filter = self;
	local tr = util.TraceLine( trace );
	
	if( tr.Fraction == 1.0 ) then
		return true;
	end
	
	return false;
end

-- A function to set a player's forced animation.
function playerMeta:SetForcedAnimation(animation, delay, OnAnimate, OnFinish)
	local forcedAnimation = self:GetForcedAnimation();
	
	if (!animation) then
		self:SetSharedVar{ ForceAnim = 0 };
		self.gcForcedAnimation = nil;
		
		if (forcedAnimation and forcedAnimation.OnFinish) then
			forcedAnimation.OnFinish(self);
		end;
		
		return false;
	end;
	
	local bIsPermanent = (!delay or delay == 0);
	local bShouldPlay = (!forcedAnimation or forcedAnimation.delay != 0);
	
	if (bShouldPlay) then		
		self.gcForcedAnimation = {
			animation = animation,
			OnAnimate = OnAnimate,
			OnFinish = OnFinish,
			delay = delay
		};
		
		if (bIsPermanent) then
			timer.Destroy("ForcedAnim"..self:UniqueID());
		else
			self:CreateAnimationStopDelay(delay);
		end;
		
		self:SetSharedVar{ ForceAnim = animation };
		
		if (forcedAnimation and forcedAnimation.OnFinish) then
			forcedAnimation.OnFinish(self);
		end;
		
		return true;
	end;
end;

-- A function to get a player's forced animation.
function playerMeta:GetForcedAnimation() return self.gcForcedAnimation; end;

-- A function to create a player'a animation stop delay.
function playerMeta:CreateAnimationStopDelay(delay)
	timer.Create("ForcedAnim"..self:UniqueID(), delay, 1, function()
		if (IsValid(self)) then
			local forcedAnimation = self:GetForcedAnimation();
			
			if (forcedAnimation) then
				self:SetForcedAnimation(false);
			end;
		end;
	end);
end;

function playerMeta:Stuck()
	local curTime = CurTime();

	if ( !self.lastUseStuck ) then
		self.lastUseStuck = 0;
	end;

	if ( self:Alive() and curTime > self.lastUseStuck ) then
		local position = greenCode.player:GetSafePosition( self, self:GetPos() );
		if ( position ) then
			self:SetMoveType(MOVETYPE_NOCLIP);
			self:SetPos(position);					
			self:SetMoveType(MOVETYPE_WALK);
			self.lastUseStuck = curTime + 3;
			return true;
		end;
	else
		self:Message( "Использование этой команды, сейчас недоступно." );
		return false;
	end;
end;

gCode.chat:AddCommand( "застрял", function( player, sMessage ) player:Stuck(); end);
gCode.chat:AddCommand( "stuck", function( player, sMessage ) player:Stuck(); end);

greenCode.command:Add( "loadcharacter", 0, function( player, command, args )
	greenCode.player:SetInitialized( player, false );
	player:LoadCharacter( nil, function()
		PrintTable(player:GetCharacter());
	end);
end);

greenCode.command:Add( "savecharacter", 0, function( player, command, args )
	player:SaveCharacter();
	PrintTable(player:GetCharacter());
end);

greenCode.command:Add( "chardata", 2, function( player, command, args )
	PrintTable(player:GetCharacter());
	print("=====================")
	PrintTable(player.gcAttrBoosts);
end);

greenCode.command:Add( "playurl", 2, function( player, command, args )	
	if ( args[2] ) then
		player = greenCode.kernel:FindPlayer(args[2]);
	end;
	
	for k, v in pairs( _player.GetAll() ) do
		greenCode.player:StopSound( v, "VkMusic" );
		greenCode.player:PlayURL( v, "VkMusic", args[1], nil, player, nil );
	end;
end);

greenCode.command:Add( "progressaattr", 0, function( player, command, args )
	gc.limb:ResetDamage(player);
	player:BoostAttribute("Runner", ATB_AGILITY, 10000, 600);
	player:BoostAttribute("Runner", ATB_ACROBATICS, 10000, 600);
	player:BoostAttribute("Runner", ATB_STRENGTH, 10000, 600);
	player:BoostAttribute("Runner", ATB_STAMINA, 10000, 600);
	player:BoostAttribute("Runner", ATB_BREAK, 10000, 600);
	player:SetCharacterData("Stamina", 100);
end);

greenCode.command:Add( "testanim", 1, function( player, command, args )
	player:SetForcedAnimation(11, 10);
end);

function setUpGroupDoors()
	local map = MySQLite.SQLStr(string.lower(game.GetMap()))
	MySQLite.query("SELECT idx, doorgroup FROM darkrp_doorgroups WHERE map = " .. map, function(data)
		if not data then return end

		for _, row in pairs(data) do
			local ent = ents.GetByIndex(GAMEMODE:DoorToEntIndex(tonumber(row.idx)))

			if not IsValid(ent) then
				continue
			end

			ent.DoorData = ent.DoorData or {}
			ent.DoorData.GroupOwn = row.doorgroup
		end
	end)
end