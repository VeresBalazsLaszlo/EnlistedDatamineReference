import "%dngscripts/platform.nut" as platform
from "videomode" import is_rt_supported
from "dagor.debug" import logerr
from "dagor.system" import dgs_get_settings
from "%ui/hud/menus/options/options_lib.nut" import optionCtor, optionSpinner, loc_opt
from "%ui/hud/menus/options/quality_preset_common.nut" import BARE_MINIMUM, MINIMUM, LOW, MEDIUM, HIGH, ULTRA, RAY_TRACING, CUSTOM
  , graphicsPresetBlkPath, graphicsPresetUpdate, graphicsPreset
from "%ui/hud/menus/options/render_options.nut" import renderOptions
from "%ui/ui_library.nut" import *





let presetsRequired = freeze([BARE_MINIMUM, MINIMUM, LOW, MEDIUM, HIGH, ULTRA, RAY_TRACING])
let numPresets = presetsRequired.len()
let presets = [BARE_MINIMUM, MINIMUM, LOW, MEDIUM, HIGH, ULTRA]
if (is_rt_supported())
  presets.append(RAY_TRACING)
presets.append(CUSTOM)
let avPresets = freeze(presets)

let mapOptionsByPreset = {}

function addPresetOptionsFromBlk(blk) {
  for (local i = 0; i < blk.paramCount(); i += numPresets) {
    let optionName = blk.getParamName(i)
    let optionBlkPath = $"{blk.getBlockName()}/{optionName}"
    let qualities = []
    for (local j = 0; j < numPresets; j++) {
      if (blk.getParamName(i + j) != optionName) {
        logerr($"incorrect number of preset values for '{optionBlkPath}' option")
        i += j - numPresets
        break
      }
      qualities.append(blk.getParamValue(i + j))
    }
    if (qualities.len() != numPresets)
      continue
    foreach (opt in renderOptions) {
      if ("blkPath" in opt && opt.blkPath == optionBlkPath) {
        mapOptionsByPreset[opt] <- qualities
        break
      }
    }
  }
}

let presetsBlk = dgs_get_settings()?.pcGraphicalPresets
if (presetsBlk != null) {
  local numPresetsFromBlk = 0
  for (local i = 0; i < presetsBlk.paramCount(); i++) {
    if (presetsBlk.getParamName(i) == "presetNames")
      numPresetsFromBlk++
  }
  if (numPresets == numPresetsFromBlk) {
    for (local i = 0; i < presetsBlk.blockCount(); ++i)
      addPresetOptionsFromBlk(presetsBlk.getBlock(i))
  } else {
    logerr($"presets count mismatch {numPresets} != {numPresetsFromBlk}")
  }
}

let optGraphicsQualityPreset = optionCtor({
  name = loc("options/graphicsPreset")
  isAvailable = @() platform.is_pc
  widgetCtor = optionSpinner
  var = graphicsPreset
  setValue = graphicsPresetUpdate
  defVal = MEDIUM
  tab = "Graphics"
  available = avPresets
  valToString = loc_opt
  blkPath = graphicsPresetBlkPath
  hint = loc("guiHints/graphicsPreset")
})

foreach (o, q in mapOptionsByPreset){
  let opt = o
  let qualities = q
  let qNum = qualities.len()
  assert(qNum <= numPresets, "preset is missed")
  if (numPresets > qNum){
    qualities.resize(numPresets, qualities[qNum-1])
  }
  foreach (v in qualities){
    if ("available" in opt && !opt.available.contains(v)) {
      logerr($"incorrect preset value: /*{v}*/")
    }
  }
  opt.var.subscribe(function(_optVal){
    if (graphicsPreset.get() == CUSTOM)
      return
    if (!(opt?.isAvailable() ?? true))
      return
    defer(function() {
      if (opt.var.get() == qualities?[presetsRequired.indexof(graphicsPreset.get())])
        return
      graphicsPresetUpdate(CUSTOM)
    })
  })
}

function getOptionsByPreset(gp) {
  if (gp == CUSTOM || !optGraphicsQualityPreset.isAvailable())
    return null
  let idx = presetsRequired.indexof(gp)
  if (idx==null)
    return null
  let changedOptsVals = []
  let presetOptsVals = []
  foreach (o, q in mapOptionsByPreset){
    let opt = o
    let qualities = q
    if ("isAvailable" in opt && !opt.isAvailable())
      continue
    if ("isDisabled" in opt && opt.isDisabled())
      continue
    let val = qualities[idx]
    presetOptsVals.append({opt, val})
    if (opt?.var.get() != val)
      changedOptsVals.append({opt, val})
  }
  return {presetOptsVals, changedOptsVals}
}

function setOptionsByOptVals(changedOptsVals){
  foreach (i in changedOptsVals) {
    let {opt, val} = i
    if ("setValue" in opt)
      opt.setValue(val)
    else if ("var" in opt)
      opt.var.set(val)
  }
}

graphicsPreset.subscribe(@(v) setOptionsByOptVals(getOptionsByPreset(v)?.changedOptsVals ?? []))
setOptionsByOptVals(getOptionsByPreset(graphicsPreset.get())?.changedOptsVals ?? [])

return {
  optGraphicsQualityPreset
}
