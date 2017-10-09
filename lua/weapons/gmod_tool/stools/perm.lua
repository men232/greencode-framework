TOOL.Category		= "Green Code"
TOOL.Name			= "Perm Object"
TOOL.Command		= nil
TOOL.ConfigName		= ""

if CLIENT then
	language.Add( "Tool.perm.name", "Perm Object" )
	language.Add( "Tool.perm.desc", "Left click Add / Right click Remvoe." )
	language.Add( "Tool.perm.0", "Click R to show or hide perm object." )
end;

local enable = CreateClientConVar("perm_show", 0, true, false );

function TOOL:LeftClick( tr )
	if CLIENT then return true; end;
	
	local owner = self:GetOwner();
	
	if (!owner:IsSuperAdmin()) then
		owner:ColChat("Perm Object", Color(255,0,0), "Super Admin only!");
		return false;
	end;
	
	if (IsValid(tr.Entity)) then
		local PERM_PLUGIN = greenCode.plugin:Get("permobject");
		local done, msg = PERM_PLUGIN:Add( tr.Entity );
		
		owner:ColChat("Perm Object", done and Color(0,255,0) or Color(255,0,0), msg);
	end;
end;

function TOOL:RightClick(tr)
	if CLIENT then return true; end;
	
	local owner = self:GetOwner();
	
	if (!owner:IsSuperAdmin()) then
		owner:ColChat("Perm Object", Color(255,0,0), "Super Admin only!");
		return false;
	end;
	
	if (IsValid(tr.Entity)) then
		local PERM_PLUGIN = greenCode.plugin:Get("permobject");
		local done, msg = PERM_PLUGIN:Remove(tr.Entity);
		
		owner:ColChat("Perm Object", done and Color(0,255,0) or Color(255,0,0), msg);
	end;
end;

function TOOL:Reload( tr )
	if SERVER then return end;
	
	if ( !self.lastChange ) then
		self.lastChange = 0;
	end;
	
	local curTime = CurTime();
	
	if ( self.lastChange < curTime ) then
		RunConsoleCommand("perm_show", !enable:GetBool() and 1 or 0);
		self.lastChange = curTime + 0.1;
	end;
end;

if CLIENT then	
	local ents = ents;
	local bShouldDisabled = false;
	
	hook.Add("PreDrawOpaqueRenderables", "DrawPermaColors",function()		
		if (enable:GetBool()) then
			for _, v in pairs(ents.GetAll()) do
				local bIsPerm = greenCode.entity:GetSharedVar(v, "PermObject", false);
				
				if ( bIsPerm ) then
					if ( !v.safeColor ) then
						local color = v:GetColor();
						v.safeColor = color != Color(255,0,0,255) and color or Color(255,255,255,255);
					end;
					v:SetColor( Color(255,0,0,255) );
					bShouldDisabled = true;
				end;
				
				if ( !bIsPerm and v.safeColor ) then
					v:SetColor( v.safeColor );
					v.safeColor = nil;
				end;
			end;
		elseif (!enable:GetBool() and bShouldDisabled) then
			for _, v in pairs(ents.GetAll()) do
				local bIsPerm = greenCode.entity:GetSharedVar(v, "PermObject", false);
				
				if (bIsPerm) then
					v:SetColor( v.safeColor );
					v.safeColor = nil;
				end;
			end;
			bShouldDisabled = false;
		end;
	end)
end;