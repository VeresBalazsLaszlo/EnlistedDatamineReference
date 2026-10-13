import "%ui/profile/anoDecoratorUi.nut" as anoDecoratorUi
from "%ui/meta/curCampaign.nut" import allCampaigns
from "%ui/style/designConst.nut" import smallOffset
from "%ui/profile/anoProfileState.nut" import anoProfileData
from "%ui/profile/profilePkg.nut" import mkMapsListPopupUi, mkPlayerStatistics
from "%ui/components/textButton.nut" import Regular
from "%ui/ui_library.nut" import *

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


return @() {
  size = FLEX
  flow = FLOW_VERTICAL
  gap = smallOffset
  children = [
    anoDecoratorUi()
    {
      size = FLEX
      flow = FLOW_HORIZONTAL
      gap = smallOffset
      children = mkPlayerStatistics(anoProfileData,
        Regular(loc("showFilters"), @(event) toggleMapsListPopup(event, allCampaigns))
      )
    }
  ]
}