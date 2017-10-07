--[[
	© 2013 GmodLive private project do not share
	without permission of its author (Andrew Mensky vk.com/men232).
--]]

local greenCode = greenCode;
local math= math;
local gc = gc;

local PLUGIN = PLUGIN or greenCode.plugin:Loader();

-- Called when the local player's headbob info should be adjusted.
function PLUGIN:PlayerAdjustHeadbobInfo( info )
	local scale = 1;
	
	if ( greenCode.Client:IsRunning() ) then
		info.speed = (info.speed * 8) * scale;
		info.roll = (info.roll * 4) * scale;
	elseif ( greenCode.Client:IsJogging() ) then
		info.speed = (info.speed * 8) * scale;
		info.roll = (info.roll * 3) * scale;
	elseif (greenCode.Client:GetVelocity():Length() > 0) then
		info.speed = (info.speed * 6) * scale;
		info.roll = (info.roll * 2) * scale;
	else
		info.roll = info.roll * scale;
	end;
end;

-- Called when the view should be calculated.
function PLUGIN:CalcView( player, origin, angles, fov )
	if (gc.kernel:IsDefaultWeapon(gc.Client:GetActiveWeapon()) or gc.Client:InVehicle()) then
		return;
	end;

	local frameTime = FrameTime();//math.min(FrameTime(), 0.06);
	
	if ( !gc.player:IsNoClipping( player ) ) then
		local approachTime = frameTime * 2;
		local curTime = UnPredictedCurTime();
		local info = {speed = 1, yaw = 0.5, roll = 0.1};
		
		if ( !gc.HeadbobAngle ) then
			gc.HeadbobAngle = 0;
		end;
		
		if ( !gc.HeadbobInfo ) then
			gc.HeadbobInfo = info;
		end;
		
		gc.HeadbobInfo.yaw = math.Approach(gc.HeadbobInfo.yaw, info.yaw, approachTime);
		gc.HeadbobInfo.roll = math.Approach(gc.HeadbobInfo.roll, info.roll, approachTime);
		gc.HeadbobInfo.speed = math.Approach(gc.HeadbobInfo.speed, info.speed, approachTime);
		gc.HeadbobAngle = gc.HeadbobAngle + (gc.HeadbobInfo.speed * frameTime);
		
		local yawAngle = math.sin(gc.HeadbobAngle);
		local rollAngle = math.cos(gc.HeadbobAngle);
		
		angles.y = angles.y + (yawAngle * gc.HeadbobInfo.yaw);
		angles.r = angles.r + (rollAngle * gc.HeadbobInfo.roll);

		local velocity = player:GetVelocity();
		local eyeAngles = player:EyeAngles();
		
		if (!gc.VelSmooth) then gc.VelSmooth = 0; end;
		if (!gc.WalkTimer) then gc.WalkTimer = 0; end;
		if (!gc.LastStrafeRoll) then gc.LastStrafeRoll = 0; end;
		
		gc.VelSmooth = math.Clamp(gc.VelSmooth * 0.9 + velocity:Length() * 0.1, 0, 700)
		gc.WalkTimer = gc.WalkTimer + gc.VelSmooth * frameTime * 0.05
		
		gc.LastStrafeRoll = (gc.LastStrafeRoll * 3) + (eyeAngles:Right():DotProduct(velocity) * 0.0001 * gc.VelSmooth * 0.3);
		gc.LastStrafeRoll = gc.LastStrafeRoll * 0.25;
		angles.r = angles.r + gc.LastStrafeRoll;
		
		if (player:GetGroundEntity() != NULL) then
			angles.p = angles.p + math.cos(gc.WalkTimer * 0.5) * gc.VelSmooth * 0.000002 * gc.VelSmooth;
			angles.r = angles.r + math.sin(gc.WalkTimer) * gc.VelSmooth * 0.000002 * gc.VelSmooth;
			angles.y = angles.y + math.cos(gc.WalkTimer) * gc.VelSmooth * 0.000002 * gc.VelSmooth;
		end;
		
		velocity = gc.Client:GetVelocity().z;
		
		if (velocity <= -1000 and gc.Client:GetMoveType() == MOVETYPE_WALK) then
			angles.p = angles.p + math.sin(UnPredictedCurTime()) * math.abs((velocity + 1000) - 16);
		end;
	end;
	
	local view = {};
	//local weapon = gc.Client:GetActiveWeapon();
	local changedAngles = (view.vm_angles != nil);
	local changedOrigin = (view.vm_origin != nil);
	
	if (!changedAngles) then
		-- Thanks to BlackOps7799 for this open source example.
		
		if (!gc.SmoothViewAngle) then
			gc.SmoothViewAngle = angles;
		else
			gc.SmoothViewAngle = LerpAngle(RealFrameTime() * 16, gc.SmoothViewAngle, angles);
		end;
		
		view.angles = gc.SmoothViewAngle;
		view.vm_origin = origin;
		view.vm_angles = angles;
	end;
	
	gc.plugin:Call("CalcViewAdjustTable", view);
	
	return view;
end;