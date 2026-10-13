import "%ui/userstats/serverTime.nut" as serverTime
from "%ui/meta/servProfile.nut" import premium
from "%ui/soldiers/model/config/gameProfile.nut" import gameProfile
from "%ui/ui_library.nut" import *

let premiumEndTime = Computed(@() (premium.get()?.premium_data.endsAtMs ?? 0) / 1000)

let hasPremium = Computed(@() premiumEndTime.get() > serverTime.get())

let premiumBonusesFields = {
  premiumExpMul = 0.0
  maxSquadsInBattle = 0
  maxInfantrySquads = 0
  maxBikeSquads = 0
  maxVehicleSquads = 0
  maxTransportSquads = 0
  soldiersReserve = 0
}.map(@(def, key) Computed(@() gameProfile.get()?.premiumBonuses[key] ?? def))

let premiumActiveTime = Computed(@()
  max(premiumEndTime.get() - serverTime.get(), 0))

console_register_command(@() console_print(premiumActiveTime.get()), "meta.showPremiumLeft")

return {
  hasPremium
  premiumEndTime
  premiumActiveTime
}.__update(premiumBonusesFields)
