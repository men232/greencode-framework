/*--[[
	© 2013 GmodLive private project do not share
	without permission of its author (Andrew Mensky vk.com/men232).
--]]

local greenCode = greenCode;
local math = math;
local SESSION_DIR = "sessions/stored/";

greenCode.request        = greenCode.kernel:NewLibrary("Request");
greenCode.request.buffer = {};

-------------------
-- Request Class --
-------------------

REQUEST_CLASS = greenCode.kernel:CreateBasicClass();

function REQUEST_CLASS:GetOrder() return self( "orderPlayer" ); end;
function REQUEST_CLASS:GetPlayer() return self( "targetPlayer" ); end;
function REQUEST_CLASS:GetName() return self( "name", "Unknown" ); end;
function REQUEST_CLASS:Name() return self:GetName(); end;
function REQUEST_CLASS:UniqueID() return self( "uid", -1 ); end;
function REQUEST_CLASS:GetAnswer() return self( "answer", false ); end;
function REQUEST_CLASS:GetTime() return self( "timeleft", 0 ); end;
function REQUEST_CLASS:GetCallBack() return self("OnAccepted", function() end), self("OnRejected", function() end); end
function REQUEST_CLASS:GetTimeOut() return self("timeout", -1); end
function REQUEST_CLASS:Register( ... ) return greenCode.request:Register( self, ... ); end;
function REQUEST_CLASS:IsAnswered( ... ) return self.answered end;

function REQUEST_CLASS:Reply()
	self.answered = true;
	
	local targetPlayer = self:GetPlayer();
	local orderPlayer = self:GetOrder();
	local bTargetValid = IsValid(targetPlayer);
	local bOrderValid = IsValid(orderPlayer);
	local bShouldStop = !bTargetValid or !bOrderValid;
	
	if ( !bOrderValid and bTargetValid ) then
		greenCode.hint:Send( targetPlayer, "Запрашиваемая сторона покинула сервер.", 15, Color(255,100,100) );
	elseif ( !bTargetValid and bOrderValid ) then
		greenCode.hint:Send( orderPlayer, "Ответная сторона покинула сервер.", 15, Color(255,100,100) );
	end;
	
	if ( bShouldStop ) then return; end;
	
	local OnAccepted, OnRejected = self:GetCallBack();
	local bAnswer = self:GetAnswer();
	
	if ( bAnswer ) then
		OnAccepted( self:GetPlayer(), self:GetOrder(), self );
	else
		OnRejected( self:GetPlayer(), self:GetOrder(), self );
	end;
	
	local nTimeOut = self:GetTimeOut();
	
	if ( nTimeOut > 0 ) then
		self:SetData("timeout", CurTime() + nTimeOut);
	end;
	
	greenCode.plugin:Call( "OnRequestAnswer", self, bAnswer );
end;

function REQUEST_CLASS:SendHint( player, sText, nTime, sColor )
	if ( IsValid(player) ) then
		greenCode.hint:Send( player, sText, nTime, sColor, nil, true );
	end;
end;

function REQUEST_CLASS:New( tMergeTable )
	local object = { 
		data = {
			uid = -1,
			className = "REQUEST",
			name = "Unknown",
			timeleft = CurTime()+30,
			timeout = -1,
			answer = false,
			OnAccepted = function() end,
			OnRejected = function() end,
			OnTimeOut = function() end,
		},
	};

	if ( tMergeTable ) then
		table.Merge( object.data, tMergeTable );
	end;
	
	local player = object.data.targetPlayer;
	
	setmetatable( object, self );
	self.__index = self;

	if ( object("uid", -1) == -1 ) then	
		object:SetData("uid", tonumber(greenCode.kernel:GetShortCRC(object:Name().."_"..player:UniqueID())));
	end;

	return object;
end;

--------------------------
-- LIB REQUEST FUNCTION --
--------------------------

function greenCode.request:CleanBuffer() self.buffer = {}; end;

function greenCode.request:FindByID( uid ) return self.buffer[uid];	end;
function greenCode.request:GetAll() return self.buffer; end;

function greenCode.request:Register( REQUEST )
	if ( REQUEST and REQUEST:IsValid() ) then
		local uid = REQUEST:UniqueID();
		
		if ( !IsValid(REQUEST:GetPlayer()) or !IsValid(REQUEST:GetOrder()) ) then
			return false, "Player's is not valid.";
		end;

		local CUR_REQUEST = self.buffer[uid];
				
		if ( !CUR_REQUEST ) then
			self.buffer[uid] = REQUEST;
			greenCode.plugin:Call( "OnRequestCreate", REQUEST );
			return self.buffer[uid], uid;
		elseif ( !CUR_REQUEST:IsAnswered() ) then
			return false, "Игрок еще не дал ответ на прошлый запрос.";
		else
			return false, "Игрок дал ответ, действие запроса еще не истекло.";
		end;
	end;
	
	return false, "Еще действует прошлий запрос.";
end;

function greenCode.request:TickSecond( curTime )
	for uid, REQUEST in pairs( self:GetAll() ) do
		local bAnswered = REQUEST:IsAnswered();
		
		if ( !bAnswered and REQUEST:GetTime() < curTime ) then
			REQUEST:Reply();
		end;
			
		if ( bAnswered ) then
			local nTimeOut = REQUEST:GetTimeOut();
			
			if ( nTimeOut < curTime ) then
				if ( REQUEST:GetAnswer() ) then
					local OnTimeOut = REQUEST("OnTimeOut")
					OnTimeOut( REQUEST:GetPlayer(), REQUEST:GetOrder(), REQUEST );
				end;
				
				greenCode.plugin:Call( "OnRequestOut", REQUEST );
				self.buffer[uid] = nil;
			end;
		end;
	end;
end;

function greenCode.request:Answer( player, requestID, bAnswer )
	if ( requestID ) then
		local REQUEST = greenCode.request:FindByID(requestID);

		if ( REQUEST and REQUEST:GetPlayer() == player ) then
			if ( !REQUEST:IsAnswered() ) then
				REQUEST:SetData("answer", bAnswer);
				REQUEST:Reply()
				return bAnswer, "Запрос '"..REQUEST:Name().."' "..(bAnswer and "подтвержден" or "откланен")..".";
			else
				return false, "Ответ на этот запрос уже дан.";
			end;
		else
			return false, "Такого запроса не существует"
		end;
	else
		return false, "Укажите ID.";
	end;
end;

-------------------
-- REQUEST HOOKS --
-------------------

function greenCode.request:OnRequestOut( REQUEST )
	local targetPlayer = REQUEST:GetPlayer();
	local orderPlayer = REQUEST:GetOrder();

	if ( IsValid(targetPlayer) and IsValid(orderPlayer) ) then
		REQUEST:SendHint( orderPlayer, "Действие запроса '"..REQUEST:Name().."' к "..targetPlayer:Name().." истек.", 5, Color(100,255,100) );
		REQUEST:SendHint( targetPlayer, "Действие запроса '"..REQUEST:Name().."' от "..orderPlayer:Name().." истек.", 5, Color(100,255,100) );
	end;
end;

function greenCode.request:OnRequestAnswer( REQUEST, bAnswer )
	local targetPlayer = REQUEST:GetPlayer();
	local orderPlayer = REQUEST:GetOrder();
	local sAction = bAnswer and " согласился на " or " дал отказ на ";
	REQUEST:SendHint( orderPlayer, targetPlayer:Name()..sAction.."'"..REQUEST:Name().."'", 15, bAnswer and Color(100,255,100) or Color(255,100,100) );
end;

function greenCode.request:OnRequestCreate( REQUEST )
	local targetPlayer = REQUEST:GetPlayer();
	local orderPlayer = REQUEST:GetOrder();
	
	REQUEST:SendHint( targetPlayer, orderPlayer:Name().." запросил у вас '"..REQUEST:Name().."'  < /да "..REQUEST:UniqueID().." > или < /нет "..REQUEST:UniqueID().." >", 30, Color(100,255,100) );
	REQUEST:SendHint( orderPlayer, "Игроку "..targetPlayer:Name().." отправлен запрос на '"..REQUEST:Name().."'.", 15, Color(100,255,100) );
end;

greenCode.chat:AddCommand( "да", function( player, tArguments )
	local bDone, sReason = greenCode.request:Answer( player, tonumber(tArguments), true );
	greenCode.hint:Send( player, sReason or "#None", 5, bDone and Color(100,255,100) or Color(255,100,100) );
end)

greenCode.chat:AddCommand( "нет", function( player, tArguments )
	local bDone, sReason = greenCode.request:Answer( player, tonumber(tArguments), false );
	greenCode.hint:Send( player, sReason or "#None", 5, bDone and Color(100,255,100) or Color(255,100,100) );
end)

greenCode.command:Add( "request_list", 1, function( player, command, args )
	local curTime = CurTime();
	
	for uid, REQUEST in pairs( greenCode.request:GetAll() ) do		
		player:PrintMsg(2, "\t" .. tostring( uid ) .. "\t[" .. REQUEST:Name() .. "] " .. greenCode.kernel:ConvertTime(math.Round(REQUEST:GetTimeOut() - curTime)));
	end;
end);*/