--[[
	© 2013 GmodLive private project do not share
	without permission of its author (Andrew Mensky vk.com/men232).
--]]

greenCode.math = {};

-- A function return true if point in polygon.
function gCode.math:IsInPolygon( vPoint, tCords, nVertex )
	if ( !tCords or #tCords < 3 ) then return end;

	local inside  = false;
	local j       = #tCords;
	nVertex = nVertex + tCords[j][3];
	
	if ( vPoint[3] > nVertex or vPoint[3] < tCords[j][3] ) then return false end;

	for i, cord in pairs( tCords ) do
		if ((cord[2]< vPoint[2] and tCords[j][2]>=vPoint[2] or tCords[j][2]< vPoint[2] and cord[2]>=vPoint[2]) and (cord[1]<=vPoint[1] or tCords[j][1]<=vPoint[1])) then
			if (cord[1]+(vPoint[2]-cord[2])/(tCords[j][2]-cord[2])*(tCords[j][1]-cord[1])<vPoint[1]) then
				inside=!inside; 
			end;
		end;
		
		j = i;
	end;

	return inside;
end;

-- A function fake polygon center.
function gCode.math:GetPolygonCenter( tCords )
	local center = Vector(0,0,0);
	local count = #tCords;
	
	if (count > 1) then
		for i, cord in pairs(tCords) do
			center = center + cord;
		end;
		
		return center / count;
	else
		return tCords[ count ];
	end;
end;