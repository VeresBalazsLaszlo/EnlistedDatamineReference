import "%ui/components/textButton.style.nut" as defStyle
import "%ui/style/colors.nut" as colors
from "%ui/style/designConst.nut" import titleTxtColor, commonBtnHeight, hoverTxtColor, hoverPanelBgColor, darkTxtColor, darkPanelBgColor, brightAccentColor
  , brightAccentColorActive, hoverBgTransp, activeBgTransp, defBgPurchase, defBgPurchaseActive, textBgBlurColor, defBgPrimary
  , defBgPrimaryActive, commonBorderRadius, disabledTxtCtor, defTxtColor, disabledTxtColorBtn, defBgBtn, defBgHoverBtn
  , defBgActiveBtn, defBdColorBtn, defBdColor, disabledLoginBgColor
from "%ui/components/glareAnimation.nut" import glareAnimation, animChildren
from "%ui/ui_library.nut" import *

let regularStyle = freeze({
  defTxtColor = defTxtColor
  hoverTxtColor = darkTxtColor
  activeTxtColor = defTxtColor
  disabledTxtColor = disabledTxtColorBtn

  defBdColor = defBdColorBtn
  hoverBdColor = defBdColor
  activeBdColor = defBdColor
  disabledBdColor = defBdColorBtn
  borderWidth = hdpx(1)
  borderRadius = commonBorderRadius

  defBgColor = defBgBtn
  hoverBgColor = defBgHoverBtn
  activeBgColor = defBgActiveBtn
  disabledBgColor = 0
})

let loginBtnStyle = freeze({
  defTxtColor = darkTxtColor
  hoverTxtColor = darkTxtColor
  activeTxtColor = darkTxtColor
  disabledTxtColor = disabledTxtColorBtn

  defBdColor = colors.BtnActionBdNormal
  hoverBdColor = colors.BtnActionBdFocused
  activeBdColor = colors.BtnActionBdActive
  disabledBdColor = defBdColorBtn
  borderWidth = 0
  borderRadius = 0

  defBgColor = brightAccentColor
  hoverBgColor = colors.BtnActionBgFocused
  activeBgColor = colors.BtnActionBgActive
  disabledBgColor = 0
})

let loginBtnStyleDisabled = freeze({
  defTxtColor  = darkTxtColor
  hoverTxtColor = colors.BtnActionTextFocused
  activeTxtColor  = colors.BtnActionTextActive
  disabledTxtColor = disabledTxtColorBtn

  defBdColor = disabledLoginBgColor
  hoverBdColor = colors.BtnActionBdFocused
  activeBdColor = colors.BtnActionBdActive
  disabledBdColor = defBdColorBtn
  borderWidth = 0
  borderRadius = 0

  defBgColor = disabledLoginBgColor
  hoverBgColor = colors.BtnActionBgFocused
  activeBgColor = colors.BtnActionBgActive
  disabledBgColor = 0
})

let purchaseStyle = freeze({
  defTxtColor = titleTxtColor
  hoverTxtColor = darkTxtColor
  activeTxtColor = textBgBlurColor
  disabledTxtColor = disabledTxtCtor

  defBdColor = defBgPurchase
  hoverBdColor = defBdColor
  activeBdColor = defBdColor
  disabledBdColor = defBdColorBtn
  borderWidth = hdpx(1)
  borderRadius = commonBorderRadius

  defBgColor = defBgPurchase
  hoverBgColor = defBgHoverBtn
  activeBgColor = defBgPurchaseActive
  disabledBgColor = defBgPurchaseActive
})

let primaryStyle = freeze({
  defTxtColor = titleTxtColor
  hoverTxtColor = darkTxtColor
  activeTxtColor = defTxtColor
  disabledTxtColor = disabledTxtColorBtn

  defBdColor = defBgPrimary
  hoverBdColor = defBdColor
  activeBdColor = defBdColor
  disabledBdColor = defBdColorBtn
  borderWidth = hdpx(1)
  borderRadius = commonBorderRadius

  defBgColor = defBgPrimary
  hoverBgColor = defBgHoverBtn
  activeBgColor = defBgPrimaryActive
  disabledBgColor = defBgPrimaryActive
})

let faStyle = freeze({
  defTxtColor = defStyle.TextNormal
  hoverTxtColor = defStyle.TextHover
  activeTxtColor = defStyle.TextActive
  disabledTxtColor = defStyle.TextActive

  defBdColor = defBgPrimary
  hoverBdColor = defBdColor
  activeBdColor = defBdColor
  disabledBdColor = defBdColorBtn
  borderWidth = 0
  borderRadius = commonBorderRadius

  defBgColor = 0
  hoverBgColor = 0
  activeBgColor = 0
  disabledBgColor = 0
})

let pressedBtnStyle = freeze({
  defTxtColor = titleTxtColor
  hoverTxtColor = hoverTxtColor
  activeTxtColor = defTxtColor
  disabledTxtColor = disabledTxtColorBtn

  defBdColor = defBdColorBtn
  hoverBdColor = defBdColor
  activeBdColor = defBdColor
  disabledBdColor = defBdColorBtn
  borderWidth = hdpx(1)
  borderRadius = commonBorderRadius

  defBgColor = darkPanelBgColor
  hoverBgColor = hoverPanelBgColor
  activeBgColor = defBgActiveBtn
  disabledBgColor = 0
})

let accentBtnStyle = freeze({
  defTxtColor = darkTxtColor
  hoverTxtColor = darkTxtColor
  activeTxtColor = darkTxtColor
  disabledTxtColor = disabledTxtColorBtn

  defBdColor = brightAccentColor
  hoverBdColor = defBdColor
  activeBdColor = defBdColor
  disabledBdColor = defBdColorBtn
  borderWidth = hdpx(1)
  borderRadius = commonBorderRadius

  defBgColor = brightAccentColor
  hoverBgColor = defBgHoverBtn
  activeBgColor = brightAccentColorActive
  disabledBgColor = 0
})

let transpBtnStyle = freeze({
  defTxtColor = defTxtColor
  hoverTxtColor = darkTxtColor
  activeTxtColor = darkTxtColor
  disabledTxtColor = disabledTxtColorBtn

  defBdColor = defBdColorBtn
  hoverBdColor = defBdColor
  activeBdColor = defBdColor
  disabledBdColor = defBdColorBtn
  borderWidth = 0
  borderRadius = commonBorderRadius

  defBgColor = 0
  hoverBgColor = hoverBgTransp
  activeBgColor = activeBgTransp
  disabledBgColor = 0
})

let purchaseButtonStyle = freeze({
  size = [SIZE_TO_CONTENT, commonBtnHeight]
  style = purchaseStyle
})

let primaryBtnAnimation = [
  { prop = AnimProp.fillColor, from = Color(1,79,181), to = 0xfa0182b5
    easing = CosineFull, duration = 1.5, loop = true, play = true }
]

let bgChild = freeze({
  key = "bgChild"
  rendObj = ROBJ_BOX
  borderWidth = hdpx(1)
  borderRadius = commonBorderRadius
  borderColor = defBgPrimary
  size = FLEX
  animations = primaryBtnAnimation
})

let fgChild = animChildren(glareAnimation())

let primaryFlatButtonStyle = freeze({
  size = [SIZE_TO_CONTENT, commonBtnHeight]
  clipChildren = true
  style = primaryStyle
  overrideBySf = @(sf, isEnabled) (sf & S_HOVER) || (sf & S_ACTIVE) || !isEnabled
    ? null
    : {
        bgChild
        fgChild
      }
})


return freeze({
  purchaseButtonStyle
  primaryFlatButtonStyle
  primaryBtnAnimation
  bgChild
  fgChild
  loginBtnStyle
  loginBtnStyleDisabled
  primaryStyle
  faStyle
  accentBtnStyle
  pressedBtnStyle
  transpBtnStyle
  regularStyle
})