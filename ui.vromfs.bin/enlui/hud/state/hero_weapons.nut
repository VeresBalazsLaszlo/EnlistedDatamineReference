import "%dngscripts/ecs.nut" as ecs
from "ecs.computed" import mkEcsComputed
from "%enlSqGlob/weapon_slots.nut" import EWS_PRIMARY, EWS_GRENADE, EWS_NUM
from "%ui/hud/state/items.nut" import mkItemDescFromComp
from "weaponevents" import CmdTrackHeroWeapons
from "%ui/hud/state/inventory_grenades_es.nut" import grenadesEids
from "%ui/ec_to_watched.nut" import mkFrameIncrementObservable
from "dasevents" import CmdShowAllWeaponsUi
from "%ui/scene_update.nut" import frameUpdateCounter
from "%ui/ui_library.nut" import *

let { anyItemComps } = require("%ui/hud/state/items.nut")






let weaponSlotsRaw = array(EWS_NUM).reduce(@(res, _, idx) res.rawset(idx, mkFrameIncrementObservable(null)), {})
let weaponSlots = weaponSlotsRaw.map(@(v) v.state)
let weaponSlotsStatic = array(EWS_NUM).reduce(@(res, _, idx) res.rawset(idx, null), {})
let weaponSlotsGen = Watched(frameUpdateCounter.get())
let setWeaponSlotsGen = @(...) weaponSlotsGen.set(frameUpdateCounter.get())

foreach (obs in weaponSlots){
  obs.subscribe(setWeaponSlotsGen)
}

let { heroModsByWeaponSlotRaw, heroModsByWeaponSlotRawModify } = mkFrameIncrementObservable(array(EWS_NUM), "heroModsByWeaponSlotRaw")

let heroModsByWeaponSlot = Computed(function(){
  let res = array(EWS_NUM)
  foreach (slotNum, modsByEids in heroModsByWeaponSlotRaw.get()) {
    let mods = {}
    let iconAttachments = []
    local modWeapon
    foreach (mod in (modsByEids ?? [])){
      let {iconName=null, isWeapon=false, isActive=null, attachedItemModSlotName=null} = mod
      if (attachedItemModSlotName==null)
        continue
      mods[attachedItemModSlotName] <- mod
      if (isWeapon) {
        iconAttachments.append({
          animchar = iconName
          slot = attachedItemModSlotName
          active = true
          scale = 2.0 
        })
        
        if (modWeapon == null || isActive == true)
          modWeapon = mods[attachedItemModSlotName]
      }
    }
    if (mods.len()>0)
      res[slotNum] = {mods, iconAttachments, modWeapon}
  }
  return res
})


let isThrowMode = mkEcsComputed({
  comps = [["human_weap__throwMode", ecs.TYPE_BOOL]]
  comps_rq = ["watchedByPlr"]
  defVal = false
})

let showAllWeaponsTrigger = Watched(0)
ecs.register_es("hero_show_all_weapons",
  {
    [CmdShowAllWeaponsUi] = @(...) showAllWeaponsTrigger.trigger()
  },
  {},{ tags="ui" }
)

let canStartMeleeCharge = mkEcsComputed({
  comps = [["human_melee_charge__canStart", ecs.TYPE_BOOL]]
  comps_rq = ["watchedByPlr"]
  defVal = false
})

let hidenInUiGunQuery = ecs.SqQuery("hidenInUiGun", { comps_rq=["gun__hideInUi"]})
let isHidenGun = @(weaponEid) hidenInUiGunQuery.perform(weaponEid, @(_, _comp) true)

let heroCurrentGunSlot = Watched(0)
ecs.register_es("hero_curgunslot_ui_es",
  {
    [["onInit", ecs.EventComponentChanged]] = function(_, __, comp){
      if (isHidenGun(comp.human_weap__gunEids?[comp.human_weap__currentGunSlot] ?? ecs.INVALID_ENTITY_ID))
        return
      heroCurrentGunSlot.set(comp.human_weap__currentGunSlot)
    }
    onDestroy = @(...) heroCurrentGunSlot.set(0)
  },
  {
    comps_ro = [["human_weap__gunEids", ecs.TYPE_EID_LIST]]
    comps_rq = ["watchedByPlr"]
    comps_track = [
      ["human_weap__currentGunSlot", ecs.TYPE_INT],
    ]
  }
)

let memoizedDesc = memoize(@(_name, eid, comp) mkItemDescFromComp(eid, comp), 2)
ecs.register_es("hero_ui_weapons_es",
  {
    [["onInit", "onChange", CmdTrackHeroWeapons]] = function(_, eid, comp){
      let weaponMod = comp["weaponMod"] != null
      let idx = comp["slot_attach__weaponSlotIdx"]
      if (idx < 0 || idx >= EWS_NUM)
        return
      if (weaponMod) {
        let modCurAmmo = comp["gun__ammo"]
        let modTotalAmmo = comp["gun__totalAmmo"]
        let modsDesc = memoizedDesc(comp["item__name"], eid, comp)
        heroModsByWeaponSlotRawModify(function(v) {
          if (v[idx] == null)
            v[idx] = {}
          v[idx][eid] <- {
            modCurAmmo
            modTotalAmmo
            isActive = comp?["weapon_mod__active"]
            isWeapon = (modTotalAmmo + modCurAmmo) > 0
          }.__update(modsDesc)
          return v
        })
        return
      }
      let staticDesc = memoizedDesc(comp["item__name"], eid, comp)
      let desc = {
        isReloading = comp["gun_anim__reloadProgress"] > 0.0
        additionalAmmo = comp?["gun__additionalAmmo"] ?? 0
        eid
        subsidiaryGunEid = comp["subsidiaryGunEid"]
        firingMode = comp["gun__firingModeName"]
        curAmmo = comp["gun__ammo"]
        totalAmmo = comp["gun__totalAmmo"]
        curAmmoHolderIndex = comp["gun__curAmmoHolderIndex"]
        ammoByHolders = comp["gun__ammoByHolders"]?.getAll() ?? []
        iconByHolders = comp["gun__iconByHolders"]?.getAll() ?? []
      }
      weaponSlotsStatic[idx] <- staticDesc
      weaponSlotsRaw[idx].setValue(desc)
    }
    onDestroy = function(eid, comp) {
      let idx = comp["slot_attach__weaponSlotIdx"]
      if (idx < 0 || idx > EWS_NUM)
        return
      let weaponMod = comp["weaponMod"] != null
      if (weaponMod) {
        heroModsByWeaponSlotRawModify(function(v) {
            if (eid not in v?[idx])
              return v
            v[idx].$rawdelete(eid)
            return v
          })
        return
      }
      weaponSlotsStatic[idx] <- null
      weaponSlotsRaw[idx].setValue(null)
    }
  },
  {
    comps_rq = anyItemComps.comps_rq,
    comps_no = ["gasMask", "binocular", "flask", "grenade_thrower", "gun__hideInUi"]
    comps_ro = [
      ["weaponMod", ecs.TYPE_TAG, null],
      ["slot_attach__weaponSlotIdx", ecs.TYPE_INT, null],
    ].extend(anyItemComps.comps_ro)
    comps_track = [
      ["slot_attach__weaponSlotIdx", ecs.TYPE_INT],
      ["gun_anim__reloadProgress", ecs.TYPE_FLOAT, 0.0],
      ["gun__ammo", ecs.TYPE_INT, 0],
      ["gun__additionalAmmo", ecs.TYPE_INT, null],
      ["gun__firingModeName", ecs.TYPE_STRING, ""],
      ["subsidiaryGunEid", ecs.TYPE_EID, ecs.INVALID_ENTITY_ID],
      ["weapon_mod__active", ecs.TYPE_BOOL, null],
      ["gun__totalAmmo", ecs.TYPE_INT, 0],
      ["gun__curAmmoHolderIndex", ecs.TYPE_INT, 0],
      ["gun__ammoByHolders", ecs.TYPE_INT_LIST, null],
      ["gun__iconByHolders", ecs.TYPE_STRING_LIST, null],
    ]
  }
)

ecs.register_es("hero_state_subsidiary_gun_ui_es",
  { [[ecs.EventComponentsAppear, ecs.EventComponentsDisappear]] = @(_, eid, __) ecs.g_entity_mgr.sendEvent(eid, CmdTrackHeroWeapons()), },
  {
    comps_rq = ["gun", "watchedPlayerItem"]
    comps_ro = [ ["subsidiaryGunEid", ecs.TYPE_EID] ]
  }
)


let fastThrowExclusive = mkEcsComputed({
  comps = [["human_weap__fastThrowExclusive", ecs.TYPE_BOOL]]
  comps_rq = ["watchedByPlr"]
  defVal = false
})

let currentGunEid = Watched(ecs.INVALID_ENTITY_ID)

ecs.register_es("watched_player_current_gun_eid_track", {
  [["onInit","onChange"]] = function(_eid,comp) {
    if (isHidenGun(comp.human_weap__currentGunEid))
      return
    currentGunEid.set(comp.human_weap__currentGunEid)
  }
},
{ comps_track=[["human_weap__currentGunEid", ecs.TYPE_EID]] comps_rq = ["watchedByPlr"] })


let curWeapon = Computed(function() {
  weaponSlotsGen.get()  
  return weaponSlots?[heroCurrentGunSlot.get()].get()
})

let curWeaponStaticInfo = Computed(function() {
  weaponSlotsGen.get()  
  return weaponSlotsStatic?[heroCurrentGunSlot.get()]
})

let needReload = Computed(function(){
  let cw = curWeapon.get()
  if (cw==null)
    return false
  let {maxAmmo=0, curAmmo, isReloading, totalAmmo} = cw
  let maxLoadedAmmo = max(maxAmmo, 1)
  let fullness = curAmmo.tofloat()/maxLoadedAmmo
  return (fullness < 0.1 || (maxLoadedAmmo > 1 && curAmmo==1)) && totalAmmo > curAmmo && !isReloading
})


let curWeaponIsReloadable = Computed(@() curWeaponStaticInfo.get()?.isReloadable ?? ((curWeaponStaticInfo.get()?.maxAmmo ?? 0) > 0))
let curWeaponFiringMode = Computed(@() curWeapon.get()?.firingMode ?? "")
let curWeaponIsDualMag = Computed(@() curWeaponStaticInfo.get()?.isDualMagGun ?? false)

let curWeaponAdditionalAmmo = Computed(@() curWeapon.get()?.additionalAmmo ?? 0)
let curGunMod = Computed(@() heroModsByWeaponSlot.get()?[heroCurrentGunSlot.get()].modWeapon)


let isModActive = Computed(function() {
  let gunMod = curGunMod.get()
  let isActive = gunMod?.isActive
  if (isActive != null)
    return isActive
  return gunMod?.eid != null && gunMod.eid == curWeapon.get()?.subsidiaryGunEid
})
let curWeaponHasAltShot = Computed(@() curGunMod.get()!=null)
let curWeaponAmmo = Computed(@() (isModActive.get() ? curGunMod.get()?.modCurAmmo : curWeapon.get()?.curAmmo) ?? 0)
let curWeaponAltAmmo = Computed(@() (isModActive.get() ? curWeapon.get()?.curAmmo : curGunMod.get()?.modCurAmmo) ?? 0)
let curWeaponTotalAmmo = Computed(@() (isModActive.get() ? curGunMod.get()?.modTotalAmmo : curWeapon.get()?.totalAmmo) ?? 0)
let curWeaponAltTotalAmmo = Computed(@() (isModActive.get() ? curWeapon.get()?.totalAmmo : curGunMod.get()?.modTotalAmmo) ?? 0)
let curWeaponWeapType = Computed(@() curWeaponStaticInfo.get()?.weapType)
let curWeaponChargeTime = Computed(@() curWeaponStaticInfo.get()?.chargeTime ?? 0)
let curWeaponIsGrenade = Computed(@() EWS_GRENADE==heroCurrentGunSlot.get())
let curWeaponCurAmmoHolderIndex = Computed(@() curWeapon.get()?.curAmmoHolderIndex ?? 0)
let curWeaponAmmoByHolders = Computed(@() curWeapon.get()?.ammoByHolders ?? [])
let curWeaponIconByHolders = Computed(@() curWeapon.get()?.iconByHolders ?? [])
let hasPrimaryWeapon = Computed(function() {
  weaponSlotsGen.get()  
  return weaponSlots?[EWS_PRIMARY].get() != null
})
let curWeaponHasScope = Computed(@() heroModsByWeaponSlot.get()?[heroCurrentGunSlot.get()].mods.scope!=null)
let curHeroGrenadeEid = Computed(function() {
  weaponSlotsGen.get()  
  return weaponSlots?[EWS_GRENADE].get().eid
})

return {
  currentGunEid
  needReload
  fastThrowExclusive
  heroCurrentGunSlot
  heroModsByWeaponSlot
  weaponSlotsStatic
  weaponSlots
  curHeroGrenadeEid

  hasAnyGrenade = Computed(@() grenadesEids.get().len()>0)

  hasWeapon = Computed(@() curWeapon.get() != null)
  curWeaponWeapType
  curWeaponAmmo
  curWeaponTotalAmmo
  curWeaponIsDualMag
  curWeaponAdditionalAmmo
  curWeaponAltAmmo
  curWeaponAltTotalAmmo
  curWeaponIsModActive = isModActive
  curWeaponIsReloadable
  curWeaponFiringMode
  curGunMod
  curWeaponHasAltShot
  curWeaponChargeTime
  curWeaponIsGrenade
  curWeaponCurAmmoHolderIndex
  curWeaponAmmoByHolders
  curWeaponIconByHolders
  hasPrimaryWeapon
  curWeaponHasScope
  canStartMeleeCharge
  EWS_NUM
  isThrowMode
  showAllWeaponsTrigger
}
