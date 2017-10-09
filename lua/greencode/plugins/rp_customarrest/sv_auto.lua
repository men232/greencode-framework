--[[
	© 2013 GmodLive private project do not share
	without permission of its author (Andrew Mensky vk.com/men232).
--]]

local greenCode = greenCode;
local table = table;
local math = math;

local PLUGIN = PLUGIN or greenCode.plugin:Loader();
local playerMeta = FindMetaTable("Player");

function playerMeta:_IsCArrested() return self:GetSharedVar("arrested", false); end;

function playerMeta:_CArrest( nTime, sReason, tDred, bRejoin )
	if ( self:HasInitialized() ) then
		if ( tDred and type(tDred) == "Player" ) then
			tDred = { name = tDred:Name(), sid = tDred:SteamID(), uid = tDred:UniqueID() };
		end;

		local tArrestData = self:GetCharacterData("_CArrest", {});
			tArrestData.time = os.time() + nTime;
			tArrestData.reason = sReason;
			tArrestData.dred = tDred;
		self:SetCharacterData("_CArrest", tArrestData);
		self:SetSharedVar{ arrestData = { time = math.ceil(CurTime() + nTime), reason = sReason, dred = tDred }, arrested = true };
		
		self:arrest( nTime, type(tDred) == "Player" and tDred or nil );
		self:SaveCharacter();

		greenCode.hint:SendAll( self:Name().." "..( bRejoin and "возвращен" or "посажен" ).."  в тюрьму '"..(sReason or "#Reason").."' на "..tostring(math.Round(nTime/60)).." мин.", 5, nil );
	end;
end;

function playerMeta:_CUnArrest( sReason, bDouble )
	if ( self:HasInitialized() ) then
		self:SetCharacterData("_CArrest", nil);
		self:SetSharedVar{ arrested = GC_NIL_KEY, arrestData = GC_NIL_KEY, arrester = GC_NIL_KEY };

		if ( bDouble ) then
			self:unArrest();
		end;

		self:SaveCharacter();

		greenCode.hint:SendAll( self:Name().." выпущен из тюрьмы"..(sReason and (" '"..sReason.."'.") or "."), 5, nil );
	end;
end;

-- Called when player unarrested.
function PLUGIN:playerUnArrested( player )
	if ( player:_IsCArrested() ) then
		player:_CUnArrest();
	end;

	timer.Simple(1, function()
		gc.datastream:Start( true, "RefreshPU", true );
	end);
end;

-- Called when player arrested.
function PLUGIN:playerArrested( player, nTime, arrester )
	if (IsValid(arrester)) then
		player:SetSharedVar{ arrester = { name = arrester:Name(), sid = arrester:SteamID()/*, uid = arrester:UniqueID()*/ } };
	end;

	timer.Simple(1, function()
		gc.datastream:Start( true, "RefreshPU", true );
	end);
end;

function PLUGIN:PlayerThink( player )
	if ( player:HasInitialized() ) then
		local bArrested = player:_IsCArrested();
		local tArrestData = player:GetCharacterData("_CArrest", {});
		local nTime = ( tArrestData.time or 0 ) - os.time();

		if ( !bArrested and nTime > 0 ) then
			player:_CArrest( nTime, tArrestData.reason or "Посодили там, за что-то там.", tArrestData.dred, true );
		end;
	end;
end;

greenCode.command:Add( "pledge", 0, function( player, command, args )
	if ( #args < 1 ) then
		player:PrintMsg(2, "Invalid arguments");
		return;
	end;

	local bDone, sReason;

	if ( !player:isArrested() ) then
		local target_ply = GAMEMODE:FindPlayer(args[1]);

		if ( target_ply and target_ply != player ) then
			if ( target_ply:isArrested() and target_ply:_IsCArrested() ) then
				local nTime = (target_ply:GetCharacterData("_CArrest", {}).time or 0) - os.time();

				if ( nTime > 0 ) then
					local nPrice = (math.ceil(nTime / 60)) * gc.config:Get("customarrest_bail"):Get(200);

					if ( player:CanAfford(nPrice) ) then
						player:AddMoney(-nPrice);
						target_ply:_CUnArrest(player:Name().." внес залог", true);

						bDone = true;
					else
						bDone, sReason = false, "У вас не хватает денег, сумма залога: "..greenCode.kernel:FormatNumber(nPrice)..GAMEMODE.Config.currency;
					end;
				else
					bDone, sReason = false, "Inccorect time.";
				end;
			else
				bDone, sReason = false, "Игрок не арестован.";
			end;
		else
			bDone, sReason = false, "Player not found.";
		end;
	else
		bDone, sReason = false, "Вы не можете внести залог когда арестованы.";
	end;

	if ( !bDone ) then
		if ( player:IsValid() ) then
			greenCode.hint:Send( player, sReason, 5, bDone and Color(100,255,100) or Color(255,100,100), nil, true );
		else
			player:PrintMsg( 2, sReason );
		end;
	end;
end);

greenCode.command:Add( "fullarrest", 0, function( player, command, args )
	if ( #args < 3 ) then
		player:PrintMsg(2, "Invalid arguments");
		return;
	end;

	local bAdmin = ( player:EntIndex() == 0 or player:IsAdmin() );
	local bDone, sReason;

	if ( bAdmin or !player:isArrested() ) then
		local team = player:Team();

		if ( bAdmin or team == TEAM_POLICE or team == TEAM_CHIEF or team == TEAM_MAYOR ) then
			local target_ply = GAMEMODE:FindPlayer(args[1]);
			
			if ( target_ply and target_ply != player ) then
				local nTime = math.floor(tonumber(args[2]) or -1);

				if ( bAdmin or nTime > 0 and nTime <= gc.config:Get("customarrest_lvl_time"):Get(15) * greenCode.attributes:Get( player, ATB_LEVEL ) ) then
					if ( bAdmin or target_ply:isArrested() ) then
						if ( bAdmin or !target_ply:GetSharedVar("arrested", false) ) then
							target_ply:_CArrest( nTime*60, args[3], player );
							bDone = true, "All done :)";
						else
							bDone, sReason = false, "Игрок уже отбывает срок.";
						end;
					else
						bDone, sReason = false, "Cначало игрок должен быть задержен.";
					end;
				else
					bDone, sReason = false, "Ваш уровень не позволяет посадить на "..nTime.." мин.";
				end;
			else
				bDone, sReason = false, "Player not found.";
			end;
		else
			bDone, sReason = false, "Только сотрудники правоохранительных органов могут использовать эту функцию."
		end;
	else
		bDone, sReason = false, "Вы не можете выдать срок когда арестованы."
	end;

	if ( !bDone ) then
		if ( player:IsValid() ) then
			greenCode.hint:Send( player, sReason, 5, bDone and Color(100,255,100) or Color(255,100,100), nil, true );
		else
			player:PrintMsg( 2, sReason );
		end;
	end;
end);