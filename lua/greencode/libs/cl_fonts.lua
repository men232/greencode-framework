--[[
	© 2013 GmodLive private project do not share
	without permission of its author (Andrew Mensky vk.com/men232).
--]]

local gc = gc;
local surface = surface;

surface.CreateFont("gcMainText", 
{
	font		= "Arial",
	size		= gc.kernel:FontScreenScale(7),
	weight		= 700,
	antialiase	= true,
	additive 	= false
});
surface.CreateFont("gcMenuTextBig",
{
	font		= "Arial",
	size		= gc.kernel:FontScreenScale(18),
	weight		= 700,
	antialiase	= true,
	additive 	= false
});
surface.CreateFont("gcMenuTextTiny",
{
	font		= "Arial",
	size		= gc.kernel:FontScreenScale(7),
	weight		= 700,
	antialiase	= true,
	additive 	= false
});
surface.CreateFont("gcMenuTextHuge",
{
	font		= "Arial",
	size		= gc.kernel:FontScreenScale(30),
	weight		= 700,
	antialiase	= true,
	additive 	= false
});
surface.CreateFont("gcMenuTextSmall",
{
	font		= "Arial",
	size		= gc.kernel:FontScreenScale(10),
	weight		= 700,
	antialiase	= true,
	additive 	= false
});
surface.CreateFont("gcIntroTextBig",
{
	font		= "Arial",
	size		= gc.kernel:FontScreenScale(18),
	weight		= 700,
	antialiase	= true,
	additive 	= false
});
surface.CreateFont("gcIntroTextTiny",
{
	font		= "Arial",
	size		= gc.kernel:FontScreenScale(9),
	weight		= 700,
	antialiase	= true,
	additive 	= false
});
surface.CreateFont("gcIntroTextSmall",
{
	font		= "Arial",
	size		= gc.kernel:FontScreenScale(7),
	weight		= 700,
	antialiase	= true,
	additive 	= false
});
surface.CreateFont("gcLarge3D2D",
{
	font		= "Arial",
	size		= gc.kernel:GetFontSize3D(),
	weight		= 700,
	antialiase	= true,
	additive 	= false
});
surface.CreateFont("gcCinematicText",
{
	font		= "Trebuchet",
	size		= gc.kernel:FontScreenScale(8),
	weight		= 700,
	antialiase	= true,
	additive 	= false
});
surface.CreateFont("gcChatSyntax",
{
	font		= "Courier New",
	size		= gc.kernel:FontScreenScale(7),
	weight		= 600,
	antialiase	= true,
	additive 	= false
});