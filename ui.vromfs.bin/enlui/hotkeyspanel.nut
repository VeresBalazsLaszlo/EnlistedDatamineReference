import "%ui/control/controls_types.nut" as controlsTypes
import "%ui/components/gamepadImgByKey.nut" as gamepadImgByKey
import "%ui/style/colors.nut" as colors
import "%ui/control/gui_buttons.nut" as JB
import "%ui/control/controller_type.nut" as controllerType
from "%ui/style/fontsStyle.nut" import fontBody
from "string" import startswith
from "%ui/control/active_controls.nut" import lastActiveControlsType, isGamepad
from "%ui/state/safeArea.nut" import safeAreaVerPadding, safeAreaHorPadding
from "%ui/ui_library.nut" import *
from "types" import String

let navState = {value = []}
let getNavState = @(...) navState.value
let navStateGen = Watched(0)
let {cursorPresent, cursorOverStickScroll, config, cursorOverClickable} = gui_scene

const panel_ver_padding = hdpxi(6)

function mktext(text){
  return {
    rendObj = ROBJ_TEXT
    text
    color = colors.BtnTextNormal
  }.__update(fontBody)
}

let defaultJoyAHint = loc("ui/cursor.activate")

gui_scene.setHotkeysNavHandler(function(state) {
  navState.value = state
  navStateGen.modify(@(v)v+1)
})

const padding = hdpx(5)
let height = calc_str_box(mktext("H"))[1]*1.1

function mkNavBtn(params = {hotkey=null, gamepad=true}){
  let description = params?.hotkey?.description
  let skip = description?.skip
  if (skip)
    return null
  let btnNames = params?.hotkey.btnName ?? []
  let children = params?.gamepad
       ? btnNames.map(@(btnName) gamepadImgByKey.mkImageCompByDargKey(btnName, {height}))
       : btnNames.map(@(btnName) {rendObj = ROBJ_TEXT text = btnName })

  if (description instanceof String)
    children.append(mktext(description))

  return {
    size = [SIZE_TO_CONTENT, height]
    gap = fsh(0.5)
    flow = FLOW_HORIZONTAL
    valign = ALIGN_CENTER
    children = children
    padding = hdpx(5)
  }
}

function combine_func(a, b){
  return (a.action==b.action)
}

let isActivateKey = @(key) JB.A == key.btnName

function combine_hotkeys(data, filter_func){
  let hotkeys = []
  local isActivateForced = false
  foreach (k in data) {
    if (isActivateKey(k)) {
      isActivateForced = true
      continue
    }
    if (!filter_func(k))
      continue
    let t = clone k
    local key_used = false
    foreach (r in hotkeys) {
      if (combine_func(r,t)) {
        r.btnName.append(t.btnName)
        key_used = true
        break
      }
    }
    if (!key_used) {
      t.btnName = [t.btnName]
      hotkeys.append(t)
    }
  }
  return { hotkeys, needShowHotkeys = isActivateForced || hotkeys.len() > 0 }
}

function getJoyAHintText(data, filter_func) {
  local hotkeyAText = defaultJoyAHint
  foreach (k in data)
    if (filter_func(k) && isActivateKey(k)) {
      if (typeof k?.description == "string")
        hotkeyAText = k.description
      else if (k?.description?.skip)
        hotkeyAText = null
    }
  return hotkeyAText
}


function _filter(hotkey, devid){
  let descrExist = "description" in hotkey
  return devid.contains(hotkey.devId) && (!descrExist || hotkey.description != null)
}

const showKbdHotkeys = false

function makeFilterFunc(is_gamepad) {
  return is_gamepad
    ? @(hotkey) _filter(hotkey, [DEVID_JOYSTICK])
    : @(hotkey) showKbdHotkeys && _filter(hotkey, [DEVID_KEYBOARD, DEVID_MOUSE])
}

let joyAHint = Computed(function() {
  return getJoyAHintText(navState.value, makeFilterFunc(isGamepad.get()))
})

let svgImg = memoize(function(image){
  let h = gamepadImgByKey.getBtnImageHeight(image, height)
  return freeze({
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    rendObj = ROBJ_IMAGE
    image = Picture("ui/skin#{0}.svg:{1}:{1}".subst(image, h.tointeger()))
    keepAspect = KEEP_ASPECT_FIT
    size = [h, h]
  })
})

function manualHint(images, text=""){
  return {
    flow = FLOW_HORIZONTAL
    valign = ALIGN_CENTER
    gap = fsh(0.5)
    children = images.map(@(image) svgImg(image)).append(mktext(text))
    padding = padding
  }
}

function gamepadcursornav_images(cType) {
  if (cType == controlsTypes.ds4gamepad)
    return ["ds4/lstick_4" "ds4/dpad"]

  return ["x1/lstick_4" "x1/dpad"]
}

function gamepadcursorclick_image(imagesMap) {
  let clickButtons = config.getClickButtons()
  return clickButtons
    .filter(@(btn) startswith(btn, "J:"))
    .map(@(btn) imagesMap?[btn])
}

function gamepadCursor() {
  let clickHint = manualHint(gamepadcursorclick_image(gamepadImgByKey.keysImagesMap.get()), joyAHint.get())
  let clickHintStub = {size = [calc_comp_size(clickHint)[0], 0], key = {}}
  let scrollHint = manualHint([gamepadImgByKey.keysImagesMap.get()?["J:R.Thumb.hv"]], loc("ui/cursor.scroll"))
  return {
    flow = FLOW_HORIZONTAL
    hplace = ALIGN_LEFT
    gap = fsh(2.5)
    size = [SIZE_TO_CONTENT, height]
    valign = ALIGN_CENTER
    zOrder = Layers.MsgBox
    watch = [joyAHint, lastActiveControlsType, cursorOverStickScroll, cursorOverClickable,gamepadImgByKey.keysImagesMap]
    children = [
      manualHint(gamepadcursornav_images(controllerType.get()),loc("ui/cursor.navigation"))
      cursorOverClickable.get() && joyAHint.get() ? clickHint : clickHintStub
      cursorOverStickScroll.get() ? scrollHint : null
      {size = const [fsh(6),0]}
    ]
  }
}

let show_tips = Computed(@() cursorPresent.get() && isGamepad.get() && combine_hotkeys(getNavState(navStateGen.get()), makeFilterFunc(isGamepad.get())).needShowHotkeys)

function tipsC(){
  let filtered_hotkeys = combine_hotkeys(getNavState(), makeFilterFunc(isGamepad.get())).hotkeys
  let tips = (cursorPresent.get() && isGamepad.get()) ? [ gamepadCursor] : []
  tips.extend(filtered_hotkeys.map(@(hotkey) mkNavBtn({hotkey=hotkey, gamepad=isGamepad.get()})))
  return {
    gap = fsh(2.5)
    size = SIZE_TO_CONTENT
    flow = FLOW_HORIZONTAL
    watch = [isGamepad, cursorPresent, navStateGen]
    zOrder = Layers.MsgBox
    children = tips
  }
}

let hotkeysBarHeight = Computed(@() height + panel_ver_padding + max(panel_ver_padding , safeAreaVerPadding.get()))


function hotkeysButtonsBar() {
  let res = { watch = [hotkeysBarHeight, show_tips, safeAreaHorPadding] }
  return !show_tips.get() ? res : res.__update({
    size = [SIZE_TO_CONTENT, hotkeysBarHeight.get()]
    vplace = ALIGN_BOTTOM
    valign = ALIGN_CENTER
    padding = [0, fsh(4), 0, max(fsh(5), safeAreaHorPadding.get())]
    children = tipsC
  })
}

return {hotkeysButtonsBar, hotkeysBarHeight}