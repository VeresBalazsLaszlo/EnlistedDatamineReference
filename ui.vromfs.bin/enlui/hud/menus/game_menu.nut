import "%ui/components/gamepadImgByKey.nut" as gamepadImgByKey
import "%ui/control/gui_buttons.nut" as JB
from "%ui/style/fontsStyle.nut" import fontHeading1, fontBody
from "%ui/style/colors.nut" import TextDefault, TextHighlight, TextHover
from "%ui/control/active_controls.nut" import isGamepad
from "%ui/hud/menus/game_menu_items.nut" import menuItemsWatch, getMenuItems
from "%ui/ui_library.nut" import *

let menuCurrentIndex = Watched(-1)

let showGameMenu = mkWatched(persist, "showGameMenu", false)

function closeMenu() {
  menuCurrentIndex.set(-1)
  showGameMenu.set(false)
}

function callHandler(item) {
  closeMenu()
  item?.action()
}

let height = calc_str_box("A", fontBody)[1]

function makeMenuItem(data, idx) {
  let stateFlags = Watched(0)
  let isCur = (idx==menuCurrentIndex.get())
  let imgA = gamepadImgByKey.mkImageCompByDargKey(JB.A, {
    height = height
    vplace = ALIGN_CENTER
    pos = const [-fsh(3.5), 0]
    transform = {
      scale = isCur ? [1,1] : [0,1]
      pivot = [0.7,0.5]
    }
    opacity = isCur ? 1: 0
    transitions = [
      { prop=AnimProp.translate, duration = 0.3, easing = InOutCubic }
      { prop=AnimProp.opacity, duration = 0.3, easing = InOutCubic }
      { prop=AnimProp.scale, duration = 0.4, easing = InOutCubic }
    ]
    animations = [
      { prop=AnimProp.scale, from=[0,1], to=[1,1], duration=0.25, play=true, easing=InOutCubic}
    ]
  })

  return @() {
    key = data
    rendObj = ROBJ_TEXT
    text = data.text
    behavior = Behaviors.Button
    sound = {
      click  = "ui/button_click"
      hover  = "ui/menu_highlight"
      active = "ui/button_action"
    }

    skipDirPadNav = true
    watch = [stateFlags, isGamepad]
    color = isCur ? TextHighlight
      : stateFlags.get() & S_HOVER ? TextHover
      : TextDefault
    transitions = [
      { prop=AnimProp.translate, duration = 0.3, easing = InOutCubic }
    ]
    transform = {
      translate = [isCur ? -fsh(0.5) : -0, 0]
    }

    fontFx = isCur ? FFT_GLOW : FFT_NONE
    fontFxColor = TextDefault
    fontFxFactor = min(48, hdpx(48))
    children = isGamepad.get() ? imgA : null
    margin = const [fsh(2), fsh(8)]
    onClick = @() callHandler(data)
    onElemState = @(sf) stateFlags.set(sf)
    onHover = @(on) on ? menuCurrentIndex.set(idx) : null

    cursorNavAnchor = [elemh(80), elemh(90)]
  }.__update(fontHeading1)
}

function goToNext(d) {
  let menuItemsVal = getMenuItems()
  let nextIdx = ((menuCurrentIndex.get() ?? 0) + d + menuItemsVal.len()) % menuItemsVal.len()
  menuCurrentIndex.set(nextIdx)
  let target = menuItemsVal?[nextIdx]
  if (target != null)
    move_mouse_cursor(target, false)
}

let skip ={skip=true}

function gameMenu() {
  let menuItemsVal = getMenuItems()
  let activateCurrent = @() callHandler(menuItemsVal?[menuCurrentIndex.get()])

  let menu = {
    size = SIZE_TO_CONTENT
    flow = FLOW_VERTICAL
    pos = const [sh(14), sh(30)]

    hotkeys = [
      ["@HUD.GameMenu", {action=closeMenu description=skip}],
      [$"^{JB.B} | J:Start", {action=closeMenu description=loc("BackBtn")}],
      [$"^{JB.A} | Enter | Space", {action=activateCurrent description=skip}],
      ["^Up | J:D.Up", {action =@() goToNext(-1) description = skip}],
      ["^Down | J:D.Down", {action =@() goToNext(1) description= skip}],
    ]

    children = menuItemsVal.map(makeMenuItem)

    transform = true
    animations = [
      { prop=AnimProp.translate, from=[-sh(10),0], to=[0, 0], duration=0.2, play=true, easing=OutCubic}
    ]

    onAttach = @() defer(@() menuCurrentIndex.set(0))
  }

  return {
    watch = [menuCurrentIndex].extend(menuItemsWatch)
    size = const [sw(100), sh(100)]

    children = [
      {
        size = const [sw(120), sh(100)]
        stopHotkeys = true
        stopMouse = true
        rendObj = ROBJ_WORLD_BLUR_PANEL
        color = Color(130,130,130)
      }
      menu
    ]

    transform = {
      pivot = [0.5, 0.25]
    }
    animations = [
      { prop=AnimProp.opacity, from=0, to=1, duration=0.2, play=true, easing=InOutCubic}
      { prop=AnimProp.opacity, from=1, to=0, duration=0.2, playFadeOut=true, easing=InOutCubic}
      
      { prop=AnimProp.translate, from=[0,0], to=[-sh(10),0], duration=0.2, playFadeOut=true, easing=InOutCubic}
    ]
    sound = {
      attach="ui/menu_enter"
      detach="ui/menu_exit"
    }

    behavior = [DngBhv.ActivateActionSet, DngBhv.UiStateControl]
    actionSet = "StopInput"
    overrideFreeCam = true
  }
}


return {
  gameMenu
  showGameMenu
}
