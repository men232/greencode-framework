--[[
	© 2013 GmodLive private project do not share
	without permission of its author (Andrew Mensky vk.com/men232).
--]]

CM_SIMPLE_TMPL = CM_TMPL_CLASS:New{ 
	name = "simple",
	callback = function( BLOCK, t )
		BLOCK:SetTooltip(t.tooltip or false);
		BLOCK.Title = xlib.makelabel{ parent = BLOCK, x = 60, y = 8, label = t.title or "#Title", font = "Trebuchet22", textcolor = t.color or Color(0,255,0) } //vgui.Create( "DLabel", BLOCK);
		BLOCK.Title:SetExpensiveShadow(2, Color(0,0,0,255));
		
		if ( t.desc ) then
			t.desc = string.Replace(t.desc, "\\n", "\n");
		end;
		BLOCK.Desc = xlib.makelabel{ parent = BLOCK, x = 80, y = 33, label = t.desc or "#Desc", textcolor = Color(255,255,255) }
		BLOCK.Desc:SetExpensiveShadow(2, Color(0,0,0,255));
		
		if ( t.mdl ) then
			BLOCK.Icon = vgui.Create("SpawnIcon", BLOCK);
			BLOCK.Icon:SetSize(50, 50);
			BLOCK.Icon:SetPos(10, 10);
			BLOCK.Icon:SetModel(Model(t.mdl));
			
			BLOCK.Icon.PaintOver = function() return false; end;
			BLOCK.Icon.OnCursorEntered = function(...) BLOCK:OnCursorEntered(...); return true; end;
			BLOCK.Icon.OnCursorExited = function(...) BLOCK:OnCursorExited(...); return true; end;
			BLOCK.Icon.OnMouseReleased = function(...) BLOCK:OnMouseReleased(...); return true; end;
			BLOCK.Icon.OnMousePressed = function(...) BLOCK:OnMousePressed(...); return true; end;
			BLOCK.Icon:SetToolTip(t.title or "#Title");
		else
			BLOCK.Title:SetPos(10,8);
			BLOCK.Desc:SetPos(10,33);
		end;
		
		if ( t.turn or t.clk2 ) then			
			BLOCK.mBox = vgui.Create("Panel", BLOCK);
			BLOCK.mBox:SetSize(10, 10);
			local c = t.turn and Color(45,255,255) or Color(45,255,45);
			
			function BLOCK.mBox:Paint()
				draw.RoundedBox(0, 0, 0, self:GetWide(), self:GetTall(), Color(c.r,c.g,c.b,a));
				surface.SetDrawColor( Color(0,0,0,a));
				self:DrawOutlinedRect();
			end;
			
			function BLOCK.mBox:Think() self:SetPos(BLOCK:GetWide()-15, 5); end;
		end;
		
		BLOCK.turnOnH = BLOCK.Desc:GetTall() + 40;
		
		return true;
	end
}:Register();