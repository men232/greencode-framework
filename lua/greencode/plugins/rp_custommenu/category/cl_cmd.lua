--[[
	© 2013 GmodLive private project do not share
	without permission of its author (Andrew Mensky vk.com/men232).
--]]

local gc = gc;
local CMENU_PLUGIN = greenCode.plugin:Get("rp_custommenu");

local cCPColor = Color(144,178,216);
local cMoneyColor = Color(147,206,142);

CMENU_CMD_CATEGORY = CM_CAT_CLASS:New{
	title = "Действия",
	priority = 1,
	callback = function()
		CMENU_PLUGIN = greenCode.plugin:Get("rp_custommenu");
		local bTextMenu, bBlockMenu = CMENU_PLUGIN:IsOpen();
		local BlockMenu = CMENU_PLUGIN.BlockMenu;
		
		if ( bBlockMenu ) then
			BlockMenu:Clear( 0.4 );
			
			local w = BlockMenu:GetWide() - (BlockMenu.Padding*2);
			
			-- Денежные операции.
			local BLOCK = BlockMenu:AddItem{ color = Color(0,0,0), w = w, h = 35,
				//callback = function( BLOCK ) BLOCK:TurnToogle(); end,
				callback = function( BLOCK )
					local menu = DermaMenu();
					menu:AddOption("Передать (на кого смотрите)", function()
						Derma_StringRequest("Количество", "Сколько денег вы хотите передать?", "", function(a)
							greenCode.Client:ConCommand("darkrp /give " .. tostring(a));
							CMENU_PLUGIN:Close();
						end);
					end);
					menu:AddOption("Выбросить", function()
						Derma_StringRequest("Количество", "Сколько денег вы хотите выбросить?", "", function(a) 
							greenCode.Client:ConCommand("darkrp /dropmoney " .. tostring(a));
							CMENU_PLUGIN:Close();
						end);
					end);
					menu:AddOption("Отмена", function() end);
					menu:Open()
				end,
			};
			
			CMENU_PLUGIN:ApplyTemplate( BLOCK, "simple", { /*clk2 = true, tooltip = "ЛКМ - Развернуть/Свернуть.\nПКМ - Действия.",*/ color = cMoneyColor, title = "Денежные операции"/*, desc = "Данное меню, испоьзуется для передачи и выброса денег."*/ } );
			BLOCK.turnOnH = 55;
						
			-- Сменить имя.
			local BLOCK = BlockMenu:AddItem{ color = Color(0,0,0), w = w, h = 35,
				callback = function( BLOCK ) BLOCK:TurnToogle(); end,
			};
			
			CMENU_PLUGIN:ApplyTemplate( BLOCK, "simple", { /*turn = true,*/ tooltip = "ЛКМ - Развернуть/Свернуть.", color = Color(178,183,213), title = "Изменить имя", desc = 
				[[Имя должно состоять из имени и фамилии. После ввода имени,
				нажмите Enter.

				Имя должно соответствовать формату < Имя фамилия > с учетом
				регистра.


				]]
			} );
			BLOCK.edit1 = xlib.maketextbox{x = 5, y = BLOCK.turnOnH-25, w = BLOCK:GetWide()-10, h = 20, tooltip = "Здесь нужно указать своё имя!", parent = BLOCK, text = gc.Client:Name()};
			BLOCK.edit1:SetAllowNonAsciiCharacters(true);
			BLOCK.edit1.OnEnter = function() RunConsoleCommand("darkrp", "/rpname", BLOCK.edit1:GetValue()) end;

			local badColor = Color(150,0,0);
			local goodColor = Color(0,150,0);
			local normalColor = BLOCK.edit1:GetTextColor();
			local allowed = {
			'q', 'w', 'e', 'r', 't', 'y', 'u', 'i', 'o', 'p',
			'a', 's', 'd', 'f', 'g', 'h', 'j', 'k', 'l',
			'z', 'x', 'c', 'v', 'b', 'n', 'm', ' ',
			'й', 'ц', 'у', 'к', 'е', 'н', 'г', 'ш', 'щ', 'з', 'х', 'ъ',
			'ф', 'ы', 'в', 'а', 'п', 'р', 'о', 'л', 'д', 'ж', 'э',
			'я', 'ч', 'с', 'м', 'и', 'т', 'ь', 'б', 'ю', '-'};

			function BLOCK.edit1:OnTextChanged()
				local str = self:GetText();
				local len = string.utf8len(str);
				local low = string.utf8lower(str);

				if len > 30 or len < 6 then
					self:SetTextColor(badColor);
					return;
				end;

				for i=1, len do
					local uchar = string.utf8sub( low, i, i );

					if not table.HasValue(allowed, uchar) then
						self:SetTextColor(badColor);
						return;
					end
				end;

				local upLen = string.upperLen( str );

				if ( upLen != 2 and upLen != 3 ) then
					self:SetTextColor(badColor);
					return;
				end;
				
				local split = string.Explode(" ", str);

				if ( #split < 2 or #split > 3 ) then
					self:SetTextColor(badColor);
					return;
				elseif ( !string.isUpper( string.utf8sub(split[1], 1, 1) ) or !string.isUpper( string.utf8sub(split[2], 1, 1) )) then
					self:SetTextColor(badColor);
					return;
				elseif string.utf8len(split[1]) < 3 or string.utf8len(split[2]) < 3 then
					self:SetTextColor(badColor);
					return;
				end;

				self:SetTextColor(goodColor);
			end;

			function BLOCK.edit1:OnLoseFocus() self:SetTextColor(normalColor); end;
			function BLOCK.edit1:OnGetFocus() self:OnTextChanged(); end;
			
			-- Спать
			/*local BLOCK = BlockMenu:AddItem{ color = Color(0,0,0), w = w, h = 35,
				callback = function( BLOCK )
					Derma_Query("Вы уверены?", DarkRP.getPhrase("go_to_sleep"),
								"Да", function() RunConsoleCommand("darkrp", "/sleep"); CMENU_PLUGIN:Close(); end,
								"Нет", function() end)
				end,
			};
			
			CMENU_PLUGIN:ApplyTemplate( BLOCK, "simple", { color = Color(225,243,253), title = DarkRP.getPhrase("go_to_sleep"), desc = "" } );*/
			
			-- Drop
			local BLOCK = BlockMenu:AddItem{ color = Color(0,0,0), w = w, h = 35,
				callback = function( BLOCK ) 								
					Derma_Query("Вы уверены?", DarkRP.getPhrase("drop_weapon"),
								"Да", function() RunConsoleCommand("darkrp", "/drop"); CMENU_PLUGIN:Close(); end,
								"Нет", function() end)
				end,
			};
			
			CMENU_PLUGIN:ApplyTemplate( BLOCK, "simple", { color = Color(228,244,253), title = DarkRP.getPhrase("drop_weapon"), desc = "" } );
			
			-- Demoute
			local BLOCK = BlockMenu:AddItem{ color = Color(0,0,0), w = w, h = 35,
				callback = function( BLOCK ) BLOCK:TurnToogle(); end,
			};
			
			CMENU_PLUGIN:ApplyTemplate( BLOCK, "simple", { /*turn = true,*/ tooltip = "ЛКМ - Развернуть/Свернуть.", color = Color(226,229,253), title = DarkRP.getPhrase("demote_player_menu"), desc = "Запрос на увольнение игрока, это очень серьёзно!\nИспользуйте эту функцию только при крайней необходимости." } );
			BLOCK.edit1 = xlib.maketextbox{x = 5, y = 65, w = BLOCK:GetWide()-10, h = 20, tooltip = "Здесь нужно указать причину увольнения!", parent = BLOCK, text = ""};
			BLOCK.edit1:SetAllowNonAsciiCharacters(true);
			
			BLOCK.edit2 = xlib.makecombobox{x = 5, y = 90, w = BLOCK:GetWide()-10, h = 20, tooltip = "Выберите игрока для увольнения.", parent = BLOCK };
			for _,ply in pairs(_player.GetAll()) do
				if (ply != greenCode.Client) then
					BLOCK.edit2:AddChoice(ply:Name());
				end;
			end;
			
			BLOCK.btn1 = xlib.makebutton{x = BLOCK:GetWide() - 80, y = 115, w = 75, h = 20, label = "Уволить", parent = BLOCK};
			BLOCK.btn1:SetSkin("DarkRP");
			
			function BLOCK.btn1:DoClick()
				local target = greenCode:FindPlayer(BLOCK.edit2:GetValue());
				
				if (target) then
					RunConsoleCommand("darkrp", "/demote", target:SteamID(), BLOCK.edit1:GetValue());
				end;
			end;
			
			BLOCK.turnOnH = 145;
			
			-- Ордер на обыск.
			local function AddWarrant()
				local BLOCK = BlockMenu:AddItem{ color = Color(0,0,0), w = w, h = 35,
					callback = function( BLOCK ) BLOCK:TurnToogle(); end,
				};
				
				CMENU_PLUGIN:ApplyTemplate( BLOCK, "simple", { /*turn = true,*/ tooltip = "ЛКМ - Развернуть/Свернуть.", color = cCPColor, title = DarkRP.getPhrase("searchwarrantbutton"), desc = "Необходим для обыска частой территории!\nИспользуйте эту функцию если есть весомая причина." } );
				BLOCK.edit1 = xlib.maketextbox{x = 5, y = 65, w = BLOCK:GetWide()-10, h = 20, tooltip = "Здесь нужно указать причину ордера!", parent = BLOCK, text = ""};
				BLOCK.edit1:SetAllowNonAsciiCharacters(true);
				
				BLOCK.edit2 = xlib.makecombobox{x = 5, y = 90, w = BLOCK:GetWide()-10, h = 20, tooltip = "Выберите игрока для запроса ордера.", parent = BLOCK };
				for _,ply in pairs(_player.GetAll()) do
					if (ply != greenCode.Client) then
						BLOCK.edit2:AddChoice(ply:Name());
					end;
				end;
				
				BLOCK.btn1 = xlib.makebutton{x = BLOCK:GetWide() - 80, y = 115, w = 75, h = 20, label = "Запрос", parent = BLOCK};
				BLOCK.btn1:SetSkin("DarkRP");
				
				function BLOCK.btn1:DoClick()
					local target = greenCode:FindPlayer(BLOCK.edit2:GetValue());
					
					if (target) then
						RunConsoleCommand("darkrp", "/warrant", target:SteamID(), BLOCK.edit1:GetValue());
					end;
				end;
				
				BLOCK.turnOnH = 145;
			end;
			
			-- Запрос на розыск.
			local function AddWanted()
				local BLOCK = BlockMenu:AddItem{ color = Color(0,0,0), w = w, h = 35,
					callback = function( BLOCK ) BLOCK:TurnToogle(); end,
				};
				
				CMENU_PLUGIN:ApplyTemplate( BLOCK, "simple", { /*turn = true,*/ tooltip = "ЛКМ - Развернуть/Свернуть.", color = cCPColor, title = DarkRP.getPhrase("make_wanted"), desc = "Необходим для розыска нарушителя закона!\nИспользуйте эту функцию если есть весомая причина." } );
				
				BLOCK.edit1 = xlib.maketextbox{x = 5, y = 65, w = BLOCK:GetWide()-10, h = 20, tooltip = "Здесь нужно указать причину розыска!", parent = BLOCK, text = ""};
				BLOCK.edit1:SetAllowNonAsciiCharacters(true);
				
				BLOCK.edit2 = xlib.makecombobox{x = 5, y = 90, w = BLOCK:GetWide()-10, h = 20, tooltip = "Выберите игрока для розыска.", parent = BLOCK };
				for _,ply in pairs(_player.GetAll()) do
					if (ply != greenCode.Client) then
						BLOCK.edit2:AddChoice(ply:Name());
					end;
				end;
				
				BLOCK.btn1 = xlib.makebutton{x = BLOCK:GetWide() - 80, y = 115, w = 75, h = 20, label = "Запрос", parent = BLOCK};
				BLOCK.btn1:SetSkin("DarkRP");
				
				function BLOCK.btn1:DoClick()
					local target = greenCode:FindPlayer(BLOCK.edit2:GetValue());
					
					if (target) then
						RunConsoleCommand("darkrp", "/wanted", target:SteamID(), BLOCK.edit1:GetValue());
					end;
				end;
				
				BLOCK.turnOnH = 145;
				
				-- Снять розысу.
				local BLOCK = BlockMenu:AddItem{ color = Color(0,0,0), w = w, h = 35,
					callback = function( BLOCK )
						local menu = DermaMenu();
						for _,ply in pairs(_player.GetAll()) do
							if ply.DarkRPVars.wanted and ply ~= gc.Client then
								menu:AddOption(ply:Nick(), function() greenCode.Client:ConCommand("darkrp /unwanted \"" .. ply:SteamID() .. "\""); CMENU_PLUGIN:Close(); end);
							end
						end
						menu:AddOption("Отмена", function() end);
						menu:Open();
					end,
				};
				
				CMENU_PLUGIN:ApplyTemplate( BLOCK, "simple", { color = cCPColor, title = DarkRP.getPhrase("make_unwanted"), desc = "" } );
			end;
			
			-- Ком. час.
			local function AddLockdown()
				local BLOCK = BlockMenu:AddItem{ color = Color(0,0,0), w = w, h = 35,
					callback = function( BLOCK )
						local menu = DermaMenu();
						menu:AddOption(DarkRP.getPhrase("initiate_lockdown"), function() greenCode.Client:ConCommand("darkrp /lockdown") CMENU_PLUGIN:Close(); end);
						menu:AddOption(DarkRP.getPhrase("stop_lockdown"), function() greenCode.Client:ConCommand("darkrp /unlockdown") CMENU_PLUGIN:Close(); end);
						menu:AddOption("Отмена", function() end);
						menu:Open();
					end,
				};
				
				CMENU_PLUGIN:ApplyTemplate( BLOCK, "simple", { color = cCPColor, title = "Комендантский час", desc = "" } );
			end;
			
			-- Спаун законов.
			local function AddPlaceLaws()
				local BLOCK = BlockMenu:AddItem{ color = Color(0,0,0), w = w, h = 35,
					callback = function( BLOCK )
						greenCode.Client:ConCommand("say /placelaws");
						CMENU_PLUGIN:Close();
					end,
				};
				
				CMENU_PLUGIN:ApplyTemplate( BLOCK, "simple", { color = cCPColor, title = "Разместить билборд с законами", desc = "" } );
			end;
			
			-- Добавить закон.
			local function AddLaws()
				local BLOCK = BlockMenu:AddItem{ color = Color(0,0,0), w = w, h = 35,
					callback = function( BLOCK ) BLOCK:TurnToogle(); end,
				};
				
				CMENU_PLUGIN:ApplyTemplate( BLOCK, "simple", { /*turn = true,*/ tooltip = "ЛКМ - Развернуть/Свернуть.", color = cCPColor, title = "Управление законами", desc = "Для управление, используйте чат команды:\n\n/addlaw <закон> - Добавить закон.\n/removelaw <номер закона> - Удалить закон.\n\n<> не учитывать!" } );
			end;
			
			-- Agenda
			local function AddAgenda()
				local BLOCK = BlockMenu:AddItem{ color = Color(0,0,0), w = w, h = 35,
					callback = function( BLOCK ) BLOCK:TurnToogle(); end,
				};
				
				CMENU_PLUGIN:ApplyTemplate( BLOCK, "simple", { /*turn = true,*/ tooltip = "ЛКМ - Развернуть/Свернуть.", color = Color(224,229,251), title = "Задачи/Приказы", desc = "Для изменения, используйте чат команду:\n\n/agenda <задача или приказ>" } );
			end;
			
			local team = greenCode.Client:Team();

			if (team == TEAM_MAYOR) then				
				AddWarrant();
				AddWanted();
				AddLockdown();
				AddPlaceLaws();
				AddLaws();
				AddAgenda();				
			elseif (greenCode.Client:IsCP()) then				
				AddWarrant();
				AddWanted();
			elseif (team == TEAM_MOB) then
				AddAgenda();
			end
		end;
	end;
}:Register();