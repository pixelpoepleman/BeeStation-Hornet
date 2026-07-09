/// Slag used by salvaging. Contains the materials of whatever was melted from salvaging.

/obj/item/slag
	name = "slag"
	desc = "Almost completely useless."
	icon = 'icons/obj/stacks/minerals.dmi'
	icon_state = "slag"
	inhand_icon_state = "slag"


	force = 5 //In case you want to bludgeon someone with a piece of slag
	throwforce = 10 //Public stonings should be more common

/// This will store recovered material later
/obj/item/slag/Initialize()
	. = ..()
	custom_materials = list()
