--[[
	© 2013 GmodLive private project do not share
	without permission of its author (Andrew Mensky vk.com/men232).
--]]

local gc = gc;
local pairs = pairs;
local string = string;

gc.attribute = gc.kernel:NewLibrary("Attribut");
gc.attribute.stored = {};
gc.attribute.buffer = {};

--[[ Set the __index meta function of the class. --]]
local CLASS_TABLE = {__index = CLASS_TABLE};

-- A function to register a new attribute.
function CLASS_TABLE:Register()
	return gc.attribute:Register(self);
end;

-- A function to get a new attribute.
function gc.attribute:New(name)
	local object = gc.kernel:NewMetaTable(CLASS_TABLE);
		object.name = name or "Inconnu";
	return object;
end;

-- A function to get the attribute buffer.
function gc.attribute:GetBuffer()
	return self.buffer;
end;

-- A function to get all attributes.
function gc.attribute:GetAll()
	return self.stored;
end;

-- A function to register a new attribute.
function gc.attribute:Register(attribute)
	attribute.uniqueID = attribute.uniqueID or string.lower(string.gsub(attribute.name, "%s", "_"));
	attribute.index = gc.kernel:GetShortCRC(attribute.name);
	attribute.cache = {};
	
	for i = -attribute.maximum, attribute.maximum do
		attribute.cache[i] = {};
	end;
	
	self.stored[attribute.uniqueID] = attribute;
	self.buffer[attribute.index] = attribute;
	
	if (SERVER and attribute.image) then
		gc.kernel:AddFile("materials/"..attribute.image..".png");
	end;
	
	return attribute.uniqueID;
end;

-- A function to find an attribute by an identifier.
function gc.attribute:FindByID(identifier)
	if (!identifier) then return; end;
	
	if (self.buffer[identifier]) then
		return self.buffer[identifier];
	elseif (self.stored[identifier]) then
		return self.stored[identifier];
	end;
	
	local tAttributeTab = nil;
	
	for k, v in pairs(self.stored) do
		if (string.find(string.lower(v.name), string.lower(identifier))) then
			if (tAttributeTab) then
				if (string.len(v.name) < string.len(tAttributeTab.name)) then
					tAttributeTab = v;
				end;
			else
				tAttributeTab = v;
			end;
		end;
	end;
	
	return tAttributeTab;
end;