import "%ui/components/icon3d.nut" as iconWidget
import "%dngscripts/ecs.nut" as ecs
from "net" import get_sync_time
from "%ui/style/fontsStyle.nut" import fontSub
from "%ui/hud/style.nut" import SELECTION_BORDER_COLOR
from "%ui/hud/huds/player_info/style.nut" import blurBack
from "%ui/style/designConst.nut" import smallPadding
from "%ui/ui_library.nut" import *

const ammoColor = Color(100,100,100,50)
const curColor = Color(180,200,230,180)
const color = Color(168,168,168,150)
let curBorderColor = SELECTION_BORDER_COLOR
const nextBorderColor = Color(200, 200, 200, 100)


function itemAppearing(duration=0.2) {
  return {prop=AnimProp.opacity, from=0, to=1, duration=duration, play=true, easing=InOutCubic}
}
const wWidth = hdpx(280)
let aHgt = calc_str_box("A", fontSub)[1]*2 
let wHeight = max(aHgt+hdpxi(2), hdpxi(40))


function weaponId(weapon, turretsAmmo) {
  let loadedGunInGroupEid = Computed(@() turretsAmmo.get()?[weapon.groupName].firstLoadedGunInGroup)
  return @() {
    watch = loadedGunInGroupEid
    size = FLEX_H
    vplace = ALIGN_CENTER
    rendObj = ROBJ_TEXT
    color = weapon?.isCurrent ? curColor : color
    text = loc(weapon?.namesInGroup[loadedGunInGroupEid.get()] ?? weapon.name)
    fontFx = FFT_BLUR
    fontFxColor = Color(0,0,0,30)
    behavior = Behaviors.Marquee
  }.__update(fontSub)
}


function weaponAmmo(weapon, turretsAmmo) {
  let combinedAmmo = Computed(function() {
    let data = turretsAmmo.get()
    if (weapon?.subGroupGunEids != null) {
      local subGroupAmmo = 0
      local subReloadAmmo = 0
      foreach (eid in weapon.subGroupGunEids) {
        subGroupAmmo += data?[eid].curAmmo ?? 0
        subReloadAmmo += data?[eid].totalAmmo ?? 0
      }
      return {
        groupAmmo = subGroupAmmo
        reloadAmmo = subReloadAmmo
      }
    }
    return (data?[weapon.gunEid] ?? {}).__merge({
      groupAmmo = data?[weapon.groupName].groupAmmo
      reloadAmmo = data?[weapon.groupName].reloadAmmo
    })
  })

  let instant = weapon?.instant
  let showZeroAmmo = weapon?.showZeroAmmo ?? false
  return function() {
    local { curAmmo = 0, totalAmmo = 0, ammoByBullet = [], reloadAmmo = 0,
      groupAmmo = 0, firstStageAmmo = 0 } = combinedAmmo.get()
    let setAmmo = ammoByBullet?[weapon?.setId]
    totalAmmo = reloadAmmo ?? totalAmmo
    if (setAmmo != null) {
      curAmmo = weapon?.isReloadable && weapon?.isCurrent ? curAmmo : 0
      totalAmmo = weapon?.isReloadable && weapon?.isCurrent ? totalAmmo
        : ammoByBullet?[weapon?.setId] ?? totalAmmo
    }
    curAmmo = groupAmmo ?? curAmmo
    local firstStage = ""
    if (!weapon?.isCurrent)
      firstStageAmmo = 0
    else if (firstStageAmmo > 0) {
      firstStageAmmo = min(firstStageAmmo, totalAmmo)
      firstStage = $"{firstStageAmmo}+"
      totalAmmo = totalAmmo - firstStageAmmo
    }
    let ammo_string = (totalAmmo + curAmmo + firstStageAmmo <= 0 && !showZeroAmmo) ? ""
      : instant ? $"{firstStage}{(totalAmmo + curAmmo)}"
      : (weapon?.isReloadable ?? false) ? $"{curAmmo}/{firstStage}{totalAmmo}"
      : $"{firstStage}{totalAmmo}"
    return {
      watch = combinedAmmo
      size = FLEX_H
      children = {
        rendObj = ROBJ_TEXT
        text = ammo_string
        color = weapon?.isCurrent ? curColor : ammoColor
        size = FLEX_H
        key = totalAmmo + curAmmo
        halign = ALIGN_RIGHT
        transform  = { pivot = [0.5,0.5] }
        animations = [{ prop = AnimProp.scale, from = [1.1,1.3], to = [1,1],
          duration = 0.2, play = true, easing = OutCubic }]
      }
    }
  }
}


let silhouetteDefColor=[200,200,200,200]
let silhouetteInactiveColor=[0,0,0,200]
let outlineDefColor=[0,0,0,0]
let outlineInactiveColor=[200,200,200,0]

let weaponWidgetAnims = [
  {prop=AnimProp.opacity, from=1, to=0, duration=0.3, playFadeOut=true}
  itemAppearing()
]

function iconCtorDefault(weapon, width, height) {
  return iconWidget(weapon, {
    width = width
    height = height
    hplace = ALIGN_CENTER
    shading = "silhouette"
    silhouette = silhouetteDefColor
    outline = outlineDefColor
    silhouetteInactive = silhouetteInactiveColor
    outlineInactive = outlineInactiveColor
  })
}

let currentBorder = { size = FLEX, rendObj = ROBJ_FRAME, borderWidth = 1, color = curBorderColor }
let nextBorder = { size = FLEX, rendObj = ROBJ_FRAME, borderWidth = 1, color = nextBorderColor, key = {}
  animations = [{ prop = AnimProp.opacity, from = 0.5, to = 1, duration = 1, play = true, loop = true, easing = CosineFull }] }

let mkReplenishmentProgress = @(from, to, duration, key) {
  margin = const [0, 0, 0, hdpx(10)]
  rendObj = ROBJ_PROGRESS_LINEAR
  imageHalign = ALIGN_CENTER
  imageValign = ALIGN_CENTER
  vplace = ALIGN_CENTER
  hplace = ALIGN_CENTER
  fValue = 0
  size = FLEX
  fgColor = Color(0,255,0)
  bgColor = Color(0,150,0)
  key
  animations = [
    { prop = AnimProp.fValue, from, to, duration, play = true }
  ]
}

function turretStowageReplenishmentTip(weapon, turretsReplenishment) {
  if (!weapon?.isControlled || !weapon?.isCurrent)
    return null
  let gunEid = weapon?.gunEid ?? ecs.INVALID_ENTITY_ID
  let turretReplenishmentState = Computed(@() turretsReplenishment.get()?[gunEid] ?? {})

  return function() {
    let { totalTime = -1, endTime = -1 } = turretReplenishmentState.get()
    let timeLeft = max(0, endTime - get_sync_time())
    let startProgress = totalTime > 0 ? max(0, 1 - timeLeft / totalTime) : 0
    const endProgress = 1
    let isReplenishing = endTime > 0
    return {
      watch = turretReplenishmentState
      valign = ALIGN_CENTER
      vplace = ALIGN_CENTER
      size = const [pw(80), hdpx(3)]
      children = isReplenishing
        ? mkReplenishmentProgress(startProgress, endProgress, timeLeft, turretReplenishmentState.get())
        : null
    }
  }
}


function weaponWidget(weapon, turretsAmmo, turretsReplenishment, hint = null,
  width = wWidth, height = wHeight, showHint = true, iconCtor = iconCtorDefault
) {
  let markAsSelected = weapon?.isEquiping || (weapon?.isCurrent && !weapon?.isHolstering)
  let borderComp = markAsSelected ? currentBorder
    : weapon?.isNext ? nextBorder
    : null

  let iconWidth = (height * 1.3).tointeger()
  let iconHeight = (height - smallPadding * 2).tointeger()
  let controlHint = showHint ? hint : null
  let hintsPadding = showHint ? wHeight + smallPadding : smallPadding

  return {
    size = [width, height]
    animations = weaponWidgetAnims
    flow = FLOW_HORIZONTAL
    children = [
      {
        size = [width - hintsPadding, height]
        clipChildren = true
        children = [
          blurBack
          borderComp
          {
            size = FLEX
            clipChildren = true
            valign = ALIGN_CENTER
            children = ((weapon?.name ?? "") != "")
              ? {
                  size = FLEX
                  padding = smallPadding
                  flow = FLOW_HORIZONTAL
                  gap = smallPadding
                  children = [
                    weaponId(weapon, turretsAmmo)
                    iconCtor(weapon, iconWidth, iconHeight)
                    {
                      size = const [hdpx(90), SIZE_TO_CONTENT]
                      flow = FLOW_VERTICAL
                      vplace = ALIGN_CENTER
                      children = [
                        weaponAmmo(weapon, turretsAmmo)
                        turretStowageReplenishmentTip(weapon, turretsReplenishment)
                      ]
                    }
                  ]
                }
              : null
          }
        ]
      }
      showHint ? {
        size = flex(0.01)
        minWidth = hdpx(1)
      } : null
      controlHint
    ]
  }
}

let vehicleWeaponWidget = kwarg(weaponWidget)

return freeze({
  vehicleWeaponWidget
  wWidth
  wHeight
  weaponWidgetAnims
})
