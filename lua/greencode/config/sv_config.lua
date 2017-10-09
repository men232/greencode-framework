greenCode.config:Add( "session_timeout", 10*60, false, false, false );
greenCode.config:Add( "session_noname", "Unknown", false, false, false );

greenCode.config:Add( "character_save_interval", 5, false, false, false );

greenCode.config:Add( "crouched_speed", 0.2, false, false, false );
greenCode.config:Add( "jump_power", 160, false, false, false );
greenCode.config:Add( "walk_speed", 140, false, false, false );
greenCode.config:Add( "run_speed", 225, false, false, false );
greenCode.config:Add( "min_speed", 15, false, false, false );

greenCode.config:Add( "duck_speed", 0.3, false, false, false );
greenCode.config:Add( "unduck_speed", 0.3, false, false, false );

greenCode.config:Add("scale_attribute_progress", 1);
greenCode.config:Add("prop_kill_protection", true);

greenCode.config:Add("damage_view_punch", true);
greenCode.config:Add("armor_chest_only", true);
greenCode.config:Add("scale_head_dmg", 5);
greenCode.config:Add("scale_chest_dmg", 2);
greenCode.config:Add("scale_limb_dmg", 1.5);
greenCode.config:Add("scale_fall_damage", 1);
greenCode.config:Add("wood_breaks_fall", true);

greenCode.config:Add("limb_damage_system", true, true);
greenCode.config:Add("scale_limb_dmg", 0.5);

greenCode.config:Add( "nlr_time", 5*60, false, false );

greenCode.config:Get("walk_speed"):Set(140);