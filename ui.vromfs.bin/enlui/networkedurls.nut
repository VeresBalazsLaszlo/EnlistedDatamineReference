from "app" import get_circuit_conf

let circuitConf = get_circuit_conf()



let getStoreUrl = @() circuitConf?.storeUrl
let getPromoUrl = @() circuitConf?.promoUrl
let getReplayPortalUrl = @() circuitConf?.replayPortalUrl ?? "https://enlisted.net/en/replays"
let getShopApiUrl = @() circuitConf?.shopApiUrl

let getEventUrl = @() circuitConf?.eventUrl
let getPremiumUrl = @() circuitConf?.premiumUrl
let getBattlePassUrl = @() circuitConf?.battlePassUrl
let getSquadCashUrl = @() circuitConf?.squadCashUrl

return {
  getStoreUrl
  getPromoUrl
  getReplayPortalUrl
  getShopApiUrl
  getEventUrl
  getPremiumUrl
  getBattlePassUrl
  getSquadCashUrl
}
