/*!
 * Custom rendering solution to allow for advanced effects
 * We (ab)use plane masters and render source/target to cheaply render 2+ planes as 1
 * if you want to read more read the _render_readme.md
 */


/**
 * Render relay object assigned to a plane master to be able to relay it's render onto other planes that are not it's own
 */
/atom/movable/render_plane_relay
	screen_loc = "CENTER"
	layer = -1
	plane = 0
	appearance_flags = PASS_MOUSE | NO_CLIENT_COLOR | KEEP_TOGETHER

/**
 * ## Rendering plate
 *
 * Acts like a plane master, but for plane masters
 * Renders other planes onto this plane, through the use of render objects
 * Any effects applied onto this plane will act on the unified plane
 * IE a bulge filter will apply as if the world was one object
 * remember that once planes are unified on a render plate you cant change the layering of them!
 */
/atom/movable/screen/plane_master/rendering_plate
	name = "default rendering plate"


///this plate renders the final screen to show to the player
/atom/movable/screen/plane_master/rendering_plate/master
	name = "master rendering plate"
	plane = RENDER_PLANE_MASTER
	render_relay_plane = null
	generate_render_target = FALSE

/atom/movable/screen/plane_master/rendering_plate/effects
	name = "game effects plate"
	plane = RENDER_PLANE_EFFECTS
	render_relay_plane = RENDER_PLANE_MASTER

/atom/movable/screen/plane_master/rendering_plate/effects/backdrop(mob/mymob)
	. = ..()


///renders general in charachter game objects
/atom/movable/screen/plane_master/rendering_plate/game_world
	name = "game rendering plate"
	plane = RENDER_PLANE_GAME
	render_relay_plane = RENDER_PLANE_EFFECTS
	var/atom/movable/render_plane_relay/suppression = null

/atom/movable/screen/plane_master/rendering_plate/game_world/backdrop(mob/mymob)
	. = ..()
	add_filter("displacer", 1, displacement_map_filter(render_source = GRAVITY_PULSE_RENDER_TARGET, size = 10))

/atom/movable/screen/plane_master/rendering_plate/game_world/proc/update_suppression(mob/mymob, enabled)
	if (enabled)
		// Create a second relay but blur it
		var/created_suppression = suppression == null
		suppression = suppression || relay_render_to_plane(mymob, RENDER_PLANE_EFFECTS)

		// Apply filters
		// TODO: The filter doesn't animate
		add_filter_and_animate("radial_blur", 1, angular_blur_filter(size=1.5), list("size" = 3), list("size" = 1.5))

		// var/filter = suppression_blur.filters[length(suppression_blur.filters)]
		// animate(filter, time=0, loop=-1, size=1, flags=ANIMATION_PARALLEL)
		// animate(time=10, loop=-1, size=1.5)
		// animate(time=20, loop=-1, size=1)
		// suppression_blur.add_filter("guassian_blur", 2, gauss_blur_filter(size=1))
		// suppression_blur.add_filter("darken", 3, color_matrix_filter(color_matrix_multiply(color_matrix_saturation(0.4), color_matrix_lightness(-0.1))))

		//add_filter_and_animate("darken", 3, color_matrix_filter(suppress_effect), list("alpha" = 255), list("alpha" = 0))

		var/icon/icon = icon('icons/hud/fullscreen/screen_full.dmi', "oxydamageoverlay7")
		suppression.add_filter("alpha_mask", 4, alpha_mask_filter(icon = icon))
		suppression.layer += 1

		var/suppress_effect = color_matrix_multiply(color_matrix_saturation(0.4), color_matrix_lightness(-0.1))
		suppression.color = suppress_effect
		animate(suppression, time=4, color=suppress_effect, flags=ANIMATION_PARALLEL)
		animate(suppression, time=25, color=color_matrix_identity())
	else if (suppression != null)
		animate(suppression, time=50, color=list(
			1, 0, 0, 0,
			0, 1, 0, 0,
			0, 0, 1, 0,
			0, 0, 0, 0,
			0, 0, 0, 0,
		), flags=ANIMATION_PARALLEL)
		QDEL_IN(suppression, 100)
		suppression = null

/atom/movable/screen/plane_master/rendering_plate/game_world/proc/add_filter_and_animate(filter_id, priority, list/filter_effect, list/start_animation, list/end_animation)
	suppression.add_filter("radial_blur", 1, filter_effect)
	var/filter = suppression.filters[length(suppression.filters)]
	// Start the animation
	animate(filter, flags=ANIMATION_PARALLEL)
	// Apply the starting animation
	var/list/start_args = list(
		time = 2,
	)
	start_args += start_animation
	// Transition to the ending animation
	animate(arglist(start_args))
	var/list/end_args = list(
		time = 25,
	)
	end_args += end_animation
	animate(arglist(end_args))

///render plate for OOC stuff like ghosts, hud-screen effects, etc
/atom/movable/screen/plane_master/rendering_plate/non_game
	name = "non-game rendering plate"
	plane = RENDER_PLANE_NON_GAME
	render_relay_plane = RENDER_PLANE_MASTER


/**
 * Plane master proc called in backdrop() that creates a relay object, sets it as needed and then adds it to the clients screen
 * Sets:
 * * layer from plane to avoid z-fighting
 * * plane to relay the render to
 * * render_source so that the plane will render on this object
 * * mouse opacity to ensure proper mouse hit tracking
 * * name for debugging purposes
 * Other vars such as alpha will automatically be applied with the render source
 * Arguments:
 * * mymob: mob whose plane is being backdropped
 * * relay_plane: plane we are relaying this plane master to
 */
/atom/movable/screen/plane_master/proc/relay_render_to_plane(mob/mymob, relay_plane)
	if(!render_target && generate_render_target)
		render_target = "*[name]: AUTOGENERATED RENDER TGT"
	var/atom/movable/render_plane_relay/relay = new()
	relay.render_source = render_target
	relay.plane = relay_plane
	relay.layer = (plane + abs(LOWEST_EVER_PLANE))*0.5 //layer must be positive but can be a decimal
	if(blend_mode_override)
		relay.blend_mode = blend_mode_override
	else
		relay.blend_mode = blend_mode
	relay.mouse_opacity = mouse_opacity
	relay.name = render_target
	if (mymob)
		relay.screen_loc = (mymob.client?.byond_version > 515) ? "1,1" : "CENTER"
		mymob.client.screen += relay
	if(blend_mode != BLEND_MULTIPLY) //internal beyond snowflake do not touch
		blend_mode = BLEND_DEFAULT
	return relay
