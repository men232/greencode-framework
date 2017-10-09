--[[
	© 2013 GmodLive private project do not share
	without permission of its author (Andrew Mensky vk.com/men232).
--]]
local PLUGIN = PLUGIN or greenCode.plugin:Loader();

PLUGIN.AttributeList = {};

function PLUGIN:Add( attribute )
	table.insert( self.AttributeList, attribute );
end;

function PLUGIN:IsValid( attribute )
	return table.HasValue( self.AttributeList, attribute );
end

-- Called when a player's update attribute progress.
function PLUGIN:PlayerAttributeProgress(player, attributeTable, amount)
	if (attributeTable and self:IsValid(attributeTable.uniqueID) and IsValid(player)) then
		local progress = math.floor(amount * 100)/100;
		local negative = ( amount < 0 );
		if(!negative) then
			player:ShowAlert( "++ ".. progress .." Очков опыта: '" .. attributeTable.name .. "'.", Color(150, 255, 150, 255) );
		else
			player:ShowAlert( "- ".. progress .." Очков опыта: '" .. attributeTable.name .. "'.", Color(255, 150, 150, 255) );
		end;
	end;
end;

-- Called when a player's update attribute count.
function PLUGIN:PlayerAttributeUpdated(player, attributeTable, amount)
	if (attributeTable and IsValid(player) and amount) then
		local negative = ( amount < 0 );
		if(!negative) then
			player:ShowHint( "Повышение уровня атрибута '".. attributeTable.name .."'.", 5, nil );
		else
			player:ShowHint( "Понижение уровня атрибута '".. attributeTable.name .."'.", 5, nil );
		end;
	end;
end;

-- Called when DarkRp call AddMoney.
function PLUGIN:PlayerWalletChanged(player, amount)
	if (amount == nil) then return false end;
	
	if (amount > 0) then
		player:ShowAlert( "+ " .. greenCode.kernel:FormatNumber(amount) .. (CUR or "$") .. ".", Color(150, 255, 150, 255) );
	else
		player:ShowAlert( "- " .. greenCode.kernel:FormatNumber(amount*-1) .. (CUR or "$") .. ".", Color(255, 150, 150, 255) );
	end;
end;

PLUGIN:Add(ATB_LEVEL);
PLUGIN:Add(ATB_STRENGTH);
//PLUGIN:Add(ATB_STAMINA);
//PLUGIN:Add(ATB_AGILITY);
//PLUGIN:Add(ATB_ACROBATICS);