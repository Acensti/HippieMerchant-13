// VOID CHILL
/datum/status_effect/void_chill
	id = "void_chill"
	alert_type = /atom/movable/screen/alert/status_effect/void_chill
	duration = 8 SECONDS
	status_type = STATUS_EFFECT_REPLACE
	tick_interval = 0.5 SECONDS
	/// The amount the victim's body temperature changes each tick() in kelvin. Multiplied by TEMPERATURE_DAMAGE_COEFFICIENT.
	var/cooling_per_tick = -14

/atom/movable/screen/alert/status_effect/void_chill
	name = "Void Chill"
	desc = "There's something freezing you from within and without. You've never felt cold this oppressive before..."
	icon_state = "void_chill"

/datum/status_effect/void_chill/on_apply()
	owner.add_movespeed_modifier(/datum/movespeed_modifier/void_chill, update = TRUE)
	return TRUE

/datum/status_effect/void_chill/on_remove()
	owner.remove_movespeed_modifier(/datum/movespeed_modifier/void_chill, update = TRUE)

/datum/status_effect/void_chill/tick()
	owner.adjust_bodytemperature(cooling_per_tick * TEMPERATURE_DAMAGE_COEFFICIENT)

/datum/status_effect/void_chill/major
	duration = 10 SECONDS
	cooling_per_tick = -20

/datum/movespeed_modifier/void_chill
	multiplicative_slowdown = 0.3

//CORROSION CURSE
/datum/status_effect/corrosion_curse
	id = "corrosion_curse"
	status_type = STATUS_EFFECT_REPLACE
	alert_type = null
	tick_interval = 1 SECONDS

/datum/status_effect/corrosion_curse/on_apply()
	to_chat(owner, span_userdanger("Your body starts to break apart!"))
	return TRUE

/datum/status_effect/corrosion_curse/tick()
	. = ..()
	if(!ishuman(owner))
		return
	var/mob/living/carbon/human/human_owner = owner
	var/chance = rand(0, 100)
	switch(chance)
		if(0 to 10)
			human_owner.vomit()
		if(20 to 30)
			human_owner.Dizzy(10)
			human_owner.Jitter(10)
		if(30 to 40)
			// Don't fully kill liver that's important
			human_owner.adjustOrganLoss(ORGAN_SLOT_LIVER, 10, 90)
		if(40 to 50)
			// Don't fully kill heart that's important
			human_owner.adjustOrganLoss(ORGAN_SLOT_HEART, 10, 90)
		if(50 to 60)
			// You can fully kill the stomach that's not crucial
			human_owner.adjustOrganLoss(ORGAN_SLOT_STOMACH, 10)
		if(60 to 70)
			// Same with eyes
			human_owner.adjustOrganLoss(ORGAN_SLOT_EYES, 5)
		if(70 to 80)
			// And same with ears
			human_owner.adjustOrganLoss(ORGAN_SLOT_EARS, 10)
		if(80 to 90)
			// But don't fully kill lungs that's usually important
			human_owner.adjustOrganLoss(ORGAN_SLOT_LUNGS, 10, 90)
		if(90 to 95)
			// And definitely don't fully kil brains
			human_owner.adjustOrganLoss(ORGAN_SLOT_BRAIN, 20, 190)
		if(95 to 100)
			human_owner.add_confusion(10)

/datum/status_effect/cloudstruck
	id = "cloudstruck"
	status_type = STATUS_EFFECT_REPLACE
	duration = 3 SECONDS
	on_remove_on_mob_delete = TRUE
	///This overlay is applied to the owner for the duration of the effect.
	var/mutable_appearance/mob_overlay

/datum/status_effect/cloudstruck/on_creation(mob/living/new_owner, set_duration)
	if(isnum(set_duration))
		duration = set_duration
	. = ..()

/datum/status_effect/cloudstruck/on_apply()
	mob_overlay = mutable_appearance('icons/effects/eldritch.dmi', "cloud_swirl", ABOVE_MOB_LAYER)
	owner.overlays += mob_overlay
	owner.update_appearance()
	ADD_TRAIT(owner, TRAIT_BLIND, STATUS_EFFECT_TRAIT)
	return TRUE

/datum/status_effect/cloudstruck/on_remove()
	. = ..()
	if(QDELETED(owner))
		return
	REMOVE_TRAIT(owner, TRAIT_BLIND, STATUS_EFFECT_TRAIT)
	if(owner)
		owner.overlays -= mob_overlay
		owner.update_appearance()

/datum/status_effect/cloudstruck/Destroy()
	. = ..()
	QDEL_NULL(mob_overlay)

// AMOK
/datum/status_effect/amok
	id = "amok"
	status_type = STATUS_EFFECT_REPLACE
	alert_type = null
	duration = 10 SECONDS
	tick_interval = 1 SECONDS

/datum/status_effect/amok/on_apply(mob/living/afflicted)
	. = ..()
	to_chat(owner, span_boldwarning("You feel filled with a rage that is not your own!"))

/datum/status_effect/amok/tick()
	. = ..()
	var/prev_combat_mode = owner.combat_mode
	owner.set_combat_mode(TRUE)

	var/list/mob/living/targets = list()
	for(var/mob/living/potential_target in oview(owner, 1))
		if(IS_HERETIC_OR_MONSTER(potential_target))
			continue
		targets += potential_target
	if(LAZYLEN(targets))
		owner.log_message(" attacked someone due to the amok debuff.", LOG_ATTACK) //the following attack will log itself
		owner.ClickOn(pick(targets))
	owner.set_combat_mode(prev_combat_mode)
