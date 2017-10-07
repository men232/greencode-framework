--[[
	© 2013 GmodLive private project do not share
	without permission of its author (Andrew Mensky vk.com/men232).
--]]
if SERVER then return end;

local greenCode = greenCode;

local PLUGIN = PLUGIN or greenCode.plugin:Loader();
PLUGIN.stored = {};
PLUGIN.layout = {};
PLUGIN.wpBack = PLUGIN.wpBack or {};

-- Add draw weapon
function PLUGIN:Add(class, layout)
	local weapon = weapons.Get( class );
	if ( weapon ) then
		self.stored[class] = weapon.WorldModel;
		self.layout[class] = layout;
	end;
end;

-- Called at an interval while a player is connected.
function PLUGIN:PlayerThink( player, curTime, infoTable, bAlive )
	local id = player:EntIndex();

	if ( bAlive ) then				
		if ( !self.wpBack[id] ) then
			self.wpBack[id] = {};
		end;
		
		local wpBack = self.wpBack[id];

		local curWeapon = IsValid( player:GetActiveWeapon() ) and player:GetActiveWeapon():GetClass() or "";
		local tShouldDraw = {};

		if ( player != gc.Client or player:GetViewEntity() != player ) then
			for i, weapon in pairs( player:GetWeapons() ) do
				local sClass = weapon:GetClass();
				if ( sClass != curWeapon and self.stored[ sClass ] ) then
					if ( !wpBack[ sClass ] ) then
						wpBack[ sClass ] = ClientsideModel(self.stored[ sClass ], RENDERGROUP_OPAQUE);
						wpBack[ sClass ]:SetRenderMode(1);
						wpBack[ sClass ]:SetColor(Color(255,255,255,255));
					end;
					tShouldDraw[ sClass ] = true;
				end;
			end;
		end;

		for class, v in pairs(wpBack) do
			if ( !tShouldDraw[class] ) then
				v:Remove();
				wpBack[ class ] = nil;
			end;
		end;
	elseif ( self.wpBack[id] ) then
		for i, weapon in pairs( self.wpBack[id] ) do
			weapon:Remove()
		end;
		self.wpBack[id] = nil;
	end;
end;

function PLUGIN:TickSecond( curTime )
	for id, wpBack in pairs(self.wpBack) do
		if ( !Entity(id):IsValid() ) then
			for i, weapon in pairs(wpBack) do
				weapon:Remove()
			end;
			self.wpBack[id] = nil;
		end;
	end;
end;

function PLUGIN:LayoutEntity(player, entity, count)
	local position, angles = vector_zero, angle_zero;
	local bone = player:LookupBone("ValveBiped.Bip01_Spine");

	if (bone != -1) then
		position, angles = player:GetBonePosition(bone);
		position = position + (angles:Right() *3) +(angles:Forward() *6) - (angles:Up() *4);
		if count > 0 then
			angles:RotateAroundAxis(angles:Right(), count * -5);
			position = position + (angles:Right() *(count*1.1));
		end;
		angles:RotateAroundAxis(angles:Up(), 10);
	end;
	
	return entity, position, angles;
end;

function PLUGIN:PostPlayerDraw( player )
	local id = player:EntIndex();
	local wpBack = self.wpBack[id];
	
	if ( wpBack ) then
		local nCount = 0;
		
		for class, v in pairs(wpBack) do
			local entity, position, angles;
			if ( self.layout[class] ) then
				entity, position, angles = self.layout[class](player, v, nCount);
			else
				entity, position, angles = self:LayoutEntity(player, v, nCount);
			end;
			entity:SetPos(position);
			entity:SetAngles(angles);
			entity:SetupBones();
			nCount = nCount + 1;
		end;
	end;
end;

PLUGIN:Add( "weapon_mad_awm" );
PLUGIN:Add( "weapon_mad_ump" );
PLUGIN:Add( "weapon_mad_famas" );
PLUGIN:Add( "weapon_mad_galil" );
PLUGIN:Add( "weapon_mad_m249" );
PLUGIN:Add( "weapon_mad_m4" );
PLUGIN:Add( "weapon_mad_sg550" );
PLUGIN:Add( "weapon_mad_sg552" );
PLUGIN:Add( "weapon_mad_aug" );
PLUGIN:Add( "weapon_mad_p90" );
PLUGIN:Add( "weapon_mad_awp" );
PLUGIN:Add( "weapon_mad_ak47" );
PLUGIN:Add( "weapon_mad_g3" );
PLUGIN:Add( "weapon_mad_scout" );
PLUGIN:Add( "weapon_mad_mp5" );
PLUGIN:Add( "weapon_mad_rpg" );

//PLUGIN:Add("cstm_rif_ak47", "models/weapons/w_rif_ak47.mdl")
//PLUGIN:Add("weapon_m42", "models/weapons/w_rif_m4a1.mdl")
//PLUGIN:Add("weapon_mp52", "models/weapons/w_smg_mp5.mdl")
//PLUGIN:Add("weapon_pistol", "models/weapons/w_pistol.mdl", LayoutPistol)
//PLUGIN:Add("weapon_shotgun", "models/weapons/w_shot_m3super90.mdl", LayoutShotgun)
//PLUGIN:Add("weapon_rpg", "models/weapons/w_rocket_launcher.mdl")
//PLUGIN:Add("weapons_shotgun", "models/Weapons/w_shotgun.mdl")