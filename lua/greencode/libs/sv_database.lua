--[[
	© 2013 GmodLive private project do not share
	without permission of its author (Andrew Mensky vk.com/men232).
--]]

require("mysqloo");

local mysqloo = mysqloo;
local ErrorNoHalt = ErrorNoHalt;
local tostring = tostring;
local error = error;
local pairs = pairs;
local pcall = pcall;
local type = type;
local string = string;
local table = table;

greenCode.database = greenCode.kernel:NewLibrary("Database");
greenCode.database.updateTable = nil;

--[[ Define the database update class metatable. --]]
MYSQL_UPDATE_CLASS = {__index = MYSQL_UPDATE_CLASS};
MYSQL_CONNECTION = MYSQL_CONNECTION or nil;
MYSQL_QUEUE = MYSQL_QUEUE or {};

-- A function to set the table to update.
function MYSQL_UPDATE_CLASS:SetTable(tableName)
	self.tableName = tableName;
	return self;
end;

-- A function to set a value for the table update.
function MYSQL_UPDATE_CLASS:SetValue(key, value)
	self.updateVars[key] = greenCode.database:Escape(tostring(value));
	return self;
end;

-- A function to replace a value for the table update.
function MYSQL_UPDATE_CLASS:Replace(key, search, replace)
	search = "\""..greenCode.database:Escape(tostring(search)).."\"";
	replace = "\""..greenCode.database:Escape(tostring(replace)).."\"";
	self.updateVars[key] = "REPLACE("..key..", \""..search.."\", \""..replace.."\")";
	
	return self;
end;

-- A function to add a requirement for the update.
function MYSQL_UPDATE_CLASS:AddWhere(key, value)
	value = greenCode.database:Escape(tostring(value));
		self.updateWhere[#self.updateWhere + 1] = string.gsub(key, '?', "\""..value.."\"");
	return self;
end;

-- A function to add a callback for the update.
function MYSQL_UPDATE_CLASS:SetCallback(Callback)
	self.Callback = Callback;
	return self;
end;

-- A function to push the update to the database.
function MYSQL_UPDATE_CLASS:Push()
	if (!self.tableName) then return; end;
	
	local updateQuery = "";
	
	for k, v in pairs(self.updateVars) do
		if (updateQuery == "") then
			updateQuery = "UPDATE "..self.tableName.." SET "..k.." = \""..v.."\"";
		else
			updateQuery = updateQuery..", "..k.." = \""..v.."\"";
		end;
	end;
	
	if (updateQuery == "") then return; end;
	
	local whereTable = {};
	
	for k, v in pairs(self.updateWhere) do
		whereTable[#whereTable + 1] = v;
	end;
	
	local whereString = table.concat(whereTable, " AND ");
	
	if (whereString != "") then
		greenCode.database:Query(updateQuery.." WHERE "..whereString, self.Callback );
	else
		greenCode.database:Query(updateQuery, self.Callback );
	end;
end;

--[[ Define the database insert class metatable. --]]
MYSQL_INSERT_CLASS = {__index = MYSQL_INSERT_CLASS};

-- A function to set the table to insert into.
function MYSQL_INSERT_CLASS:SetTable(tableName)
	self.tableName = tableName;
	return self;
end;

-- A function to set a value for the insertion.
function MYSQL_INSERT_CLASS:SetValue(key, value)
	self.insertVars[key] = value;
	return self;
end;

-- A function to add a callback for the insert.
function MYSQL_INSERT_CLASS:SetCallback(Callback)
	self.Callback = Callback;
	return self;
end;

-- A function to push the insert to the database.
function MYSQL_INSERT_CLASS:Push()
	if (!self.tableName) then return; end;
	
	local keyList = {};
	local valueList = {};
	
	for k, v in pairs(self.insertVars) do
		keyList[#keyList + 1] = k;
		valueList[#valueList + 1] = "\""..greenCode.database:Escape(tostring(v)).."\"";
	end;
	
	if (#keyList == 0) then return; end;
	
	local insertQuery = "INSERT INTO "..self.tableName.." ("..table.concat(keyList, ", ")..")";
		insertQuery = insertQuery.." VALUES("..table.concat(valueList, ", ")..")";
	greenCode.database:Query(insertQuery, self.Callback );
end;

--[[ Define the database select class metatable. --]]
MYSQL_SELECT_CLASS = {__index = MYSQL_SELECT_CLASS};

-- A function to set the table to select from.
function MYSQL_SELECT_CLASS:SetTable(tableName)
	self.tableName = tableName;
	return self;
end;

--[[
	A function to add a column to select.
	Use * as a wildcard to select all columns.
--]]
function MYSQL_SELECT_CLASS:AddColumn(key)
	self.selectColumns[#self.selectColumns + 1] = key;
	return self;
end;

-- A function to add a requirement for the selection.
function MYSQL_SELECT_CLASS:AddWhere(key, value)
	value = greenCode.database:Escape(tostring(value));
		self.selectWhere[#self.selectWhere + 1] = string.gsub(key, '?', "\""..value.."\"");
	return self;
end;

-- A function to add a callback for the selection.
function MYSQL_SELECT_CLASS:SetCallback(Callback)
	self.Callback = Callback;
	return self;
end;

-- A function to set the order for the selection.
function MYSQL_SELECT_CLASS:SetOrder(key, value)
	self.Order = key.." "..value;
	return self;
end;

-- A function to pull the selection from the database.
function MYSQL_SELECT_CLASS:Pull()
	if (!self.tableName) then return; end;
	
	if (#self.selectColumns == 0) then
		self.selectColumns[#self.selectColumns + 1] = "*";
	end;
	
	local selectQuery = "SELECT "..table.concat(self.selectColumns, ", ").." FROM "..self.tableName;
	local whereTable = {};
	
	for k, v in pairs(self.selectWhere) do
		whereTable[#whereTable + 1] = v;
	end;
	
	local whereString = table.concat(whereTable, " AND ");
	
	if (whereString != "") then
		selectQuery = selectQuery.." WHERE "..whereString;
	end;
	
	if (self.selectOrder != "") then
		selectQuery = selectQuery.." ORDER BY "..self.selectOrder;
	end;
	
	greenCode.database:Query( selectQuery, self.Callback );
end;

--[[ Define the database delete class metatable. --]]
MYSQL_DELETE_CLASS = {__index = MYSQL_DELETE_CLASS};

-- A function to set the table to delete from.
function MYSQL_DELETE_CLASS:SetTable(tableName)
	self.tableName = tableName;
	return self;
end;

-- A function to add a requirement for the deletion.
function MYSQL_DELETE_CLASS:AddWhere(key, value)
	value = greenCode.database:Escape(tostring(value));
		self.deleteWhere[#self.deleteWhere + 1] = string.gsub(key, '?', "\""..value.."\"");
	return self;
end;

-- A function to add a callback for the deletion.
function MYSQL_DELETE_CLASS:SetCallback(Callback)
	self.Callback = Callback;
	return self;
end;

-- A function to push the deletion to the database.
function MYSQL_DELETE_CLASS:Push()
	if (!self.tableName) then return; end;
	
	local deleteQuery = "DELETE FROM "..self.tableName;
	local whereTable = {};
	
	for k, v in pairs(self.deleteWhere) do
		whereTable[#whereTable + 1] = v;
	end;
	
	local whereString = table.concat(whereTable, " AND ");
	
	if (whereString != "") then
		greenCode.database:Query(deleteQuery.." WHERE "..whereString, self.Callback);
	else
		greenCode.database:Query(deleteQuery, self.Callback);
	end;
end;

-- A function to begin a database update.
function greenCode.database:Update(tableName)
	local object = greenCode.kernel:NewMetaTable(MYSQL_UPDATE_CLASS);
		object.updateVars = {};
		object.updateWhere = {};
		object.tableName = tableName;
	return object;
end;

-- A function to begin a database insert.
function greenCode.database:Insert(tableName)
	local object = greenCode.kernel:NewMetaTable(MYSQL_INSERT_CLASS);
		object.insertVars = {};
		object.tableName = tableName;
	return object;
end;

-- A function to begin a database select.
function greenCode.database:Select(tableName)
	local object = greenCode.kernel:NewMetaTable(MYSQL_SELECT_CLASS);
		object.selectColumns = {};
		object.selectWhere = {};
		object.selectOrder = "";
		object.tableName = tableName;
	return object;
end;

-- A function to begin a database delete.
function greenCode.database:Delete(tableName)
	local object = greenCode.kernel:NewMetaTable(MYSQL_DELETE_CLASS);
		object.deleteWhere = {};
		object.tableName = tableName;
	return object;
end;

-- Called when a MySQL error occurs.
function greenCode.database:Error(errText)
	if (errText) then
		error("[GreenCode] MySQL Error: "..errText.."\n");
	end;
end;

-- A function to query the database.
function greenCode.database:Query( sql, Callback )
	local query = MYSQL_CONNECTION:query( sql );

	print( sql .."\n" );

	query.onError = function( q, err, sql )
		if MYSQL_CONNECTION:status() == mysqloo.DATABASE_NOT_CONNECTED then
			table.insert( MYSQL_QUEUE, { sql, Callback or function() end } );
			MYSQL_CONNECTION:connect();
		end;

		greenCode.database:Error( err );
	end;

	query.onSuccess = function( q, data )
		if ( Callback ) then
			Callback(data);
		end;
	end;

	query:start();
end;

-- A function to get whether a result is valid.
function greenCode.database:IsResult(result)
	return (result and type(result) == "table" and #result > 0);
end;

-- A function to make a string safe for SQL.
function greenCode.database:Escape(text)
	return MYSQL_CONNECTION:escape(text);
end;

-- Called when the database is connected.
function greenCode.database:OnConnected()
	local PLAYERS_TABLE_QUERY = [[
	CREATE TABLE IF NOT EXISTS `]]..gc.config:Get("mysql_players_table"):Get("green_player")..[[` (
		`_Uid` BIGINT NOT NULL UNIQUE,
		`_Data` text NOT NULL,
		`_SteamID` varchar(60) NOT NULL,
		`_IPAddress` varchar(50) NOT NULL,
		`_SteamName` varchar(150) NOT NULL,
		`_LastPlayed` varchar(50) NOT NULL,
		`_Attributes` text NOT NULL,
		PRIMARY KEY (`_Uid`) );
	]];

	self:Query( string.gsub(PLAYERS_TABLE_QUERY, "%s", " "), nil );

	greenCode:Success( "GreenCode MySQL", "connected!" );
	
	greenCode.NoMySQL = false;
	greenCode.plugin:Call("GreenCodeDatabaseConnected");
end;

-- Called when the database connection fails.
function greenCode.database:OnConnectionFailed(errText)
	greenCode:Error( "GreenCode MySQL Error", errText );

	greenCode.NoMySQL = errText;
	
	greenCode.plugin:Call("GreenCodeDatabaseConnectionFailed", errText);
end;

-- A function to connect to the database.
function greenCode.database:Connect(host, username, password, database, port)
	if (host == "localhost") then
		host = "127.0.0.1";
	end;
	
	local bSuccess, databaseConnection, errText = pcall(mysqloo.connect, host, username, password, database, port);

	if ( databaseConnection ) then
		databaseConnection.onConnected = function( db )
			self:OnConnected();

			for k, v in pairs( MYSQL_QUEUE ) do
				greenCode.database:Query( v[ 1 ], v[ 2 ] );
			end;

			MYSQL_QUEUE = {};
		end;

		databaseConnection.onConnectionFailed = function( db, err )
			self:OnConnectionFailed(err);
		end;

	else
		self:OnConnectionFailed( errText or "Somtinh wrong" );
	end;

	databaseConnection:connect();
	MYSQL_CONNECTION = databaseConnection;
end;

-- A function to connect to the database.
function greenCode.database:GreenCodeInitialized()
	local dbHost = gc.config:Get( "mysql_host" ):GetString( "localhost" );
	local dbUser = gc.config:Get( "mysql_username" ):GetString( "root" );
	local dbPass = gc.config:Get( "mysql_password" ):GetString( "" );
	local dbName = gc.config:Get( "mysql_database" ):GetString( "greencode" );
	local dbPort = gc.config:Get( "mysql_port" ):GetInt( 3306 );

	greenCode.database:Connect( dbHost, dbUser, dbPass, dbName, dbPort );
end;

--[[
	EXAMPLE:
	
	local myInsert = greenCode.database:Insert();
		myInsert:SetTable("players");
		myInsert:SetValue("_Name", "Joe");
		myInsert:SetValue("_SteamID", "STEAM_0:1:9483843344");
		myInsert:AddCallback(MyCallback);
	myInsert:Push();
--]]