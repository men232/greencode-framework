--[[
	© 2013 GmodLive private project do not share
	without permission of its author (Andrew Mensky vk.com/men232).
--]]

greenCode.entity = greenCode.kernel:NewLibrary("entity");

if SERVER then

	local tRemoveDataKey = {
		[""]     = true,
		["nil"]  = true,
		["null"] = true
	};

	-- A function to set a shared variable for a player or entity.
	function greenCode.entity:SetSharedVar( entity, tData, bIgnore, bPrivate )
		if ( IsValid( entity ) or entity:IsWorld() and type( tData ) == "table" ) then
			entity.gcSharedVars = entity.gcSharedVars or {};
			entity.gcPrivateVars = entity.gcPrivateVars or {};

			local tSendData = {};
			local bShouldSend = false;

			for k, v in pairs( tData ) do
				if ( (tRemoveDataKey[ v ] or v == GC_NIL_KEY) and !bIgnore ) then
					entity.gcSharedVars[ k ] = nil;
					tData[k]                 = nil;
					tSendData[ k ]           = GC_NIL_KEY;
				elseif ( entity.gcSharedVars[ k ] != v ) then
					tSendData[ k ]         = v;
				end;
			end;
			
			for k, v in pairs( tData ) do
				entity.gcPrivateVars[k] = bPrivate or nil;
				entity.gcSharedVars[k] = v;
			end;

			//table.Merge( entity.gcSharedVars, tData );
			
			//if ( self.gcSharedCache ) then
			//	self.gcSharedCache[ entity ] = entity.gcSharedVars or {};
			//end;
			
			//print("=============================")
			//PrintTable(tSendData)
			//print("=============================")

			if ( table.Count(tSendData) > 0 ) then
				greenCode.datastream:Start( bPrivate and entity or true, "SharedVar", { e = entity, d = tSendData } );
			end;
		end;
	end;

	function greenCode.entity:SyncSharedVars( player )
		local curTime = CurTime();

		if ( !player.gcLastSyncSharedVars ) then
			player.gcLastSyncSharedVars = 0;
		end;
		
		if ( curTime >= player.gcLastSyncSharedVars ) then
			local tSendData = {};

			//if ( !self.gcSharedCache or self.gcSharedCacheTimeLeft < curTime ) then
				for k, v in ipairs( _ents.GetAll() ) do
					tSendData[v] = v.gcSharedVars;
					
					for k, v in ipairs( v.gcPrivateVars or {} ) do
						tSendData[v][k] = nil;
					end;
				end;

				local eWorld = game.GetWorld();
				tSendData[ eWorld ] = eWorld.gcSharedVars;

				//self.gcSharedCache = tSendData;
				//self.gcSharedCacheTimeLeft = curTime + 5;
			//else
			//	tSendData = self.gcSharedCache;
			//end;

			greenCode.datastream:Start( player, "SyncSharedVars", tSendData );
			
			player.gcLastSyncSharedVars = curTime + 300;
		end;
	end;

else
	greenCode.datastream:Hook( "SharedVar", function( tData )
		local entity = tData.e;
		local tData = tData.d;

		if ( IsValid( entity ) or entity:IsWorld() and type( tData ) == "table" ) then
			entity.gcSharedVars = entity.gcSharedVars or {};

			for k, v in pairs( tData ) do
				if ( v == GC_NIL_KEY ) then 
					tData[ k ]               = nil;
					entity.gcSharedVars[ k ] = nil;
				end;
			end;
			
			for k, v in pairs( tData ) do
				entity.gcSharedVars[k] = v;
			end;

			//table.Merge( entity.gcSharedVars, tData );
		end;
	end);

	greenCode.datastream:Hook( "SyncSharedVars", function( tData )
		for entity, vars in pairs( tData ) do
			if !IsValid( entity ) and !entity:IsWorld() then
				continue;
			end;
			
			entity.gcSharedVars = vars or {};

			//if ( !entity.gcSharedVars ) then
			//	entity.gcSharedVars = {};
			//end;
			
			//table.Merge( entity.gcSharedVars, vars or {} );
		end;
	end);
end;

if SERVER then

	-- A function to set an entity's player.
	function greenCode.entity:SetPlayer(entity, player)
		entity:SetNetworkedEntity("player", player);
	end;

end;

-- A function to get an entity's player.
function greenCode.entity:GetPlayer(entity)
	local player = entity:GetNetworkedEntity( "player", entity );
	
	if ( IsValid(player) and player:IsPlayer() ) then
		return player;
	elseif ( entity:IsPlayer() ) then
		return entity;
	end;
end;

-- A function to check entity is a door.
local tDoorClass = {
	"func_door",
	"func_door_rotating",
	"prop_door_rotating",
	"prop_door_rotating",
	"prop_dynamic"
};

function greenCode.entity:IsDoor( entity )	
	return IsValid(entity) and table.HasValue(tDoorClass, entity:GetClass());
end

-- A function to get a ragdoll entity's pelvis position.
function greenCode.entity:GetPelvisPosition( entity )
	local position = entity:GetPos();
	local physBone = entity:LookupBone("ValveBiped.Bip01_Pelvis");

	if (physBone) then
		local bonePosition = entity:GetBonePosition(physBone);
		
		if (bonePosition) then
			position = bonePosition;
		end;
	end;
	
	return position;
end;

-- A function to get a shared variable for a player or entity.
function greenCode.entity:GetSharedVar( entity, key, default )
	if ( IsValid( entity ) or entity:IsWorld() ) then
		entity.gcSharedVars = entity.gcSharedVars or {};
		return entity.gcSharedVars[ key ] != nil and entity.gcSharedVars[key] or default;
	else
		return default;
	end;
end;

-- Called to get whether an entity is being held.
function greenCode.entity:GetEntityBeingHeld(entity)
	return entity.gcIsBeingHeld or entity:IsPlayerHolding();
end;

local entityMeta = FindMetaTable("Entity");

-- A function to get whether an entity is being held.
function entityMeta:IsBeingHeld()
	if (IsValid(self)) then
		return gc.plugin:Call("GetEntityBeingHeld", self);
	end;
end;

-- A function to get shared vars.
function entityMeta:SharedVars() return self.gcSharedVars or {}; end;

-- A function to get a shared variable for a player or entity.
function entityMeta:GetSharedVar( key, default ) return greenCode.entity:GetSharedVar( self, key, default ); end;

-- A function to get whether an entity can see a position.
function greenCode.entity:CanSeePosition( entity, position, iAllowance, tIgnoreEnts )
	local trace = {};
	
	trace.mask = CONTENTS_SOLID + CONTENTS_MOVEABLE + CONTENTS_OPAQUE + CONTENTS_DEBRIS + CONTENTS_HITBOX + CONTENTS_MONSTER;
	trace.start = entity:LocalToWorld(entity:OBBCenter());
	trace.endpos = position;
	trace.filter = {entity};
	
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

-- A function to get whether an entity can see an NPC.
function greenCode.entity:CanSeeNPC( entity, target, iAllowance, tIgnoreEnts )
	local trace = {};
	
	trace.mask = CONTENTS_SOLID + CONTENTS_MOVEABLE + CONTENTS_OPAQUE + CONTENTS_DEBRIS + CONTENTS_HITBOX + CONTENTS_MONSTER;
	trace.start = entity:LocalToWorld(entity:OBBCenter());
	trace.endpos = target:GetShootPos();
	trace.filter = {entity, target};
	
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

-- A function to get whether an entity can see a player.
function greenCode.entity:CanSeePlayer( entity, target, iAllowance, tIgnoreEnts )
	if (target:GetEyeTraceNoCursor().Entity == entity) then
		return true;
	else
		local trace = {};
		
		trace.mask = CONTENTS_SOLID + CONTENTS_MOVEABLE + CONTENTS_OPAQUE + CONTENTS_DEBRIS + CONTENTS_HITBOX + CONTENTS_MONSTER;
		trace.start = entity:LocalToWorld(entity:OBBCenter());
		trace.endpos = target:GetShootPos();
		trace.filter = {entity, target};
		
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
end;

-- A function to get whether an entity can see an entity.
function greenCode.entity:CanSeeEntity( entity, target, iAllowance, tIgnoreEnts )
	local trace = {};
	trace.mask = CONTENTS_SOLID + CONTENTS_MOVEABLE + CONTENTS_OPAQUE + CONTENTS_DEBRIS + CONTENTS_HITBOX + CONTENTS_MONSTER;
	trace.start = entity:LocalToWorld(entity:OBBCenter());
	trace.endpos = target:LocalToWorld(target:OBBCenter());
	trace.filter = {entity, target};
	
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

if SERVER then
	-- A function to check super admin right.
	function entityMeta:IsAdminRight( super )
		if (super) then
			return self:EntIndex() == 0 or self:IsSuperAdmin();
		else
			return self:EntIndex() == 0 or self:IsAdmin();
		end;
	end;

	-- A function to print message.
	function entityMeta:PrintMsg(type, msg)
		if (self:IsPlayer() and self:EntIndex() != 0) then
			self:PrintMessage(type, msg);
		else
			print(msg);
		end;
	end;

	concommand.Add("gc_sendsharedvars", function( player, command, args )
		greenCode.entity:SyncSharedVars( player );
	end);
end;