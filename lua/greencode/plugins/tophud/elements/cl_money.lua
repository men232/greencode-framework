--[[
	© 2013 GmodLive private project do not share
	without permission of its author (Andrew Mensky vk.com/men232).
--]]

local greenCode = greenCode;
local string = string;
local math = math;

TOPHUD_MONEY = TOPHUD_CLASS:New{ name = "Money", icon = Material("icon16/money.png") }
	function TOPHUD_MONEY:Think()
		local moneyDelta = greenCode.kernel:GetRpVar("money", 0);
		local moneyCur = self.money or 0;
		local cof = string.len(math.abs(moneyDelta-moneyCur));
		
		self.money = math.Approach(self.money or 0, moneyDelta, cof^math.max(cof-2, 1) );
		self:SetData("text", (CUR or "$")..greenCode.kernel:FormatNumber(self.money));
	end;
TOPHUD_MONEY:SetData( "priority", 2 );
TOPHUD_MONEY:Register();