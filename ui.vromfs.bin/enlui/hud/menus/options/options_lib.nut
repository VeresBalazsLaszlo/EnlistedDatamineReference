import "%ui/components/optionTextSlider.nut" as mkSliderWithText
import "%ui/components/optionCheckBox.nut" as optionCheckBox
import "%ui/components/optionCombo.nut" as optionCombo
import "%ui/components/optionSpinner.nut" as optionSpinner
import "%ui/components/optionSlider.nut" as optionSlider
import "%ui/components/faComp.nut" as faComp
from "%ui/style/fontsStyle.nut" import fontBody, fontSub
from "%ui/style/cursors.nut" import setTooltip
from "settings" import get_setting_by_blk_path
from "math" import fabs
from "%ui/options/mkOnlineSaveData.nut" import mkOnlineSaveData
from "%sqstd/math.nut" import round_by_value
from "%ui/ui_library.nut" import *

const WARNING_COLOR = 0xFFFF3300
let iconSize = const [hdpx(13), hdpx(13)]

let getOnlineSaveData = memoize(@(saveId, defValueFunc, validateFunc = @(v) v)
  mkOnlineSaveData(saveId, defValueFunc, validateFunc), 1)

function defCmp(a, b) {
  if (typeof a != "float")
    return a == b
  let absSum = fabs(a) + fabs(b)
  return absSum < 0.00001 ? true : fabs(a - b) < 0.0001 * absSum
}

let loc_opt = @(s) loc($"option/{s}")

function optionPercentTextSliderCtor(opt, group, xmbNode) {
  return mkSliderWithText(opt, group, xmbNode,
    @(v) "{0}%".subst((opt?.unit != null ? round_by_value(v, opt.unit) : v) * (opt?.mult ?? 1)))
}

let optionDisabledText = @(text) {
  size = FLEX_H
  clipChildren = true
  rendObj = ROBJ_TEXT 
  text
  color = Color(90,90,90)
}.__update(fontBody)

let mkDisableableCtor = @(disableWatch, enabledCtor, disabledCtor = optionDisabledText)
  function(opt, group, xmbNode) {
    let enabledWidget = enabledCtor(opt, group, xmbNode)
    return @() {
      watch = disableWatch
      size = FLEX
      valign = ALIGN_CENTER
      children = disableWatch.get() == null ? enabledWidget
        : disabledCtor(disableWatch.get())
    }
  }

function optionCtor(opt){
  if (opt?.originalVal == null)
    opt.originalVal <- (type(opt?.blkPath)==type("")
      ? get_setting_by_blk_path(opt.blkPath)
      : opt?.var
        ? opt.var.get()
        : null
    ) ?? opt?.defVal
  if ("convertFromBlk" in opt)
    opt.originalVal = opt.convertFromBlk(opt.originalVal)

  if ("var" not in opt)
    opt.var <- Watched(opt.originalVal)
  if ("isEqual" not in opt)
    opt.isEqual <- defCmp
  if ("typ" not in opt && "defVal" in opt)
    opt.typ <- type(opt.defVal)
  return freeze(opt)
}

function isOption(opt){
  if ("isSeparator" in opt)
    return true
  if ("name" not in opt || "var" not in opt || "widgetCtor" not in opt)
    return false
  return true
}

let tinyQuestion = faComp("question-circle", {
  size = iconSize
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  rendObj = ROBJ_INSCRIPTION
  fontSize = iconSize[1]
  color = WARNING_COLOR
})

let mkOptionWarning = @(isShownWatch, text, hint = null) function() {
  let watch = [isShownWatch]
  if (!isShownWatch.get())
    return { watch }

  return {
    watch
    size = FLEX_H
    flow = FLOW_HORIZONTAL
    valign = ALIGN_CENTER
    children = [
      {
        rendObj = ROBJ_TEXT
        text
        color = WARNING_COLOR
      }.__update(fontSub)
      tinyQuestion
    ]
    behavior = Behaviors.Button
    onHover = hint == null ? null : @(on) setTooltip(on ? hint : null)
  }
}

return {
  defCmp
  optionCtor
  isOption
  loc_opt
  getOnlineSaveData
  mkSliderWithText
  optionPercentTextSliderCtor
  optionSlider
  optionCombo

  optionCheckBox


  mkDisableableCtor
  optionSpinner
  mkOptionWarning
}
