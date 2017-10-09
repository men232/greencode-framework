--[[
	© 2013 GmodLive private project do not share
	without permission of its author (Andrew Mensky vk.com/men232).
--]]
local PLUGIN = PLUGIN or greenCode.plugin:Loader();

local greenCode = greenCode;
local gc = gc;

-- Include models list.
greenCode:IncludePrefixed(PLUGIN:GetBaseDir().."/sh_model.lua");

function PLUGIN:PlayerCharacterInitialized( player )
	local _RPModel = player:GetCharacterData("_RPModel");
	
	if ( _RPModel ) then
		self:ChangeModel( player, _RPModel.gender, _RPModel.mdlID, _RPModel.skin, true );
	else
		gc.datastream:Start( player, "_RPModel", true );
	end;
end;

function PLUGIN:PlayerModelChanged( player, sModel )
	if ( !player.gcIgnoreChangeModel and player:HasInitialized() ) then
		self:PlayerCharacterInitialized( player );
	end;
end;

/*function PLUGIN:PlayerSpawn( player, bFirstSpawn, bInitialized )
	if ( !bFirstSpawn ) then
		timer.Simple( 5, function()
			self:PlayerCharacterInitialized( player );
		end);
	end;
end;

function PLUGIN:OnPlayerChangedTeam( player, prevTeam, curTeam )
	timer.Simple( 5, function()
		self:PlayerCharacterInitialized( player );
	end);
end;*/

local tBlackJobList = { TEAM_CHIEF, TEAM_POLICE, TEAM_MAYOR, TEAM_SWAT };

function PLUGIN:CanChangeModel( player, nGender, sModel, nSkin )
	local _RPModel = player:GetCharacterData("_RPModel");

	if ( table.HasValue(tBlackJobList, player:Team()) ) then
		return false, "Вы не можете сменить скин играя за эту профессию.";
	elseif player.gcIgnoreChangeModel then
		return true;
	elseif player:GetModel() == sModel and player:GetSkin() == nSkin then
		return false, "У вас точно такой же скин.";
	elseif _RPModel and (_RPModel.gender != nGender or _RPModel.mdl != sModel) then
		return false, "Вы не можете изменить лицо или пол.";
	end;
end;

function PLUGIN:IsFirstTime( player )
	return player:GetCharacterData("_RPModel") == nil;
end;

function PLUGIN:ChangeModel( player, nGender, nModelID, nSkin, bNoSave )
	local tModelsList = nGender == 0 and self.MaleModels or self.FemaleModels;
	local tData = tModelsList[ nModelID ];

	if ( tData ) then
		local bShould, sReason = greenCode.plugin:Call("CanChangeModel", player, nGender, tData.Model, nSkin );

		if ( bShould == false ) then
			return false, sReason;
		end;

		if ( table.HasValue( tData.Skin, nSkin ) ) then
			player.gcIgnoreChangeModel = true;
				player:SetModel( tData.Model );
				player:SetSkin( nSkin );
			player.gcIgnoreChangeModel = false;
		end;

		if ( !bNoSave ) then
			local _RPModel = player:GetCharacterData("_RPModel", {});
				_RPModel = { mdl = tData.Model, mdlID = nModelID, skin = nSkin, gender = nGender };
			player:SetCharacterData("_RPModel", _RPModel);
			player:SaveCharacter();
		end;

		gc.datastream:Start( player, "_RPModel", { cmd = 0 } ); // close gui

		return true, "Ваш скин был изменен.";
	else
		gc.datastream:Start( player, "_RPModel", { cmd = 1 } ); // enabled apply btn.
		return false, "Incorreect gender or model.";
	end;
end;

greenCode.command:Add( "nulled_data", 1, function( player, command, args )
	if ( #args < 1 ) then return end;
	player:SetCharacterData(args[1], nil);
end);

greenCode.command:Add( "changemodel", 0, function( player, command, args )
	if ( #args < 3 ) then
		return;
	end

	local bDone, sMessage, entity;

	if ( args[4] ) then
		entity = Entity( tonumber(args[4]) );
	end;

	if ( PLUGIN:IsFirstTime(player) ) then
		bDone, sMessage = PLUGIN:ChangeModel( player, tonumber(args[1]), tonumber(args[2]), tonumber(args[3]) );
	elseif ( IsValid(entity) and entity:GetClass() == "short_sell" ) then
		local nDistance = player:GetShootPos():Distance( entity:GetPos() );
		local owner = entity:Getowning_ent();

		if ( IsValid(owner) ) then
			if ( nDistance <= 150 ) then
				local nPrice = entity:Getprice();

				if ( player:CanAfford(nPrice) or player == owner ) then
					bDone, sMessage = PLUGIN:ChangeModel( player, tonumber(args[1]), tonumber(args[2]), tonumber(args[3]) );

					if ( bDone ) then
						if ( player != owner ) then
							player:AddMoney(-nPrice);
							owner:AddMoney(nPrice);
						end;

						entity:SetCount(entity:GetCount() - 1);
					end;
				else
					bDone, sMessage = false, "Вы не можете себе это позволить.";
				end;
			else
				bDone, sMessage = false, "Вы находитесь слишком далеко от точки продажи.";
			end;
		else
			bDone, sMessage = false, "Продавец не найден.";
		end;
	else
		bDone, sMessage = false, "Найдите магазин, для того чтобы купить новый скин!";
	end;

	gc.datastream:Start( player, "_RPModel", { cmd = 0 } ); // enabled apply btn.
	greenCode.hint:Send( player, sMessage, 5, bDone and Color(150,255,25) or Color(255,100,100), nil, true );
end);