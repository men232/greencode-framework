ENT.Type			= "anim"
ENT.Base			= "base_anim"
ENT.PrintName		= "Bass Test"
ENT.Author			= "Grocel"
ENT.Information		= "To test sound.PlayURL()."


ENT.Editable			= true
ENT.Spawnable			= true
ENT.AdminOnly			= false
ENT.RenderGroup 		= RENDERGROUP_BOTH


function ENT:SetupDataTables()
	--String
	self:NetworkVar( "String", 0, "URL", {KeyName = "URL", Edit = {type = "String"}} )
	self:NetworkVar( "String", 1, "Mode", {KeyName = "Mode", Edit = {type = "String"}} )

	--Bool

	--Float
	self:NetworkVar( "Float", 0, "Volume", {KeyName = "Volume", Edit = {type = "Float", min = 0, max = 1, order = 1}} )

	--Int

	--Vector

	--Angle

	--Entity
end