AddCSLuaFile( 'shared.lua' )
AddCSLuaFile( 'cl_init.lua' )
include( 'shared.lua' )

function ENT:SpawnFunction( ply, tr )
	if ( !tr.Hit ) then return end
	if ( !IsValid( ply ) ) then return end

	local pos = tr.HitPos + tr.HitNormal * 16
	local ang = ply:GetAimVector():Angle()
	ang.p = 0
	ang.r = 0
	ang.y = ( ang.y + 180 ) % 360

	local ent = ents.Create( "sent_basstest" )
	ent:SetPos( pos )
	ent:SetAngles( ang )
	ent:Spawn()
	ent:Activate()

	return ent
end

function ENT:Initialize()
	self:SetUseType( SIMPLE_USE )
	self:SetModel( "models/props_lab/citizenradio.mdl" )

	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )

	local phys = self:GetPhysicsObject()
	if ( IsValid( phys ) ) then
		phys:Wake()
	end
	
	self:SetURL( "http://cs1-22v4.vk.me/p26/d88ea6d1230f3d.mp3" )
	self:SetMode( "mono" )
	self:SetVolume( 1 )
end

function ENT:OnReloaded()
	self:Remove()
end

function ENT:Use( activator, caller )
end

function ENT:Think()
	self:NextThink( CurTime()+0.03 )
	return true
end

function ENT:OnRemove()
end