/datum/unit_test/emoting
	var/emotes_used = 0

/datum/unit_test/emoting/Run()
	var/mob/living/carbon/human/human = allocate(/mob/living/carbon/human/consistent)
	human.key = "EmoteTestKey"
	RegisterSignal(human, COMSIG_MOB_EMOTE, PROC_REF(on_emote_used))

	emotes_used = 0
	human.say("*shrug")
	TEST_ASSERT_EQUAL(emotes_used, 1, "Human did not shrug")

	emotes_used = 0
	human.say("*beep")
	TEST_ASSERT_EQUAL(emotes_used, 0, "Human beeped, when that should be restricted to silicons")

	human.setOxyLoss(140)

	TEST_ASSERT(human.stat != CONSCIOUS, "Human is somehow conscious after receiving suffocation damage")

	emotes_used = 0
	human.say("*shrug")
	TEST_ASSERT_EQUAL(emotes_used, 0, "Human shrugged while unconscious")

	human.key = null

/datum/unit_test/emoting/proc/on_emote_used()
	SIGNAL_HANDLER
	emotes_used += 1
