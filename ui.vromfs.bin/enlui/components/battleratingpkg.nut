import "%ui/components/colorize.nut" as colorize
from "%ui/style/designConst.nut" import defTxtColor, brightAccentColor
from "%sqstd/math.nut" import getRomanNumeral
from "%ui/ui_library.nut" import *

let mkBattleRating = @(tier, override = {}) tier < 1 ? null : {
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  color = defTxtColor
  text = loc("battleRating/full", { tier = colorize(brightAccentColor, getRomanNumeral(tier)) })
}.__update(override)

let mkBattleRatingShort = @(tier) {
  rendObj = ROBJ_TEXT
  color = brightAccentColor
  text = loc("battleRating/short", { tier = getRomanNumeral(tier) })
}

return {
  mkBattleRating
  mkBattleRatingShort
}
