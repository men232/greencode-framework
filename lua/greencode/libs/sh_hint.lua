--[[
	© 2013 GmodLive private project do not share
	without permission of its author (Andrew Mensky vk.com/men232).
--]]

local greenCode = greenCode;
local pairs = pairs;
local math = math;

greenCode.hint = greenCode.kernel:NewLibrary("Hint");
greenCode.hint.stored = {};

if SERVER then

	function greenCode.hint:Send( player, text, delay, color, bNoSound, bShowDuplicates )
		gc.datastream:Start(player, "Hint", {
			text = text, delay = delay, color = color, noSound = bNoSound, showDuplicates = bShowDuplicates
		});
	end;

	function greenCode.hint:SendAll( text, delay, color, bShowDuplicates, bOnlyAdmin )
		for k, v in pairs(_player.GetAll()) do
			if ( v:HasInitialized() and ( !bOnlyAdmin or v:IsAdmin() ) ) then
				self:Send(v, text, delay, color, nil, bShowDuplicates);
			end;
		end;
	end;

else

	function greenCode.hint:Add(text, delay, color, bNoSound, bShowDuplicates)
		local colorWhite = Color(255, 255, 255, 255);
		
		if ( !color ) then
			color = colorWhite;
		end;

		if ( !text ) then
			text = "#Text"
		end;

		MsgC(color, "[System] "..text.."\n");
		
		if (!bShowDuplicates) then
			for k, v in pairs(self.stored) do
				if (v.text == text) then
					return;
				end;
			end;
		end;

		if (table.Count(self.stored) == 10) then
			table.remove(self.stored, 10);
		end;
		
		if (type(bNoSound) == "string") then
			surface.PlaySound(bNoSound);
		elseif (bNoSound == nil) then
			//surface.PlaySound("hl1/fvox/blip.wav");
			surface.PlaySound("ui/buttonrollover.wav");
		end;
		
		self.stored[#self.stored + 1] = {
			startTime = SysTime(),
			velocityX = -5,
			velocityY = 0,
			targetAlpha = 255,
			alphaSpeed = 64,
			color = color,
			delay = delay,
			alpha = 0,
			text = text,
			y = ScrH() * 0.3,
			x = ScrW() + 200
		};
	end;

	local function UpdateHint( index, hintInfo, iCount )
		local hintsFont = "gcIntroTextTiny";
		local fontWidth, fontHeight = gc.kernel:GetCachedTextSize(
			hintsFont, hintInfo.text
		);
		local height = fontHeight;
		//local width = fontWidth;
		local alpha = 255;
		local x = hintInfo.x;
		local y = hintInfo.y;
		
		--[[ Work out the ideal X and Y position for the hint. --]]
		local idealY = 25 + (height * (index - 1));
		local idealX = ScrW() - 32;
		local timeLeft = (hintInfo.startTime - (SysTime() - hintInfo.delay) + 2);
		
		if (timeLeft < 0.7) then
			idealX = idealX - 50;
			alpha = 0;
		end;
		
		if (timeLeft < 0.2) then
			idealX = idealX * 2;
		end;
		
		local fSpeed = FrameTime() * 15;
			y = y + hintInfo.velocityY * fSpeed;
			x = x + hintInfo.velocityX * fSpeed;
		local distanceY = idealY - y;
		local distanceX = idealX - x;
		local distanceA = (alpha - hintInfo.alpha);
		
		hintInfo.velocityY = hintInfo.velocityY + distanceY * fSpeed * 1;
		hintInfo.velocityX = hintInfo.velocityX + distanceX * fSpeed * 1;
		
		if (math.abs(distanceY) < 2 and math.abs(hintInfo.velocityY) < 0.1) then
			hintInfo.velocityY = 0;
		end;
		
		if (math.abs(distanceX) < 2 and math.abs(hintInfo.velocityX) < 0.1) then
			hintInfo.velocityX = 0;
		end;
		
		hintInfo.velocityX = hintInfo.velocityX * (0.95 - FrameTime() * 8);
		hintInfo.velocityY = hintInfo.velocityY * (0.95 - FrameTime() * 8);
		hintInfo.alpha = hintInfo.alpha + distanceA * fSpeed * 0.1;
		hintInfo.x = x;
		hintInfo.y = y;
		
		--[[ Remove it if we're finished. --]]
		return (timeLeft < 0.1);
	end;

	function greenCode.hint:Think()
		for k, v in pairs(self.stored) do
			if ( UpdateHint(k, v, #self.stored) ) then
				table.remove(self.stored, k);
			end;
		end;
	end;

	-- Called when the local player attempts to see the top hints.
	function greenCode.hint:PlayerCanSeeHints()
		return true;
	end;

	function greenCode.hint:HUDPaint()
		if (gc.plugin:Call("PlayerCanSeeHints") and #self.stored > 0) then
			local hintsFont = "gcIntroTextTiny";
			
			for k, v in pairs(self.stored) do
				gc.kernel:DrawInfo(v.text, v.x, v.y, v.color, v.alpha, true, nil, nil, TEXT_ALIGN_RIGHT);
			end;
		end;
	end;

	greenCode.datastream:Hook("Hint", function(data)
		if (data and type(data) == "table") then
			greenCode.hint:Add(
				data.text, data.delay, data.color, data.noSound, data.showDuplicates
			);
		end;
	end);
end;

if SERVER then
	greenCode.command:Add( "alert", 2, function( player, command, args )
		//player:ShowHint( args[1], 5 );
		//player:ShowAlert( args[1], Color( 150,255,150,255 ) );
		greenCode.hint:SendAll( args[1], 5, Color( 150,255,150,255 ), true, false );
	end);
end;