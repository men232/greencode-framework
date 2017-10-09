--[[
	© 2013 GmodLive private project do not share
	without permission of its author (Andrew Mensky vk.com/men232).
--]]

local greenCode = greenCode;
local math = math;

local PLUGIN = PLUGIN or greenCode.plugin:Loader();
ECONOMIC_TAX = ECONOMIC_TAX or 0;

PLUGIN.stored = PLUGIN.stored or {
	status = 1.00,
	stock = greenCode.config:Get("bank_start_stock"):Get(10000000);
};
PLUGIN.buffer = PLUGIN.buffer or {};
PLUGIN.lastStatus = 0;

local playerMeta = FindMetaTable("Player");

function PLUGIN:SetStatus( nAmount )
	self.stored.status = math.Clamp( nAmount, 0.8, 1.8 )
end;

function PLUGIN:GetStatus()
	return self.stored.status or 1;
end;

function PLUGIN:AddStock( nAmount )
	self.buffer.stock = (self.buffer.stock or self.stored.stock) + nAmount;
end;

function PLUGIN:TickSecond( curTime )
	if ( !self.lastTick ) then
		self.lastTick = 0;
	end;

	if ( curTime > self.lastTick ) then
		local nDropedMoney = 0;

		for k, v in pairs(_ents.GetAll()) do
			if (v:GetClass() == "spawned_money" and !v.printed) then
				nDropedMoney = nDropedMoney + v:Getamount();
			end;
		end;

		if (self.buffer.stock) then
			self.stored.stock = self.buffer.stock;
			self.buffer.stock = nil;
		end;

		local start = greenCode.config:Get("bank_start_stock"):Get(10000000);
		local stock = self.stored.stock - nDropedMoney;
		local status = stock / start;
		self:SetStatus( status );

		if ( self.lastStatus != status ) then
			local tSendData = { status = status, stock = stock, tax = ECONOMIC_TAX };
				gc.datastream:Start( true, "_RPEconomic", tSendData );
			self.lastStatus = status;
			self:Save(nDropedMoney);
		end;

		self.lastTick = greenCode.config:Get("bank_update"):Get(1) + curTime;
	-- Tax
		if ( !self.TaxDay ) then
			self.TaxDay = 0;
		end;
	
		local nCPSalary = 0;
		local nAllowance = 0;
		local nStatus = self:GetStatus()
		local nTaxPlayerCount = 0;
		
		for k, v in pairs(_player.GetAll()) do
			local team = RPExtraTeams[v:Team()];

			if (!IsValid(team)) then continue end;

			local nSalary = math.ceil((team.salary or GAMEMODE.Config.normalsalary) * nStatus);

			if ( v:IsCP() ) then
				nCPSalary = nCPSalary + nSalary;
			else
				nAllowance = nAllowance + nSalary;
				nTaxPlayerCount = nTaxPlayerCount + 1;
			end;
		end;
		
		//nCPSalary = nCPSalary + math.ceil(nAllowance/2);
		ECONOMIC_TAX = math.ceil(math.Clamp(nCPSalary/nTaxPlayerCount, 100, nAllowance*0.065)/2);
		
		//print( nCPSalary, nAllowance, nTaxPlayerCount, ECONOMIC_TAX, self.TaxDay - curTime );
	end;
	
	//self.TaxDay = 0
	
	if ( self.TaxDay < curTime ) then
		for k, v in pairs(_player.GetAll()) do
			//if ( !v:IsCP() ) then
				if ( v:CanAfford(ECONOMIC_TAX) ) then
					v:AddMoney(-ECONOMIC_TAX);
				else
					v:AddMoney(-(v:getDarkRPVar("money") or 0));
				end;
				
				greenCode.hint:Send( v, "Оплата налога: "..greenCode.kernel:FormatNumber(ECONOMIC_TAX).."$", 5, Color(255,255,100) );
			//end;
		end;
				
		self.TaxDay = (greenCode.config:Get("tax_day"):Get(15)*60) + curTime;
	end;
end;

function PLUGIN:PlayerWalletChanged( player, nAmount )
	self.lastTick = greenCode.config:Get("bank_update"):Get(1) + CurTime();
	self:AddStock(-nAmount);
end;

function PLUGIN:Save( nDropedMoney )
	local tSaveData = table.Copy( self.stored );
		tSaveData.stock = tSaveData.stock - ( nDropedMoney or 0 );

	greenCode.kernel:SaveGameData("bank", tSaveData);	
	greenCode:Success( "Bank", "saved, "..(tSaveData.stock or 0).." | "..(tSaveData.status or 0) );
end;

function PLUGIN:Load()
	local tData = greenCode.kernel:RestoreGameData( "bank", self.stored );

	if ( tData and tData.stock and tData.status ) then
		self.stored = tData;
		greenCode:Success( "Bank", "loaded, "..tData.stock.." | "..tData.status );
	end;
end;

function PLUGIN:PlayerCharacterInitialized( player )
	gc.datastream:Start( player, "_RPEconomic", { status = self:GetStatus(), stock = self.stored.stock  } );
end;

function PLUGIN:GetPrice( nAmount ) return math.Round( nAmount * (1 + (1 - self:GetStatus())*greenCode.config:Get("bank_agres"):Get(2)) ); end;

function playerMeta:PayDay()
	if not IsValid(self) then return end
	if not self:isArrested() then
		DB.RetrieveSalary(self, function(amount)
			amount = math.floor((amount or GAMEMODE.Config.normalsalary) * PLUGIN:GetStatus())
			hook.Call("PlayerGetSalary", GAMEMODE, self, amount)
			if amount == 0 or not amount then
				GAMEMODE:Notify(self, 4, 4, DarkRP.getPhrase("payday_unemployed"))
			else
				self:AddMoney(amount)
				GAMEMODE:Notify(self, 4, 4, DarkRP.getPhrase("payday_message", GAMEMODE.Config.currency .. amount))
			end
		end)
	else
		GAMEMODE:Notify(self, 4, 4, DarkRP.getPhrase("payday_missed"))
	end
end

greenCode.command:Add( "salary", 1, function( player, command, args )
	player:PayDay();
end);

greenCode.command:Add( "addstack", 1, function( player, command, args )
	if ( args[1] ) then
		PLUGIN:AddStock( tonumber(args[1]) );
	end;
end);

greenCode.command:Add( "setstack", 1, function( player, command, args )
	if ( args[1] ) then
		PLUGIN.buffer.stock = args[1];
	end;
end);

PLUGIN:Load();