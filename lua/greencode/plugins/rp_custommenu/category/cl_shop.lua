--[[
	© 2013 GmodLive private project do not share
	without permission of its author (Andrew Mensky vk.com/men232).
--]]
local greenCode = greenCode;
local gc = gc;
local math = math;
local table = table;
local CMENU_PLUGIN;

local cBGColor = Color(0,0,0);
local cNormalColor = Color(81,222,81);
local cBadColor = Color(222,81,81);
local cTitleColor = Color(81,222,81);
local cBlackShopTitle = Color(222,81,81);
local cMainTitle = Color(222,222,81);
local BlockMenu;
local w;

local userSmallIcon = CreateClientConVar( "cl_gc_cshop_smallicon", 0, true );
local bUseSmallIcon = userSmallIcon:GetBool();

local function AddCat( sName, cColor )
	local BLOCK = BlockMenu:AddItem{ color = Color(0,0,0), h = 40, w = w };
	CMENU_PLUGIN:ApplyTemplate( BLOCK, "simple", { color = cColor, title = sName, desc = "" });
	BLOCK:SetDisabled( true );
	BLOCK.Title:Center();
	return BLOCK;
end;

local function AddItem( CSHOP_ITEM, bIgnoreHide )
	local tAllowed = CSHOP_ITEM("allowed");
	local team = greenCode.Client:Team();
	local sLicense = CSHOP_ITEM("license");
	local sLicenseIgnore = CSHOP_ITEM("licIgnore");
	
	if ( tAllowed and type(tAllowed) != "table" ) then tAllowed = { tAllowed } end;
	
	if ( (!bIgnoreHide and CSHOP_ITEM("hide")) or tAllowed and !table.HasValue(tAllowed, team) ) then
		return;
	end;
	
	if ( (sLicense and !gc.Client:HasLicense(sLicense)) or ( sLicenseIgnore and gc.Client:HasLicense(sLicenseIgnore) ) ) then
		return;
	end;

	local size = BlockMenu.RecomendSize[6];

	local fTurn = function( BLOCK ) BLOCK:TurnToogle(); end;
	local fBuy = function( BLOCK ) RunConsoleCommand("gc_buy_item", CSHOP_ITEM:UniqueID()); end;
	
	if ( CSHOP_ITEM and CSHOP_ITEM:IsValid() ) then
		local BLOCK = BlockMenu:AddItem{ 
			color = Color(0,0,0),
			h = bUseSmallIcon and size or 62,
			w = bUseSmallIcon and size or w,

			callback = fBuy,
			callback2 = bUseSmallIcon and fTurn or nil,
		};
		
		CMENU_PLUGIN:ApplyTemplate( BLOCK, "simple", {
			mdl = CSHOP_ITEM:GetModel(),
			color = cNormalColor,
			title = CSHOP_ITEM:Name(),
			desc = CSHOP_ITEM("description", "")
		});

		if ( bUseSmallIcon ) then
			BLOCK.Icon:SetPos(5,5);
			BLOCK.Icon:SetSize( BLOCK:GetWide()-10, BLOCK:GetTall()-10 );
		end;
		
		function BLOCK.Title:Think()
			local sTitle = CSHOP_ITEM:Name().." - "..CSHOP_ITEM("cur", "$")..gc.kernel:FormatNumber(CSHOP_ITEM:GetPrice());
			self:SetText( sTitle );
			BLOCK.Icon:SetToolTip(sTitle..(bUseSmallIcon and "\nПКМ - Развернуть/Свернуть" or ""));
			self:SizeToContents();
		end;
		
		BLOCK:SetWide( math.Max( BLOCK:GetWide(), BLOCK.turnOnH ) );

		BLOCK.deployed = !bUseSmallIcon;
		
		BLOCK.turnOnW = w;
		BLOCK.turnOnH = math.Max( BLOCK:GetTall(), BLOCK.turnOnH );

		BLOCK.turnOffW = size;
		BLOCK.turnOffH = size;
		
		return BLOCK;
	end;
end;

CMENU_SHOP_CATEGORY = CM_CAT_CLASS:New{
	title = "Магазин",
	priority = 3,
	callback = function()
		CMENU_PLUGIN = greenCode.plugin:Get("rp_custommenu");
		local bTextMenu, bBlockMenu = CMENU_PLUGIN:IsOpen();
		local args = CMENU_PLUGIN.args;
		
		BlockMenu = CMENU_PLUGIN.BlockMenu;
		w = BlockMenu:GetWide() - (BlockMenu.Padding*2);
		
		if ( bBlockMenu ) then
			BlockMenu:Clear( 0.4 );
			
			local CSHOP_PLUGIN = greenCode.plugin:FindByID("rp_customshop");
			local tBlackShop = {};
			local tCatFilter;
			
			if ( args[3] and args[3] != "" ) then
				tCatFilter = string.Explode(",", args[3]);
			end;
			
			if ( !tCatFilter ) then
				local BLOCK = BlockMenu:AddItem{ color = Color(0,0,0), h = 35, w = w, callback = function( BLOCK ) BLOCK:TurnToogle(); end };
				CMENU_PLUGIN:ApplyTemplate( BLOCK, "simple", {
					color = cMainTitle,
					title = "Добро пожаловать в магазин",
					desc = [[Здесь вы можете заказать товары для себя, либо для продажи.
					Заказывать и продавать товары можно, лишь имея на это лицензию.
					
					Зеленый цвет заголовка указывает на то, что у вас есть лицензия
					на данный тип товара.
					
					Красный заголовок указывает на то, что товары из данной категории
					буду приобретены нелегально и по 2x цене.
					
					Для получения лицензии, обратитесь к шерифу или меру города.
					Чтобы узнать наличие лицензии, перейдите в категорию "Лицензии".

					]]
				});

				bUseSmallIcon = userSmallIcon:GetBool();

				BLOCK.btn1 = xlib.makebutton{x = BLOCK:GetWide() - 205, y = 185, w = 200, h = 20, label = "Использовать "..(bUseSmallIcon and "крупные" or "мелкие").." значки", parent = BLOCK};
				BLOCK.btn1:SetSkin("DarkRP");

				function BLOCK.btn1:DoClick()
					local callback = CMENU_SHOP_CATEGORY:GetCallBack();
					RunConsoleCommand("cl_gc_cshop_smallicon", !userSmallIcon:GetBool() and 1 or 0);
					RunConsoleCommand("cl_gc_custommenu_update", 25772);
				end;

				BLOCK:TurnToogle();
				BLOCK.Title:Center();
				BLOCK:SetTall( BLOCK.turnOnH );
			end;
			
			for catName, v in pairs(CSHOP_PLUGIN:SortItems()) do				
				if ( tCatFilter and !table.HasValue( tCatFilter, greenCode.kernel:GetShortCRC(catName) ) ) then
					continue;
				end;
				
				if (string.find(catName, "Черный рынок")) then
					tBlackShop[catName] = v;
					continue;
				end;
				
				local BLOCK = AddCat( catName, cTitleColor );
				local bAdd = false;
				
				for _, CSHOP_ITEM in pairs(v) do										
					if AddItem( CSHOP_ITEM, tCatFilter ) then
						bAdd = true;
					end;
				end;
				
				if ( !bAdd ) then BlockMenu:RemoveItem( BLOCK ); end;
			end;
			
			if (tCatFilter) then
				return;
			end;
			
			for catName, v in pairs(tBlackShop) do
				local BLOCK = AddCat( catName, cBlackShopTitle );
				local bAdd = false;
				
				for _, CSHOP_ITEM in pairs(v) do
					if AddItem( CSHOP_ITEM ) then
						bAdd = true;
					end;
				end;
				
				if ( !bAdd ) then BlockMenu:RemoveItem( BLOCK ); end;
			end;
		end;
	end;
}:Register();