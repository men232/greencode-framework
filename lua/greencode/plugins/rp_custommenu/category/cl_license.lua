--[[
	© 2013 GmodLive private project do not share
	without permission of its author (Andrew Mensky vk.com/men232).
--]]
local greenCode = greenCode;
local gc = gc;
local math = math;
local table = table;
local CMENU_PLUGIN;
local LICENSE_PLUGIN;

local cBGColor = Color(0,0,0);
local cMainTitle = Color(222,222,81);
local cTitleColor = Color(81,222,81);
local cNormalColor = Color(225,243,253);
local cBadColor = Color(132,132,132);
local BlockMenu;
local w;

local function GiveLicense( player,  sLicense )
	local bHasLicense, bLicenseByJob = player:HasLicense(sLicense);
	
	local menu = DermaMenu();
	
	if ( bLicenseByJob == true ) then
		menu:AddOption("Эта лицензия предоставлена профессией.", function() end);
	else
		menu:AddOption( bHasLicense and "Забрать" or "Выдать", function() RunConsoleCommand("gc_setlicense", tostring(player:Name()), sLicense, tostring(!bHasLicense)); end);
		menu:AddOption("Отмена", function() end);
	end;
	
	menu:Open();
end;

local tPlayerList = {};

local function AddLicense( player, bCanGiveLicense )
	local BLOCK = BlockMenu:AddItem{ color = Color(0,0,0), h = 35, w = w };
	local cColor = team.GetColor(player:Team());
	local bPublishLicense = player:IsPublishLicense()
	cColor = Color(cColor.r+100, cColor.g+100,cColor.b+100);
	CMENU_PLUGIN:ApplyTemplate( BLOCK, "simple", { color = cColor, title = player:Name()..(!bPublishLicense and " (Скрыто)" or ""), desc = "" });
	BLOCK.Title:Center();
	BLOCK:SetDisabled(true);

	tPlayerList[player] = bPublishLicense;

	if ( player != gc.Client and !bPublishLicense and !bCanGiveLicense ) then
		return;
	end;
	
	for uid, tLicense in pairs( LICENSE_PLUGIN.stored ) do
		local BLOCK = BlockMenu:AddItem{ color = Color(0,0,0), h = 25, w = w,
			callback = bCanGiveLicense and function() GiveLicense( player, uid ) end};
		CMENU_PLUGIN:ApplyTemplate( BLOCK, "simple", { 
			color = cTitleColor,
			title = tLicense.description,
			desc = ""
		});
		BLOCK:SetDisabled(!bCanGiveLicense);
		BLOCK.Title:SetFont("ChatFont");
		BLOCK.Title:SizeToContents("ChatFont");
		BLOCK.Title:SetExpensiveShadow(2, Color(0,0,0,100));
		BLOCK.Title:Center();
		
		function BLOCK.Title:Think()
			local bHaveLicense = player:HasLicense(uid);
			self:SetColor( bHaveLicense and cNormalColor or cBadColor );
		end;
	end;
end;

CMENU_LICENSE_CATEGORY = CM_CAT_CLASS:New{
	title = "Лицензии",
	priority = 4,
	callback = function()
		CMENU_PLUGIN = greenCode.plugin:Get("rp_custommenu");
		local bTextMenu, bBlockMenu = CMENU_PLUGIN:IsOpen();
		
		BlockMenu = CMENU_PLUGIN.BlockMenu;
		w = BlockMenu:GetWide() - (BlockMenu.Padding*2);
		
		if ( bBlockMenu ) then
			BlockMenu:Clear( 0.4 );
			
			LICENSE_PLUGIN = greenCode.plugin:FindByID("rp_license");
			local bAdmin = gc.Client:IsAdmin();
			
			local BLOCK = BlockMenu:AddItem{ color = Color(0,0,0), h = 35, w = w, callback = function( BLOCK ) BLOCK:TurnToogle(); end };
			CMENU_PLUGIN:ApplyTemplate( BLOCK, "simple", {
				color = cMainTitle,
				title = "Что такое лицензии?",
				desc = [[Лицензии позволяют совершать различные действия.
				Выполняя действия без лицензии, вы можете попасть в тюрьму.
				
				Некоторые лицензии предоставляются профессиями по умолчанию и
				не могут быть отняты.
				
				Выдача лицензий очень ответственный шаг, отнеситесь к этому с
				полной серьёзностью, иначе вы можете быть наказаны..
				
				Для того чтобы выдать иди отобрать лицензию, подойдите к игроку.

				Также, вы можете скрыть свои лицензии по своим нуждам, для этого
				используйте кнопку ниже.
				]]
			});

			local bPublishLicense = gc.Client:IsPublishLicense();
			BLOCK.btn1 = xlib.makebutton{x = 0, y = 0, w = 200, h = 20, label = (bPublishLicense and "Скрыть лицензии <от всех>" or "Показать лицензии <для всех>"), parent = BLOCK};
			BLOCK.btn1:SetSkin("DarkRP");

			function BLOCK.btn1:DoClick()
				local callback = CMENU_LICENSE_CATEGORY:GetCallBack();
				RunConsoleCommand("gc_showlicense");
			end;

			BLOCK:TurnToogle();
			BLOCK.Title:Center();
			BLOCK:SetTall( BLOCK.turnOnH );
			BLOCK.btn1:SetPos( BLOCK:GetWide() - 205, BLOCK:GetTall()-25 );
			
			local bCanGiveLicense = table.HasValue( LICENSE_PLUGIN.canChangeLicense, gc.Client:Team() ) or bAdmin;
			local bCP = gc.Client:IsCP();
			tPlayerList = {};

			AddLicense( gc.Client, bAdmin );
			
			for _, player in pairs(_player.GetAll()) do
				if ( player != gc.Client ) then
					if ( bCanGiveLicense or (bCP and player:IsCP()) or gc.Client:GetShootPos():Distance(player:GetShootPos()) <= 150 ) then
						AddLicense( player, bCanGiveLicense );
					end;
				end;
			end;

			function BLOCK.Title:Think()
				local curTime = CurTime();

				if ( !self.LastUpdate ) then
					self.LastUpdate = curTime + 5;
				end;

				if ( self.LastUpdate < curTime ) then
					local bCanGiveLicense = table.HasValue( LICENSE_PLUGIN.canChangeLicense, gc.Client:Team() ) or bAdmin;

					if ( !bCanGiveLicense ) then
						for _, player in pairs(_player.GetAll()) do
							if ( player != gc.Client ) then
								local bShouldUpdate = false;
								local bHasPlayer = tPlayerList[player] != nil;
								local bRihgtDistance = gc.Client:GetShootPos():Distance(player:GetShootPos()) <= 150;

								if ( bHasPlayer != bRihgtDistance ) then
									bShouldUpdate = true;
								elseif bHasPlayer and tPlayerList[player] != player:IsPublishLicense() then
									bShouldUpdate = true;
								end;

								if ( bShouldUpdate ) then
									local callback = CMENU_LICENSE_CATEGORY:GetCallBack();
									callback();
									break;
								end;
							end;
						end;
					end;

					self.LastUpdate = nil;
				end;
			end;
		end;
	end;
}:Register();