import "%darg/helpers/hoverHoldAction.nut" as hoverHoldAction
from "%ui/style/fontsStyle.nut" import fontBody
from "%ui/components/defcomps.nut" import txt
from "%ui/soldiers/model/config/gameProfile.nut" import gameProfile
from "%ui/meta/curCampaign.nut" import allCampaigns
from "%ui/profile/medalsState.nut" import medalsByCampaign
from "%ui/style/cursors.nut" import setTooltip
from "%ui/profile/medalsPkg.nut" import mkMedalCard, mkDisabledMedalCard, mkMedalTooltip
from "%ui/profile/profilePkg.nut" import PROFILE_WIDTH
from "%ui/style/designConst.nut" import midPadding, bigPadding, blurBgFillColor
from "%ui/components/scrollbar.nut" import makeVertScroll, thinStyle
from "%ui/profile/unseenProfileState.nut" import seenMedals, markSeenMedal, markMedalsOpened
from "%ui/components/unseenComps.nut" import smallUnseenNoBlink
from "%ui/components/itemsInfo.nut" import getCampaignTitle
from "%ui/ui_library.nut" import *

const MAX_COLUMNS = 6

let mCardWidth = ((PROFILE_WIDTH - (MAX_COLUMNS - 1) * midPadding) / MAX_COLUMNS).tointeger()
const mIconSize = hdpx(160)

function mkMedalBlock(medal, isUnseen) {
  let { id, received = [], bgImage = null, stackImages = [] } = medal
  return {
    size = [mCardWidth, mCardWidth]
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    behavior = Behaviors.Button
    onHover = function(on) {
      setTooltip(on ? mkMedalTooltip(medal) : null)
      if (isUnseen)
        hoverHoldAction("merkSeenDecorator", id, @(v) markSeenMedal(v))(on)
    }
    xmbNode = XmbNode({
      canFocus = true
      wrap = false
      isGridLine=true
      scrollToEdge = [false, true]
    })
    children = received.len() > 0
      ? mkMedalCard(bgImage, stackImages, mIconSize)
      : mkDisabledMedalCard(bgImage, stackImages, mIconSize)
  }
}

function mkCampaignMedals(campaignId, medalsByCamp, unseen) {
  let campaignMedals = medalsByCamp?[campaignId] ?? []
  if (campaignMedals.len() == 0)
    return null

  return {
    size = FLEX_H
    flow = FLOW_VERTICAL
    halign = ALIGN_CENTER
    children = [
      {
        size = FLEX_H
        halign = ALIGN_CENTER
        rendObj = ROBJ_SOLID
        color = blurBgFillColor
        children = txt({
          text = getCampaignTitle(campaignId)
          margin = midPadding
        }).__update(fontBody)
      }
      wrap(campaignMedals.map(function(medal) {
        let isUnseen = medal.id in unseen
        return {
          children = [
            mkMedalBlock(medal, isUnseen)
            isUnseen ? smallUnseenNoBlink : null
          ]
        }
      }), {
        width = PROFILE_WIDTH
        hGap = midPadding
        vGap = midPadding
        halign = ALIGN_CENTER
      })
    ]
  }
}

function medalsListUi() {
  let medalsByCamp = medalsByCampaign.get()
  let { unseen = {}, unopened = {} } = seenMedals.get()
  return {
    xmbNode = XmbContainer({
      isGridLine = true
      canFocus = false
      wrap = false
      scrollSpeed = [0, 2.0]
    })
    watch = [medalsByCampaign, gameProfile, seenMedals, allCampaigns]
    size = FLEX
    margin = bigPadding
    onDetach = @() markMedalsOpened(unopened.keys())
    children = makeVertScroll({
      size = FLEX_H
      flow = FLOW_VERTICAL
      gap = midPadding
      children = allCampaigns.get().map(@(c) mkCampaignMedals(c, medalsByCamp, unseen))
    }, {
      styling = thinStyle
    })
  }
}

return {
  size = FLEX
  children = medalsListUi
}
