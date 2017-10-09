--[[
	© 2013 GmodLive private project do not share
	without permission of its author (Andrew Mensky vk.com/men232).
--]]

TOPHUD_PROPS = TOPHUD_CLASS:New{ name = "Props", icon = Material("icon16/brick.png") }
	function TOPHUD_PROPS:Think()
		if ( greenCode.Client.GetCount ) then
			self:SetData("text", greenCode.Client:GetCount("props").."/"..cvars.Number( "sbox_maxprops", 0 ));
		end;
	end;
TOPHUD_PROPS:SetData( "priority", 3 );
TOPHUD_PROPS:Register();