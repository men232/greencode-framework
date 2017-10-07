local rp_customshop = greenCode.plugin:FindByID("rp_customshop");
if (!rp_customshop) then return end;

local cWeaponColor = gc.config:Get("inv_color_wp"):Get(Color(100,25,0));
local cFoodColor   = gc.config:Get("inv_color_fd"):Get(Color(0,75,0));
local cAmmoColor   = gc.config:Get("inv_color_am"):Get(Color(100,60,0));

-- RP Custom Shop Import
for uid, v in pairs(rp_customshop.buffer or {}) do
	if (!v.data) then continue end;
	if (!v.data.license and v.data.licIgnore) then continue end;

	local ITEM, d = INV_ITEM_CLASS:New{
		uid = uid,
		name = v.data.name,
		class = v.data.class,
		model = v.data.model,
		description = v.data.description,
		stackable = v.data.stackable or false,
		weight = v.data.weight or 5,
		data = v.data.data,
		allow_drop = v.data.allow_drop,
		color = v.data.color,
	};

	-- Finder
	if (v.data.class == "spawned_weapon") then		
		if (v.data.stackable == nil) then
			ITEM:SetData("stackable", true);
		end;

		ITEM:SetData("weight", v.data.weight or 3);
		ITEM:SetData("color", cWeaponColor);

		function ITEM:Compliance( entity )
			return self("data", {}).weaponclass == entity.weaponclass;
		end;
	elseif (v.data.class == "spawned_food") then
		if (v.data.stackable == nil) then
			ITEM:SetData("stackable", true);
		end;

		ITEM:SetData("color", cFoodColor);
		ITEM:SetData("weight", v.data.weight or 1);

		function ITEM:Compliance( entity )
			return self("model") == entity:GetModel();
		end;
	elseif (string.find(v.data.class, "ammo")) then
		ITEM:SetData("color", cAmmoColor);
		ITEM:SetData("weight", v.data.weight or 2);
	end;

	function ITEM:OnDrop( owner )
		if (!owner:IsPlayer()) then	return;	end;
		local nMax, sClass = v:GetMax(), v:GetClass();

		if ( nMax > 0 ) then
			if (!owner["max"..sClass]) then owner["max"..sClass] = 0; end;
			
			if (owner["max"..sClass] >= nMax) then
				return false, "Вы достигли лимита.";
			end;
		end;
	end;

	ITEM:Register();
end;