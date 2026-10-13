import "%ui/control/gui_buttons.nut" as JB
import "%ui/gameModes/getMissionInfo.nut" as getMissionInfo
import "%ui/components/faComp.nut" as faComp
from "%ui/matchingQueues.nut" import matchingQueues
from "%ui/components/textButton.nut" import Regular
from "%ui/style/fontsStyle.nut" import fontSub, fontBody
from "%ui/components/modalWindows.nut" import addModalWindow, removeModalWindow
from "%ui/components/scrollbar.nut" import makeVertScroll, thinStyle
from "%ui/components/missionsPresentation.nut" import typeToLocId, missionTypes
from "%ui/style/cursors.nut" import setTooltip
from "%ui/components/msgbox.nut" import showMsgbox
from "%ui/gameModes/missionsRatingState.nut" import isMissionsRatingOpened, setRate,
  missionRatesData, RatesStatus, getMissionRate, missionRatesCfg, frontByCampaign,
  lastPlayedMissionData
from "%ui/style/designConst.nut" import bigPadding, midPadding, smallPadding, transpBgColor,
  defItemBlur, activeTxtColor, defTxtColor, darkTxtColor, attentionTxtColor, panelBgColor,
  modsBgColor, squadSlotBgIdleColor, squadSlotBgHoverColor, squadSlotBgActiveColor,
  negativeTxtColor, positiveTxtColor
from "dagor.localize" import doesLocTextExist
from "%ui/ui_library.nut" import *

let { optMissions } = require("%ui/gameModes/createEventRoomState.nut")


const WND_UID = "MISSIONS_RATING_WNG"


const columns = 4
const contentWidth = sw(60)
let blockWidth = ((contentWidth - (columns - 1) * bigPadding) / columns).tointeger()

let missionBlockSize = [blockWidth, (blockWidth * 0.75).tointeger()]
let filterSlotSize = [sw(20), hdpx(46)]


let selectedFront = Watched(0)
let selectedMissionType = Watched(null)
let highlightedTagsCode = Watched(null)


let mkTextArea = @(text, override = {}) {
  rendObj = ROBJ_TEXTAREA
  size = FLEX_H
  behavior = Behaviors.TextArea
  color = activeTxtColor
  text = text
}.__update(fontSub, override)

let mkText = @(text, override = {}) {
  rendObj = ROBJ_TEXT
  color = attentionTxtColor
  text
}.__update(fontSub, override)


let likeViewCfg = {
  [RatesStatus.LIKE] = {
    icon = "thumbs-up"
    color = positiveTxtColor
    locId = "limitReached/likes"
    hotkeys = [["^J:X", { description = loc("map/like") }]]
  },
  [RatesStatus.DISLIKE] = {
    icon = "thumbs-down"
    color = negativeTxtColor
    locId = "limitReached/dislikes"
    hotkeys = [["^J:Y", { description = loc("map/dislike") }]]
  },
  [RatesStatus.BAN] = {
    icon = "ban"
    color = negativeTxtColor
    locId = "limitReached/ban"
  }
}

function mkLikeBtn(onClick, btnType, isSelected, isBlocked = false, missionId = null) {
  let viewCfg = likeViewCfg[btnType]
  return watchElemState(function(sf) {
    let color = isSelected ? viewCfg.color
      : sf & S_HOVER ? activeTxtColor
      : defTxtColor
    return {
      halign = ALIGN_CENTER
      valign = ALIGN_CENTER
      behavior = onClick == null ? null : Behaviors.Button
      onClick
      key = missionId == null ? null : $"{missionId}.{btnType}"
      onHover = !isBlocked || isSelected ? null
        : @(on) setTooltip(!on ? null : loc(viewCfg.locId))
      hotkeys = missionId != null ? viewCfg?.hotkeys : null
      children = [
        {
          size = hdpx(32)
          rendObj = ROBJ_VECTOR_CANVAS
          commands = [
            [ VECTOR_WIDTH, hdpx(2) ],
            [ VECTOR_COLOR, color ],
            [ VECTOR_ELLIPSE, 50, 50, 50, 50 ]
          ]
          fillColor = modsBgColor
        }
        faComp(viewCfg.icon, { fontSize = hdpxi(18), color })
      ]
    }
  })
}


let blinkingFrame = {
  rendObj = ROBJ_BOX
  borderWidth = hdpx(3)
  size = FLEX
  animations = [{
    prop = AnimProp.opacity, from = 0.3, to = 1, duration = 1,
    play = true, loop = true, easing = Blink
  }]
}

let mkRateCb = @(tagsCode, rateIdx, rate, isBlocked) function() {
  if (rate.get() != rateIdx && isBlocked.get())
    showMsgbox(loc(likeViewCfg[rateIdx].locId))
  else
    setRate(tagsCode, rate.get() == rateIdx ? RatesStatus.UNDEFINED : rateIdx)
}

function mkMission(mission, rCfg, ratesCount, typeToString) {
  let { id, image, campaign, tagsCode } = mission
  let frontIdx = rCfg.findindex(@(l) (l?.limits.len() ?? 0) > 0 && tagsCode in l.missionsByTags)
  let { limits = {} } = rCfg?[frontIdx]

  let curRate = Computed(@() getMissionRate(missionRatesData.get(), tagsCode))
  let isHighlighted = Computed(@() tagsCode == highlightedTagsCode.get())
  let hasLikeLimitReached = Computed(function() {
    let count = ratesCount.get()?[frontIdx][RatesStatus.LIKE] ?? 0
    let limit = limits?[RatesStatus.LIKE] ?? 0
    return count >= limit
  })
  let hasDislikeLimitReached = Computed(function() {
    let count = ratesCount.get()?[frontIdx][RatesStatus.DISLIKE] ?? 0
    let limit = limits?[RatesStatus.DISLIKE] ?? 0
    return count >= limit
  })

  let resampledImage = $"{image}:{missionBlockSize[0]}:{missionBlockSize[1]}"
  let frontText = loc(frontByCampaign[campaign])
  let onLikeCb = mkRateCb(tagsCode, RatesStatus.LIKE, curRate, hasLikeLimitReached)
  let onDislikeCb = mkRateCb(tagsCode, RatesStatus.DISLIKE, curRate, hasDislikeLimitReached)
  let missionName = doesLocTextExist($"rate/{tagsCode}")
    ? loc($"rate/{tagsCode}", { mission_type = typeToString(id) })
    : loc(id, { mission_type = typeToString(id) })

  return watchElemState(function(sf) {
    let rate = curRate.get()
    let buttons = {
        flow = FLOW_HORIZONTAL
        gap = midPadding
        padding = midPadding
        children = sf & S_HOVER
            ? [
                mkLikeBtn(onLikeCb, RatesStatus.LIKE, rate == RatesStatus.LIKE,
                  hasLikeLimitReached.get(), id)
                mkLikeBtn(onDislikeCb, RatesStatus.DISLIKE, rate == RatesStatus.DISLIKE,
                  hasDislikeLimitReached.get(), id)
              ]
          : rate != RatesStatus.UNDEFINED ? mkLikeBtn(null, rate, true)
          : null
      }

    return {
      watch = [curRate, hasLikeLimitReached, hasDislikeLimitReached, isHighlighted]
      size = missionBlockSize
      behavior = Behaviors.Button
      children = [
        {
          rendObj = ROBJ_IMAGE
          size = missionBlockSize
          image = Picture(resampledImage)
          keepAspect = KEEP_ASPECT_FILL
        }
        {
          size = FLEX_H
          flow = FLOW_VERTICAL
          padding = midPadding
          vplace = ALIGN_BOTTOM
          rendObj = ROBJ_SOLID
          color = panelBgColor
          children = [
            mkTextArea(missionName)
            mkText(frontText)
          ]
        }
        isHighlighted.get() ? blinkingFrame : null
        buttons
      ]
    }
  })
}


let mkLimitsBlock = @(rCfg, rCnt) rCfg == null ? null
  : {
      flow = FLOW_HORIZONTAL
      gap = bigPadding
      hplace = ALIGN_RIGHT
      children = [RatesStatus.LIKE, RatesStatus.DISLIKE]
        .map(function(rate) {
          let curValue = rCnt?[rate] ?? 0
          let maxValue = rCfg?.limits[rate] ?? 0
          return {
            flow = FLOW_HORIZONTAL
            gap = smallPadding
            valign = ALIGN_CENTER
            children = [
              mkLikeBtn(null, rate, true)
              mkText($"{curValue}/{maxValue}", {
                color = curValue < maxValue ? defTxtColor : negativeTxtColor
              })
            ]
          }
        })
    }


function changeFront(delta) {
  let amount = missionRatesCfg.len()
  let index = (selectedFront.get() + delta + amount) % amount
  selectedFront.set(index)
}

function changeGameMode(delta, usedModes) {
  let mode = selectedMissionType.get()
  let currentIndex = usedModes.indexof(mode) ?? 0
  let amount = usedModes.len()
  let index = (currentIndex + delta + amount) % amount
  selectedMissionType.set(usedModes[index])
}

function mkFront(cfg, idx, rCfg, rCnt) {
  let isSelected = Computed(@() selectedFront.get() == idx)
  let hasLimits = (rCfg?.limits.len() ?? 0) > 0
  return watchElemState(@(sf) {
    watch = isSelected
    size = filterSlotSize
    padding = midPadding
    valign = ALIGN_CENTER
    rendObj = ROBJ_SOLID
    color = isSelected.get() ? squadSlotBgActiveColor
      : sf & S_HOVER ? squadSlotBgHoverColor
      : squadSlotBgIdleColor
    behavior = Behaviors.Button
    onClick = @() selectedFront.set(idx)
    children = [
      mkText(loc(cfg.locId), {
        color = isSelected.get() ? activeTxtColor
          : sf & S_HOVER ? darkTxtColor
          : defTxtColor
      }.__update(fontBody))
      hasLimits ? mkLimitsBlock(rCfg, rCnt) : null
    ]
  })
}

function mkMissionType(missionType = null) {
  let isSelected = Computed(@() selectedMissionType.get() == missionType)
  let btnText = missionType == null
    ? loc("gamemode/all")
    : loc(typeToLocId[missionType])
  return watchElemState(@(sf) {
    watch = isSelected
    size = filterSlotSize
    padding = midPadding
    rendObj = ROBJ_SOLID
    color = isSelected.get() ? squadSlotBgActiveColor
      : sf & S_HOVER ? squadSlotBgHoverColor
      : squadSlotBgIdleColor
    behavior = Behaviors.Button
    onClick = @() selectedMissionType.set(missionType)
    children = mkText(btnText, {
      color = isSelected.get() ? activeTxtColor
        : sf & S_HOVER ? darkTxtColor
        : defTxtColor
    }.__update(fontBody))
  })
}


let mkFilterBlockUi = @(ratesCfg, ratesCount, missions, usedTypes) {
  size = FLEX_V
  flow = FLOW_VERTICAL
  gap = hdpx(70)
  children = [
    function() {
      let rCfg = ratesCfg.get()
      let rCnt = ratesCount.get()
      return {
        watch = [ratesCfg, ratesCount]
        flow = FLOW_VERTICAL
        gap = midPadding
        children = missionRatesCfg.map(@(cfg, idx) mkFront(cfg, idx, rCfg?[idx], rCnt?[idx]))
        hotkeys = missionRatesCfg.len() <= 1 ? null
          : [
              ["^J:LB", @() changeFront(-1), loc("front/prev")],
              ["^J:RB", @() changeFront(1), loc("front/next")],
            ]
      }
    }
    @() {
      watch = [missions, usedTypes]
      flow = FLOW_VERTICAL
      gap = midPadding
      children = usedTypes.get().map(mkMissionType)
      hotkeys = usedTypes.get().len() <= 1 ? null
        : [
            ["^J:LT", @() changeGameMode(-1, usedTypes.get()), loc("gamemode/prev")],
            ["^J:RT", @() changeGameMode(1, usedTypes.get()), loc("gamemode/next")],
          ]
    }
    {
      size = FLEX
      valign = ALIGN_BOTTOM
      children = Regular(loc("BackBtn"), @() isMissionsRatingOpened.set(false), {
        hotkeys = [[$"^{JB.B} | Esc", { description = { skip = true }}]]
      })
    }
  ]
}


let wrapParams = {
  width = contentWidth
  hGap = bigPadding
  vGap = bigPadding
}

let scrollParams = {
  size = const [SIZE_TO_CONTENT, sh(70)]
  styling = thinStyle
  rootBase = {
    key = "battlepassUnlocksRoot"
    behavior = Behaviors.Pannable
    wheelStep = 1
  }
}

function open() {
  let missionsByFront = Computed(function() {
    let missions = {}
    foreach (queue in matchingQueues.get()) {
      let { isEventQueue = false, newbies = false } = queue?.extraParams
      if (!isEventQueue && !newbies)
        foreach (scene in queue.scenes) {
          let { fileName, tags } = scene
          if (tags.len() == 0)
            continue

          let tagsCode = ",".join(tags)
          let sceneInfo = getMissionInfo(fileName)
          let { id, image, campaign } = sceneInfo
          if (tagsCode not in missions || id.len() < missions[tagsCode].id.len())
            missions[tagsCode] <- { tagsCode, id, image, campaign, missionType = sceneInfo.type }
        }
    }

    let res = []
    foreach (rateData in missionRatesCfg) {
      let { campaigns = [] } = rateData
      res.append(missions.values().filter(@(mission) campaigns.contains(mission.campaign)))
    }

    return res
  })

  let missions = Computed(@() missionsByFront.get()?[selectedFront.get()] ?? [])

  let usedTypes = Computed(function() {
    let types = {}
    foreach (mission in missions.get())
      types[mission.missionType] <- true

    let used = missionTypes.filter(@(t) types?[t] == true)
    return [null].extend(used)
  })

  let missionsByType = Computed(function() {
    let selectedType = selectedMissionType.get()
    return selectedType == null
      ? missions.get()
      : missions.get().filter(@(mission) mission.missionType == selectedType)
  })

  let ratesCfg = Computed(function() {
    let res = {}
    foreach (idx, frontData in missionsByFront.get()) {
      if ((missionRatesCfg[idx]?.campaigns.len() ?? 0) == 0)
        continue

      let missionsByTags = {}
      foreach (mission in frontData)
        missionsByTags[mission.tagsCode] <- true

      let { limits = {} } = missionRatesCfg[idx]
      res[idx] <- { limits, missionsByTags }
    }

    return res
  })

  let ratesCount = Computed(function() {
    let likesDataVal = ratesCfg.get()
    let res = {}
    foreach (idx, _ in missionsByFront.get()) {
      let { missionsByTags = {}, limits = {} } = likesDataVal?[idx]
      let rates = {}
      foreach (id, rate in missionRatesData.get())
        if (id in missionsByTags && rate in limits)
          rates[rate] <- (rates?[rate] ?? 0) + 1
      res[idx] <- rates
    }
    return res
  })

  let { typeToString = @(v) v } = optMissions
  return addModalWindow({
    key = WND_UID
    size = FLEX
    valign = ALIGN_CENTER
    halign = ALIGN_CENTER
    rendObj = ROBJ_WORLD_BLUR_PANEL
    fillColor = transpBgColor
    color = defItemBlur
    onAttach = function() {
      if (lastPlayedMissionData.get() != null) {
        let { tagsCode, campaign, missionType } = lastPlayedMissionData.get()
        let front = missionRatesCfg.findindex(@(cfg)
          "limits" in cfg && cfg.campaigns.contains(campaign)) ?? 0
        selectedFront.set(front)
        selectedMissionType.set(missionType)
        highlightedTagsCode.set(tagsCode)
      }
    }
    onDetach = function() {
      lastPlayedMissionData.set(null)
      highlightedTagsCode.set(null)
    }
    children = {
      flow = FLOW_HORIZONTAL
      gap = bigPadding
      children = [
        mkFilterBlockUi(ratesCfg, ratesCount, missions, usedTypes)
        makeVertScroll(function() {
          let rCfg = ratesCfg.get()
          return {
            watch = [missionsByType, ratesCfg]
            children = wrap(missionsByType.get().map(@(mission)
              mkMission(mission, rCfg, ratesCount, typeToString)), wrapParams)
          }
        }, scrollParams)
      ]
    }
    onClick = @() null
  })
}


if (isMissionsRatingOpened.get())
  open()

isMissionsRatingOpened.subscribe(@(v) v ? open() : removeModalWindow(WND_UID))
