/obj/machinery/computer/prisoner/management
	name = "prisoner management console"
	desc = "Used to manage tracking implants placed inside criminals."
	icon_screen = "explosive"
	icon_keyboard = "security_key"
	req_access = list(ACCESS_BRIG)
	var/id = 0
	var/temp = null
	var/status = 0
	var/timeleft = 60
	var/stop = 0
	var/screen = 0 // 0 - No Access Denied, 1 - Access allowed
	circuit = /obj/item/circuitboard/computer/prisoner

	light_color = LIGHT_COLOR_RED

/obj/machinery/computer/prisoner/management/ui_interact(mob/user)
	. = ..()
	if(isliving(user))
		playsound(src, 'sound/machines/terminal_prompt_confirm.ogg', 50, FALSE)
	var/dat = ""
	if(screen == 0)
		dat += "<HR><A href='byond://?src=[REF(src)];lock=1'>{Log In}</A>"
	else if(screen == 1)
		dat += "<H3>Prisoner ID Management</H3>"
		if(contained_id)
			dat += "<A href='byond://?src=[REF(src)];id=eject'>[contained_id]</A><br>"
			dat += "Collected Points: [contained_id.points]. <A href='byond://?src=[REF(src)];id=reset'>Reset.</A><br>"
			dat += "Card goal: [contained_id.goal].  <A href='byond://?src=[REF(src)];id=setgoal'>Set</A> <A href='byond://?src=[REF(src)];id=setpermanent'>Make [contained_id.permanent ? "temporary" : "permanent"].</A><br>"
			dat += "Space Law recommends quotas of 100 points per minute they would normally serve in the brig.<BR>"
		else
			dat += "<A href='byond://?src=[REF(src)];id=insert'>Insert Prisoner ID.</A><br>"
		dat += "<H3>Prisoner Implant Management</H3>"
		dat += "<HR>Chemical Implants<BR>"
		var/turf/Tr = null
		for(var/obj/item/implant/chem/C in GLOB.tracked_chem_implants)
			Tr = get_turf(C)
			if((Tr) && (Tr.get_virtual_z_level() != src.get_virtual_z_level()))
				continue//Out of range
			if(!C.imp_in)
				continue
			dat += "ID: [C.imp_in.name] | Remaining Units: [C.reagents.total_volume] <BR>"
			dat += "| Inject: "
			dat += "<A href='byond://?src=[REF(src)];inject1=[REF(C)]'>(<font class='bad'>(1)</font>)</A>"
			dat += "<A href='byond://?src=[REF(src)];inject5=[REF(C)]'>(<font class='bad'>(5)</font>)</A>"
			dat += "<A href='byond://?src=[REF(src)];inject10=[REF(C)]'>(<font class='bad'>(10)</font>)</A><BR>"
			dat += "********************************<BR>"
		dat += "<HR>Tracking Implants<BR>"
		for(var/obj/item/implant/tracking/T in GLOB.tracked_implants)
			if(!isliving(T.imp_in))
				continue
			Tr = get_turf(T)
			if((Tr) && (Tr.get_virtual_z_level() != src.get_virtual_z_level()))
				continue//Out of range

			var/loc_display = "Unknown"
			var/mob/living/M = T.imp_in
			if(is_station_level(Tr.z) && !isspaceturf(M.loc))
				var/turf/mob_loc = get_turf(M)
				loc_display = mob_loc.loc

			dat += "ID: [T.imp_in.name] | Location: [loc_display]<BR>"
			dat += "<A href='byond://?src=[REF(src)];warn=[REF(T)]'>(<font class='bad'><i>Send Message</i></font>)</A><BR>"
		dat += "<HR><A href='byond://?src=[REF(src)];lock=1'>{Log Out}</A>"
	var/datum/browser/popup = new(user, "computer", "Prisoner Management Console", 400, 500)
	popup.set_content(dat)
	popup.open()
	return

/obj/machinery/computer/prisoner/management/attackby(obj/item/I, mob/user, params)
	if(istype(I, /obj/item/card/id))
		if(screen)
			id_insert(user)
		else
			to_chat(user, span_danger("Unauthorized access."))
	else
		return ..()

/obj/machinery/computer/prisoner/management/process()
	if(!..())
		src.updateDialog()
	return

/obj/machinery/computer/prisoner/management/Topic(href, href_list)
	if(..())
		return
	if(usr.contents.Find(src) || (in_range(src, usr) && isturf(loc)) || issilicon(usr))
		usr.set_machine(src)

		if(href_list["id"])
			if(href_list["id"] =="insert" && !contained_id)
				id_insert(usr)
			else if(contained_id)
				switch(href_list["id"])
					if("eject")
						id_eject(usr)
					if("reset")
						contained_id.points = 0
					if("setgoal")
						var/num = round(tgui_input_number(usr, "Choose prisoner's goal:", "Input an number.", 0, 1500, 0))
						contained_id.goal = num
					if("setpermanent")
						contained_id.permanent = !contained_id.permanent
		else if(href_list["inject1"])
			var/obj/item/implant/I = locate(href_list["inject1"]) in GLOB.tracked_chem_implants
			if(I && istype(I))
				I.activate(1)
		else if(href_list["inject5"])
			var/obj/item/implant/I = locate(href_list["inject5"]) in GLOB.tracked_chem_implants
			if(I && istype(I))
				I.activate(5)
		else if(href_list["inject10"])
			var/obj/item/implant/I = locate(href_list["inject10"]) in GLOB.tracked_chem_implants
			if(I && istype(I))
				I.activate(10)

		else if(href_list["lock"])
			if(allowed(usr))
				screen = !screen
				playsound(src, 'sound/machines/terminal_on.ogg', 50, FALSE)
			else
				to_chat(usr, span_danger("Unauthorized access."))

		else if(href_list["warn"])
			var/warning = tgui_input_text(usr, "Message:", "Enter your message here!", "")
			if(!warning)
				return
			if(CHAT_FILTER_CHECK(warning))
				to_chat(usr, span_warning("Your message contains forbidden words."))
				return
			warning = usr.treat_message_min(warning)
			var/obj/item/implant/I = locate(href_list["warn"]) in GLOB.tracked_implants
			if(I && istype(I) && I.imp_in)
				var/mob/living/R = I.imp_in
				to_chat(R, span_hear("You hear a voice in your head saying: '[warning]'"))
				log_directed_talk(usr, R, warning, LOG_SAY, "implant message")

		src.add_fingerprint(usr)
	src.updateUsrDialog()
	return
