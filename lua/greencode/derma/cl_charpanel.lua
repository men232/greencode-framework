local PANEL = { };

AccessorFunc( PANEL, "m_fAnimSpeed", 	"AnimSpeed" )
AccessorFunc( PANEL, "Entity", 			"Entity" )
AccessorFunc( PANEL, "vCamPos", 		"CamPos" )
AccessorFunc( PANEL, "fFOV", 			"FOV" )
AccessorFunc( PANEL, "vLookatPos", 		"LookAt" )
AccessorFunc( PANEL, "colAmbientLight", "AmbientLight" )
AccessorFunc( PANEL, "colColor", 		"Color" )
AccessorFunc( PANEL, "bAnimated", 		"Animated" )

function PANEL:Init()
	
	self.LastPaint = 0;
	
	self:SetText( "" );
	self:SetAnimSpeed( 0.5 );
	self:SetAnimated( true );
	
	self:SetAmbientLight( Color( 50, 50, 50 ) );
	
	self:SetDirectionalLight( BOX_TOP, Color( 255, 255, 255 ) );
	self:SetDirectionalLight( BOX_FRONT, Color( 255, 255, 255 ) );
	
	self:SetColor( Color( 255, 255, 255, 255 ) );
	
	self.Entity = ClientsideModel( "models/humans/group01/male_01.mdl", RENDER_GROUP_OPAQUE_ENTITY );
	self.Entity:SetNoDraw( true );
	
	self:SetCamPos( Vector( 50, 50, 50 ) );
	self:SetLookAt( Vector( 0, 0, 55 ) );
	self:SetFOV( 30 );
	
	self.HasModel = false;
	
end

function PANEL:SetModel( strModelName )
	
	self.Entity:SetModel( strModelName );
	self.Entity:SetNoDraw( true );
	
	if( string.len( strModelName ) == 0 ) then
		
		self.HasModel = false;
		
	else
		
		self.HasModel = true;
		
	end
	
end

function PANEL:GetModel()
	
	return self.Entity:GetModel();
	
end

function PANEL:SetSkin( i )
	
	self.Entity:SetSkin( i );
	
end

function PANEL:OnMouseWheeled( dlta )
	
	if( string.len( self:GetModel() ) > 0 ) then
		
		self:SetFOV( math.Clamp( self:GetFOV() + dlta * -2, 20, 120 ) );
		
	end
	
end

function PANEL:Paint()
	
	if( !IsValid( self.Entity ) ) then return end
	if( !self.HasModel ) then return end
	
	local x, y = self:LocalToScreen( 0, 0 )
	
	self:LayoutEntity( self.Entity )
	
	cam.Start3D( self.vCamPos, (self.vLookatPos-self.vCamPos):Angle(), self.fFOV, x, y, self:GetSize() )
		cam.IgnoreZ( true )
		
		render.SuppressEngineLighting( true )
		render.SetLightingOrigin( self.Entity:GetPos() )
		render.ResetModelLighting( self.colAmbientLight.r/255, self.colAmbientLight.g/255, self.colAmbientLight.b/255 )
		render.SetColorModulation( self.colColor.r/255, self.colColor.g/255, self.colColor.b/255 )
		render.SetBlend( self.colColor.a / 255 )
		
		for i=0, 6 do
			local col = self.DirectionalLight[ i ]
			if ( col ) then
				render.SetModelLighting( i, col.r/255, col.g/255, col.b/255 )
			end
		end
		
		self.Entity:DrawModel()
		
		render.SuppressEngineLighting( false )
		cam.IgnoreZ( false )
	cam.End3D()
	
	self.LastPaint = RealTime()
	
end

PANEL.Anims = { };
PANEL.Anims["idle"] = { "idle_subtle", "idle_all" };
PANEL.Anims["walk"] = { "walk_all", "WalkUnarmed_all", "walk_all_moderate" };

function PANEL:StartAnimation( set )
	
	if( !self.Anims[set] ) then return end
	
	local seq = -1;
	
	for _, v in pairs( self.Anims[set] ) do
		
		if( seq <= 0 ) then
			
			seq = self.Entity:LookupSequence( v );
			
		end
		
		if( seq > 0 ) then
			
			self.bAnimated = true;
			self.Entity:ResetSequence( seq );
			break;
			
		end
		
	end
	
end

function PANEL:RunAnimation()
	self.Entity:FrameAdvance( ( RealTime() - self.LastPaint ) * self.m_fAnimSpeed );
end

function PANEL:StartScene( name )
	
	if ( IsValid( self.Scene ) ) then
		self.Scene:Remove()
	end
	
	self.Scene = ClientsideScene( name, self.Entity )
	
end

function PANEL:OnMousePressed( code )
	
	if( self.HasModel ) then
		
		self:MouseCapture( true );
		self.MouseDetect = true;
		
		local centerx, centery = self:LocalToScreen( self:GetWide() * 0.5, self:GetTall() * 0.5 )
		input.SetCursorPos( centerx, centery );
		
		self.MX = centerx;
		self.MY = centery;
		
	end
	
end

function PANEL:OnMouseReleased( code )
	
	if( self.HasModel ) then
		
		self:MouseCapture( false );
		self.MouseDetect = false;
		
	end
	
end

function PANEL:LayoutEntity( Entity )
	
	if( self.bAnimated ) then
		self:RunAnimation();
	end
	
	if( self.MouseDetect ) then
		
		local xpos = gui.MouseX();
		local ypos = gui.MouseY();
		
		local dx = xpos - self.MX;
		local dy = ypos - self.MY;
		
		input.SetCursorPos( self.MX, self.MY );
		
		Entity:SetAngles( Entity:GetAngles() + Angle( 0, dx, 0 ) );
		
	else
		
		//local ang = Entity:GetAngles();
		//ang = ang * 0.9;
		//Entity:SetAngles( ang );
		
	end
	
end

vgui.Register( "gcCharPanel", PANEL, "DModelPanel" );