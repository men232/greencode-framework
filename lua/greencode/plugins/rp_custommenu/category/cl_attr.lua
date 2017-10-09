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

CMENU_ATTR_CATEGORY = CM_CAT_CLASS:New{
	title = "Атрибуты",
	priority = 10,
	callback = function()
		CMENU_PLUGIN = greenCode.plugin:Get("rp_custommenu");
		local bTextMenu, bBlockMenu = CMENU_PLUGIN:IsOpen();
		local BlockMenu = CMENU_PLUGIN.BlockMenu;
		
		if ( bBlockMenu ) then
			BlockMenu:Clear( 0.4 );
			
			local w = BlockMenu:GetWide() - (BlockMenu.Padding*2);
			
			local BLOCK = BlockMenu:AddItem{ color = cBGColor, h = 40, w = w };
			CMENU_PLUGIN:ApplyTemplate( BLOCK, "simple", { color = Color(178,183,213), title = "Атрибуты", desc = "" } );
			BLOCK:SetDisabled(true);
			BLOCK.Title:Center();
			
			for uid, attributeTable in pairs(greenCode.attribute:GetAll()) do
				local amount, progress = greenCode.attributes:Get(uid, true);
				amount, progress = amount or 0, progress or 0;
				local amountBoost = greenCode.attributes:Get(uid) or 0;
				
				local BLOCK = BlockMenu:AddItem{ color = cBGColor, h = 40, w = w, callback = function( BLOCK ) BLOCK:TurnToogle() end };
				CMENU_PLUGIN:ApplyTemplate( BLOCK, "simple", { color = cNormalColor, title = attributeTable.name..": "..amount, desc = attributeTable.description } );
				
				function BLOCK.Title:Think()
					amount, progress = greenCode.attributes:Get(uid, true);
					amount, progress = amount or 0, progress or 0;
					amountBoost = greenCode.attributes:Get(uid) or 0;
					
					if ( amount != amountBoost ) then
						BLOCK.bNegative = amount > amountBoost;
						local different = math.abs(amount - amountBoost);
						local color = BLOCK.bNegative and cBadColor or cNormalColor;
						
						self:SetText(attributeTable.name..": "..amount.." ("..(BLOCK.bNegative and "-" or "+")..different..")");
						self:SetColor(color);
						BLOCK.Bar.color = color;
					else
						self:SetText(attributeTable.name..": "..amount);
						self:SetColor(cNormalColor);
						BLOCK.Bar.color = cNormalColor;
					end;
					self:SizeToContents();
				end;
				
				BLOCK.Title:SetPos(10, 12);
				BLOCK.Desc:SetPos(10,39);
				BLOCK.turnOnH = BLOCK.Desc:GetTall() + 47;
				//BLOCK:SetDisabled(true);
				BLOCK:TurnToogle();
				
				BLOCK.Bar = vgui.Create("Panel", BLOCK);	
				BLOCK.Bar:SetSize(BLOCK:GetWide()-10, 5);
				BLOCK.Bar:SetPos(5, 5);
				BLOCK.Bar.value = 0;
				BLOCK.Bar.color = BLOCK.bNegative and cBadColor or cNormalColor;
				
				function BLOCK.Bar:Think()
					self.value = progress / 100;
				end;
				
				function BLOCK.Bar:Paint()
					local w, h = self:GetSize();
					draw.RoundedBox(0, 0, 0, w, h, cBGColor);
					draw.RoundedBox(0, 2, 2, (w-4)*self.value, h-4, self.color);
					surface.SetDrawColor(cBGColor);
					self:DrawOutlinedRect();
				end;
			end;
			
			local BLOCK = BlockMenu:AddItem{ color = cBGColor, h = 40, w = w };
			CMENU_PLUGIN:ApplyTemplate( BLOCK, "simple", { color = Color(224,229,251), title = "Активные эффекты", desc = "" } );
			BLOCK.Title:Center();
			BLOCK:SetDisabled(true);
			
			local tBoostInfo = {};
								
			for attribute, boosts in pairs(greenCode.attributes.boosts) do
				for name, boost in pairs(boosts) do					
					if ( !tBoostInfo[name] ) then
						tBoostInfo[name] = {};
					end;
					
					tBoostInfo[name][attribute] = boost
				end;
			end;
			
			for boostName, boosts in pairs(tBoostInfo) do
				local BLOCK = BlockMenu:AddItem{ color = cBGColor, h = 35, w = w, callback = function( BLOCK ) BLOCK:TurnToogle() end };
				local tDesc = {};
				local nValue = 0;
				local tempAtt = "";
				
				for attribute, boost in pairs(boosts) do
					local attributeName = greenCode.attribute:FindByID(attribute).name;
					tempAtt = attribute;
					BLOCK.endTime = boost.endTime;
					nValue = nValue + boost.amount;
					table.insert( tDesc, attributeName.." "..(boost.amount > 0 and "+" or "")..boost.amount );
				end;
				
				nValue = (nValue / #tDesc)/255;
				
				CMENU_PLUGIN:ApplyTemplate( BLOCK, "simple", { color = nValue < 0 and cBadColor or cNormalColor, title = boostName, desc = string.Implode("\n", tDesc) } );
				
				function BLOCK.Title:Think()
					local curTime = CurTime();
					
					if ( !(greenCode.attributes.boosts[tempAtt] or {})[boostName] and !BLOCK.Removed ) then
						BlockMenu:RemoveItem( BLOCK, 0.4 );
						BLOCK.Removed = true;
					end;
					
					if ( BLOCK.endTime ) then
						if ( !BLOCK.Removed and BLOCK.endTime < curTime ) then
							BlockMenu:RemoveItem( BLOCK, 0.4 );
							BLOCK.Removed = true;
						else
							self:SetText( boostName..": "..greenCode.kernel:ConvertTime( math.ceil(BLOCK.endTime - curTime) ) );
							self:SizeToContents();
						end;
					end;
				end;

				//BLOCK:SetDisabled(true);
				BLOCK:TurnToogle();
			end;
		end;
	end;
}:Register();