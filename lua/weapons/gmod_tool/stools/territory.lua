TOOL.Category		= "Green Code"
TOOL.Name			= "Territory"
TOOL.Command		= nil
TOOL.ConfigName		= ""

if CLIENT then
	language.Add( "Tool.territory.name", "Territory marking" );
	language.Add( "Tool.territory.desc", "Left click to add mark on cross / Right click to add mark on self position." );
	language.Add( "Tool.territory.0", "Z remove last spawned mark | Using only for SuperAdmin." );
end;

local CreateTerritoryName  = CreateClientConVar("ter_create_name", "", true, false );
local EditTerritoryUid = CreateClientConVar("ter_edit_uid", "", true, false );

function TOOL:LeftClick( tr )
	local ply = self:GetOwner();
	
	if SERVER and ply:IsSuperAdmin() then 
		return true;
	end;
	
	if ( !ply.gcTerInterval ) then ply.gcTerInterval = 0; end;
	
	if ( ply.gcTerInterval < CurTime() ) then
		local pos = tr.HitPos;

		RunConsoleCommand("gc", "territory", "addcord", EditTerritoryUid:GetString(), pos[1]..","..pos[2]..","..pos[3]);
		ply.gcTerInterval = CurTime() + 1;
		return ply:IsSuperAdmin();
	end;
end;

function TOOL:RightClick( tr )
	local ply = self:GetOwner();
	
	if SERVER and ply:IsSuperAdmin() then 
		return true;
	end;
	
	if ( !ply.gcTerInterval ) then ply.gcTerInterval = 0; end;
	
	if ( ply.gcTerInterval < CurTime() ) then
		RunConsoleCommand("gc", "territory", "addcord", EditTerritoryUid:GetString(), "0");
		ply.gcTerInterval = CurTime() + 1;
		return ply:IsSuperAdmin();
	end;
end;

if CLIENT then
	function RebuildTerritoryPanel()
		local panel = controlpanel.Get( "territory" );
		if not panel then return end;
		
		--clear the panel so we can make it again!
		for i,v in pairs( panel.Items ) do
			if v.Left then v.Left:GetParent():Remove() end;
			panel.Items[i]:Remove();
			panel.Items[i] = nil;
		end;
		
		panel:AddControl("Header", { Text = "#Tool.territory.name", Description = "--== Create territory ==--" });
		panel:AddControl("TextBox", { Label = "Name", Command = "ter_create_name", MaxLength = "20"} );
		panel:AddControl("Button", { Label   = "Create territory", Text = "Create", Command = "ter_create", });
		
		panel:AddControl("Header", { Text = "#Tool.territory.name", Description = "--== Edit territory ==--" });
		
		local NameList = {};
		local TER_PLUGIN = greenCode.plugin:FindByID("territory");
		
		for _, TERRITORY in pairs( TER_PLUGIN.stored ) do	
			NameList[ TERRITORY:Name() .. " | ".. TERRITORY:UniqueID() ] = { ter_edit_uid = tostring(math.Round(TERRITORY:UniqueID())) };
		end;
		
		panel:AddControl("ComboBox", {Label		= "Territory", MenuButton = "0", Command = "ter_edit_uid", Options = NameList } );
		panel:AddControl( "Button", { Label   = "Remove territory", Text = "Remove", Command = "ter_remove", });
	end;
	
	function TOOL.BuildCPanel(panel)
		RebuildTerritoryPanel();
	end;
	
	hook.Add( "OnTerritoryDataReceive", "RebuildTerritoryToolMenu", function()
		RebuildTerritoryPanel();
	end);
	
	concommand.Add("ter_remove", function( ply, cmd, args )
		RunConsoleCommand("gc", "territory", "remove", EditTerritoryUid:GetString())
	end);
	
	concommand.Add("ter_create", function( ply, cmd, args )
		RunConsoleCommand("gc", "territory", "add", CreateTerritoryName:GetString())
	end);
end;