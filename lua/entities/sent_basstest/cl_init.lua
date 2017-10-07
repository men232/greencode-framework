include( 'shared.lua' )

function ENT:Initialize()
	self.Sound = nil
	self.Connecting = false
end

function ENT:RemoveSound()
	if !self.Sound then return end

	self.Sound:Stop()
end

function ENT:OnURLChanged( url, mode )
	self:RemoveSound()

	if self.Connecting then return end
	self.Connecting = true
	self.oldurl = url
	self.oldmode = mode

	local t = sound.PlayURL( url, "3d"..mode, function( ... )
		if !IsValid( self ) then return end

		self:RemoveSound()
		self.Connecting = false

		self.OnStream( self, ... )
	end )
end

function ENT:OnStream( sound )
	if ( sound ) then
		print( self, "Sound" )

		self.Sound = sound
		self.Sound:Play()
		self.Sound:SetVolume( self:GetVolume() )
	else
		print( self, "No Sound" )
	end
end


function ENT:Think()
	local URL = self:GetURL()
	local Mode = self:GetMode()
	if self.oldurl ~= URL or self.oldmode ~= Mode then
		self:OnURLChanged( URL, Mode )
	end
	
	if self.Sound then
		self.Sound:SetVolume( self:GetVolume() )
		self.Sound:SetPos( self:GetPos() )
	end

	self:NextThink( CurTime()+0.03 )
	return true
end


function ENT:Draw()
	self:DrawModel()
end

function ENT:OnRemove()
	self:RemoveSound()
end