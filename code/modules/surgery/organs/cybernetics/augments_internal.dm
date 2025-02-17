

//[[[[BRAIN]]]]

/obj/item/organ/cyberimp/brain
	name = "cybernetic brain implant"
	desc = "Injectors of extra sub-routines for the brain."
	icon_state = "brain_implant"
	implant_overlay = "brain_implant_overlay"
	zone = BODY_ZONE_HEAD
	w_class = WEIGHT_CLASS_TINY

/obj/item/organ/cyberimp/brain/emp_act(severity)
	. = ..()
	if(!owner || . & EMP_PROTECT_SELF)
		return
	var/stun_amount = 200/severity
	owner.Stun(stun_amount)
	to_chat(owner, span_warning("Your body seizes up!"))


/obj/item/organ/cyberimp/brain/anti_drop
	name = "anti-drop implant"
	desc = "This cybernetic brain implant will allow you to force your hand muscles to contract, preventing item dropping. Twitch ear to toggle."
	var/active = 0
	var/list/stored_items = list()
	implant_color = "#DE7E00"
	slot = ORGAN_SLOT_BRAIN_ANTIDROP
	encode_info = AUGMENT_NO_REQ
	actions_types = list(/datum/action/item_action/organ_action/toggle)

/obj/item/organ/cyberimp/brain/anti_drop/ui_action_click()
	if(!check_compatibility())
		to_chat(owner, "<span class='warning'>The Neuralink beeps: ERR01 INCOMPATIBLE IMPLANT</span>")
		return

	active = !active
	if(active)
		for(var/obj/item/I in owner.held_items)
			stored_items += I

		var/list/hold_list = owner.get_empty_held_indexes()
		if(LAZYLEN(hold_list) == owner.held_items.len)
			to_chat(owner, span_notice("You are not holding any items, your hands relax..."))
			active = FALSE
			stored_items = list()
		else
			for(var/obj/item/stored_item in stored_items)
				to_chat(owner, span_notice("Your [owner.get_held_index_name(owner.get_held_index_of_item(stored_item))]'s grip tightens."))
				ADD_TRAIT(stored_item, TRAIT_NODROP, IMPLANT_TRAIT)

	else
		release_items()
		to_chat(owner, span_notice("Your hands relax..."))


/obj/item/organ/cyberimp/brain/anti_drop/emp_act(severity)
	. = ..()
	if(!owner || . & EMP_PROTECT_SELF)
		return
	var/range = severity ? 10 : 5
	if(active)
		release_items()
	for(var/obj/item/stored_item in stored_items)
		var/throw_target = pick(oview(range))
		stored_item.throw_at(throw_target, range, 2)
		to_chat(owner, span_warning("Your [owner.get_held_index_name(owner.get_held_index_of_item(stored_item))] spasms and throws the [stored_item.name]!"))
	stored_items = list()


/obj/item/organ/cyberimp/brain/anti_drop/proc/release_items()
	for(var/obj/item/I in stored_items)
		REMOVE_TRAIT(I, TRAIT_NODROP, ANTI_DROP_IMPLANT_TRAIT)
	stored_items = list()


/obj/item/organ/cyberimp/brain/anti_drop/Remove(mob/living/carbon/M, special = 0)
	if(active)
		ui_action_click()
	..()

/obj/item/organ/cyberimp/brain/anti_stun
	name = "CNS Rebooter implant"
	desc = "This implant will automatically give you back control over your central nervous system, reducing downtime when stunned."
	implant_color = "#FFFF00"
	slot = ORGAN_SLOT_BRAIN_ANTISTUN
	encode_info = AUGMENT_NO_REQ

	var/static/list/signalCache = list(
		COMSIG_LIVING_STATUS_STUN,
		COMSIG_LIVING_STATUS_KNOCKDOWN,
		COMSIG_LIVING_STATUS_IMMOBILIZE,
		COMSIG_LIVING_STATUS_PARALYZE,
	)

	var/stun_cap_amount = 40

/obj/item/organ/cyberimp/brain/anti_stun/Remove(mob/living/carbon/M, special = FALSE)
	. = ..()
	UnregisterSignal(M, signalCache)

/obj/item/organ/cyberimp/brain/anti_stun/Insert()
	. = ..()
	RegisterSignal(owner, signalCache, .proc/on_signal)

/obj/item/organ/cyberimp/brain/anti_stun/proc/on_signal(datum/source, amount)
	if(!check_compatibility())
		to_chat(owner, "<span class='warning'>The Neuralink beeps: ERR01 INCOMPATIBLE IMPLANT</span>")
		return
	if(!(organ_flags & ORGAN_FAILING) && amount > 0)
		addtimer(CALLBACK(src, .proc/clear_stuns), stun_cap_amount, TIMER_UNIQUE|TIMER_OVERRIDE)

/obj/item/organ/cyberimp/brain/anti_stun/proc/clear_stuns()
	if(owner || !(organ_flags & ORGAN_FAILING))
		owner.SetStun(0)
		owner.SetKnockdown(0)
		owner.SetImmobilized(0)
		owner.SetParalyzed(0)

/obj/item/organ/cyberimp/brain/anti_stun/emp_act(severity)
	. = ..()
	if((organ_flags & ORGAN_FAILING) || . & EMP_PROTECT_SELF)
		return
	organ_flags |= ORGAN_FAILING
	addtimer(CALLBACK(src, .proc/reboot), 90 / severity)

/obj/item/organ/cyberimp/brain/anti_stun/proc/reboot()
	organ_flags &= ~ORGAN_FAILING

/obj/item/organ/cyberimp/brain/anti_stun/syndicate
	encode_info = AUGMENT_NO_REQ

//[[[[MOUTH]]]]
/obj/item/organ/cyberimp/mouth
	zone = BODY_ZONE_PRECISE_MOUTH

/obj/item/organ/cyberimp/mouth/breathing_tube
	name = "breathing tube implant"
	desc = "This simple implant adds an internals connector to your back, allowing you to use internals without a mask and protecting you from being choked."
	icon_state = "implant_mask"
	slot = ORGAN_SLOT_BREATHING_TUBE
	w_class = WEIGHT_CLASS_TINY

/obj/item/organ/cyberimp/mouth/breathing_tube/emp_act(severity)
	. = ..()
	if(!owner || . & EMP_PROTECT_SELF)
		return
	if(prob(60/severity))
		to_chat(owner, span_warning("Your breathing tube suddenly closes!"))
		owner.losebreath += 2

//BOX O' IMPLANTS

/obj/item/storage/box/cyber_implants
	name = "boxed cybernetic implants"
	desc = "A sleek, sturdy box."
	icon_state = "cyber_implants"
	var/list/boxed = list(
		/obj/item/autosurgeon/organ/syndicate/thermal_eyes,
		/obj/item/autosurgeon/organ/syndicate/xray_eyes,
		/obj/item/autosurgeon/organ/syndicate/anti_stun,
		/obj/item/autosurgeon/organ/syndicate/reviver,
		/obj/item/autosurgeon/organ/syndicate/ammo_counter,
		/obj/item/autosurgeon/organ/syndicate/esword,
		/obj/item/autosurgeon/organ/syndicate/syndie_mantis
		)
	var/amount = 5

/obj/item/storage/box/cyber_implants/PopulateContents()
	new /obj/item/autosurgeon/organ/cyberlink_syndicate(src)
	var/implant
	while(contents.len <= amount)
		implant = pick(boxed)
		new implant(src)
