--[[
	© 2013 GmodLive private project do not share
	without permission of its author (Andrew Mensky vk.com/men232).
--]]

local PLUGIN = PLUGIN or greenCode.plugin:Loader();
PLUGIN.stored = PLUGIN.stored or {};

function PLUGIN:GetObject()
	local tObjects = {};
	
	for k, entity in pairs(_ents.GetAll()) do
		if ( entity.permID ) then
			tObjects[ entity.permID ] = entity;
		end;
	end;

	return tObjects;
end;

function PLUGIN:Add( entity )
	local bExists = entity.permID and self.stored[entity.permID];
	
	if ( !entity.permID ) then
		entity.permID = util.CRC(os.time().."_"..CurTime()..entity:EntIndex());
	end;
	
	local phys = entity:GetPhysicsObject();
	local bFrozen = IsValid(phys) and !phys:IsMoveable();
	
	self.stored[entity.permID] = {
		mat = entity:GetMaterial(),
		frozen = bFrozen,
		mdl = entity:GetModel(),
		class = entity:GetClass(),
		pos = entity:GetPos(),
		ang = entity:GetAngles()
	};
	
	self:Save();
	greenCode.entity:SetSharedVar(entity, { PermObject = true });
	
	return true, "Object ["..self.stored[entity.permID].class.."] "..entity.permID..(bExists and " update." or " add.");
end;

function PLUGIN:Remove( entity )
	if (entity.permID and self.stored[entity.permID]) then
		self.stored[entity.permID] = nil;
		greenCode.entity:SetSharedVar(entity, { PermObject = "nil" });
		
		self:Save();
		
		return true, "Object ["..entity:GetClass().."] "..entity.permID.." removed.";
	end;
	
	return false, "Object not perm object."
end;

function PLUGIN:RestoreObject()
	local tSpawnedObject = self:GetObject();
	local tSpawnedDebug = { "Spawn permobject" };
	local tSkipDebug = { "Skip permobject" };
	
	for k, v in pairs(self.stored) do
		if (!tSpawnedObject[k]) then
			local ent = ents.Create(v.class);
			
			if (!IsValid(ent)) then
				greenCode:Error("Perma Object", "filed spawn permobject "..k.." ["..v.class.."].");
				continue;
			end;
			
			ent.permID = k;
			ent:SetModel(v.mdl);
			ent:SetPos(v.pos);
			ent:SetAngles(v.ang);
			if (v.mat) then ent:SetMaterial(v.mat); end;
			ent:Spawn();
			ent:Activate();
			
			local phys = ent:GetPhysicsObject();

			if (IsValid(phys)) then
				phys:Wake();
				phys:EnableMotion(!v.frozen);
			end;
			
			greenCode.entity:SetSharedVar(ent, { PermObject = true });
			
			table.insert( tSpawnedDebug, "["..k.."] ["..v.class.."] ["..v.mdl.."]" );
		else
			table.insert( tSkipDebug, "["..k.."] ["..v.class.."] ["..v.mdl.."]" );
		end;
	end;
	
	if ( #tSpawnedDebug > 1 ) then greenCode:Debug( table.concat(tSpawnedDebug, "\n\t\t") ); end;
	if ( #tSkipDebug > 1 ) then greenCode:Debug( table.concat(tSkipDebug, "\n\t\t") ); end;
end;

-- A function to save cars data.
function PLUGIN:Save()
	local map = string.lower(game.GetMap());
	greenCode.kernel:SaveGameData("permObject/"..map, self.stored);
end;

-- A function to save data.
function PLUGIN:Load()
	local map = string.lower(game.GetMap());
	
	if (greenCode.kernel:GameDataExists("permObject/"..map)) then
		self.stored = greenCode.kernel:RestoreGameData("permObject/"..map);
		greenCode:Success("Perma Object", "initialized...");
	end;
end;

-- A functiln to clean all cars.
function PLUGIN:Clear()
	self.stored = {};
	self:Save();
end;

function PLUGIN:InitPostEntity()
	self:Load();
	self:RestoreObject();
end;

greenCode.command:Add( "perm_load", 2, function( player, command, args )
	PLUGIN:Load();
end);

greenCode.command:Add( "perm_save", 2, function( player, command, args )
	PLUGIN:Save();
end);

greenCode.command:Add( "perm_restore", 2, function( player, command, args )
	PLUGIN:RestoreObject();
end);

greenCode.command:Add( "perm_clean", 2, function( player, command, args )
	local tSpawnedObject = PLUGIN:GetObject();
	local tRemovedDebug = { "Remove perm object:" };
	
	for k, v in pairs(tSpawnedObject) do
		if (PLUGIN.stored[v.permID]) then
			table.insert( tRemovedDebug, "["..v.permID.."] ["..v:GetClass().."] ["..v:GetModel().."]" );
			v:Remove();
		end;
	end;
	
	if (#tRemovedDebug > 1) then greenCode:Debug( table.concat(tRemovedDebug, "\n\t\t") ); end;
end);

greenCode.command:Add( "perm_update", 2, function( player, command, args )
	local tSpawnedObject = PLUGIN:GetObject();
	
	for k, v in pairs(tSpawnedObject) do
		greenCode.entity:SetSharedVar(v, { PermObject = true });
	end;
end);