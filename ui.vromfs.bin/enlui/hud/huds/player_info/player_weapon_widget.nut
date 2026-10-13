import "%ui/components/icon3d.nut" as iconWidget
from "%ui/hud/state/hero_weapons.nut" import heroCurrentGunSlot, heroModsByWeaponSlot
from "%ui/style/fontsStyle.nut" import fontSub
from "%ui/hud/style.nut" import SELECTION_BORDER_COLOR
from "%ui/hud/huds/player_info/style.nut" import blurBack
from "%ui/ui_library.nut" import *

let { weaponSlotsStatic } = require("%ui/hud/state/hero_weapons.nut")

const ammoColor = Color(100,100,100,50)
const curColor = Color(180,200,230,180)
const color = Color(168,168,168,150)
let curBorderColor = SELECTION_BORDER_COLOR



function itemAppearing(duration=0.2) {
  return {prop=AnimProp.opacity, from=0, to=1, duration=duration, play=true, easing=InOutCubic}
}
let wWidth = hdpx(280)
let aHgt = calc_str_box("A", fontSub)[1]*2 
let wHeight = max(aHgt+hdpx(2), hdpx(40))

let weapIdPadding = freeze([0,0,hdpx(2),hdpx(2)])
function weaponId(weaponName, isCurrent, params={width=FLEX height=wHeight}) {
  let size = [params?.width ?? FLEX, params?.height ?? wHeight]
  let {padding = weapIdPadding, margin = null} = params
  return {
    size
    padding
    margin
    clipChildren = true
    children = {
      behavior = Behaviors.Marquee
      size = FLEX
      valign = ALIGN_BOTTOM
      children = @() {
        watch = isCurrent
        size = SIZE_TO_CONTENT
        halign = ALIGN_LEFT
        rendObj = ROBJ_TEXT
        text = loc(weaponName)
        fontFx = FFT_BLUR
        fontFxColor = Color(0,0,0,30)
        color = isCurrent.get() ? curColor : color
      }.__update(fontSub)
    }
  }
}
let wAmmoDef = {width=SIZE_TO_CONTENT height=SIZE_TO_CONTENT}
let weapAmmoAnimations = [ { prop=AnimProp.scale, from=[1.1,1.3], to=[1,1], duration=0.2, play=true, easing=OutCubic } ]

function weaponAmmo(watchedWeapon, isCurrent, params=wAmmoDef, idx = null) {
  let size = [params?.width ?? SIZE_TO_CONTENT, params?.height ?? SIZE_TO_CONTENT]
  let totalAmmoW = Computed(@() watchedWeapon.get()?.totalAmmo ?? 0)
  let curAmmoW = Computed(@() watchedWeapon.get()?.curAmmo ?? 0)
  let addAmmoW = Computed(@() watchedWeapon.get()?.additionalAmmo ?? 0)
  let {margin = hdpx(5), halign = ALIGN_RIGHT, hplace = ALIGN_RIGHT} = params
  return function(){
    let addAmmo = addAmmoW.get()
    let curAmmo = curAmmoW.get() + addAmmo
    let totalAmmo = max(0, totalAmmoW.get() - addAmmo)
    let isReloadable = watchedWeapon.get()?.isReloadable ?? weaponSlotsStatic?[idx].isReloadable

    let ammo_string = (totalAmmo + curAmmo <= 0 )
      ? ""
      : isReloadable
        ? $"{curAmmo}/{totalAmmo}"
        : curAmmo

    return {
      rendObj = ROBJ_TEXT
      watch = [totalAmmoW, curAmmoW, addAmmoW, isCurrent]
      text = ammo_string
      color = isCurrent.get() ? curColor : ammoColor
      size
      clipChildren=true
      halign
      hplace
      transform  = {pivot =[0.5,0.5]}
      margin
      animations = weapAmmoAnimations
    }
  }
}


let silhouetteDefColor=[200,200,200,200]
let silhouetteEmptyColor=[0,0,0,120]
let silhouetteInactiveColor=[0,0,0,200]
let outlineDefColor=[0,0,0,0]
let outlineEmptyColor=[200,200,200,0]
let outlineInactiveColor=[200,200,200,0]

let weaponWidgetAnims = freeze([
  {prop=AnimProp.opacity, from=1, to=0, duration=0.3, playFadeOut=true}
  itemAppearing()
])

function iconCtor(itemInfo, isLoadable, isAmmoLoaded, width, height, mods=null) {
  return iconWidget(itemInfo, {
      width
      height
      hplace = ALIGN_CENTER
      shading = "silhouette"
      silhouette = isAmmoLoaded ? silhouetteDefColor : silhouetteEmptyColor
      outline = isLoadable ? outlineDefColor : outlineEmptyColor
      silhouetteInactive = silhouetteInactiveColor
      outlineInactive = outlineInactiveColor
    }, mods)
}
let iconCtorMemoized  = memoize(iconCtor)

let currentBorder = freeze({ size = FLEX, rendObj = ROBJ_FRAME, borderWidth = hdpx(1), color = curBorderColor })

function weaponWidget(weapon=null, idx=null, hint = null, width = wWidth, height = wHeight, weaponState = null, doMemoize=false) {
  let weaponWatched = weaponState != null ? Computed(@() (weapon ?? {}).__merge(weaponState.get() ?? {})) : WatchedRo(weapon ?? {})
  let name = Computed(@() weapon?.name ?? weaponSlotsStatic?[idx].name ?? weaponWatched.get()?.name)
  let isCurrentW = Computed(@() heroCurrentGunSlot.get()!=null && heroCurrentGunSlot.get() == idx)
  let controlHint = hint
  let hintsPadding = wHeight + hdpx(2)
  let borderComp = @() {size = FLEX children  = isCurrentW.get() ? currentBorder : null, watch=isCurrentW}
  function weaponHudIcon() {
    let sInfo = weaponSlotsStatic?[idx]
    let isLoadable = sInfo?.isReloadable ?? weaponWatched.get()?.isReloadable ?? ((weaponWatched.get()?.maxAmmo ?? 0) > 0)
    let isAmmoLoaded = !isLoadable || ((weaponWatched.get()?.curAmmo ?? 0) > 0)
    let ctor = doMemoize || (sInfo != null && !weaponWatched.get()?.subsidiaryGunEid) ? iconCtorMemoized : iconCtor
    return {
      size = FLEX
      watch = [heroModsByWeaponSlot, name]
      children = ctor(weaponSlotsStatic?[idx] ?? weaponWatched.get(), isLoadable, isAmmoLoaded, hdpx(128), height - hdpx(2) * 2, weaponWatched.get()?.subsidiaryGunEid ? heroModsByWeaponSlot.get()?[idx].iconAttachments : null)
    }
  }
  let ammo = weaponWatched != null ? weaponAmmo(weaponWatched, isCurrentW, {width = SIZE_TO_CONTENT height=wHeight/2 hplace=ALIGN_RIGHT vplace = ALIGN_CENTER}, idx) : null
  let weapId = @() weaponId(name.get(), isCurrentW, { size=[FLEX,height/2]}).__update({watch = name})

  return freeze({
    size = [width,height]
    animations = weaponWidgetAnims
    flow = FLOW_HORIZONTAL
    children = [
      {
        size = [width - hintsPadding, height]
        clipChildren = true
        children = [
          blurBack,
          borderComp,
          {
            size = [width-hintsPadding,height]
            clipChildren = true
            valign = ALIGN_CENTER
            children = {
              size = FLEX
              padding=hdpx(2)
              children = [
                weaponHudIcon,
                {
                  flow = FLOW_HORIZONTAL
                  size = FLEX
                  valign = ALIGN_CENTER
                  children = [ weapId, ammo ]
                }
              ]
            }
          }
        ]
      }
      {size = flex(0.01) minWidth=hdpx(1)}
      controlHint
    ]
  })
}

return {
  weaponWidget = kwarg(weaponWidget)
  weaponWidgetDefaultWidth = wWidth
}
