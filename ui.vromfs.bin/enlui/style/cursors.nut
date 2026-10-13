import "%ui/style/tooltipCtor.nut" as defTooltipCtor
from "%ui/control/active_controls.nut" import isGamepad
from "%ui/state/safeArea.nut" import safeAreaVerPadding, safeAreaHorPadding
from "%dngscripts/platform.nut" import is_sony, is_xbox
from "%ui/ui_library.nut" import *
from "types" import String, Array

let tooltipComp = {value = null, elemPos = null}
let tooltipGen = Watched(0)

const MAX_GEN_INT = 1000
function setTooltip(val, elemPos = null) {
  tooltipComp.value = val
  tooltipComp.elemPos = elemPos
  tooltipGen.modify(@(v) v > MAX_GEN_INT ? 0 : v + 1)
}

let getTooltip = @() tooltipComp.value
let cursors = {getTooltip, setTooltip, tooltip = {}}
let { cursorOverStickScroll, cursorOverClickable } = gui_scene
let showGamepad = Computed(@() isGamepad.get() || is_xbox || is_sony)

const colorBack = Color(0,0,0,120)

let safeAreaBorders = Computed(@() [safeAreaVerPadding.get()+fsh(1), safeAreaHorPadding.get()+fsh(1)])

function getTooltipPositioning(vplace, tooltipChildren) {
  if (vplace == ALIGN_BOTTOM)
    return [0, 0]

  if (!showGamepad.get())
    return [hdpxi(12), hdpxi(28)]

  let elemPos = tooltipComp.elemPos?.targetRect
  if (!elemPos)
    return [hdpxi(28), hdpxi(40)]

  let rootSizeHeight = elemPos.b - elemPos.t
  local posY = (((rootSizeHeight * 0.5) + hdpx(20)) + 0.5).tointeger()

  let tooltipPrecalcRect = calc_comp_size(tooltipChildren)
  let critPosY = elemPos.b + tooltipPrecalcRect[1]
  if (critPosY >= (sh(100) - safeAreaBorders.get()[0])) {
    let curPos = get_mouse_cursor_pos()
    posY = elemPos.t - curPos.y - tooltipPrecalcRect[1] + hdpxi(20)
  }

  return [hdpxi(28), posY]
}

let mkTooltipCmp = @(align) function() {
  let tip = getTooltip()
  let dynamicTip = isObservable(tip)
  let children = tip instanceof String || dynamicTip
    ? defTooltipCtor({
        rendObj = ROBJ_TEXTAREA
        behavior = Behaviors.TextArea
        maxWidth = hdpxi(500)
        text = dynamicTip ? tip.get() : tip
        color = Color(180, 180, 180, 120)
      })
    : tip

  if (children == null)
    return { watch = [tooltipGen] }

  let pos = getTooltipPositioning(align, children)
  let watchList = [tooltipGen, showGamepad, safeAreaBorders]
  return {
    key = "tooltip"
    pos
    watch = dynamicTip ? [tip].extend(watchList) : watchList
    behavior = Behaviors.BoundToArea
    transform = true
    safeAreaMargin = safeAreaBorders.get()
    vplace = align
    children
  }
}

cursors.tooltip.cmp <- mkTooltipCmp(ALIGN_TOP)
cursors.tooltip.cmpTop <- mkTooltipCmp(ALIGN_BOTTOM)



















let getEvenIntegerHdpx = @(px) hdpxi(0.5 * px) * 2

let scroll_size = getEvenIntegerHdpx(20)

let round_cursor = [
  [VECTOR_WIDTH, hdpx(1.4)],
  [VECTOR_FILL_COLOR, Color(70, 80, 90, 90)],
  [VECTOR_COLOR, Color(100, 100, 100, 50)],
  [VECTOR_ELLIPSE, 50, 50, 50, 50],
  [VECTOR_WIDTH, hdpx(1.5)],
  [VECTOR_FILL_COLOR, 0],
  [VECTOR_COLOR, Color(0, 0, 0, 60)],
  [VECTOR_ELLIPSE, 50, 50, 43, 43],
  [VECTOR_WIDTH, hdpx(1.5)],
  [VECTOR_COLOR, Color(100, 100, 100, 50)],
  [VECTOR_ELLIPSE, 50, 50, 46, 46],
]

let joyScrollCursorImage = {
  key = "scroll-cursor"
  rendObj = ROBJ_IMAGE
  size = [scroll_size, scroll_size]
  image = Picture($"!ui/uiskin/cursor_scroll.svg:{scroll_size}:{scroll_size}:K")
  keepAspect = KEEP_ASPECT_FIT
  pos = const [hdpxi(20), hdpxi(30)]
  opacity = 1

  transform = true

  animations = [
    { prop=AnimProp.opacity,  from=0.0,    to=1.0,     duration=0.3,  play=true, easing=OutCubic }
    { prop=AnimProp.opacity,  from=1.0,    to=0.0,     duration=0.1,  playFadeOut=true, easing=OutCubic }
    { prop=AnimProp.scale,    from=[0, 0], to=[1, 1],  duration=0.15, play=true, easing=OutCubic }
    { prop=AnimProp.scale,    from=[1, 1], to=[0, 0],  duration=0.1,  playFadeOut=true, easing=OutCubic }
  ]
}

let cursorSzNormal     = getEvenIntegerHdpx(32)
let cursorSzResizeDiag = getEvenIntegerHdpx(18)

let normalCursorPic = Picture("ui/skin#cursor.svg:{0}:{0}".subst(cursorSzNormal))
let draggableCursorPic = Picture("ui/skin#hand.svg:{0}:{0}".subst(cursorSzNormal))
let targetCursorPic = Picture("ui/skin#sniper_rifle.svg:{0}:{0}".subst(cursorSzNormal))

let cursorImageComp = {
  rendObj = ROBJ_IMAGE
  image = normalCursorPic
  size = [cursorSzNormal, cursorSzNormal]
}

function mkPcCursor(children) {
  children = children ?? []
  if (!(children instanceof Array))
    children = [children]
  children = clone children
  children.append(cursorImageComp)
  return {
    watch = [showGamepad, cursorOverStickScroll]
    size = 0
    children
  }
}

let gamepadCursorSize = [hdpxi(40), hdpxi(40)]

let gamepadOnClickAnimationComp = {
  animations = [
    {prop=AnimProp.scale, from=[0.5, 0.5], to=[1, 1],  duration=0.5, play=true, loop=true }
  ]
  commands = round_cursor
  rendObj = ROBJ_VECTOR_CANVAS
  size = gamepadCursorSize
  halign = ALIGN_CENTER
  transform = {pivot=[0.5,0.5]}
  opacity = 0.5
}

let gamepadComp = {
  rendObj = ROBJ_VECTOR_CANVAS
  size = gamepadCursorSize
  commands = round_cursor
}

function mkGamepadCursor(children){
  children = clone children
  children.append(gamepadComp)
  if (cursorOverClickable.get())
    children.append(gamepadOnClickAnimationComp)
  return {
    hotspot = [hdpxi(20), hdpxi(20)]
    watch = [showGamepad, cursorOverStickScroll, cursorOverClickable]
    size = gamepadCursorSize
    children = children
    halign = ALIGN_CENTER
    transform = {
      pivot = [0.5, 0.5]
    }
  }
}

function mkCursorWithTooltip(children){
  if (!(children instanceof Array))
    children = [children]
  if (cursorOverStickScroll.get() && showGamepad.get())
    children.append(joyScrollCursorImage)
  return showGamepad.get() ? mkGamepadCursor(children)
                           : mkPcCursor(children)
}

cursors.normal <- Cursor(@() mkCursorWithTooltip(cursors.tooltip.cmp))

cursors.normalTooltipTop <- Cursor(@() mkCursorWithTooltip(cursors.tooltip.cmpTop))

cursors.target <- Cursor(function() {
  let children = [cursors.tooltip.cmp]
  return {
    rendObj = ROBJ_IMAGE
    size = [cursorSzNormal, cursorSzNormal]
    hotspot = [cursorSzNormal/2, cursorSzNormal/2]
    image = targetCursorPic
    children
    transform = {
      pivot = [0, 0]
    }
  }
})

cursors.mkCustom <- function(image, size = cursorSzNormal) {
  let cursorImage = Picture(image.endswith(".svg") ? $"{image}:{size}:{size}" : image)
  return Cursor(@() {
    rendObj = ROBJ_IMAGE
    size = [size, size]
    hotspot = [size/2, size/2]
    image = cursorImage
    transform = {
      pivot = [0, 0]
    }
  })
}

cursors.draggable <- Cursor(function() {
  let children = [cursors.tooltip.cmp]
  if (cursorOverStickScroll.get() && showGamepad.get())
    children.append(joyScrollCursorImage)
  return showGamepad.get()
    ? mkGamepadCursor(children)
    : {
        rendObj = ROBJ_IMAGE
        watch = [showGamepad, cursorOverStickScroll]
        size = [cursorSzNormal, cursorSzNormal]
        hotspot = [0, 0]
        image = draggableCursorPic
        children
        transform = {
          pivot = [0, 0]
        }
      }
})

let helpSign = {
  rendObj = ROBJ_INSCRIPTION
  text = "?"
  fontSize = hdpx(25)
  vplace = ALIGN_CENTER
  fontFx = FFT_GLOW
  fontFxFactor = 48
  fontFxColor = colorBack
  color = Color(150,150,150,100)
}

let helpSignPc = helpSign.__merge({ pos = const [hdpxi(25), hdpxi(10)] })

cursors.help <- Cursor(function(){
  let children = [
    cursorOverStickScroll.get() && showGamepad.get()
      ? joyScrollCursorImage : null,
    showGamepad.get() ? helpSign
                      : helpSignPc,
    cursors.tooltip.cmp
  ]
  return showGamepad.get() ? mkGamepadCursor(children)
                           : mkPcCursor(children)
})

function mkResizeC(commands, angle=0){
  return {
    rendObj = ROBJ_VECTOR_CANVAS
    size = [cursorSzResizeDiag, cursorSzResizeDiag]
    commands = [
      [VECTOR_WIDTH, hdpx(1)],
      [VECTOR_FILL_COLOR, Color(255,255,255)],
      [VECTOR_COLOR, Color(20, 40, 70, 250)],
      [VECTOR_POLY].extend(commands.map(@(v) v.tofloat()*100/7.0))
    ]
    hotspot = [cursorSzResizeDiag / 2, cursorSzResizeDiag / 2]
    transform = {rotate=angle}
  }
}
let horArrow = [0,3, 2,0, 2,2, 5,2, 5,0, 7,3, 5,6, 5,4, 2,4, 2,6]
cursors.sizeH <- Cursor(mkResizeC(horArrow))
cursors.sizeV <- Cursor(mkResizeC(horArrow, 90))
cursors.sizeDiagLtRb <- Cursor(mkResizeC(horArrow, 45))
cursors.sizeDiagRtLb <- Cursor(mkResizeC(horArrow, 135))

cursors.moveResizeCursors <- {
  [MR_LT] = cursors.sizeDiagLtRb,
  [MR_RB] = cursors.sizeDiagLtRb,
  [MR_LB] = cursors.sizeDiagRtLb,
  [MR_RT] = cursors.sizeDiagRtLb,
  [MR_T]  = cursors.sizeV,
  [MR_B]  = cursors.sizeV,
  [MR_L]  = cursors.sizeH,
  [MR_R]  = cursors.sizeH,
}

cursors.normalCursorPic <- normalCursorPic

function applyTooltip(comp, tooltipCtor) {
  
  local { behavior = [], onHover = null, skipDirPadNav = true, eventPassThrough = true } = comp
  behavior = typeof behavior != "array" ? [behavior] : behavior
  if (!behavior.contains(Behaviors.Button))
    behavior.append(Behaviors.Button)
  function onHoverNew(on) {
    setTooltip(on ? tooltipCtor() : null)
    onHover?(on)
  }
  return (comp ?? {}).__merge({
    behavior
    skipDirPadNav
    eventPassThrough
    onHover = onHoverNew
    inputPassive = true
  })
}
cursors.withTooltip <- function(comp, tooltipCtor) {
  if (comp == null)
    return null
  return typeof comp == "table"
    ? applyTooltip(comp, tooltipCtor)
    : @() applyTooltip(comp?(), tooltipCtor)
}

return freeze(cursors)
