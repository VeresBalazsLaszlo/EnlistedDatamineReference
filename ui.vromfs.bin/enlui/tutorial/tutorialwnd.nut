import "%ui/tutorial/tutorialWndDefStyle.nut" as tutorialWndDefStyle
from "dagor.debug" import logerr
from "%ui/components/modalWindows.nut" import addModalWindow, removeModalWindow
from "%ui/tutorial/tutorialWndState.nut" import isTutorialActive, tutorialConfigVersion, getTutorialConfig, stepIdx, nextStep, nextStepByDefaultHotkey, skipCurTutorial
  , nextKeyAllowed, getTimeAfterStepStart
from "%ui/tutorial/tutorialUtils.nut" import getBox, incBoxSize, createHighlight, findGoodPos, findGoodArrowPos, sizePosToBox
from "%ui/style/designConst.nut" import midPadding
from "%ui/ui_library.nut" import *
from "types" import Array

const WND_UID = "tutorial_wnd"
const DEF_SKIP_TIME = 3.0

let mkLightCtorExt = @(lightCtor, nextStepDelay) function(box) {
  let { ctor = null, onClick = null, hotkey = null } = box
  if (ctor != null)
    return ctor(box)

  function onClickExt() {
    let skipNext = onClick?() ?? false
    if (!skipNext && (onClick != null || nextStepDelay < getTimeAfterStepStart()))
      nextStep()
  }

  return lightCtor(box,
    {
      onClick = onClickExt
      hotkeys = hotkey == null ? null
        : [ [hotkey, { description = { skip = true }, sound = "click"}] ]
    })
}

function mkBg(boxes, style, nextStepDelay) {
  let { lightCtor, darkCtor } = style
  let lightCtorExt = mkLightCtorExt(lightCtor, nextStepDelay)
  return {
    size = FLEX
    children = createHighlight(boxes, lightCtorExt, darkCtor)
  }
}

function mkArrowLinks(stepData, boxes, style) {
  let { arrowLinks = null } = stepData
  if (!(arrowLinks instanceof Array))
    return null

  let { mkLinkArrow } = style
  let linkBoxes = []
  let linkComps = []
  foreach (link in arrowLinks) {
    if (!(link instanceof Array) || link.len() != 2) {
      logerr($"Bad link in tutorial: /*{link}*/. Expected array with length 2.")
      continue
    }
    let lBoxes = link.map(@(idx) boxes.findvalue(@(b) b?.idx == idx))
    if (lBoxes.findindex(@(b) b == null) != null)
      continue
    let { component = null, box = null } = mkLinkArrow(lBoxes[0], lBoxes[1])
    if (component == null)
      continue
    linkComps.append(component)
    if (box != null)
      linkBoxes.append(box)
  }
  return {
    linkBoxes,
    arrowLinks = {
      size = FLEX
      children = linkComps
    }
  }
}

function mkMessage(text, customCtor, boxes, style) {
  if (text == null && customCtor == null)
    return null

  let ctor = customCtor ?? style.messageCtor
  
  let size = calc_comp_size(ctor(text, Watched(true), nextStepByDefaultHotkey))
  let pos = findGoodPos(size, [sw(50) - 0.5 * size[0], sh(50) - 0.5 * size[1]], boxes)
  return {
    messageComp = {
      pos
      children = ctor(text, nextKeyAllowed, nextStepByDefaultHotkey)
    }
    messageBox = sizePosToBox(size, pos)
  }
}


function mkSkipButtonUi() {
  let config = getTutorialConfig()
  let style = tutorialWndDefStyle.__merge(config?.style ?? {})
  let delay = config?.stepSkipDelay ?? DEF_SKIP_TIME
  return {
    margin = midPadding
    hplace = ALIGN_RIGHT
    children = style.skipBtnCtor(delay, skipCurTutorial, "")
  }
}


function mkArrows(boxes, obstaclesVar, style) {
  boxes = boxes.filter(@(b) (b?.needArrow ?? false) && b.r - b.l > 0 && b.b - b.t > 0)
  if (boxes.len() == 0)
    return null
  let { pointerArrow } = style
  let size = calc_comp_size(pointerArrow)
  let children = []
  foreach (box in boxes) {
    let { pos, rotate } = findGoodArrowPos(box, size, obstaclesVar)
    obstaclesVar.append(sizePosToBox(size, pos))
    children.append(pointerArrow.__merge({ pos, transform = { rotate } }))
  }
  return {
    size = FLEX
    children
  }
}

let nextStepSubscription = @(v) v ? nextStep() : null

let boxUpdateCount = Watched(0)
let boxUpdateCountWithStep = Computed(@() boxUpdateCount.get() + stepIdx.get())
let headerBox = sizePosToBox([sw(100), hdpx(50)], [0, 0])

let incrementBoxUpdateCount = @() boxUpdateCount.modify(@(v) v + 1)

function tutorialWnd() {
  let watch = [tutorialConfigVersion, stepIdx, boxUpdateCountWithStep]
  let config = getTutorialConfig()
  let style = tutorialWndDefStyle.__merge(config?.style ?? {})
  let stepData = config?.steps[stepIdx.get()] ?? {}

  local { nextStepAfter = null, text = null, textCtor = null } = stepData

  if (isObservable(text)) {
    watch.append(text)
    text = text.get()
  }

  let boxes = []
  local shouldBeBoxes = false
  local hasValidBoxes = false
  foreach (idx, objData in stepData?.objects ?? []) {
    local { keys = null, sizeIncAdd = 0 } = objData
    shouldBeBoxes = shouldBeBoxes || keys != null
    if (isObservable(keys)) {
      watch.append(keys)
      keys = keys.get()
    }
    local box = getBox(keys)
    if (box == null)
      continue
    let isValid = box.r - box.l > 0 && box.b - box.t > 0
    if (isValid)
      box = incBoxSize(box, sizeIncAdd)
    boxes.append(objData.__merge(box, { idx }))
    hasValidBoxes = hasValidBoxes || isValid
  }

  let { linkBoxes = null, arrowLinks = null } = mkArrowLinks(stepData, boxes, style)
  let obstacles = [].extend(boxes, linkBoxes ?? []).append(headerBox)

  let { messageComp = null, messageBox = null } = mkMessage(text, textCtor, obstacles, style)
  if (messageBox != null)
    obstacles.append(messageBox)

  return {
    watch
    size = FLEX
    children = [
      mkBg(boxes, style, config?.nextStepDelay ?? 0.5)
      arrowLinks
      messageComp
      mkArrows(boxes, obstacles, style)
      hasValidBoxes || !shouldBeBoxes ? null 
        : {
            size = SIZE_TO_CONTENT
            key = boxUpdateCountWithStep.get(),
            onAttach = @() gui_scene.resetTimeout(0.05, incrementBoxUpdateCount)
          }
      nextStepAfter == null ? null
        : {
            size = SIZE_TO_CONTENT
            key = $"nextStepAfter{stepIdx.get()}"
            onAttach = @() nextStepAfter.get() ? nextStep()
              : nextStepAfter.subscribe(nextStepSubscription)
            onDetach = @() nextStepAfter.unsubscribe(nextStepSubscription)
          }
    ]
  }
}

let close = @() removeModalWindow(WND_UID)
function open() {
  addModalWindow({
    key = WND_UID
    size = const [sw(100), sh(100)]
    children = [
      tutorialWnd
      mkSkipButtonUi()
    ]
    onClick = @() null
  })
}

if (isTutorialActive.get())
  open()
isTutorialActive.subscribe(@(v) v ? open() : close())