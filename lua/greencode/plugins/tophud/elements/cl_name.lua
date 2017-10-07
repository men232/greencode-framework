--[[
	© 2013 GmodLive private project do not share
	without permission of its author (Andrew Mensky vk.com/men232).
--]]

local greenCode = greenCode;

TOPHUD_NAME = TOPHUD_CLASS:New{ name = "Job", icon = Material("icon16/user_gray.png") }
	function TOPHUD_NAME:Think()
		self:SetData("text", greenCode.Client:Name() or "Who Are You?");
	end;
TOPHUD_NAME:SetData( "priority", 6 );
TOPHUD_NAME:Register();