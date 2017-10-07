--[[
	© 2013 GmodLive private project do not share
	without permission of its author (Andrew Mensky vk.com/men232).
--]]

local PANEL = {};

function PANEL:Init()
	self:MakePopup();
	self:SetPos( 0, 0 );
	self:SetSize( ScrW(), ScrH() );
	self:SetAlpha( 200 );
	self.items = {};

	self:FadeIn( 0.3, function( panel )
		for k, v in pairs( self.items ) do
			v:FadeIn( 1 );
		end;

		self.loaded = true;
	end);
end;

-- A function to make the panel fade out.
function PANEL:FadeOut(speed, Callback)
	self.animation = Derma_Anim("Fade Panel", self, function(panel, animation, delta, data)
		panel:SetAlpha(255 - (delta * 255));
		
		if (animation.Finished) then
			panel:SetVisible(false);
				if (Callback) then
					Callback();
				end;
			self.animation = nil;
		end;
	end);
	
	if (self.animation) then
		self.animation:Start(speed);
	end;
end;

-- A function to make the panel fade in.
function PANEL:FadeIn(speed, Callback)
	self.animation = Derma_Anim("Fade Panel", self, function(panel, animation, delta, data)
		panel:SetAlpha(delta * 255);
		
		if (animation.Finished) then
			if (Callback) then
				Callback();
			end;
			
			self.animation = nil;
		end;
	end);
	
	if (self.animation) then
		self.animation:Start(speed);
	end;

	self:SetVisible(true);
end;

-- Called every frame.
function PANEL:Think()
	if (self.animation) then
		self.animation:Run();
	end;
end;

local Mat = Material("gui/gradient");

function PANEL:Paint( w, h )
	local nAlpha = math.Clamp( self:GetAlpha(), 0, 150 );
	local cColor = Color(0,0,0,nAlpha);

	surface.SetDrawColor( 0, 0, 0, 255 ) 
	surface.SetMaterial( Mat )
	surface.DrawTexturedRect( 0, 0, self:GetWide()*0.56, self:GetTall() );
end;

function PANEL:AddItem( t )
	if ( type( t ) == "table" ) then
		local item = vgui.Create( "gcLabelButton", self );
		item:SetText( t.title );

		if ( t.fadein or self.loaded ) then
			item:FadeIn( t.fadein or 0.25 );
		else
			item:SetAlpha( 0 );
		end;

		if ( t.callback ) then
			item:SetCallback( t.callback );
		end;

		item:SetFont("gcIntroTextBig");
		item:SizeToContents();
		item:SetMouseInputEnabled(true);

		table.insert( self.items, item );

		self:Rebuild();

		return item;
	end;
end;

function PANEL:Rebuild()
	for k, v in pairs( self.items ) do
		v:Center();
		local x, y = v:GetPos();
		v:SetPos( 75, 25 + (65 * k) );
	end;
end;

function PANEL:Close()
	self:FadeOut( 0.25, function()
		self:Remove();
	end );

	for k, v in pairs( self.items ) do
		v:SetDisabled( true );
	end;
end;

function PANEL:Clean()
	for k, v in pairs( self.items ) do
		v:FadeOut( 0.25, function() v:Remove() end );
		v:SetDisabled( true );
	end;
end;

vgui.Register( "gcTextMenu", PANEL, "EditablePanel" );