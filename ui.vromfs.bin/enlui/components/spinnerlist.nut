import "%ui/components/fontawesome.map.nut" as fa
from "%ui/style/fontsStyle.nut" import fontBody, fontawesome
from "%ui/style/colors.nut" import BtnBgHover, BtnBgActive, ControlBgOpaque, TextHighlight, TextDefault, Active
from "%ui/style/sounds.nut" import buttonSound
from "%ui/control/active_controls.nut" import isTouch
from "%ui/ui_library.nut" import *

let fillColor = @(sf, active) !active ? ControlBgOpaque
  : sf & S_HOVER ? BtnBgHover
  : BtnBgActive

let spinnerLeftLoc = loc("spinner/prevValue", "Previous value")
let spinnerRightLoc = loc("spinner/nextValue", "Next value")

let mkSpinnerLine = @(sf, indexWatch, total, setValue, allValues, group) @() {
  watch = indexWatch
  size = FLEX
  gap = hdpx(4)
  padding = const [hdpx(2), hdpx(4), hdpx(2), 0]
  margin = const [0, 0, hdpx(4), 0]
  group
  flow = FLOW_HORIZONTAL
  children = sf & S_HOVER ? array(total).map(@(_, idx) {
    size = FLEX
    valign = ALIGN_BOTTOM
    children = {
      rendObj = ROBJ_SOLID
      size = const [FLEX, hdpx(4)]
      color = indexWatch.get() != idx ? ControlBgOpaque
        : sf & S_HOVER ? TextHighlight
        : TextDefault
    }
    skipDirPadNav = true
    behavior = Behaviors.Button
    onClick = @() setValue(allValues[idx])
    }) : null
}

let mkSpinnerBtn = @(isEnabled, icon, action)
  watchElemState(@(sf){
    rendObj = ROBJ_BOX
    watch = isEnabled
    borderWidth = (sf & S_HOVER) && isEnabled.get() ? hdpx(2) : 0
    sound = buttonSound
    borderColor = BtnBgHover
    borderRadius = hdpx(2)
    behavior = Behaviors.Button
    onClick = @() isEnabled.get() ? action() : null
    padding = const [0, hdpx(10)]
    vplace = ALIGN_CENTER
    skipDirPadNav = true
    children = {
      rendObj = ROBJ_INSCRIPTION
      text = icon
      hplace = ALIGN_CENTER
      vplace = ALIGN_CENTER
      color = fillColor(sf, isEnabled.get())
     }.__update(fontawesome, {fontSize = hdpx(35)})
   }
  )

local spinner = kwarg(function(curValue, allValues, setValue = null,
  valToString = null, xmbNode= null, group = null, isEqual = null, stateFlags = null 
) {
  setValue = setValue ?? @(v) curValue.set(v)
  valToString = valToString ?? @(v) v
  let valuesCount = max(allValues.len(), 1)
  let maxIdx = valuesCount - 1
  let curIdx = Computed(@() isEqual != null
    ? allValues.findindex(@(value) isEqual(value, curValue.get()))
    : allValues.indexof(curValue.get()))

  let isLeftBtnEnabled = Computed(@() curIdx.get() != null && curIdx.get() > 0)
  let isRightBtnEnabled = Computed(@() curIdx.get() != null && curIdx.get() < maxIdx)
  function leftBtnAction() { if (isLeftBtnEnabled.get()) setValue(allValues[curIdx.get() - 1]) }
  function rightBtnAction() { if (isRightBtnEnabled.get()) setValue(allValues[curIdx.get() + 1]) }

  let hotkeysElem = @(){
    watch = [isLeftBtnEnabled, isRightBtnEnabled]
    key = $"hotkeys{isLeftBtnEnabled.get()}{isRightBtnEnabled.get()}"
    hotkeys = [
      ["Left | J:D.Left",
        { action = leftBtnAction, sound = buttonSound,
          description = isLeftBtnEnabled.get() ? spinnerLeftLoc : { skip = true }
        }
      ],
      ["Right | J:D.Right",
        { action = rightBtnAction, sound = buttonSound,
          description = isRightBtnEnabled.get() ? spinnerRightLoc : { skip = true }
        }
      ]
    ]
  }

  let labelText = @() {
    watch = curValue
    behavior = Behaviors.Marquee
    rendObj = ROBJ_TEXT
    vplace = ALIGN_CENTER
    valign = ALIGN_CENTER
    text = valToString(curValue.get())
    color = Active
    size = FLEX
    scrollOnHover = true
    clipChildren = true
    group
  }.__update(fontBody)

  let buttons = {
    flow = FLOW_HORIZONTAL
    size = SIZE_TO_CONTENT
    vplace = ALIGN_CENTER
    gap = hdpx(5)
    children = [
      mkSpinnerBtn(isLeftBtnEnabled, fa["angle-left"], leftBtnAction)
      mkSpinnerBtn(isRightBtnEnabled, fa["angle-right"], rightBtnAction)
    ]
  }

  return watchElemState(@(sf) {
      behavior = Behaviors.Button
      watch = curIdx
      xmbNode
      group
      eventPassThrough = isTouch.get()
      size = FLEX
      flow = FLOW_HORIZONTAL
      children = [
        {
          size = FLEX
          children = [
            labelText
            mkSpinnerLine(sf, curIdx, valuesCount, setValue, allValues,  group)
          ]
        }
        buttons
        sf & S_HOVER ? hotkeysElem : null
      ]
    }, {stateFlags})
})



return spinner