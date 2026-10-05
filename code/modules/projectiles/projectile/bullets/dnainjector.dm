/obj/projectile/bullet/dnainjector
	name = "\improper DNA injector"
	icon_state = "syringeproj"
	var/obj/item/dnainjector/injector
	damage = 5
	hitsound_wall = "shatter"

/obj/projectile/bullet/dnainjector/on_hit(atom/target, def_zone)
	if(iscarbon(target))
		var/mob/living/carbon/M = target
		if(!M.check_shields(src, damage, "\the [name]", PROJECTILE_ATTACK, sharpness))
			if(M.can_inject(target_zone = def_zone))
				if(injector.inject(M, firer))
					QDEL_NULL(injector)
					return BULLET_ACT_HIT
			else
				target.visible_message(span_danger("\The [src] was deflected!"), \
									   span_userdanger("You were protected against \the [src]!"))
	return ..()

/obj/projectile/bullet/dnainjector/Destroy()
	QDEL_NULL(injector)
	return ..()
