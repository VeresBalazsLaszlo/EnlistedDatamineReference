import "%ui/components/closeBtn.nut" as closeBtnBase
import "%ui/components/colorize.nut" as colorize
from "%sqstd/string.nut" import utf8ToUpper
from "%ui/style/fontsStyle.nut" import fontSub, fontBody
from "%ui/components/modalWindows.nut" import addModalWindow, removeModalWindow
from "%ui/soldiers/model/config/gameProfile.nut" import gameProfile
from "%ui/components/defcomps.nut" import noteTextArea
from "%ui/soldiers/unlockSquadScene.nut" import openUnlockSquadScene
from "%ui/meta/curCampaign.nut" import COMMON_CAMPAIGN
from "%ui/style/designConst.nut" import midPadding, smallPadding, tinyOffset, smallOffset,
  blurBgColor, defBgColor, activeTxtColor, accentTitleTxtColor, disabledTxtColor
from "%sqstd/underscore.nut" import arrayByRows
from "%ui/components/itemsInfo.nut" import getCampaignTitle
from "%ui/soldiers/model/newSquadsToShow.nut" import needNewSquadsWindow,
  markNewSquadsSeen, newSquadsPromo
from "%ui/ui_library.nut" import *

const WND_UID = "received_squads"
const SQUADS_PER_LINE = 2

const squadSlotWidth = hdpx(500)
let squadImageSize = [hdpx(160), hdpx(120)]

let closeButton = closeBtnBase({ onClick = @() markNewSquadsSeen() })

let mkImage = @(img, override = {}) {
  rendObj = ROBJ_IMAGE
  size = FLEX
  keepAspect = KEEP_ASPECT_FIT
  image = Picture(img)
}.__update(override)

function mkSquad(squadCfg) {
  let { image, nameLocId, titleLocId } = squadCfg
  let title = "{0}\n{1}".subst(loc(nameLocId),
    colorize(accentTitleTxtColor, loc(titleLocId)))
  return {
    rendObj = ROBJ_SOLID
    size = FLEX_H
    flow = FLOW_HORIZONTAL
    gap = smallPadding
    padding = smallPadding
    color = defBgColor
    children = [
      mkImage(image, { size = squadImageSize })
      noteTextArea(title)
        .__update({
          padding = smallPadding
          color = activeTxtColor
        }, fontSub)
    ]
  }
}

let curSquadStyle = {
  rendObj = ROBJ_SOLID
  color = Color(20,20,20,20)
}

function receivedSquadsUi() {
  let watch = [gameProfile, newSquadsPromo]
  let squadsByArmy = newSquadsPromo.get()
  if (squadsByArmy.len() == 0)
    return { watch }

  let { campaigns = {} } = gameProfile.get()
  let curCampaigns = []
  foreach (id, campaignData in campaigns) {
    let { armies = [] } = campaignData
    if (armies.len() > 0)
      curCampaigns.append({ id, armies, title = getCampaignTitle(id) })
  }
  curCampaigns.sort(@(a,b) (b.id == COMMON_CAMPAIGN) <=> (a.id == COMMON_CAMPAIGN) || a.id <=> b.id)

  let squadsBlock = []
  foreach (campaign in curCampaigns) {
    let isCurrent = campaign.id == COMMON_CAMPAIGN
    local campaignSquads = []
    foreach (army in campaign.armies) {
      let armyId = army.id
      let squadsList = squadsByArmy?[armyId]
      if (squadsList != null) {
        foreach (squad in squadsList) {
          let { squadCfg } = squad
          local onClick, behavior
          if (isCurrent) {
            onClick = function() {
                markNewSquadsSeen()
                openUnlockSquadScene(armyId, squadCfg, null, true)
              }
            behavior = Behaviors.Button
          }
          campaignSquads.append(watchElemState(@(sf) {
            size = const [squadSlotWidth, SIZE_TO_CONTENT]
            behavior
            onClick
            children = [
              mkSquad(squadCfg)
              {
                rendObj = ROBJ_BOX
                size = FLEX
                borderWidth = sf & S_HOVER ? hdpx(1) : 0
                borderColor = disabledTxtColor
              }
              isCurrent && (sf & S_HOVER) ? {
                rendObj = ROBJ_TEXT
                text = utf8ToUpper(loc("btn/view"))
                padding = midPadding
                hplace = ALIGN_RIGHT
                vplace = ALIGN_BOTTOM
                color = activeTxtColor
              } : null
            ]
          }))
        }
      }
    }

    if (campaignSquads.len() > 0) {
      local headerTxt = campaign.title
      if (isCurrent)
        headerTxt = $"{headerTxt} {colorize(accentTitleTxtColor, loc("currentCampaign"))}"
      campaignSquads = arrayByRows(campaignSquads, SQUADS_PER_LINE)
        .map(@(list) {
          flow = FLOW_HORIZONTAL
          gap = midPadding
          children = list
        })
      squadsBlock.append({
        flow = FLOW_VERTICAL
        gap = smallPadding
        padding = midPadding
        children = [
          noteTextArea(headerTxt).__update({ color = activeTxtColor }, fontBody)
          campaignSquads.len() == 1
            ? campaignSquads[0]
            : {
                flow = FLOW_VERTICAL
                gap = midPadding
                children = campaignSquads
              }
        ]
      }.__update(isCurrent ? curSquadStyle : {}))
    }
  }

  return {
    watch
    flow = FLOW_VERTICAL
    gap = smallOffset
    children = [
      {
        size = FLEX_H
        children = [
          {
            rendObj = ROBJ_TEXT
            text = utf8ToUpper(loc("squad/gotNewSquads"))
            hplace = ALIGN_CENTER
            color = activeTxtColor
          }.__update(fontBody)
          closeButton
        ]
      }
      {
        flow = FLOW_VERTICAL
        gap = tinyOffset
        children = squadsBlock
      }
    ]
  }
}

let close = @() removeModalWindow(WND_UID)

let open = @() addModalWindow({
  rendObj = ROBJ_WORLD_BLUR_PANEL
  key = WND_UID
  size = FLEX
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  color = blurBgColor
  onClick = @() null
  children = receivedSquadsUi
})

function conditionalOpen() {
  let squadsByArmy = newSquadsPromo.get()
  if (squadsByArmy.len() == 1) {
    foreach (armyId, squadsList in squadsByArmy)
      if (squadsList.len() == 1) {
        markNewSquadsSeen()
        openUnlockSquadScene(armyId, squadsList.top().squadCfg, null, true)
        return
      }
  }
  open()
}

if (needNewSquadsWindow.get())
  conditionalOpen()

needNewSquadsWindow.subscribe(function(v) {
  if (v)
    conditionalOpen()
  else
    close()
})
