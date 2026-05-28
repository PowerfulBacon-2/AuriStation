/datum/injury/acute/hypoxia
	base_type = /datum/injury/acute/hypoxia
	examine_description = "<b>hypoxia</b>"
	heal_description = "The effects of this injury will naturally dissipate over time."
	max_absorption = 0
	external = TRUE
	damage_multiplier = 0
	injury_flags = INJURY_LIMB
	damage_multiplier = 1
	pain_multiplier = 0

/datum/injury/acute/hypoxia/update_progressive_effects()
	if (!mob)
		return
	if (progression > mob.maxHealth * 0.5)
		ADD_TRAIT(mob, TRAIT_KNOCKEDOUT, OXYLOSS_TRAIT)
	else
		REMOVE_TRAIT(mob, TRAIT_KNOCKEDOUT, OXYLOSS_TRAIT)

/datum/injury/acute/hypoxia/remove_progressive_effects()
	if (mob)
		REMOVE_TRAIT(mob, TRAIT_KNOCKEDOUT, OXYLOSS_TRAIT)
