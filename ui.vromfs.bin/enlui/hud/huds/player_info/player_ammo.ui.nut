from "%ui/style/fontsStyle.nut" import fontBody, fontSub
from "%ui/hud/huds/tips/tipComponent.nut" import mkInputHintBlock
from "%ui/hud/state/hero_weapons.nut" import hasWeapon, curWeaponIsReloadable, curWeaponAmmo, curWeaponIsDualMag, curWeaponAdditionalAmmo, curWeaponTotalAmmo, curWeaponAltAmmo
  , curWeaponAltTotalAmmo, curWeaponIsModActive, curWeaponHasAltShot, curWeaponIconByHolders, curWeaponCurAmmoHolderIndex, curWeaponAmmoByHolders, curGunMod
from "%ui/hud/huds/player_info/style.nut" import blurBack, DEFAULT_TEXT_COLOR
from "%ui/ui_library.nut" import *
from "%ui/hud/state/attached_gun_state.nut" import attachedGunCurAmmo

let heightTxt = calc_str_box("auto", fontBody)[1]
let ammoNumAnim = [
  { prop=AnimProp.scale, from=[1.25,1.4], to=[1,1], duration=0.25, play=true, easing=OutCubic }
]

const ALT_ICON_SIZE = hdpx(22)
const ALT_SECONDARY_ICON_SIZE = hdpx(19)

let weapModToggleHint = mkInputHintBlock("Human.WeapModToggle")
function weapModToggleTip() {
  return {
    watch = [curWeaponHasAltShot]
    vplace = ALIGN_CENTER
    children = curWeaponHasAltShot.get() ? [weapModToggleHint] : null
    padding = [0,heightTxt/2,0,0]
  }
}

let sep = {
  rendObj = ROBJ_TEXT
  text = "/"
}

let add = {
  rendObj = ROBJ_TEXT
  text = "+"
}

let ammoText = @(txt, styles) {
  rendObj = ROBJ_TEXT
  text = txt
  key = txt
  transform = {
    pivot = [0.5, 0.5]
  }
  animations = ammoNumAnim
}.__update(styles)

const RIFLE_GRENADE_ICON = "!ui/uiskin/item_rifle_grenade.svg"
const FLAMETHROWER_ICON = "!ui/uiskin/flametrooper.svg"

let ammoTypeImage = memoize(@(size, iconName) freeze({
  rendObj = ROBJ_IMAGE
  size = [size,size]
  image = Picture("{0}:{1}:{1}".subst(iconName, size.tointeger()))
  valign = ALIGN_CENTER
  halign = ALIGN_CENTER
  margin = hdpx(5)
}))

let ammoCmp = @(curAmmo, additionalAmmo, totalAmmo, styles, icon = null) {
  size = SIZE_TO_CONTENT
  children = [
    styles.useBlur ? blurBack : null,
    {
      size  = [SIZE_TO_CONTENT, heightTxt]
      padding = const [0,hdpx(2)]
      flow  = FLOW_HORIZONTAL
      halign = ALIGN_RIGHT
      valign = ALIGN_CENTER
      gap = heightTxt/10
      children = [
        icon
        curAmmo != null ? ammoText(curAmmo, styles.curAmmo) : null
        curAmmo != null && additionalAmmo != null ? add.__merge(styles.add) : null
        additionalAmmo != null ? ammoText(additionalAmmo, styles.additionalAmmo) : null
        curAmmo != null || additionalAmmo != null ? sep.__merge(styles.sep) : null
        ammoText(max(0, totalAmmo - (additionalAmmo ?? 0)), styles.totalAmmo)
      ]
    }
  ]
}


let mkStyles = @() {
  curAmmo = {color = DEFAULT_TEXT_COLOR}.__update(fontBody)
  sep = {color = DEFAULT_TEXT_COLOR}.__update(fontSub)
  totalAmmo = {color = DEFAULT_TEXT_COLOR}.__update(fontSub)
  add = {color = DEFAULT_TEXT_COLOR}.__update(fontSub)
  additionalAmmo = {color = DEFAULT_TEXT_COLOR}.__update(fontSub)
  useBlur = true
}
let defMainStyles = mkStyles()

let defSecondaryStyles = mkStyles()
defSecondaryStyles.curAmmo.__update(fontSub)

let ammoCmpHgt = calc_comp_size(ammoCmp(1,2,3, defMainStyles))[1]

function mkAmmoInfo(mainStyles = {}, secondaryStyles = {}) {
  mainStyles = defMainStyles.__merge(mainStyles)
  secondaryStyles = defSecondaryStyles.__merge(secondaryStyles)
  return function() {
    if (attachedGunCurAmmo.get() != 0){
      return {
        watch = [attachedGunCurAmmo]
        valign = ALIGN_CENTER
        halign = ALIGN_RIGHT
        flow = FLOW_VERTICAL
        size = SIZE_TO_CONTENT
        children = [
          mainStyles.useBlur ? blurBack : null,
          {
            size  = [SIZE_TO_CONTENT, heightTxt]
            padding = const [0,hdpx(2)]
            flow  = FLOW_HORIZONTAL
            halign = ALIGN_RIGHT
            valign = ALIGN_CENTER
            gap = heightTxt/10
            children = ammoText(attachedGunCurAmmo.get(), mainStyles.totalAmmo)
          }
        ]
      }
    }
    if (!hasWeapon.get() || !curWeaponIsReloadable.get())
      return {
        watch = [hasWeapon, curWeaponIsReloadable, attachedGunCurAmmo]
        size = [0, ammoCmpHgt]
      }

    let watch = [
      attachedGunCurAmmo, hasWeapon, curWeaponIsReloadable, curWeaponAmmo, curWeaponIsDualMag,
      curWeaponAdditionalAmmo, curWeaponTotalAmmo, curWeaponHasAltShot
    ]
    let curAmmo = curWeaponAmmo.get()
    let additionalAmmo = curWeaponIsDualMag.get() ? curWeaponAdditionalAmmo.get() : null
    let totalAmmo = curWeaponTotalAmmo.get()
    if (!curWeaponHasAltShot.get()) {
      let iconByHolders = curWeaponIconByHolders.get()
      let ammoByHolders = curWeaponAmmoByHolders.get()
      let ammoByHoldersLen = ammoByHolders.len()
      let curAmmoHolderIndex = curWeaponCurAmmoHolderIndex.get()
      let curTotalAmmo = ammoByHolders?[curAmmoHolderIndex] ?? totalAmmo
      let curAmmoIconName = iconByHolders?[curAmmoHolderIndex] ?? ""
      let curAmmoIcon = curAmmoIconName != "" ? ammoTypeImage(ALT_ICON_SIZE, curAmmoIconName) : null

      local children = [ ammoCmp(curAmmo, additionalAmmo, curTotalAmmo, mainStyles, curAmmoIcon) ]
      for (local i = 0; i < ammoByHoldersLen; i++) {
        if (i == curAmmoHolderIndex || ammoByHolders[i] <= 0)
          continue

        let ammoIconName = iconByHolders?[i] ?? ""
        let ammoIcon = ammoIconName != ""
                     ? ammoTypeImage(ALT_SECONDARY_ICON_SIZE, ammoIconName)
                     : null
        let ammoCounter = ammoCmp(null, null, ammoByHolders[i], secondaryStyles, ammoIcon)
        children.append(ammoCounter)
      }

      watch.append(curWeaponIconByHolders, curWeaponCurAmmoHolderIndex, curWeaponAmmoByHolders)

      return {
        watch
        valign = ALIGN_CENTER
        halign = ALIGN_RIGHT
        flow = FLOW_VERTICAL
        children
      }
    }

    watch.append(curWeaponAltAmmo, curWeaponAltTotalAmmo, curWeaponIsModActive, curGunMod)
    let altCurAmmo = curWeaponAltAmmo.get()
    let altTotalAmmo = curWeaponAltTotalAmmo.get()
    let isModActive = curWeaponIsModActive.get()
    let modIconName = curGunMod.get()?.weapType == "flamethrower" ? FLAMETHROWER_ICON : RIFLE_GRENADE_ICON
    let mainAmmoIcon = isModActive ? ammoTypeImage(ALT_ICON_SIZE, modIconName) : null
    let altAmmoIcon = !isModActive ? ammoTypeImage(ALT_SECONDARY_ICON_SIZE, modIconName) : null
    return {
      watch
      flow = FLOW_HORIZONTAL
      valign = ALIGN_CENTER
      children = [
        weapModToggleTip
        {
          flow = FLOW_VERTICAL
          halign = ALIGN_RIGHT
          children = [
            ammoCmp(curAmmo, additionalAmmo, totalAmmo, mainStyles, mainAmmoIcon)
            ammoCmp(altCurAmmo, additionalAmmo, altTotalAmmo, secondaryStyles, altAmmoIcon)
          ]
        }
      ]
    }
  }
}

return mkAmmoInfo