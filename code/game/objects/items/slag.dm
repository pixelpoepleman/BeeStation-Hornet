/// Slag used by salvaging. Contains the materials of whatever was melted from salvaging.

/obj/item/slag
	name = "slag"
	desc = "Almost completely useless."
	icon = 'icons/obj/stacks/minerals.dmi'
	icon_state = "slag"
	inhand_icon_state = "slag"

	/// This will store recovered material later

/obj/item/slag/Initialize()
	. = ..()
	custom_materials = list()

/obj/item/slag/proc/load_materials(list/materials)
	if(!materials)
		return

	custom_materials = list()

	/// Basically just copies the materials that are passed in into the slag.
	for(var/M in materials)
		custom_materials[M] = materials[M]
	return
