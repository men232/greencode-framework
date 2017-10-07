--[[
	© 2013 GmodLive private project do not share
	without permission of its author (Andrew Mensky vk.com/men232).
--]]

local greenCode = greenCode;
local math = math;
local SESSION_DIR = "sessions/stored/";

greenCode.session        = greenCode.kernel:NewLibrary("Session");
greenCode.session.buffer = {};
greenCode.session.active = {};

RunConsoleCommand( "sv_timeout", greenCode.config:Get("session_timeout"):Get(180) );

-------------------
-- Session Class --
-------------------

SESSION_CLASS = greenCode.kernel:CreateBasicClass();

function SESSION_CLASS:SetData( key, value )
	if ( self:IsValid() and self.data[key] != nil ) then
		local perv_value = self.data[key];
		self.data[key] = value;
		greenCode.plugin:Call( "OnSessionChangeData", self, key, value, perv_value );
		return true;
	end;
end;

function SESSION_CLASS:GetName() return self( "name", "Unknown" ); end;
function SESSION_CLASS:Name() return self:GetName(); end;
function SESSION_CLASS:UniqueID() return self( "uid", -1 ); end;
function SESSION_CLASS:GetTimeOut() return self( "timeout", -1 ); end;
function SESSION_CLASS:IsActive() return self:GetTimeOut() >= 0 and greenCode.session.active[ self:UniqueID() ]; end;

-- A function to check active session.
function SESSION_CLASS:IsClosing()
	local nTimeOut = self:GetTimeOut();
	return ( nTimeOut > 0 and nTimeOut < 2 );
end;

function SESSION_CLASS:SetTimeOut( nTime )
	local curTimeOut = self:GetTimeOut();
	self:SetData("timeout", nTime);
	greenCode.plugin:Call( "OnSessionChangeTimeOut", self, self:GetTimeOut(), curTimeOut );
end;

function SESSION_CLASS:Extend( nTime )
	local nTimeOut = self:GetTimeOut();
	self:SetTimeOut( nTimeOut + nTime );
end;

function SESSION_CLASS:GetParent() return greenCode.session:FindByID( self("parent", -1) ); end;

function SESSION_CLASS:SetParent( uid )
	if ( type(uid) == "table" ) then
		uid = uid:UniqueID();
	end;
	
	self:SetData("parent", uid);
end;

function SESSION_CLASS:SetName( sName )
	local curName = self:Name();
	self:SetData("name", sName);
	greenCode.plugin:Call( "OnSessionRename", self, sName, curName );
end;

function SESSION_CLASS:Open( nTime, sReason )
	if ( self:IsValid() ) then
		if ( nTime ) then
			self:SetTimeOut( nTime );
		end;

		greenCode.session.active[ self:UniqueID() ] = true;
		greenCode.plugin:Call( "OnSessionOpen", self, sReason or "just open session." );
	end;
end;

function SESSION_CLASS:Close( bStilly, sReason, bNoSave, nCloseStep )
	if ( self:IsValid() and self:IsActive() ) then
		self:SetTimeOut( -1 );

		local sessionUid = self:UniqueID();
		local sessionName = self:Name();
		greenCode.session.active[ sessionUid ] = nil;
		nCloseStep = nCloseStep or 0;

		for uid, SESSION in pairs( greenCode.session:GetAll( true ) ) do
			if ( sessionUid == uid or !SESSION:IsActive() ) then
				continue;
			end;

			local PARENT = SESSION:GetParent();

			if ( PARENT and PARENT:IsValid() and PARENT:UniqueID() == sessionUid ) then
				SESSION:Close( bStilly, "Parent -> [ "..sessionUid.." => "..sessionName.." ]", true, nCloseStep+1 );
			end;
		end;

		if ( !bNoSave ) then
			greenCode.session:Save( sessionUid );
		end;

		greenCode.plugin:Call( "OnSessionClose", self, sReason or "just close session." );
		return true;
	end;

	return false;
end;

-- A function to get a first parent.
local tParentCachedKey = {};

function SESSION_CLASS:GetFirstParent( nKey )
	local PARENT = self:GetParent();
	
	if ( PARENT and PARENT:IsValid() ) then
		local uid             = parent:UniqueID()
		local nKey            = nKey or util.CRC(os.time() + CurTime());
		tParentCachedKey[nKey] = tParentCachedKey[nKey] or {};
		
		if ( !tParentCachedKey[nKey][uid] ) then
			tParentCachedKey[nKey][uid] = true;
			return parent:GetFirstParent( nKey );
		end
	end;

	tParentCachedKey[nKey] = nil;
	return self;
end;

function SESSION_CLASS:Register( ... ) return greenCode.session:Register( self, ... ); end;

function SESSION_CLASS:New( tMergeTable )
	local object = { 
		data = {
			uid = -1,
			className = "SESSION",
			name = "Unknown",
			parent = -1,
			timeout = greenCode.config:Get("session_timeout"):Get(180)
		},
	};

	if ( tMergeTable ) then
		table.Merge( object.data, tMergeTable );
	end;

	setmetatable( object, self );
	self.__index = self;

	if ( object("uid", -1) == -1 ) then	
		object:SetData("uid", tonumber(util.CRC(object:Name())));
	end;

	return object;
end;

--------------------------
-- LIB SESSION FUNCTION --
--------------------------

-- A function to save all session.
function greenCode.session:Save( uid )
	if ( !uid ) then
		for uid, SESSION in pairs( self.buffer ) do
			greenCode.kernel:SaveGameData("sessions/stored/"..uid, SESSION.data);
		end;

		greenCode:Success( "Save Session", "everything" );

	elseif self.buffer[ uid ] then
		greenCode.kernel:SaveGameData( "sessions/stored/"..uid, self.buffer[ uid ].data );
		greenCode:Success( "Save Session", uid );
	end;
	
	greenCode.kernel:SaveGameData("sessions/active", self.active);
end;

-- A function to load all session.
function greenCode.session:Load()
	self:CleanBuffer();
	self.active = greenCode.kernel:RestoreGameData("sessions/active", {});

	greenCode.session:GetAll();

	greenCode:Success( "Load Session", "load session data." );
end;

function greenCode.session:Restore( uid )
	if ( greenCode.kernel:GameDataExists( SESSION_DIR..uid ) ) then
		local tSessionData = greenCode.kernel:RestoreGameData( SESSION_DIR..uid );
		
		if ( tSessionData ) then
			local SESSION = SESSION_CLASS:New( tSessionData ):Register( true );
			
			if ( SESSION ) then
				greenCode.plugin:Call( "OnSessionRestore", SESSION );
				return SESSION;
			end;
		end;
	end;
end;

function greenCode.session:CleanBuffer()
	self.buffer = {};
end;

function greenCode.session:Register( SESSION, bRestore )
	if ( SESSION and SESSION:IsValid() ) then
		local uid = SESSION:UniqueID();
		
		if ( !self.buffer[uid] ) then
			self.buffer[uid] = SESSION;

			if ( !bRestore ) then
				self.active[ uid ] = true;
				self:Save( uid );
				greenCode.plugin:Call( "OnSessionCreate", SESSION );
			end;

			return self.buffer[uid], uid;
		end;
	end;
	
	return false;
end;

function greenCode.session:FindByID( uid )
	return self.buffer[uid] or self:Restore( uid );	
end;

function greenCode.session:GetAll( bOnlyActive )
	local tReturnTable = {};
	
	for uid, _ in pairs( self.active ) do
		local SESSION = self:FindByID( uid );

		if ( SESSION and ( !bOnlyActive or SESSION:IsActive() ) ) then
			tReturnTable[uid] = SESSION;
		end
	end;
	
	for uid, SESSION in pairs( self.buffer ) do
		if ( tReturnTable[uid] ) then
			continue;
		end
		
		if ( !bOnlyActive or SESSION:IsActive() ) then
			tReturnTable[uid] = SESSION;
		end;
	end;
	
	return tReturnTable;
end;

function greenCode.session:GetPlayerData( player )
	local uid, sid, sName;

	if ( type(player) == "number" ) then
		local SESSION = self:FindByID(player);
		uid = player;
		sid = (SESSION and SESSION:IsValid()) and SESSION("sid", "Unknown") or "Unknown";
		sName = (SESSION and SESSION:IsValid()) and SESSION:Name() or "Unknown";
	else
		uid = tonumber(player:UniqueID());
		sid = player:SteamID();
		sName = player:Name();
	end;

	return uid, sid, sName;
end;

-------------------
-- SESSION HOOKS --
-------------------

-- Called when player authed.
function greenCode.session:PlayerAuthed( player, sid, uid )
	local uid      = tonumber(uid);
	local nTimeOut = greenCode.config:Get("session_timeout"):Get(180); 
	local SESSION  = self:FindByID( uid );

	if ( !SESSION ) then
		local sName = player:Name();	
		SESSION = SESSION_CLASS:New{ name = sName, uid = uid, sid = sid, timeout = nTimeOut }:Register();
	else
		SESSION:SetTimeOut( nTimeOut );
	end;
end;

-- Called when player disconnected.
function greenCode.session:PlayerDisconnected( player )
	local uid      = tonumber(player:UniqueID());
	local SESSION  = self:FindByID( uid );

	if ( SESSION and SESSION:IsValid() ) then
		SESSION:SetTimeOut( greenCode.config:Get("session_timeout"):Get(180) );
	end;
end;

-- Called witch seccond interval.
function greenCode.session:TickSecond( curTime )
	for uid, SESSION in pairs( self:GetAll( true ) ) do
		if ( SESSION and SESSION:IsValid() ) then
			if ( SESSION:IsClosing() ) then
				greenCode.plugin:Call( "PreSessionClose", SESSION, uid );
			end;

			SESSION:Extend( -1 );
		end;
	end;
end;

-- Called at an interval while a player is connected.
function greenCode.session:PlayerThink( player )
	local uid     = tonumber(player:UniqueID());
	local SESSION = self:FindByID( uid );

	if ( !SESSION or !SESSION:IsValid() ) then
		self:PlayerAuthed( player, player:SteamID(), uid )
	elseif ( !SESSION:IsActive() ) then
		SESSION:SetTimeOut( /*greenCode.config:Get("session_timeout"):Get(180)*/ 10 );
	else
		local sPlayerName = player:Name();
		local sSessionName = SESSION:GetName();

		if ( sSessionName != sPlayerName ) then
			SESSION:SetName( sPlayerName );
		end;
	end;
end;

-- Called when session pre closing.
function greenCode.session:PreSessionClose( SESSION, uid )
	local player = player.GetByUniqueID( tostring(uid) );

	if ( player and IsValid( player ) ) then
		SESSION:Extend( greenCode.config:Get("session_timeout"):Get(180) );
	end;
end;

-- Called when session timeout value change.
function greenCode.session:OnSessionChangeTimeOut( SESSION, nValue, nPrev )
	local bActive = SESSION:IsActive();
	local difference = math.abs( nValue - nPrev );

	if ( nValue <= 0 and bActive ) then
		SESSION:Close( nil, "TimeOut" );
	elseif ( nValue > 0 and !bActive ) then
		SESSION:Open();
	end;

	if ( difference > 1 ) then
		self:Save(SESSION:UniqueID());
		
		local sAction = nPrev < nValue and "extend" or "change timeout";
		greenCode.hint:SendAll( "Session ["..SESSION:UniqueID().." => "..SESSION:Name().."] "..sAction.." "..nValue..".", 5, Color(255,255,255), true, true );
	end;
end;

function greenCode.session:OnSessionChangeData( SESSION, key, value, perv )
	if ( key != "timeout" ) then
		self:Save(SESSION:UniqueID());
	end;
end;

-- Called when session is open.
function greenCode.session:OnSessionOpen( SESSION, sReason )
	greenCode.hint:SendAll( "Open Session ["..SESSION:UniqueID().." => "..SESSION:Name().."] [ "..sReason.." ].", 5, Color(255,255,255), true, true );
end;

-- Called when session is close.
function greenCode.session:OnSessionClose( SESSION, sReason )
	greenCode.hint:SendAll( "Close Session ["..SESSION:UniqueID().." => "..SESSION:Name().."] ["..sReason.."].", 5, Color(255,255,255), true, true );
end;

-- Called when session change name.
function greenCode.session:OnSessionRename( SESSION, sName, sPrevName )
	greenCode.hint:SendAll( "Rename Session ["..SESSION:UniqueID().." => "..sPrevName.."] to ["..sName.."].", 5, Color(255,255,255), true, true );
end;

-- Called when create new session.
function greenCode.session:OnSessionCreate( SESSION )
	greenCode.hint:SendAll( "Create Session [ "..SESSION:UniqueID().." => "..SESSION:Name().." ].", 5, Color(255,255,255), true, true );
end;

-- Called when session restore from pc data.
function greenCode.session:OnSessionRestore( SESSION )
	greenCode.hint:SendAll( "Restore Session data [ "..SESSION:UniqueID().." => "..SESSION:Name().." ].", 5, Color(255,255,255), true, true );
end;

greenCode.session:Load();

greenCode.command:Add( "session_list", 1, function( player, command, args )
	for uid, SESSION in pairs( greenCode.session:GetAll( true ) ) do		
		local PARENT = SESSION:GetParent();
		player:PrintMsg(2, "\t" .. tostring( uid ) .. "\t[" .. SESSION:Name() .. "]" .. ( PARENT and (" parent: " .. PARENT:Name() .."["..PARENT:UniqueID().."] ") or " ") .. greenCode.kernel:ConvertTime(SESSION:GetTimeOut()));
	end;
end);

greenCode.command:Add( "session_cleanbuffer", 2, function( player, command, args )
	greenCode.session:CleanBuffer()
	player:PrintMsg(2, "Session buffer is cleared");
end);

greenCode.command:Add( "session_preparent_close", 2, function( player, command, args )
	for uid, SESSION in pairs( greenCode.session:GetAll( true ) ) do	
		local PARENT = SESSION:GetParent();
		
		if ( PARENT and PARENT:IsValid() and !PARENT:IsActive() ) then
			SESSION:Close( nil, "Parent -> [ "..PARENT:UniqueID().." => "..PARENT:Name().." ]" )
		end;
	end;
end);