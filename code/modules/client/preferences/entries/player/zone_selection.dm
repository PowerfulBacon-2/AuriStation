/// The preference for zone selection
/datum/preference/choiced/zone_select
	db_key = "zone_select"
	preference_type = PREFERENCE_PLAYER
	category = PREFERENCE_CATEGORY_GAME_PREFERENCES

/datum/preference/choiced/zone_select/init_possible_values()
	return list(
		PREFERENCE_BODYZONE_SIMPLIFIED,
		PREFERENCE_BODYZONE_INTENT,
	)

/datum/preference/choiced/zone_select/create_default_value()
	return PREFERENCE_BODYZONE_SIMPLIFIED

/datum/preference/choiced/zone_select/apply_to_client(client/client, value)
	var/atom/movable/screen/zone_sel/selector = client.mob?.hud_used?.zone_select
	if (!selector)
		return
	// Reset zone selected to a sane value
	if (value == PREFERENCE_BODYZONE_SIMPLIFIED)
		selector.set_selected_zone(BODY_GROUP_CHEST_HEAD, client.mob)
	else
		selector.set_selected_zone(BODY_ZONE_CHEST, client.mob)
