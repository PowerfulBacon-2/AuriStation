/datum/job_group
	/// The EXP that this job group provides
	var/exp_type
	/// The jobs inside of this job group
	var/list/jobs

/datum/job_group/command
	exp_type = EXP_TYPE_COMMAND
	jobs = list(
		/datum/job/captain,
		/datum/job/head_of_personnel,
		/datum/job/head_of_security,
		/datum/job/chief_engineer,
		/datum/job/quartermaster,
		/datum/job/chief_medical_officer,
		/datum/job/research_director,
	)

/datum/job_group/engineering
	exp_type = EXP_TYPE_ENGINEERING
	jobs = list(
		/datum/job/chief_engineer,
		/datum/job/station_engineer,
		/datum/job/atmospheric_technician,
	)

/datum/job_group/medical
	exp_type = EXP_TYPE_MEDICAL
	jobs = list(
		/datum/job/chief_medical_officer,
		/datum/job/medical_doctor,
		/datum/job/paramedic,
		/datum/job/brig_physician,
		/datum/job/chemist,
		/datum/job/geneticist,
		/datum/job/surgeon,
	)

/datum/job_group/science
	exp_type = EXP_TYPE_SCIENCE
	jobs = list(
		/datum/job/research_director,
		/datum/job/scientist,
		/datum/job/roboticist,
	)

/datum/job_group/supply
	exp_type = EXP_TYPE_SUPPLY
	jobs = list(
		/datum/job/quartermaster,
		/datum/job/cargo_technician,
		/datum/job/shaft_miner,
	)

/datum/job_group/security
	exp_type = EXP_TYPE_SECURITY
	jobs = list(
		/datum/job/head_of_security,
		/datum/job/security_officer,
		/datum/job/deputy,
		/datum/job/brig_physician,
		/datum/job/detective,
		/datum/job/warden,
	)

/datum/job_group/silicon
	exp_type = EXP_TYPE_SILICON
	jobs = list(
		/datum/job/cyborg,
		/datum/job/ai,
	)

/datum/job_group/service
	jobs = list(
		/datum/job/assistant,
		/datum/job/bartender,
		/datum/job/botanist,
		/datum/job/chaplain,
		/datum/job/clown,
		/datum/job/cook,
		/datum/job/curator,
		/datum/job/gimmick,
		/datum/job/gimmick/barber,
		/datum/job/gimmick/psychiatrist,
		/datum/job/gimmick/stage_magician,
		/datum/job/gimmick/vip,
		/datum/job/janitor,
	)
