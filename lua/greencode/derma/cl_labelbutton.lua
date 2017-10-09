--[[
	© 2013 GmodLive private project do not share
	without permission of its author (Andrew Mensky vk.com/men232)., stole from clockwork.
--]]

local PANEL = {};

function PANEL:SetDisabled(disabled) self.Disabled = disabled; end;
function PANEL:GetDisabled() return self.Disabled; end;
function PANEL:SetDepressed(depressed) self.Depressed = depressed; end;
function PANEL:GetDepressed() return self.Depressed; end;
function PANEL:SetHovered(hovered) self.Hovered = hovered; end;
function PANEL:GetHovered() return self.Hovered; end;

-- Called when the cursor has entered the panel.
function PANEL:OnCursorEntered()
	if (!self:GetDisabled()) then
		self:SetHovered(true);
	end;
	
	DLabel.ApplySchemeSettings(self);
	surface.PlaySound("ui/buttonrollover.wav");
end;

-- Called when the cursor has exited the panel.
function PANEL:OnCursorExited()
	self:SetHovered(false);
	DLabel.ApplySchemeSettings(self);
	surface.PlaySound("ui/buttonrollover.wav");
end;

-- Called when the mouse is pressed.
function PANEL:OnMousePressed(code)
	self:MouseCapture(true);
	self:SetDepressed(true);
end;

-- Called when the mouse is released.
function PANEL:OnMouseReleased(code)
	self:MouseCapture(false);
	
	if (!self:GetDepressed()) then
		return;
	end;
	
	self:SetDepressed(false);
	
	if (!self:GetHovered()) then
		return;
	end;
	
	if (code == MOUSE_LEFT and self.DoClick
	and !self:GetDisabled()) then
		self.DoClick(self);
	end;
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

-- A function to override the text color.
function PANEL:OverrideTextColor(color)
	if (color) then
		self.OverrideColorNormal = color;
		self.OverrideColorHover = Color(math.max(color.r - 50, 0), math.max(color.g - 50, 0), math.max(color.b - 50, 0), color.a);
	else
		self.OverrideColorNormal = nil;
		self.OverrideColorHover = nil;
	end;
end;

function PANEL:Paint(w, h) end;

local function Step( nVal1, nVal2, speed )
	if ( nVal1 != nVal2 ) then
		return nVal1 < nVal2 and math.Clamp(nVal1 + speed, nVal1, nVal2) or math.Clamp(nVal1 - speed, nVal2, nVal1);
	else
		return nVal1;
	end;
end;

-- Called every frame.
function PANEL:Think()
	if (self.animation) then
		self.animation:Run();
	end;
	
	local colorWhite = Color(255, 255, 255, 255);
	local colorDisabled = Color(
		math.max(colorWhite.r - 50, 0),
		math.max(colorWhite.g - 50, 0),
		math.max(colorWhite.b - 50, 0),
		255
	);
	local colorInfo = Color(100, 255, 255, 255);

	if (self:GetDisabled()) then
		self.difColor = self.OverrideColorHover or colorDisabled;
	elseif (self:GetHovered()) then
		self.difColor = self.OverrideColorHover or colorInfo;
	else
		self.difColor = self.OverrideColorNormal or colorWhite;
	end;

	if ( !self.curColor ) then
		self.curColor = self.difColor;
	end

	self.curColor = Color(
		Step( self.curColor.r, self.difColor.r, 3 ),
		Step( self.curColor.g, self.difColor.g, 3 ),
		Step( self.curColor.b, self.difColor.b, 3 )
	)

	self:SetTextColor(self.curColor);
	
	self:SetExpensiveShadow(1, Color(0, 0, 0, 150));
end;

-- A function to set the panel's Callback.
function PANEL:SetCallback(Callback)
	self.DoClick = function(button)
		surface.PlaySound("ui/buttonclick.wav");
		Callback(button);
	end;
end;

vgui.Register("gcLabelButton", PANEL, "DLabel");