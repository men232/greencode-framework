--[[
	© 2013 GmodLive private project do not share
	without permission of its author (Andrew Mensky vk.com/men232).
--]]

local greenCode = greenCode;
local CurTime = CurTime;
local SysTime = SysTime;
local table = table;
local gc = greenCode;

greenCode.hooks        = greenCode.hooks or greenCode.kernel:NewLibrary("Hooks");
greenCode.hooks.stored = greenCode.hooks.stored or {};

function greenCode.hooks:Register( sName )
	if ( !self.stored[ sName ] ) then
		self.stored[ sName ] = greenCode[ sName ] or function() end;
	end;
end;

function greenCode.hooks:Call( sName, ... )
	if ( self.stored[ sName ] ) then
		return self.stored[ sName ]( greenCode, ... );
	end;
end;

-- Called when some get fall damage.
gc.hooks:Register("GetFallDamage");

function greenCode:GetFallDamage( player, velocity )
	local pluginFallDamage = self.plugin:RunHooks( "GetFallDamage", false, player, velocity );
	local baseFallDamage;

	if ( pluginFallDamage == nil ) then
		baseFallDamage = self.hooks:Call( "GetFallDamage", player, velocity );
	end;

	return pluginFallDamage or baseFallDamage;
end;

-- Called when entity take damage.
gc.hooks:Register("EntityTakeDamage");

greenCode.HitGroupBonesCache = {
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
};

-- A function to get a ragdoll's hit bone.
function greenCode:GetRagdollHitBone(entity, position, failSafe, minimum)
	local closest = {};
	
	for k, v in pairs(self.HitGroupBonesCache) do
		local bone = entity:LookupBone(v[1]);
		
		if (bone) then
			local bonePosition = entity:GetBonePosition(bone);
			
			if (bonePosition) then
				local distance = bonePosition:Distance(position);
				
				if (!closest[1] or distance < closest[1]) then
					if (!minimum or distance <= minimum) then
						closest[1] = distance;
						closest[2] = bone;
					end;
				end;
			end;
		end;
	end;
	
	if (closest[2]) then
		return closest[2];
	else
		return failSafe;
	end;
end;

if SERVER then
	function greenCode:EntityTakeDamage( entity, damageInfo )
		if (entity:IsPlayer() and entity:InVehicle() and !IsValid(entity:GetVehicle():GetParent())) then
			entity.gcLastHitGroup = self:GetRagdollHitBone(entity, damageInfo:GetDamagePosition(), HITGROUP_GEAR);
			
			if (damageInfo:IsBulletDamage()) then
				if ((attacker:IsPlayer() or attacker:IsNPC()) and attacker != player) then
					damageInfo:ScaleDamage(10000);
				end;
			end;
		end;

		self.hooks:Call( "EntityTakeDamage", entity, damageInfo );

		local inflictor = damageInfo:GetInflictor();
		local attacker = damageInfo:GetAttacker();
		local amount = damageInfo:GetDamage();
		local curTime = CurTime();

		local bSuccess, sReason = self.plugin:RunHooks( entity:IsPlayer() and "PlayerShouldTakeDamage"
			or "EntityShouldTakeDamage", true, entity, attacker, inflictor, damageInfo );

		if ( amount != damageInfo:GetDamage() ) then amount = damageInfo:GetDamage(); end;

		if ( bSuccess or bSuccess == nil ) then		
			if (gc.config:Get("prop_kill_protection"):Get()) then	
				if ( entity:IsPlayer() and IsValid(attacker) and attacker:GetClass() == "prop_physics" ) then
					damageInfo:SetDamage(0);
					entity.gcDamageImmunity = curTime + 5;
					MsgC(Color(255,0,0), "Prop Kill Protection: "..entity:Name());
					return false;		
				end;
				
				if ((IsValid(inflictor) and inflictor:IsPlayerHolding())
				or attacker:IsPlayerHolding()) then
					damageInfo:SetDamage(0);
					return false;
				end;
				
				if ( attacker and attacker:GetClass() == "worldspawn"
				and entity.gcDamageImmunity and entity.gcDamageImmunity > curTime) then
					MsgC(Color(0,255,0), "Prop Kill Protection: "..entity:Name());
					damageInfo:SetDamage(0);
					return false;
				end;
			end;
			
			if (damageInfo:GetDamage() == 0) then return; end;
			if (damageInfo:IsExplosionDamage()) then damageInfo:ScaleDamage(2); end;

			self.plugin:RunHooks( "EntityTakeDamage", false, entity, inflictor, attacker, amount, damageInfo, curTime );
			
			local player = gc.entity:GetPlayer(entity);
			
			if ( player and entity:IsPlayer() ) then
				if (damageInfo:IsFallDamage() or gc.config:Get("damage_view_punch"):Get()) then
					player:ViewPunch(
						Angle(math.random(amount, amount), math.random(amount, amount), math.random(amount, amount))
					);
				end;
				
				if (damageInfo:IsDamageType(DMG_CRUSH) and damageInfo:GetDamage() < 10) then
					damageInfo:SetDamage(0);
				else
					local lastHitGroup = player:LastHitGroup();
					local killed = nil;
					
					if (player:InVehicle() and damageInfo:IsExplosionDamage()) then
						if (!damageInfo:GetDamage() or damageInfo:GetDamage() == 0) then
							damageInfo:SetDamage(player:GetMaxHealth());
						end;
					end;
					
					self:ScaleDamageByHitGroup(player, attacker, lastHitGroup, damageInfo, amount);
					
					if (damageInfo:GetDamage() > 0) then
						self:CalculatePlayerDamage(player, lastHitGroup, damageInfo);
						player:SetVelocity(gc.kernel:ConvertForce(damageInfo:GetDamageForce() * 32, 200));
						
						if (player:Alive() and player:Health() == 1) then
							player:SetFakingDeath(true);
								hook.Call("DoPlayerDeath", self, player, attacker, damageInfo);
								hook.Call("PlayerDeath", self, player, inflictor, attacker, damageInfo);
							player:SetFakingDeath(false, true);
						else
							local bNoMsg = gc.plugin:Call("PlayerTakeDamage", player, inflictor, attacker, lastHitGroup, damageInfo, curTime);
							local sound = gc.plugin:Call("PlayerPlayPainSound", player, player:GetGender(), damageInfo, lastHitGroup);
							
							if (sound and !bNoMsg) then
								player:EmitHitSound(sound);
							end;
						end;
					end;
					
					damageInfo:SetDamage(0);
					player.gcLastHitGroup = nil;
				end;
			elseif (entity:IsNPC()) then
				if (attacker:IsPlayer() and IsValid(attacker:GetActiveWeapon())
				and greenCode.player:GetWeaponClass(attacker) == "weapon_crowbar") then
					damageInfo:ScaleDamage(0.25);
				end;
			end;
		else
			damageInfo:SetDamage(0);

			if ( attacker:IsPlayer() and sReason ) then
				attacker:ShowAlert( sReason, Color(255,150,150,255) );
			end;
		end;
	end;

	-- Called when player says.
	gc.hooks:Register("PlayerSay");

	function greenCode:PlayerSay( player, sText, bPublic, bDead )
		local sPluginText = self.plugin:RunHooks( "PlayerSay", false, player, sText, bPublic, bDead ) or sText;
		return self.hooks:Call("PlayerSay", player, sPluginText, bPublic, bDead );
	end;
end;

-- Called after the gamemode and map load and start.
gc.hooks:Register("InitPostEntity");

function greenCode:InitPostEntity()
	self.hooks:Call( "InitPostEntity" );
	self.plugin:RunHooks( "InitPostEntity", false );
end;

-- Called each frame.
gc.hooks:Register("Think");

function greenCode:Think()
	self.hooks:Call( "Think" );
	self.plugin:RunHooks( "Think", false, CurTime() );
end;

-- Called every tick on both client and server. 
gc.hooks:Register("Tick");

-- A function to call a player's think hook.
if SERVER then
	-- A function to calculate player damage.
	function greenCode:CalculatePlayerDamage(player, hitGroup, damageInfo)
		local bDamageIsValid = damageInfo:IsBulletDamage() or damageInfo:IsDamageType(DMG_CLUB) or damageInfo:IsDamageType(DMG_SLASH);
		local bHitGroupIsValid = true;
		
		if (self.config:Get("armor_chest_only"):Get()) then
			if (hitGroup != HITGROUP_CHEST and hitGroup != HITGROUP_GENERIC) then
				bHitGroupIsValid = nil;
			end;
		end;
		
		if (player:Armor() > 0 and bDamageIsValid and bHitGroupIsValid) then
			local armor = player:Armor() - damageInfo:GetDamage();
			
			if (armor < 0) then
				self.limb:TakeDamage(player, hitGroup, damageInfo:GetDamage() * 2);
				player:SetHealth(math.max(player:Health() - math.abs(armor), 1));
				player:SetArmor(math.max(armor, 0));
			else
				player:SetArmor(math.max(armor, 0));
			end;
		else
			self.limb:TakeDamage(player, hitGroup, damageInfo:GetDamage() * 2);
			player:SetHealth(math.max(player:Health() - damageInfo:GetDamage(), 1));
		end;
		
		if (damageInfo:IsFallDamage()) then
			self.limb:TakeDamage(player, HITGROUP_RIGHTLEG, damageInfo:GetDamage());
			self.limb:TakeDamage(player, HITGROUP_LEFTLEG, damageInfo:GetDamage());
		end;
	end;

	-- A function to scale damage by hit group.
	function greenCode:ScaleDamageByHitGroup(player, attacker, hitGroup, damageInfo, baseDamage)
		if (!damageInfo:IsFallDamage() and !damageInfo:IsDamageType(DMG_CRUSH)) then
			if (hitGroup == HITGROUP_HEAD) then
				damageInfo:ScaleDamage(self.config:Get("scale_head_dmg"):Get());
			elseif (hitGroup == HITGROUP_CHEST or hitGroup == HITGROUP_GENERIC) then
				damageInfo:ScaleDamage(self.config:Get("scale_chest_dmg"):Get());
			elseif (hitGroup == HITGROUP_LEFTARM or hitGroup == HITGROUP_RIGHTARM or hitGroup == HITGROUP_LEFTLEG
			or hitGroup == HITGROUP_RIGHTLEG or hitGroup == HITGROUP_GEAR) then
				damageInfo:ScaleDamage(self.config:Get("scale_limb_dmg"):Get());
			end;
		end;
		
		self.plugin:Call("PlayerScaleDamageByHitGroup", player, attacker, hitGroup, damageInfo, baseDamage);
	end;

	function greenCode:CallThinkHook( player, setSharedVars, curTime )
		player.gcInfoTable = player.gcInfoTable or {};
		player.gcInfoTable.crouchedSpeed = player.gcCrouchedSpeed;
		player.gcInfoTable.jumpPower = player.gcJumpPower;
		player.gcInfoTable.walkSpeed = player.gcWalkSpeed;
		player.gcInfoTable.isRunning = player:IsRunning();
		player.gcInfoTable.isJogging = player:IsJogging();
		player.gcInfoTable.runSpeed = player.gcRunSpeed;
		player.gcInfoTable.DSP = player.gcDSP;
		player.gcInfoTable.state = player:Health() / player:GetMaxHealth();
		
		if (!player:IsJogging(true)) then
			player.gcInfoTable.isJogging = nil;
			player:SetSharedVar{ IsJogMode = false };
		end;

		if ( setSharedVars ) then
			self.entity:SyncSharedVars( player );
			
			local tSharedData = {};
			self.plugin:Call("PlayerSetSharedVars", player, tSharedData, curTime);
			player:SetSharedVar( tSharedData );

			local tPrivateData = {};
			self.plugin:Call("PlayerSetPrivateVars", player, tPrivateData, curTime);
			player:SetPrivateVar( tPrivateData );

			player.gcNextSetSharedVars = nil;
		end;

		self.plugin:Call( "PlayerThink", player, curTime, player.gcInfoTable, player:Alive() );

		if (player.gcInfoTable.runSpeed < player.gcInfoTable.walkSpeed) then
			player.gcInfoTable.runSpeed = player.gcInfoTable.walkSpeed;
		end;

		local curSpeed = math.Round(player:GetVelocity():Length());
		local allowSpeed = math.Round(player.gcInfoTable.runSpeed);

		/*-- Soo fucking fix
		if ( !player.gcLastALTDamage ) then
			player.gcLastALTDamage = curTime + 1;
		end;

		if ( !player:isArrested() and player:KeyDown(IN_WALK) and player.gcLastALTDamage < curTime and curSpeed > (allowSpeed+15) and !greenCode.player:IsNoClipping(player) and player:IsOnGround() ) then
			player:TakeDamage( 0.01, player, player );
			player.gcLastALTDamage = nil;
		end;*/
		
		player:SetSharedVar{ IsRunMode = player.gcInfoTable };

		local nMinSpeed = self.config:Get("min_speed"):Get(15);
		player:SetCrouchedWalkSpeed(math.max( player.gcInfoTable.crouchedSpeed, 0 ), true);
		player:SetWalkSpeed(math.max( player.gcInfoTable.walkSpeed, nMinSpeed ), true);
		player:SetJumpPower(math.max( player.gcInfoTable.jumpPower, 0 ), true);
		player:SetRunSpeed(math.max( player.gcInfoTable.runSpeed, nMinSpeed ), true);
		player:SetDSP(player.gcInfoTable.DSP or 1, false, true);
		player.gcNextThink = nil;
	end;
else
	function greenCode:CallThinkHook( player, setSharedVars, curTime )
		player.gcInfoTable = player.gcInfoTable or {};
		player.gcInfoTable.state = player:Health() / player:GetMaxHealth();
		self.plugin:Call( "PlayerThink", player, curTime, player.gcInfoTable, player:Alive() );
		player.gcNextThink = nil;
	end;
end;

function greenCode:Tick()
	self.hooks:Call( "Tick" );

	local sysTime = SysTime();
	local curTime = CurTime();
	
	for k, v in pairs(_player.GetAll()) do
		if ( v:HasInitialized() ) then
			if ( !v.gcNextThink ) then
				v.gcNextThink = curTime + 0.1;
			end;
			
			if ( !v.gcNextSetSharedVars ) then
				v.gcNextSetSharedVars = curTime + 1;
			end;
			
			if ( curTime >= v.gcNextThink ) then
				self:CallThinkHook(
					v, (curTime >= v.gcNextSetSharedVars), curTime
				);
			end;
		end;
	end;

	self.plugin:RunHooks( "Tick", false, curTime );

	if ( !self.gcLastTickSecond ) then
		self.gcLastTickSecond = curTime + 1
	end;

	if ( self.gcLastTickSecond < curTime ) then
		self.plugin:RunHooks( "TickSecond", false, curTime );
		self.gcLastTickSecond = nil;
	end;
end;

-- Called when player spawn.
gc.hooks:Register("PlayerSpawn");

function greenCode:PlayerSpawn( player )
	self.hooks:Call( "PlayerSpawn", player );

	if SERVER then
		player:UnSpectate();

		player:SetForcedAnimation(false);
		player:SetMaxHealth(100);
		player:SetMaxArmor(100);
		player:SetMaterial("");
		player:Extinguish();
		player:SetColor( Color(255, 255, 255, 255) );
		
		player:SetCrouchedWalkSpeed( self.config:Get("crouched_speed"):Get() );
		player:SetWalkSpeed( self.config:Get("walk_speed"):Get() );
		player:SetJumpPower( self.config:Get("jump_power"):Get() );
		player:SetRunSpeed( self.config:Get("run_speed"):Get() );
		
		player:SetDuckSpeed( self.config:Get("duck_speed"):Get()  );
		player:SetUnDuckSpeed( self.config:Get("unduck_speed"):Get()  );

		if (player:FlashlightIsOn()) then
			player:Flashlight(false);
		end;
		
		player:SetFakingDeath(false);
	end;

	self.plugin:RunHooks( "PlayerSpawn", false, player, player.firstSpawn, player:HasInitialized() );
	player.firstSpawn = player.firstSpawn == nil;
end;

-- Callde when player first spawn on server.
gc.hooks:Register("PlayerInitialSpawn");

function greenCode:PlayerInitialSpawn( player )
	self.hooks:Call( "PlayerInitialSpawn", player );

	player.characters = {};
	player.sharedVars = {};
	player:LoadCharacter();

	self.plugin:RunHooks( "PlayerInitialSpawn", false, player );
end;

-- Called when a player presses a key.
gc.hooks:Register("KeyPress");

function greenCode:KeyPress( player, key )
	self.hooks:Call( "KeyPress", player, key );
	
	if SERVER then
		if (key == IN_WALK) then
			local velocity = player:GetVelocity():Length();
			
			if (velocity > 0 and !player:KeyDown(IN_SPEED)) then
				player:SetSharedVar{ IsJogMode = !player:GetSharedVar("IsJogMode", false) };
			elseif (velocity == 0 and player:KeyDown(IN_SPEED)) then
				if (player:Crouching()) then
					player:ConCommand("-duck");
				else
					player:ConCommand("+duck");
				end;
			end;
		end;
	end;
	
	self.plugin:RunHooks( "KeyPress", false, player, key );
end;

-- Called just before a player dies.
gc.hooks:Register("DoPlayerDeath");

function greenCode:DoPlayerDeath( player, attacker, damageInfo )
	self.hooks:Call( "DoPlayerDeath", player, attacker, damageInfo );
	self.plugin:RunHooks( "DoPlayerDeath", false, player, attacker, damageInfo );
end;

-- Called when a player dies.
gc.hooks:Register("PlayerDeath");

function greenCode:PlayerDeath( player, inflictor, attacker, damageInfo )
	self.hooks:Call( "PlayerDeath", player, inflictor, attacker, damageInfo );
	self.plugin:RunHooks( "PlayerDeath", false, player, inflictor, attacker, damageInfo );
end;

-- Called when a player dies.
gc.hooks:Register("PlayerSilentDeath");

function greenCode:PlayerSilentDeath( player )
	self.hooks:Call( "PlayerSilentDeath", player );
	self.plugin:RunHooks( "PlayerSilentDeath", false, player );
end;

-- Called when player authed.
gc.hooks:Register("PlayerAuthed");

function greenCode:PlayerAuthed( ... )
	self.hooks:Call( "PlayerAuthed", ... );
	self.plugin:RunHooks( "PlayerAuthed", false, ... );
end;

-- Called when a player has disconnected.
greenCode.hooks:Register( "PlayerDisconnected" );

function greenCode:PlayerDisconnected( player )	
	self.hooks:Call( "PlayerDisconnected", player );

	if ( IsValid(player) ) then
		self.plugin:RunHooks( "PlayerDisconnected", false, player );
	end;
end;

-- Called right before an entity is removed.
greenCode.hooks:Register( "EntityRemoved" );

function greenCode:EntityRemoved( entity )
	self.hooks:Call( "EntityRemoved", entity );
	self.plugin:RunHooks( "EntityRemoved", false, entity );
end;

-- Called when the server shuts down.
gc.hooks:Register( "ShutDown" );

function greenCode:ShutDown()
	self.hooks:Call( "ShutDown" );
	self.plugin:RunHooks( "ShutDown" );
	self.ShuttingDown = true;
end;

-- Called whenever a player footstep is going to be played. 
gc.hooks:Register( "PlayerFootstep" );

function greenCode:PlayerFootstep( ... )
	local pluginFootstep = self.plugin:RunHooks( "PlayerFootstep", false, ... );
	local baseFootstep;

	if ( pluginFootstep == nil ) then
		baseFootstep = self.hooks:Call( "PlayerFootstep", ... );
	end;

	return pluginFootstep or baseFootstep;
end;

if SERVER then
	-- Called when a player is attacked by a trace.
	gc.hooks:Register( "PlayerTraceAttack" );

	function greenCode:PlayerTraceAttack( player, damageInfo, direction, trace )
		self.hooks:Call( "PlayerTraceAttack", player, damageInfo, direction, trace );
		player.gcLastHitGroup = trace.HitGroup;
	end;
else

	 -- Allows override of the default view.
	gc.hooks:Register("CalcView");

	function greenCode:CalcView( ... )
		local view = self.hooks:Call( "CalcView", ... )
		local greenViev = self.plugin:RunHooks( "CalcView", false, ... );
		
		if ( greenViev ) then
			if (view.vm_origin and greenViev.vm_origin) then
				greenViev.vm_origin = view.vm_origin - (greenViev.vm_origin - greenViev.vm_origin);
			end;
			
			if (view.vm_angles and greenViev.vm_angles) then
				greenViev.vm_angles = view.vm_angles// - (greenViev.vm_angles - view.vm_angles);
			end;
			
			if (view.angles and greenViev.angles) then
				greenViev.angles = view.angles + (greenViev.angles - view.angles);
			end;
		end;
		
		return greenViev or view;
	end;

	-- Called when the local player should be drawn.
	gc.hooks:Register("ShouldDrawLocalPlayer");

	function greenCode:ShouldDrawLocalPlayer( ... )
		local bSuccess = self.hooks:Call( "ShouldDrawLocalPlayer", ... );
		
		if ( bSuccess != nil ) then
			return bSuccess;
		end;
		
		local greenAllow = self.plugin:RunHooks( "ShouldDrawLocalPlayer", false, ... );
		return greenAllow or bSuccess;
	end;

	-- Called each frame.
	gc.hooks:Register( "HUDPaint" );

	function greenCode:HUDPaint()				
		if (self.Client:WaterLevel() > 2) then
			local scrW, scrH = ScrW(), ScrH();
			local fraction = 1;

			surface.SetMaterial( self.ScreenBlur )	
			surface.SetDrawColor( 255, 255, 255, 255 )
							
			for i = 0.33, 1, 0.33 do
				self.ScreenBlur:SetFloat("$blur", fraction * 20 * i);
				self.ScreenBlur:Recompute();
				
				if (render) then render.UpdateScreenEffectTexture();end;
				surface.DrawTexturedRect(0, 0, scrW, scrH);
			end;

			surface.DrawTexturedRect( 0, 0, scrW, scrH );
		end;
		
		self.hooks:Call( "HUDPaint" );
		self.plugin:RunHooks( "PostHUDPaint", false );
		if ( greenCode.kernel:IsUsingCamera() ) then return end;
		self.plugin:RunHooks( "HUDPaint", false );
	end;

	-- Used by most Post-processing effects, see them for proper examples.
	gc.hooks:Register( "RenderScreenspaceEffects" );

	function greenCode:RenderScreenspaceEffects()
		self.hooks:Call( "RenderScreenspaceEffects" );

		if (IsValid(self.Client)) then
			local frameTime = FrameTime();
			local motionBlurs = {
				enabled = true,
				blurTable = {}
			};
			local color = 1;
			local isDrunk = self.player:GetDrunk();
			
			if (self.Client:Health() <= 75) then
				motionBlurs.blurTable["health"] = math.Clamp(
					1 - ((self.Client:GetMaxHealth() - self.Client:Health()) * 0.01), 0, 1
				);
			end;
			
			if (self.Client:Alive()) then
				color = math.Clamp(color - ((self.Client:GetMaxHealth() - self.Client:Health()) * 0.01), 0, color);
			else
				color = 0;
			end;
			
			if (isDrunk and self.DrunkBlur) then
				self.DrunkBlur = math.Clamp(self.DrunkBlur - (frameTime / 10), math.max(1 - (isDrunk / 8), 0.1), 1);					
				DrawMotionBlur(self.DrunkBlur, 1, 0);
			elseif (self.DrunkBlur and self.DrunkBlur < 1) then
				self.DrunkBlur = math.Clamp(self.DrunkBlur + (frameTime / 10), 0.1, 1);
				motionBlurs.blurTable["isDrunk"] = self.DrunkBlur;
			else
				self.DrunkBlur = 1;
			end;
			
			self.ColorModify = self.ColorModify or {};
			self.ColorModify["$pp_colour_brightness"] = color < 0.7 and -((0.7 - color)*0.25) or 0;
			self.ColorModify["$pp_colour_contrast"] = 1;
			self.ColorModify["$pp_colour_colour"] = color;
			self.ColorModify["$pp_colour_addr"] = 0;
			self.ColorModify["$pp_colour_addg"] = 0;
			self.ColorModify["$pp_colour_addb"] = 0;
			self.ColorModify["$pp_colour_mulr"] = 0;
			self.ColorModify["$pp_colour_mulg"] = 0;
			self.ColorModify["$pp_colour_mulb"] = 0;
			
			self.plugin:RunHooks( "RenderScreenspaceEffects", false, self.ColorModify, motionBlurs );
			
			if (motionBlurs.enabled) then
				local addAlpha = nil;
				
				for k, v in pairs(motionBlurs.blurTable) do
					if (!addAlpha or v < addAlpha) then
						addAlpha = v;
					end;
				end;
				
				if (addAlpha) then
					DrawMotionBlur(math.Clamp(addAlpha, 0.1, 1), 1, 0);
				end;
			end;
			
			if (system.IsOSX()) then
				self.ColorModify["$pp_colour_brightness"] = 0;
				self.ColorModify["$pp_colour_contrast"] = 1;
			end;
			
			DrawColorModify(self.ColorModify);
		end;

		/*if (IsValid(self.Client)) then
			local tPPData = {
				[ "enable" ] = false,
				[ "$pp_colour_addr" ] = 0,
				[ "$pp_colour_addg" ] = 0,
				[ "$pp_colour_addb" ] = 0,
				[ "$pp_colour_brightness" ] = 0,
				[ "$pp_colour_contrast" ] = 1,
				[ "$pp_colour_colour" ] = 1,
				[ "$pp_colour_mulr" ] = 0,
				[ "$pp_colour_mulg" ] = 0,
				[ "$pp_colour_mulb" ] = 0 
			};

			local tBlurData = {
				["enable"] = false;
				["AddAlpha"] = 0;
				["DrawAlpha"] = 0;
				["Delay"] = 0;
			};

			self.plugin:RunHooks( "RenderScreenspaceEffects", false, tPPData, tBlurData );

			if ( tPPData.enable ) then DrawColorModify(tPPData); end;
			if ( tBlurData.enable ) then DrawMotionBlur( tBlurData.AddAlpha, tBlurData.DrawAlpha, tBlurData.Delay ); end;
		end;*/
	end;

	-- Called after the player is drawn.
	gc.hooks:Register("PostPlayerDraw");

	function greenCode:PostPlayerDraw( ... )
		self.hooks:Call( "PostPlayerDraw", ... );
		self.plugin:RunHooks( "PostPlayerDraw", false, ... );
	end;

	-- Called whenever a players presses a mouse key.
	gc.hooks:Register("GUIMouseReleased");
	function greenCode:GUIMouseReleased( ... )
		self.hooks:Call( "GUIMouseReleased", ... );
		self.plugin:RunHooks( "GUIMouseReleased", false, ... );
	end;

	-- Called when the player presses a mouse button (when the cursor is visible).
	gc.hooks:Register("GUIMousePressed");
	
	function greenCode:GUIMousePressed( ... )
		self.hooks:Call( "GUIMousePressed", ... );
		self.plugin:RunHooks( "GUIMousePressed", false, ... );
	end;
	
	gc.hooks:Register("PlayerBindPress");

	function greenCode:PlayerBindPress( ... )
		self.hooks:Call( "PlayerBindPress", ... );
		self.plugin:RunHooks( "PlayerBindPress", false, ... );
	end;
end;

/*gc.hooks:Register("PlayerButtonDown");

function greenCode:PlayerButtonDown( ... )
	self.hooks:Call( "PlayerButtonDown", ... );
	self.plugin:RunHooks( "PlayerButtonDown", false, ... );
end;

gc.hooks:Register("PlayerButtonUp");

function greenCode:PlayerButtonUp( ... )
	self.hooks:Call( "PlayerButtonUp", ... );
	self.plugin:RunHooks( "PlayerButtonUp", false, ... );
end;

*/

/*-- Called when the main activity should be calculated.
gc.hooks:Register("CalcMainActivity");

function gc:CalcMainActivity(player, velocity)
	player.CalcIdeal, player.CalcSeqOverride = self.hooks:Call( "CalcMainActivity", player, velocity );

	ANIMATION_PLAYER = player;

	local forcedAnimation = player:GetForcedAnimation();

	if (forcedAnimation) then
		player.CalcSeqOverride = forcedAnimation.animation;
		
		if (forcedAnimation.OnAnimate) then
			forcedAnimation.OnAnimate(player);
			forcedAnimation.OnAnimate = nil;
		end;
	end;

	ANIMATION_PLAYER = nil;

	local eyeAngles = player:EyeAngles();
	local yaw = velocity:Angle().yaw;
	local normalized = math.NormalizeAngle(yaw - eyeAngles.y);
	
	return player.CalcIdeal, player.CalcSeqOverride;
end;*/