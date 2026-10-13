from "%ui/style/designConst.nut" import titleTxtColor, defTxtColor, bonusColor
from "%ui/components/defcomps.nut" import note
from "%ui/currency/premiumComp.nut" import premiumImage
from "%ui/ui_library.nut" import *

let trim = @(str) "".join((str ?? "").tostring().split())

function strikeThrough(child) {
  return {
    rendObj = ROBJ_VECTOR_CANVAS
    commands = [
      [VECTOR_WIDTH, hdpx(1)],
      [VECTOR_COLOR, defTxtColor],
      [VECTOR_LINE, 0, 90, 100, 20]
    ]
    padding = const [0, hdpx(5)]
    margin = const [0, hdpx(5), 0, 0]
    children = child
  }
}

function mkValueWithBonus(commonValue, bonusValue, style = {}) {
  let commonWatch = isObservable(commonValue) ? commonValue : Computed(@() commonValue)
  let bonusWatch = isObservable(bonusValue) ? bonusValue : Computed(@() bonusValue)
  let watches = [commonWatch, bonusWatch]
  return @() bonusWatch.get() != null
    ? {
        watch = watches
        flow = FLOW_HORIZONTAL
        valign = ALIGN_CENTER
        children = [
          strikeThrough(note(trim(commonWatch.get())).__update(style))
          premiumImage(hdpx(20), { pos = const [0, hdpx(2)] })
          note({ text = trim(bonusWatch.get()), color = bonusColor })
            .__update(style)
        ]
      }
    : note({ watch = watches, text = trim(commonWatch.get()), color = titleTxtColor })
        .__update(style)
}

return mkValueWithBonus