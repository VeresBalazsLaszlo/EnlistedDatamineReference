from "%ui/soldiers/model/config/gameProfile.nut" import allArmiesInfo
from "%ui/ui_library.nut" import *

function getArmyName(armyId) {
  let { country = null } = allArmiesInfo.get()?[armyId]
  return country != null ? loc($"country/{country}") : armyId
}

return {
  getArmyName
}
