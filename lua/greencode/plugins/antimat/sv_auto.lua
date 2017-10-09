--[[
	© 2013 GmodLive private project do not share
	without permission of its author (Andrew Mensky vk.com/men232).
--]]

local PLUGIN = PLUGIN or greenCode.plugin:Loader();

PLUGIN.Words = {};

function PLUGIN:AddBadWord( word )
	table.insert(self.Words, word);
end;

PLUGIN:AddBadWord("ахует");
PLUGIN:AddBadWord("ахуен");
PLUGIN:AddBadWord("бля");
PLUGIN:AddBadWord("гандон");
PLUGIN:AddBadWord("гондон");
PLUGIN:AddBadWord("долбоёб");
PLUGIN:AddBadWord("дрочить");
PLUGIN:AddBadWord("драчить");
PLUGIN:AddBadWord("ебало");
PLUGIN:AddBadWord("ебальник");
PLUGIN:AddBadWord("ебанутый");
PLUGIN:AddBadWord("ебануть");
PLUGIN:AddBadWord("ебать");
PLUGIN:AddBadWord("ебанный");
PLUGIN:AddBadWord("ёбнутый");
PLUGIN:AddBadWord("ебану");
PLUGIN:AddBadWord("ёбну");
PLUGIN:AddBadWord("еби");
PLUGIN:AddBadWord("ебал");
PLUGIN:AddBadWord("ебло");
PLUGIN:AddBadWord("ёбарь");
PLUGIN:AddBadWord("заёб");
PLUGIN:AddBadWord("залупа");
PLUGIN:AddBadWord("манда");
PLUGIN:AddBadWord("минет");
PLUGIN:AddBadWord("мудак");
PLUGIN:AddBadWord("наебну");
PLUGIN:AddBadWord("пидар");
PLUGIN:AddBadWord("пидор");
PLUGIN:AddBadWord("пизда");
PLUGIN:AddBadWord("пиздеть");
PLUGIN:AddBadWord("пиздец");
PLUGIN:AddBadWord("пиздёж");
PLUGIN:AddBadWord("пиздить");		
PLUGIN:AddBadWord("пиздюл");
PLUGIN:AddBadWord("траха");
PLUGIN:AddBadWord("ёба");	
PLUGIN:AddBadWord("еба");	
PLUGIN:AddBadWord("хуй");
PLUGIN:AddBadWord("хуё");		
PLUGIN:AddBadWord("хуя");
PLUGIN:AddBadWord("хуе");		
PLUGIN:AddBadWord("шалава");
PLUGIN:AddBadWord("шлюха");
PLUGIN:AddBadWord("выебок");
PLUGIN:AddBadWord("ебучий");
PLUGIN:AddBadWord("ебу");
PLUGIN:AddBadWord("еблан");

function PLUGIN:PrinStar(num)
	local bufer = "";
	
	for i = 1, num do 
		bufer = bufer .. "*";
	end;
	
	return bufer;
end;

function PLUGIN:PlayerSay(ply, text)
	local tbl = string.Explode(" ", text);
	local str = "";
	local bFindBadWord = false
	
	for _,word in pairs(tbl) do	
		
		for k,v in pairs(self.Words) do		
			if (string.find( greenCode.string:lower(word), v)) then
				word = string.Replace( greenCode.string:lower(word), v, self:PrinStar(greenCode.string:len(v)))
				bFindBadWord = true;
				break;
			end;
		end
		
		str = str .. word .. " ";
	end;
	
	if ( bFindBadWord ) then
		return str;
	end;
end