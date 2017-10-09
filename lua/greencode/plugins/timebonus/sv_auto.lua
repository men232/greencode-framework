--[[
	© 2013 GmodLive private project do not share
	without permission of its author (Andrew Mensky vk.com/men232).
--]]
if CLIENT then return end;

local PLUGIN = PLUGIN or greenCode.plugin:Loader();

PLUGIN.stored = {};

-- A function to add time bonus.
function PLUGIN:AddBonus( sName, nTime, fGetBonus, nAmount )
	self.stored[ sName ] = {
		time = nTime,
		amount = nAmount,
		callback = fGetBonus,
	};
end;

-- A function to give time bonus.
function PLUGIN:GiveBonus( player, sBonus, ... )
	local tBonus = self.stored[ sBonus ];

	if ( tBonus ) then
		greenCode:Debug( "Give time bonus ["..sBonus.." => "..tBonus.amount.."] for "..player:Name() );
		return tBonus.callback( player, tBonus.amount, ... );
	end;

	return false;
end;

-- Called at an interval while a player is connected.
function PLUGIN:PlayerThink( player, curTime, infoTable )
	for name, bonus in pairs( self.stored ) do
		if ( !player[ "tBonus"..name ] ) then
			player[ "tBonus"..name ] = curTime + bonus.time;
		end;
	

		if ( player[ "tBonus"..name ] < curTime ) then
			self:GiveBonus( player, name, bonus.amount );
			player[ "tBonus"..name ] = nil;
		end;
	end;
end;

------------------------------
--        Time Bonus        --
-- name, time, func, amount --
------------------------------

PLUGIN:AddBonus( "lvl", 15*65, function( player, nAmount ) player:ProgressAttribute( ATB_LEVEL, nAmount, true ); end, 10 );
//PLUGIN:AddBonus( "lvl2", 5, function( player, nAmount ) player:ProgressAttribute( ATB_LEVEL, nAmount, true ); end, -100 );