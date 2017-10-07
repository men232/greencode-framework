--[[
	© 2013 GmodLive private project do not share
	without permission of its author (Andrew Mensky vk.com/men232).
--]]

local greenCode = greenCode;

TOPHUD_TERRITORY = TOPHUD_CLASS:New{ text = "Неизвестно", name = "Territory", icon = Material("icon16/world.png") }
	function TOPHUD_TERRITORY:Think()
		local TERRITORY = greenCode.Client.gcLocation;
		
		if ( TERRITORY and TERRITORY:IsValid() ) then
			self:SetData("text", TERRITORY:Name().." | "..TERRITORY:UniqueID());
		else
			self:SetData("text", "Неизвестно");
		end;
	end;
TOPHUD_TERRITORY:SetData( "priority", 4 );
TOPHUD_TERRITORY:Register();