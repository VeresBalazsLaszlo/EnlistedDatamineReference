import "%ui/mainScene/systemWarnings.nut" as systemWarningsBlock
import "%ui/components/fontawesome.map.nut" as fa
import "%ui/unlocks/isNewbie.nut" as isNewbie
import "%ui/offers/offersPanel.nut" as mkOffersPanel
import "%ui/notifications/mkServiceNotification.nut" as mkServiceNotification
import "%ui/soldiers/researchUpgradeMsgBox.nut" as gotoResearchUpgradeMsgBox
import "%ui/style/tooltipCtor.nut" as tooltipCtor
from "%ui/style/fontsStyle.nut" import fontBody, fontSub, fontawesome
from "%ui/style/designConst.nut" import bigPadding, startBtnWidth, contentOffset, commonBtnHeight, defItemBlur, darkTxtColor, transpPanelBgColor , hoverSlotBgColor, titleTxtColor, defTxtColor, accentColor, smallPadding, mainContentHeaderHeight, sidePadding , midPadding, attentionTxtColor
from "%ui/startButton.nut" import startButton
from "%ui/mainScene/changeGameModeButton.nut" import changeGameModeBtn, selectedGameMode, mkMissionLikesBtn
from "%ui/quickMatch.nut" import randTeamAvailable, randTeamCheckbox, queuesCampaignsData, mkAutoSquadCheckbox
from "%ui/unlocks/taskWidgetUi.nut" import mkDailyTasksUiReward, mkDailyTasksUi
from "%ui/mainMenu/sectionsState.nut" import isMainMenuVisible
from "%ui/notifications/serviceNotificationsList.nut" import serviceNotificationsList
from "%ui/soldiers/squads_list.ui.nut" import mkSquadsList
from "%ui/soldiers/squad_info.ui.nut" import mkSquadInfo
from "%ui/soldiers/mkSoldierInfo.nut" import mkSoldierInfo, mkCustomButtons
from "%ui/soldiers/model/curSoldiersState.nut" import curSoldierInfo
from "%ui/components/mkPromoWidget.nut" import promoWidget
from "%ui/preset/presetEquipUi.nut" import mkPresetEquipBlock
from "%ui/tutorial/notifierTutorial.nut" import notifierHint
from "%ui/gameModes/eventModesState.nut" import hasBaseEvent, openCustomGameMode
from "%sqstd/string.nut" import utf8ToUpper
from "%ui/shop/armyShopState.nut" import goodManageData
from "%ui/style/cursors.nut" import withTooltip
from "%ui/soldiers/components/armyPackage.nut" import mkArmyIcon
from "%ui/campaigns/armiesConfig.nut" import getArmyName
from "%ui/components/itemsInfo.nut" import getCampaignTitle
from "%ui/gameModes/missionsRatingState.nut" import isMissionsRatingOpened
from "%ui/featureFlags.nut" import hasMissionLikes
from "%ui/components/scrollbar.nut" import makeVertScroll, thinStyle
from "%ui/ui_library.nut" import *

let isOfferExpandLocked = Watched(false)

function mkMainSceneContent() {
  let autoSquadCheckbox = mkAutoSquadCheckbox()

  function mkSoldiersUi(){
    let squad_info = mkSquadInfo()
    let squads_list = mkSquadsList()

    let mainContent = {
      size = FLEX
      flow = FLOW_HORIZONTAL
      gap = bigPadding
      children = [
        squads_list
        squad_info
        mkSoldierInfo({
          soldierInfoWatch = curSoldierInfo
          onResearchClickCb = gotoResearchUpgradeMsgBox
          buttons = mkCustomButtons(curSoldierInfo)
        })
        mkPresetEquipBlock(curSoldierInfo)
      ]
    }

    return mainContent
  }

  let customMatchesBtn = @(){
    watch = hasBaseEvent
    size = FLEX_H
    children = hasBaseEvent.get() ? null : watchElemState(@(sf) {
      rendObj = ROBJ_WORLD_BLUR
      size = [FLEX, commonBtnHeight]
      color = defItemBlur
      fillColor = sf & S_ACTIVE ? accentColor
        : sf & S_HOVER ? hoverSlotBgColor
        : transpPanelBgColor
      behavior = Behaviors.Button
      onClick = openCustomGameMode
      sound = {
        hover = "ui/enlist/button_highlight"
        click = "ui/enlist/button_click"
        active = "ui/enlist/button_action"
      }
      valign = ALIGN_CENTER
      halign = ALIGN_CENTER
      children = {
        rendObj = ROBJ_TEXT
        text = utf8ToUpper(loc("custom_matches"))
        color = sf & S_ACTIVE ? titleTxtColor
          : sf & S_HOVER ? darkTxtColor
          : defTxtColor
      }.__update(fontBody)
    })
  }

  let quickMatchButtonWidth = startBtnWidth

  let armyGameModeBlock = @() {
    watch = [selectedGameMode, randTeamAvailable]
    size = FLEX_H
    flow = FLOW_VERTICAL
    gap = smallPadding
    halign = ALIGN_RIGHT
    children = [
      selectedGameMode.get()?.isLocal || !randTeamAvailable.get() ? null : randTeamCheckbox
      autoSquadCheckbox
      @() {
        watch = [isNewbie, hasMissionLikes]
        size = [startBtnWidth, SIZE_TO_CONTENT]
        flow = FLOW_HORIZONTAL
        gap = hdpx(1)
        children = [
          isNewbie.get() || !hasMissionLikes.get() ? null
            : mkMissionLikesBtn(@() isMissionsRatingOpened.set(true))
          changeGameModeBtn
        ]
      }
    ]
  }

  let startPlay = {
    halign = ALIGN_RIGHT
    children = @() {
      size = [quickMatchButtonWidth, SIZE_TO_CONTENT]
      flow = FLOW_VERTICAL
      halign = ALIGN_RIGHT
      gap = smallPadding
      children = [
        armyGameModeBlock
        startButton
      ]
    }
  }

  let bpAnims = [{ prop = AnimProp.translate, from = [0, -hdpxi(180)],
                  to = [0, 0], duration = 0.3, easing = OutQuintic, play = true }]

  let bpBlockUi = @() {
    watch = isOfferExpandLocked
    behavior = Behaviors.Button
    onHover = @(on) isOfferExpandLocked.set(on)
    skipDirPadNav = true
    children = {
      flow = FLOW_VERTICAL
      gap = smallPadding
      children = [
        mkDailyTasksUiReward(@(on) isOfferExpandLocked.set(on))
        !isOfferExpandLocked.get() ? null
          : {
              clipChildren = true
              children = {
                key = isOfferExpandLocked.get()
                children = mkDailyTasksUi(false, @(on) isOfferExpandLocked.set(on), true)
                transform = true
                animations = bpAnims
              }
            }
      ]
    }
  }

  let mkMapsListItem = @(army, maps) {
    flow = FLOW_VERTICAL
    children = [
      {
        flow = FLOW_HORIZONTAL
        gap = midPadding
        valign = ALIGN_CENTER
        children = [
          mkArmyIcon(army, hdpxi(18), { margin = 0 })
          {
            rendObj = ROBJ_TEXT
            color = attentionTxtColor
            text = getArmyName(army)
          }.__update(fontSub)
        ]
      }
      {
        rendObj = ROBJ_TEXTAREA
        behavior = [Behaviors.TextArea]
        color = defTxtColor
        text = "\n".join(maps.map(@(v) getCampaignTitle(v)))
      }.__update(fontSub)
    ]
  }

  let possibleMaps = {
    behavior = Behaviors.Button
    skipDirPadNav = false
    vplace = ALIGN_BOTTOM
    valign = ALIGN_CENTER
    children = {
      rendObj = ROBJ_TEXTAREA
      behavior = Behaviors.TextArea
      color = defTxtColor
      halign = ALIGN_RIGHT
      text = loc("start/possible_maps", { questionIcon = $"<fa>{fa["question-circle"]}</fa>" })
      tagsTable = {
        fa = fontawesome
      }
    }.__update(fontSub)
  }

  function possibleMapsTooltip() {
    let children = []
    queuesCampaignsData.get().mapsList.each(@(maps, army)
      children.append(mkMapsListItem(army, maps)))

    return {
      watch = queuesCampaignsData
      flow = FLOW_VERTICAL
      gap = bigPadding
      children
    }
  }

  let possibleMapsWidget = @() {
    watch = queuesCampaignsData
    size = FLEX_V
    vplace = ALIGN_BOTTOM
    children = queuesCampaignsData.get().mapsList.len() == 0 ? null
      : withTooltip(possibleMaps, @() tooltipCtor(possibleMapsTooltip))
  }

  let rightContent = {
    size = FLEX_V
    hplace = ALIGN_RIGHT
    flow = FLOW_HORIZONTAL
    gap = midPadding
    children = [
      possibleMapsWidget
      {
        size = [startBtnWidth, FLEX]
        flow = FLOW_VERTICAL
        children = [
          @() {
            watch = [serviceNotificationsList, hasBaseEvent]
            size = FLEX
            flow = FLOW_VERTICAL
            gap = smallPadding
            children = serviceNotificationsList.get().len() > 0
              ? mkServiceNotification(serviceNotificationsList.get(), { hplace = ALIGN_RIGHT })
              : {
                  size = FLEX
                  children = makeVertScroll({
                    flow = FLOW_VERTICAL
                    gap = smallPadding
                    children = [
                      bpBlockUi
                      mkOffersPanel(isOfferExpandLocked)
                      hasBaseEvent.get() ? customMatchesBtn : null
                    ]
                  }, {
                    styling = thinStyle
                  })
                }
          }
          startPlay
        ]
      }
    ]
  }

  let headerContent = {
    size = FLEX_H
    flow = FLOW_HORIZONTAL
    margin = [contentOffset, 0, 0, 0]
    minHeight = mainContentHeaderHeight
    children = [
      promoWidget("soldier_equip", "soldier_inventory", {margin = [0, sidePadding, 0, 0]})
      notifierHint
    ]
  }

  return {
    size = FLEX
    onAttach = @() isMainMenuVisible.set(true)
    onDetach = function() {
      goodManageData.set(null)
      isMainMenuVisible.set(false)
    }
    children = {
      size = FLEX
      flow = FLOW_VERTICAL
      children = [
        headerContent
        {
          size = FLEX
          children = [
            rightContent
            mkSoldiersUi
            systemWarningsBlock
          ]
        }
      ]
    }
  }
}
return {mkMainSceneContent}
