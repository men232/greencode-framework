--[[
	© 2013 GmodLive private project do not share
	without permission of its author (Andrew Mensky vk.com/men232).
--]]
local greenCode = greenCode;
local gc = gc;
local math = math;
local table = table;
local CMENU_PLUGIN, TER_PLUGIN, TER_ONW;

local cMainTitle = Color(222,222,81);
local cTitleColor = Color(81,222,81);
local cTitleColor2 = Color(100,255,255);
local cTitleColor3 = Color(255,200,25);
local cTitleColor4 = Color(255,255,100);
local cTitleColor5 = Color(255,100,100);
local cTitleColor6 = Color(150,186,123);
local w;

local function AddTitle( title, color, desc, bCallback, bCallback2, bNoChangeFont )
	local BLOCK = BlockMenu:AddItem{ color = Color(0,0,0), h = 25, w = w,
		callback = bCallback and function( BLOCK ) BLOCK:TurnToogle(); end,
		callback2 = bCallback2 and function( BLOCK )
			local menu = DermaMenu();
			menu:AddOption("Скопировать информацию", function()
				SetClipboardText(BLOCK.Desc:GetText());
			end);
			menu:AddOption("Отмена", function() end);
			menu:Open()
		end,
	};
	CMENU_PLUGIN:ApplyTemplate( BLOCK, "simple", { color = color, title = title, desc = desc or "" });
	
	if ( !bNoChangeFont ) then
		BLOCK.Title:SetFont("ChatFont");
		BLOCK.Title:SetExpensiveShadow(2, Color(0,0,0,100));
		BLOCK.Title:SizeToContents();
	end;

	BLOCK.Title:Center();

	if ( !bCallback and !bCallback2 ) then
		BLOCK:SetDisabled(true);
	end;

	return BLOCK;
end;

CMENU_TERRITORY_CATEGORY = CM_CAT_CLASS:New{
	title = "Территории",
	priority = 5,
	callback = function()		
		CMENU_PLUGIN = CMENU_PLUGIN or greenCode.plugin:Get("rp_custommenu");
		TER_PLUGIN = TER_PLUGIN or greenCode.plugin:Get("territory");
		TER_ONW = TER_ONW or greenCode.plugin:Get("ter_owning");
		
		local bTextMenu, bBlockMenu = CMENU_PLUGIN:IsOpen();
		local args = CMENU_PLUGIN.args;
		
		BlockMenu = CMENU_PLUGIN.BlockMenu;
		w = BlockMenu:GetWide() - (BlockMenu.Padding*2);
		
		if ( bBlockMenu ) then
			BlockMenu:Clear( 0.4 );
					
			local BLOCK = BlockMenu:AddItem{ color = Color(0,0,0), h = 35, w = w, callback = function( BLOCK ) BLOCK:TurnToogle(); end };
			CMENU_PLUGIN:ApplyTemplate( BLOCK, "simple", {
				color = cMainTitle,
				title = "Территории",
				desc = [[Здесь вы можете покупать, продавать и настраивать права
				для своих территорий. Покупая целую территорию, вы становитесь
				владельцем всех дверей.	]]
			});
			
			BLOCK:TurnToogle();
			BLOCK.Title:Center();
			//BLOCK:SetTall( BLOCK.turnOnH );
			
			local TERRITORY = TER_PLUGIN:GetLocation(gc.Client:GetShootPos());
			
			if ( TERRITORY and TERRITORY:IsValid() ) then
				local tOwnerNames = {};
				local tCoOwnerNames = {};
				local space = "\n"/*..string.rep(" ",)*/;
				
				for uid, v in pairs( TERRITORY:GetOwners() ) do table.insert( tOwnerNames, v.name.." ("..string.Replace(v.sid, "STEAM_", "")..")" ) end;
				for uid, v in pairs( TERRITORY:GetCoOwners() ) do table.insert( tCoOwnerNames, v.name.." ("..string.Replace(v.sid, "STEAM_", "")..")" ) end;
				
				local sOwners, sCoOwners = "", "";
				local bCanOwning, bOwned = TERRITORY("forsale", false), TERRITORY:IsOwned();
				local nOwnerLevel = TERRITORY:GetOwnerLevel(gc.Client);

				if (bOwned) then
					sOwners = table.concat( tOwnerNames, space );
					sCoOwners = table.concat( tCoOwnerNames, space );
					//sOwners = (sOwners == "" and "пусто..." or sOwners);
					//sCoOwners = (sCoOwners == "" and "пусто..." or sCoOwners);
					bCanOwning = false;
				end;
				
				local BLOCK = AddTitle( "Информация о текущем расположении", cTitleColor, "");
				local BLOCK = AddTitle( TERRITORY:Name().." ("..TERRITORY:UniqueID()..")", Color(255,255,255), TERRITORY("desc", "Без описания."), true, nil, true);
				BLOCK:TurnToogle();

				if (bOwned) then
					w = (w/2) - BlockMenu.Padding/2;

					local BLOCK = AddTitle( "Владельцы:", Color(255,255,255), sOwners, false, false, true);
					BLOCK.Title:Center();
					BLOCK.turnOffW, BLOCK.turnOnW = w, w;
					BLOCK:TurnToogle();
					
					local BLOCK = AddTitle( "Совладельцы:", Color(255,255,255), sCoOwners, false, false, true);
					BLOCK.Title:Center();
					BLOCK.turnOffW, BLOCK.turnOnW = w, w;
					BLOCK:TurnToogle();

					w = BlockMenu:GetWide() - (BlockMenu.Padding*2);
				end;

				if ( !bCanOwning and TERRITORY("lastBuyType") == "rent" ) then
					local BLOCK = AddTitle( "#Rent", cTitleColor6);
					function BLOCK.Title:Think()
						local text = (nOwnerLevel > 1 and "До продления аренды: " or "Срок аренды: ")..greenCode.kernel:ConvertTime( math.ceil(TERRITORY("_rent", 0) - CurTime() - 1) );

						if ( nOwnerLevel > 1 ) then
							text = text .. " | " .. " Цена: "..greenCode.kernel:FormatNumber(TERRITORY:GetPrice("rent")).."$";
						end;

						self:SetText(text);
						self:SizeToContents();
						self:Center();
					end;
				end;
				
				if ( nOwnerLevel > 0 or bCanOwning ) then
					AddTitle( "Действия", cTitleColor2 );

					-- Buy
					if ( bCanOwning ) then
						for k, v in SortedPairs(TER_ONW.class, true) do
							local BLOCK = BlockMenu:AddItem{ color = Color(0,0,0), h = 28, w = w,
								callback = function( BLOCK ) 
									Derma_Query("Вы уверены, что хотите "..v.desc.."?", "Внимание",
												"Да", function() RunConsoleCommand("gc_ter_buy", TERRITORY:UniqueID(), k ) end,
												"Нет", function() end)
								end,
							};
							CMENU_PLUGIN:ApplyTemplate( BLOCK, "simple", { color = cTitleColor3, title = "", desc = "" });
							BLOCK.Title:SetFont("ChatFont");
							BLOCK.Title:SetExpensiveShadow(2, Color(0,0,0,100));
							
							function BLOCK.Title:Think()
								self:SetText(v.desc..": "..greenCode.kernel:FormatNumber(TERRITORY:GetPrice(k))..v.cur);
								self:SizeToContents();
							end;
						end;
					end;

					if ( nOwnerLevel > 0 ) then
						-- Allow to spawn.
						local BLOCK = BlockMenu:AddItem{ color = Color(0,0,0), h = 30, w = w, callback = function( BLOCK )
							local menu = DermaMenu();
							for k, v in pairs(_player.GetAll()) do
								local uid = tonumber(v:UniqueID());

								if ( TERRITORY:GetOwnerLevel(v) > 0 or TERRITORY("propSpawn", {})[uid] ) then
									continue;
								end;

								menu:AddOption(v:Name(), function() RunConsoleCommand("gc_ter_allowspawn", tostring(TERRITORY:UniqueID()), uid, 1) end)
							end;
							menu:AddOption("Отмена");
							menu:Open();

						end};
						CMENU_PLUGIN:ApplyTemplate( BLOCK, "simple", { color = cTitleColor4, title = "Разрешить спавн объектов", desc = "" });
						BLOCK.Title:Center();

						-- Denny to spawn.
						local BLOCK = BlockMenu:AddItem{ color = Color(0,0,0), h = 30, w = w, callback = function( BLOCK )
							local menu = DermaMenu();
							for k, v in pairs(TERRITORY("propSpawn", {})) do
								menu:AddOption(v, function() RunConsoleCommand("gc_ter_allowspawn", tostring(TERRITORY:UniqueID()), k, "0") end)
							end;
							menu:AddOption("Отмена");
							menu:Open();

						end};
						CMENU_PLUGIN:ApplyTemplate(BLOCK, "simple", { color = cTitleColor5, title = "Запретить спавн объектов", desc = "" });
						BLOCK.Title:Center();
					end;

					if ( nOwnerLevel > 1 ) then
						-- Add Co Own
						local BLOCK = BlockMenu:AddItem{ color = Color(0,0,0), h = 30, w = w, callback = function( BLOCK )
							local menu = DermaMenu();
							for k, v in pairs(_player.GetAll()) do
								if ( TERRITORY:GetOwnerLevel(v) > 0 ) then
									continue;
								end;
								
								local uid = tonumber(v:UniqueID());

								menu:AddOption(v:Name(), function() RunConsoleCommand("gc_ter_allowcoown", tostring(TERRITORY:UniqueID()), uid, 1) end)
							end;
							menu:AddOption("Отмена");
							menu:Open();

						end};
						CMENU_PLUGIN:ApplyTemplate( BLOCK, "simple", { color = cTitleColor4, title = "Добавить в совладельцы", desc = "" });
						BLOCK.Title:Center();
						
						-- Remove Co Own
						local BLOCK = BlockMenu:AddItem{ color = Color(0,0,0), h = 30, w = w, callback = function( BLOCK )
							local menu = DermaMenu();
							for k, v in pairs(TERRITORY("coowner", {})) do
								menu:AddOption(v.name, function() RunConsoleCommand("gc_ter_allowcoown", tostring(TERRITORY:UniqueID()), k, "0") end)
							end;
							menu:AddOption("Отмена");
							menu:Open();

						end};
						CMENU_PLUGIN:ApplyTemplate(BLOCK, "simple", { color = cTitleColor5, title = "Убрать из совладельцев", desc = "" });
						BLOCK.Title:Center();
						
						-- Sell
						local BLOCK = BlockMenu:AddItem{ color = Color(0,0,0), h = 35, w = w, callback = function( BLOCK )
							local nPriceType = TERRITORY("lastBuyType", "session");
							local nAmount = math.ceil(TERRITORY:GetPrice(nPriceType)/2);
							local cur = TER_ONW.class[nPriceType].cur;
							local sWarning = TER_ONW:HoldingCount( gc.Client ) < 2 and "Внимание! После продажи у вас не будет дома, а значит вы потеряете профессию.\n\n" or "";
							
							Derma_Query(sWarning.."При продаже, вы получите: "..greenCode.kernel:FormatNumber(nAmount)..cur.."\nВы согласны?", "Внимание",
										"Да", function() RunConsoleCommand("gc_ter_sell", TERRITORY:UniqueID() ) end,
										"Нет", function() end)
						end };
						CMENU_PLUGIN:ApplyTemplate( BLOCK, "simple", { color = cTitleColor3, title = "Продать", desc = [[При продаже территории, вы получите 50% от её стоимости и
							типа покупки.]] });
						BLOCK:TurnToogle();
					end;
				end;
			end;
		end;
	end;
}:Register();