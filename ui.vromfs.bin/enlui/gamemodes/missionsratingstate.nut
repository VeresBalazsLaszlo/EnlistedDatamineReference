from "%ui/meta/clientApi.nut" import rate_mission
from "%ui/meta/servProfile.nut" import missionRates
from "%ui/ui_library.nut" import *

let isMissionsRatingOpened = mkWatched(persist, "isMissionsRatingOpened", false)
let lastPlayedMissionData = Watched(null)


enum RatesStatus {
  UNDEFINED = 0
  BAN = 1
  DISLIKE = 2
  LIKE = 3
}

let holdActions = {}

const ALL_MISSIONS = "all_missions"

let missionRatesCfg = [
  {
    id = ALL_MISSIONS
    locId = "front/all"
    campaigns = ["normandy", "berlin", "tunisia", "stalingrad", "moscow", "rzhev", "pacific", "burma", "ardennes", "manchuria"]
  }
  {
    id = "western_front"
    locId = "front/western"
    campaigns = ["normandy", "tunisia", "ardennes"]
    limits = {
      [RatesStatus.BAN] = 3,
      [RatesStatus.DISLIKE] = 10,
      [RatesStatus.LIKE] = 10
    }
  }
  {
    id = "eastern_front"
    locId = "front/eastern"
    campaigns = ["stalingrad", "moscow", "rzhev", "berlin"]
    limits = {
      [RatesStatus.BAN] = 2,
      [RatesStatus.DISLIKE] = 15,
      [RatesStatus.LIKE] = 15
    }
  }
  {
    id = "pacific_front"
    locId = "front/pacific"
    campaigns = ["pacific", "burma"]
    limits = {
      [RatesStatus.BAN] = 1,
      [RatesStatus.DISLIKE] = 5,
      [RatesStatus.LIKE] = 5
    }
  }
  {
    id = "manchuria_front"
    locId = "front/manchuria"
    campaigns = ["manchuria"]
    limits = {
      [RatesStatus.BAN] = 1,
      [RatesStatus.DISLIKE] = 3,
      [RatesStatus.LIKE] = 3
    }
  }
]


let missionRatesData = Computed(@() missionRates.get().map(@(rateData) rateData.rate))

function mkFrontNamesByCampaign(ratesCfg) {
  let res = {}
  foreach (rateCfg in ratesCfg)
    if (rateCfg.id != ALL_MISSIONS)
      foreach (campaign in rateCfg.campaigns)
        res[campaign] <- rateCfg.locId

  return res
}
let frontByCampaign = mkFrontNamesByCampaign(missionRatesCfg)


function getDislikedScenes() {
  let res = []
  foreach (rateData in missionRates.get()) {
    if (rateData.rate == RatesStatus.DISLIKE) {
      res.append({ tags = rateData.guid.split(",") })
    }
  }
  return res
}

function setRate(missionId, rate) {
  if (missionId in holdActions)
    return

  holdActions[missionId] <- true
  rate_mission(missionId, rate, @(_) holdActions.$rawdelete(missionId))
}

return freeze({
  isMissionsRatingOpened
  missionRatesData
  RatesStatus
  missionRatesCfg
  frontByCampaign
  getDislikedScenes
  setRate
  getMissionRate = @(rates, id) rates?[id] ?? RatesStatus.UNDEFINED
  lastPlayedMissionData
})
