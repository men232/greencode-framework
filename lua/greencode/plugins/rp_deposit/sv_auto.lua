--[[
	© 2013 GmodLive private project do not share
	without permission of its author (Andrew Mensky vk.com/men232).
--]]
local PLUGIN = PLUGIN or greenCode.plugin:Loader();

local greenCode = greenCode;
local table = table;
local math = math;
local os = os;
local playerMeta = FindMetaTable("Player");

PLUGIN.stored = PLUGIN.stored or {};

greenCode.config:Add( "min_deposit_money", 5000, false, false, false );

--[[ Define the deposit class metatable. --]]
DEPOSIT_CLASS = DEPOSIT_CLASS or greenCode.kernel:CreateBasicClass();

function DEPOSIT_CLASS:SetData( key, value )
	if ( self:IsValid() and self.data[key] != nil ) then
		self.data[key] = value;
		greenCode.plugin:Call( "OnDepositDataChange", self, key, value );
		return true;
	end;
end;

function DEPOSIT_CLASS:SetPin( pin )
	if ( self:IsValid() ) then
		pin = util.CRC("wtf_"..pin.."_lol");
		self:SetData("pin", pin);
	end;
end;

function DEPOSIT_CLASS:CheckPin( pin )
	return self("pin", "0000") == util.CRC("wtf_"..pin.."_lol");
end;

function DEPOSIT_CLASS:CanAfford( amount ) return self("money", 0) - amount >= 0; end;

function DEPOSIT_CLASS:SetMoney( amount )
	self:SetData("money", math.max(amount, 0));
end;

function DEPOSIT_CLASS:AddMoney( amount )
	self:SetData("money", math.max(self("money", 0) + amount, 0));
end;

function DEPOSIT_CLASS:GetMoney() return self("money", 0); end;
function DEPOSIT_CLASS:Name() return self("name", "Unknown"); end;
function DEPOSIT_CLASS:GetName() return self:Name(); end;
function DEPOSIT_CLASS:UniqueID() return self("uid", -1) end;

function DEPOSIT_CLASS:Cashing( player, amount, bDeposit )
	if ( bDeposit ) then
		if ( player:CanAfford( amount ) ) then
			player:AddMoney(-amount);
			self:AddMoney(amount);
		else
			return false, "Вы не можете себе этого позволить.";
		end;
	else
		if ( self:CanAfford(amount) ) then
			player:AddMoney(amount);
			self:AddMoney(-amount);
		else
			return false, "На депозите нет такой суммы.";
		end;
	end;

	return true;
end;

function DEPOSIT_CLASS:Register() return PLUGIN:RegisterDeposit(self) end;

function playerMeta:GetDeposits()
	local tList = {};
	local sid = self:SteamID();
	
	for uid, DEPOSIT in pairs( PLUGIN.stored ) do
		if ( DEPOSIT("sid") == sid ) then
			table.insert(tList, DEPOSIT);
		end;
	end;
	
	return tList;
end;

function playerMeta:DepositsCanAfford( amount )
	for uid, DEPOSIT in pairs( self:GetDeposits() ) do
		if ( DEPOSIT:CanAfford(amount) ) then
			return DEPOSIT;
		end;
	end;
	
	return false;
end;

function PLUGIN:FindByID( identifier ) return self.stored[identifier] end;

function PLUGIN:OpenDeposit( owner, name, pincode, money )
	return DEPOSIT_CLASS:New{
		uid = tonumber(greenCode.kernel:GetShortCRC( os.time()..name )),
		name = name,
		pin = util.CRC("wtf_"..pincode.."_lol"),
		className = "BANK DEPOSIT",
		sid = owner:SteamID(),
		money = money or 0,
	}:Register();
end;

function PLUGIN:RegisterDeposit( DEPOSIT )
	if ( DEPOSIT and DEPOSIT:IsValid() and DEPOSIT("uid") != -1 ) then
		local uid = DEPOSIT("uid");
		if ( !self.stored[uid] ) then
			self.stored[uid] = DEPOSIT;
			greenCode.plugin:Call( "OnDepositRegistered", DEPOSIT );
			return DEPOSIT, uid;
		end;
	end;

	return false;
end;

function DEPOSIT_CLASS:Remove()
	if ( self:IsValid() and PLUGIN.stored[self:UniqueID()] ) then
		local uid = self:UniqueID();
		local name = self:Name();

		PLUGIN.stored[uid] = nil;
		self = nil;
		greenCode.plugin:Call( "OnDepositRemove", uid, name );
		return true;
	end;
end;

function PLUGIN:CheckDistanse( player )
	return true;
end;

function PLUGIN:IsLoading() return self.LoadingMode end;
function PLUGIN:SetLoading( bValue ) self.LoadingMode = bValue end;

function PLUGIN:Save( uid )
	local tSavedList = { "Deposit saved:" };

	if ( uid and self.stored[uid] ) then
		greenCode.kernel:SaveGameData( "deposit/"..tostring( uid ), self.stored[ uid ].data );
		table.insert( tSavedList, self.stored[ uid ]:Name() .. " - " .. uid );
	else
		for uid, _ in pairs( self.stored ) do
			greenCode.kernel:SaveGameData( "deposit/"..tostring( uid ), self.stored[ uid ].data );
			table.insert( tSavedList, self.stored[ uid ]:Name() .. " - " .. uid );
		end;
	end;

	if ( #tSavedList > 1 ) then
		greenCode:Debug( table.concat(tSavedList, "\n\t\t") );
	end;
end;

function PLUGIN:Load()
	local Loaded = { "Loaded deposit:" };
	local Errors = { "Loaded error deposit:" };

	self:SetLoading( true );

	for id, v in pairs( _file.Find( GC_GAMEDATA_FOLDER.."/deposit/*.txt", "DATA" ) ) do
		local uid   = tonumber(string.Replace(v, ".txt", ""));
		local tData = greenCode.kernel:RestoreGameData("deposit/"..uid);
		tData.uid   = uid;

		local DEPOSIT = DEPOSIT_CLASS:New( tData );
		
		if ( DEPOSIT:Register() ) then
			table.insert( Loaded, DEPOSIT:Name().." - "..DEPOSIT:UniqueID() );
		else
			table.insert( Errors, DEPOSIT:Name().." - "..DEPOSIT:UniqueID() );
		end;
	end;

	self:SetLoading( false );

	if ( #Loaded > 1 ) then
		greenCode:Debug( table.concat(Loaded, "\n\t\t") );
	end;
	if ( #Errors > 1 ) then
		greenCode:Debug( table.concat(Errors, "\n\t\t") );
	end;
end;

function PLUGIN:OnDepositRegistered( DEPOSIT )
	if ( !self:IsLoading() ) then
		self:Save( DEPOSIT:UniqueID() );
	end;
end;

function PLUGIN:InitPostEntity()
	self:Load();
end;

function PLUGIN:SendDepositList( player )
	local tPlayerDeposits = {};
	local sid = player:SteamID();

	for uid, DEPOSIT in pairs( PLUGIN.stored ) do
		if ( DEPOSIT("sid") == sid ) then
			tPlayerDeposits[uid] = DEPOSIT:Name();
		end;
	end;

	player:SetPrivateVar{ deposits = tPlayerDeposits };
end;

function PLUGIN:SendDepositData( player, DEPOSIT, pincode, login )
	gc.datastream:Start(player, "DepositUpdate", {
		name = DEPOSIT:Name(),
		money = DEPOSIT:GetMoney(),
		uid = DEPOSIT:UniqueID(),
		pin = pincode,
		login = login,
	});
end;

function PLUGIN:PlayerCharacterInitialized( player )
	timer.Simple( 5, function()
		self:SendDepositList( player );
	end)
end;

function PLUGIN:OnDepositDataChange( DEPOSIT, key, value )
	local uid = DEPOSIT:UniqueID();
	
	if ( key == "money" ) then

		for k, v in pairs( _player.GetAll() ) do
			if ( v.gcDepositLogin == uid ) then
				self:SendDepositData( v, DEPOSIT, nil );
			end;
		end;
	end;
	
	self:Save( uid );
end;

function PLUGIN:OnDepositRemove( uid, name )
	greenCode.kernel:DeleteGameData("deposit/"..uid);
end;

greenCode.command:Add( "deposit_status", 2, function( player, command, args )
	for uid, DEPOSIT in pairs( PLUGIN.stored ) do
		player:PrintMsg( 2, "#"..DEPOSIT:UniqueID().."\t"..DEPOSIT:Name().."\t"..greenCode.kernel:FormatNumber(DEPOSIT:GetMoney()).."$" );
	end;
end);

local DEPOSIT_RECHARGE = 1;
local DEPOSIT_WITHDRAW = 2;
local DEPOSIT_CHANGEPIN = 3;
local DEPOSIT_TRANS = 4;

greenCode.command:Add( "deposit_operation", 0, function( player, command, args )
	if ( #args < 4 ) then return; end;

	if ( !PLUGIN:CheckDistanse(player) ) then
		return;
	end;

	local bDone, sReason = false, "Somting wrong.";
	local nOperation = tonumber(args[1]);
	local DEPOSIT = PLUGIN:FindByID( tonumber(args[2]) );
	local PinCode = string.match(args[3], "%d+");
	local sid = player:SteamID();

	if ( DEPOSIT and DEPOSIT:IsValid() ) then		
		if ( DEPOSIT:CheckPin(PinCode) or DEPOSIT("sid") == sid ) then
			-- Get Set money
			if ( nOperation == DEPOSIT_RECHARGE or nOperation == DEPOSIT_WITHDRAW ) then
				local amount = math.floor(math.abs(tonumber(args[4])));
				local bDeposit = nOperation == DEPOSIT_WITHDRAW;

				bDone, sReason = DEPOSIT:Cashing( player, amount, bDeposit );

				if ( bDone ) then
					sReason = (bDeposit and "Вы внесли " or "Вы сняли ")..greenCode.kernel:FormatNumber(amount).."$ "..(bDeposit and "на счет" or "со счета").." #"..DEPOSIT:UniqueID().." - "..DEPOSIT:Name()..".";
				end;

			-- Change Pin.
			elseif ( nOperation == DEPOSIT_CHANGEPIN ) then
				local NewPinCode = math.abs(tonumber(args[4]) or "1111");
				local PinCodeLen = string.len(tostring(NewPinCode));

				if ( DEPOSIT("sid", sid) == sid ) then
					if ( PinCodeLen < 4 or PinCodeLen > 12 ) then
						bDone, sReason = false, "PinCode должен быть больше 4 и меньше 12 цифер.";
					else
						DEPOSIT:SetPin( NewPinCode );
						PLUGIN:SendDepositData( player, DEPOSIT, NewPinCode );
						bDone, sReason = true, "Пин код от счета #"..DEPOSIT:UniqueID().." был изменен на: "..NewPinCode;
					end;
				else
					bDone, sReason = false, "Не верный pin код.";
				end;

			-- Trans money.
			elseif ( nOperation == DEPOSIT_TRANS ) then
				local DEPOSIT_TARGET = PLUGIN:FindByID( tonumber(args[4]) );
				local amount = math.floor(math.abs(tonumber(args[5]) or 0));

				if ( DEPOSIT_TARGET and DEPOSIT_TARGET:IsValid() and DEPOSIT != DEPOSIT_TARGET ) then
					if ( DEPOSIT:CanAfford(amount) ) then
						DEPOSIT:AddMoney(-amount);
						DEPOSIT_TARGET:AddMoney(amount);

						bDone, sReason = true, "Успешный перевод "..greenCode.kernel:FormatNumber(amount).."$ с #"..DEPOSIT:UniqueID().." - "..DEPOSIT:Name().." на #"..
							DEPOSIT_TARGET:UniqueID().." - "..DEPOSIT_TARGET:Name();
					else
						bDone, sReason = false, "На депозите нет такой суммы.";
					end;
				else
					bDone, sReason = false, "Конечный счет не найден.";
				end;
			end;
		else
			bDone, sReason = false, "Не верный pin код.";
		end;
	else
		bDone, sReason = false, "Лицевой счет не найден.";
	end;

	greenCode.hint:Send( player, sReason, 15, bDone and Color(100,255,100) or Color(255,100,100), nil, true );
end);

greenCode.command:Add( "deposit_login", 0, function( player, command, args )
	if ( #args < 2 ) then return; end;

	if ( !PLUGIN:CheckDistanse(player) ) then
		return;
	end;

	local bDone, sReason = false, "Somting wrong.";
	local DEPOSIT = PLUGIN:FindByID( tonumber(args[1]) );
	local PinCode = string.match(args[2], "%d+") or "";

	if ( DEPOSIT ) then
		if ( DEPOSIT:CheckPin(PinCode) ) then
			player.gcDepositLogin = DEPOSIT:UniqueID();
			PLUGIN:SendDepositData( player, DEPOSIT, PinCode, true );
			bDone, sReason = true, "Успешный вход в лицевой счет #"..DEPOSIT:UniqueID()..".";
		else
			bDone, sReason = false, "Не верный pin код.";
		end;
	else
		bDone, sReason = false, "Лицевой счет не найден.";
	end;

	greenCode.hint:Send( player, sReason, 15, bDone and Color(100,255,100) or Color(255,100,100), nil, true );
end);

greenCode.command:Add( "deposit_create", 0, function( player, command, args )
	if ( #args < 3 ) then return; end;

	local sName = args[1];
	local PinCode = string.match(args[2], "%d+") or "";
	local startDeposit = math.floor(math.max(tonumber(args[3]), greenCode.config:Get("min_deposit_money"):Get()));
	local PinCodeLen = string.len(PinCode);

	local bDone, sReason = false, "Somting wrong.";

	if ( player:CanAfford(startDeposit) ) then
		if ( PinCodeLen < 4 or PinCodeLen > 12 ) then
			bDone, sReason = false, "PinCode должен быть больше 4 и меньше 12 цифер.";
		else
			local DEPOSIT = PLUGIN:OpenDeposit( player, sName, PinCode, startDeposit );

			if ( DEPOSIT ) then
				player:AddMoney(-startDeposit);
				PLUGIN:SendDepositList(player);
				bDone, sReason = true, "Ваш счет успешно создан #"..DEPOSIT:UniqueID().." приятного пользования!";
			end;
		end;
	else
		bDone, sReason = false, "У вас недостаточно денег для открытия депозита.";
	end;

	greenCode.hint:Send( player, sReason, 15, bDone and Color(100,255,100) or Color(255,100,100), nil, true );
end);

greenCode.command:Add( "deposit_update", 0, function( player, command, args )
	PLUGIN:SendDepositList(player);
end);

greenCode.command:Add( "deposit_remove", 0, function( player, command, args )
	if ( #args < 2 ) then return; end;

	local DEPOSIT = PLUGIN:FindByID( tonumber(args[1]) );
	local PinCode = tonumber(args[2]);
	local sid = player:SteamID();
	local bDone, sReason = false, "Somting wrong.";

	if ( DEPOSIT ) then
		if ( DEPOSIT:CheckPin(PinCode) ) then
			if ( DEPOSIT("sid", sid) == sid ) then
				local money = DEPOSIT:GetMoney();

				if ( DEPOSIT:Remove() ) then
					PLUGIN:SendDepositList(player);
					player:AddMoney(money);

					gc.datastream:Start(player, "DepositClean", true);
					bDone, sReason = true, "Вы закрыли счет #"..math.floor(args[2])..".";
				end;
			else
				bDone, sReason = false, "Только создатель счета может его удалить.";
			end;
		else
			bDone, sReason = false, "Не верный pin код.";
		end;
	else
		bDone, sReason = false, "Лицевой счет не найден.";
	end;

	greenCode.hint:Send( player, sReason, 15, bDone and Color(100,255,100) or Color(255,100,100), nil, true );
end);