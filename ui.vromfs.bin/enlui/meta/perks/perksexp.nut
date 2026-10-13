from "%ui/meta/configs.nut" import mkComputedConfigGet
from "%ui/ui_library.nut" import *

let perkLevelsGrid = mkComputedConfigGet("perk_levels_grid")

let getExpToNextLevel = @(level, maxLevel, expToLevel)
  level < maxLevel ? (expToLevel?[level] ?? 0) : 0

let getGoldToNextLevel = @(level, maxLevel, lvlsCfg) lvlsCfg == null ? 0
  : level < (maxLevel ?? lvlsCfg.MAX_LEVEL) ? (lvlsCfg.goldToLevel?[level] ?? lvlsCfg.goldToPerkOnMaxLevel)
  : lvlsCfg.goldToPerkOnMaxLevel

let getNextLevelData = kwarg(function(level, maxLevel, exp, lvlsCfg) {
  let expToLevel = getExpToNextLevel(level, maxLevel, lvlsCfg.expToLevel)
  let goldToLevel = getGoldToNextLevel(level, maxLevel, lvlsCfg)
  if (expToLevel <= 0 || goldToLevel <= 0)
    return null

  let needExp = expToLevel - exp
  return {
    exp = needExp
    cost = max(goldToLevel * needExp / expToLevel, 1)
  }
})

return {
  perkLevelsGrid
  getNextLevelData
}
