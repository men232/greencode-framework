--[[
	© 2013 GmodLive private project do not share
	without permission of its author (Andrew Mensky vk.com/men232).
--]]

greenCode.string = {};

local CYRILLIC_UPPER_CYM = {}
local CYRILLIC_LOWER_CYM = {}
	
local function AddCyrillicCym( a, b )
	table.insert(CYRILLIC_LOWER_CYM, a)
	table.insert(CYRILLIC_UPPER_CYM, b)
end

AddCyrillicCym( "й", "Й" );
AddCyrillicCym( "ц", "Ц" );
AddCyrillicCym( "у", "У" );
AddCyrillicCym( "к", "К" );
AddCyrillicCym( "е", "Е" );
AddCyrillicCym( "н", "Н" );
AddCyrillicCym( "г", "Г" );
AddCyrillicCym( "ш", "Ш" );
AddCyrillicCym( "щ", "Щ" );
AddCyrillicCym( "з", "З" );
AddCyrillicCym( "х", "Х" );
AddCyrillicCym( "ъ", "Ъ" );
AddCyrillicCym( "ф", "Ф" );
AddCyrillicCym( "ы", "Ы" );
AddCyrillicCym( "в", "В" );
AddCyrillicCym( "а", "А" );
AddCyrillicCym( "п", "П" );
AddCyrillicCym( "р", "Р" );
AddCyrillicCym( "о", "О" );
AddCyrillicCym( "л", "Л" );
AddCyrillicCym( "д", "Д" );
AddCyrillicCym( "ж", "Ж" );
AddCyrillicCym( "э", "Э" );
AddCyrillicCym( "я", "Я" );
AddCyrillicCym( "ч", "Ч" );
AddCyrillicCym( "с", "С" );
AddCyrillicCym( "м", "М" );
AddCyrillicCym( "и", "И" );
AddCyrillicCym( "т", "Т" );
AddCyrillicCym( "ь", "Ь" );
AddCyrillicCym( "б", "Б" );
AddCyrillicCym( "ю", "Ю" );

cyrillic = {
	[233] = "й",
	[246] = "ц",
	[243] = "у",
	[234] = "к",
	[229] = "е",
	[237] = "н",
	[227] = "г",
	[248] = "ш",
	[249] = "щ",
	[231] = "з",
	[245] = "х",
	[250] = "ъ",
	[244] = "ф",
	[251] = "ы",
	[226] = "в",
	[224] = "а",
	[239] = "п",
	[240] = "р",
	[238] = "о",
	[235] = "л",
	[228] = "д",
	[230] = "ж",
	[253] = "э",
	[255] = "я",
	[247] = "ч",
	[241] = "с",
	[236] = "м",
	[232] = "и",
	[242] = "т",
	[252] = "ь",
	[225] = "б",
	[254] = "ю",
	
	[201] = "Й",
	[214] = "Ц",
	[211] = "У",
	[202] = "К",
	[197] = "Е",
	[205] = "Н",
	[195] = "Г",
	[216] = "Ш",
	[217] = "Щ",
	[199] = "З",
	[213] = "Х",
	[218] = "Ъ",
	[212] = "Ф",
	[219] = "Ы",
	[194] = "В",
	[192] = "А",
	[207] = "П",
	[208] = "Р",
	[206] = "О",
	[203] = "Л",
	[196] = "Д",
	[198] = "Ж",
	[221] = "Э",
	[223] = "Я",
	[215] = "Ч",
	[209] = "С",
	[204] = "М",
	[200] = "И",
	[210] = "Т",
	[220] = "Ь",
	[193] = "Б",
	[222] = "Ю",
}

function greenCode.string:CyrillicCount( text, devide )
	local count = 0;
	
	for k, v in pairs(CYRILLIC_UPPER_CYM) do
		_, num = string.gsub(text, v, CYRILLIC_LOWER_CYM[k]);
		count = count + num;
	end;
	
	local upper = 0;
	if ( devide ) then
		upper = count;
		count = 0;
	end;
	
	for k, v in pairs(CYRILLIC_LOWER_CYM) do
		_, num = string.gsub(text, v, CYRILLIC_UPPER_CYM[k]);
		count = count + num;
	end;
	
	if ( devide ) then
		return count, upper;
	else
		return count;
	end;
end;

function greenCode.string:len( text )
	local CyrCount = greenCode.string:CyrillicCount(text);
	return string.len(text) - CyrCount;
end;

function greenCode.string:lower( text )
	for k, v in pairs(CYRILLIC_UPPER_CYM) do
		text = string.gsub(text, v, CYRILLIC_LOWER_CYM[k]);
	end;
	
	return string.upper(text);
end

function greenCode.string:upper( text )
	for k, v in pairs(CYRILLIC_LOWER_CYM) do
		text = string.gsub(text, v, CYRILLIC_UPPER_CYM[k]);
	end;
	
	return string.upper(text);
end;

function greenCode.string:CheckName( sName )
	if ( !sName or sName == "" ) then
		return false, "Укажите имя";
	end;
	
	local len = string.utf8len(sName);
	local low = string.utf8lower(sName);
	
	if len > 31 then
		return false, "Имя должно быть меньше 30 символов.";
	elseif len < 7 then
		return false, "Имя должно быть больше 5 символов.";
	end

	local allowed = {
	'q', 'w', 'e', 'r', 't', 'y', 'u', 'i', 'o', 'p',
	'a', 's', 'd', 'f', 'g', 'h', 'j', 'k', 'l',
	'z', 'x', 'c', 'v', 'b', 'n', 'm', ' ',
	'й', 'ц', 'у', 'к', 'е', 'н', 'г', 'ш', 'щ', 'з', 'х', 'ъ',
	'ф', 'ы', 'в', 'а', 'п', 'р', 'о', 'л', 'д', 'ж', 'э',
	'я', 'ч', 'с', 'м', 'и', 'т', 'ь', 'б', 'ю', '-'};

	for i=1, len do
		local uchar = string.utf8sub( low, i, i );
		
		if not table.HasValue(allowed, uchar) then
			return false, string.format("В имени есть запрещенный символ: '%s'", uchar);
		end
	end
	
	local split = string.Explode(" ", sName);
	local upLen = string.upperLen( sName );
	
	if ( (upLen != 2 and upLen != 3) or #split < 2 or #split > 3 or !string.isUpper( string.utf8sub(split[1], 1, 1) ) or !string.isUpper( string.utf8sub(split[2], 1, 1) ) ) then
		return false, "Не правильный формат имени < Имя Фамилия > (с учетем регистра).";
	elseif ( string.utf8len(split[1]) < 3 ) then
		return false, "Имя должно быть больше 2 символов.";
	elseif string.utf8len(split[2]) < 3 then
		return false, "Фамилия должно быть больше 2 символов.";
	end;
	
	return true;
end;

if SERVER then
	function greenCode.string:PlayerThink( player, curTime, infoTable, bAlive )
		if ( bAlive ) then
			if ( !player.gcLastCheckName ) then
				player.gcLastCheckName = 0;
			end;
			
			if ( curTime > player.gcLastCheckName ) then
				local bSuccess, sReason = self:CheckName(player:Name());
				
				if ( !bSuccess ) then
					player.gcNormalName = false;
					greenCode.hint:Send( player, "Ваш ник не соответствует правилам RP, а именно '"..sReason.."'", 28, Color(255,100,100), nil, true );
					greenCode.hint:Send( player, "Для того чтобы изменить имя, используйте F4 > Изменить имя.", 28, Color(100,255,100), nil, true );
				elseif ( !player.gcNormalName ) then
					player.gcNormalName = true;
					greenCode.hint:Send( player, "Спасибо, что ваше имя соответствует всем правилам RP.", 5, Color(100,255,100), nil, true );
				end;
				
				player.gcLastCheckName = curTime + 30;
			end;
		end;
	end;
end;