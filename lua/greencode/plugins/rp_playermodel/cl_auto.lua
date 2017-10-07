--[[
	© 2013 GmodLive private project do not share
	without permission of its author (Andrew Mensky vk.com/men232).
--]]
local PLUGIN = PLUGIN or greenCode.plugin:Loader();

local greenCode = greenCode;
local gc = gc;

-- Include models list.
greenCode:IncludePrefixed(PLUGIN:GetBaseDir().."/sh_model.lua");

function PLUGIN:ModelToInt( sModel, nSkin )
	for k, v in pairs( self.MaleModels ) do
		if( v.Model == sModel and table.HasValue( v.Skin, nSkin ) ) then
			return k;
		end
	end;
	
	for k, v in pairs( self.FemaleModels ) do
		if( v.Model == sModel and table.HasValue( v.Skin, nSkin ) ) then
			return k;
		end
	end;
end;

function PLUGIN:IsOpen() return ValidPanel(self.panel) end;

function PLUGIN:Close()
	if ( self:IsOpen() ) then
		self.panel:Remove();
		self.panel = nil;
	end;
end;

function PLUGIN:Open( sText, entity, bHide )
	if ( self:IsOpen() ) then
		self:Close();
	end;

	local scrW, scrH = ScrW(), ScrH();
	local w, h = 400, scrH*0.8;
	local sModel, nSkin = gc.Client:GetModel(), gc.Client:GetSkin();

	-- panel
	self.panel = xlib.makeframe{ w = w, h = h, label = "Выбор скина", showclose = true, draggable = true, nopopup = false };
	self.panel:SetSkin("DarkRP");

	local model = vgui.Create( "gcCharPanel", self.panel );
	model:SetModel( sModel );
	model:SetSkin( nSkin );
	model:SetPos(0, 25);
	model:SetSize( w, h*0.7 );
	model.Entity:SetAngles( Angle() );
	model:SetCamPos( Vector( 0, 50, 50 ) );
	model:SetLookAt( Vector( 0, 0, 40 ) );
	model:SetFOV( 65 );

	self.title = xlib.makelabel{x = 10, y = h*0.75, label = sText or [[Используйте стрелки, для переключения. Первый выбор за
	наш счет.

	В дальнейшем, если вы захотите изменить скин, найдите магазин.
	Внимание! После выбора пола и лица, их изменить нельзя!]], parent = self.panel, textcolor = Color(255,255,255)};
	self.title:SetExpensiveShadow(2, Color(0,0,0,100));

	local padding = 60;
	self.btn1 = xlib.makebutton{x = padding, y = 100, w = 35, h = 30, label = "<", parent = self.panel};
	self.btn2 = xlib.makebutton{x = w-30-padding, y = 100, w = 35, h = 30, label = ">", parent = self.panel};

	self.btn3 = xlib.makebutton{x = padding, y = 400, w = 75, h = 50, label = "<", parent = self.panel};
	self.btn4 = xlib.makebutton{x = w-50-padding, y = 400, w = 75, h = 50, label = ">", parent = self.panel};

	self.btn5 = xlib.makebutton{w = 250, h = 40, label = "Применить", parent = self.panel};
	self.btn5:Center();
	local x, y = self.btn5:GetPos();
	self.btn5:SetPos(x, h - 60);

	local nGender = greenCode.player:GetGender(LocalPlayer()) == "male" and 0 or 1;
	local tModelsList = nGender == 0 and self.MaleModels or self.FemaleModels;
	local ModelID = self:ModelToInt( sModel, nSkin );
	local SkinID = 1;

	if (!ModelID) then
		ModelID, SkinID = 1, 1;
	end;

	local function Update()	
		if (ModelID < 1) then
			ModelID = #tModelsList;
		elseif (ModelID > #tModelsList) then
			ModelID = 1;
		end;
		
		min = 1;
		max = #tModelsList[ModelID].Skin;
		
		if (SkinID < min) then
			SkinID = max;
		elseif (SkinID > max) then
			SkinID = min;
		end;
	end;

	function self.btn1:DoClick()
		ModelID = ModelID - 1;
		Update();
		
		model:SetModel(tModelsList[ModelID].Model);		
		model:SetSkin(tModelsList[ModelID].Skin[SkinID]);
	end;
	
	function self.btn2:DoClick()
		ModelID = ModelID + 1;
		Update();
		
		model:SetModel(tModelsList[ModelID].Model);		
		model:SetSkin(tModelsList[ModelID].Skin[SkinID]);
	end;

	function self.btn3:DoClick()
		SkinID = SkinID - 1;
		Update();
		
		model:SetSkin(tModelsList[ModelID].Skin[SkinID]);
	end;
	
	function self.btn4:DoClick()
		SkinID = SkinID + 1;
		Update();
		
		model:SetSkin(tModelsList[ModelID].Skin[SkinID]);
	end;

	function self.btn5:DoClick()
		self:SetDisabled(true);
		RunConsoleCommand("gc_changemodel", nGender, ModelID, tModelsList[ModelID].Skin[SkinID], IsValid(entity) and tostring(entity:EntIndex()));
	end;

	self.btn6 = xlib.makebutton{x = w - 130, y = 35, w = 120, h = 20, label = nGender == 0 and "Баба" or "Мужик", parent = self.panel};

	self.btn6.DoClick = function()
		if( nGender == 0 ) then 
			nGender = 1;
			tModelsList = self.FemaleModels;
			self.btn6:SetText("Мужик");
		else
			nGender = 0;
			tModelsList = self.MaleModels;
			self.btn6:SetText("Баба");
		end
		
		ModelID = 1;
		SkinID = 1;
		Update();
		
		model:SetModel(tModelsList[ModelID].Model);		
		model:SetSkin(tModelsList[ModelID].Skin[SkinID]);
	end;

	if (bHide) then
		self.btn1:SetVisible(false);
		self.btn2:SetVisible(false);
		self.btn6:SetVisible(false);
	end;
end;

local tTextSample = {
	[1] = [[Используйте стрелки, для переключения.

	Цена скина: %s

	Запас: %s]]
}

greenCode.datastream:Hook( "_RPModel", function( tData )
	local CMD = tData.cmd;
	local ENT = tData.ent;

	if ( CMD == 0 ) then
		PLUGIN:Close();
	elseif CMD == 1 then
		if ( PLUGIN:IsOpen() ) then
			PLUGIN.btn5:SetDisabled(false);
		end;
	else
		local text;
		if ( tTextSample[tData.text] and IsValid(ENT) ) then
			text = string.format( tTextSample[tData.text], ENT:Getprice()..GAMEMODE.Config.currency, ENT:GetCount() )
		end;

		PLUGIN:Open( text, ENT, tData.hide);
	end;
end);