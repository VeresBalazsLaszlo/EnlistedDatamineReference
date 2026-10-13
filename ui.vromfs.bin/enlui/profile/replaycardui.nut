import "%ui/control/gui_buttons.nut" as JB
from "%ui/style/fontsStyle.nut" import fontBody
from "%ui/style/designConst.nut" import rowBg, bigPadding, blockedTxtColor, defTxtColor, commonBtnHeight
from "%ui/replay/replaySettings.nut" import currentRecord, replayPlay, deleteReplay, records, updateReplays, defaultRecordFolder
from "dagor.iso8601" import format_unix_time
from "%ui/helpers/time.nut" import secondsToStringLoc
from "dagor.shell" import shell_execute
from "%sqstd/math.nut" import ceil
from "%dngscripts/platform.nut" import is_pc, is_steam_deck
from "%ui/components/textButton.nut" import Regular, FARegular
from "%ui/components/msgbox.nut" import showMsgbox
from "%ui/components/openUrl.nut" import openUrl
from "%ui/networkedUrls.nut" import getReplayPortalUrl
from "%ui/ui_library.nut" import *

let replayPortalUrl = getReplayPortalUrl()

const DISPLAY_PER_PAGE = 14

let maxListHeight = (DISPLAY_PER_PAGE + 1) * commonBtnHeight
let curPage = Watched(0)
const listGap = hdpx(20)
let listPadding = [0, listGap]
let isCurrentRecordProtocolValid = Watched(true)
let totalPages = Computed(@() ceil(records.get().len().tofloat() / DISPLAY_PER_PAGE).tointeger())

let defTxtStyle = { color = defTxtColor }.__update(fontBody)
let disabledTxtStyle = { color = blockedTxtColor }.__update(fontBody)

records.subscribe(function(_) {
  if (totalPages.get() < curPage.get())
    curPage.set(totalPages.get())
})

let mkProtocolBlock = @(isValid) {
  size = const [flex(1.3), SIZE_TO_CONTENT]
  rendObj = ROBJ_TEXT
  text = isValid ? loc("replay/readyToPlay") : loc("replay/protocolMisMatch")
}.__update(isValid ? defTxtStyle : disabledTxtStyle)

let listHeader = [
  {
    locId = loc("replay/recordDate")
    size = FLEX
  }
  {
    locId = loc("replay/mission")
    size = const [flex(1.5), FLEX]
  }
  {
    locId = loc("replay/gameTime")
    size = const [flex(0.7), FLEX]
  }
  {
    locId = loc("replay/availabilityStatus")
    size = const [flex(1.3), FLEX]
  }
]

let headerRow = {
  size = [FLEX, commonBtnHeight]
  flow = FLOW_HORIZONTAL
  padding = listPadding
  gap = listGap
  children = listHeader.map(@(tab) {
    size = tab.size
    rendObj = ROBJ_TEXT
    text = tab.locId
  }.__update(defTxtStyle))
}

function mkReplay(record, idx) {
  let replayInfo = record.recordInfo
  if (!replayInfo)
    return null

  let { isValid } = record
  return watchElemState(@(sf) {
    watch = currentRecord
    size = [FLEX, commonBtnHeight]
    rendObj = ROBJ_SOLID
    flow = FLOW_HORIZONTAL
    gap = listGap
    padding = listPadding
    valign = ALIGN_CENTER
    xmbNode = XmbNode()
    behavior = Behaviors.Button
    color = rowBg(sf, idx, record.id == (currentRecord.get()?.id ?? ""))
    onClick = function() {
      currentRecord.set(record)
      isCurrentRecordProtocolValid.set(isValid)
    }
    children = [
      {
        rendObj = ROBJ_TEXT
        size = FLEX_H
        text = format_unix_time(replayInfo?.start_timestamp ?? 0)
          .replace("T", " ").replace("Z", "")
      }.__update(fontBody)
      {
        rendObj = ROBJ_TEXT
        size = const [flex(1.5), SIZE_TO_CONTENT]
        behavior = Behaviors.Marquee
        text = loc(replayInfo?.mission_name ?? "replay/UnknownMission",
          { mission_type=loc(replayInfo?.mission_type ? $"missionType/{replayInfo.mission_type}" : "unknownMissionType") })
      }.__update(fontBody)
      {
        size = const [flex(0.7), SIZE_TO_CONTENT]
        rendObj = ROBJ_TEXT
        text = secondsToStringLoc(replayInfo?.total_play_time ?? 0)
      }.__update(fontBody)
      mkProtocolBlock(isValid)
    ]
  })
}

let emptyReplayBlock = {
  rendObj = ROBJ_TEXT
  text = loc("replay/emptyList")
  size = FLEX
  valign = ALIGN_CENTER
  halign = ALIGN_CENTER
}.__update(defTxtStyle)

function mkReplayList() {
  let sliceFrom = curPage.get() * DISPLAY_PER_PAGE
  let sliceTo = sliceFrom + DISPLAY_PER_PAGE
  let recordsToShow = records.get()
    .sort(@(a, b) b.isValid <=> a.isValid || (b.recordInfo?.start_timestamp ?? 0) <=> (a.recordInfo?.start_timestamp ?? 0))
  let hasAnyReplay = records.get().len() > 0
  return {
    watch = [records, curPage]
    size = FLEX_H
    minHeight = maxListHeight
    onAttach = updateReplays
    flow = FLOW_VERTICAL
    children = !hasAnyReplay ? emptyReplayBlock
      : [headerRow].extend(recordsToShow.slice(sliceFrom, sliceTo).map(@(v, k) mkReplay(v, k)))
  }}

let deleteReplayMsgbox = @() showMsgbox({
  text = loc("replay/deleteApprove"),
  buttons = [
    {
      text = loc("Yes")
      action = @() deleteReplay(currentRecord.get().id)
      isCurrent = true
    },
    {
      text = loc("No")
      isCancel = true
      customStyle = { hotkeys = [[$"^{JB.B} | Esc"]] }
    }
  ]
})


let curPageInfo = @() {
  watch = [totalPages, curPage]
  size = FLEX_H
  halign = ALIGN_CENTER
  rendObj = ROBJ_TEXT
  text = totalPages.get() <= 1 ? ""
    : loc("replay/page", { curPage = curPage.get() + 1, totalPages = totalPages.get() })
}.__update(defTxtStyle)


let mkReplayControl = @() {
  watch = [totalPages, curPage, currentRecord]
  size = FLEX_H
  flow = FLOW_HORIZONTAL
  gap = bigPadding
  children = [
    is_pc && !is_steam_deck
      ? FARegular("folder-open", @() shell_execute({cmd="explore", dir=defaultRecordFolder}))
      : null
    Regular(loc("replay/replaysOnSite"), @() openUrl(replayPortalUrl), {
      hotkeys = [["^J:RS"]]
    })
    {
      size = [FLEX, SIZE_TO_CONTENT]
      flow = FLOW_HORIZONTAL
      gap = bigPadding
      halign = ALIGN_CENTER
      children = [
        Regular(loc("page/prev"), @() curPage.modify(@(v) v - 1),
          curPage.get() > 0
            ? { isEnabled = true, hotkeys = [["^J:LT"]] }
            : { isEnabled = false })
        Regular(loc("page/next"), @() curPage.modify(@(v) v + 1),
          curPage.get() + 1 < totalPages.get()
            ? { isEnabled = true, hotkeys = [["^J:RT"]] }
            : { isEnabled = false })
      ]
    }
    Regular(loc("replay/delete"), deleteReplayMsgbox,
      currentRecord.get() != null
        ? { isEnabled = true, hotkeys = [["^J:X"]] }
        : { isEnabled = false })
    Regular(loc("replay/Watch"), @() replayPlay(currentRecord.get().id),
      currentRecord.get() != null
        ? { isEnabled = true, hotkeys = [["^J:Y"]] }
        : { isEnabled = false })
  ]
}


return {
  size = FLEX
  flow = FLOW_VERTICAL
  gap = { size = FLEX }
  padding = [bigPadding, bigPadding, 0, bigPadding]
  children = [
    {
      size = FLEX
      flow = FLOW_VERTICAL
      gap = bigPadding
      children = [
        mkReplayList
        curPageInfo
      ]
    }
    mkReplayControl
  ]
}
