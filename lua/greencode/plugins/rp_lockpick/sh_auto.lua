--[[
	© 2013 GmodLive private project do not share
	without permission of its author (Andrew Mensky vk.com/men232).
--]]
local PLUGIN = PLUGIN or greenCode.plugin:Loader();

local greenCode = greenCode;
local gc = gc;
local surface = surface;
local math = math;

LOCKPICK_PIN_COUNT = 0;

if CLIENT then

	function PLUGIN:IsOpen() return ValidPanel(self.panel) end;

	local BackGround = Material("greencode/lockpick/back.png");
	local LockPick = Material("greencode/lockpick/pick.png");
	local Top = Material("greencode/lockpick/top.png");
	local Pin = Material("greencode/lockpick/pin.png");
	local Right = Material("greencode/lockpick/right.png");
	local Wrong = Material("greencode/lockpick/wrong.png");
	local Cracked = Material("greencode/lockpick/cracked.png");

	function PLUGIN:Open( Level )
		if ( self:IsOpen() ) then
			return;
		end;
		
		local PIN_ENUMS_PASS = { "sOkSfs8X2b", "ms3gU7aNYe", "3hky3LAtpa", "G9EhZNwE8s", "rUN7XWJr39", "rYm6HKnQGN" };
		LOCKPICK_PIN_COUNT = 0;
		
		Level = math.Clamp( Level or 0, 1, 6 );
			
		tLevelData = {
			[1] = { PinSpeed = 10, PinStep = 20, space = 25 },
			[2] = { PinSpeed = 20, PinStep = 15, space = 20 },
			[3] = { PinSpeed = 30, PinStep = 15, space = 15 },
			[4] = { PinSpeed = 40, PinStep = 10, space = 14 },
			[5] = { PinSpeed = 50, PinStep = 9, space = 12 },
			[6] = { PinSpeed = 50, PinStep = 8, space = 8 },
		};
		
		self.panel = xlib.makepanel{ w = 334*1.3, h = 304*1.3 };
		self.panel:Center();
		self.panel:MakePopup();
		
		local PLUGIN = self;
		local w, h = self.panel:GetSize();
		
		self.panel.data = {
			LPick = { x = -w+25, y = h*0.52 },
			PIN = {
				{ x = w*0.219 , y = h*0.165, w = w*0.06, h = math.ceil(h*0.315 + math.random(0, 35)) },
				{ x = w*0.334 , y = h*0.165, w = w*0.06, h = math.ceil(h*0.315 + math.random(0, 35)) },
				{ x = w*0.446 , y = h*0.165, w = w*0.06, h = math.ceil(h*0.315 + math.random(0, 35)) },
				{ x = w*0.559 , y = h*0.165, w = w*0.06, h = math.ceil(h*0.315 + math.random(0, 35)) },
				{ x = w*0.672 , y = h*0.165, w = w*0.06, h = math.ceil(h*0.315 + math.random(0, 35)) },
				{ x = w*0.787 , y = h*0.165, w = w*0.06, h = math.ceil(h*0.315 + math.random(0, 35)) }
			},
		};
		
		self.panel.prevX, self.panel.prevY = self.panel:CursorPos();
		
		local AddSpeedLockPick = gc.attributes:Fraction(ATB_BREAK, 175, 0);
		local AddSpace = gc.attributes:Fraction(ATB_BREAK, 10, 0);
		local AddStep = gc.attributes:Fraction(ATB_BREAK, 10, 0);
		
		local Amount = gc.attributes:Get(ATB_BREAK);
		local PinSpeed = tLevelData[Level].PinSpeed;
		local PinStep = tLevelData[Level].PinStep + AddStep;
		local Space = AddSpace + tLevelData[Level].space;
		local LockPickSpedd = 75;
		
		for i = 1, 6 do
			local t = self.panel.data.PIN[i];
			t.y = (h*0.52) - t.h;
			t.nH = t.h;
			t.nY = t.y;
			t.lock = true;
			t.maxY = (h*0.3) - t.h;
			t.dot = math.random(t.maxY+Space, (h*0.45) - t.h);
		end;
		
		local NormalLockPickY = self.panel.data.LPick.y;
		local ActiveLockPickY = self.panel.data.LPick.y - h*0.07;
		
		function self.panel:Nulled()
			for i = 1, 6 do
				local t = self.data.PIN[i];
				t.y = t.nY;
				t.lock = true;
				t.h = t.nH;
			end;
		end;
		
		function self.panel:IsUnderPin( x )
			local x = x + w;
			
			for i = 1, 6 do
				local t = self.data.PIN[i];
				
				if ( x >= t.x and x <= (t.x + t.w + 5) ) then
					return true, i;
				end;
			end;
		
			return false;
		end;
		
		function self.panel:IsRight( t, bOptim )
			local Space = Space/2;
			local Min = t.dot-Space;
			local Max = t.dot+Space;
			
			local bRight = !t.lock or t.y >= Min and t.y <= Max;
			
			if ( bOptim and !bRight ) then
				local dif1 = t.y - Min
				local dif2 = Max - t.y;
				bRight = dif1 >= -0.5 and dif2 >= -0.5;
			end;
			
			return bRight;
		end;
		
		function self.panel:GetMaterial( t )
			if ( !t.lock ) then
				return Cracked;
			elseif ( self:IsRight(t) ) then
				return Right;
			elseif t.y < (t.dot+(Space/2)) then
				return Wrong;
			else
				return Pin;
			end;
		end;
		
		function self.panel:Think()
			if ( !IsValid(gc.Client) or !gc.Client:Alive() ) then
				PLUGIN:Close();
			end;
			
			if ( !self.LastCmd ) then
				self.LastCmd = 0;
			end;
			
			local frameTime, curTime = FrameTime(), CurTime();
			local x, y = self:CursorPos();
			local t = self.data;
						
			local velocityX, velocityY = x - self.prevX, y - self.prevY;
			local bUnderPin, i = self:IsUnderPin( t.LPick.x );
			
			if ( bUnderPin and t.PIN[i].lock and t.LPick.y == NormalLockPickY and velocityY < -4 ) then
				t.PIN[i].y = math.Clamp( t.PIN[i].y - PinStep, t.PIN[i].maxY, t.PIN[i].nY );
				t.LPick.y = ActiveLockPickY;
				LockPickSpedd = 250;
				RunConsoleCommand("gc_lockpcik_action", "picking");
			else
				LockPickSpedd = 50 + AddSpeedLockPick;
			end;
			
			local lockNum = 0;
			for i = 1, 6 do
				local t = self.data.PIN[i];
				if ( !t.lock ) then lockNum = lockNum + 1; continue end;
				t.y = math.Approach( t.y, t.nY, frameTime*PinSpeed );
			end;
			
			LOCKPICK_PIN_COUNT = lockNum;
			
			if ( curTime > self.LastCmd ) then
				RunConsoleCommand("gc_lockpcik", PIN_ENUMS_PASS[LOCKPICK_PIN_COUNT] or "nil");
				self.LastCmd = curTime + 1;
			end;
			
			if ( t.LPick.y == NormalLockPickY ) then
				t.LPick.x = math.Clamp( x-w+10/*t.LPick.x + velocityX*/, -w+100, 0 );
			end;
			
			t.LPick.y = math.Approach( t.LPick.y, NormalLockPickY, frameTime * LockPickSpedd );
			
			self.prevX, self.prevY = x, y;
		end;
		
		function self.panel:Paint()
			local t = self.data;
					
			surface.SetDrawColor( 255, 255, 255, 255 );
			
			surface.SetMaterial( BackGround );
			surface.DrawTexturedRect( 0, 0, w, h );
					
			surface.SetMaterial( LockPick );
			surface.DrawTexturedRect( t.LPick.x, t.LPick.y, w-5, h/15 );
			
			surface.SetMaterial( self:GetMaterial(t.PIN[1]) );
			surface.DrawTexturedRect( t.PIN[1].x, t.PIN[1].y, t.PIN[1].w, t.PIN[1].h );
			
			surface.SetMaterial( self:GetMaterial(t.PIN[2]) );
			surface.DrawTexturedRect( t.PIN[2].x, t.PIN[2].y, t.PIN[2].w, t.PIN[2].h );
			
			surface.SetMaterial( self:GetMaterial(t.PIN[3]) );
			surface.DrawTexturedRect( t.PIN[3].x, t.PIN[3].y, t.PIN[3].w, t.PIN[3].h );
			
			surface.SetMaterial( self:GetMaterial(t.PIN[4]) );
			surface.DrawTexturedRect( t.PIN[4].x, t.PIN[4].y, t.PIN[4].w, t.PIN[4].h );
			
			surface.SetMaterial( self:GetMaterial(t.PIN[5]) );
			surface.DrawTexturedRect( t.PIN[5].x, t.PIN[5].y, t.PIN[5].w, t.PIN[5].h );
			
			surface.SetMaterial( self:GetMaterial(t.PIN[6]) );
			surface.DrawTexturedRect( t.PIN[6].x, t.PIN[6].y, t.PIN[6].w, t.PIN[6].h );
			
			surface.SetMaterial( Top );
			surface.DrawTexturedRect( 0, 0, w, h );
		end;
		
		self.panel.Title = xlib.makelabel{ parent = self.panel, x = w*0.195, y = h*0.04, label = "Уровень: "..Level.." | Навык: "..Amount, font = "Trebuchet24", textcolor = Color(255,255,200) };
		self.panel.Title:SetExpensiveShadow(2, Color(0,0,0,150));
		
		self.panel.btn = xlib.makebutton{ x = self.panel:GetWide() - 32, y = 0, w = 32, h = 32, btype="close", parent = self.panel};
		self.panel.btn.DoClick = function()
			self:Close();
		end;
		
		self.panel.OnMousePressed = function( _, code )
			self:GUIMousePressed(code);
		end;
	end;

	function PLUGIN:GUIMousePressed( code )
		if self:IsOpen() then
			if ( code == MOUSE_RIGHT ) then
				self:Close();
				return;
			end;
			
			local t = self.panel.data;
			
			local bUnderPin, i = self.panel:IsUnderPin( t.LPick.x );
			
			if ( bUnderPin and t.PIN[i].lock ) then		
				if self.panel:IsRight(t.PIN[i], true) then				
					t.PIN[i].h = self.panel:GetTall()*0.315;
					t.PIN[i].y = (self.panel:GetTall()*0.212);
					t.PIN[i].lock = false;
					RunConsoleCommand("gc_lockpcik_action", "break");
				elseif ( t.PIN[i].y != t.PIN[i].nY ) then
					self.panel:Nulled();
					RunConsoleCommand("gc_lockpcik_action", "fail");
				end;
			end;
		end;
	end;

	function PLUGIN:Close()
		if self:IsOpen() then
			self.panel:Remove();
			self.panel = nil;
			RunConsoleCommand("gc_lockpcik", 1, 1);
		end;
	end;
	
	greenCode.command:Add( "lockpick_menu", 0, function( player, command, args )
		if ( args[1] == "weitui789235kad" and args[2] ) then
			PLUGIN:Open( tonumber(args[2]) );
		else
			PLUGIN:Close();
		end;
	end);
	
else
	local entityMeta = FindMetaTable("Entity");
	
	function entityMeta:GetLockLevel() return math.Clamp(self.gcLockLevel or 1, 1, 6); end;
	
	function entityMeta:SetLockLevel( nLevel )
		if IsValid(self) and ( self:IsVehicle() or greenCode.entity:IsDoor(self) ) then
			self.gcLockLevel = math.Clamp( nLevel or 1, 1, 6 );
			PLUGIN:Save();
		end;
	end;
	
	function PLUGIN:PlayerCrackedDoor( player, door )
		player:ProgressAttribute( ATB_BREAK, 15 * door:GetLockLevel(), true );
	end;
	
	function PLUGIN:Save()
		local tSaveData = {};
		
		for k, v in pairs( _ents.GetAll() ) do
			if IsValid(v) and greenCode.entity:IsDoor(v) and v:GetLockLevel() > 1 then
				tSaveData[v:EntIndex()] = v:GetLockLevel();
			end;
		end;
		
		greenCode.kernel:SaveGameData( "lock/"..string.lower(game.GetMap()), tSaveData );
	end;
	
	function PLUGIN:Load()
		local tLockData = greenCode.kernel:RestoreGameData( "lock/"..string.lower(game.GetMap()), {} );
		
		for k, v in pairs( tLockData ) do
			local entity = Entity(k);
			
			if ( IsValid(entity) and greenCode.entity:IsDoor(entity) ) then
				entity:SetLockLevel(v);
			end;
		end;
	end;
	
	function PLUGIN:InitPostEntity()
		self:Load();
	end;
	
	greenCode.chat:AddCommand( "locklevel", function( player, sMessage )
		if ( player:IsSuperAdmin() and sMessage ) then
			local nLevel = tonumber(sMessage[1]);
			
			local tr = player:GetEyeTrace()
			
			if IsValid(tr.Entity) and greenCode.entity:IsDoor(tr.Entity) or tr.Entity.isFadingDoor and trace.Entity.fadeActivate then
				tr.Entity:SetLockLevel(nLevel);
				player:Message( tr.Entity:EntIndex().." ["..tr.Entity:GetClass().."] set locklevel = "..tr.Entity:GetLockLevel() );
			end;
		end;
	end);
	
	greenCode.command:Add( "lockpcik", 0, function( player, command, args )
		if ( #args < 1 ) then return end;
		player.BreakPinPass = args[1];
		
		if ( args[2] ) then
			player.BreakPinPass = -1;
		end;
	end);
	
	greenCode.command:Add( "lockpcik_action", 0, function( player, command, args )
		if ( #args < 1 ) then
			return;
		end;
		
		local nVolume = 80 * (1.3 - gc.attributes:Fraction( player, ATB_BREAK, 1, 0));
		
		if ( args[1] == "picking" ) then
			player:EmitSound("ambient/machines/keyboard"..math.random(1, 6).."_clicks.wav", nVolume, 100);
		elseif args[1] == "break" then
			player:EmitSound("ambient/machines/keyboard7_clicks_enter.wav",  nVolume, 100);
		elseif args[1] == "fail" then
			player:EmitSound("weapons/rpg/shotdown.wav", nVolume, 100);
		end;
	end);
end;