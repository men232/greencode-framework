--[[
	© 2013 gmodlive.com commissioned by Leonid Sahnov
	private source
--]]

-- Базовые конфиги
greenCode.config:Add( "inv_min_weight", 15, false, false, false );		-- Минимальный переносимый вес.
greenCode.config:Add( "inv_max_weight", 120, false, false, false );		-- Максимальный переносимый вес
greenCode.config:Add( "inv_research_dist", 150, false, false, false );	-- Максимальная дистанция обыска.
greenCode.config:Add( "inv_steal_dist", 1200, false, false, false );	-- На сколько далеко должен быть владелец, что-бы украсть его вещ.
greenCode.config:Add( "inv_sync_dist", 300, false, false, false );		-- Дистанция синхронизации инвентарев.
greenCode.config:Add( "inv_pickup_interval", 0.6, false, false, false );-- Интервал между подъемом вещей.
greenCode.config:Add( "inv_death_drop", true, false, false, false );	-- Выпадание инвентаря при смерти.
greenCode.config:Add( "inv_allow_fulldrop", true, false, false, false );-- Разрешить полный сброс инвентаря.
greenCode.config:Add( "inv_fire_dmg", true, false, false, false );		-- Наносить урон, при попытки взять горящий предмет.
greenCode.config:Add( "inv_one_research", false, false, false, false ); -- Только 1 игрок может иследовать инвентарь.

-- Конфиги цвета импорта
greenCode.config:Add( "inv_color_wp", Color(100,25,0), false, false, false );	-- Цвет ячейки оружия.
greenCode.config:Add( "inv_color_fd", Color(0,75,0), false, false, false );		-- Цвет ячейки еды.
greenCode.config:Add( "inv_color_am", Color(100,60,0), false, false, false );	-- Цвет ячейки патронов.

-- Множитель групп
-- На фактор будет умножаться общий перегруз.
-- EXAMPLE: inv_factor_[group name]
greenCode.config:Add( "inv_factor_superadmin", 0.5, false, false, false );	-- Множетель перегруза для SuperAdmin.
greenCode.config:Add( "inv_factor_vp", 0.75, false, false, false );			-- Множетель перегруза для VIP.