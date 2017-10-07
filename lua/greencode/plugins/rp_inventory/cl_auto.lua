--[[
	© 2013 gmodlive.com commissioned by Leonid Sahnov
	private source
--]]

local PLUGIN = PLUGIN or greenCode.plugin:Loader();
PLUGIN.stored = {};
PLUGIN.buffer = {};

local greenCode    = greenCode;
local gc           = gc;
local math         = math;
local CMENU_PLUGIN = greenCode.plugin:Get("rp_custommenu");

local cBGColor     = Color(0,0,0);
local cNormalColor = Color(81,222,81);
local cBadColor    = Color(222,81,81);
local cMainTitle   = Color(222,222,81);

local basic_callback = function( BLOCK ) BLOCK:TurnToogle(); end;
local basic_open_block = function( BLOCK ) BLOCK:TurnToogle(); BLOCK:SetTall( BLOCK.turnOnH ); end;

-- A function to swat two block in BlockMenu
local function SwapBlock(BlockMenu, oldId, newId)
	local t = BlockMenu.Items[newId];
	BlockMenu.Items[newId] = BlockMenu.Items[oldId];
	BlockMenu.Items[oldId] = t;
end;

-- Basic item action callback
local function own_item_action(BLOCK)
	local item = BLOCK.item;
	local count = item:IsStackable() and 1 or BLOCK.item_index;

	-- Quick function
	if (input.IsKeyDown(KEY_LALT)) then
		RunConsoleCommand("gc_inv_drop", item:UniqueID(), count);
		return;
	elseif (input.IsKeyDown(KEY_LCONTROL)) then
		RunConsoleCommand("gc_inv_drop", item:UniqueID(), count, 1);
		return;
	end;

	-- Menu
	local menu = DermaMenu();
	menu:AddOption("Использовать", function() RunConsoleCommand("gc_inv_drop", item:UniqueID(), 1, 1); end);
	menu:AddOption("Выбросить", function()
		if (item:IsStackable()) then
			if (count < 2) then
				RunConsoleCommand("gc_inv_drop", item:UniqueID(), 1);
			else
				Derma_StringRequest("Количество", "Сколько вы хотите выбросить?", "", function(a)
					local count = tonumber(a);
					if (count > 0) then
						RunConsoleCommand("gc_inv_drop", item:UniqueID(), count);
					end;
				end);
			end;
		else
			RunConsoleCommand("gc_inv_drop", item:UniqueID(), BLOCK.item_index);
		end;
	end);
	menu:AddOption("Отмена", function() end);
	menu:Open();
end;

-- A function to find id by block table
local function find_block_id(BlockMenu, BLOCK)
	for i=1, #BlockMenu.Items do
		if (!ID and tostring(BLOCK) == tostring(BlockMenu.Items[i])) then
			return i;
		end;
	end;

	return 0;
end;

-- Basic display item
local function DisplayItem(BlockMenu, inventory, item, count, start_id, callback, tUserData)
	-- Data
	local size = BlockMenu.RecomendSize[6];
	local uid = item:UniqueID();
	local bStackable = item:IsStackable();
	local w = BlockMenu:GetWide() - (BlockMenu.Padding*2);
	local mID = start_id;

	-- A function to open item and swith to first position
	local function to_one_callback(BLOCK)
		-- Find ID
		local ID = find_block_id(BlockMenu, BLOCK);

		for i=mID, #BlockMenu.Items do
			local BLOCK = BlockMenu.Items[i];

			if (ID != il) then
				BLOCK.off = false;
			end;

			if (BLOCK.deployed && ID != i) then
				BLOCK:TurnOff();
				BLOCK:SetWidth( BLOCK.turnOffW );
				BLOCK.CountTitle:SetPos(5,BLOCK.idealH-15);
				BLOCK.off = true;
			end;

			if (BLOCK.PREV_ID) then
				SwapBlock(BlockMenu, i, BLOCK.PREV_ID);
				BLOCK.PREV_ID = nil;
				i = i - 1;
				continue;
			end;
		end;

		BlockMenu.Items[mID].off = false;

		ID = find_block_id(BlockMenu, BLOCK);

		if (!BLOCK.off) then
			SwapBlock(BlockMenu, ID, mID);
			BlockMenu.Items[mID].PREV_ID = ID;
			BlockMenu.Items[ID].PREV_ID = mID;

			BLOCK:TurnToogle();
			BLOCK:SetSize(BLOCK.idealW, BLOCK.idealH);
			BLOCK.CountTitle:SetPos(5,BLOCK.idealH-15);
		end;

		BLOCK.off = false;
		BlockMenu:Rebuild();
	end;

	-- Create basic blcok
	local BLOCK = BlockMenu:AddItem{ color = item:GetColor(), h = size, w = size,
		callback = callback,
		callback2 = to_one_callback,
	};

	CMENU_PLUGIN:ApplyTemplate( BLOCK, "simple", {
		mdl   = item:GetModel(tUserData),
		color = cNormalColor,
		title = item:GetName(tUserData),
		desc  = item:GetDescription(tUserData),
	});

	BLOCK.Icon:SetPos(5,5);
	BLOCK.Icon:SetSize(BLOCK:GetWide()-10, BLOCK:GetTall()-10);

	BLOCK.CountTitle = xlib.makelabel{ parent = BLOCK, x = 5, y = BLOCK.idealH-15,
		label = "x"..(bStackable and count or 1),
		font = "Trebuchet16",
		textcolor = Color(255,255,255)
	};

	-- Size
	BLOCK.turnOnW = w;
	BLOCK.turnOnH = math.Max(BLOCK:GetTall(), BLOCK.turnOnH);

	BLOCK.turnOffW = size;
	BLOCK.turnOffH = size;

	BLOCK.item = item;
	BLOCK.inventory = inventory;
	BLOCK.item_index = !bStackable and count or nil;

	-- Subscribe update
	local org_think = BLOCK.Think;
	function BLOCK:Think()
		org_think(BLOCK);

		-- Remove
		if (!inventory or !inventory:IsExist(uid, self.item_index)) then
			local ID = find_block_id(BlockMenu, self);
			BlockMenu:RemoveItem(ID, 0.4);
			self.CountTitle:SetText("x0");
		elseif (bStackable) then
			self.Count = inventory:GetItemsCount(uid);
			self.CountTitle:SetText("x"..self.Count);
			self.CountTitle:SizeToContents();
		end;
	end;
end;

-- Basic display inventory
local function DisplayInventory(BlockMenu, inventory, item_callback, start_id, bHideSupport)
	local owner = inventory:GetOwner();
	local sOwnerName = (owner.GetName and owner:GetName()) or (owner.GetTitle and owner:GetTitle()) or owner.PrintName or "Some Prop";
	local w = BlockMenu:GetWide() - (BlockMenu.Padding*2);
	start_id = start_id or 2;

	-- Title
	local cColor = owner:IsPlayer() and team.GetColor(owner:Team()) or cMainTitle;

	local BLOCK = BlockMenu:AddItem{ color = cBGColor, h = 35, w = w, callback = !bHideSupport and basic_callback };
	CMENU_PLUGIN:ApplyTemplate( BLOCK, "simple", {
		color = cColor,
		title = "Инвентарь: ["..sOwnerName.."]",
		desc = [[В этом меню, Вы можете манипулировать инвентарем. Здесь
		Будут отображены все ваши вещи и данные о весовом перегрузе.

		За кол-во переносимого веса, отвечает атрибут "Сила".

		ЛКМ - Выбор действия.
		ПКМ - Подробно о предмете.

		Используйте зажатый [ALT + ЛКМ] для быстрого выброса предмета.
		Используйте зажатый [CTRL + ЛКМ] для быстрого использования.
		]],
	});
	BLOCK.Title:Center();

	if (!bHideSupport) then
		basic_open_block(BLOCK);
	else
		BLOCK:SetDisabled(true);
	end;

	-- Items
	for uid, data in pairs(inventory:GetItems()) do
		local item = PLUGIN:FindByID(uid);

		if (not item) then 
			print("Skip display item (Item not Registred): "..uid);
			continue;
		end;

		if (type(data) == "table") then
			for index, tUserData in pairs(data) do
				DisplayItem(BlockMenu, inventory, item, index, start_id, item_callback, tUserData);
			end;
		else
			local count = data;
			DisplayItem(BlockMenu, inventory, item, count, start_id, item_callback);
		end;
	end;

	-- Update information
	function BLOCK.Title:Think()
		local tList = {};

		for i=start_id, #BlockMenu.Items do
			if (not BlockMenu.Items[i].item) then continue end;
			local index = BlockMenu.Items[i].item_index or "";
			tList[tostring(BlockMenu.Items[i].item("uid"))..index] = true;
		end;

		for uid, data in pairs(inventory:GetItems()) do
			local item = PLUGIN:FindByID(uid);

			if (type(data) == "table") then
				for index, tUserData in pairs(data) do
					if (not tList[tostring(uid)..index]) then
						DisplayItem(BlockMenu, inventory, item, index, start_id, item_callback, tUserData);
					end;
				end;
			else
				local count = data;
				if (not tList[tostring(uid)]) then
					DisplayItem(BlockMenu, inventory, item, count, start_id, item_callback);
				end;
			end;
		end;
	end;
end;

-- Registration own inventory category
CMENU_ATTR_CATEGORY = CM_CAT_CLASS:New{
	title = "Инвентарь",
	priority = 3,
	hide = false,
	callback = function(CM_CATEGORY, CMENU_PLUGIN, BlockMenu, bTextMenu, bBlockMenu)
		-- Clear old data
		BlockMenu:Clear(0.4);

		local inventory = gc.Client:GetInventory();
		DisplayInventory(BlockMenu, inventory, own_item_action);
	end,
}:Register();

-- Registration transfer inventory category
CMENU_ATTR_CATEGORY = CM_CAT_CLASS:New{
	title = "Инвентарь #Transfer",
	priority = 3,
	hide = true,
	callback = function(CM_CATEGORY, CMENU_PLUGIN, BlockMenu, bTextMenu, bBlockMenu)
		-- Clear old data
		local ResearchMenu = vgui.Create("gcBlockMenu", CMENU_PLUGIN.TextMenu);
		BlockMenu:Clear(0.4);

		local _orgClose = BlockMenu.Close;
		function BlockMenu:Close()
			ResearchMenu:Close();
			_orgClose(self);
		end;

		ResearchMenu.x = BlockMenu.x - 402;

		-- Display own inventory
		local inventory = gc.Client:GetInventory();
		local rm_inventory = gc.Client.gcInventoryResearch;

		if (not rm_inventory or not inventory) then
			return;
		end;

		local _orgThink = ResearchMenu.Think;
		local rm = false;
		function ResearchMenu:Think()
			if (not rm and (not rm_inventory or not IsValid(rm_inventory:GetOwner()) or not inventory)) then
			 	CMENU_PLUGIN:Close(); rm = true;
			 end;
			 
			_orgThink(ResearchMenu);
		end;

		DisplayInventory(ResearchMenu, rm_inventory, function(BLOCK)
			local rm_entity = gc.Client.gcInventoryResearch:GetOwner();
			local item = BLOCK.item;

			RunConsoleCommand("gc_inv_put", rm_entity:EntIndex(),
				item:UniqueID(), (BLOCK.item_index or 1));
		end, nil, true, 1);

		DisplayInventory(BlockMenu, inventory, function(BLOCK)
			local rm_entity = gc.Client.gcInventoryResearch:GetOwner();
			local item = BLOCK.item;

			RunConsoleCommand("gc_inv_put", rm_entity:EntIndex(), item:UniqueID(),
				(BLOCK.item_index or 1), 1);
		end, nil, true);

	end,
}:Register();