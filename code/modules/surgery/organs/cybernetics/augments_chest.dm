/obj/item/organ/cyberimp/chest
	name = "cybernetic torso implant"
	desc = "Implants for the organs in your torso."
	icon_state = "chest_implant"
	implant_overlay = "chest_implant_overlay"
	zone = BODY_ZONE_CHEST

/obj/item/organ/cyberimp/chest/nutriment
	name = "Nutriment pump implant"
	desc = "This implant will synthesize and pump into your bloodstream a small amount of nutriment when you are starving."
	icon_state = "chest_implant"
	implant_color = "#00AA00"
	encode_info = AUGMENT_NO_REQ
	var/hunger_threshold = NUTRITION_LEVEL_STARVING
	var/synthesizing = 0
	var/poison_amount = 5
	slot = ORGAN_SLOT_STOMACH_AID

/obj/item/organ/cyberimp/chest/nutriment/on_life(delta_time)
	if(!check_compatibility())
		return

	if(synthesizing)
		return

	if(owner.nutrition <= hunger_threshold)
		synthesizing = TRUE
		to_chat(owner, span_notice("You feel less hungry..."))
		owner.adjust_nutrition(25 * delta_time)
		addtimer(CALLBACK(src, .proc/synth_cool), 50)

/obj/item/organ/cyberimp/chest/nutriment/proc/synth_cool()
	synthesizing = FALSE

/obj/item/organ/cyberimp/chest/nutriment/emp_act(severity)
	. = ..()
	if(!owner || . & EMP_PROTECT_SELF)
		return
	owner.reagents.add_reagent(/datum/reagent/toxin/bad_food, poison_amount / severity)
	to_chat(owner, span_warning("You feel like your insides are burning."))


/obj/item/organ/cyberimp/chest/nutriment/plus
	name = "Nutriment pump implant PLUS"
	desc = "This implant will synthesize and pump into your bloodstream a small amount of nutriment when you are hungry."
	icon_state = "chest_implant"
	implant_color = "#006607"
	hunger_threshold = NUTRITION_LEVEL_HUNGRY
	encode_info = AUGMENT_NO_REQ
	poison_amount = 10

/obj/item/organ/cyberimp/chest/reviver
	name = "Reviver implant"
	desc = "This implant will attempt to revive and heal you if you lose consciousness. For the faint of heart!"
	icon_state = "chest_implant"
	implant_color = "#AD0000"
	slot = ORGAN_SLOT_HEART_AID
	encode_info = AUGMENT_NO_REQ
	var/revive_cost = 0
	var/reviving = FALSE
	COOLDOWN_DECLARE(reviver_cooldown)


/obj/item/organ/cyberimp/chest/reviver/on_life()
	if(!check_compatibility())
		return

	if(reviving)
		switch(owner.stat)
			if(UNCONSCIOUS, HARD_CRIT)
				addtimer(CALLBACK(src, .proc/heal), 3 SECONDS)
			else
				COOLDOWN_START(src, reviver_cooldown, revive_cost)
				reviving = FALSE
				to_chat(owner, span_notice("Your reviver implant shuts down and starts recharging. It will be ready again in [DisplayTimeText(revive_cost)]."))
		return

	if(!COOLDOWN_FINISHED(src, reviver_cooldown) || owner.suiciding)
		return

	switch(owner.stat)
		if(UNCONSCIOUS, HARD_CRIT)
			revive_cost = 0
			reviving = TRUE
			to_chat(owner, span_notice("You feel a faint buzzing as your reviver implant starts patching your wounds..."))


/obj/item/organ/cyberimp/chest/reviver/proc/heal()
	if(owner.getOxyLoss())
		owner.adjustOxyLoss(-5)
		revive_cost += 5
	if(owner.getBruteLoss())
		owner.adjustBruteLoss(-2)
		revive_cost += 40
	if(owner.getFireLoss())
		owner.adjustFireLoss(-2)
		revive_cost += 40
	if(owner.getToxLoss())
		owner.adjustToxLoss(-1)
		revive_cost += 40

/obj/item/organ/cyberimp/chest/reviver/emp_act(severity)
	. = ..()
	if(!owner || . & EMP_PROTECT_SELF)
		return

	if(reviving)
		revive_cost += 200
	else
		reviver_cooldown += 20 SECONDS

	if(ishuman(owner))
		var/mob/living/carbon/human/human_owner = owner
		if(human_owner.stat != DEAD && prob(50 / severity) && human_owner.can_heartattack())
			human_owner.set_heartattack(TRUE)
			to_chat(human_owner, span_userdanger("You feel a horrible agony in your chest!"))
			addtimer(CALLBACK(src, .proc/undo_heart_attack), 600 / severity)

/obj/item/organ/cyberimp/chest/reviver/proc/undo_heart_attack()
	var/mob/living/carbon/human/human_owner = owner
	if(!istype(human_owner))
		return
	human_owner.set_heartattack(FALSE)
	if(human_owner.stat == CONSCIOUS)
		to_chat(human_owner, span_notice("You feel your heart beating again!"))

/obj/item/organ/cyberimp/chest/reviver/syndicate
	encode_info = AUGMENT_NO_REQ

/obj/item/organ/cyberimp/chest/thrusters
	name = "implantable thrusters set"
	desc = "An implantable set of thruster ports. They use the gas from environment or subject's internals for propulsion in zero-gravity areas. \
	Unlike regular jetpacks, this device has no stabilization system."
	slot = ORGAN_SLOT_THRUSTERS
	icon_state = "imp_jetpack"
	implant_overlay = null
	implant_color = null
	actions_types = list(/datum/action/item_action/organ_action/toggle)
	w_class = WEIGHT_CLASS_NORMAL
	encode_info = AUGMENT_NO_REQ
	var/on = FALSE
	var/datum/effect_system/trail_follow/ion/ion_trail

/obj/item/organ/cyberimp/chest/thrusters/Insert(mob/living/carbon/thruster_owner, special = 0)
	. = ..()
	if(!ion_trail)
		ion_trail = new
		ion_trail.auto_process = FALSE
	ion_trail.set_up(thruster_owner)

/obj/item/organ/cyberimp/chest/thrusters/Remove(mob/living/carbon/thruster_owner, special = 0)
	if(on)
		toggle(silent = TRUE)
	..()

/obj/item/organ/cyberimp/chest/thrusters/ui_action_click()
	toggle()

/obj/item/organ/cyberimp/chest/thrusters/update_implants()
	. = ..()
	if(check_compatibility())
		return

	if(on)
		toggle(TRUE)

/obj/item/organ/cyberimp/chest/thrusters/proc/toggle(silent = FALSE)
	if(!on && check_compatibility())
		if((organ_flags & ORGAN_FAILING))
			if(!silent)
				to_chat(owner, span_warning("Your thrusters set seems to be broken!"))
			return FALSE
		if(allow_thrust(0.01))
			on = TRUE
			ion_trail.start()
			RegisterSignal(owner, COMSIG_MOVABLE_MOVED, .proc/move_react)
			owner.add_movespeed_modifier(/datum/movespeed_modifier/jetpack/cybernetic)
			RegisterSignal(owner, COMSIG_MOVABLE_PRE_MOVE, .proc/pre_move_react)
			if(!silent)
				to_chat(owner, span_notice("You turn your thrusters set on."))
	else
		ion_trail.stop()
		UnregisterSignal(owner, COMSIG_MOVABLE_MOVED)
		owner.remove_movespeed_modifier(/datum/movespeed_modifier/jetpack/cybernetic)
		UnregisterSignal(owner, COMSIG_MOVABLE_PRE_MOVE)
		if(!silent)
			to_chat(owner, span_notice("You turn your thrusters set off."))
		on = FALSE
	update_icon()

/obj/item/organ/cyberimp/chest/thrusters/update_icon_state()
	. = ..()
	if(on)
		icon_state = "imp_jetpack-on"
	else
		icon_state = "imp_jetpack"

/obj/item/organ/cyberimp/chest/thrusters/proc/move_react()
	SIGNAL_HANDLER
	if(!on)//If jet dont work, it dont work
		return
	if(!owner)//Don't allow jet self using
		return
	if(!isturf(owner.loc))//You can't use jet in nowhere or in mecha/closet
		return
	if(!(owner.movement_type & FLOATING) || owner.buckled)//You don't want use jet in gravity or while buckled.
		return
	if(owner.pulledby)//You don't must use jet if someone pull you
		return
	if(owner.throwing)//You don't must use jet if you thrown
		return
	if(length(owner.client.keys_held & owner.client.movement_keys))//You use jet when press keys. yes.
		allow_thrust(0.01)

/obj/item/organ/cyberimp/chest/thrusters/proc/pre_move_react()
	SIGNAL_HANDLER
	ion_trail.oldposition = get_turf(owner)

/obj/item/organ/cyberimp/chest/thrusters/proc/allow_thrust(num)
	if(!owner)
		return FALSE

	var/turf/owner_turf = get_turf(owner)
	if(!owner_turf) // No more runtimes from being stuck in nullspace.
		return FALSE

	// Priority 1: use air from environment.
	var/datum/gas_mixture/environment = owner_turf.return_air()
	if(environment && environment.return_pressure() > 30)
		ion_trail.generate_effect()
		return TRUE

	// Priority 2: use plasma from internal plasma storage.
	// (just in case someone would ever use this implant system to make cyber-alien ops with jetpacks and taser arms)
	if(owner.getPlasma() >= num*100)
		owner.adjustPlasma(-num*100)
		ion_trail.generate_effect()
		return TRUE

	// Priority 3: use internals tank.
	var/obj/item/tank/I = owner.internal
	if(I && I.air_contents && I.air_contents.total_moles() > num)
		var/datum/gas_mixture/removed = I.air_contents.remove(num)
		if(removed.total_moles() > 0.005)
			owner_turf.assume_air(removed)
			ion_trail.generate_effect()
			return TRUE
		else
			owner_turf.assume_air(removed)
			ion_trail.generate_effect()

	toggle(silent = TRUE)
	return FALSE

/obj/item/organ/cyberimp/chest/filtration
	name = "S.I.L.V.E.R. filtration pump"
	desc = "This implant purges your body of any toxins and drugs extremely quickly"
	implant_color = "#00e7b5"
	encode_info = AUGMENT_NO_REQ
	slot = ORGAN_SLOT_STOMACH_AID
	var/removal_speed = 1
	var/list/reagent_quirks = list()
	var/num_reagent_quirks = 0

/obj/item/organ/cyberimp/chest/filtration/emp_act(severity)
	. = ..()
	for(var/i in 0 to rand(0,5))
		reagent_quirks += get_random_reagent_id()

/obj/item/organ/cyberimp/chest/filtration/Initialize()
	. = ..()
	for(var/i in 0 to num_reagent_quirks)
		reagent_quirks += get_random_reagent_id()

/obj/item/organ/cyberimp/chest/filtration/on_life()
	. = ..()
	if(!check_compatibility())
		return

	for(var/R in owner.reagents.reagent_list)
		if(istype(R,/datum/reagent/toxin) || istype(R,/datum/reagent/drug) || is_type_in_list(R,reagent_quirks))
			owner.reagents.remove_reagent(R,removal_speed)

/obj/item/organ/cyberimp/chest/filtration/offbrand
	name = "offbrand filtration pump"
	desc = "You're not sure if it is a great idea, This implant purges your body of any toxins and drugs extremely quickly"
	implant_color = "#0d3d33"
	encode_info = AUGMENT_NO_REQ
	slot = ORGAN_SLOT_STOMACH_AID
	removal_speed = 2
	num_reagent_quirks = 5
