--[[
	© 2013 GmodLive private project do not share
	without permission of its author (Andrew Mensky vk.com/men232).
--]]

local greenCode = greenCode;
local ECONOMIC = greenCode.plugin:Get("rp_economic");
local string = string;

TOPHUD_ECONOMIC = TOPHUD_CLASS:New{ onlyadmin = true, team = {TEAM_MAYOR}, text = "Неизвестно", name = "Economic", icon = Material("icon16/coins.png") }
	function TOPHUD_ECONOMIC:Think()
		if (!ECONOMIC) then
			ECONOMIC = greenCode.plugin:Get("rp_economic");
			return "0 ^ 0";
		end;
		
		local stock = ECONOMIC:GetStock();
		local status = ECONOMIC:GetStatus();
		self:SetData( "text", string.Left(status, 4).." ^ "..greenCode.kernel:FormatNumber(stock).." # "..greenCode.kernel:FormatNumber(ECONOMIC_TAX).."$" );
	end;
TOPHUD_ECONOMIC:SetData( "priority", 7 );
TOPHUD_ECONOMIC:Register();