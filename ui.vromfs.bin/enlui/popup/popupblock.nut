from "%ui/style/fontsStyle.nut" import fontBody
from "%ui/popup/popupsState.nut" import popupsGen, getPopups
from "%ui/components/textButton.nut" import Regular
from "%ui/style/colors.nut" import BtnBgNormal
from "%dngscripts/sound_system.nut" import sound_play
from "%ui/state/safeArea.nut" import safeAreaBorders
from "%ui/style/designConst.nut" import bigGap
from "%ui/ui_library.nut" import *

const HighlightNeutral = Color(230, 230, 100)
const HighlightFailure = Color(255,60,70)

let POPUP_STYLE = {
  animColor = HighlightNeutral
  sound = "ui/enlist/notification"
}

let styles = {
  error = {
    animColor = HighlightFailure
    sound = "ui/enlist/notification"
  }
  silence = {
    animColor = HighlightNeutral
  }
}
let popupWidth = calc_comp_size({rendObj = ROBJ_TEXT text = "" size=const [fontH(1000), SIZE_TO_CONTENT]}.__update(fontBody))[0]
let defPopupBlockPos = [-safeAreaBorders.get()[1] - popupWidth, -(safeAreaBorders.get()[2] + 4*bigGap)]
let popupBlockStyle = Watched({
    hplace = ALIGN_RIGHT
    vplace = ALIGN_BOTTOM
    pos = defPopupBlockPos
})

function popupBlock() {
  let children = []
  let popups = getPopups()
  foreach (idx, p in popups) {
    let popup = p
    let prevVisIdx = popup.visibleIdx.get()
    let curVisIdx = popups.len() - idx
    if (prevVisIdx != curVisIdx) {
      let prefix = curVisIdx > prevVisIdx ? "popupMoveTop" : "popupMoveBottom"
      anim_start(prefix + popup.id)
    }

    let style = styles?[popup?.styleName] ?? POPUP_STYLE
    if (prevVisIdx == -1 && style?.sound != null)
      sound_play(style.sound)

    children.append({
      size = SIZE_TO_CONTENT
      stopMouse = true
      stopHover = true

      children = Regular(popup.text, @() popup.click(), {
        btnHeight = SIZE_TO_CONTENT
        textParams = {
          rendObj = ROBJ_TEXTAREA
          behavior = Behaviors.TextArea
          size = [popupWidth, SIZE_TO_CONTENT]
        }.__update(fontBody)
        key = $"popup_block_{popup.uid}"
        animations = [
          { prop=AnimProp.fillColor, from=style.animColor, to=BtnBgNormal, easing=OutCubic, duration=0.5, play=true }
        ]
      })

      key = $"popup_{popup.uid}"
      transform = true
      animations = [
        { prop=AnimProp.opacity, from=0.0, to=1.0, duration=0.5, play=true, easing=OutCubic }
        { prop=AnimProp.translate, from=[0,100], to=[0, 0], duration=0.3, trigger = $"popupMoveTop{popup.id}", play = true, easing=OutCubic }
        { prop=AnimProp.translate, from=[0,-100], to=[0, 0], duration=0.3, trigger = $"popupMoveBottom{popup.id}", easing=OutCubic }
      ]

      behavior = Behaviors.RecalcHandler
      onRecalcLayout = @(_initial) popup.visibleIdx.set(curVisIdx)
    })
  }
  let {hplace, vplace, pos = defPopupBlockPos} = popupBlockStyle.get()
  return {
    watch = [popupsGen, safeAreaBorders, popupBlockStyle]
    pos = pos
    size = SIZE_TO_CONTENT
    hplace = hplace
    vplace = vplace
    flow = FLOW_VERTICAL
    children = children
  }
}

return {popupBlock, popupBlockStyle, defPopupBlockPos}
