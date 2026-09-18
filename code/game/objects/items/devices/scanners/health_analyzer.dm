#define SCANNER_CONDENSED 0
#define SCANNER_VERBOSE 1

/obj/item/healthanalyzer
	name = "health analyzer"
	icon = 'icons/obj/device.dmi'
	icon_state = "health"
	inhand_icon_state = "healthanalyzer"
	worn_icon_state = "healthanalyzer"
	lefthand_file = 'icons/mob/inhands/equipment/medical_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/equipment/medical_righthand.dmi'
	desc = "A hand-held body scanner capable of distinguishing vital signs of the subject. Has a side button to scan for chemicals"
	flags_1 = CONDUCT_1
	item_flags = NOBLUDGEON
	slot_flags = ITEM_SLOT_BELT
	throwforce = 3
	w_class = WEIGHT_CLASS_TINY
	throw_speed = 3
	throw_range = 7
	custom_materials = list(/datum/material/iron=200)
	custom_price = 100
	var/advanced = FALSE
	/// The object that we are currently scanning
	var/datum/weakref/target = null

/obj/item/healthanalyzer/suicide_act(mob/living/carbon/user)
	user.visible_message(span_suicide("[user] begins to analyze [user.p_them()]self with [src]! The display shows that [user.p_theyre()] dead!"))
	return BRUTELOSS

/obj/item/healthanalyzer/attack(mob/living/M, mob/living/carbon/human/user)
	flick("[icon_state]-scan", src)	//makes it so that it plays the scan animation upon scanning, including clumsy scanning

	target = WEAKREF(M)
	ui_interact(user)

	user.visible_message(span_notice("[user] analyzes [M]'s vitals."))
	playsound(user.loc, 'sound/effects/fastbeep.ogg', 10)
	add_fingerprint(user)
	add_fibers(M)

/obj/item/healthanalyzer/add_context_interaction(datum/screentip_context/context, mob/user, atom/target)
	if (isliving(target))
		context.add_left_click_action("Scan Health")

/obj/item/healthanalyzer/ui_state(mob/user)
	return new /datum/ui_state/hands_state/health_analyzer(src)

/obj/item/healthanalyzer/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "HealthAnalyzer")
		ui.set_autoupdate(TRUE)
		ui.open()
	return TRUE

/obj/item/healthanalyzer/ui_data(mob/user)
	var/list/data = list()
	var/mob/living/target = src.target?.resolve()

	if (target == null)
		data["target"] = null
		return data

	// Overall Stats
	data["target"] = target.get_examine_name()
	data["is_dead"] = target.stat == DEAD || HAS_TRAIT(target, TRAIT_FAKEDEATH)
	data["consciousness"] = target.stat == DEAD || HAS_TRAIT(target, TRAIT_FAKEDEATH) \
		? HEALTH_THRESHOLD_DEAD \
		: target.consciousness.value / target.consciousness.max_value

	// Body-wide Attribute
	var/list/body_injuries = list()
	for (var/datum/injury/injury in target.get_injuries(null))
		body_injuries += list(injury_to_list(injury))

	append_husking(body_injuries, target)

	if(iscarbon(target))
		append_trauma_and_quirks(body_injuries, target)

	// Apply the attributes
	data["injuries"] = list()
	data["injuries"]["body"] = body_injuries

	var/list/zones = list(
		BODY_ZONE_CHEST,
		BODY_ZONE_HEAD,
		BODY_ZONE_L_ARM,
		BODY_ZONE_L_LEG,
		BODY_ZONE_R_ARM,
		BODY_ZONE_R_LEG
	)
	for (var/zone in zones)
		var/list/part_injuries = list()
		for (var/datum/injury/injury in target.get_injuries(zone))
			part_injuries += list(injury_to_list(injury))
		data["injuries"][parse_zone(zone)] = part_injuries
	return data

/obj/item/healthanalyzer/proc/append_husking(list/body_injuries, mob/living/target)
	PRIVATE_PROC(TRUE)
	if (!HAS_TRAIT(target, TRAIT_HUSK))
		return
	if (advanced)
		if(HAS_TRAIT_FROM(target, TRAIT_HUSK, BURN))
			body_injuries += list(fake_injury("Husked (Burns)", "Tend wounds or Synthflesh."))
		else if (HAS_TRAIT_FROM(target, TRAIT_HUSK, CHANGELING_DRAIN))
			body_injuries += list(fake_injury("Husked (Drained)", "Synthflesh."))
		else
			body_injuries += list(fake_injury("Husked (Unknown)", "Synthflesh."))
	else
		body_injuries += list(fake_injury("Husked", "Tend wounds or Synthflesh, depending on the cause of the husking."))

/obj/item/healthanalyzer/proc/append_trauma_and_quirks(list/body_injuries, mob/living/carbon/carbontarget)
	PRIVATE_PROC(TRUE)
	if(LAZYLEN(carbontarget.get_traumas()))
		for(var/datum/brain_trauma/trauma in carbontarget.get_traumas())
			switch(trauma.resilience)
				if (TRAUMA_RESILIENCE_BASIC)
					body_injuries += list(fake_injury(trauma.scan_desc, "Basic medicine."))
				if(TRAUMA_RESILIENCE_SURGERY)
					body_injuries += list(fake_injury(trauma.scan_desc, "Brain recalibration surgery."))
				if(TRAUMA_RESILIENCE_LOBOTOMY)
					body_injuries += list(fake_injury(trauma.scan_desc, "Lobotomy surgery."))
				if(TRAUMA_RESILIENCE_MAGIC, TRAUMA_RESILIENCE_ABSOLUTE)
					body_injuries += list(fake_injury(trauma.scan_desc, "Unknown."))
	for(var/datum/quirk/candidate in carbontarget.get_visible_quirks(CAT_QUIRK_MAJOR_DISABILITY))
		body_injuries += list(fake_injury(candidate.name, "Unknown."))
	if (advanced)
		for(var/datum/quirk/candidate in carbontarget.get_visible_quirks(CAT_QUIRK_MINOR_DISABILITY))
			body_injuries += list(fake_injury(candidate.name, "Unknown."))

/obj/item/healthanalyzer/proc/injury_to_list(datum/injury/injury)
	var/list/injury_object = list()
	injury_object["name"] = injury.examine_description
	injury_object["severity"] = injury.severity_level
	injury_object["effectiveness_modifier"] = injury.effectiveness_modifier
	injury_object["bone_armour_modifier"] = injury.bone_armour_modifier
	injury_object["skin_armour_modifier"] = injury.skin_armour_modifier
	injury_object["pain"] = injury.pain + injury.pain_multiplier * injury.progression
	injury_object["damage"] = injury.added_damage + injury.damage_multiplier * injury.progression
	injury_object["heal_text"] = injury.heal_description
	return injury_object

/obj/item/healthanalyzer/proc/fake_injury(name, heal_text)
	var/list/injury_object = list()
	injury_object["name"] = name
	injury_object["heal_text"] = heal_text
	return injury_object

/**
 * Health analyzer state requires the target to be nearby, and for there to be a target.
 * Does not update if the target is >1 unit away, and closes if they are more than 3.
 */
/datum/ui_state/hands_state/health_analyzer
	var/obj/item/healthanalyzer/source

/datum/ui_state/hands_state/health_analyzer/New(obj/item/healthanalyzer/source)
	. = ..()
	src.source = source

/datum/ui_state/hands_state/health_analyzer/can_use_topic(src_object, mob/user)
	. = ..()
	if (. <= UI_CLOSE)
		return UI_CLOSE
	var/mob/living/target = source.target?.resolve()
	if (target == null)
		return UI_CLOSE
	// Stop updating when not adjacent
	if (!user.Adjacent(target))
		. = min(., UI_DISABLED)
	// Close when too far away
	if (get_dist(user, target) > 3)
		return UI_CLOSE

/**
 * healthscan
 * returns a list of everything a health scan should give to a player.
 * Examples of where this is used is Health Analyzer and the Physical Scanner tablet app.
 * Args:
 * user - The person with the scanner
 * target - The person being scanned
 * mode - Uses SCANNER_CONDENSED or SCANNER_VERBOSE to decide whether to give a list of all individual limb damage
 * advanced - Whether it will give more advanced details, such as husk source.
 * tochat - Whether to immediately post the result into the chat of the user, otherwise it will return the results.
 */
/proc/healthscan(mob/user, mob/living/target, mode = SCANNER_VERBOSE, advanced = FALSE, tochat = TRUE)
	if(user.incapacitated())
		return

	// the final list of strings to render
	var/render_list = list()

	if(ishuman(target))
		var/mob/living/carbon/human/humantarget = target
		if(humantarget.undergoing_cardiac_arrest() && humantarget.stat != DEAD)
			render_list += "<span class='alert ml-1'><b>Subject suffering from heart attack: Apply defibrillation or other electric shock immediately!</b></span>\n"

	SEND_SIGNAL(target, COMSIG_LIVING_HEALTHSCAN, render_list, advanced, user, mode, tochat)

	if (!target.get_organ_slot(ORGAN_SLOT_BRAIN)) // kept exclusively for soul purposes
		render_list += "<span class='alert ml-1'>Subject lacks a brain.</span>\n"
	//Eyes and ears
	if(advanced && iscarbon(target))
		var/mob/living/carbon/carbontarget = target

		// Ear status
		var/obj/item/organ/ears/ears = carbontarget.get_organ_slot(ORGAN_SLOT_EARS)
		if(istype(ears))
			if(HAS_TRAIT_FROM(carbontarget, TRAIT_DEAF, GENETIC_MUTATION))
				render_list += "<span class='alert ml-2'>Subject is genetically deaf.\n</span>"
			else if(HAS_TRAIT_FROM(carbontarget, TRAIT_DEAF, EAR_DAMAGE))
				render_list += "<span class='alert ml-2'>Subject is deaf from ear damage.\n</span>"
			else if(HAS_TRAIT(carbontarget, TRAIT_DEAF))
				render_list += "<span class='alert ml-2'>Subject is deaf.\n</span>"
			else
				if(ears.damage)
					render_list += "<span class='alert ml-2'>Subject has [ears.damage > ears.maxHealth ? "permanent ": "temporary "]hearing damage.\n</span>"
				if(ears.deaf)
					render_list += "<span class='alert ml-2'>Subject is [ears.damage > ears.maxHealth ? "permanently ": "temporarily "] deaf.\n</span>"

		// Eye status
		var/obj/item/organ/eyes/eyes = carbontarget.get_organ_slot(ORGAN_SLOT_EYES)
		if(istype(eyes))
			if(carbontarget.is_blind())
				render_list += "<span class='alert ml-2'>Subject is blind.\n</span>"
			else if(HAS_TRAIT(carbontarget, TRAIT_NEARSIGHT))
				render_list += "<span class='alert ml-2'>Subject is nearsighted.\n</span>"

	// Body part damage report
	if(iscarbon(target))
		var/mob/living/carbon/carbontarget = target
		var/list/damaged = carbontarget.get_injured_bodyparts(include_injuries = TRUE)
		if(length(damaged)>0 || oxy_loss>0 || tox_loss>0 || fire_loss>0)
			var/dmgreport = {"
<span class='info ml-1'>General status:</span>
<table class='ml-2' style='width:100%'>
	<tr><font face='Verdana'>
		<td style='width:7em;'><font color='#ff0000'><b>Damage:</b></font></td>
		<td style='width:5em;'><font color='#ff3333'><b>Brute</b></font></td>
		<td style='width:4em;'><font color='#ff9933'><b>Burn</b></font></td>
		<td style='width:4em;'><font color='#00cc66'><b>Toxin</b></font></td>
		<td style='width:8em;'><font color='#00cccc'><b>Hypoxia</b></td>
		<td style='width:calc(100%-28em);'><font color='#7c7c7c'><b>Injuries</b></td>
	</font></tr>
	<tr>
		<td><font color='#ff3333'><b>Overall:</b></font></td>
		<td><font color='#ff3333'><b>[CEILING(brute_loss,1)]</b></font></td>
		<td><font color='#ff9933'><b>[CEILING(fire_loss,1)]</b></font></td>
		<td><font color='#00cc66'><b>[CEILING(tox_loss,1)]</b></font></td>
		<td><font color='#33ccff'><b>[CEILING(oxy_loss,1)]</b></font></td>
		<td></td>
	</tr>"}

			if(mode == SCANNER_VERBOSE)
				for(var/obj/item/bodypart/limb as anything in damaged)
					if(limb.bodytype & BODYTYPE_ROBOTIC)
						dmgreport += "<tr><td><font color='#cc3333'>[capitalize(limb.name)]:</font></td>"
					else
						dmgreport += "<tr><td><font color='#cc3333'>[capitalize(limb.plaintext_zone)]:</font></td>"
					dmgreport += "<td><font color='#ff3333'>[limb.get_injury_amount(BRUTE)]</font></td>"
					dmgreport += "<td><font color='#ff9933'>[limb.get_injury_amount(BURN)]</font></td>"
					dmgreport += "<td><font color='#00cc66'>[limb.get_injury_amount(TOX)]</font></td>"
					dmgreport += "<td><font color='#33ccff'>[limb.get_injury_amount(OXY)]</font></td>"
					var/list/injury_texts = list()
					for (var/datum/injury/injury in limb.injuries)
						if (!injury.examine_description)
							continue
						if (injury.type == BRUTE || injury.type == BURN || injury.type == TOX || injury.type == OXY)
							continue
						if (injury.heal_description)
							injury_texts += span_tooltip(injury.heal_description, injury.examine_description)
						else
							injury_texts += injury.examine_description
					dmgreport += "<td>[jointext(injury_texts, ", ")]</td>"
					dmgreport += "</tr>"
			dmgreport += "</font></table>"
			render_list += dmgreport // tables do not need extra linebreak
		for(var/obj/item/bodypart/limb as anything in carbontarget.bodyparts)
			for(var/obj/item/embed as anything in limb.embedded_objects)
				render_list += "<span class='alert ml-1'>Embedded object: [embed] located in \the [limb.plaintext_zone]</span>\n"

	if(ishuman(target))
		var/mob/living/carbon/human/humantarget = target

		// Organ damage, missing organs
		if(humantarget.internal_organs && humantarget.internal_organs.len)
			var/render = FALSE
			var/toReport = "<span class='info ml-1'>Organs:</span>\
				<table class='ml-2'><tr>\
				<td style='width:6em;'><font color='#ff0000'><b>Organ:</b></font></td>\
				[advanced ? "<td style='width:3em;'><font color='#ff0000'><b>Dmg</b></font></td>" : ""]\
				<td style='width:12em;'><font color='#ff0000'><b>Status</b></font></td>"

			for(var/obj/item/organ/organ as anything in humantarget.internal_organs)
				var/status = organ.get_status_text()
				if (status != "")
					render = TRUE
					toReport += "<tr><td><font color='#cc3333'>[organ.name]:</font></td>\
						[advanced ? "<td><font color='#ff3333'>[CEILING(organ.damage,1)]</font></td>" : ""]\
						<td>[status]</td></tr>"

			var/missing_organs = list()
			if(!humantarget.get_organ_slot(ORGAN_SLOT_BRAIN))
				missing_organs += "brain"
			if(!HAS_TRAIT_FROM(humantarget, TRAIT_NO_BLOOD, SPECIES_TRAIT) && !humantarget.get_organ_slot(ORGAN_SLOT_HEART))
				missing_organs += "heart"
			if(!HAS_TRAIT_FROM(humantarget, TRAIT_NOBREATH, SPECIES_TRAIT) && !humantarget.get_organ_slot(ORGAN_SLOT_LUNGS))
				missing_organs += "lungs"
			if(/*!HAS_TRAIT_FROM(humantarget, TRAIT_LIVERLESS_METABOLISM, SPECIES_TRAIT) &&*/ !humantarget.get_organ_slot(ORGAN_SLOT_LIVER))
				missing_organs += "liver"
			if(!HAS_TRAIT_FROM(humantarget, TRAIT_NOHUNGER, SPECIES_TRAIT) && !humantarget.get_organ_slot(ORGAN_SLOT_STOMACH))
				missing_organs += "stomach"
			if(!humantarget.get_organ_slot(ORGAN_SLOT_TONGUE))
				missing_organs += "tongue"
			if(!humantarget.get_organ_slot(ORGAN_SLOT_EARS))
				missing_organs += "ears"
			if(!humantarget.get_organ_slot(ORGAN_SLOT_EYES))
				missing_organs += "eyes"

			if(length(missing_organs))
				render = TRUE
				for(var/organ in missing_organs)
					toReport += "<tr><td><font color='#cc3333'>[organ]:</font></td>\
						[advanced ? "<td><font color='#ff3333'>["-"]</font></td>" : ""]\
						<td><font color='#cc3333'>["Missing"]</font></td></tr>"

			if(render)
				render_list += toReport + "</table>" // tables do not need extra linebreak

		//Genetic stability
		if(advanced && humantarget.has_dna())
			render_list += "<span class='info ml-1'>Genetic Stability: [humantarget.dna.stability]%.</span>\n"
			if(humantarget.has_status_effect(/datum/status_effect/ling_transformation))
				render_list += "<span class='info ml-1'>Subject's DNA appears to be in an unstable state.</span>\n"

		// Species and body temperature
		var/datum/species/targetspecies = humantarget.dna.species
		var/mutant = humantarget.dna.check_mutation(/datum/mutation/hulk) \
			|| targetspecies.mutantlungs != initial(targetspecies.mutantlungs) \
			|| targetspecies.mutantbrain != initial(targetspecies.mutantbrain) \
			|| targetspecies.mutantheart != initial(targetspecies.mutantheart) \
			|| targetspecies.mutanteyes != initial(targetspecies.mutanteyes) \
			|| targetspecies.mutantears != initial(targetspecies.mutantears) \
			|| targetspecies.mutanttongue != initial(targetspecies.mutanttongue) \
			|| targetspecies.mutantliver != initial(targetspecies.mutantliver) \
			|| targetspecies.mutantstomach != initial(targetspecies.mutantstomach) \
			|| targetspecies.mutantappendix != initial(targetspecies.mutantappendix) \
			|| targetspecies.mutantwings != initial(targetspecies.mutantwings)

		render_list += "<span class='info ml-1'>Species: [targetspecies.name][mutant ? "-derived mutant" : ""]</span>\n"
		var/core_temperature_message = "Core temperature: [round(humantarget.coretemperature-T0C, 0.1)] &deg;C ([round(humantarget.coretemperature*1.8-459.67,0.1)] &deg;F)"
		if(humantarget.coretemperature >= humantarget.get_body_temp_heat_damage_limit())
			render_list += "<span class='alert ml-1'>☼ [core_temperature_message] ☼</span>\n"
		else if(humantarget.coretemperature <= humantarget.get_body_temp_cold_damage_limit())
			render_list += "<span class='alert ml-1'>❄ [core_temperature_message] ❄</span>\n"
		else
			render_list += "<span class='info ml-1'>[core_temperature_message]</span>\n"

	var/body_temperature_message = "Body temperature: [round(target.bodytemperature-T0C, 0.1)] &deg;C ([round(target.bodytemperature*1.8-459.67,0.1)] &deg;F)"
	if(target.bodytemperature >= target.get_body_temp_heat_damage_limit())
		render_list += "<span class='alert ml-1'>☼ [body_temperature_message] ☼</span>\n"
	else if(target.bodytemperature <= target.get_body_temp_cold_damage_limit())
		render_list += "<span class='alert ml-1'>❄ [body_temperature_message] ❄</span>\n"
	else
		render_list += "<span class='info ml-1'>[body_temperature_message]</span>\n"

	// Time of death
	if(target.tod && (target.stat == DEAD || ((HAS_TRAIT(target, TRAIT_FAKEDEATH)) && !advanced)))
		render_list += "<span class='info ml-1'>Time of Death: [target.tod]</span>\n"
		var/tdelta = round(world.time - target.timeofdeath)
		render_list += "<span class='alert ml-1'><b>Subject died [DisplayTimeText(tdelta)] ago.</b></span>\n"

	/*
	// Wounds
	if(iscarbon(target))
		var/mob/living/carbon/carbontarget = target
		var/list/wounded_parts = carbontarget.get_wounded_bodyparts()
		for(var/i in wounded_parts)
			var/obj/item/bodypart/wounded_part = i
			render_list += "<span class='alert ml-1'><b>Physical trauma[LAZYLEN(wounded_part.wounds) > 1 ? "s" : ""] detected in [wounded_part.name]</b>"
			for(var/k in wounded_part.wounds)
				var/datum/wound/W = k
				render_list += "<div class='ml-2'>[W.name] ([W.severity_text()])\nRecommended treatment: [W.treat_text]</div>" // less lines than in woundscan() so we don't overload people trying to get basic med info
			render_list += "</span>"
	*/

	//Diseases
	for(var/datum/disease/disease as anything in target.diseases)
		if(!(disease.visibility_flags & HIDDEN_SCANNER))
			render_list += "<span class='alert ml-1'><b>Warning: [disease.form] detected</b>\n\
			<div class='ml-2'>Name: [disease.name].\nType: [disease.spread_text].\nStage: [disease.stage]/[disease.max_stages].\nPossible Cure: [disease.cure_text]</div>\
			</span>" // divs do not need extra linebreak

	// Blood Level
	if(target.has_dna())
		var/mob/living/carbon/carbontarget = target
		var/blood_id = carbontarget.blood.get_blood_id()
		if(blood_id)
			if(target.is_bleeding())
				render_list += "<span class='alert ml-1'><b>Subject is bleeding at a rate of [round(carbontarget.get_bleed_rate(), 0.1)]/s!</b></span>\n"
			else if (carbontarget.is_bandaged())
				render_list += "<span class='alert ml-1'><b>Subject is bleeding (Bandaged)!</b></span>\n"
			var/blood_percent = round((carbontarget.blood.volume / BLOOD_VOLUME_NORMAL) * 100)
			var/blood_type = carbontarget.dna.blood_type.name
			if(blood_id != /datum/reagent/blood) // special blood substance
				var/datum/reagent/R = GLOB.chemical_reagents_list[blood_id]
				blood_type = R ? R.name : blood_id

			// Get compatible blood type names
			var/list/compatible_names = list()
			for(var/compatible_type in carbontarget.dna.blood_type.compatible_types)
				var/datum/blood_type/compatible_datum = new compatible_type()
				compatible_names += compatible_datum.name
				qdel(compatible_datum)
			var/blood_info = "[blood_type] (Compatible: [jointext(compatible_names, ", ")])"

			if(HAS_TRAIT(carbontarget, TRAIT_MASQUERADE))
				render_list += "<span class='alert ml-1'>Blood level: 100 %, 560 cl,</span> [span_info("type: [blood_info]")]\n"
			else if(carbontarget.blood.volume <= BLOOD_VOLUME_SAFE && carbontarget.blood.volume > BLOOD_VOLUME_OKAY)
				render_list += "<span class='alert ml-1'>Blood level: LOW [blood_percent] %, [carbontarget.blood.volume] cl,</span> [span_info("type: [blood_info]")]\n"
			else if(carbontarget.blood.volume <= BLOOD_VOLUME_OKAY)
				render_list += "<span class='alert ml-1'>Blood level: <b>CRITICAL [blood_percent] %</b>, [carbontarget.blood.volume] cl,</span> [span_info("type: [blood_info]")]\n"
			else
				render_list += "<span class='info ml-1'>Blood level: [blood_percent] %, [round(carbontarget.blood.volume)] cl, type: [blood_type]</span>\n"
		render_list += "<span class='info ml-1'>Final Cell Saturation: [round(carbontarget.blood.get_effectiveness() * 100)]%</span>\n"
		render_list += "<span class='info ml-2'>Lung Oxygenation: [round(carbontarget.blood.get_oxygenation_rating() * 100)]%</span>\n"
		render_list += "<span class='info ml-2'>Blood Circulation: [round(carbontarget.blood.get_circulation_rating() * 100)]%</span>\n"
		render_list += "<span class='info ml-1'>Perceived Pain: [round(carbontarget.pain.adjusted_pain)]% (Approaching: [round(carbontarget.pain.pain)]%)</span>\n"

	// Cybernetics
	if(iscarbon(target))
		var/mob/living/carbon/carbontarget = target
		var/cyberimp_detect
		for(var/obj/item/organ/cyberimp/cyberimp in carbontarget.internal_organs)
			if(cyberimp.status == ORGAN_ROBOTIC && !cyberimp.syndicate_implant)
				cyberimp_detect += "[!cyberimp_detect ? "[cyberimp.examine_title(user)]" : ", [cyberimp.examine_title(user)]"]"
		if(cyberimp_detect)
			render_list += "<span class='notice ml-1'>Detected cybernetic modifications:</span>\n"
			render_list += "<span class='notice ml-2'>[cyberimp_detect]</span>\n"
	// We handled the last <br> so we don't need handholding

	SEND_SIGNAL(target, COMSIG_NANITE_SCAN, user, FALSE)
	if(tochat)
		to_chat(user, examine_block(jointext(render_list, "")), trailing_newline = FALSE, type = MESSAGE_TYPE_INFO)
	else
		return(jointext(render_list, ""))

/proc/chemscan(mob/living/user, mob/living/target)
	if(user.incapacitated())
		return

	if(istype(target) && target.reagents)
		var/list/render_list = list() //The master list of readouts, including reagents in the blood/stomach, addictions, quirks, etc.
		var/list/render_block = list() //A second block of readout strings. If this ends up empty after checking stomach/blood contents, we give the "empty" header.

		// Blood reagents
		if(target.reagents.reagent_list.len)
			for(var/r in target.reagents.reagent_list)
				var/datum/reagent/reagent = r
				//if(reagent.chemical_flags & REAGENT_INVISIBLE) //Don't show hidden chems on scanners
				//	continue
				render_block += "<span class='notice ml-2'>[round(reagent.volume, 0.001)] units of [reagent.name][reagent.overdosed ? "</span> - [span_boldannounce("OVERDOSING")]" : ".</span>"]\n"

		if(!length(render_block)) //If no VISIBLY DISPLAYED reagents are present, we report as if there is nothing.
			render_list += "<span class='notice ml-1'>Subject contains no reagents in their blood.</span>\n"
		else
			render_list += "<span class='notice ml-1'>Subject contains the following reagents in their blood:</span>\n"
			render_list += render_block //Otherwise, we add the header, reagent readouts, and clear the readout block for use on the stomach.
			render_block.Cut()

		// Stomach reagents
		/*
		var/obj/item/organ/stomach/belly = target.get_organ_slot(ORGAN_SLOT_STOMACH)
		if(belly)
			if(belly.reagents.reagent_list.len)
				for(var/bile in belly.reagents.reagent_list)
					var/datum/reagent/bit = bile
					if(bit.chemical_flags & REAGENT_INVISIBLE)
						continue
					if(!belly.food_reagents[bit.type])
						render_block += "<span class='notice ml-2'>[round(bit.volume, 0.001)] units of [bit.name][bit.overdosed ? "</span> - [span_boldannounce("OVERDOSING")]" : ".</span>"]\n"
					else
						var/bit_vol = bit.volume - belly.food_reagents[bit.type]
						if(bit_vol > 0)
							render_block += "<span class='notice ml-2'>[round(bit_vol, 0.001)] units of [bit.name][bit.overdosed ? "</span> - [span_boldannounce("OVERDOSING")]" : ".</span>"]\n"

			if(!length(render_block))
				render_list += "<span class='notice ml-1'>Subject contains no reagents in their stomach.</span>\n"
			else
				render_list += "<span class='notice ml-1'>Subject contains the following reagents in their stomach:</span>\n"
				render_list += render_block
		*/

		// Addictions
		if(LAZYLEN(target.mind?.active_addictions))
			render_list += "<span class='boldannounce ml-1'>Subject is addicted to the following types of drug:</span><br>"
			for(var/datum/addiction/addiction_type as anything in target.mind.active_addictions)
				render_list += "<span class='alert ml-2'>[initial(addiction_type.name)]</span><br>"

		// we handled the last <br> so we don't need handholding
		to_chat(user, examine_block(jointext(render_list, "")), trailing_newline = FALSE, type = MESSAGE_TYPE_INFO)

/**
 * Scans an atom, showing any (detectable) diseases they may have.
 */
/proc/virusscan(mob/user, atom/target, maximum_stealth, maximum, list/extracted_ids)
	. = TRUE
	var/list/result = target?.extrapolator_act(user, target)
	var/list/diseases = result[EXTRAPOLATOR_RESULT_DISEASES]
	if(!length(diseases))
		return FALSE
	if(EXTRAPOLATOR_ACT_CHECK(result, EXTRAPOLATOR_ACT_PRIORITY_SPECIAL))
		return
	var/list/message = list()
	if(length(diseases))
		// costly_icon2html should be okay, as the extrapolator has a cooldown and is NOT spammable
		message += span_noticebold("[costly_icon2html(target, user)] [target] scan results]")
		for(var/datum/disease/disease in diseases)
			if(istype(disease, /datum/disease/advance))
				var/datum/disease/advance/advance_disease = disease
				if(advance_disease.stealth >= maximum_stealth) //the extrapolator can detect diseases of higher stealth than a normal scanner
					continue
				var/list/properties
				if(!advance_disease.mutable)
					LAZYADD(properties, "immutable")
				if(advance_disease.faltered)
					LAZYADD(properties, "faltered")
				if(advance_disease.carrier)
					LAZYADD(properties, "carrier")
				message += span_info("<b>[advance_disease.name]</b>[LAZYLEN(properties) ? " ([properties.Join(", ")])" : ""], [advance_disease.dormant ? "<i>dormant virus</i>" : "stage [advance_disease.stage]/5"]")
				if(extracted_ids[advance_disease.GetDiseaseID()])
					message += span_infoitalics("This virus has been extracted previously.")
				message += span_infobold("[advance_disease.name] has the following symptoms:")
				for(var/datum/symptom/symptom in advance_disease.symptoms)
					message += "[symptom.name]"
			else
				message += span_info("<b>[disease.name]</b>, stage [disease.stage]/[disease.max_stages].")
	to_chat(user, examine_block(jointext(message, "\n")), avoid_highlighting = TRUE, trailing_newline = FALSE, type = MESSAGE_TYPE_INFO)

/proc/genescan(mob/living/carbon/C, mob/user, list/discovered)
	. = TRUE
	if(!iscarbon(C) || !C.has_dna())
		return FALSE
	if(HAS_TRAIT(C, TRAIT_RADIMMUNE) || HAS_TRAIT(C, TRAIT_BADDNA))
		return FALSE
	var/list/message = list()
	var/list/active_inherent_muts = list()
	var/list/active_injected_muts = list()
	var/list/inherent_muts = list()
	var/list/mut_index = C.dna.mutation_index.Copy()

	for(var/datum/mutation/each in C.dna.mutations)
		//get name and alias if discovered (or no discovered list was provided) or just alias if not
		var/datum/mutation/each_mutation = GET_INITIALIZED_MUTATION(each.type) //have to do this as instances of mutation do not have alias but global ones do....
		var/each_mut_details = "ERROR"
		if(!discovered || (each_mutation.type in discovered))
			each_mut_details = span_info("[each_mutation.name] ([each_mutation.alias])")
		else
			each_mut_details = span_info("[each_mutation.alias]")

		if(each_mutation.type in mut_index)
			//add mutation readout for all active inherent mutations
			active_inherent_muts += "[each_mut_details][span_infobold(" : Active ")]"
			mut_index -= each_mutation.type
		else
			//add mutation readout for all injected (not inherent) mutations
			active_injected_muts += each_mut_details

	for(var/each in mut_index)
		var/datum/mutation/each_mutation = GET_INITIALIZED_MUTATION(each)
		var/each_mut_details = "ERROR"
		if(each_mutation)
			//repeating this code twice is nasty, but nested procs (if even possible??) or more global procs then needed is... less so
			if(!discovered || (each_mutation.type in discovered))
				each_mut_details = span_info("[each_mutation.name] ([each_mutation.alias])")
			else
				each_mut_details = span_info("[each_mutation.alias]")
		inherent_muts += each_mut_details

	message += span_noticebold("[C] scan results")
	active_inherent_muts.len > 0 ? (message += "[jointext(active_inherent_muts, "\n")]") : ""
	inherent_muts.len > 0 ? (message += "[jointext(inherent_muts, "\n")]") : ""
	active_injected_muts.len > 0 ? (message += "[span_infobold("Injected mutations:\n")][jointext(active_injected_muts, "\n")]") : ""

	to_chat(user, examine_block(jointext(message, "\n")), avoid_highlighting = TRUE, trailing_newline = FALSE, type = MESSAGE_TYPE_INFO)

/obj/item/healthanalyzer/advanced
	name = "advanced health analyzer"
	icon_state = "health_adv"
	desc = "A hand-held body scanner able to distinguish vital signs of the subject with high accuracy."
	advanced = TRUE

#undef SCANNER_CONDENSED
#undef SCANNER_VERBOSE
