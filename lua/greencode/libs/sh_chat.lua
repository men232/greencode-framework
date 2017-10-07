--[[
	© 2013 GmodLive private project do not share
	without permission of its author (Andrew Mensky vk.com/men232).
--]]

local greenCode = greenCode;

greenCode.chat = greenCode.kernel:NewLibrary("Chat");

local playerMeta = FindMetaTable("Player");

----------------------
-- Base Script code --
----------------------

if ( SERVER ) then
	chat = chat or {};
	chat.m_Command = {};
	chat.m_sCommandPrefix = "/";

	-- Stolen from ULX. thx --
	function SplitArguments( sMessage )
		sMessage = sMessage:Trim();
		local tArguments = {};
		local bCapture = false;
		local i = 1;
		local iLength = string.len( sMessage );
		while ( bCapture or i <= iLength ) do
			local iPosition = string.find( sMessage, " ", i, true );
			local sPrefix = string.sub( sMessage, i, ( iPosition or 0 ) - 1 );
			if ( !bCapture ) then
				local sTrimmed = string.Trim( sPrefix );
				if ( sTrimmed ~= "" ) then
					table.Add( tArguments, string.Explode( "%s+", sTrimmed ) );
				end
			else
				table.insert( tArguments, sPrefix );
			end
			if ( iPosition ~= nil ) then
				i = iPosition + 1;
				bCapture = !bCapture;
			else
				break;
			end
		end
		return tArguments;
	end

	function chat.CommandExists( sCommand )
		return chat.m_Command[ string.lower( sCommand ) ] ~= nil;
	end

	function chat.AddCommand( sCommand, fFunction )
		chat.m_Command[ string.lower( sCommand ) ] = fFunction;
	end

	function chat.CallCommand( Player, sMessage )
		if ( !IsValid( Player ) ) then
			console.Error( "Calling command", "Invalid Player!" );
			return;
		end
		local tArguments = SplitArguments( sMessage );
		local sCommand = tArguments[1];

		if ( getChatCommand and getChatCommand("/"..sCommand) ) then
			return "/"..sMessage;
		end;

		if ( !chat.CommandExists( sCommand ) ) then
			Player:Message( "The command '", sCommand, "' does not exist." );
			return;
		end
		table.remove( tArguments, 1 );
		chat.m_Command[ string.lower(sCommand) ]( Player, tArguments );
	end
	
	function greenCode.chat:PlayerSay( Player, sMessage, bTeam )
		if ( string.StartWith( sMessage, chat.m_sCommandPrefix ) ) then
			return chat.CallCommand( Player, string.sub( sMessage, 2 ) ) or "";
		end
	end;

	util.AddNetworkString( "Chat.Message" );

	function playerMeta:Message( ... )
		net.Start( "Chat.Message" );
			net.WriteTable( { n = select("#", ...), ... } );
		net.Send( self );
	end

	function chat.Area( vPos, fRadius, ... )
		for k, v in pairs( player.GetAll() ) do
			if ( vPos:Distance( v:GetPos() ) <= fRadius ) then
				v:Message( ... );
			end
		end
	end

	function chat.Broadcast( ... )
		net.Start( "Chat.Message" );
			net.WriteTable( { n = select("#", ...), ... } );
		net.Broadcast();
	end
end

if ( CLIENT ) then
	net.Receive( "Chat.Message", function( iLen )
		chat.AddText( Color( 225, 255, 225, 235 ), unpack( net.ReadTable() ) );
	end );
end

----------------------
-- ColChat by Cubie --
----------------------

if SERVER then
		util.AddNetworkString("ColChat");
		
        function playerMeta:ColChat(nam,col,msg)
			local data = { nam, Vector(col.r,col.g,col.b), msg };
			net.Start("ColChat");
				net.WriteTable(data);
			net.Send(self);
        end
       
else	
		-- ColChat by Cubie(modify)
		net.Receive("ColChat", function(len)
			local Data = net.ReadTable();
			local nam = Data[1];
			local vcol = Data[2];
			local col = Color(vcol.x,vcol.y,vcol.z);
			local msg = Data[3];
		   
			chat.AddText(unpack({col,"[" .. nam .. "] ",Color(255,255,255),msg}));
			chat.PlaySound();
		end)      
end


if SERVER then
	-- greenCode Resive.
	function gCode.chat:CommandExists( sCommand ) return chat.CommandExists( sCommand ) end;
	function gCode.chat:AddCommand( sCommand, fFunction ) chat.AddCommand( sCommand, fFunction ) end;
	function gCode.chat:CallCommand( Player, sMessage ) chat.CallCommand( Player, sMessage ) end;
	function gCode.chat:Area( vPos, fRadius, ... )  chat.Area( vPos, fRadius, ... ) end;
	function gCode.chat:Broadcast(...) chat.Broadcast( ... ) end;

	gCode.chat:AddCommand( "gcversion", function( player, sMessage )
		player:Message( "greenCode Kernel Version: "..greenCode:GetKernelVersion() );
	end);
end;