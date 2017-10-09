--[[
	© 2013 GmodLive private project do not share
	without permission of its author (Andrew Mensky vk.com/men232).
--]]

local CMENU_PLUGIN = greenCode.plugin:Get("rp_custommenu");
local TER_ONW;

local function ChangeJob( command, special, specialcommand )
	local menu = DermaMenu();
	
	if special then
		menu:AddOption("Голосовать", function() gc.Client:ConCommand("darkrp "..command); CMENU_PLUGIN:Close(); end)
		menu:AddOption("Без голосования", function() gc.Client:ConCommand("darkrp " .. specialcommand); CMENU_PLUGIN:Close(); end)
	else
		menu:AddOption("Сменить", function() gc.Client:ConCommand("darkrp " .. command); CMENU_PLUGIN:Close(); end)
	end;
	menu:AddOption("Отмена", function() end);
	menu:Open()
end;

CMENU_JOBS_CATEGORY = CM_CAT_CLASS:New{
	title = "Профессии",
	priority = 2,
	callback = function()
		CMENU_PLUGIN = greenCode.plugin:Get("rp_custommenu");
		local bTextMenu, bBlockMenu = CMENU_PLUGIN:IsOpen();
		local BlockMenu = CMENU_PLUGIN.BlockMenu;
		local w = BlockMenu:GetWide() - (BlockMenu.Padding*2);
		
		if ( bBlockMenu ) then
			BlockMenu:Clear( 0.4 );
			
			TER_ONW = TER_ONW or greenCode.plugin:Get("ter_owning");
			
			if ( TER_ONW:HoldingCount( gc.Client ) < 1 ) then
				local BLOCK = BlockMenu:AddItem{ color = Color(0,0,0), h = 35, w = w };
				CMENU_PLUGIN:ApplyTemplate( BLOCK, "simple", {
					color = Color(200,0,0),
					title = "Внимание",
					desc = greenCode.kernel:TextWarp("Для того, чтобы выбрать другие профессии Вам необходимо купить дом или торговую точку (для торговца/повара). Покупку можно осуществить через F4 -> Территории в момент нахождения на оной одним из 3-х способов оплаты. Только после покупки жилья или магазина Вам откроется доступ к списку профессий и их выбору. Заметьте, что при продаже единственной территории Вы будете сняты с занимаемой должности и снова станете обычным гражданином.", w-20, "Default"),
				});

				BLOCK:TurnToogle();
				BLOCK:SetDisabled(true);
			end;
			
			for k, v in ipairs(RPExtraTeams) do
				if gc.Client:Team() == k or !GAMEMODE:CustomObjFitsMap(v) then
					continue;
				elseif v.admin == 1 and not gc.Client:IsAdmin() then
					continue;
				elseif v.admin > 1 and not gc.Client:IsSuperAdmin() then
					continue;
				elseif v.customCheck and not v.customCheck(gc.Client) then
					continue;
				elseif (type(v.NeedToChangeFrom) == "number" and gc.Client:Team() ~= v.NeedToChangeFrom) or (type(v.NeedToChangeFrom) == "table" and not table.HasValue(v.NeedToChangeFrom, gc.Client:Team())) then
					continue;
				end
				
				local BLOCK = BlockMenu:AddItem{ 
					color = Color(0,0,0),
					h = 62,
					w = w,
					
					callback = function( BLOCK ) BLOCK:TurnToogle() end,
					callback2 = function( BLOCK ) 
						if (not v.RequiresVote and v.vote) or (v.RequiresVote and v.RequiresVote(gc.Client, k)) then
							local condition = ((v.admin == 0 and gc.Client:IsAdmin()) or (v.admin == 1 and gc.Client:IsSuperAdmin()) or gc.Client.DarkRPVars["Priv"..v.command])
							ChangeJob("/vote"..v.command, condition, "/"..v.command)
						else
							ChangeJob("/"..v.command)
						end
					end,
				};
				
				local mdl = type(v.model) == "string" and v.model or v.model[math.random( 1, #v.model )];
				CMENU_PLUGIN:ApplyTemplate( BLOCK, "simple", { tooltip = "ЛКМ - Развернуть/Свернуть.\nПКМ - Действия.", mdl = mdl, color = Color( v.color.r+100, v.color.g+100,v.color.b+100 ), title = v.name, desc = v.description } );
				BLOCK.turnOnW = w;
			end;
		end;
	end;
}:Register();