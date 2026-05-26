/mob/living/take_direct_damage(amount, type = BRUTE, flag = DAMAGE_STANDARD, zone = null)
	switch(type)
		if(BRUTE)
			adjustBruteLoss(amount)
		if(BURN)
			adjustFireLoss(amount)
		if(TOX)
			adjustToxLoss(amount)
		if(OXY)
			adjustOxyLoss(amount)
		if(CLONE)
			adjustCloneLoss(amount)
		if(STAMINA)
			adjustExhaustion(amount)

/mob/living/proc/get_damage_amount(damagetype = BRUTE)
	switch(damagetype)
		if(BRUTE)
			return getBruteLoss()
		if(BURN)
			return getFireLoss()
		if(TOX)
			return getToxLoss()
		if(OXY)
			return getOxyLoss()
		if(CLONE)
			return getCloneLoss()
		if(STAMINA)
			return getExhaustion()

/// return the total damage of all types which update your health
/mob/living/proc/get_total_damage(precision = DAMAGE_PRECISION)
	return round(getBruteLoss() + getFireLoss() + getToxLoss() + getOxyLoss() + getCloneLoss(), precision)

/mob/living/proc/apply_effect(effect = 0,effecttype = EFFECT_STUN, blocked = FALSE)
	var/hit_percent = (100-blocked)/100
	if(!effect || (hit_percent <= 0))
		return 0
	switch(effecttype)
		if(EFFECT_STUN)
			Stun(effect * hit_percent)
		if(EFFECT_KNOCKDOWN)
			Knockdown(effect * hit_percent)
		if(EFFECT_PARALYZE)
			Paralyze(effect * hit_percent)
		if(EFFECT_IMMOBILIZE)
			Immobilize(effect * hit_percent)
		if(EFFECT_UNCONSCIOUS)
			Unconscious(effect * hit_percent)
		if(EFFECT_EYE_BLUR)
			blur_eyes(effect * hit_percent)
		if(EFFECT_DROWSY)
			drowsyness = max(drowsyness,(effect * hit_percent))
	return 1


/mob/living/proc/apply_effects(
	stun = 0,
	knockdown = 0,
	unconscious = 0,
	slur = 0 SECONDS,
	stutter = 0 SECONDS,
	eyeblur = 0,
	drowsy = 0,
	blocked = 0, // This one's not an effect, don't be confused - it's block chance
	stamina = 0, // This one's a damage type, and not an effect
	jitter = 0 SECONDS,
	paralyze = 0,
	immobilize = 0
	)
	if(blocked >= 100)
		return BULLET_ACT_BLOCK

	if(stun)
		apply_effect(stun, EFFECT_STUN, blocked)
	if(knockdown)
		apply_effect(knockdown, EFFECT_KNOCKDOWN, blocked)
	if(unconscious)
		apply_effect(unconscious, EFFECT_UNCONSCIOUS, blocked)
	if(paralyze)
		apply_effect(paralyze, EFFECT_PARALYZE, blocked)
	if(immobilize)
		apply_effect(immobilize, EFFECT_IMMOBILIZE, blocked)
	if(eyeblur)
		apply_effect(eyeblur, EFFECT_EYE_BLUR, blocked)
	if(drowsy)
		apply_effect(drowsy, EFFECT_DROWSY, blocked)
	if(stamina)
		take_direct_damage(stamina, STAMINA)

	if(slur)
		adjust_timed_status_effect(slur, /datum/status_effect/speech/slurring/drunk)
	if(stutter)
		adjust_timed_status_effect(stutter, /datum/status_effect/speech/stutter)

	if(jitter && (status_flags & CANSTUN) && !HAS_TRAIT(src, TRAIT_STUNIMMUNE))
		adjust_timed_status_effect(jitter, /datum/status_effect/jitter)
	return BULLET_ACT_HIT


/mob/living/proc/getBruteLoss()
	return get_injury_amount(BRUTE)

/mob/living/proc/adjustBruteLoss(amount, updating_health = TRUE, forced = FALSE, required_status)
	if(!forced && HAS_TRAIT(src, TRAIT_GODMODE))
		return FALSE
	return adjust_injury(BRUTE, amount)

/mob/living/proc/setBruteLoss(amount, updating_health = TRUE, forced = FALSE)
	if(!forced && HAS_TRAIT(src, TRAIT_GODMODE))
		return
	set_injury(BRUTE, amount)

/mob/living/proc/getOxyLoss()
	return get_injury_amount(OXY)

/mob/living/proc/adjustOxyLoss(amount, updating_health = TRUE, forced = FALSE)
	if(!forced && HAS_TRAIT(src, TRAIT_GODMODE))
		return FALSE
	return adjust_injury(OXY, amount)

/mob/living/proc/setOxyLoss(amount, updating_health = TRUE, forced = FALSE)
	if(!forced && HAS_TRAIT(src, TRAIT_GODMODE))
		return
	set_injury(OXY, amount)

/mob/living/proc/getToxLoss()
	return get_injury_amount(TOX)

/mob/living/proc/adjustToxLoss(amount, updating_health = TRUE, forced = FALSE)
	if(!forced && HAS_TRAIT(src, TRAIT_GODMODE))
		return FALSE
	return adjust_injury(TOX, amount)

/mob/living/proc/setToxLoss(amount, updating_health = TRUE, forced = FALSE)
	if(!forced && HAS_TRAIT(src, TRAIT_GODMODE))
		return FALSE
	set_injury(TOX, amount)

/mob/living/proc/getFireLoss()
	return get_injury_amount(BURN)

/mob/living/proc/adjustFireLoss(amount, updating_health = TRUE, forced = FALSE)
	if(!forced && HAS_TRAIT(src, TRAIT_GODMODE))
		return FALSE
	return adjust_injury(BURN, amount)

/mob/living/proc/setFireLoss(amount, updating_health = TRUE, forced = FALSE)
	if(!forced && HAS_TRAIT(src, TRAIT_GODMODE))
		return
	set_injury(BURN, amount)

/mob/living/proc/getCloneLoss()
	return get_injury_amount(CLONE)

/mob/living/proc/adjustCloneLoss(amount, updating_health = TRUE, forced = FALSE)
	if(!forced && (HAS_TRAIT(src, TRAIT_GODMODE) || HAS_TRAIT(src, TRAIT_NOCLONELOSS)))
		return FALSE
	return adjust_injury(CLONE, amount)

/mob/living/proc/setCloneLoss(amount, updating_health = TRUE, forced = FALSE)
	if(!forced && (HAS_TRAIT(src, TRAIT_GODMODE) || HAS_TRAIT(src, TRAIT_NOCLONELOSS)))
		return FALSE
	return set_injury(CLONE, amount)

/mob/living/proc/adjustOrganLoss(slot, amount, maximum, required_status)
	return

/mob/living/proc/setOrganLoss(slot, amount, maximum)
	return

/mob/living/proc/getOrganLoss(slot)
	return

/mob/living/proc/getExhaustion()
	return exhaustion

/mob/living/proc/adjustExhaustion(amount, updating_health = TRUE, forced = FALSE)
	return

/mob/living/proc/setStaminaLoss(amount, updating_health = TRUE, forced = FALSE)
	return

// damage ONE external organ, organ gets randomly selected from damaged ones.
/mob/living/proc/take_direct_bodypart_injury(injury, amount, required_status)
	take_direct_damage(amount, injury, DAMAGE_EXISTENTIAL)
	updatehealth()
	update_stamina()

// heal MANY bodyparts, in random order
/mob/living/proc/heal_overall_injuries(injury_type, amount, required_status)
	adjust_injury(injury_type, -amount)

// damage MANY bodyparts, in random order
/mob/living/proc/take_direct_overall_damage(injury_type, amount, required_status)
	adjust_injury(injury_type, amount)

//heal up to amount damage, in a given order
/mob/living/proc/heal_ordered_damage(amount, list/damage_types)
	. = amount //we'll return the amount of damage healed
	for(var/i in damage_types)
		var/amount_to_heal = min(amount, get_damage_amount(i)) //heal only up to the amount of damage we have
		if(amount_to_heal)
			take_direct_damage(-amount_to_heal, i)
			amount -= amount_to_heal //remove what we healed from our current amount
		if(!amount)
			break
	. -= amount //if there's leftover healing, remove it from what we return
