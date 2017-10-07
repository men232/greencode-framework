--[[
	© 2013 GmodLive private project do not share
	without permission of its author (Andrew Mensky vk.com/men232).
--]]

local greenCode = greenCode;
local concommand     = concommand;

greenCode.command = greenCode.kernel:NewLibrary( "Command" );

function greenCode.command:Add( sName, nAdminRight, callback )
	local prefix = SERVER and "" or "cl_";

	concommand.Add( prefix.."gc_"..sName, function( player, command, args ) 
		if ( nAdminRight > 0 ) then
			if ( player:EntIndex() != 0 and !player:HasAdminRight( nAdminRight > 1 ) ) then
				return;
			end;
		end;

		callback( player, command, args );
	end);
end;

--[[
	EXAMPLE:

	greenCode.command:Add( "test", 2, function( player, command, args )
		print( "test work" );
	end)

--]]