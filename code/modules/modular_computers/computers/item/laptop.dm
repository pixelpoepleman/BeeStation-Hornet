/obj/item/modular_computer/laptop
	name = "laptop"
	desc = "A portable laptop computer."
	icon = 'icons/obj/modular_laptop.dmi'
	icon_state = "laptop-closed"
	icon_state_menu = "menu"
	max_hardware_size = WEIGHT_CLASS_NORMAL
	w_class = WEIGHT_CLASS_NORMAL
	max_bays = 4
	can_save_id = TRUE
	custom_price = PAYCHECK_MEDIUM * 3

	// No running around with open laptops in hands.
	item_flags = SLOWS_WHILE_IN_HAND

	screen_on = 0 		// Starts closed
	var/start_open = FALSE	// unless this var is set to 1
	var/w_class_open = WEIGHT_CLASS_BULKY
	var/slowdown_open = TRUE

/obj/item/modular_computer/laptop/examine(mob/user)
	. = ..()
	if(screen_on)
		. += span_notice("Alt-click to close it.")

/obj/item/modular_computer/laptop/ui_static_data(mob/user)	// This ensures players are able to imprint ID. Necessary before Laptops become a subtype of tablet.
	var/list/data = ..()
	data["show_imprint"] = TRUE
	return data

/obj/item/modular_computer/laptop/Initialize(mapload)
	. = ..()

	if(start_open && !screen_on)
		toggle_open()

/obj/item/modular_computer/laptop/update_icon_state()
	. = ..()
	if(screen_on)
		icon_state = "laptop"
	else
		icon_state = "laptop-closed"

/obj/item/modular_computer/laptop/attack_self(mob/user)
	if(!screen_on)
		try_toggle_open(user)
	else
		return ..()

/obj/item/modular_computer/laptop/verb/open_computer()
	set name = "Toggle Open"
	set category = "Object"
	set src in view(1)

	try_toggle_open(usr)

/obj/item/modular_computer/laptop/MouseDrop(obj/over_object, src_location, over_location)
	. = ..()
	if(over_object == usr || over_object == src)
		try_toggle_open(usr)
		return
	if(istype(over_object, /atom/movable/screen/inventory/hand))
		var/atom/movable/screen/inventory/hand/H = over_object
		var/mob/M = usr

		if(M.stat != CONSCIOUS || HAS_TRAIT(M, TRAIT_HANDS_BLOCKED))
			return
		if(!isturf(loc) || !Adjacent(M))
			return
		M.put_in_hand(src, H.held_index)

/obj/item/modular_computer/laptop/attack_hand(mob/user, list/modifiers)
	. = ..()
	if(.)
		return
	if(screen_on && isturf(loc))
		return attack_self(user)

/obj/item/modular_computer/laptop/proc/try_toggle_open(mob/living/user)
	if(issilicon(user))
		return
	if(!isturf(loc) && !ismob(loc)) // No opening it in backpack.
		return
	if(!user.canUseTopic(src, BE_CLOSE))
		return

	toggle_open(user)


/obj/item/modular_computer/laptop/AltClick(mob/user)
	if(screen_on) // Close it.
		try_toggle_open(user)
	else
		..()

/obj/item/modular_computer/laptop/proc/toggle_open(mob/living/user)
	if(screen_on)
		to_chat(user, span_notice("You close \the [src]."))
		slowdown = initial(slowdown)
		w_class = initial(w_class)
	else
		to_chat(user, span_notice("You open \the [src]."))
		slowdown = slowdown_open
		w_class = w_class_open
	screen_on = !screen_on
	update_appearance()
