import "%ui/control/gui_buttons.nut" as JB
import "%ui/gameModes/components/mkOptionRow.nut" as mkOptionRow
import "%ui/components/faComp.nut" as faComp
from "%enlSqGlob/game_mods_constant.nut" import MOD_LATEST_URL, MOD_BASE_URL
from "%ui/style/fontsStyle.nut" import fontBody, fontHeading2, fontSub
from "%ui/gameModes/sandbox/customMissionState.nut" import modPath, receivedModInfos, requestModManifest, deleteMod, hasBeenUpdated
from "%ui/style/designConst.nut" import midPadding, maxContentWidth, isWide, commonBtnHeight
, titleTxtColor, defTxtColor, bigPadding, blurBgFillColor, attentionTxtColor
from "%ui/gameModes/eventModeStyle.nut" import localPadding, localGap, rowHeight
from "%ui/components/modalWindows.nut" import addModalWindow, removeModalWindow
from "%ui/components/scrollbar.nut" import makeVertScroll
from "%ui/components/textButton.nut" import Regular, FAPrimary
from "%ui/components/openUrl.nut" import openUrl
from "%darg/helpers/mkGradientImg.nut" import mkLinearGradientImg
from "%ui/components/defcomps.nut" import noteTextArea
from "dagor.clipboard" import get_clipboard_text
from "%ui/components/formatText.nut" import formatText
from "%sqstd/time.nut" import TIME_DAY_IN_SECONDS
from "dagor.time" import format_unixtime
from "datetime" import time
from "%ui/ui_library.nut" import *


let textInput = require("%ui/components/textInput.nut")

const WND_UID = "CUSTOM_MISSION_WND"
const fmtTime = "%Y-%m-%d"
const OUTDATED_AFTER = TIME_DAY_IN_SECONDS * 30 * 6

let sceneName = Watched("")
let maxWndContentWidth = min(maxContentWidth, sw(100)) - localPadding * 2
let isInputFocused = Watched(false)

const modInfoWidth = hdpx(520)
const rowModWidth = hdpx(400)
let modListWidth = isWide
  ? (rowModWidth + localGap) * 3
  : (rowModWidth + localGap) * 2

let btnStyle = {
  size = [SIZE_TO_CONTENT, commonBtnHeight]
}

let closeButton = Regular(loc("BackBtn"), function(){
  modPath.set("")
  removeModalWindow(WND_UID)
}, btnStyle.__merge({
  vplace = ALIGN_BOTTOM
  hotkeys = [[$"^{JB.B} | Esc", { description = { skip = true }}]]
}))

let applyBtn = Regular(loc("Apply"), @() removeModalWindow(WND_UID), btnStyle.__merge({
  hplace = ALIGN_RIGHT
  vplace = ALIGN_BOTTOM
}))


let modsWrapParams = {
  width = modListWidth
  hGap = localGap
  vGap = midPadding
}

let inputOptions = {
  size = [FLEX, commonBtnHeight - hdpx(7) * 2]
  textmargin = hdpx(7)
  colors = { backGroundColor = Color(0, 0, 0, 255) }
  placeholder = loc("pasteLink")
  valignText = ALIGN_CENTER
  hotkeys = [
    ["^J:Y", {action = @() sceneName.set(get_clipboard_text()), description = loc("pasteLink")}],
    ["^J:X", {action = @() sceneName.set(""), description = loc("clearInput")}]
  ]
  margin = 0
  onFocus = @() isInputFocused.set(true)
  onBlur = @() isInputFocused.set(false)
}.__update(fontBody)

let urlInput = @(){
  watch = sceneName
  size = [hdpx(400), commonBtnHeight]
  valign = ALIGN_CENTER
  children = [
    sceneName.get().len() > 0
      ? FAPrimary("close", @() sceneName.set(""), { pos = const [ -hdpx(40), 0 ] })
      : null
    textInput(sceneName, inputOptions)
  ]
}

let urlInputBlock = @(){
  watch = [sceneName, isInputFocused]
  flow = FLOW_HORIZONTAL
  hplace = ALIGN_RIGHT
  gap = localGap
  children = [
    urlInput
    Regular(loc("downloadMission"),
      function(){
        set_kb_focus(null)
        requestModManifest(sceneName.get())
        sceneName.set("")
      }, btnStyle.__merge({
        isEnabled = sceneName.get() != ""
        hotkeys = isInputFocused.get() ? [[$"^{JB.A} | Enter", { skip = true }]] : null
      }))
  ]
}

let topBlock = @(){
  size = const [FLEX, hdpx(150)]
  valign = ALIGN_CENTER
  children = [
    Regular(loc("MissionsListOnWeb"), @() openUrl(MOD_BASE_URL), btnStyle)
    urlInputBlock
  ]
}

let scrollOnlyUp = mkLinearGradientImg({
  points = [{offset = 0 color = [50, 35, 30]}, {offset = 100 color = [30, 35, 44]}]
  width = 16
  height = 128
  x1 = 0
  y1 = 0
  x2 = 0
  y2 = 128
})


let modsContent = makeVertScroll(@(){
  watch = [modPath, receivedModInfos]
  size = [modsWrapParams.width, SIZE_TO_CONTENT]
  children = wrap(receivedModInfos.get().values()
    .sort(@(a, b) a.title <=> b.title)
    .map(@(mod) mkOptionRow(mod.title,
      modPath.get() == mod.id ? faComp("check") : null,
      {
        size = [rowModWidth, rowHeight]
        valign = ALIGN_CENTER
      },
      @() modPath.modify(@(v) v != mod.id ? mod.id : ""),
      FAPrimary("close", @() deleteMod(mod.id)))
    ),
  modsWrapParams)
}, { size = FLEX_V })

function mkOptions(modInfo, option, needPrefix = false){
  local info = modInfo.room_params.rules[option].oneOf
  if (needPrefix)
    info = info.map(@(v) loc($"options/{v}"));
  return ", ".join(info)
}

let getLinkToMod = @(modInfo) MOD_LATEST_URL.subst(modInfo.id)

let modLinkButton = @(modInfo)
  formatText([{ t="url", url = getLinkToMod(modInfo), v = loc("mods/modOnSite")}])


function mkUpdateWarningText(modInfo) {
  let { updatedTS = 0 } = modInfo
  if (updatedTS == 0 || updatedTS + OUTDATED_AFTER > time())
    return null

  return {
    size = FLEX_H
    rendObj = ROBJ_BOX
    borderWidth = 0
    fillColor = blurBgFillColor
    borderRadius = hdpxi(2)
    padding = bigPadding
    children = noteTextArea({
      text = loc("mods/outdated", { updated = format_unixtime(fmtTime, updatedTS) })
      halign = ALIGN_CENTER
      color = attentionTxtColor
    }).__update(fontSub)
  }
}

let textRow = @(text) {
  size = FLEX_H
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  color = defTxtColor
  text
}.__update(fontSub)

const LABELED_TEXT = "{0}: {1}"
let labeledRow = @(text1, text2) textRow(LABELED_TEXT.subst(text1, text2))

function currentModInfo() {
  let watch = [modPath, receivedModInfos]
  let curModInfo = receivedModInfos.get()?[modPath.get()]
  if (!curModInfo)
    return { watch }

  let { authors, description = null } = curModInfo
  return {
    watch
    size = const [modInfoWidth, SIZE_TO_CONTENT]
    hplace = ALIGN_LEFT
    flow = FLOW_VERTICAL
    gap = localGap
    children = [
      mkUpdateWarningText(curModInfo)
      {
        size = FLEX_H
        rendObj = ROBJ_TEXTAREA
        text = curModInfo.title
        color = titleTxtColor
        behavior = [Behaviors.Marquee, Behaviors.TextArea]
      }.__update(fontHeading2)
      textRow(loc("options/authorsList", {
        count = authors.len()
        authors = ", ".join(authors)
      }))
      labeledRow(loc("options/version"), curModInfo.version)
      labeledRow(loc("options/difficulty"), mkOptions(curModInfo, "public/difficulty", true))
      labeledRow(loc("options/maxPlayers"), mkOptions(curModInfo, "public/maxPlayers"))
      labeledRow(loc("options/botCount"), mkOptions(curModInfo, "public/botpop"))
      labeledRow(loc("options/numTeams"), curModInfo?.room_params.defaults.public.numTeams ?? 2)
      description == null ? null : textRow(loc("mods/modDescription", { description }))
      modLinkButton(curModInfo)
    ]
  }
}

let bottomBlock = {
  size = FLEX_H
  margin = const [hdpx(20), 0]
  children = [
    applyBtn
    closeButton
  ]
}

let centerBlock = {
  size = FLEX
  hplace = ALIGN_CENTER
  flow = FLOW_HORIZONTAL
  gap = hdpx(20)
  children = [
    modsContent
    currentModInfo
  ]
}

let wndContent = {
  maxWidth = maxWndContentWidth
  flow = FLOW_VERTICAL
  rendObj = ROBJ_IMAGE
  image = scrollOnlyUp
  hplace = ALIGN_CENTER
  vplace = ALIGN_CENTER
  padding = bigPadding
  size = const [FLEX, hdpx(900)]
  children = [
    topBlock
    centerBlock
    bottomBlock
  ]
}

function openCustomMissionWnd() {
  hasBeenUpdated.set(true)
  return addModalWindow({
    key = WND_UID
    rendObj = ROBJ_WORLD_BLUR_PANEL,
    children = wndContent
    onClick = @() null
  })
}

return openCustomMissionWnd