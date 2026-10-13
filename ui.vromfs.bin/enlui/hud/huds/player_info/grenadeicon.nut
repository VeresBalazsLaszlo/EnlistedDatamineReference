from "%ui/ui_library.nut" import *

let grenadeIconNames = {
  antitank = "grenade_antitank_icon.svg"
  fougasse = "grenade_fougasse_icon.svg"
  impact = "impact_grenade_icon.svg"
  incendiary = "grenade_incendiary_icon.svg"
  flame = "grenade_flame_icon.svg"
  lunge_mine = "ni_05_lunge_mine.svg"
  tnt_block = "item_tnt_block_exploder.svg"
  smoke = "grenade_smoke_icon.svg"
}

let GRENADES_ORDER = freeze([
  "antitank", "tnt_block", "lunge_mine", "impact", "incendiary", "fougasse", "flame", "smoke"
].reduce(@(tbl, val, idx) tbl.$rawset(val, idx), {}))

let grenadeIcon = memoize(function(gType, size) {
  return Picture("ui/skin#{0}:{1}:{1}"
    .subst(grenadeIconNames?[gType] ?? grenadeIconNames.fougasse, size))
})

let mkGrenadeIcon = memoize(@(grenadeType, size, color) grenadeType == null ? null : {
  rendObj = ROBJ_IMAGE
  size = [size, size]
  color
  image = grenadeIcon(grenadeType, size)
})

return {
  GRENADES_ORDER
  grenadeIcon
  mkGrenadeIcon
}