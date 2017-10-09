--[[
	© 2013 GmodLive private project do not share
	without permission of its author (Andrew Mensky vk.com/men232).
--]]

local greenCode = greenCode;
local pairs = pairs;
local math = math;
local ScrW = ScrW;
local ScrH = ScrH;

greenCode.alert = greenCode.kernel:NewLibrary("Alert");
greenCode.alert.stored = {};

if SERVER then

	-- A function to alert a player.
	function greenCode.alert:Send( player, text, color )
		gc.datastream:Start(player, "Alert", {
			text = text, color = color
		});
	end;

	-- A function to alert each player.
	function greenCode.alert:SendAll( text, color )
		for k, v in pairs(_player.GetAll()) do
			if (v:HasInitialized()) then
				self:Send( v, text, color );
			end;
		end;
	end;

else

	function greenCode.alert:HUDPaint()
		local scrW = ScrW();
		local scrH = ScrH();
		local k, v;
		
		-- Loop through each value in a table.
		for k, v in pairs(self.stored) do
			v.alpha = math.Clamp(v.alpha - v.speed, 0, 255); v.add = v.add + v.speed;
			
			-- Check if a statement is true.
			if ( self.stored[k - 1] ) then
				if ( (scrH - 64 - v.add) < ( (scrH - 64 - self.stored[k - 1].add) + 24 ) ) then
					v.add = v.add - 24;
				end;
			end;
			
			-- Draw some information.
			gc.kernel:DrawInfo(v.text, scrW, scrH - (scrH / 6) - v.add, v.color, v.alpha, true, function(x, y, width, height)
				return x - width - 8, y - height - 8;
			end);
			
			-- Check if a statement is true.
			if (v.alpha == 0) then
				self.stored[k] = nil;
			end;
		end;
	end;
	
	-- A function to add an alert.
	function greenCode.alert:Add(text, color)
		local alert = {	color = color, alpha = 255, text = text, add = 1, speed = 0.3 };
		
		-- Play a sound.
		surface.PlaySound("buttons/button15.wav");
		
		-- Set some information.
		self.stored[#self.stored + 1] = alert;
		
		-- Print the alert.
		print(alert.text);
	end;
	
	function greenCode.alert:GreenCodeInitialized()
		greenCode.datastream:Hook("Alert", function(data)
			if (data and type(data) == "table") then
				greenCode.alert:Add(
					data.text, data.color
				);
			end;
		end);
	end;
end;