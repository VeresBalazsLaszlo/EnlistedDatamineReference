import "%ui/control/gui_buttons.nut" as JB
from "dagor.clipboard" import set_clipboard_text
from "%ui/style/fontsStyle.nut" import fontSub
from "%sqstd/string.nut" import tostring_r, utf8ToLower
from "string" import startswith, endswith
from "%ui/components/scrollbar.nut" import makeVertScroll
from "%ui/components/modalWindows.nut" import addModalWindow, removeModalWindow
from "%ui/ui_library.nut" import *
from "types" import Array, Table

let textInput = require("%ui/components/textInput.nut")

const wndWidth = sw(80)

const gap = hdpx(5)
const defaultColor = 0xFFA0A0A0
let defFilterText = mkWatched(persist, "filterText", "")

function tabButton(text, idx, curTab){
  let stateFlags = Watched(0)
  return function(){
    let isSelected = curTab.get() == idx
    let sf = stateFlags.get()
    return {
      children = {
        rendObj = ROBJ_TEXT
        text
        color = isSelected ? Color(255,255,255) : defaultColor
      }.__update(fontSub)
      behavior = Behaviors.Button
      onClick = @() curTab.set(idx)
      onElemState = @(s) stateFlags.set(s)
      watch = [stateFlags, curTab]
      padding = const [hdpx(5),hdpx(10)]
      rendObj = ROBJ_BOX
      fillColor = sf & S_HOVER ? Color(200,200,200) : isSelected ? Color(0,0,0,0) : Color(0,0,0)
      borderColor = Color(200,200,200)
      borderWidth = isSelected ? [hdpx(1), hdpx(1), 0, hdpx(1)] : [0,0, hdpx(1), 0]
    }
  }
}
let hGap = freeze({rendObj = ROBJ_SOLID size = const [hdpx(1), hdpx(10)] vplace = ALIGN_CENTER color = Color(40,40,40,40)})
let mkTabs = @(tabs, curTab) @() {
  watch = curTab
  children = wrap(
    tabs.map(@(_, idx) tabButton(tabs[idx].id, idx, curTab)),
    {
      width = wndWidth - gap - hdpx(250), 
      vGap = gap
      hGap
    })
}

let textArea = @(text) {
  size = FLEX_H
  color = defaultColor
  rendObj=ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  preformatted = FMT_AS_IS 
  text
}.__update(fontSub)

let dataToText = @(data) tostring_r(data, { maxdeeplevel = 10, compact = false })

function defaultRowFilter(rowData, rowKey, txt) {
  if (txt == "")
    return true
  if (startswith(txt, "\"") && endswith(txt, "\""))
    return txt.slice(1,-1) == rowKey.tostring()
  else if (startswith(txt, "\""))
    return startswith(rowKey.tostring(), txt.slice(1))
  else if (endswith(txt, "\""))
    return endswith(rowKey.tostring(), txt.slice(0,-1))

  if (utf8ToLower(rowKey.tostring()).contains(txt))
    return true
  if (rowData == null)
    return false
  let dataType = type(rowData)
  if (dataType == "array" || dataType == "table") {
    foreach (key, value in rowData)
      if (defaultRowFilter(value, key, txt))
        return true
    return false
  }
  return utf8ToLower(rowData.tostring()).contains(txt)
}

function filterData(data, curLevel, filterLevel, rowFilter, countLeft) {
  let isArray = data instanceof Array
  if (!isArray && !(data instanceof Table))
    return rowFilter(data, "") ? data : null

  let res = isArray ? [] : {}
  foreach (key, rowData in data) {
    local curData = rowData
    if (filterLevel <= curLevel) {
      let isVisible = countLeft.get() >= 0 && rowFilter(rowData, key)
      if (!isVisible)
        continue
      countLeft.modify(@(v) v - 1)
      if (countLeft.get() < 0)
        break
    }
    else {
      curData = filterData(rowData, curLevel + 1, filterLevel, rowFilter, countLeft)
      if (curData == null)
        continue
    }

    if (isArray)
      res.append(curData)
    else
      res[key] <- curData
    if (countLeft.get() < 0)
      break
  }
  return (curLevel == 0 || res.len() > 0) ? res : null
}

let mkFilter = @(rowFilterBase, filterArr) filterArr.len() == 0 ? @(_rowData, _key) true
  : function(rowData, key) {
      foreach (anyList in filterArr) {
        local res = true
        foreach (andText in anyList)
          if (!rowFilterBase(rowData, key, andText)) {
            res = false
            break
          }
        if (res)
          return true
      }
      return false
    }

local mkInfoBlockKey = 0
function mkInfoBlock(curTabIdx, tabs, filterText) {
  let curTabV = tabs?[curTabIdx]
  let dataWatch = curTabV?.data
  let textWatch = Watched("")
  function recalcText() {
    let filterArr = utf8ToLower(filterText.get()).split("||").map(@(v) v.split("&&"))
    let rowFilterBase = curTabV?.rowFilter ?? defaultRowFilter
    let rowFilter = mkFilter(rowFilterBase, filterArr)
    let countLeft = Watched(curTabV?.maxItems ?? 100)
    let resData = filterData(dataWatch?.get(), 0, curTabV?.recursionLevel ?? 0, rowFilter, countLeft)
    local resText = dataToText(resData)
    if (countLeft.get() < 0)
      resText = $"{resText}\n...... has more items ......"
    textWatch.set(resText)
  }

  function timerRestart(_) {
    gui_scene.resetTimeout(0.8, recalcText)
  }
  filterText.subscribe(timerRestart)

  mkInfoBlockKey++
  function copytoCb() {
    log_for_user("copied to clipboard")
    set_clipboard_text(textWatch.get())
  }
  return @() {
    watch = [textWatch]
    key = mkInfoBlockKey
    size = FLEX_H
    children = textArea(textWatch.get())
    hotkeys = [["L.Ctrl C", {action = copytoCb}]]
    onAttach = recalcText
    onDetach = function() {
      gui_scene.clearTimer(recalcText)
      filterText.unsubscribe(timerRestart)
    }
  }
}

let mkCurInfo = @(curTab, tabs, filterText) @() {
  watch = curTab
  size = FLEX_H
  children = mkInfoBlock(curTab.get(), tabs, filterText)
}

let debugShopWnd = @(tabs, curTab, filterText) {
  size = const [wndWidth + 2 * gap, sh(90)]
  stopMouse = true
  padding = gap
  vplace = ALIGN_CENTER
  hplace = ALIGN_CENTER
  rendObj = ROBJ_SOLID
  color = Color(30,30,30,120)
  flow = FLOW_VERTICAL
  gap = gap

  children = [
    {
      size = FLEX_H
      flow = FLOW_HORIZONTAL
      valign = ALIGN_TOP
      children = [
        mkTabs(tabs, curTab)
        textInput(filterText, {
          placeholder = "filter..."
          textmargin = hdpx(5)
          margin = 0
          onChange = @(value) filterText.set(value)
          onEscape = @() filterText.set("")
        }.__update(fontSub))
      ]
    }
    makeVertScroll(mkCurInfo(curTab, tabs, filterText))
  ]
}

function openDebugWnd(tabs, wndUid = "debugWnd", filterText = defFilterText) {
  let curTab = Watched(0)
  let close = @() removeModalWindow(wndUid)

  addModalWindow({
    key = wndUid
    size = const [sw(100), sh(100)]
    rendObj = ROBJ_WORLD_BLUR_PANEL
    fillColor = Color(0,0,0,220)
    onClick = close
    children = debugShopWnd(tabs, curTab, filterText)
    hotkeys = [[$"^{JB.B} | Esc", { action = close, description = loc("Cancel") }]]
  })
}

return {
  openDebugWnd = kwarg(openDebugWnd)
}
