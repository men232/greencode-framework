--[[
	© 2013 GmodLive private project do not share
	without permission of its author (Andrew Mensky vk.com/men232).
--]]

CM_SIMPLE2_TMPL = CM_TMPL_CLASS:New{ 
	name = "simple2",
	callback = function( BLOCK, t )
		BLOCK:SetTooltip(t.tooltip or false);
		BLOCK.Title = vgui.Create( "DLabel", BLOCK);
		BLOCK.Title:SetText( t.title or "#Title" );
		BLOCK.Title:SetFont("ChatFont");
		BLOCK.Title:SetColor( t.color or Color(0,255,0) );
		BLOCK.Title:SizeToContents();
		BLOCK.Title:SetExpensiveShadow(2, Color(0,0,0,100));
		BLOCK.Title:Center();
		return true;
	end
}:Register();