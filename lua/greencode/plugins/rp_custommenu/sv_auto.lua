--[[
	© 2013 GmodLive private project do not share
	without permission of its author (Andrew Mensky vk.com/men232).
--]]

local PLUGIN = PLUGIN or greenCode.plugin:Loader();

greenCode:IncludeDirectory( PLUGIN:GetBaseDir().. "/templates/", false );
greenCode:IncludeDirectory( PLUGIN:GetBaseDir().. "/category/", false );