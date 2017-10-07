--[[
	© 2013 GmodLive private project do not share
	without permission of its author (Andrew Mensky vk.com/men232).
--]]
local greenCode = greenCode;
local math = math;
local CMENU_PLUGIN = greenCode.plugin:Get("rp_custommenu");

local cBGColor = Color(0,0,0);
local cNormalColor = Color(81,222,81);
local cBadColor = Color(222,81,81);
local cBadColor2 = Color(255,81,81);

local MANAGEMENT_DEPOSIT_NAME = MANAGEMENT_DEPOSIT_NAME or "";
local MANAGEMENT_DEPOSIT_UID = MANAGEMENT_DEPOSIT_UID or 0;
local MANAGEMENT_DEPOSIT_PIN = MANAGEMENT_DEPOSIT_PIN or "";
local MANAGEMENT_DEPOSIT_MONEY = MANAGEMENT_DEPOSIT_MONEY or 0;
local MANAGEMENT_DEPOSIT_UPDATE = MANAGEMENT_DEPOSIT_UPDATE or function() end;

local function AddBack( BlockMenu, w )
	CMENU_PLUGIN = CMENU_PLUGIN or greenCode.plugin:Get("rp_custommenu");
	
	local BLOCK = BlockMenu:AddItem{ color = Color(0,0,0), h = 35, w = 35, callback = function()
		RunConsoleCommand("cl_gc_custommenu_update", "2657");
	end};
	CMENU_PLUGIN:ApplyTemplate( BLOCK, "simple", {
		color = Color(255,50,50),
		title = " ←",
		desc = "",
	});
	
	BLOCK.Title:SetFont("gcIntroTextBig");
	BLOCK.Title:SizeToContents();
	BLOCK.Title:SetPos( -7, -7 );
end;

CMENU_ATTR_CATEGORY = CM_CAT_CLASS:New{
	title = "#Deposit-Create",
	priority = 11,
	hide = true,
	callback = function( CM_CATEGORY, CMENU_PLUGIN, BlockMenu, bTextMenu, bBlockMenu )
		if ( bBlockMenu ) then
			BlockMenu:Clear( 0.4 );

			local w = BlockMenu:GetWide() - (BlockMenu.Padding*2);
			
			AddBack( BlockMenu, w ); -- Add Back button

			local BLOCK = BlockMenu:AddItem{ color = Color(0,0,0), h = 35, w = w };
			CMENU_PLUGIN:ApplyTemplate( BLOCK, "simple", {
				color = cMainTitle,
				title = "Создание счета в банке",
				desc = greenCode.kernel:TextWarp("Для создания депозита, вам потрубется стартовый капитал."..
					" А именно 5,000$. После чего вы сможете хранить свои збережения.", w-20, "default" ).."\n\n"..greenCode.kernel:TextWarp(
					"Зная pin код от вашего депозита, любой игрок сможете манипулировать вашим счетом в банке.", w-20, "default" )
			});

			BLOCK.turnOnH = 280;
			BLOCK:TurnToogle();
			BLOCK.Title:Center();
			BLOCK:SetDisabled(true);

			-- Name
			BLOCK.label1 = xlib.makelabel{ x = 10, y = 115, textcolor = Color(255,255,255), label = "Название счета:", parent = BLOCK }
			BLOCK.label1:SetExpensiveShadow(2, Color(0,0,0,255));
				BLOCK.edit1 = xlib.maketextbox{x = 10, y = 133, w = BLOCK:GetWide()-20, h = 20, tooltip = "Имя счета в банке.", parent = BLOCK, text = "Личный счет '"..gc.Client:Name().."'"};
				BLOCK.edit1:SetAllowNonAsciiCharacters(true);

			-- Pin
			BLOCK.label2 = xlib.makelabel{ x = 10, y = 165, textcolor = Color(255,255,255), label = "Pin код:", parent = BLOCK }
			BLOCK.label2:SetExpensiveShadow(2, Color(0,0,0,255));
				BLOCK.edit2 = xlib.maketextbox{x = 10, y = 183, w = BLOCK:GetWide()-20, h = 20, tooltip = "Пин код для вашего счета.", parent = BLOCK, text = ""};
				BLOCK.edit2:SetNumeric(true);

				local badColor = Color(200,0,0);
				local goodColor = Color(0,150,0);
				local normalColor = BLOCK.edit2:GetTextColor();

				function BLOCK.edit2:OnTextChanged()
					local str = self:GetText();
					local len = string.utf8len(str);

					if ( len < 4 or len > 12 ) then
						self:SetTextColor(badColor);
						return;
					end;

					self:SetTextColor(goodColor);
				end;

				function BLOCK.edit2:OnLoseFocus() self:SetTextColor(normalColor); end;
				function BLOCK.edit2:OnGetFocus() self:OnTextChanged(); end;

			-- Start Money
			BLOCK.edit3 = xlib.makeslider{x = 10, y = 215, w = w-20, min = 5000, max = gc.Client:getDarkRPVar("money") or 0, textcolor = Color(255,255,255), value = 5000, parent = BLOCK, label = "Начальный капитал: $" };
			BLOCK.edit3.Label:SetExpensiveShadow(2, Color(0,0,0,255));

			-- Create
			BLOCK.btn1 = xlib.makebutton{x = 10, y = BLOCK.turnOnH-40, w = BLOCK:GetWide()-20, h = 35, label = "Создать", parent = BLOCK};
			BLOCK.btn1:SetSkin("DarkRP");

			function BLOCK.btn1:DoClick()
				surface.PlaySound("ui/buttonclick.wav");
				CMENU_PLUGIN:Close();
				RunConsoleCommand("gc_deposit_create", BLOCK.edit1:GetValue(), BLOCK.edit2:GetValue(), BLOCK.edit3:GetValue() );
			end;
		end;
	end,
}:Register();

CMENU_ATTR_CATEGORY = CM_CAT_CLASS:New{
	title = "#Deposit-Login",
	priority = 12,
	hide = true,
	callback = function( CM_CATEGORY, CMENU_PLUGIN, BlockMenu, bTextMenu, bBlockMenu )
		if ( bBlockMenu ) then
			BlockMenu:Clear( 0.4 );

			local w = BlockMenu:GetWide() - (BlockMenu.Padding*2);
			
			AddBack( BlockMenu, w ); -- Add Back button

			local BLOCK = BlockMenu:AddItem{ color = Color(0,0,0), h = 35, w = w - 45 };
			CMENU_PLUGIN:ApplyTemplate( BLOCK, "simple", {
				color = cMainTitle,
				title = "Вход в управление депозитом",
				desc = "",
			});

			BLOCK.Title:Center();
			BLOCK:SetDisabled(true);

			local BLOCK_UID = BlockMenu:AddItem{ color = Color(0,0,0), h = 35, w = w };
			CMENU_PLUGIN:ApplyTemplate( BLOCK_UID, "simple", {
				color = cMainTitle,
				title = "Лицевой счет:",
				desc = ""
			});

			local tDeposits = {}

			for uid, name in pairs( gc.Client:GetSharedVar("deposits", {}) ) do
				table.insert( tDeposits, uid.." - "..name );
			end

			BLOCK_UID.edit1 = xlib.makecombobox{x = 140, y = 8, choices = tDeposits, enableinput = true, w = BLOCK_UID:GetWide()-150, h = 20, tooltip = "Номер лицевого счета в банке.", parent = BLOCK_UID, text = ""};
			BLOCK_UID.edit1.TextEntry:SetNumeric(true);

			local BLOCK_PIN = BlockMenu:AddItem{ color = Color(0,0,0), h = 35, w = w };
			CMENU_PLUGIN:ApplyTemplate( BLOCK_PIN, "simple", {
				color = cMainTitle,
				title = "Pin Code:",
				desc = ""
			});

			BLOCK_PIN.edit2 = xlib.maketextbox{x = 140, y = 8, w = BLOCK_PIN:GetWide()-150, h = 20, tooltip = "Pin код от лицевого счета.", parent = BLOCK_PIN, text = ""};
			BLOCK_PIN.edit2:SetNumeric(true);

			local function AddNum(i, callback)
				local BLOCK_PIN = BlockMenu:AddItem{ color = Color(0,0,0), h = 120, w = 120, callback = callback or function()
					surface.PlaySound("ui/buttonclick.wav");
					BLOCK_PIN.edit2:SetText(BLOCK_PIN.edit2:GetValue()..tostring(i));
				end};
				BLOCK_PIN.Title = xlib.makelabel{ parent = BLOCK_PIN, x = 0, y = 0, label = i, font = "gcMenuTextBig", textcolor = Color(255,255,255) }
				BLOCK_PIN.Title:SetExpensiveShadow(2, Color(0,0,0,255));
				BLOCK_PIN.Title:Center();
			end;

			for i=1,9 do AddNum(i) end;
			AddNum(0)
			AddNum("<", function()
				surface.PlaySound("ui/buttonclick.wav");
				BLOCK_PIN.edit2:SetText( BLOCK_PIN.edit2:GetValue():sub(1, #BLOCK_PIN.edit2:GetValue()-1) );
			end)
			AddNum("Enter", function()
				surface.PlaySound("ui/buttonclick.wav");
				local uid, name = string.match(BLOCK_UID.edit1:GetValue(), "(%d+) - (.+)");
				RunConsoleCommand("gc_deposit_login", uid or BLOCK_UID.edit1:GetValue(), BLOCK_PIN.edit2:GetValue());
			end)
		end;
	end,
}:Register();

CMENU_ATTR_CATEGORY = CM_CAT_CLASS:New{
	title = "#Deposit-Maganer",
	priority = 13,
	hide = true,
	callback = function( CM_CATEGORY, CMENU_PLUGIN, BlockMenu, bTextMenu, bBlockMenu )
		if ( bBlockMenu ) then
			BlockMenu:Clear( 0.4 );

			local w = BlockMenu:GetWide() - (BlockMenu.Padding*2);
			
			AddBack( BlockMenu, w ); -- Add Back button

			local BLOCK = BlockMenu:AddItem{ color = Color(0,0,0), h = 35, w = w };
			CMENU_PLUGIN:ApplyTemplate( BLOCK, "simple", {
				color = cMainTitle,
				title = MANAGEMENT_DEPOSIT_NAME.." - "..MANAGEMENT_DEPOSIT_UID,
				desc =  greenCode.kernel:TextWarp("Вы находитесь в панели управления депозитом. С помошью этой панели вы можете управлять этим счетом.", w-20, "default"),
			});

			BLOCK.Title:Center();
			BLOCK:TurnToogle();
			BLOCK:SetDisabled(true);

			local BLOCK = BlockMenu:AddItem{ color = Color(0,0,0), h = 35, w = w };
			CMENU_PLUGIN:ApplyTemplate( BLOCK, "simple", {
				color = cMainTitle,
				title = "Баланс",
				desc = "",
			});

			function BLOCK.Title:Think()
				self:SetText("Баланс: "..greenCode.kernel:FormatNumber(MANAGEMENT_DEPOSIT_MONEY).."$");
				self:SizeToContents();
			end;

			BLOCK:SetDisabled(true);

			-- Set money
			local BLOCK_SET = BlockMenu:AddItem{ color = Color(0,0,0), h = 35, w = w, callback = function( BLOCK_SET ) BLOCK_SET:TurnToogle(); end };
			CMENU_PLUGIN:ApplyTemplate( BLOCK_SET, "simple", {
				color = cMainTitle,
				title = "Положить деньги",
				desc = "\n\n\n\n\n",
			});

			BLOCK_SET.edit1 = xlib.makeslider{x = 10, y = 40, value = 1, w = w-20, min = 1, max = gc.Client:getDarkRPVar("money") or 0, textcolor = Color(255,255,255), parent = BLOCK_SET, label = "Сумма: $" };
			BLOCK_SET.edit1.Label:SetExpensiveShadow(2, Color(0,0,0,255));

			BLOCK_SET.btn1 = xlib.makebutton{x = 10, y = BLOCK_SET.turnOnH-40, w = BLOCK_SET:GetWide()-20, h = 35, label = "Положить", parent = BLOCK_SET};
			BLOCK_SET.btn1:SetSkin("DarkRP");

			function BLOCK_SET.btn1:DoClick()
				surface.PlaySound("ui/buttonclick.wav");
				RunConsoleCommand("gc_deposit_operation", 2, MANAGEMENT_DEPOSIT_UID, MANAGEMENT_DEPOSIT_PIN, BLOCK_SET.edit1:GetValue() );
			end;

			-- Get money
			local BLOCK_GET = BlockMenu:AddItem{ color = Color(0,0,0), h = 35, w = w, callback = function( BLOCK_GET ) BLOCK_GET:TurnToogle(); end };
			CMENU_PLUGIN:ApplyTemplate( BLOCK_GET, "simple", {
				color = cMainTitle,
				title = "Снять деньги",
				desc = "\n\n\n\n\n",
			});

			BLOCK_GET.edit1 = xlib.makeslider{x = 10, y = 40,  value = 1, w = w-20, min = 1, max = MANAGEMENT_DEPOSIT_MONEY or 0, textcolor = Color(255,255,255), parent = BLOCK_GET, label = "Сумма: $" };
			BLOCK_GET.edit1.Label:SetExpensiveShadow(2, Color(0,0,0,255));

			BLOCK_GET.btn1 = xlib.makebutton{x = 10, y = BLOCK_GET.turnOnH-40, w = BLOCK_GET:GetWide()-20, h = 35, label = "Снять", parent = BLOCK_GET};
			BLOCK_GET.btn1:SetSkin("DarkRP");

			function BLOCK_GET.btn1:DoClick()
				surface.PlaySound("ui/buttonclick.wav");
				RunConsoleCommand("gc_deposit_operation", 1, MANAGEMENT_DEPOSIT_UID, MANAGEMENT_DEPOSIT_PIN, BLOCK_GET.edit1:GetValue() );
			end;

			-- Change pin
			local BLOCK_PIN = BlockMenu:AddItem{ color = Color(0,0,0), h = 35, w = w, callback = function( BLOCK_PIN ) BLOCK_PIN:TurnToogle(); end };
			CMENU_PLUGIN:ApplyTemplate( BLOCK_PIN, "simple", {
				color = cMainTitle,
				title = "Изменить PIN",
				desc = "\n\n\n\n\n",
			});

			BLOCK_PIN.turnOnH = 105;

			BLOCK_PIN.edit1 = xlib.maketextbox{x = 10, y = 40, w = BLOCK_PIN:GetWide()-20, h = 20, tooltip = "Pin код от лицевого счета.", parent = BLOCK_PIN, text = MANAGEMENT_DEPOSIT_PIN};
			BLOCK_PIN.edit1:SetNumeric(true);

			local badColor = Color(200,0,0);
			local goodColor = Color(0,150,0);
			local normalColor = BLOCK_PIN.edit1:GetTextColor();

			function BLOCK_PIN.edit1:OnTextChanged()
				local str = self:GetText();
				local len = string.utf8len(str);

				if ( len < 4 or len > 12 ) then
					self:SetTextColor(badColor);
					return;
				end;

				self:SetTextColor(goodColor);
			end;

			function BLOCK_PIN.edit1:OnLoseFocus() self:SetTextColor(normalColor); end;
			function BLOCK_PIN.edit1:OnGetFocus() self:OnTextChanged(); end;

			BLOCK_PIN.btn1 = xlib.makebutton{x = 10, y = BLOCK_PIN.turnOnH-40, w = BLOCK_PIN:GetWide()-20, h = 35, label = "Изменить", parent = BLOCK_PIN};
			BLOCK_PIN.btn1:SetSkin("DarkRP");

			function BLOCK_PIN.btn1:DoClick()
				surface.PlaySound("ui/buttonclick.wav");
				RunConsoleCommand("gc_deposit_operation", 3, MANAGEMENT_DEPOSIT_UID, MANAGEMENT_DEPOSIT_PIN, BLOCK_PIN.edit1:GetValue() );
			end;

			-- Trans
			local BLOCK_TRANS = BlockMenu:AddItem{ color = Color(0,0,0), h = 35, w = w, callback = function( BLOCK_TRANS ) BLOCK_TRANS:TurnToogle(); end };
			CMENU_PLUGIN:ApplyTemplate( BLOCK_TRANS, "simple", {
				color = cMainTitle,
				title = "Перевод",
				desc = "\n\n\n\n\n",
			});

			BLOCK_TRANS.turnOnH = 150;

			BLOCK_TRANS.edit1 = xlib.maketextbox{x = 10, y = 40, w = BLOCK_TRANS:GetWide()-20, h = 20, tooltip = "Конечний лицевой счет.", parent = BLOCK_TRANS, text = ""};
			BLOCK_TRANS.edit1:SetNumeric(true);

			BLOCK_TRANS.edit2 = xlib.makeslider{x = 10, y = 75,  value = 1, w = w-20, min = 1, max = MANAGEMENT_DEPOSIT_MONEY or 0, textcolor = Color(255,255,255), parent = BLOCK_TRANS, label = "Сумма: $" };
			BLOCK_TRANS.edit2.Label:SetExpensiveShadow(2, Color(0,0,0,255));

			BLOCK_TRANS.btn1 = xlib.makebutton{x = 10, y = BLOCK_TRANS.turnOnH-40, w = BLOCK_TRANS:GetWide()-20, h = 35, label = "Перевод", parent = BLOCK_TRANS};
			BLOCK_TRANS.btn1:SetSkin("DarkRP");

			function BLOCK_TRANS.btn1:DoClick()
				surface.PlaySound("ui/buttonclick.wav");
				RunConsoleCommand("gc_deposit_operation", 4, MANAGEMENT_DEPOSIT_UID, MANAGEMENT_DEPOSIT_PIN, BLOCK_TRANS.edit1:GetValue(), BLOCK_TRANS.edit2:GetValue() );
			end;

			-- Remove
			local BLOCK = BlockMenu:AddItem{ color = Color(0,0,0), h = 35, w = w, callback = function()
				surface.PlaySound("ui/buttonclick.wav");
				Derma_Query("Вы уверены что хотите удалить счет?\nПосле удаление восстановить счет невозможно!", "Внимание",
							"Да", function() RunConsoleCommand("gc_deposit_remove", MANAGEMENT_DEPOSIT_UID, MANAGEMENT_DEPOSIT_PIN ); end,
							"Нет", function() end);
			end};
			CMENU_PLUGIN:ApplyTemplate( BLOCK, "simple", {
				color = cBadColor,
				title = "Удалить счет",
				desc = "",
			});

			-- Exit
			local BLOCK = BlockMenu:AddItem{ color = Color(0,0,0), h = 35, w = w, callback = function()
				surface.PlaySound("ui/buttonclick.wav");
				RunConsoleCommand("cl_gc_custommenu_close");
			end};
			CMENU_PLUGIN:ApplyTemplate( BLOCK, "simple", {
				color = cBadColor2,
				title = "Выход",
				desc = "",
			});

			MANAGEMENT_DEPOSIT_UPDATE = function()
				timer.Simple(0.3, function()
					if ( ValidPanel(BLOCK_SET) ) then
						BLOCK_SET.edit1:SetMinMax( 1, gc.Client:getDarkRPVar("money") or 0 );
						BLOCK_SET.edit1:SetValue( 1 );
					end;

					if ( ValidPanel(BLOCK_GET) ) then
						BLOCK_GET.edit1:SetMinMax( 1, MANAGEMENT_DEPOSIT_MONEY or 0 );
						BLOCK_GET.edit1:SetValue( 1 );
					end;

					if ( ValidPanel(BLOCK_TRANS) ) then
						BLOCK_TRANS.edit1:SetText("");
						BLOCK_TRANS.edit2:SetMinMax( 1, MANAGEMENT_DEPOSIT_MONEY or 0 );
						BLOCK_TRANS.edit2:SetValue( 1 );
					end;
				end);
			end;
		end;
	end,
}:Register();

CMENU_ATTR_CATEGORY = CM_CAT_CLASS:New{
	title = "#Deposit-Menu",
	priority = 12,
	hide = true,
	callback = function( CM_CATEGORY, CMENU_PLUGIN, BlockMenu, bTextMenu, bBlockMenu )
		if ( bBlockMenu ) then
			BlockMenu:Clear( 0.4 );

			local w = BlockMenu:GetWide() - (BlockMenu.Padding*2);

			-- Login
			local BLOCK = BlockMenu:AddItem{ color = Color(0,0,0), h = 35, w = w, callback = function()
				surface.PlaySound("ui/buttonclick.wav");
				RunConsoleCommand("cl_gc_custommenu_update", "20763");
			end};
			CMENU_PLUGIN:ApplyTemplate( BLOCK, "simple", {
				title = "Личный кабинет",
				desc = "",
			});

			-- Create
			local BLOCK = BlockMenu:AddItem{ color = Color(0,0,0), h = 35, w = w, callback = function()
				surface.PlaySound("ui/buttonclick.wav");
				RunConsoleCommand("cl_gc_custommenu_update", "29645");
			end};
			CMENU_PLUGIN:ApplyTemplate( BLOCK, "simple", {
				title = "Создать счет",
				desc = "",
			});
		end;
	end,
}:Register();

greenCode.datastream:Hook("DepositUpdate", function(data)
	MANAGEMENT_DEPOSIT_NAME = data.name;
	MANAGEMENT_DEPOSIT_UID = data.uid;
	MANAGEMENT_DEPOSIT_PIN = data.pin or MANAGEMENT_DEPOSIT_PIN;
	MANAGEMENT_DEPOSIT_MONEY = data.money;

	if ( data.login ) then
		RunConsoleCommand("cl_gc_custommenu_update", 14385);
	else
		MANAGEMENT_DEPOSIT_UPDATE();
	end;
end);

greenCode.datastream:Hook("DepositClean", function()
	MANAGEMENT_DEPOSIT_NAME = "";
	MANAGEMENT_DEPOSIT_UID = 0;
	MANAGEMENT_DEPOSIT_PIN = "";
	MANAGEMENT_DEPOSIT_MONEY = 0;
	RunConsoleCommand("cl_gc_custommenu_close");
end);