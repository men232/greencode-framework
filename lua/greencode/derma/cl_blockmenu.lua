--[[
	© 2013 GmodLive private project do not share
	without permission of its author (Andrew Mensky vk.com/men232).
--]]

local math = math;
local draw = draw;
local gui = gui;
local surface = surface;

local function Step( nVal1, nVal2, speed )
	return math.Approach( nVal1, nVal2, speed );
end;

local PANEL = {};

function PANEL:Init()
	local scrH = ScrH();
	local scrW = ScrW();
	local x = (scrW*0.6);
	local xLayout = 405 + x;
	local dif = scrW - xLayout;
	local x = dif < 0 and x + dif or x;

	self.Initialized = false;
	self.AlphaMax = 200;
	self.Color = Color(0,0,0);
	self.Padding = 10;
	self:SetPos( x, -2 );
	self:SetSize( 400, scrH+2 );
	//self:SetPos( 360, 10 );
	//self:SetSize( scrW-370, scrH-20 );
	gui.EnableScreenClicker(true);

	self.ScrollSize = 0;
	self.Scroll = 0;

	self.Items = {};
	self:Rebuild();

	self:SetAlpha(0);
	self:FadeIn(0.4, function()
		self.Initialized = true;
	end);

	self.RecomendSize = {};

	for i=1, self:GetWide() - self.Padding * 2 do
		if ( i > self.Padding and ( self:GetWide() - self.Padding )%i == 0 ) then
			table.insert(self.RecomendSize, i-self.Padding);
		end;
	end

	local idSize = 4;
	self.ItemW = 85//self.RecomendSize[math.Clamp(idSize, 1, #self.RecomendSize)];//self:GetWide()-(self.Padding*2);
	self.ItemH = 85//self.RecomendSize[math.Clamp(idSize, 1, #self.RecomendSize)];
end;

function PANEL:SetPadding( n )
	self.Padding = n;
	self:Rebuild();
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

function PANEL:Think()
	if (self.animation) then
		self.animation:Run();
	end;

	if ( !self.Initialized ) then
		return;
	end;

	local cutTime = CurTime();
	local frameTime = FrameTime();
	local Scroll = math.Round(self.Scroll);
	local bShouldRebuild = false;

	for i=1, #self.Items do
		local BLOCK = self.Items[i];
		if ( !BLOCK or !ValidPanel(BLOCK) or !BLOCK.Active ) then continue end;

		local x, y = BLOCK:GetPos();
		local w, h = BLOCK:GetSize();

		if ( w != BLOCK.idealW or h != BLOCK.idealH ) then
			BLOCK:SetSize( Step( w, BLOCK.idealW, 5 ), Step( h, BLOCK.idealH, 5 ) );
			bShouldRebuild = true;
		end;

		local idealX = BLOCK.idealX;
		local idealY = BLOCK.idealY + -Scroll;

		if ( x == idealX and y == idealY ) then
			BLOCK.velocityY = 0;
			BLOCK.velocityX = 0;
			continue;
		end;
		
		local fSpeed = math.Clamp(frameTime * 20, 0, 0.30);
			local vY = math.ceil(BLOCK.velocityY * fSpeed);
			local vX = math.ceil(BLOCK.velocityX * fSpeed);
			y = y + (vY > 0 and math.max(vY, 1) or math.min(vY, -1));
			x = x + (vX > 0 and math.max(vX, 1) or math.min(vX, -1));
		local distanceY = idealY - y;
		local distanceX = idealX - x;

		BLOCK.velocityY = BLOCK.velocityY * (0.6 - frameTime) + (distanceY * fSpeed * 1);
		BLOCK.velocityX = BLOCK.velocityX * (0.6 - frameTime) + (distanceX * fSpeed * 1);

		if (math.abs(distanceY) < 2 and math.abs(BLOCK.velocityY) < 5) then
			y = idealY;
			BLOCK.velocityY = 0;
		end;
		
		if (math.abs(distanceX) < 2 and math.abs(BLOCK.velocityX) < 5) then
			x = idealX;
			BLOCK.velocityX = 0;
		end;

		BLOCK:SetPos( x, y );
	end;

	if ( bShouldRebuild ) then
		self:Rebuild();
	end;
end;

function PANEL:Paint( w, h )
	local a = math.Clamp(self:GetAlpha(), 0, self.AlphaMax);
	local c = self.Color;

	draw.RoundedBox( 0, 0, 0, w, h, Color(c.r, c.g, c.b, a) );
	surface.DrawOutlinedRect( 0, 0, w, h );
end;

function PANEL:PerformLayout()
	for i = 1, #self.Items do
		if (!ValidPanel(self.Items[i])) then 
			self.Items[i] = nil;
			self.Items = table.ClearKeys(self.Items);
			continue;
		end;
	end;
end;

function PANEL:Rebuild()
	//self.MaxPreLine = math.floor((self:GetWide()-self.Padding)/(self.ItemW+self.Padding));

	local startX = self.Padding;
	local startY = self.Padding + 2;
	local lineMaxH = 0;

	for i=1, #self.Items do
		local BLOCK = self.Items[i];
		if ( !BLOCK or !ValidPanel(BLOCK) ) then continue end;

		BLOCK.idealX = startX;
		BLOCK.idealY = startY;
		lineMaxH = math.max( BLOCK:GetTall(), lineMaxH );

		startX = startX + self.Padding + BLOCK:GetWide();

		if ( (startX + self.Padding + (self.Items[i+1] and self.Items[i+1]:GetWide() or 0)) > self:GetWide() ) then
			startX = self.Padding;
			startY = startY + self.Padding + lineMaxH;
			self.ScrollSize = startY;
			lineMaxH = 0;
		end;
	end;
end;

function PANEL:OnMouseWheeled(delta)
	local scroll = math.Max(self.Scroll - delta * math.min(FrameTime() * 4000, 36), 0);
	scroll = math.Min(scroll, math.Max(self.ScrollSize-(ScrH()-100), 10));
	self.Scroll = scroll;
	self:InvalidateLayout();
end;

function PANEL:AddItem( t )
	local t = t or {};
	local BLOCK = vgui.Create("DFrame", self);
	BLOCK.Initialized = false;
	BLOCK:SetTitle("");
	BLOCK:ShowCloseButton(false);

	BLOCK.curColor = Color(0,0,0,0);
	BLOCK.Color = Color(0,0,0,0);
	BLOCK.velocityX = -5;
	BLOCK.velocityY = 0;

	BLOCK:SetAlpha(0);
	BLOCK:SetSize( t.w or self.ItemW, t.h or self.ItemH );

	BLOCK.turnOffW, BLOCK.turnOffH = BLOCK:GetSize();
	BLOCK.turnOnW, BLOCK.turnOnH = t.turnOnW or BLOCK.turnOffW, t.turnOnH or BLOCK.turnOffH;

	function BLOCK:SetColor( c )
		self.OverrideColorHover = Color( c.r, c.g, c.b, 200 );
		self.OverrideColorNormal = Color( c.r, c.g, c.b, 150 );
		self.OverrideColorClicked = Color( c.r, c.g, c.b, 235 );
		self.OverrideColorDisabled = Color( 200, 200, 200, 200 );
	end;

	local color = t.color or Color(200,200,200,0) //Color(math.random(0,255), math.random(0,255), math.random(0,255), 0);
	BLOCK:SetColor( color );

	-- A function to make the panel fade out.
	function BLOCK:FadeOut(speed, Callback)
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
	function BLOCK:FadeIn(speed, Callback)
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

	function BLOCK:Paint( w, h )
		local a = !self.Initialized and math.Clamp(self:GetAlpha(), 0, 150) or self.curColor.a;
		local c = self.curColor;

		draw.RoundedBox( 0, 0, 0, w, h, Color(c.r, c.g, c.b, a) );
		surface.DrawOutlinedRect( 0, 0, w, h );
	end;

	BLOCK.Think = function()
		if ( !self.Initialized ) then
			return;
		end;

		if (BLOCK.animation) then
			BLOCK.animation:Run();
		end;
		
		if (BLOCK:GetDisabled()) then
			BLOCK.Color = BLOCK.OverrideColorNormal//BLOCK.OverrideColorDisabled;
		elseif(BLOCK:GetDepressed()) then
			BLOCK.Color = BLOCK.OverrideColorClicked;
		elseif (BLOCK:GetHovered()) then
			BLOCK.Color = BLOCK.OverrideColorHover;
		else
			BLOCK.Color = BLOCK.OverrideColorNormal;
		end;
		
		BLOCK:SetExpensiveShadow(1, Color(0, 0, 0, 150));

		BLOCK.curColor = Color(
			Step( BLOCK.curColor.r, BLOCK.Color.r, 3 ),
			Step( BLOCK.curColor.g, BLOCK.Color.g, 3 ),
			Step( BLOCK.curColor.b, BLOCK.Color.b, 3 ),
			Step( BLOCK.curColor.a, BLOCK.Color.a, 3 )
		);
	end;

	function BLOCK:OnCursorEntered()
		if (!self:GetDisabled()) then
			self:SetHovered(true);
		end;
	end;
	function BLOCK:OnCursorExited()
		self:SetHovered(false);
	end;
	function BLOCK:OnMousePressed(code)
		self:MouseCapture(true);
		self:SetDepressed(true);
	end;
	function BLOCK:OnMouseReleased(code)
		self:MouseCapture(false);
		
		if (!self:GetDepressed()) then
			return;
		end;
		
		self:SetDepressed(false);
		
		if (!self:GetHovered()) then
			return;
		end;
		
		if ( !self:GetDisabled() ) then
			if (code == MOUSE_LEFT and self.DoClick) then
				self.DoClick(self);
			elseif (code == MOUSE_RIGHT and self.DoClick2) then
				self.DoClick2(self);
			end;
		end;
	end;

	if ( t.callback ) then
		BLOCK:SetCursor("hand");
		
		BLOCK.DoClick = function()
			t.callback(BLOCK);
		end;
	end;

	if ( t.callback2 ) then		
		BLOCK.DoClick2 = function()
			t.callback2(BLOCK);
		end;
	end;

	function BLOCK:SetDisabled(disabled) self.Disabled = disabled; end;
	function BLOCK:GetDisabled() return self.Disabled; end;
	function BLOCK:SetDepressed(depressed) self.Depressed = depressed; end;
	function BLOCK:GetDepressed() return self.Depressed; end;
	function BLOCK:SetHovered(hovered) self.Hovered = hovered; end;
	function BLOCK:GetHovered() return self.Hovered; end;

	function BLOCK:TurnOn()
		self.deployed = true;
		self.idealW = self.turnOnW;
		self.idealH = self.turnOnH;
	end;

	function BLOCK:TurnOff()
		self.deployed = false;
		self.idealW = BLOCK.turnOffW;
		self.idealH = BLOCK.turnOffH;
	end;

	function BLOCK:TurnToogle()
		if ( self.deployed ) then
			self:TurnOff();
		else
			self:TurnOn();
		end
	end;

	function BLOCK:AnimRemove( nSpeed )
		if ( self.Initialized and nSpeed ) then
			self:FadeOut(0.2, function()
				self:Remove();
			end);
		else
			self:Remove();
		end;
	end;

	table.insert( self.Items, BLOCK );

	BLOCK.idealX = -BLOCK:GetWide();
	BLOCK.idealY = -BLOCK:GetTall();
	BLOCK.idealW, BLOCK.idealH = BLOCK:GetSize();

	timer.Simple( #self.Items*0.05, function()
		if ( BLOCK and ValidPanel(BLOCK) ) then
			BLOCK.Active = true;

			BLOCK:FadeIn(0.2, function()
				BLOCK.Initialized = true;
				BLOCK.curColor.a = math.Clamp(BLOCK:GetAlpha(), 0, 150);
			end);
		end;
	end)

	self:Rebuild();

	return BLOCK;
end;

function PANEL:RemoveItem( id, nRemoveAnimSpeed )
	if ( type(id) != "number" ) then
		for i=1, #self.Items do
			if ( id == self.Items[i] ) then
				id = i;
				break;
			end;
		end;
	end;

	if ( type(id) == "number" and self.Items[ id ] ) then
		self.Items[ id ]:AnimRemove( nRemoveAnimSpeed );
		self.Items[ id ] = nil;
		self.Items = table.ClearKeys(self.Items);
		self:Rebuild();
	end;
end;

function PANEL:Clear( nSpeed, callback )
	for i=1, #self.Items do
		local BLOCK = self.Items[i];
		if ( BLOCK ) then
			BLOCK:AnimRemove(nSpeed or 0.4);
		end;

		self.Items[ i ] = nil;
	end;

	self.Items = table.ClearKeys(self.Items);
	self:Rebuild();
	self.ScrollSize = 0;
	self.Scroll = 0;

	if ( callback ) then
		timer.Simple(nSpeed or 0.4, function() callback(); end);
	end;
end;

function PANEL:Close()
	gui.EnableScreenClicker(false);

	self:FadeOut(0.2, function()
		self:Remove();
	end);
end;

vgui.Register( "gcBlockMenu", PANEL, "Panel" );