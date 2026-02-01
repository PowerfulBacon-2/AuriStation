/datum/injury/acute

/datum/injury/acute/heal()
	if (bodypart)
		bodypart.remove_injury_tree(src)
	else
		mob.remove_injury(src)
