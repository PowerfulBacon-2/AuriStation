/**********************
Metals Sheets
	Contains:
		- Iron
		- Plasteel
		- Runed Metal (cult)
		- Brass (clockwork cult)
		- Bronze (bake brass)
		- Copper
		- Titanium
		- Plastitanium
		- Coal
**********************/

/* Iron */

/obj/item/stack/sheet/iron
	name = "iron"
	desc = "Sheets made out of iron."
	singular_name = "iron sheet"
	icon_state = "sheet-metal"
	inhand_icon_state = "sheet-metal"
	mats_per_unit = list(/datum/material/iron=MINERAL_MATERIAL_AMOUNT)
	throwforce = 10
	flags_1 = CONDUCT_1
	resistance_flags = FIRE_PROOF
	merge_type = /obj/item/stack/sheet/iron
	grind_results = list(/datum/reagent/iron = 20)
	point_value = 2
	tableVariant = /obj/structure/table
	material_type = /datum/material/iron
	matter_amount = 4
	cost = 500
	source = /datum/robot_energy_storage/metal

/obj/item/stack/sheet/iron/examine(mob/user)
	. = ..()
	. += "<span class='notice'>You can build a wall girder (unanchored) by right clicking on an empty floor.</span>"

/obj/item/stack/sheet/iron/narsie_act()
	new /obj/item/stack/sheet/runed_metal(loc, amount)
	qdel(src)

/obj/item/stack/sheet/iron/get_recipes()
	return GLOB.metal_recipes

/obj/item/stack/sheet/iron/suicide_act(mob/living/carbon/user)
	user.visible_message(span_suicide("[user] begins whacking [user.p_them()]self over the head with \the [src]! It looks like [user.p_theyre()] trying to commit suicide!"))
	return BRUTELOSS

/obj/item/stack/sheet/iron/afterattack_secondary(atom/target, mob/user, proximity_flag, click_parameters)
	if(istype(target, /turf/open))
		var/turf/open/build_on = target
		if(!user.Adjacent(build_on))
			return SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN
		if(isgroundlessturf(build_on))
			user.balloon_alert(user, "can't place it here!")
			return SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN
		if(build_on.is_blocked_turf())
			user.balloon_alert(user, "something is blocking the tile!")
			return SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN
		if(get_amount() < 2)
			user.balloon_alert(user, "not enough material!")
			return SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN
		if(!do_after(user, 4 SECONDS, build_on))
			return SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN
		if(build_on.is_blocked_turf())
			user.balloon_alert(user, "something is blocking the tile!")
			return SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN
		if(!use(2))
			user.balloon_alert(user, "not enough material!")
			return SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN
		new/obj/structure/girder/displaced(build_on)
		return SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN
	return SECONDARY_ATTACK_CONTINUE_CHAIN

/* Plasteel */

/obj/item/stack/sheet/plasteel
	name = "plasteel"
	singular_name = "plasteel sheet"
	desc = "This sheet is an alloy of iron and plasma."
	icon_state = "sheet-plasteel"
	inhand_icon_state = "sheet-metal"
	mats_per_unit = list(/datum/material/alloy/plasteel=MINERAL_MATERIAL_AMOUNT)
	material_type = /datum/material/alloy/plasteel
	throwforce = 10
	flags_1 = CONDUCT_1
	armor_type = /datum/armor/military_metal
	resistance_flags = FIRE_PROOF
	merge_type = /obj/item/stack/sheet/plasteel
	grind_results = list(/datum/reagent/iron = 20, /datum/reagent/toxin/plasma = 20)
	point_value = 23
	tableVariant = /obj/structure/table/reinforced
	matter_amount = 12
	material_flags = NONE

/obj/item/stack/sheet/plasteel/get_recipes()
	return GLOB.plasteel_recipes

/* Bronze - the non cult one */

/obj/item/stack/sheet/bronze
	name = "bronze"
	desc = "On closer inspection, what appears to be wholly-unsuitable-for-building brass is actually more structurally stable bronze."
	singular_name = "bronze sheet"
	icon_state = "sheet-brass"
	inhand_icon_state = "sheet-brass"
	resistance_flags = FIRE_PROOF | ACID_PROOF
	throwforce = 10
	max_amount = 50
	throw_speed = 1
	throw_range = 3
	novariants = FALSE
	grind_results = list(/datum/reagent/iron = 5, /datum/reagent/copper = 3) //we have no "tin" reagent so this is the closest thing
	merge_type = /obj/item/stack/sheet/bronze
	tableVariant = /obj/structure/table/bronze
	walltype = /turf/closed/wall/mineral/bronze
	has_unique_girder = TRUE

/obj/item/stack/sheet/bronze/get_recipes()
	return GLOB.bronze_recipes

CREATION_TEST_IGNORE_SUBTYPES(/obj/item/stack/sheet/bronze)

/obj/item/stack/sheet/bronze/Initialize(mapload, new_amount, merge = TRUE)
	. = ..()
	pixel_x = 0
	pixel_y = 0

/* Fleshy iron */

/obj/item/stack/sheet/fleshymass
	name = "fleshy mass"
	singular_name = "fleshy mass"
	desc = "You swear it looks at you..."
	icon_state = "sheet-fleshymass"
	inhand_icon_state = "sheet-fleshymass"
	merge_type = /obj/item/stack/sheet/fleshymass

/obj/item/stack/sheet/fleshymass/get_recipes()
	return GLOB.fleshymass_recipes
