--[[
	© 2013 GmodLive private project do not share
	without permission of its author (Andrew Mensky vk.com/men232).
--]]
local PLUGIN = PLUGIN or greenCode.plugin:Loader();
PLUGIN.request = {};
PLUGIN.stored = {};
PLUGIN.canChangeLicense = { TEAM_MAYOR, TEAM_CHIEF };

local playerMeta = FindMetaTable("Player");

function PLUGIN:AddLicense( uid, tLicense )
	if (tLicense.name and tLicense.description) then
		self.stored[uid] = tLicense;
	end;
end;

function PLUGIN:HasLicense( player, uid )
	if ( !IsValid(player) ) then
		return false, "Incorrect player."
	end;
	
	if ( !self.stored[uid] ) then
		return false, "Incorrect license.";
	end;
	
	local tLicense = self.stored[uid];
	
	if ( tLicense.job and table.HasValue( tLicense.job, player:Team() ) ) then
		return true, true;
	end;
	
	if SERVER then
		return player:GetCharacterData("license", {})[uid] or false;
	else
		return player:GetSharedVar("license", {})[uid] or false;
	end;
end;

function PLUGIN:IsPublishLicense( player )
	if SERVER then
		return player:GetCharacterData("publishLicense", false);
	else
		return player:GetSharedVar("publishLicense", false);
	end;
end;

-- A function return true if player have license.
function playerMeta:HasLicense( uid ) return PLUGIN:HasLicense(self, uid); end;
function playerMeta:IsPublishLicense() return PLUGIN:IsPublishLicense(self); end;

if SERVER then
	function PLUGIN:SetLicense( player, uid, bAllow )
		if ( !self.stored[uid] ) then
			return false, "Incorrect license.";
		end;
		
		local tLicenseData = player:GetCharacterData("license", {});
		local bHasLicense = tLicenseData[uid] or false;
		
		player.gcLicenseUpdate = 0;
		
		if ( bHasLicense != bAllow ) then
			tLicenseData[uid] = bAllow;
			player:SetCharacterData("license", tLicenseData);
		end;
		
		return true, "License not need set.";
	end;
	
	-- A function to allow or deny access to license.
	function playerMeta:SetLicense( uid, bAllow ) return PLUGIN:SetLicense( self, uid, bAllow ); end;
	
	function PLUGIN:ShouldBuyCShop( player, CSHOP_ITEM )
		local sLicense = CSHOP_ITEM("license");
		
		if ( sLicense and self.stored[sLicense] and !player:HasLicense(sLicense) ) then
			return false, "Вам нужна '"..self.stored[sLicense].description.."'.";
		end;
	end;
	
	-- Called at an interval while a player is connected.
	function PLUGIN:PlayerThink( player, curTime, infoTable )
		if (!player.gcLicenseUpdate) then
			player.gcLicenseUpdate = curTime + 5;
		end;
		
		if ( curTime >= player.gcLicenseUpdate ) then
			local tLicenseData = {};
			
			for uid, _ in pairs(self.stored) do
				tLicenseData[uid] = player:HasLicense( uid );
			end;
			
			local nLicenseHash = greenCode.kernel:GetTableCRC( tLicenseData );
			
			if ( nLicenseHash != player.lastLicenseHash ) then
				player:SetSharedVar{ license = tLicenseData };
				player.lastLicenseHash = nLicenseHash;
			end;
			
			player.gcLicenseUpdate = nil;
		end;
	end;
	
	function PLUGIN:PlayerChangeJob( player, t )
		player.gcLicenseUpdate = 0;
	end;
	
	function PLUGIN:playerArrested( player, nTime, arrester )
		for uid, _ in pairs(self.stored) do
			self:SetLicense( player, uid, false );
		end;
	end;

	greenCode.command:Add( "showlicense", 0, function( player, command, args )
		local bPublish = player:IsPublishLicense();
		player:SetCharacterData("publishLicense", !bPublish);
		player:SetSharedVar{ publishLicense = !bPublish };
		greenCode.hint:Send( player, "Вы "..(bPublish and "скрыли" or "открыли").." для всех, свои лицензии.", 5, bPublish and Color(255,100,100) or Color(100,255,100), nil, true );
		player:ConCommand("cl_gc_custommenu_update 29227");
	end);

	greenCode.chat:AddCommand( "license", function( player, tArguments )
		player:ConCommand("gc_showlicense");
	end)

	/*greenCode.command:Add( "requestlicense", 0, function( player, command, args )
		if ( #args < 1 ) then
			return
		end;

		local bDone, sMessage;
		local targetPlayer = greenCode.kernel:FindPlayer(args[1]);
		local requestID = tonumber(greenCode.kernel:GetShortCRC( targetPlayer:UniqueID().."_licenseshow" ));

		if ( targetPlayer and player != targetPlayer ) then
			if ( player:GetShootPos():Distance(targetPlayer:GetShootPos()) <= 450 ) then
				local REQUEST, sError = REQUEST_CLASS:New{
					uid = requestID,
					name = "предоставление лицензии",
					targetPlayer = targetPlayer,
					orderPlayer = player,
					timeout = 60,
					OnAccepted = function( player, oerder, REQUEST )
						player:SetSharedVar{ publishLicense = true };
					end,
					OnRejected = function( player, oerder, REQUEST )
						player:SetSharedVar{ publishLicense = false };
					end,
					OnTimeOut = function( player, oerder, REQUEST )
						if ( IsValid(player) ) then
							player:SetSharedVar{ publishLicense = "nil" };
						end;
					end,
				}:Register();

				if ( REQUEST and REQUEST:IsValid() ) then
					return true;
				else
					bDone, sMessage = false, sError;
				end;
			else
				bDone, sMessage = false, "Игрок слишном далеко от Вас.";
			end;
		else
			bDone, sMessage = false, "Игрок не найден.";
		end;

		if ( !bDone ) then
			greenCode.hint:Send( player, sMessage or "#None", 15, Color(255,100,100), nil, true );
		end;
	end);*/
	
	greenCode.command:Add( "setlicense", 0, function( player, command, args )
		if ( #args < 3 ) then
			return;
		end;
		
		local bDone, sReason;
		
		local bAdmin = player:IsAdminRight();
		local team = player:Team();
		local bAllow = tobool(args[3]);
		local sLicense = args[2];
		local targetPlayer = greenCode.kernel:FindPlayer(args[1]);
		local tLicenseData = PLUGIN.stored[sLicense];
		
		if ( bAdmin or table.HasValue( PLUGIN.canChangeLicense, team ) ) then			
			if ( tLicenseData ) then
				if ( targetPlayer ) then
					if ( bAdmin or !bAllow or player:GetShootPos():Distance(targetPlayer:GetShootPos()) <= 150 ) then
						local bHasLicense, bLicenseByJob = targetPlayer:HasLicense(sLicense);
						
						if ( bLicenseByJob == true ) then
							bDone, sReason = false, "У ".. targetPlayer:Name().." '"..tLicenseData.description.."' от профессии.";
						elseif ( bHasLicense == bAllow ) then
							bDone, sReason = false, "Это действие ничего не изменит.";
						else
							if ( bAllow ) then
								local player_level = greenCode.attributes:Get( player, ATB_LEVEL );
								local tartget_level = greenCode.attributes:Get( targetPlayer, ATB_LEVEL );
								
								local need_lvl = tLicenseData["need_lvl"] or 0;
								local lvl_token = tLicenseData["lvl_token"] or 0;
								
								if ( player_level < lvl_token ) then
									bDone, sReason = false, "Для выдачи этой лицензии, вам нужен уровень: "..tostring(lvl_token)..".";
								elseif ( tartget_level < need_lvl ) then
									bDone, sReason = false, "У игрока уровень ниже необходимого: "..tostring(need_lvl)..".";
								else
									bDone, sReason = PLUGIN:SetLicense( targetPlayer, sLicense, bAllow );
								end;
							else
								bDone, sReason = PLUGIN:SetLicense( targetPlayer, sLicense, bAllow );
							end;
						end;
					else
						bDone, sReason = false, "Игрок слишном далеко от Вас.";
					end;
				else
					bDone, sReason = false, "Игрок не найден.";
				end;
			else
				bDone, sReason = false, "Incorrect license.";
			end;
		else
			bDone, sReason = false, "У вас нет прав.";
		end;
				
		if ( bDone ) then
			local cColor = bAllow and Color(150,255,25) or Color(255,100,100);
			greenCode.hint:SendAll( player:Name()..( bAllow and " выдал" or " забрал" ).." '"..PLUGIN.stored[sLicense].description.."' "..targetPlayer:Name(), 5, cColor );
		else
			greenCode.hint:Send( player, sReason or "#None", 5, Color(255,100,100) );
		end;
	end);
end;

-- Include license.
greenCode:IncludePrefixed(PLUGIN:GetBaseDir().."/sh_license.lua");