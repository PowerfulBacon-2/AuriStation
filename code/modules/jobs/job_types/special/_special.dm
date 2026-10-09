/datum/job/special
	title = "Unemployed"
	description = "Not employed or working on Space Station 13."
	job_flags = JOB_NO_ANNOUNCE | JOB_NO_MIDROUND
	show_in_prefs = FALSE
	bank_account_department = NONE
	biohazard = 0
	rpg_title = "Vagabond"

/datum/job/special/New(title)
	src.title = title
	. = ..()
