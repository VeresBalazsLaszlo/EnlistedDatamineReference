import "%ui/hud/huds/player_info/vital_player_info.ui.nut" as vitalPlayerInfo
import "%ui/hud/huds/player_info/vehicle_weapons.nut" as vehicleBlock
import "%ui/hud/huds/player_info/player_ammo.ui.nut" as mkAmmoInfo
import "%ui/hud/huds/player_info/medkitIcon.nut" as mkMedkitIcon
import "%ui/hud/huds/player_info/repairIcon.nut" as mkRepairIcon
import "%dngscripts/ecs.nut" as ecs
from "%ui/hud/state/hudGameModes.nut" import forcedMinimalHud
from "%ui/style/fontsStyle.nut" import fontHeading2, fontSub
from "%ui/hud/huds/player_info/medic_medpacks.ui.nut" import medicMedpacks
from "%ui/hud/huds/player_info/player_cur_weapon.ui.nut" import firingModeCmp
from "%ui/hud/state/vehicle_turret_state.nut" import showVehicleWeapons
from "%ui/hud/huds/player_info/player_weapon_switch.nut" import weaponItems
from "%ui/hud/state/controlled_hero.nut" import controlledHeroEid
from "%ui/hud/state/watched_hero.nut" import watchedHeroEid
from "%ui/hud/state/hudOptionsState.nut" import minimalistHud
from "%ui/hud/state/hero_weapons.nut" import currentGunEid, showAllWeaponsTrigger
from "%ui/hud/state/total_medkits.nut" import selfHealMedkits
from "%ui/hud/state/total_repairkits.nut" import repairKits
from "%ui/style/designConst.nut" import defTxtColor, smallPadding
from "%ui/hud/huds/player_info/mobile_respawn_widget.nut" import mobileRespawnOccupiedSeats
from "%ui/hud/huds/tips/spy_detected_tip.nut" import spyDetectedIcon
from "%sqstd/frp.nut" import subscribeList
from "%ui/ui_library.nut" import *

let playerGrenades = require("%ui/hud/huds/player_info/grenades.ui.nut")


let hasRepair = Computed(@() repairKits.get() > 0)
let medkitIco = mkMedkitIcon(hdpxi(25), defTxtColor)
let repairIco = mkRepairIcon(hdpxi(25), defTxtColor)

let mkText = @(txt, override = {}) {
  rendObj = ROBJ_TEXT
  text = txt
  color = defTxtColor
}.__update(fontSub, override)


function playerMedkits() {
  let count = selfHealMedkits.get()
  return {
    watch = selfHealMedkits
    children = count <= 0 ? null
      : count == 1 ? medkitIco
      : {
          flow = FLOW_HORIZONTAL
          valign = ALIGN_BOTTOM
          children = [
            medkitIco
            mkText(count, { pos = [0, smallPadding] })
          ]
        }
  }
}

let playerRepairkit = @() {
  watch = hasRepair
  children = hasRepair.get() ? repairIco : null
}

let mainStyles = {
  curAmmo = {fontFxColor=Color(0,0,0,50) fontFx=FFT_GLOW}.__update(fontHeading2)
  sep = {fontFxColor=Color(0,0,0,50) fontFx=FFT_GLOW}.__update(fontHeading2)
  totalAmmo = {fontFxColor=Color(0,0,0,50) fontFx=FFT_GLOW}.__update(fontHeading2)
  useBlur = false
}

let secondaryStyles = {
  curAmmo = {fontFxColor=Color(0,0,0,50) fontFx=FFT_GLOW}.__update(fontSub)
  sep = {fontFxColor=Color(0,0,0,50) fontFx=FFT_GLOW}.__update(fontSub)
  totalAmmo = {fontFxColor=Color(0,0,0,50) fontFx=FFT_GLOW}.__update(fontSub)
  useBlur = false
}

let gap = freeze({size = const [0, hdpx(5)]})

let equipmentIcons = freeze({
  flow = FLOW_HORIZONTAL
  gap = hdpx(8)
  valign = ALIGN_CENTER
  children = [playerRepairkit, playerMedkits, playerGrenades]
})

let showShortBlock = Watched(true)
let hideShortBlock = @() showShortBlock.set(false)
function activateShowShortBlock(...){
  showShortBlock.set(true)
  if (!forcedMinimalHud.get())
    return
  gui_scene.resetTimeout(4, hideShortBlock)
}
subscribeList(activateShowShortBlock, forcedMinimalHud, minimalistHud)

let showShortHandlers = [ "Human.Weapon1","Human.Weapon2","Human.Weapon3",
    "Human.Weapon4","Human.Throw","Human.SpecialItemSlot","Human.GrenadeNext","Human.GrenadePrev","Inventory.UseMedkit",
    "Human.WeaponNext","Human.WeaponPrev","Human.Melee", "Human.WeaponNextMain", "Human.GrenadeNext", "Human.FiringMode",
    "Human.WeapModToggle", "Human.Reload"
  ].map(@(v) [v,activateShowShortBlock]).totable()

let handlersCm = {eventHandlers = showShortHandlers}

let shortPlayerBlock = @() {
  flow = FLOW_VERTICAL
  size = SIZE_TO_CONTENT
  halign = ALIGN_RIGHT
  watch = showShortBlock
  children = showShortBlock.get() ? [
    medicMedpacks
    gap
    spyDetectedIcon
    mkAmmoInfo(mainStyles, secondaryStyles)
    gap
    firingModeCmp
    gap
    gap
    equipmentIcons
    handlersCm
  ] : handlersCm
}

let showAllWeapons = Watched(false)
let hideAllWeapons = @(...) showAllWeapons.set(false)
function activateShowAllWeapons(...){
  if (controlledHeroEid.get() != watchedHeroEid.get() || controlledHeroEid.get() == ecs.INVALID_ENTITY_ID)
    return
  showAllWeapons.set(true)
  activateShowShortBlock()
  gui_scene.resetTimeout(4, hideAllWeapons)
}
subscribeList(activateShowAllWeapons, showAllWeaponsTrigger, controlledHeroEid)
activateShowAllWeapons()
currentGunEid.subscribe(function(eid) {
  if (eid != ecs.INVALID_ENTITY_ID)
    activateShowAllWeapons()
})

let playerDynamic = @(){
  watch = [showAllWeapons, showShortBlock]
  flow = FLOW_VERTICAL
  halign = ALIGN_RIGHT
  gap = fsh(2)
  children = [
    showAllWeapons.get() ? weaponItems : null,
    shortPlayerBlock
  ]
}

function playerBlock() {
  let playerDynamicUi = !showVehicleWeapons.get() ? playerDynamic : null
  let vehicleBlockUi = showVehicleWeapons.get() || mobileRespawnOccupiedSeats.get() != null
    ? vehicleBlock : null
  return {
    watch = [ showVehicleWeapons, mobileRespawnOccupiedSeats ]
    flow = FLOW_VERTICAL
    halign = ALIGN_RIGHT
    gap = fsh(0.5)
    children = [
      playerDynamicUi
      vehicleBlockUi
      vitalPlayerInfo
    ]
  }
}

return playerBlock