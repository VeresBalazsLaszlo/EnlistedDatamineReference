import "%ui/control/gui_buttons.nut" as JB
from "%dngscripts/globalState.nut" import nestWatched
from "settings" import set_setting_by_blk_path, save_settings, get_setting_by_blk_path
from "gpuBenchmark" import initGraphicsAutodetect, getGpuBenchmarkDuration, startGpuBenchmark, closeGraphicsAutodetect, getPresetFor60Fps, getPresetForMaxQuality, getPresetForMaxFPS
from "%ui/helpers/time.nut" import secondsToStringLoc
from "%ui/components/modalWindows.nut" import addModalWindow, removeModalWindow
from "%ui/style/fontsStyle.nut" import fontBody, fontSub
from "%ui/components/textButton.nut" import Regular
from "%ui/hud/menus/options/quality_preset_common.nut" import graphicsPresetUpdate
from "dagor.time" import get_time_msec
from "%ui/style/designConst.nut" import midPadding, defTxtColor, titleTxtColor
from "%ui/ui_library.nut" import *

const WND_UID = "benchmark"
const BENCHMARK_FLAG_BLK = "graphics/benchmark"

let defTxtStyle = { color = titleTxtColor }.__update(fontBody)
let descTxtStyle = { color = defTxtColor }.__update(fontSub)

let benchmarkWindowSeen = nestWatched("benchmarkWindowSeen", get_setting_by_blk_path(BENCHMARK_FLAG_BLK))
let benchmarkWindowSeenUpdate = @(v) benchmarkWindowSeen.set(v)

enum BMState {
  WAIT = 0
  RUNNING = 1
  DONE = 2
}

let timeRem = Watched(0)
let runState = Watched(BMState.WAIT)
local timeEnd

let gpuBenchmarkPresets = [
  {
    presetId = "presetMaxQuality"
    getPresetFunc = getPresetForMaxQuality
  }
  {
    presetId = "presetMaxFPS"
    getPresetFunc = getPresetForMaxFPS
  }
  {
    presetId = "preset60Fps"
    getPresetFunc = getPresetFor60Fps
  }
]

function onTimer(){
  timeRem.set((timeEnd - get_time_msec()) / 1000)
  if (timeRem.get() <= 0){
    gui_scene.clearTimer(onTimer)
    runState.set(BMState.DONE)
  }
}

function closeWindow(){
  if (timeRem.get() > 0){
    gui_scene.clearTimer(onTimer)
  }
  closeGraphicsAutodetect()
  removeModalWindow(WND_UID)
}

function applyQuality(quality){
  graphicsPresetUpdate(quality)
  closeWindow()
}

function mkBMResult(){
  let res = gpuBenchmarkPresets.map(function(pres) {
    let quality = pres.getPresetFunc()
    let description = $"benchmark/{pres.presetId}/desc"
    return {
      size = FLEX_H
      flow = FLOW_VERTICAL
      children = [
        {
          flow = FLOW_HORIZONTAL
          size = FLEX_H
          valign = ALIGN_CENTER
          halign = ALIGN_CENTER
          gap = { size = FLEX }
          children = [
            Regular(loc($"benchmark/{pres.presetId}"), @() applyQuality(quality))
            {
              rendObj = ROBJ_TEXT
              hplace = ALIGN_RIGHT
              halign = ALIGN_RIGHT
              text = loc($"option/{quality}")
            }.__update(defTxtStyle)
          ]
        }
        {
          rendObj = ROBJ_TEXTAREA
          behavior = Behaviors.TextArea
          size = const [sw(20), SIZE_TO_CONTENT]
          text = loc(description)
        }.__update(descTxtStyle)
      ]
    }
  })
  return {
    size = FLEX_H
    flow = FLOW_VERTICAL
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    children = [
      {
        rendObj = ROBJ_TEXT
        text = loc("benchmark/result")
      }.__update(defTxtStyle)
      {
        size = const [pw(60), SIZE_TO_CONTENT]
        flow = FLOW_VERTICAL
        children = res
      }
      Regular(loc("Cancel"), @() closeWindow(), { hotkeys = [[$"^{JB.B} | Esc"]] })
    ]
  }
}

function runBenchmark(){
  initGraphicsAutodetect()
  
  timeEnd = get_time_msec() + (getGpuBenchmarkDuration().tointeger() + 1) * 1000
  gui_scene.clearTimer(onTimer)
  gui_scene.setInterval(0.5, onTimer)
  runState.set(BMState.RUNNING)
  startGpuBenchmark()
}

let textBlock = @() {
  watch = [runState, timeRem]
  size = FLEX_H
  children = runState.get() == BMState.DONE ? mkBMResult()
    : {
        size = FLEX
        valign = ALIGN_CENTER
        halign = ALIGN_CENTER
        children = {
          size = SIZE_TO_CONTENT
          rendObj = ROBJ_TEXT
          text = runState.get() == BMState.WAIT ? loc("benchmark/runTitle")
            : loc("benchmark/timeRemain", { time = secondsToStringLoc(timeRem.get()) })
        }.__update(defTxtStyle)
      }
}

let buttonsBlock = @() {
  flow = FLOW_HORIZONTAL
  vplace = ALIGN_BOTTOM
  gap = midPadding
  watch = [runState]
  children = runState.get() == BMState.WAIT ? [
      Regular(loc("Cancel"), @() closeWindow(), { hotkeys = [[$"^{JB.B} | Esc"]] })
      Regular(loc("benchmark/runBenchmarkBtn"), @() runBenchmark())
    ]
  : runState.get() == BMState.RUNNING ? Regular(loc("Cancel"), @() closeWindow()
    , { hotkeys = [[$"^{JB.B} | Esc"]] })
  : null
}

let benchmarkWnd = {
  flow = FLOW_VERTICAL
  rendObj = ROBJ_WORLD_BLUR_PANEL
  fillColor = Color(0,0,0,220)
  size = const [sw(50), sh(45)]
  valign = ALIGN_CENTER
  halign = ALIGN_CENTER
  gap = hdpx(30)
  children = [
    textBlock
    buttonsBlock
  ]
}

function gpuBenchmarkWnd(){
  set_setting_by_blk_path(BENCHMARK_FLAG_BLK, true)
  save_settings()
  runState.set(BMState.WAIT)
  benchmarkWindowSeenUpdate(true)
  addModalWindow({
    key = WND_UID
    size = const [sw(100), sh(100)]
    onClick = @() null
    valign = ALIGN_CENTER
    halign = ALIGN_CENTER
    children = benchmarkWnd
  })
}

let runBenchmarkBtn = Regular(loc("benchmark/runBenchmark"), gpuBenchmarkWnd,
  { skipDirPadNav = true })

function resetBenchmark(){
  set_setting_by_blk_path(BENCHMARK_FLAG_BLK, false)
  save_settings()
}

console_register_command(@() resetBenchmark(), "meta.resetBenchmark")

return { gpuBenchmarkWnd, runBenchmarkBtn, benchmarkWindowSeen }