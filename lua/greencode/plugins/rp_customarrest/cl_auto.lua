--[[
	© 2013 GmodLive private project do not share
	without permission of its author (Andrew Mensky vk.com/men232).
--]]

local greenCode = greenCode;
local table = table;
local math = math;

local PLUGIN = PLUGIN or greenCode.plugin:Loader();
PLUGIN.UI = PLUGIN.UI or {};
local playerMeta = FindMetaTable("Player");

local puSteamID = CreateClientConVar("pu_steamid", "", false, false );
local puTime = CreateClientConVar("pu_time", "", false, false );
local puReason = CreateClientConVar("pu_reason", "", false, false );
local ARREST_PERIOD = 0;

function playerMeta:_IsCArrested() return self:GetSharedVar("arrested", false); end;

function PLUGIN:IsOpen() return ValidPanel(self.UI.panel); end;

function PLUGIN:Refresh()
	if ( self:IsOpen() ) then
		local UI = self.UI;

		UI.lst1:Clear();
		UI.lst2:Clear();
		ARREST_PERIOD = 0;

		local ID1, ID2 = 1, 1;

		for k, v in pairs(_player.GetAll()) do
			if ( !IsValid(v) or !v:HasInitialized() ) then continue end;

			local bFullArrest = v:GetSharedVar("arrested", false);
			local tArrestData = v:GetSharedVar("arrestData", {});
			local dred = tArrestData.dred;
			local arrester = v:GetSharedVar("arrester", {});
			local bFullList = false;

			local lineObj;
			if ( v:isArrested() and !bFullArrest ) then
				lineObj = UI.lst1:AddLine( ID1, v:Name(), v:SteamID(), arrester.name and ( arrester.name .." ("..arrester.sid..")" ) or "Unknown" );
				ID1 = ID1 + 1;
			elseif (bFullArrest) then
				lineObj = UI.lst2:AddLine( ID2, v:Name(), v:SteamID(), dred.name and ( dred.name .." ("..dred.sid..")" ) or "Unknown", tArrestData.reason or "", "#Time");
				bFullList = true;
				ID2 = ID2 + 2;
			end;

			-- center align
			if ( lineObj ) then
				for k, col in pairs(lineObj.Columns) do
					col:SetContentAlignment(5);
				end;

				function lineObj:OnSelect()
					RunConsoleCommand("pu_steamid", self:GetValue(3));
					ARREST_PERIOD = math.ceil( (self.JailTime or 0)/60 );
				end;

				function lineObj:OnRightClick()
					local menu = DermaMenu();
					menu:AddOption("Скопировать информацию", function()
						local sData = "";

						for k, col in pairs(lineObj.Columns) do
							sData = sData.. ((bFullList and UI.lst2 or UI.lst1).Columns[k].Header:GetText()).." = "..col:GetValue().."\n";
						end;

						greenCode:SetClipboardText(sData);
					end);
					menu:AddOption("Отмена", function() end);
					menu:Open()
				end;

				if ( bFullList ) then
					function lineObj:Think()
						local curTime = CurTime();
						local nTime = 0;

						if ( tArrestData.time and tArrestData.time > curTime ) then
							nTime = math.ceil( tArrestData.time - curTime );
						end;

						self:SetValue( 6, greenCode.kernel:ConvertTime( nTime ) );
						self.JailTime = nTime;
					end;
				end;
			end;
		end;

		self:Clear();
	end;
end;

-- A function to anullation data.
function PLUGIN:Clear()
	local UI = self.UI;
	if ( IsValid(UI.edt1) ) then
		UI.edt1:SetValue("Причина");
		UI.edt2:SetValue(1);
	end;
	
	RunConsoleCommand("pu_steamid", "");
	RunConsoleCommand("pu_reason", "");
	RunConsoleCommand("pu_time", "");
end;

function PLUGIN:Open()
	if ( self:IsOpen() ) then
		self:Close();
	end;

	local scrW, scrH = ScrW(), ScrH();
	local w, h = scrW*0.8, scrH*0.8;
	local team = gc.Client:Team();
	local bCP = ( team == TEAM_POLICE or team == TEAM_CHIEF or team == TEAM_MAYOR );
	local bArrested = gc.Client:isArrested();

	local UI = self.UI; -- to save my finger.

	-- panel
	UI.panel = xlib.makeframe{ w = w, h = h, label = "Полицейский участок", showclose = true, draggable = true, nopopup = false };
	UI.panel:SetSkin("DarkRP");

	-- sheet
	UI.sheet = vgui.Create("DPropertySheet", UI.panel);
	UI.sheet:SetPos(15, 30);
	UI.sheet:SetSize(w-30, h-35);

	-- tab 1
	UI.tab1 = xlib.makepanel{ w = w-30, h = h-15 };
		UI.lst1 = xlib.makelistview( { w = w-40, h = h-125, multiselect = false, parent = UI.tab1 } );
		UI.lst1:AddColumn("ID"):SetFixedWidth(15);
		UI.lst1:AddColumn("Имя");
		UI.lst1:AddColumn("SteamID"):SetFixedWidth(200);
		UI.lst1:AddColumn("Задержан сотрудником"):SetFixedWidth(350);

		-- CP Option
		if ( bCP and !bArrested ) then
			-- Give you niga
			UI.btn2 = xlib.makebutton{x = 140, y = h-118, w = 120, h = 40, tooltip = "Вынести приговор.", label = "Выдать срок", parent = UI.tab1}
			UI.btn2.DoClick = function()
				local sid = puSteamID:GetString();
				local nTime = puTime:GetInt();
				local sReason = puReason:GetString();
				local bShould, sError;

				if ( nTime < 0 ) then
					bShould, sError = false, "Срок должен быть больше чем 0.";
				elseif ( sid:len() < 8 ) then
					bShould, sError = false, "Выберите задержанного из списка.";
				elseif ( string.utf8lower(sReason) == "причина" ) then
					bShould, sError = false, "Укажите нормальную причину!";
				elseif ( string.utf8len(sReason) < 10 ) then
					bShould, sError = false, "Причина должа быть больше 10 символов";
				end;

				if ( bShould == false ) then
					Derma_Message(sError, "Внимание", "Okay");
					return;
				end;

				RunConsoleCommand("gc_fullarrest", sid, nTime, sReason);

			end;

			UI.btn2:SetSkin("DarkRP");

			-- TEdit
			UI.edt1 = xlib.maketextbox{x = 300, y = h-120, w = 400, h = 20, tooltip = "Здесь нужно указать причину ареста!", parent = UI.tab1, text = "Причина"};
			UI.edt2 = xlib.makeslider{x = 300, y = h-95, w = 325, min = 1, max = gc.config:Get("customarrest_lvl_time"):Get(15) * (greenCode.attributes:Get(ATB_LEVEL) or 1), value = 15, parent = UI.tab1, label = "Время(мин):" };
			
			function UI.edt1:OnGetFocus()
				if ( !self.firstFocus ) then
					self:SetValue("");
					self.firstFocus = true;
				end;
			end;

			function UI.edt1:OnTextChanged() RunConsoleCommand("pu_reason", self:GetValue()); end;
			function UI.edt2:OnValueChanged() RunConsoleCommand("pu_time", math.Round(tonumber(self:GetValue()))); end;

			UI.edt1:SetAllowNonAsciiCharacters(true);
			UI.edt2:OnValueChanged();
		end;

	-- tab 2
	UI.tab2 = xlib.makepanel{ w = w-30, h = h-15 };
		UI.lst2 = xlib.makelistview{ w = w-40, h = h-125, multiselect = false, parent = UI.tab2 }
		UI.lst2:AddColumn("ID"):SetFixedWidth(15);
		UI.lst2:AddColumn("Имя");
		UI.lst2:AddColumn("SteamID"):SetFixedWidth(150);
		UI.lst2:AddColumn("Арестован сотрудником");
		UI.lst2:AddColumn("Причина")
		UI.lst2:AddColumn("Срок"):SetFixedWidth(100);
		
		-- Citizen option.
		if ( !bCP and !bArrested ) then
			UI.bt3 = xlib.makebutton{x = 140, y = h-118, w = 120, h = 40, tooltip = "Внести залог за БРО.", label = "Внести залог", parent = UI.tab2}
			UI.bt3.DoClick = function()
				local nPrice = ARREST_PERIOD * gc.config:Get("customarrest_bail"):Get(200);
				local sid = puSteamID:GetString();

				if ( sid:len() < 8 ) then
					Derma_Message("Выберите задержанного из списка.", "Внимание", "Okay");
					return;
				end;

				Derma_Query("Цена залога "..greenCode.kernel:FormatNumber(nPrice) .. GAMEMODE.Config.currency..", Вы согласны?", "Внести залог",
							"Да", function() RunConsoleCommand("gc_pledge", sid) end,
							"Нет", function() end);
			end;

			UI.bt3:SetSkin("DarkRP");
		end;


	UI.tab2:SetSkin("DarkRP");

	-- Button refresh
	UI.btn1 = xlib.makebutton{x = 35, y = h-60, w = 120, h = 40, tooltip = "Обновить информацию.", label = "Обновить", parent = UI.panel}
	UI.btn1.DoClick = function()
		self:Refresh();
	end;

	-- Add tabs
	UI.sheet:AddSheet( "Список задержанных", UI.tab1, "icon16/shield.png", false, false, false );
	UI.sheet:AddSheet( "Список заключенных", UI.tab2, "icon16/lock.png", false, false, false );

	-- Clean
	local Close = UI.panel.Close;
	function UI.panel:Close()
		gui.EnableScreenClicker(false);
		PLUGIN:Clear();
		Close(self);
	end;

	self:Refresh();
end;

function PLUGIN:Close()
	if ( self:IsOpen() ) then
		self.UI.panel:Remove();
		self.UI.panel = nil;
	end;
end;

function GAMEMODE:ShowSpare1()
	if ( PLUGIN:IsOpen() ) then
		PLUGIN:Close();
	else
		PLUGIN:Open();
	end;
end;

greenCode.datastream:Hook("RefreshPU", function(data)
	PLUGIN:Refresh();
end);

local function TextWarp( sText, nCount, symb )
	//local txt = string.utf8sub(sText, 0, nCount);
	local len = string.utf8len(sText);
	local nLine = 0;
	
	if ( len > nCount ) then
		nLine = math.ceil(len/nCount);
	end;
	
	local textWarp = "";
	symb = symb or "-";
	
	for i=0,nLine-1 do
		if (i==nLine-1) then symb = "" end;
		local space = i*nCount;
		textWarp = textWarp .. string.utf8sub( sText, space, space+nCount-1 )..symb;
	end
	
	print(textWarp)
end;

TextWarp( "проверка", 5, "-\n" );