/datum/computer_file/program/log_viewer
	filename = "ore_log_viewer"
	filedesc = "Ore Silo Log Viewer"
	category = PROGRAM_CATEGORY_MISC
	program_icon_state = "comm_logs"
	extended_desc = "View ore silo logs via NTNet or saved to your system."
	size = 4
	tgui_id = "NtosLogViewer"
	program_icon = "database"

/datum/computer_file/program/log_viewer/ui_act(action, list/params, datum/tgui/ui)
	. = ..()
	if(.)
		return

	switch(action)
		if("DownloadRemote")
			if(!istype(computer))
				return
			if(!check_remote())
				computer.visible_message(span_warning("\The [computer] shows an \"Connection Error - Remote log server connection timeout\" warning."))
				return
			var/obj/item/computer_hardware/hard_drive/hard_drive = computer.all_components[MC_HDD]
			if(!hard_drive)
				computer.visible_message(span_warning("\The [computer] shows an \"I/O Error - Hard drive connection error\" warning."))
				return
			var/datum/computer_file/data/text/log_file/log
			switch(params["name"])
				if("ore_silo")
					var/obj/item/computer_hardware/hard_drive/role/job_disk = computer.all_components[MC_HDD_JOB]
					if(!istype(job_disk) || !(job_disk.disk_flags & DISK_SILO_LOG) || !GLOB.ore_silo_default)
						computer.visible_message(span_warning("\The [computer] shows an \"Access Error - Remote log server refused connection\" warning."))
						return
					log = new()
					log.set_stored_data(get_silo_log())
			if(!log)
				return
			var/filename = check_filename(stripped_input(usr, "Enter a name for the file", "File Name Entry", "", 16))
			if(!filename)
				return
			log.filename = filename
			if(!hard_drive.store_file(log))
				computer.visible_message(span_warning("\The [computer] shows an \"I/O Error - Hard drive may be full. Please free some space and try again. Required space: [log.size]GQ\" warning."))
				return
			return TRUE
		if("EditInNotepad")
			var/data = params["data"]
			if(!istype(computer))
				return
			var/obj/item/computer_hardware/hard_drive/hard_drive = computer.all_components[MC_HDD]
			var/obj/item/computer_hardware/hard_drive/role/ssd = computer.all_components[MC_HDD_JOB]
			var/datum/computer_file/program/notepad/notepad

			// Find the notepad program in the drive
			if(hard_drive)
				notepad = hard_drive.find_file_by_name("notepad")
			if(ssd && !notepad)
				notepad = ssd.find_file_by_name("notepad")

			if(!notepad || !istype(notepad))
				to_chat(usr, span_danger("\The [computer]'s screen shows \"I/O ERROR - Notepad not found.\""))
				return
			notepad.set_note(data)
			notepad.computer = computer
			computer.open_program(usr, notepad)
			return TRUE

/datum/computer_file/program/log_viewer/ui_data(mob/user)
	var/list/data = list()
	if(!istype(computer))
		return data
	var/list/datum/computer_file/data/text/log_file/data_files = list()
	var/obj/item/computer_hardware/hard_drive/hard_drive = computer.all_components[MC_HDD]
	var/obj/item/computer_hardware/hard_drive/ssd = computer.all_components[MC_SDD]
	if(hard_drive)
		for(var/datum/computer_file/data/text/log_file/file in hard_drive.stored_files)
			data_files += file
	if(ssd)
		for(var/datum/computer_file/data/text/log_file/file in ssd.stored_files)
			data_files += file
	var/files = list()
	for(var/datum/computer_file/data/text/log_file/file in data_files)
		files += list(list(
			name = file.filename,
			size = file.size,
			data = file.stored_data,
		))
	var/online = check_remote()
	var/obj/item/computer_hardware/hard_drive/role/job_disk = computer.all_components[MC_HDD_JOB]
	if(GLOB.ore_silo_default && istype(job_disk) && (job_disk.disk_flags & DISK_SILO_LOG))
		var/silo_log
		if(online)
			silo_log = get_silo_log()
		files += list(
			list(
				name = "ore_silo",
				remote = TRUE,
				data = silo_log,
				online = online,
			)
		)
	data["files"] = files

	return data

/datum/computer_file/program/log_viewer/proc/get_silo_log()
	if(!GLOB.ore_silo_default)
		return ""
	var/list/silo_logs = GLOB.silo_access_logs[REF(GLOB.ore_silo_default)]
	var/silo_log = ""
	for(var/i in length(silo_logs) to 1 step -1)
		var/datum/ore_silo_log/entry = silo_logs[i]
		// strip_html_simple would be great, if it actually removed the stuff between <>. smh
		silo_log += replacetext(replacetext(replacetext("[entry.formatted]\n", "<br>", "\n"), "<b>", ""), "</b>", "")
	return silo_log

/datum/computer_file/program/log_viewer/proc/check_remote()
	return computer.get_ntnet_status(NTNET_COMMUNICATION)
