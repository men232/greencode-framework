--[[
	© 2013 GmodLive private project do not share
	without permission of its author (Andrew Mensky vk.com/men232).
--]]

local greenCode = greenCode;

TOPHUD_JOB = TOPHUD_CLASS:New{ name = "Job", icon = Material("icon16/user.png") }
	function TOPHUD_JOB:Think()
		self:SetData("text", greenCode.kernel:GetRpVar("job", "Citizen"));
	end;
TOPHUD_JOB:SetData( "priority", 5 );
TOPHUD_JOB:Register();