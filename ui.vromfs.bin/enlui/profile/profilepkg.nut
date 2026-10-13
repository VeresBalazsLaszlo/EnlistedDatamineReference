from "%ui/style/designConst.nut" import activeBgColor, blurBgFillColor, disabledTxtColor, midPadding, smallPadding, smallOffset, activeTxtColor
  , rowBg, darkTxtColor, defTxtColor, hoverSlotBgColor, startBtnWidth
from "%ui/style/fontsStyle.nut" import fontSub, fontBody
from "%ui/soldiers/components/armyPackage.nut" import mkArmyIcon
from "%ui/components/itemsInfo.nut" import getCampaignTitle
from "%ui/meta/curCampaign.nut" import COMMON_CAMPAIGN, allArmies, sidesArmies
from "%ui/components/scrollbar.nut" import makeVertScroll, thinStyle
from "%ui/ui_library.nut" import *
from "%ui/profile/profileState.nut" import playerStatsList, killsList


const PROFILE_WIDTH = fsh(100)
const statLabelWidth = pw(40)

const MAIN_GAME_STAT = "main_game"

const headerHeight = hdpxi(50)
const armyIconSize = hdpxi(28)

let selectedCampaign = Watched(null)

let txtColor = @(sf, isSelected = false) isSelected
  ? Color(255,255,255)
  : sf & S_HOVER ? darkTxtColor : defTxtColor

let bgColor = @(sf, isSelected = false) isSelected
  ? Color(160,160,160)
  : sf & S_HOVER ? hoverSlotBgColor : blurBgFillColor

let borderColor = @(sf, isSelected = false) isSelected
  ? activeBgColor
  : sf & S_HOVER ? activeBgColor : disabledTxtColor

let mkText = @(text, customStyle = {}) {
  rendObj = ROBJ_TEXT
  color = activeTxtColor
  text
}.__update(fontSub, customStyle)

let campaignSlotStyle = {
  rendObj = ROBJ_BOX
  size = const [FLEX, hdpx(40)]
  behavior = Behaviors.Button
  sound = {
    hover = "ui/enlist/button_highlight"
    click = "ui/enlist/button_click"
    active = "ui/enlist/button_action"
  }
}

let statValueStyle = {
  size = FLEX_H
  halign = ALIGN_RIGHT
}.__update(fontBody)

let statNameStyle = {
  size = const [statLabelWidth, SIZE_TO_CONTENT]
}.__update(fontBody)

function mkCampaignInfoBtn(campId, cb = null) {
  let isSelected = Computed(@() selectedCampaign.get() == campId)
  return watchElemState(function(sf) {
    let isSelectedVal = isSelected.get()
    return {
      watch = isSelected
      onClick = function() {
        if (!isSelectedVal)
          selectedCampaign.set(campId)
        cb?()
      }
      padding = [0, smallOffset]
      valign = ALIGN_CENTER
      fillColor = bgColor(sf, isSelectedVal)
      children = mkText(getCampaignTitle(campId), fontBody.__merge({
        color = txtColor(sf, isSelectedVal)
      }))
    }.__update(campaignSlotStyle)
  })
}

function mkAllCampaignBtn(cb = null) {
  let isSelected = Computed(@() selectedCampaign.get() == null)
  return watchElemState(function(sf) {
    let isSelectedVal = isSelected.get()
    return {
      watch = isSelected
      onClick = function() {
        selectedCampaign.set(null)
        cb?()
      }
      padding = [0, smallOffset]
      valign = ALIGN_CENTER
      fillColor = bgColor(sf, isSelectedVal)
      children = mkText(loc("menu/campaigns"), fontBody.__merge({
        color = txtColor(sf, isSelectedVal)
      }))
    }.__update(campaignSlotStyle)
  })
}


let mkMapsListPopupUi = @(campaignsWatched, cb) function() {
  local campList = []
  local campCommon = null
  foreach(comp in campaignsWatched.get())
    if (comp != COMMON_CAMPAIGN)
      campList.append(comp)
    else
      campCommon = comp
  return {
    watch = [campaignsWatched]
    size = [startBtnWidth, SIZE_TO_CONTENT]
    flow = FLOW_VERTICAL
    gap = midPadding
    children = [
      mkAllCampaignBtn(cb)
      !campCommon ? null : mkCampaignInfoBtn(COMMON_CAMPAIGN, cb)
      campList.len() == 0 ? null : mkText(loc("oldCampaigns"), {margin = [midPadding, 0, 0, 0]})
    ].extend(campList.map(@(campaignId) mkCampaignInfoBtn(campaignId, cb)))
  }
}


let mkStats = @(baseStats) {
  size = FLEX_H
  flow = FLOW_VERTICAL
  children = baseStats.map(@(s, idx) {
    rendObj = ROBJ_SOLID
    size = FLEX_H
    flow = FLOW_HORIZONTAL
    padding = [smallPadding, smallOffset]
    color = rowBg(0, idx)
    children = [
      mkText(loc($"debriefing/awards/{s.statId}"), statNameStyle)
    ].extend(s.statVal.map(@(v) mkText(v, statValueStyle)))
  })
}

let mkStatsHeader = @(armiesList, headerAddObj) @() {
  size = const [FLEX, headerHeight]
  flow = FLOW_HORIZONTAL
  padding = [0, smallOffset]
  valign = ALIGN_CENTER
  children = [
    {
      size = const [statLabelWidth, SIZE_TO_CONTENT]
      flow = FLOW_HORIZONTAL
      gap = smallOffset
      valign = ALIGN_CENTER
      children = [
        mkText(loc("debriefing/tab/statistic"), fontBody)
        headerAddObj
      ]
    }
  ].extend(armiesList
    .filter(@(armyId) armyId != MAIN_GAME_STAT)
    .map(@(armyId) {
      size = FLEX_H
      valign = ALIGN_CENTER
      halign = ALIGN_RIGHT
      children = mkArmyIcon(sidesArmies?[armyId] ?? armyId, armyIconSize, { margin = 0} )
    }))
}

function mkPlayerStatistics(statsWatch, headerAddObj = null) {
  let playerCardStats = Computed(function() {
    let selCampaign = selectedCampaign.get()
    let armiesList = allArmies.get()?[selCampaign] ?? []
    if (armiesList.len() == 0)
      armiesList.append(MAIN_GAME_STAT)

    let globalStats = statsWatch.get()?.stats["global"] ?? {}
    let stats = armiesList.map(@(armyId) globalStats?[armyId] ?? {})
    let res = {
      campaignTitle = getCampaignTitle(selCampaign)
      armiesList
      baseStats = playerStatsList.map(@(statData) {
        statId = statData.statId
        statVal = stats.map(@(stat)
          statData.calculator(stat) + (statData?.unitSign ?? "")
        )
      })
      killsData = killsList.map(@(statData) {
        statId = statData.statId
        statVal = stats.map(@(stat)
          statData?.calculator(stat) ?? stat?[statData.statId] ?? 0)
      })
    }

    return res
  })

  return function() {
    let { baseStats, killsData, armiesList } = playerCardStats.get()
    return {
      watch = playerCardStats
      size = FLEX
      gap = smallPadding
      flow = FLOW_VERTICAL
      children = [
        mkStatsHeader(armiesList, headerAddObj)
        makeVertScroll({
          size = FLEX_H
          flow = FLOW_VERTICAL
          children = [
            mkStats(baseStats)
            { size = [0, smallOffset] }
            mkStats(killsData)
          ]
        }, {
          size = FLEX
          needReservePlace = false
          styling = thinStyle
        })
      ]
    }
  }
}

return {
  txtColor
  bgColor
  borderColor
  mkPlayerStatistics
  mkMapsListPopupUi
  PROFILE_WIDTH
}
