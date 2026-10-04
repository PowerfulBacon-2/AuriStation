GLOBAL_LIST_INIT(cable_colors, list(
<<<<<<< HEAD
	"yellow" = "#ffff00",
	"green" = "#00aa00",
	"blue" = "#1919c8",
	"pink" = "#ff3cc8",
	"orange" = "#ff8000",
	"cyan" = "#00ffff",
	"white" = "#ffffff",
	"red" = "#ff0000"
	))


///////////////////////////////
//CABLE STRUCTURE
///////////////////////////////
=======
	"yellow" = COLOR_YELLOW,
	"green" = COLOR_DARK_LIME,
	"pink" = COLOR_LIGHT_PINK,
	"orange" = COLOR_MOSTLY_PURE_ORANGE,
	"red" = COLOR_RED,
	"white" = COLOR_WHITE,
))
>>>>>>> 367709c9418 ([MDB IGNORE] Smartwires, again (#14275))

/**
 * Helper proc to get a cable in a turf of a specific color
 * If cable_color is null, the first cable found is returned
 */
/proc/get_cable(turf/location, cable_color)
	for (var/obj/structure/cable/cable in location)
		if (isnull(cable_color) || cable.cable_color == cable_color)
			return cable

////////////////////////////////
// Definitions
////////////////////////////////

/obj/structure/cable
	name = "power cable"
	desc = "A flexible, superconducting insulated cable for heavy-duty power transfer."
	icon = 'icons/obj/power_cond/cables.dmi'
	icon_state = "0-1-2-4-8"
	layer = WIRE_LAYER //Above hidden pipes, GAS_PIPE_HIDDEN_LAYER
	anchored = TRUE
	flags_1 = STAT_UNIQUE_1

	/// The powernet we are linked to
	var/datum/powernet/powernet
	/// Are we a single cable that wants to be a node?
	var/has_power_node = FALSE
	/// Have we been manually given a power node and should keep it when we change?
	var/forced_power_node = FALSE
	/// List of cables that are connected to this cable.
	var/list/connected = list()
	/// A bitfield of the directions this cable connects to.
	var/linked_dirs = NONE
	/// A bitfield of the directions that have an omni-cable connection.
	var/omni_dirs = NONE
	/// Reference to the cable that is above us.
	var/obj/structure/cable/up
	/// Reference to the cable that is below us.
	var/obj/structure/cable/down
	/// Are we an omni cable?
	var/omni = FALSE
	/// Are we a multi-z cable?
	var/multiz = FALSE
	/// Sound loop for multi-z cables
	VAR_PRIVATE/datum/looping_sound/transformer/sound_loop

	FASTDMM_PROP(\
		pipe_type = PIPE_TYPE_CABLE,\
		pipe_interference_group = list("cable"),\
		pipe_group = "cable-[cable_color]"\
	)

	var/cable_color = "red"
	color = "#ff0000"

<<<<<<< HEAD
/obj/structure/cable/yellow
	cable_color = "yellow"
	color = "#ffff00"

/obj/structure/cable/green
	cable_color = "green"
	color = "#00aa00"

/obj/structure/cable/blue
	cable_color = "blue"
	color = "#1919c8"

/obj/structure/cable/pink
	cable_color = "pink"
	color = "#ff3cc8"

/obj/structure/cable/orange
	cable_color = "orange"
	color = "#ff8000"

/obj/structure/cable/cyan
	cable_color = "cyan"
	color = "#00ffff"

/obj/structure/cable/white
	cable_color = "white"
	color = "#ffffff"

=======
>>>>>>> 367709c9418 ([MDB IGNORE] Smartwires, again (#14275))
// the power cable object
CREATION_TEST_IGNORE_SUBTYPES(/obj/structure/cable)

/obj/structure/cable/Initialize(mapload, param_color = cable_color, multiz = FALSE)
	. = ..()

// If building for CI then we will check to ensure that cables are not incorrectly overlapping.
#ifdef CIBUILDING
	for (var/obj/structure/cable/cable in get_turf(src))
		if (cable == src || cable.cable_color != cable_color || omni || cable.omni)
			continue
		stack_trace("A cable was created when one already exists at [COORD(src)].")
		return INITIALIZE_HINT_QDEL
#endif

	cable_color = param_color
	src.multiz = multiz

	// If our tile is open space, we're a multiz cable
	if(mapload && isopenspace(loc))
		multiz = TRUE

	if(multiz)
		sound_loop = new(src, start_immediately = TRUE)

	// Our pixel offsets are modified for mapping icons, let's reset them here
	pixel_x = 0
	pixel_y = 0

	GLOB.cable_list += src //add it to the global cable list

	AddElement(/datum/element/undertile, TRAIT_T_RAY_VISIBLE)

	if(isturf(loc))
		var/turf/turf_loc = loc
		turf_loc.add_blueprints_preround(src)

	return INITIALIZE_HINT_LATELOAD

/obj/structure/cable/LateInitialize()
	reform_connections()
	update_appearance(UPDATE_ICON)

	// If we're being maploaded, SSmachines.makepowernets() will handle powernet creation
	var/should_we_make_a_powernet = SSatoms.initialized != INITIALIZATION_INNEW_MAPLOAD
	linkup_adjacent(should_we_make_a_powernet)

/obj/structure/cable/Destroy()
	// Update our neighbors
	clear_connections()
	if(powernet)
		cut_cable_from_powernet() // update the powernets
	GLOB.cable_list -= src //remove it from global cable list
	if (sound_loop)
		QDEL_NULL(sound_loop)
	return ..() // then go ahead and delete the cable

/obj/structure/cable/examine(mob/user)
	. = ..()
	if(isobserver(user))
		. += get_power_info()

/// Explicitly reject edits of managed variables
/obj/structure/cable/vv_edit_var(vname, vval)
	switch (vname)
		if (NAMEOF(src, connected))
			return FALSE
		if (NAMEOF(src, linked_dirs))
			return FALSE
		if (NAMEOF(src, omni_dirs))
			return FALSE
		if (NAMEOF(src, up))
			return FALSE
		if (NAMEOF(src, down))
			return FALSE
		if (NAMEOF(src, powernet))
			return FALSE
		if (NAMEOF(src, has_power_node))
			return FALSE
	. = ..()
	update_appearance(UPDATE_ICON)

/obj/structure/cable/proc/clear_connections()
	for (var/obj/structure/cable/connected_cable as anything in connected)
		connected_cable.connected -= src

		var/inbetween_dir = get_dir(connected_cable, src)

		// Don't clear the cable's linked dir if there's still a cable.
		// This only matters for omni-cables
		if(connected_cable.omni)
			var/has_other_cable = FALSE
			var/reverse_dir = REVERSE_DIR(inbetween_dir)
			for(var/obj/structure/cable/other_cable in connected_cable.connected)
				if(other_cable.linked_dirs & reverse_dir)
					has_other_cable = TRUE
					break
			if(!has_other_cable)
				connected_cable.linked_dirs &= ~(inbetween_dir)
		else
			connected_cable.linked_dirs &= ~(inbetween_dir)

		connected_cable.omni_dirs &= ~(inbetween_dir)

		connected_cable.update_power_node()
		connected_cable.update_appearance(UPDATE_ICON)
	down?.set_up(null)
	up?.set_down(null)

/**
 * Searches the four cardinal directions for cables and links the compatible ones to us.
 * If we are a multi-z wire, the turfs above and below us are searched as well.
 */
/obj/structure/cable/proc/reform_connections()
	for(var/cardinal in GLOB.cardinals)
		for(var/obj/structure/cable/adjacent_cable in get_step(src, cardinal))
			if (!adjacent_cable.omni && !omni && adjacent_cable.cable_color != cable_color)
				continue

			var/reverse_cardinal = REVERSE_DIR(cardinal)

			connected |= adjacent_cable
			linked_dirs |= cardinal

			adjacent_cable.connected |= src
			adjacent_cable.linked_dirs |= reverse_cardinal

			if(adjacent_cable.omni)
				omni_dirs |= cardinal
			if(omni)
				adjacent_cable.omni_dirs |= reverse_cardinal

			adjacent_cable.update_power_node()
			adjacent_cable.update_appearance(UPDATE_ICON)

	// Linkup with multi-z cables
	if (multiz)
		var/turf/current_location = get_turf(src)
		// Omni-cables will not connect with coloured cables along the z-axis
		var/obj/structure/cable/below_cable = get_cable(GET_TURF_BELOW(current_location), cable_color)
		below_cable?.set_up(src)

		var/obj/structure/cable/above_cable = get_cable(GET_TURF_ABOVE(current_location), cable_color)
		above_cable?.set_down(src)

/**
 * Updates the has_power_node bool and connects/disconnects from machines if it changed.
 */
/obj/structure/cable/proc/update_power_node()
	if (forced_power_node)
		return

	var/previous_node_state = has_power_node
	has_power_node = FALSE

	// If we have 0 or 1 connections, we get a free power node
	if((linked_dirs & NORTH) + (linked_dirs & SOUTH) + (linked_dirs & WEST) + (linked_dirs & EAST) <= 1)
		has_power_node = TRUE

	if (previous_node_state != has_power_node)
		if (has_power_node)
			connect_to_machines()
		else
			disconnect_from_machines()

/**
 * Adds a focred power node to this cable
 */
/obj/structure/cable/proc/add_power_node()
	forced_power_node = TRUE
	has_power_node = TRUE
	linkup_adjacent(FALSE)
	update_appearance(UPDATE_ICON)

/**
 * Sets the linked cable on the z-level below us
 */
/obj/structure/cable/proc/set_down(obj/structure/cable/new_cable)
	down = new_cable
	update_appearance(UPDATE_ICON)
	if(!isnull(down))
		down.up = src
		down.update_appearance(UPDATE_ICON)

/**
 * Sets the linked cable on the z-level above us
 */
/obj/structure/cable/proc/set_up(obj/structure/cable/new_cable)
	up = new_cable
	update_appearance(UPDATE_ICON)
	if(!isnull(up))
		up.down = src
		up.update_appearance(UPDATE_ICON)

/obj/structure/cable/deconstruct(disassembled = TRUE)
	if(flags_1 & NODECONSTRUCT_1)
		return ..()
	var/atom/drop_loc = drop_location()
	if(drop_loc)
		var/amount_to_drop = forced_power_node ? 2 : 1
		var/obj/item/stack/cable_coil/dropped_cable = new(drop_loc, amount_to_drop, TRUE, null, cable_color, omni)
		if(QDELETED(dropped_cable)) // the coil merged with something on the tile
			dropped_cable = locate(/obj/item/stack/cable_coil) in drop_loc
		transfer_fingerprints_to(dropped_cable)
	if (multiz)
		up?.deconstruct()
		down?.deconstruct()
	return ..()

///////////////////////////////////
// General procedures
///////////////////////////////////

/obj/structure/cable/update_overlays()
	. = ..()
	underlays.Cut()
	if (multiz)
		ADD_LUM_SOURCE(src, LUM_SOURCE_MANAGED_OVERLAY)
		. += mutable_appearance(icon, "box", appearance_flags = RESET_COLOR)
		. += mutable_appearance(icon, "boxlight", appearance_flags = RESET_COLOR)
		. += emissive_appearance(icon, "boxlight", layer)

	if(down)
		underlays += mutable_appearance(icon, "32", appearance_flags = RESET_COLOR)
	if(up)
		. += mutable_appearance(icon, "16", appearance_flags = RESET_COLOR)

	var/shift_amount = get_shift_amount()
	if (shift_amount != 0)
		// Add for the sake of hitboxes
		var/mutable_appearance/ma = mutable_appearance(icon, icon_state)
		ma.alpha = 1
		ma.pixel_x = -shift_amount
		ma.pixel_y = shift_amount
		. += ma

/obj/structure/cable/update_icon_state()
	. = ..()
	// Icon state
	var/list/adjacencies = list()
	if (has_power_node)
		adjacencies += "0"
	if (linked_dirs & NORTH)
		adjacencies += "1"
	if (linked_dirs & SOUTH)
		adjacencies += "2"
	if (linked_dirs & EAST)
		adjacencies += "4"
	if (linked_dirs & WEST)
		adjacencies += "8"
	if (length(adjacencies) <= 1 && !has_power_node)
		adjacencies.Insert(1, "0")
	if (omni)
		adjacencies += "o"
	icon_state = jointext(adjacencies, "-")

	// Color
	if (omni)
		remove_atom_colour(FIXED_COLOUR_PRIORITY)
		return
	add_atom_colour(GLOB.cable_colors[cable_color], FIXED_COLOUR_PRIORITY)

	// Calculate pixel shifts
	remove_filter(list("displace_wire", "omni-connection-up", "omni-connection-left", "omni-connection-down", "omni-connection-right"))
	var/shift_amount = get_shift_amount()
	// Shift amount not required if we are centered, reduces filter usage on main station wires
	if (shift_amount)
		layer = initial(layer)
		add_filter("displace_wire", 1, displacement_map_filter(icon('icons/obj/power_cond/cables.dmi', "displace-wire"), size=shift_amount))
		if (omni_dirs & NORTH)
			add_filter("omni-connection-up", 1, displacement_map_filter(icon('icons/obj/power_cond/cables.dmi', "displace-up"), size=shift_amount))
		if (omni_dirs & SOUTH)
			add_filter("omni-connection-down", 1, displacement_map_filter(icon('icons/obj/power_cond/cables.dmi', "displace-down"), size=shift_amount))
		if (omni_dirs & WEST)
			add_filter("omni-connection-left", 1, displacement_map_filter(icon('icons/obj/power_cond/cables.dmi', "displace-left"), size=shift_amount))
		if (omni_dirs & EAST)
			add_filter("omni-connection-right", 1, displacement_map_filter(icon('icons/obj/power_cond/cables.dmi', "displace-right"), size=shift_amount))
	else
		// Gets slightly priority over displaced cables so that shift-click functions as intended
		layer = initial(layer) + 0.001

/obj/structure/cable/proc/get_shift_amount()
	switch (cable_color)
		if ("green")
			return -4
		if ("orange")
			return -2
		if ("yellow")
			return 0
		if ("red")
			return 2
		if ("pink")
			return 4
	return 0

/obj/structure/cable/attackby(obj/item/attacking_item, mob/user, params)
	var/turf/our_turf = get_turf(src)
	if(our_turf.underfloor_accessibility < UNDERFLOOR_INTERACTABLE)
		return FALSE

	if(istype(attacking_item, /obj/item/stack/cable_coil))
		// Pass the click down to the turf instead
		return our_turf.attackby(attacking_item, user, params)

	add_fingerprint(user)
	return ..()

/obj/structure/cable/wirecutter_act(mob/living/user, obj/item/tool)
	var/turf/our_turf = get_turf(src)
	if (our_turf.underfloor_accessibility < UNDERFLOOR_INTERACTABLE)
		return

	var/obj/structure/cable/target = resolve_ambiguous_target(user)
	if(isnull(target))
		return TOOL_ACT_SIGNAL_BLOCKING

	if (target.shock(user, 50))
		return TOOL_ACT_SIGNAL_BLOCKING

	user.visible_message("[user] cuts [target].", span_notice("You cut [target]."))
	target.investigate_log("was cut by [key_name(usr)] in [AREACOORD(target)]", INVESTIGATE_WIRES)
	target.deconstruct()
	return TOOL_ACT_TOOLTYPE_SUCCESS

/obj/structure/cable/multitool_act(mob/living/user, obj/item/tool)
	var/turf/our_turf = get_turf(src)
	if (our_turf.underfloor_accessibility < UNDERFLOOR_INTERACTABLE)
		return

	var/obj/structure/cable/target = resolve_ambiguous_target(user)
	if(isnull(target))
		return TOOL_ACT_SIGNAL_BLOCKING

	target.add_fingerprint(user)
	to_chat(user, target.get_power_info())
	target.shock(user, 5, 0.2)
	return TOOL_ACT_TOOLTYPE_SUCCESS

/**
 * Called when we attempt to interact with this cable
 * If there are multiple cables in our location, display a radial menu for the user to choose a cable
 */
/obj/structure/cable/proc/resolve_ambiguous_target(mob/user)
	var/list/targets = list()
	for (var/obj/structure/cable/cable in loc)
		targets["Cable [cable.omni ? "(Omni)" : "([cable.cable_color])"]"] = cable
	if (length(targets) <= 1)
		return src
	var/result = show_radial_menu(user, user, targets, tooltips = TRUE)
	if (isnull(result))
		return
	return targets[result]

/// shock the user with probability prb
/obj/structure/cable/proc/shock(mob/user, prb, siemens_coeff = 1)
	if(!prob(prb))
		return FALSE
	if (electrocute_mob(user, powernet, src, siemens_coeff))
		do_sparks(5, TRUE, src)
		return TRUE
	return FALSE

/obj/structure/cable/singularity_pull(obj/anomaly/singularity/singularity, current_size)
	..()
	if(current_size >= STAGE_FIVE)
		deconstruct()

/obj/structure/cable/proc/get_power_info()
	if(powernet?.avail > 0)
		return span_danger("Total power: [display_power_persec(powernet.avail)]\nLoad: [display_power_persec(powernet.load)]\nExcess power: [display_power_persec(surplus())]")
	else
		return span_danger("The cable is not powered.")

////////////////////////////////////////////
// Power related
///////////////////////////////////////////

// All power generation handled in add_avail()
// Machines should use add_load(), surplus(), avail()
// Non-machines should use add_delayedload(), delayed_surplus(), newavail()

/obj/structure/cable/proc/add_avail(amount)
	powernet?.newavail += amount

/obj/structure/cable/proc/add_load(amount)
	powernet?.load += amount

/obj/structure/cable/proc/surplus()
	if(powernet)
		return clamp(powernet.avail-powernet.load, 0, powernet.avail)
	else
		return 0

/obj/structure/cable/proc/avail(amount)
	if(powernet)
		return amount ? powernet.avail >= amount : powernet.avail
	else
		return 0

/obj/structure/cable/proc/add_delayedload(amount)
	powernet?.delayedload += amount

/obj/structure/cable/proc/delayed_surplus()
	if(powernet)
		return clamp(powernet.newavail - powernet.delayedload, 0, powernet.newavail)
	else
		return 0

/obj/structure/cable/proc/newavail()
	if(powernet)
		return powernet.newavail
	else
		return 0

/////////////////////////////////////////////////
// Cable laying helpers
////////////////////////////////////////////////

/// Linkup with adjacent cables
/obj/structure/cable/proc/linkup_adjacent(link_powernets = FALSE)
	if (link_powernets)
		// Don't linkup if they have no powernet, for example in the case of
		// shuttle moving where we get a null powernet until we land
		for (var/obj/structure/cable/connected_cable in connected)
			if (connected_cable.powernet)
				if (powernet)
					merge_powernets(powernet, connected_cable.powernet)
				else
					connected_cable.powernet.add_cable(src)
		if (up?.powernet)
			if (powernet)
				merge_powernets(powernet, up.powernet)
			else
				up.powernet.add_cable(src)
		if (down?.powernet)
			if (powernet)
				merge_powernets(powernet, down.powernet)
			else
				down.powernet.add_cable(src)
		if (!powernet)
			var/datum/powernet/new_powernet = new()
			new_powernet.add_cable(src)
	if (has_power_node)
		connect_to_machines()

/**
 * Connects power machinery to our powernet.
 *
 * Called when has_power_node is set to TRUE.
 */
/obj/structure/cable/proc/connect_to_machines()
	for (var/obj/machinery/power/power_machine in get_turf(src))
		if(istype(power_machine, /obj/machinery/power/apc))
			var/obj/machinery/power/apc/apc = power_machine
			if (isnull(apc.terminal) || apc.terminal.powernet == powernet)
				continue
			if(!apc.terminal.connect_to_network())
				apc.terminal.disconnect_from_network()
			continue

		if (power_machine.powernet == powernet)
			continue
		if(!power_machine.connect_to_network())
			power_machine.disconnect_from_network()

/obj/structure/cable/proc/disconnect_from_machines()
	for(var/obj/machinery/power/power_machine in get_turf(src))
		if(!power_machine.connect_to_network()) //can't find a node cable on a the turf to connect to
			power_machine.disconnect_from_network() //remove from current network

//////////////////////////////////////////////
// Powernets handling helpers
//////////////////////////////////////////////

// cut the cable's powernet at this cable and updates the powergrid
/obj/structure/cable/proc/cut_cable_from_powernet(remove = TRUE)
	var/turf/location = get_turf(src)
	// remove the cut cable from its turf and powernet, so that it doesn't get count in propagate_network worklist
	if(remove)
		moveToNullspace()
	powernet.remove_cable(src) //remove the cut cable from its powernet

	if (!location)
		return

	// Disconnect machines connected to nodes
	if(has_power_node) // if we cut a node (O-X) cable
		disconnect_from_machines()

<<<<<<< HEAD

///////////////////////////////////////////////
// The cable coil object, used for laying cable
///////////////////////////////////////////////

////////////////////////////////
// Definitions
////////////////////////////////

GLOBAL_LIST_INIT(cable_coil_recipes, list (
	new/datum/stack_recipe("cable restraints", /obj/item/restraints/handcuffs/cable, 15, category = CAT_EQUIPMENT),
	new/datum/stack_recipe("noose", /obj/structure/chair/noose, 30, time = 80, crafting_flags = CRAFT_CHECK_DENSITY | CRAFT_ONE_PER_TURF | CRAFT_ON_SOLID_GROUND),
))

/obj/item/stack/cable_coil
	name = "cable coil"
	custom_price = 15
	gender = NEUTER //That's a cable coil sounds better than that's some cable coils
	icon = 'icons/obj/power.dmi'
	icon_state = "coil"
	inhand_icon_state = "coil"
	novariants = FALSE
	lefthand_file = 'icons/mob/inhands/equipment/tools_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/equipment/tools_righthand.dmi'
	max_amount = MAXCOIL
	amount = MAXCOIL
	merge_type = /obj/item/stack/cable_coil // This is here to let its children merge between themselves
	desc = "A coil of insulated power cable."
	throwforce = 0
	w_class = WEIGHT_CLASS_SMALL
	throw_speed = 3
	throw_range = 5
	mats_per_unit = list(/datum/material/iron=10, /datum/material/glass=5)
	flags_1 = CONDUCT_1
	slot_flags = ITEM_SLOT_BELT
	attack_verb_continuous = list("whips", "lashes", "disciplines", "flogs")
	attack_verb_simple = list("whip", "lash", "discipline", "flog")
	singular_name = "cable piece"
	full_w_class = WEIGHT_CLASS_SMALL
	grind_results = list(/datum/reagent/copper = 2) //2 copper per cable in the coil
	usesound = 'sound/items/deconstruct.ogg'
	cost = 1
	source = /datum/robot_energy_storage/wire
	var/cable_color = "red"

/obj/item/stack/cable_coil/attack_self(mob/user)
	if(!iscyborg(user))
		. = ..()
		return
	var/picked = input(user,"Pick a cable color.","Cable Color") in list("red","yellow","green","blue","pink","orange","cyan","white")
	cable_color = picked
	update_icon()

/obj/item/stack/cable_coil/suicide_act(mob/living/user)
	if(locate(/obj/structure/chair/stool) in get_turf(user))
		user.visible_message(span_suicide("[user] is making a noose with [src]! It looks like [user.p_theyre()] trying to commit suicide!"))
	else
		user.visible_message(span_suicide("[user] is strangling [user.p_them()]self with [src]! It looks like [user.p_theyre()] trying to commit suicide!"))
	return OXYLOSS

/obj/item/stack/cable_coil/get_recipes()
	return GLOB.cable_coil_recipes

CREATION_TEST_IGNORE_SUBTYPES(/obj/item/stack/cable_coil)

/obj/item/stack/cable_coil/Initialize(mapload, new_amount = null, param_color = null)
=======
/obj/structure/cable/beforeShuttleMove(turf/newT, rotation, move_mode, obj/docking_port/mobile/moving_dock)
>>>>>>> 367709c9418 ([MDB IGNORE] Smartwires, again (#14275))
	. = ..()
	cut_cable_from_powernet(FALSE)

/obj/structure/cable/afterShuttleMove(turf/oldT, list/movement_force, shuttle_dir, shuttle_preferred_direction, move_dir, rotation)
	. = ..()
	clear_connections()
	reform_connections()
	linkup_adjacent(TRUE)

<<<<<<< HEAD
//add cables to the stack
/obj/item/stack/cable_coil/proc/give(extra)
	if(amount + extra > max_amount)
		amount = max_amount
	else
		amount += extra
	update_icon()



///////////////////////////////////////////////
// Cable laying procedures
//////////////////////////////////////////////

/obj/item/stack/cable_coil/proc/get_new_cable(location)
	var/path = /obj/structure/cable
	return new path(location, cable_color)

// called when cable_coil is clicked on a turf
/obj/item/stack/cable_coil/proc/place_turf(turf/T, mob/user, dirnew)
	if(!isturf(user.loc))
		return

	if(!isturf(T) || T.underfloor_accessibility < UNDERFLOOR_INTERACTABLE || !T.can_have_cabling())
		to_chat(user, span_warning("You can only lay cables on top of exterior catwalks and plating!"))
		return

	if(get_amount() < 1) // Out of cable
		to_chat(user, span_warning("There is no cable left!"))
		return

	if(get_dist(T,user) > 1) // Too far
		to_chat(user, span_warning("You can't lay cable at a place that far away!"))
		return

	var/d2
	if(!dirnew) //If we weren't given a direction, come up with one! (Called as null from catwalk.dm and floor.dm)
		if(user.loc == T)
			d2 = user.dir //If laying on the tile we're on, lay in the direction we're facing
		else
			d2 = get_dir(T, user)
	else
		d2 = dirnew

	var/d1 = 0
	if(istype(T, /turf/open/openspace))
		if(!(get_amount() >= 2))
			to_chat(user, span_warning("You need at least 2 pieces of cable to wire between decks!"))
			return
		d1 = d2 //bigger number goes last for sprite reasons
		d2 = DOWN

	for(var/obj/structure/cable/LC in T)
		if(LC.d2 == d2 && LC.d1 == d1)
			to_chat(user, span_warning("There's already a cable at that position!"))
			return

	var/obj/structure/cable/C = place_cable(T, user, d1, d2)
	if(C.shock(user, 50))
		if(prob(50)) //fail
			new /obj/item/stack/cable_coil(get_turf(C), 1, C.color)
			C.deconstruct()
	else if(d2 == DOWN)
		place_cable(GET_TURF_BELOW(T), user, 0, UP)
		to_chat(user, span_notice("You slide the cable downward."))

	return C

/obj/item/stack/cable_coil/proc/place_cable(turf/open/T, mob/user, d1, d2)
	if(!istype(T))
		return
	var/obj/structure/cable/C = get_new_cable(T)

	//set up the new cable
	C.d1 = d1
	C.d2 = d2
	C.add_fingerprint(user)
	C.update_icon()

	//create a new powernet with the cable, if needed it will be merged later
	var/datum/powernet/PN = new()
	PN.add_cable(C)

	C.mergeConnectedNetworks(C.d1)
	C.mergeConnectedNetworks(C.d2) //merge the powernet with adjacents powernets
	C.mergeConnectedNetworksOnTurf() //merge the powernet with on turf powernets

	if(C.d1 & (C.d1 - 1))// if the cable is layed diagonally, check the others 2 possible directions
		C.mergeDiagonalsNetworks(C.d2)

	if(C.d2 & (C.d2 - 1))// if the cable is layed diagonally, check the others 2 possible directions
		C.mergeDiagonalsNetworks(C.d2)

	use(1)

	return C

// called when cable_coil is click on an installed obj/cable
// or click on a turf that already contains a "node" cable
/obj/item/stack/cable_coil/proc/cable_join(obj/structure/cable/C, mob/user, showerror = TRUE, forceddir)
	var/turf/U = user.loc
	if(!isturf(U))
		return

	var/turf/T = C.loc

	if(!isturf(T) || T.underfloor_accessibility < UNDERFLOOR_INTERACTABLE) // sanity checks, also stop use interacting with T-scanner revealed cable
		return

	if(get_dist(C, user) > 1)		// make sure it's close enough
		to_chat(user, span_warning("You can't lay cable at a place that far away!"))
		return


	if(U == T && !forceddir) //if clicked on the turf we're standing on and a direction wasn't supplied, try to put a cable in the direction we're facing
		place_turf(T,user)
		return

	var/dirn = get_dir(C, user)
	if(T.allow_z_travel && GET_TURF_BELOW(T) && !locate(/obj/structure/lattice/catwalk, T))
		dirn = DOWN
	if(forceddir)
		dirn = forceddir

	// one end of the clicked cable is pointing towards us and no direction was supplied
	if((C.d1 == dirn || C.d2 == dirn) && !forceddir)
		if(!U.can_have_cabling()) //checking if it's a plating or catwalk
			if (showerror)
				to_chat(user, span_warning("You can only lay cables on catwalks and plating!"))
			return
		if(U.underfloor_accessibility < UNDERFLOOR_INTERACTABLE) //can't place a cable if it's a plating with a tile on it
			to_chat(user, span_warning("You can't lay cable there unless the floor tiles are removed!"))
			return
		else
			// cable is pointing at us, we're standing on an open tile
			// so create a stub pointing at the clicked cable on our tile

			var/fdirn = dir_inverse_multiz(dirn) // the opposite direction

			for(var/obj/structure/cable/LC in U) // check to make sure there's not a cable there already
				if(LC.d1 == fdirn || LC.d2 == fdirn)
					if (showerror)
						to_chat(user, span_warning("There's already a cable at that position!"))
					return

			var/obj/structure/cable/NC = get_new_cable (U)

			NC.d1 = 0
			NC.d2 = fdirn
			NC.add_fingerprint(user)
			NC.update_icon()

			//create a new powernet with the cable, if needed it will be merged later
			var/datum/powernet/newPN = new()
			newPN.add_cable(NC)

			NC.mergeConnectedNetworks(NC.d2) //merge the powernet with adjacents powernets
			NC.mergeConnectedNetworksOnTurf() //merge the powernet with on turf powernets

			if(NC.d2 & (NC.d2 - 1))// if the cable is layed diagonally, check the others 2 possible directions
				NC.mergeDiagonalsNetworks(NC.d2)

			use(1)

			if (NC.shock(user, 50))
				if (prob(50)) //fail
					NC.deconstruct()

			return

	// exisiting cable doesn't point at our position or we have a supplied direction, so see if it's a stub
	else if(C.d1 == 0)
							// if so, make it a full cable pointing from it's old direction to our dirn
		var/nd1 = C.d2	// these will be the new directions
		var/nd2 = dirn


		if(nd1 > nd2)		// swap directions to match icons/states
			nd1 = dirn
			nd2 = C.d2


		for(var/obj/structure/cable/LC in T)		// check to make sure there's no matching cable
			if(LC == C)			// skip the cable we're interacting with
				continue
			if((LC.d1 == nd1 && LC.d2 == nd2) || (LC.d1 == nd2 && LC.d2 == nd1) )	// make sure no cable matches either direction
				if (showerror)
					to_chat(user, span_warning("There's already a cable at that position!"))

				return


		C.update_icon()

		C.d1 = nd1
		C.d2 = nd2

		C.add_fingerprint(user)
		C.update_icon()


		C.mergeConnectedNetworks(C.d1) //merge the powernets...
		C.mergeConnectedNetworks(C.d2) //...in the two new cable directions
		C.mergeConnectedNetworksOnTurf()

		if(C.d1 & (C.d1 - 1))// if the cable is layed diagonally, check the others 2 possible directions
			C.mergeDiagonalsNetworks(C.d1)

		if(C.d2 & (C.d2 - 1))// if the cable is layed diagonally, check the others 2 possible directions
			C.mergeDiagonalsNetworks(C.d2)

		use(1)

		if (C.shock(user, 50))
			if (prob(50)) //fail
				C.deconstruct()
				return

		C.denode()// this call may have disconnected some cables that terminated on the centre of the turf, if so split the powernets.
		return

//////////////////////////////
// Misc.
/////////////////////////////

/obj/item/stack/cable_coil/red
	cable_color = "red"
	color = "#ff0000"

/obj/item/stack/cable_coil/red/one
	amount = 1

/obj/item/stack/cable_coil/yellow
	cable_color = "yellow"
	color = "#ffff00"
=======
/obj/structure/cable/yellow
	cable_color = "yellow"
	color = COLOR_YELLOW
	pixel_x = 2
	pixel_y = 2
>>>>>>> 367709c9418 ([MDB IGNORE] Smartwires, again (#14275))

/obj/structure/cable/green
	cable_color = "green"
	color = COLOR_DARK_LIME
	pixel_x = -2
	pixel_y = -2

/obj/structure/cable/pink
	cable_color = "pink"
	color = COLOR_LIGHT_PINK
	pixel_x = -4
	pixel_y = -4

/obj/structure/cable/orange
	cable_color = "orange"
	color = COLOR_MOSTLY_PURE_ORANGE
	pixel_x = 4
	pixel_y = 4

<<<<<<< HEAD
/obj/item/stack/cable_coil/cyan
	cable_color = "cyan"
	color = "#00ffff"

/obj/item/stack/cable_coil/white
	cable_color = "white"

/obj/item/stack/cable_coil/random
	cable_color = null
	color = "#ffffff"


/obj/item/stack/cable_coil/random/five
	amount = 5

/obj/item/stack/cable_coil/cut
	amount = null
	icon_state = "coil2"
	worn_icon_state = "coil"

/obj/item/stack/cable_coil/cut/Initialize(mapload)
	if(!amount)
		amount = rand(1,2)
	. = ..()
	pixel_x = base_pixel_x + rand(-2, 2)
	pixel_y = base_pixel_y + rand(-2, 2)
	update_icon()

/obj/item/stack/cable_coil/cut/red
	cable_color = "red"
	color = "#ff0000"

/obj/item/stack/cable_coil/cut/yellow
	cable_color = "yellow"
	color = "#ffff00"

/obj/item/stack/cable_coil/cut/blue
	cable_color = "blue"
	color = "#1919c8"

/obj/item/stack/cable_coil/cut/green
	cable_color = "green"
	color = "#00aa00"

/obj/item/stack/cable_coil/cut/pink
	cable_color = "pink"
	color = "#ff3ccd"

/obj/item/stack/cable_coil/cut/orange
	cable_color = "orange"
	color = "#ff8000"

/obj/item/stack/cable_coil/cut/cyan
	cable_color = "cyan"
	color = "#00ffff"

/obj/item/stack/cable_coil/cut/white
	cable_color = "white"

/obj/item/stack/cable_coil/cut/random
	cable_color = null
	color = "#ffffff"
=======
/obj/structure/cable/omni
	icon_state = "0-o"
	cable_color = "white"
	color = COLOR_WHITE
	omni = TRUE
>>>>>>> 367709c9418 ([MDB IGNORE] Smartwires, again (#14275))
