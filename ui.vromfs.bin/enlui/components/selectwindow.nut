from "%ui/components/textButton.nut" import Secondary
from "%ui/components/scrollbar.nut" import makeVertScroll
from "%ui/components/text.nut" import dtext
from "%ui/ui_library.nut" import *
from "%sqstd/underscore.nut" import chunk

let textInput = require("%ui/components/textInput.nut")
let modalPopupWnd = require("%ui/components/modalPopupWnd.nut")

const hvrCl = Color(0,0,0)
const nrmClr = Color(180,180,180)
function mkSelectBtn(name, opt, state, close=null) {
  function onClick() {
    state.set(opt)
    close?()
  }
  let size = const [fsh(30), SIZE_TO_CONTENT]
  return watchElemState( function(sf) {
    let group = ElemGroup()
    return {
      watch = [state]
      group
      behavior = [Behaviors.Button]
      clipChildren = true
      padding = const [hdpx(2), hdpx(10)]
      children = {
        group
        behavior = Behaviors.Marquee
        size = FLEX_H
        scrollOnHover = true
        children = {
          rendObj = ROBJ_TEXT
          text = name
          color = sf & S_HOVER ? hvrCl : nrmClr
        }
      }
      rendObj = ROBJ_BOX
      fillColor = sf & S_HOVER ? nrmClr : 0
      borderWidth = state.get() == opt ? hdpx(1) : 0
      onClick
      size
    }
  })
}

let mkMkColumn = @(options, buttonCtor) {
  flow = FLOW_VERTICAL
  children = options.map(buttonCtor)
}

let mkSelectWindow = kwarg(function(
    uid, optionsState, state, filterState=null, title=null, filterPlaceHolder=null, columns=4, titleStyle=null, mkTxt = @(v) v,
    onAttach=null
  ) {
  assert(isObservable(state))
  let titleComp = title!=null ? dtext(title, {hplace = ALIGN_CENTER}.__update(titleStyle ?? {})) : null
  let filter = filterState!=null ? textInput(filterState, {placeholder = filterPlaceHolder ?? loc("filter")}) : null
  let buttonCtor = @(opt) mkSelectBtn(mkTxt(opt), opt, state, @() modalPopupWnd.remove(uid))
  let mkColumn = @(options) mkMkColumn(options, buttonCtor)
  let selectWindow = @() {
    size = const [sw(70), sh(80)]
    hplace = ALIGN_CENTER
    vplace = ALIGN_CENTER
    color = Color(0,0,0,120)
    stopMouse = true
    key = uid
    watch = [optionsState]
    onAttach
    flow = FLOW_VERTICAL
    rendObj = ROBJ_FRAME
    borderWidth = hdpx(1)
    gap = hdpx(5)
    children = [
      titleComp
      filter
      makeVertScroll({
        size = FLEX_H
        flow = FLOW_HORIZONTAL
        children = chunk(optionsState.get(), optionsState.get().len()/columns + 1).map(mkColumn)
      })
    ]
    padding = hdpx(20)
  }
  return @() modalPopupWnd.add([0, 0],
    {
      size = const [sw(100), sh(100)]
      uid
      fillColor = Color(0,0,0)
      padding = 0
      popupFlow = FLOW_HORIZONTAL
      popupValign = ALIGN_TOP
      popupOffset = 0
      margin = 0
      pos = const [0,0]
      children = selectWindow
      popupBg = { rendObj = ROBJ_WORLD_BLUR_PANEL, fillColor = Color(0,0,0,120) }
    }
  )
})

function mkOpenSelectWindowBtn(state, title, openMenu, mkTxt = @(v) v){
  return @() {
    watch = state
    flow = FLOW_HORIZONTAL
    size = FLEX_H
    padding = const [0, hdpx(5)]
    valign = ALIGN_CENTER
    children = [
      dtext(title, {color = Color(180,180,180), padding=0, margin=0})
      {size = const [FLEX, 0]}
      Secondary(mkTxt(state.get()), openMenu, {
        minWidth = hdpx(50)
      })
    ]
  }
}


return {
  mkSelectWindow
  mkOpenSelectWindowBtn
}