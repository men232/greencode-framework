--[[
	© 2013 GmodLive private project do not share
	without permission of its author (Andrew Mensky vk.com/men232).
--]]

local greenCode = greenCode;
local math = math;

local PLUGIN = PLUGIN or greenCode.plugin:Loader();
ECONOMIC_TAX = 0;

PLUGIN.stored = PLUGIN.stored or {};

function PLUGIN:GetStatus()
	return self.stored.status or 1;
end;

function PLUGIN:GetStock()
	return self.stored.stock or 0;
end;

function PLUGIN:GetPrice( nAmount ) return math.Round( nAmount * (1 + (1 - self:GetStatus())*greenCode.config:Get("bank_agres"):Get(2)) ); end;

greenCode.datastream:Hook( "_RPEconomic", function( tData )
	ECONOMIC_TAX = tData.tax or 0;
		tData.tax = nil;
	PLUGIN.stored = tData or {};
end);