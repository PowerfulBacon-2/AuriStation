/datum/station_trait/carp_infestation
	name = "Carp infestation"
	trait_type = STATION_TRAIT_NEGATIVE
	weight = 5
	show_in_report = TRUE
	report_message = "Dangerous fauna is present in the area of this station."
	trait_to_give = STATION_TRAIT_CARP_INFESTATION

/datum/station_trait/distant_supply_lines
	name = "Distant supply lines"
	trait_type = STATION_TRAIT_NEGATIVE
	weight = 3
	show_in_report = TRUE
	report_message = "Due to the distance to our normal supply lines, cargo orders are more expensive."
	blacklist = list(/datum/station_trait/strong_supply_lines)
	trait_to_give = STATION_TRAIT_DISTANT_SUPPLY_LINES

/datum/station_trait/slow_shuttle
	name = "Slow Shuttle"
	trait_type = STATION_TRAIT_NEGATIVE
	weight = 5
	show_in_report = TRUE
	report_message = "Due to distance to our supply station, the cargo shuttle will have a slower flight time to your cargo department."
	blacklist = list(/datum/station_trait/quick_shuttle)

/datum/station_trait/slow_shuttle/on_round_start()
	. = ..()
	SSshuttle.supply.callTime *= 1.5

/datum/station_trait/bot_languages
	name = "Bot Language Matrix Malfunction"
	trait_type = STATION_TRAIT_NEGATIVE
	weight = 3
	cost = STATION_TRAIT_COST_LOW
	show_in_report = TRUE
	report_message = "Your station's friendly bots have had their language matrix fried due to an event, resulting in some strange and unfamiliar speech patterns."
	trait_to_give = STATION_TRAIT_BOTS_GLITCHED

/datum/station_trait/bot_languages/New()
	. = ..()
	/// What "caused" our robots to go haywire (fluff)
	var/event_source = pick(list("an ion storm", "a syndicate hacking attempt", "a malfunction", "issues with your onboard AI", "an intern's mistakes", "budget cuts"))
	report_message = "Your station's friendly bots have had their language matrix fried due to [event_source], resulting in some strange and unfamiliar speech patterns."

/datum/station_trait/bot_languages/on_round_start()
	. = ..()
	// All bots that exist round start on station Z OR on the escape shuttle have their set language randomized.
	for(var/mob/living/found_bot as anything in GLOB.bots_list)
		found_bot.randomize_language_if_on_station()

/datum/station_trait/machine_languages
	name = "Machine Language Matrix Malfunction"
	trait_type = STATION_TRAIT_NEGATIVE
	weight = 2
	cost = STATION_TRAIT_COST_FULL
	show_in_report = TRUE
	report_message = "Your station's machines have had their language matrix fried due to an event, \
		resulting in some strange and unfamiliar speech patterns."
	trait_to_give = STATION_TRAIT_MACHINES_GLITCHED

/datum/station_trait/machine_languages/New()
	. = ..()
	// What "caused" our machines to go haywire (fluff)
	var/event_source = pick("an ion storm", "a malfunction", "a software update", "a power surge", "a computer virus", "a subdued machine uprising", "a clown's prank")
	report_message = "Your station's machinery have had their language matrix fried due to [event_source], resulting in some strange and unfamiliar speech patterns."
