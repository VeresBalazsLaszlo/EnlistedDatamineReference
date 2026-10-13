from "%ui/meta/curCampaign.nut" import allCampaigns, allArmies
from "%ui/userstats/userstat.nut" import userstatStats
from "%ui/style/designConst.nut" import bigPadding
from "%ui/profile/profilePkg.nut" import mkMapsListPopupUi, mkPlayerStatistics
from "%ui/profile/rankState.nut" import playerRank, markOpenedRank
from "%ui/components/textButton.nut" import Regular
from "%ui/ui_library.nut" import *

let decoratorUi = require("%ui/profile/decoratorUi.nut")
let modalPopupWnd = require("%ui/components/modalPopupWnd.nut")


const WND_UID = "campaignsListPopup"
let isMapsListOpened = Watched(false)


let closeMapsListPopup = @() modalPopupWnd.remove(WND_UID)

let openMapsListPopup = @(event, campaigns)
  modalPopupWnd.add(event.targetRect, {
    uid = WND_UID
    popupHalign = ALIGN_LEFT
    onAttach = @() isMapsListOpened.set(true)
    onDetach = @() isMapsListOpened.set(false)
    children = mkMapsListPopupUi(campaigns, closeMapsListPopup)
  })


function toggleMapsListPopup(event, campaigns) {
  if (isMapsListOpened.get())
    closeMapsListPopup()
  else
    openMapsListPopup(event, campaigns)
}


let mkPlayerCardUi = @(campaigns) {
  size = FLEX
  flow = FLOW_VERTICAL
  gap = bigPadding
  padding = bigPadding
  children = mkPlayerStatistics(userstatStats,
    Regular(loc("showFilters"), @(event) toggleMapsListPopup(event, campaigns), {
      hotkeys = [["^J:Start", { description = { skip = true }}]]
    })
  )
}

let notEmptyStatisticCampaigns = Computed(function(prev) {
  if (prev == FRP_INITIAL)
    prev = []

  let res = []
  foreach (campId in allCampaigns.get()) {
    let armiesCamp = allArmies.get()?[campId] ?? []
    foreach (armyId in armiesCamp) {
      let { battles = 0 } = userstatStats.get()?.stats["global"][armyId]
      if (battles > 0) {
        res.append(campId)
        break
      }
    }
  }
  return isEqual(prev, res) ? prev : res
})

return @() {
  size = FLEX
  flow = FLOW_VERTICAL
  gap = bigPadding
  onDetach = @() markOpenedRank(playerRank.get()?.rank ?? 0)
  children = [
    decoratorUi
    mkPlayerCardUi(notEmptyStatisticCampaigns)
  ]
}
