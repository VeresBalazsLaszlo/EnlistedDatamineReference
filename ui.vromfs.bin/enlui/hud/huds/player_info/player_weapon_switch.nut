import "%ui/hud/huds/player_info/player_weapon_hotkey.nut" as getWeaponHotkeyWidget
from "%ui/hud/state/total_medkits.nut" import selfHealMedkits
from "%ui/hud/state/hero_weapons.nut" import fastThrowExclusive, EWS_NUM
from "%ui/hud/huds/player_info/player_weapon_widget.nut" import weaponWidget, weaponWidgetDefaultWidth
from "%ui/hud/state/flask.nut" import hasHeroFlask, heroFlaskInfo
from "%ui/hud/state/binocular.nut" import hasHeroBinocular, binocularInfo
from "%ui/hud/state/gas_mask.nut" import hasHeroGasMask, gasMaskInfo
from "%ui/ui_library.nut" import *

let { weaponSlots } = require("%ui/hud/state/hero_weapons.nut")

const equipItemsGap = hdpx(4)

let mainWeaponHotkeys = Computed(function() {
  let weaponHotkeys = array(4).map(@(_, i) $"Human.Weapon{i + 1}")
  weaponHotkeys.append(fastThrowExclusive.get() ? "Human.Throw" : "Human.GrenadeNext")
  weaponHotkeys.append("Human.SpecialItemSlot")
  return weaponHotkeys
})

function mkWeaponHotkeys(weaponHotkeys) {
  let children = array(EWS_NUM)
  foreach (idx, weaponState in (weaponSlots ?? [])) {
    if (idx not in children)
      continue
    let hint = getWeaponHotkeyWidget(weaponHotkeys[idx], weaponState != null)
    children[idx] = weaponWidget({ weaponState, idx, hint })
  }
  return children
}

let binocularWidget = weaponWidget({
  weaponState = binocularInfo
  hint = getWeaponHotkeyWidget("Human.UseBinocular", true)
  doMemoize = true
})

let gasMaskWidget = weaponWidget({
  weaponState = gasMaskInfo
  hint = getWeaponHotkeyWidget("Human.UseBinocular", true)
  doMemoize = true
})

let flaskHint = getWeaponHotkeyWidget("Inventory.UseFlask", true)

function weaponItems() {
  let children = mkWeaponHotkeys(mainWeaponHotkeys.get())

  if (hasHeroBinocular.get())
    children.append(binocularWidget)
  else if (hasHeroGasMask.get())
    children.append(gasMaskWidget)

  let equipCount = (selfHealMedkits.get() > 0 ? 1 : 0) + (hasHeroFlask.get() ? 1 : 0)
  if (equipCount > 0) {
    let equipChildren = []
    let width = weaponWidgetDefaultWidth / equipCount - (equipCount > 1 ? equipItemsGap : 0)

    if (selfHealMedkits.get() > 0)
      equipChildren.append(weaponWidget({
        weapon = {
          name = loc("hud/medkits")
          curAmmo = selfHealMedkits.get()
        }
        hint = getWeaponHotkeyWidget("Inventory.UseMedkit", true)
        width
      }))

    if (hasHeroFlask.get())
      equipChildren.append(weaponWidget({
        weaponState = heroFlaskInfo
        hint = flaskHint
        width
      }))

    children.append({
      flow = FLOW_HORIZONTAL
      gap = equipItemsGap
      children = equipChildren
    })
  }

  return {
    watch = [mainWeaponHotkeys, selfHealMedkits, hasHeroFlask, hasHeroBinocular, hasHeroGasMask]
    flow = FLOW_VERTICAL
    valign = ALIGN_BOTTOM
    halign = ALIGN_RIGHT
    gap = equipItemsGap
    children
  }
}


return {
  weaponItems
}
