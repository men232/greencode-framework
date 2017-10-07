--[[
	© 2013 GmodLive private project do not share
	without permission of its author (Andrew Mensky vk.com/men232).
--]]

if SERVER then
	AddCSLuaFile();
	AddCSLuaFile( "greencode/sh_boot.lua" );
end;

function _gc_init()
	greenCode = GM or gmod.GetGamemode() or {};
	gCode     = greenCode;
	gC        = greenCode;
	gc        = greenCode
	
	include("greencode/sh_boot.lua");
end;

hook.Add( "Initialize", "greenCode.initialize", _gc_init );