--[[
	© 2013 GmodLive private project do not share
	without permission of its author (Andrew Mensky vk.com/men232).
--]]

local greenCode = greenCode;
local net = net;
local pairs = pairs;
local pcall = pcall;
local type = type;
local util = util;

greenCode.datastream = greenCode.datastream or greenCode.kernel:NewLibrary("Datastream");
greenCode.datastream.stored = greenCode.datastream.stored or {};

function greenCode.datastream:Hook( name, Callback )
	self.stored[ name ] = Callback;
end;

if SERVER then
	util.AddNetworkString("gcDataDS");
end;
	
function greenCode.datastream:Start( recipients, name, tData )
	if ( tData == nil ) then tData = { 0 }; end;
	if ( type(tData) != "table" ) then tData = { d = {} } end;
	
	local serializeData = gc.kernel:Serialize( tData );
	local encodedData = util.Compress( serializeData );
	
	//print(name, "=============================")
	//print(serializeData, encodedData)
	//print("=============================")

	if ( encodedData and #encodedData > 0 and recipients ) then
		net.Start("gcDataDS");
			net.WriteString( name );
			net.WriteUInt( #encodedData, 32 );
			net.WriteData( encodedData, #encodedData );
		if ( SERVER and recipients == true ) then
			net.Broadcast();
		else
			net.Send(recipients);
		end;
	end;
end;

net.Receive( "gcDataDS", function( length, player )
	local dsName = net.ReadString();
	local dsLenght = net.ReadUInt( 32 );
	local dsData = net.ReadData( dsLenght );

	if ( dsName and dsLenght and dsData ) then
		dsData = util.Decompress( dsData );

		if ( !dsData ) then
			gc:Error( "Green Code", "The datastream failed to decompress!" );
			return;
		end;
		
		if ( gc.datastream.stored[ dsName ] ) then
			local bSuccess, value = pcall( gc.kernel.Deserialize, gc.kernel, dsData );

			if (bSuccess) then
				gc.datastream.stored[ dsName ]( SERVER and player or value, value );
			elseif (value != nil) then
				gc:Error( "Green Code", "The '"..dsName.."' datastream has failed to run.\n"..value );
			end;
		end;
	end;
end);