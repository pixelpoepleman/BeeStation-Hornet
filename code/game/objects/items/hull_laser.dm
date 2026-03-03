/*
CONTAINS:
H3L
MHL
*/

/obj/item/salvaging
	name = "You shouldn't be seeing this"
	desc = "Not for ingame use"
	var/datum/effect_system/spark_spread/spark_system
	var/obj/item/stock_parts/cell/cell
	var/cell_type = /obj/item/stock_parts/cell/high/plus
	var/cell_cover_open = FALSE /// Status of the cell cover on the laser


	///var/has_ammobar = FALSE	//controls whether or not does update_icon apply ammo indicator overlays
	///var/ammo_sections = 10	//amount of divisions in the ammo indicator overlay/number of ammo indicator states
	var/upgrade = NONE 	/// Bitflags for upgrades
	var/banned_upgrades = NONE 	/// Bitflags for banned upgrades
	var/mode = RCD_DECONSTRUCT /// Here to reuse RCD code to allow us to pull values for if things can be RCD'd, and similarly slagged by the laser
	var/canRturf = TRUE	/// Similar to above, except for if we can Rturf things with the laser

/obj/item/salvaging/handheld_hull_laser
	name = "Handheld Hull Laser"
	desc = "A large hand-held ultra-violet laser used for salvaging hulls of vessels."
	icon = 'icons/obj/tools.dmi'
	icon_state = "inducer-engi"
	lefthand_file = 'icons/mob/inhands/equipment/tools_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/equipment/tools_righthand.dmi'
	///item_flags = NOBLUDGEON
	force = 10
	throwforce = 10
	throw_speed = 3
	throw_range = 5
	w_class = WEIGHT_CLASS_LARGE
	custom_materials = list(/datum/material/iron=100000)
	resistance_flags = FIRE_PROOF


/obj/item/salvaging/get_cell()
	return cell

/// Handles EMP on the laser
/obj/item/salvaging/emp_act(severity)
	. = ..()
	if(cell && !(. & EMP_PROTECT_CONTENTS))
		cell.emp_act(severity)

/// Open the cell cover when ALT+Click on the laser
/obj/item/salvaging/AltClick(mob/living/user)
	if(!user.canUseTopic(src, BE_CLOSE, NO_DEXTERITY, FALSE, !iscyborg(user)))
		return ..()
	toggle_laser_cell(user)

/// Toggle the laser's cell cover
/obj/item/salvaging/proc/toggle_laser_cell(mob/user)
	cell_cover_open = !cell_cover_open
	to_chat(user, span_notice("You [cell_cover_open ? "open" : "close"] the cell cover on \the [src]."))
	update_icon()

/// Remove the cell when the cover is open on CTRL+Click
/obj/item/salvaging/CtrlClick(mob/living/user)
	if(user.canUseTopic(src, BE_CLOSE, NO_DEXTERITY, FALSE, !iscyborg(user)))
		if(cell_cover_open && cell)
			remove_cell(user)
			return
	return ..()

/// Remove the cell from the laser if the cell cover is open
/obj/item/salvaging/proc/remove_cell(mob/user)
	if(cell_cover_open && cell)
		user.visible_message(span_notice("[user] removes \the [cell] from [src]!"), span_notice("You remove [cell]."))
		update_icon()
		cell.add_fingerprint(user)
		user.put_in_hands(cell)
		cell = null

/// Handles cell insertion if cover is open
/obj/item/salvaging/attackby(obj/item/I, mob/user, params)
	// if(istype(W, /obj/item/rcd_upgrade))
	// 	install_upgrade(W, user)
	// 	return TRUE
	if(istype(I, /obj/item/stock_parts/cell))
		if(cell_cover_open)
			if(!cell)
				to_chat(user, span_notice("You insert [I] into [src]."))
				cell = I
				I.forceMove(src)
				update_icon()
				return
			else
				to_chat(user, span_notice("[src] already has \a [cell] installed!"))
				return
	return ..()

/obj/item/salvaging/Initialize(mapload)
	. = ..()

	if(!cell && cell_type)
		cell = new cell_type(src)

	update_icon()

/// fuckass icon updates that I dont understand
/obj/item/salvaging/update_icon()
	. = ..()

/obj/item/salvaging/update_overlays()
	. = ..()
	if(cell_cover_open)
		if(!cell)
			. += "inducer-nobat"
		else
			. += "inducer-bat"

/obj/item/salvaging/afterattack(atom/target, mob/living/user, proximity)
	. = ..()
	if(!ISADVANCEDTOOLUSER(user))
		to_chat(user, span_warning("You don't have the dexterity to use [src]!"))
		return TRUE

	if(!cell)
		to_chat(user, span_warning("[src] doesn't have a power cell installed!"))
		return TRUE

	if(!target.salvage_vals(src)) /// The real important check for if we can melt the target
		to_chat(user, span_warning("The [target] isn't a valid target for the [src]!"))
		return
	var/list/salvage_results = target.salvage_vals(src)

	if(cell.charge < salvage_results["power"])
		to_chat(user, span_warning("The cell has insufficient charge."))
		return

	var/delay = salvage_results["delay"]
	var/power_cost = salvage_results["power"]
	to_chat(user, span_notice("You begin melting through [target]..."))

	if(!do_after(user, delay, target = target))
		return

	cell.use(power_cost)
	target.salvage_act(user,src)
