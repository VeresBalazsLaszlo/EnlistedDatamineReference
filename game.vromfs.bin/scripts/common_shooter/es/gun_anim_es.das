require Gun
require PhysVars
require ecs
require AnimV20
require common_shooter.es.gun_anim_common
require daslib/enum_trait
require enlisted.events_enlisted
require common_shooter.es.human.human_reload_common
require common_shooter.es.human.gun_reload_common
require DngHuman

[es(on_appear)]
def gun_anim_init_es(evt : Event;
                     var phys_vars : PhysVars&;
                     var gun_anim__boltActionVarId : int&;
                     var gun_anim__reloadStateId : int&;
                     var gun_anim__reloadVarId : int&;
                     var gun_anim__singleReloadVarId : int&;
                     var gun_anim__reloadStyleVarId : int&;
                     var gun_anim__singleReloadStateVarId : int&;
                     var gun_anim__haveProjectileInChamberVarId : int&;
                     var gun_anim__curNumAmmoVarId : int&;
                     var gun_anim__haveOpticsVarId : int&;
                     var gun_anim__isSecondMagVarId : int&;
                     var gun_anim__weapModStateVarId : int&;
                     var gun_anim__adsPositionVarId : int&;
                     var gun_anim__bipodEnabledId : int&;
                     var gun_anim__singleReloadStates : IntList;
                     var gun_anim__reloadStyles : IntList;
                     var gun_anim__reloadStates : IntList;
                     var gun_anim__weapModStates : IntList)
  gun_anim__boltActionVarId = registerVar(phys_vars, "bolt_action", 0.f)
  gun_anim__reloadVarId = registerVar(phys_vars, "reload_progress", 0.f)
  gun_anim__singleReloadVarId = registerVar(phys_vars, "single_reload_progress", 0.f)
  gun_anim__reloadStyleVarId = registerVar(phys_vars, "reload_style", 0.f)
  gun_anim__reloadStateId = registerVar(phys_vars, "reload_state", 0.f)
  gun_anim__singleReloadStateVarId = registerVar(phys_vars, "single_reload_state", 0.f)
  gun_anim__haveProjectileInChamberVarId = registerVar(phys_vars, "have_projectile_in_chamber", 0.f)
  gun_anim__curNumAmmoVarId = registerVar(phys_vars, "cur_num_ammo", 0.f)
  gun_anim__haveOpticsVarId = registerVar(phys_vars, "have_optics", 0.f)
  gun_anim__isSecondMagVarId = registerVar(phys_vars, "is_second_mag", 0.f)
  gun_anim__weapModStateVarId = registerVar(phys_vars, "weapon_mod_state", 0.f)
  gun_anim__adsPositionVarId = registerVar(phys_vars, "ads_position", 0.f)
  gun_anim__bipodEnabledId = registerVar(phys_vars, "bipod_enabled", 0.f)

  let reload_count = typeinfo enum_length(type<GunSingleReloadState>)
  resize(gun_anim__singleReloadStates, reload_count)
  let animStates <- {"single_reload_prepare" => 1, "single_reload_loop" => 2, "single_reload_post" => 3}
  gun_anim__singleReloadStates[int(GunSingleReloadState.SINGLE_RELOAD_DISABLED)] = -1
  for state_name, state_num in keys(animStates), values(animStates)
    gun_anim__singleReloadStates[state_num] = animV20_get_enum_value_by_name(state_name)

  let reload_style_count = typeinfo enum_length(type<GunReloadStyle>)
  resize(gun_anim__reloadStyles, reload_style_count)
  let reloadStylesEnum = fixed_array("reload_simple", "reload_alt", "reload_alt_jammed", "reload_jammed", "realod_dual_mag", "reload_quick")
  assert(length(reloadStylesEnum) == reload_style_count)
  for i in range(length(reloadStylesEnum))
    gun_anim__reloadStyles[i] = animV20_get_enum_value_by_name(reloadStylesEnum[i])

  let reload_state_count = typeinfo enum_length(type<GunReloadState>)
  resize(gun_anim__reloadStates, reload_state_count)
  for i in range(length(GUN_RELOAD_STATE_NAMES))
    gun_anim__reloadStates[i] = animV20_get_enum_value_by_name(GUN_RELOAD_STATE_NAMES[i])

  let weap_mode_count = typeinfo enum_length(type<GunWeapModState>)
  resize(gun_anim__weapModStates, weap_mode_count)
  for weap_mode in gun_anim__weapModStates
    weap_mode = -1
  let weapModStatesStrs = fixed_array("weapon_mod_reload", "weapon_mod_activate", "weapon_mod_deactivate")
  assert(length(weapModStatesStrs) == weap_mode_count - 1)
  for i in range(length(weapModStatesStrs))
    gun_anim__weapModStates[i + 1] = animV20_get_enum_value_by_name(weapModStatesStrs[i])


[es(tag=render)]
def  gun_anim_updater_es(info : ParallelUpdateFrameDelayed&;
                         gun_anim__boltActionVarId : int;
                         gun_anim__reloadVarId : int;
                         gun_anim__singleReloadVarId : int;
                         gun_anim__reloadStyleVarId : int;
                         gun_anim__reloadStateId : int;
                         gun_anim__bipodEnabledId : int;
                         gun_anim__singleReloadStateVarId : int;
                         gun_anim__haveProjectileInChamberVarId : int;
                         gun_anim__curNumAmmoVarId : int;
                         gun_anim__haveOpticsVarId : int;
                         gun_anim__isSecondMagVarId : int;
                         gun_anim__weapModStateVarId : int;
                         gun_anim__singleReloadStates : IntList;
                         gun_anim__reloadStyles : IntList;
                         gun_anim__reloadStates : IntList;
                         gun_anim__weapModStates : IntList;
                         gun : Gun const?;
                         gun_reload__state : int = 0;
                         gun__ammo : int = 0;
                         visual_magazine_fullness__ammoCount : int = -1;
                         gun_anim__reloadProgress : float = -1.0f;
                         gun_anim__singleReloadProgress : float = -1.0f;
                         gun_anim__singleReloadState : int = 0;
                         gun_anim__reloadStyle : int = 0;
                         gun__opticsAttached : bool = false;
                         gun__owner : EntityId = INVALID_ENTITY_ID;
                         gun__showChamberedAmmo : bool = true;
                         gun__bipodMandatory : Tag const?;
                         gun__bipodMandatoryAds : Tag const?;
                         gun_anim__weapModEid : EntityId = INVALID_ENTITY_ID;
                         gun_anim__weapModState : int = int(GunWeapModState.WEAP_MOD_STATE_NONE);
                         gun__isDualMagReady : bool = true;
                         animchar__visible : bool = true;
                         var phys_vars : PhysVars)
  if !animchar__visible
    return
  var foundGun = false

  query(gun_anim__weapModEid) <| $ [es] (gun : Gun&; gun__showChamberedAmmo : bool)
    foundGun = true
    setVar(phys_vars, gun_anim__boltActionVarId, gun |> gun_lerpBoltActionTime(info.curTime))
    setVar(phys_vars, gun_anim__haveProjectileInChamberVarId, (gun__showChamberedAmmo &&  gun.curState.loaded) ? 1.f : 0.f)

  if !foundGun && gun != null
    setVar(phys_vars, gun_anim__boltActionVarId, *gun |> gun_lerpBoltActionTime(info.curTime))
    setVar(phys_vars, gun_anim__haveProjectileInChamberVarId, (gun__showChamberedAmmo && gun.curState.loaded) ? 1.f : 0.f)

  let singleReloadStateEnum = gun_anim__singleReloadStates[gun_anim__singleReloadState]
  let reloadStyleEnum = gun_anim__reloadStyles[gun_anim__reloadStyle]
  let reloadStateEnum = gun_anim__reloadStates[gun_reload__state]

  setVar(phys_vars, gun_anim__weapModStateVarId, float(gun_anim__weapModStates[gun_anim__weapModState]))
  setVar(phys_vars, gun_anim__isSecondMagVarId, gun__isDualMagReady ? 0.f : 1.f)
  setVar(phys_vars, gun_anim__reloadVarId, gun_anim__reloadProgress)
  setVar(phys_vars, gun_anim__singleReloadVarId, gun_anim__singleReloadProgress)
  setVar(phys_vars, gun_anim__singleReloadStateVarId, float(singleReloadStateEnum))
  setVar(phys_vars, gun_anim__reloadStyleVarId, float(reloadStyleEnum))
  setVar(phys_vars, gun_anim__reloadStateId, float(reloadStateEnum))
  if gun__bipodMandatory != null || gun__bipodMandatoryAds != null
    query(gun__owner) <| $ [es] (bipod__enabled : bool = false; human_net_phys__isCrawl : bool = false)
      setVar(phys_vars, gun_anim__bipodEnabledId, (bipod__enabled || human_net_phys__isCrawl) ? 1.f : 0.f)

  setVar(phys_vars, gun_anim__curNumAmmoVarId, visual_magazine_fullness__ammoCount >= 0 ? float(visual_magazine_fullness__ammoCount) : float(gun__ammo))
  setVar(phys_vars, gun_anim__haveOpticsVarId, gun__opticsAttached ? 1.f : 0.f)

[es(tag=render, track=human_gun_attached)]
def gun_anim_reset_vars_on_deequip(evt : Event;
                                   human_gun_attached : bool;
                                   gun_anim__adsPositionVarId : int;
                                   var phys_vars : PhysVars)
  if !human_gun_attached
    setVar(phys_vars, gun_anim__adsPositionVarId, 0.0f)


[es(tag=render, after=keep_human_net_phys_cur_state_es)]
def gun_anim_update_ads_position(info : ParallelUpdateFrameDelayed;
                                 human_weap__currentGunSlot : int;
                                 human_weap__gunEids : EidList;
                                 human_net_phys : HumanActor)
  let gunEid = human_weap__currentGunSlot >= 0 ? human_weap__gunEids[human_weap__currentGunSlot] : INVALID_ENTITY_ID
  query(gunEid) <| $ [es] (gun_anim__adsPositionVarId : int; var phys_vars : PhysVars)
    let interpK = get_phys_interpk_clamped(human_net_phys.phys, info.curTime)
    let aimPosition = lerp(human_net_phys.phys.previousState.aimPosition, human_net_phys.phys.currentState.aimPosition, interpK)
    setVar(phys_vars, gun_anim__adsPositionVarId, aimPosition)
