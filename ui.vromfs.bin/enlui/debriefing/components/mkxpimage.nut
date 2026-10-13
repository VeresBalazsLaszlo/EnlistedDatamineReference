import "%ui/components/armiesPresentation.nut" as armiesPresentation
from "%ui/ui_library.nut" import *

let winImagePath = @(size) "ui/uiskin/battlehero/debriefing_awards_winner.avif:{0}:{0}".subst(size.tointeger())
let battleHeroImagePath = @(size) "ui/uiskin/battlehero/debriefing_awards_mvp.avif:{0}:{0}".subst(size.tointeger())
let boosterXpImagePath = @(size) "ui/skin#xp_booster.svg:{0}:{0}".subst(size.tointeger())
let premiumImagePath = @(size) "ui/skin#currency/enlisted_prem.svg:{0}:{0}".subst(size.tointeger())
let premiumSquadImagePath = @(size, armyId)
  "{0}:{1}:{1}".subst(armiesPresentation?[armyId].premIcon ?? "ui/skin#icons/ussr/prem_squad_ussr.svg", size.tointeger())

let xpImage = @(size, path) {
  rendObj = ROBJ_IMAGE
  size = [size, size]
  image = Picture(path)
}

return {
  mkWinXpImage = @(size) xpImage(size, winImagePath(size))
  mkBattleHeroAwardXpImage = @(size) xpImage(size, battleHeroImagePath(size))
  mkPremiumAccountXpImage = @(size) xpImage(size, premiumImagePath(size))
  mkPremiumSquadXpImage = @(size, armyId) xpImage(size, premiumSquadImagePath(size, armyId))
  mkBoosterXpImage = @(size) xpImage(size, boosterXpImagePath(size))
}
