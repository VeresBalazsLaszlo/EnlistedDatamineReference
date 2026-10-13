import "%ui/control/gui_buttons.nut" as JB
import "%ui/style/cursors.nut" as cursors
import "%ui/components/mkPieMenuBase.nut" as mkPieMenuDarg
import "dainput2" as dainput
from "%ui/control/active_controls.nut" import isGamepad
from "%ui/components/uiHotkeysHint.nut" import mkHotkey
from "%ui/hud/style.nut" import HUD_TIPS_HOTKEY_FG
from "%ui/ui_library.nut" import *
from "types" import String, Function

function locAction(action) {
  return loc($"controls/{action}", action)
}
let closeHotkey = $"^{JB.B} | Esc"

const white = Color(255,255,255)
const dark = Color(200,200,200)
const disabledColor = Color(60,60,60)
const curTextColor = Color(250,250,200,200)
const defTextColor = Color(150,150,150,50)
const disabledTextColor = Color(50, 50, 50, 50)

let mkDefTxtCtor = @(text, available) function(curIdx, idx) {
  if (!(isObservable(text)))
    text = Watched(text)
  let isActive = Computed(@() curIdx.get() == idx)
  return watchElemState(@(sf) {
    watch = [available, text, isActive]
    rendObj = ROBJ_TEXTAREA
    behavior = Behaviors.TextArea
    text = text.get()
    color = !available.get() ? disabledTextColor
      : (sf & S_HOVER) || isActive.get() ? curTextColor
      : defTextColor
    hplace = ALIGN_CENTER
    vplace = ALIGN_CENTER
    maxWidth = hdpx(140)
    valign = ALIGN_CENTER
  })
}

let mkDefImageCtor = @(elemSize) function (curImage, fallbackImage=null, available = Watched(true)) {
  if (curImage == null)
    return null
  let fallbackPicture = fallbackImage != null ? Picture(fallbackImage) : null
  return function(curIdx, idx) {
    if (!(isObservable(curImage)))
      curImage = Watched(curImage)
    let isActive = Computed(@() curIdx.get() == idx)
    return watchElemState(@(sf) {
      rendObj = ROBJ_IMAGE
      watch = [available, curImage, isActive]
      image = curImage.get() == "" ? fallbackPicture : Picture(curImage.get())
      fallbackImage = fallbackPicture
      color = !available.get() ? disabledColor
        : (sf & S_HOVER) || isActive.get() ? white
        : dark
      size = elemSize
      hplace = ALIGN_CENTER
      vplace = ALIGN_CENTER
    })
  }
}


function mkBlurBack(radius) {
  let size = array(2, 2 * radius * 1.02)
  return {
    size
    rendObj = ROBJ_MASK
    image = Picture("!ui/uiskin/white_circle.svg:{0}:{0}:K".subst(min(size[0].tointeger(), 620)))
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    children = {
      rendObj = ROBJ_WORLD_BLUR
      size
      color = Color(190,190,190,190)
    }
  }
}

let mkSelectedActionHint = @(curIdx, actions, radius) function() {
  let watch = [ curIdx ]
  let action = actions?[curIdx.get()]
  if (action == null)
    return { watch }

  let { available = Watched(true) } = action
  let isAvailable = available.get()
  watch.append(available)

  local text = isAvailable ? action?.text : action?.disabledtext
  if (!isObservable(text))
    text = Watched(text)
  watch.append(text)

  return {
    watch
    rendObj = ROBJ_TEXTAREA
    size = SIZE_TO_CONTENT
    valign = ALIGN_CENTER
    hplace = ALIGN_CENTER
    halign = ALIGN_CENTER
    maxWidth = 0.7 * radius
    behavior = Behaviors.TextArea
    color = isAvailable ? curTextColor : disabledTextColor
    text = text.get()
  }
}

function mkPieMenuRoot(actions, curIdx, radius, showPieMenu, key = null, stickNo = 1) {
  function closeWithoutClick() {
    curIdx.set(null)
    showPieMenu.set(false)
  }

  let curHoveredIdx = Watched(null)
  curHoveredIdx.subscribe(function(v) { if (v != null || !isGamepad.get()) curIdx.set(v) })

  let desc = {
    key
    size = FLEX
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    sound = {
      attach = "ui/map_on"
      detach = "ui/map_off"
    }
    behavior = DngBhv.ActivateActionSet
    actionSet = "PieMenu"
    hotkeys = [
      [closeHotkey, {description = {skip = true}, action = closeWithoutClick}],
    ]

    children = [
      mkBlurBack(radius)
      mkPieMenuDarg({
        stickNo
        devId = isGamepad.get() ? DEVID_JOYSTICK : DEVID_MOUSE
        onClick = @(_) showPieMenu.set(false) 
        radius = radius
        onDetach = @() actions?[curIdx.get()].onClick()
        onAttach = @() curIdx.set(null)
        curIdx
        curHoveredIdx
        children = [{
          hplace = ALIGN_CENTER
          vplace = ALIGN_CENTER
          children = mkSelectedActionHint(curIdx, actions, radius)
        }]
        objs = actions
      })
    ]
  }

  if (!isGamepad.get())
    desc.cursor <- cursors.normal

  return desc
}

let mkOnSelect = @(action, disabledAction, available)
  @() available.get() ? action() : disabledAction?()

let mkOnClick = @(onSelect, showPieMenu) function() {
  onSelect()
  showPieMenu.set(false)
}

let mkOnHotkey = @(curIdx, idx, showPieMenu) function() {
  curIdx.set(idx)
  showPieMenu.set(false)
}

function textFunc(text) {
  return {
    fillColor = HUD_TIPS_HOTKEY_FG
    borderWidth = 0
    borderRadius = hdpx(2)
    size = SIZE_TO_CONTENT
    padding = const [0, hdpx(3)]
    rendObj = ROBJ_BOX
    children = [
      {rendObj = ROBJ_TEXT text = text color=Color(0,0,0)}
    ]
  }
}

function mkCtor(ctor, mkDefCtor, image, fallbackImage, available, text, hotkey, hotkeyAction) {
  available = available ?? Watched(true)
  let main = ctor
    ?? mkDefCtor(image, fallbackImage, available)
    ?? mkDefTxtCtor(text ?? "", available)
  return @(curIdx, idx) function() {
    let children = [main(curIdx, idx)]
    if (hotkey != null)
      if (available.get())
        children.insert(0, mkHotkey(hotkey, hotkeyAction, { textFunc }))
      else
        children.insert(0, { hotkeys = [[hotkey, @() null]] })
    return {
      watch = [isGamepad, available]
      halign = ALIGN_CENTER
      gap = isGamepad.get() ? hdpx(1) : hdpx(5)
      valign = ALIGN_CENTER
      flow = isGamepad.get() ? FLOW_VERTICAL : FLOW_HORIZONTAL
      children
    }
  }
}

const KEYBOARD_HOTKEY_MAX_NUM = 9

let idxToKbHotkey = @(idx) ((idx + 1) % (KEYBOARD_HOTKEY_MAX_NUM + 1)).tostring()
let mkKbdHotkeyStub = @(actionsCount) "{0}".subst(" | ".join(
  array(KEYBOARD_HOTKEY_MAX_NUM - min(actionsCount, KEYBOARD_HOTKEY_MAX_NUM))
    .map(@(_, idx) idx + actionsCount + 1)))

function filterAndUpdateActions(actions, showPieMenu, mkDefCtor, curIdx){
  actions = actions.map(function(a, idx) {
    let available = isObservable(a?.available)
      ? a.available
      : Watched(a?.available ?? true)
    if (a == null
       || (a?.action instanceof String
           
           && dainput.get_action_handle(a?.action, 0xFFFF) == dainput.BAD_ACTION_HANDLE))
      return null
    let text = a?.text ?? ((a.action instanceof String) ? locAction(a.action) : null)
    let action = a.action instanceof Function
      ? a.action
      : @() dainput.send_action_event(dainput.get_action_handle(a.action, 0xFFFF))
    let onSelect = mkOnSelect(action, a?.disabledAction, available)
    let onClick = mkOnClick(onSelect, showPieMenu)
    let onHotkey = mkOnHotkey(curIdx, idx, showPieMenu)
    let kbdHotkey = "{0}".subst(idxToKbHotkey(idx))
    let ctor = mkCtor(a?.ctor, mkDefCtor, a?.image, a?.fallbackImage, available, text, kbdHotkey, onHotkey)
    return a.__merge({
      text
      action
      ctor
      disabledtext = a?.disabledtext ?? loc("pieMenu/actionUnavailable")
      onSelect
      onClick
      available
      idx
    })
  })
  return actions
}

function mkPieMenu(actions, curIdx = Watched(null), showPieMenu = Watched(false),
  radius = Watched(hdpx(350)), elemSize = null, key = null, stickNo = 1
){
  elemSize = elemSize ?? Computed(@() array(2, (0.4 * radius.get()).tointeger()))

  return function(){
    let mkDefCtor = mkDefImageCtor(elemSize.get())
    let actionsV = filterAndUpdateActions(actions.get(), showPieMenu, mkDefCtor, curIdx)
    let kbdHotkeyStub = mkKbdHotkeyStub(actionsV.len())
    let res = { watch = [showPieMenu, isGamepad, actions, elemSize, radius] }
    if (!showPieMenu.get())
      return res

    return res.__update({
      size = FLEX
      children = [
        mkPieMenuRoot(actionsV, curIdx, radius.get(), showPieMenu, key, stickNo)
        { key = kbdHotkeyStub, hotkeys = [[kbdHotkeyStub, @() null]] }
      ]
      onAttach= @(elem) move_mouse_cursor(elem)
    })
  }
}

return kwarg(mkPieMenu)
