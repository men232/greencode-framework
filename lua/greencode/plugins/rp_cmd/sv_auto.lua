--[[
	© 2013 GmodLive private project do not share
	without permission of its author (Andrew Mensky vk.com/men232).
--]]
if CLIENT then return end;

local greenCode = greenCode;
local PLUGIN = PLUGIN or greenCode.plugin:Loader();

greenCode.chat:AddCommand( "roll", function( player, tArguments )
	greenCode.chat:Area( player:GetShootPos(), 550, player:Name().." выкинул "..math.random(0, 100).." из 100" );
end);

greenCode.chat:AddCommand( "resetjob", function( player, tArguments )
	if ( player:IsSuperAdmin() ) then
		for k, v in pairs( _player.GetAll() ) do
			v:ChangeTeam(GAMEMODE.DefaultTeam, true);
		end;
	end;
end);

greenCode.chat:AddCommand( "жертва", function( player, tArguments )
	local nAmount = tonumber(tArguments[1] or 50);
	local nProgress = math.ceil( nAmount/250 );
	
	player:AddMoney(-nAmount);
	player:ProgressAttribute( ATB_LEVEL, nProgress, true );
	
	if ( nAmount > 100 ) then
		greenCode.hint:SendAll( player:Name().." пожертвовал городу "..greenCode.kernel:FormatNumber(nAmount).."$", 5, Color(100,255,100), true, true );
	end;
end);

function PLUGIN:onKeysLocked( entity )
	-- Lock create
	if !entity:IsVehicle() and !IsValid(entity.lock1) then	
		if (string.lower( entity:GetClass() ) == "prop_door_rotating") then
			-- Remove lock
			if IsValid(entity.lock1) then entity.lock1:Remove() end
			if IsValid(entity.lock2) then entity.lock2:Remove() end
		
			entity.lock1 = ents.Create("door_lock")		
			entity.lock1.door = entity
			entity.lock1.type = 1
			entity.lock1:Spawn()	

			entity.lock2 = ents.Create("door_lock")	
			entity.lock2.door = entity
			entity.lock2.type = 2	
			entity.lock2:Spawn()	
		end
	end
end;

function PLUGIN:onKeysUnlocked( entity )
	-- Remove lock
	if IsValid(entity.lock1) then entity.lock1:Remove() end
	if IsValid(entity.lock2) then entity.lock2:Remove() end
end;

function PLUGIN:canChangeJob( player )
end;

function PLUGIN:OnPlayerChangedTeam( player, oldTeam, newTeam )
	/*if ( newTeam != GAMEMODE.DefaultTeam and !greenCode.string:CheckName( player:Name() ) ) then
		player:ChangeTeam(GAMEMODE.DefaultTeam, true);
		return false, "Для начала, исправьте ошибки в своём имени!";
	end;*/
	
	if ( newTeam == TEAM_SWAT ) then
		player:SetArmor(100);
		player.gcSwatServed = true;
	elseif ( player.gcSwatServed ) then
		player:SetArmor(0);
	end;
	
	/*if ( curTeam == TEAM_MEDIC ) then
		self.HasMedic = true;
	else		
		for k, v in pairs(_player.GetAll()) do
			if ( v:Team() == TEAM_MEDIC ) then
				self.HasMedic = true;
				return;
			end;
		end;
		
		self.HasMedic = false;
	end;*/
end;

function PLUGIN:PlayerSpawn( player, bFirstSpawn, bInitialized )
	if ( player:Team() == TEAM_SWAT ) then
		player:SetArmor(100);
	end;
end;

local HOSPITAL = 5746;
local HOSPITAL_PALATA = {
	[25132] = true,
	[5673] = true,
	[35136] = true,
};
local DOC_ON_HOSPITAL = false;

function PLUGIN:TickSecond(curTime)
	for k, v in pairs(_player.GetAll()) do
		if ( v:Team() == TEAM_MEDIC and v:GetSharedVar("territory", 0) == HOSPITAL ) then
			DOC_ON_HOSPITAL = true;
			return;
		end;
	end;
	
	DOC_ON_HOSPITAL = false;
end;

-- Called at an interval while a player is connected.
function PLUGIN:PlayerThink( player, curTime, infoTable, bAlive )
	if ( !DOC_ON_HOSPITAL and bAlive and HOSPITAL_PALATA[player:GetSharedVar("territory", 0)] ) then
		local nMaxHealth = player:GetMaxHealth();
		local nHealth = player:Health();
		
		if ( !player.gcNextHealth ) then
			player.gcNextHealth = 0;
		end;
		
		if ( !player.gcLastTakeDamage ) then
			player.gcLastTakeDamage = 0;
		end;
		
		if ( ( nHealth < nMaxHealth or greenCode.limb:IsAnyDamaged(player) ) and (player.gcLastTakeDamage+5) < curTime and player.gcNextHealth < curTime ) then		
			player:SetHealth( math.Clamp(nHealth + 1, 1, nMaxHealth) )
			greenCode.limb:HealBody( player, 1 );
			
			if ( player:CanAfford(2) ) then
				player:AddMoney(-2);
			end;
			
			player.gcNextHealth = curTime + 1;
		end;
	end;
end;

function PLUGIN:EntityTakeDamage( entity, inflictor, attacker, amount, damageInfo, curTime )
	if (entity:IsPlayer()) then
		entity.gcLastTakeDamage = curTime;
	end;
end;

-- Disable moution on prop.
function PLUGIN:PlayerSpawnedProp( player, model, ent )
	//ent:SetMoveType(MOVETYPE_NONE);
	local phys = ent:GetPhysicsObject();
	if (IsValid(phwys)) then
		phys:EnableMotion(false);
	end;
end;