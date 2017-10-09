--[[
	© 2013 GmodLive private project do not share
	without permission of its author (Andrew Mensky vk.com/men232).
--]]

local greenCode = greenCode;
local math = math;

//award_star_bronze_1
//award_star_bronze_2
//award_star_bronze_3

LVL_STAR_LIST = {
	[0]  = Material("icon16/award_star_bronze_1.png"),
	
	[1]  = Material("icon16/award_star_bronze_1.png"),
	[2]  = Material("icon16/award_star_bronze_2.png"),
	[3]  = Material("icon16/award_star_bronze_3.png"),
	[4]  = Material("icon16/award_star_silver_1.png"),
	[5]  = Material("icon16/award_star_gold_1.png"),
	[6]  = Material("icon16/award_star_gold_2.png"),
	[7]  = Material("icon16/award_star_gold_3.png"),
	["max"]  = Material("icon16/star.png"),
}

local playerMeta = FindMetaTable("Player");

function playerMeta:GetLVLIcon()
	local lvl = self:GetSharedVar("atb_lvl", 1);

	if ( lvl >= gc.attribute:FindByID(ATB_LEVEL).maximum ) then
		return LVL_STAR_LIST.max;
	else
		return LVL_STAR_LIST[math.Clamp(math.floor(lvl/10), 1, 7)];
	end;
end;

TOPHUD_LVL = TOPHUD_CLASS:New{ name = "LvL", icon = LVL_STAR_LIST[0] }
	function TOPHUD_LVL:Think()
		local lvl = greenCode.attributes:Get(ATB_LEVEL);
		self:SetData( "text", lvl );
		self:SetData( "icon", LVL_STAR_LIST[math.Clamp(math.floor(lvl/10), 1, 23)] );
	end;
TOPHUD_LVL:Register();