--[[
	© 2013 GmodLive private project do not share
	without permission of its author (Andrew Mensky vk.com/men232).
--]]

local greenCode = greenCode;
local Color = Color;
local table = table;
local MsgN = MsgN;
local MsgC = MsgC;

greenCode.console = {};

local function GetColor()
	return SERVER and Color( 0, 195, 255 ) or Color( 255, 195, 0 );
end;

function greenCode.console:MsgN( sCause, ... )
	local cMessageColor = GetColor();

	MsgC( cMessageColor, "[".. (sCause or "Green Code").."] " );

	table.ForEach( {...}, function( k, v )
		MsgC( cMessageColor, v );
	end );

	MsgN();
end;

function greenCode.console:Error( sCause, sError )
	MsgC( Color( 255, 0, 0 ), "[", sCause, "] ");
	MsgC( Color( 220, 20, 20 ), sError, "\n" );
end;

function greenCode.console:Success( sCause, sText )
	MsgC( Color( 20, 255, 20 ), "[", sCause, "] " );
	MsgC( Color( 20, 200, 20 ), sText, "\n" );
end;

function greenCode.console:MsgC( sCause, sText, cColor )
	MsgC( cColor or Color( 20, 255, 20 ), "[", sCause, "] " );
	MsgC( cColor, sText, "\n" );
end;

function greenCode.console:Debug( ... )
	if greenCode:IsDebug() then
		local cMessageColor = GetColor();

		MsgC( Color( 255, 20, 255 ), "[GC DEBUG]:\n" );
		
		table.ForEach( {...}, function( k, v )
			MsgC( cMessageColor, "\t", v, "\n" );
		end);
	end;
end;

function greenCode:MsgN( ... )		self.console:MsgN( ... ); 		end;
function greenCode:Error( ... )		self.console:Error( ... ); 		end;
function greenCode:Success( ... )	self.console:Success( ... ); 	end;
function greenCode:MsgC( ... )		self.console:MsgC( ... ); 		end;
function greenCode:Debug( ... )		self.console:Debug( ... ); 		end;