/obj/machinery/modular_computer/console/preset/card
	name = "identification console"
	desc = "You can use this to manage jobs and ID access."
	_has_second_id_slot = TRUE
	_has_printer = TRUE

/obj/machinery/modular_computer/console/preset/card/install_programs()
	var/obj/item/computer_hardware/hard_drive/hard_drive = cpu.all_components[MC_HDD]
	hard_drive.store_file(new/datum/computer_file/program/chatclient())
	hard_drive.store_file(new/datum/computer_file/program/card_mod())
