import "%ui/components/fontawesome.map.nut" as fa
import "%ui/components/faComp.nut" as faComp
import "%ui/components/mkBulletTypeIcon.nut" as mkBulletTypeIcon
import "%ui/hud/huds/player_info/mk_health_bar.nut" as healthBar
import "%dngscripts/ecs.nut" as ecs
from "%ui/style/fontsStyle.nut" import fontBody, fontawesome
from "%ui/hud/style.nut" import HUD_TIPS_HOTKEY_FG, FAIL_TEXT_COLOR, DEFAULT_TEXT_COLOR
from "%ui/hud/state/vehicle_hp.nut" import hero as heroVehicleState
from "%ui/hud/state/vehicle_turret_state.nut" import vehicleTurrets, turretsReload, turretsReplenishment, turretsAmmo, showVehicleWeapons
from "%ui/hud/menus/controls_state.nut" import generation
from "%ui/hud/huds/player_info/vehicle_weapon_widget.nut" import vehicleWeaponWidget
from "%ui/control/active_controls.nut" import isGamepad
from "net" import get_sync_time
from "%ui/hud/state/replay_state.nut" import isReplay
from "%ui/hud/huds/player_info/mobile_respawn_widget.nut" import mobileRespawnWidget, mobileRespawnOccupiedSeats
from "%ui/control/formatInputBinding.nut" import textListFromAction, buildElems
from "%ui/components/controlHudHint.nut" import mkShortHudHintFromList
from "%ui/state/biggerFontsState.nut" import biggerFontsState
from "%ui/ui_library.nut" import *

const barWidth = sw(7)
const barHeight = fsh(1)
const barBlockHeight = hdpx(22)
const gap = hdpx(5)
let vehicleWeaponWidth = biggerFontsState.get() ? hdpx(480) : hdpx(425)

let mkControlText = @(text) {
  text,
  color = HUD_TIPS_HOTKEY_FG,
  rendObj = ROBJ_TEXT padding = hdpx(4)
}.__update(fontBody)

const eventTypeToText = false
let makeTurretControlTip = @(hotkey) function(){
  if (hotkey == null)
    return null
  let textList = textListFromAction(hotkey, isGamepad.get() ? 1 : 0, eventTypeToText)
  let controlElems = buildElems(textList, { textFunc = mkControlText, compact = true })
  return mkShortHudHintFromList(controlElems, [generation])
}

const reloadProgressSize = fsh(4.0)
let reloadImg = Picture("ui/skin#round_border.svg:{0}:{0}".subst(reloadProgressSize.tointeger()))
let reloadMoreOne = freeze({
  size = const [fontH(100), SIZE_TO_CONTENT]
  rendObj = ROBJ_INSCRIPTION
  font = fontawesome.font
  color = Color(255, 86, 86)
  text = fa["arrow-down"]
  fontSize = hdpx(10)
  vplace = ALIGN_CENTER
  hplace = ALIGN_CENTER
})
let reloadLessOne = freeze({
  size = const [fontH(100), SIZE_TO_CONTENT]
  rendObj = ROBJ_INSCRIPTION
  font = fontawesome.font
  color = Color(86, 255, 86)
  text = fa["arrow-up"]
  fontSize = hdpx(10)
  vplace = ALIGN_CENTER
  hplace = ALIGN_CENTER
})

let mkReloadProgress = @(from, to, duration, key, perksMult, stowageMult) {
  margin = const [0, 0, 0, hdpx(10)]
  rendObj = ROBJ_PROGRESS_CIRCULAR
  image = reloadImg
  imageHalign = ALIGN_CENTER
  imageValign = ALIGN_CENTER
  vplace = ALIGN_CENTER
  hplace = ALIGN_CENTER
  halign = ALIGN_CENTER
  size = const [reloadProgressSize, reloadProgressSize]
  fValue = 0
  key
  flow = FLOW_HORIZONTAL
  children =
    perksMult < 1. && stowageMult <= 1.
      ? reloadLessOne
      : [
          perksMult > 1. ? reloadMoreOne : null,
          stowageMult > 1. ? reloadMoreOne : null
        ]
  animations = [
    { prop = AnimProp.fValue, from, to, duration, play = true}
  ]
}

let triggerGroupTurretControlTips = ["Vehicle.Shoot", "Vehicle.ShootSecondary", "Vehicle.ShootMachinegun", "Vehicle.ShootGrenadeLauncher"]
let defaultTurretControlTips = ["Vehicle.Shoot", "Vehicle.ShootSecondary", "Vehicle.ShootMachinegun", "Vehicle.ShootTurret03"]

function turretControlTip(turret, index) {
  let hotkey = turret?.hotkey
  let triggerGroup = turret?.triggerGroup ?? -1
  let gunEid = turret?.gunEid ?? ecs.INVALID_ENTITY_ID
  let turretReloadState = Computed(@() turretsReload.get()?[gunEid] ?? {})

  return function() {
    let {
      progressStopped = -1, totalTime = -1, endTime = -1, perksReloadTimeMult = 1., ammoStowageReloadTimeMult = 1.
    } = turretReloadState.get()
    let reloadTimeLeft = max(0, endTime - get_sync_time())
    let isReloadStopped = progressStopped >= 0
    let startProgress = isReloadStopped ? progressStopped
      : totalTime > 0 ? max(0, 1 - reloadTimeLeft / totalTime)
      : 0
    let endProgress = isReloadStopped ? progressStopped : 1
    let isReloading = endTime > 0
    return {
      watch = turretReloadState
      valign = ALIGN_CENTER
      vplace = ALIGN_CENTER
      children = [
        isReloading ? mkReloadProgress(startProgress, endProgress, reloadTimeLeft, turretReloadState.get(), perksReloadTimeMult, ammoStowageReloadTimeMult)
                    : makeTurretControlTip(hotkey ?? (triggerGroup != -1
                      ? triggerGroupTurretControlTips[triggerGroup]
                      : defaultTurretControlTips?[index]))
      ]
    }
  }
}

let triggerGroupNextBulletTips = ["Vehicle.NextBulletType", "Vehicle.SecondaryNextBulletType"]
function turretNextBulletTip(triggerGroup) {
  return makeTurretControlTip(triggerGroupNextBulletTips?[triggerGroup] ?? triggerGroupNextBulletTips[0])
}

function turretIconCtor(weapon, width, baseHeight) {
  let height = (0.8 * baseHeight).tointeger()
  let size = [width, height]
  let bulletIcon = mkBulletTypeIcon(weapon, size)
  return {
    size = size
    rendObj = ROBJ_IMAGE
    imageHalign = ALIGN_RIGHT
    imageValign = ALIGN_CENTER
    vplace = ALIGN_CENTER
    hplace = ALIGN_RIGHT
    image = bulletIcon.image
    color = bulletIcon.color
    keepAspect = KEEP_ASPECT_FIT
  }
}

function ordnanceWeaponBlock(turret, idx) {
  let groupName = turret.groupName
  let subGroupGunEids = turret?.subGroupGunEids
  let isCurrentOrdnance = Computed(function() {
    let nextGunEid = turretsAmmo.get()?[groupName].firstLoadedGunInGroup
    if (nextGunEid == null)
      return false
    return subGroupGunEids == null ? true : subGroupGunEids.indexof(nextGunEid) != null
  })
  return function() {
    let isCurrent = isCurrentOrdnance.get()
    return {
      watch = isCurrentOrdnance
      size = SIZE_TO_CONTENT
      children = vehicleWeaponWidget({
        width = vehicleWeaponWidth
        weapon = turret.__merge({ instant = !turret.isReloadable, showZeroAmmo = true, isCurrent })
        hint = isCurrent ? turretControlTip(turret, idx) : null
        iconCtor = turretIconCtor
        turretsAmmo
        turretsReplenishment
      })
    }
  }
}

function vehicleTurretBlock(turret, idx) {
  if (!turret.isControlled && !isReplay.get())
    return null

  if (!turret.isWithSeveralShells) {
    if (turret.isBomb || turret.isRocket)
      return ordnanceWeaponBlock(turret, idx)
    return vehicleWeaponWidget({
      width = vehicleWeaponWidth
      weapon = turret.__merge({ instant = !turret.isReloadable, showZeroAmmo = true })
      hint = turretControlTip(turret, idx)
      iconCtor = turretIconCtor
      turretsAmmo
      turretsReplenishment
    })
  }

  return function() {
    let activeAmmoSets = turret.ammoSet
      .map(@(ammoSet, setId) ammoSet.__merge({setId}))
      .filter(@(ammoSet) (ammoSet?.maxAmmo ?? 0) > 0)
    let ammoSetsCount = activeAmmoSets.len()
    let nextAmmoSetIndex = activeAmmoSets.findindex(@(set) set.setId == turret.nextAmmoSetId) ?? 0
    let switchToBulletIdx = activeAmmoSets[(nextAmmoSetIndex + 1) % max(ammoSetsCount, 1)].setId
    let children = activeAmmoSets.map(function(bt) {
      let setId = bt.setId
      let isCurrent = turret.currentAmmoSetId == setId
      let weapon = turret.__merge({
        isCurrent = isCurrent
        isNext = turret.nextAmmoSetId == setId
        name = $"{bt.type}/name/short"
        bulletType = bt.type
        setId
        instant = !isCurrent || !turret.isReloadable
      })
      return vehicleWeaponWidget({
        width = vehicleWeaponWidth
        height = hdpx(60)
        weapon = weapon
        hint = !turret.isControlled ? null
          : isCurrent ? turretControlTip(turret, idx)
          : setId == switchToBulletIdx ? turretNextBulletTip(turret?.triggerGroup)
          : null
        iconCtor = turretIconCtor
        turretsAmmo
        turretsReplenishment
      })
    })
    return {
      size = SIZE_TO_CONTENT
      flow = FLOW_VERTICAL
      gap = gap
      children = children
    }
  }
}

let mkFaIcon = @(faId, color) faComp(faId, {color, minHeight = fontH(100)})

let isBurn = Computed(@() heroVehicleState.get().isBurn)
function vehicleHpEffects() {
  let res = { watch = isBurn }
  if (!isBurn.get())
    return res
  return res.__update(mkFaIcon("fire", FAIL_TEXT_COLOR))
}

const hitAnimTrigger = "vehicle_hit"
local lastVehicleData = null
function saveLastVehicleData() {
  lastVehicleData = {
    vehicle = heroVehicleState.get().vehicle
    hp = heroVehicleState.get().hp
  }
}
saveLastVehicleData()
heroVehicleState.subscribe(function(v) {
  if (v.vehicle == lastVehicleData.vehicle && v.hp == lastVehicleData.hp)
    return
  if (v.vehicle == lastVehicleData.vehicle)
    anim_start(hitAnimTrigger)
  saveLastVehicleData()
})

function vehicleHp() {
  let res = { watch = heroVehicleState }
  let { vehicle, hp, maxHp } = heroVehicleState.get()
  if (vehicle == ecs.INVALID_ENTITY_ID)
    return res

  return res.__update({
    flow = FLOW_HORIZONTAL
    valign = ALIGN_CENTER
    gap = gap
    children = [
      hp >= maxHp ? null : mkFaIcon("gear", DEFAULT_TEXT_COLOR)
      {
        size = [barWidth, barHeight]
        children = healthBar({ hp = heroVehicleState.get().hp, maxHp = heroVehicleState.get().maxHp,
          hitTrigger = hitAnimTrigger, colorFg = DEFAULT_TEXT_COLOR })
      }
    ]
  })
}

return function() {
  let turretsChildren = []
  if (mobileRespawnOccupiedSeats.get() != null)
    turretsChildren.append(mobileRespawnWidget(mobileRespawnOccupiedSeats.get()))
  if (showVehicleWeapons.get())
    turretsChildren.extend(vehicleTurrets.get().map(vehicleTurretBlock))
  let turrets = turretsChildren.len() != 0 ? {
    flow = FLOW_VERTICAL
    gap = gap
    children = turretsChildren
  } : null

  return {
    watch = [vehicleTurrets, showVehicleWeapons, mobileRespawnOccupiedSeats]
    size = SIZE_TO_CONTENT
    flow = FLOW_VERTICAL
    halign = ALIGN_RIGHT
    gap = hdpx(30)
    children = [
      turrets
      {
        size = [SIZE_TO_CONTENT, barBlockHeight]
        flow = FLOW_HORIZONTAL
        valign = ALIGN_CENTER
        gap = gap
        children = [
          vehicleHpEffects
          vehicleHp
        ]
      }
    ]
  }
}