import "%ui/hud/huds/tips/mkTipComposite.nut" as mkTipComposite
from "%ui/components/controlHudHint.nut" import controlHudHint, mkHasBinding
from "%ui/ui_library.nut" import *

function mkTextHint(text, params = {}) {
  if ((text ?? "") == "")
    return null

  let isFunc = isObservable(text)
  function mkComp() {
    let srcText = isFunc ? text.get() : text
    let container = {
      flow = FLOW_HORIZONTAL
      margin = hdpx(2)
      transform = const { pivot=[0.1,0.5] }
      animations = params?.textAnims
      children = mkTipComposite(srcText, params?.style)
    }
    if (isFunc)
      container.watch <- text
    return container
  }
  return isFunc ? mkComp : mkComp()
}

let defTipAnimations = const [
  { prop=AnimProp.scale, from=[0,1], to=[1,1], duration=0.25, play=true, easing=OutCubic }
  { prop=AnimProp.opacity, from=0, to=1, duration=0.15, play=true, easing=OutCubic }
  { prop=AnimProp.scale, from=[1,1], to=[0,1], duration=0.25, playFadeOut=true, easing=OutCubic }
  { prop=AnimProp.opacity, from=1, to=0, duration=0.25, playFadeOut=true, easing=OutCubic }
]

function mkInputHintBlock(inputId, addChild = null) {
  if (inputId == null)
    return null

  let hasBinding = mkHasBinding(inputId)
  let inputHint = controlHudHint(inputId)
  return @() {
    watch = hasBinding
    flow = FLOW_HORIZONTAL
    children = hasBinding.get() ? [inputHint, addChild] : null
  }
}

let padding = freeze({ size = const [fsh(1), 0] })

let tipBack = const {
  rendObj = ROBJ_WORLD_BLUR
  padding = hdpx(2)
  valign = ALIGN_CENTER
  flow = FLOW_HORIZONTAL
  transform = { pivot = [0.5, 0.5] }
}

function tipCmp(params) {
  local {
    text = null, inputId = null, extraCmp = params?.text ? padding : null,
    size = SIZE_TO_CONTENT, animations = defTipAnimations
  } = params
  if (text == null && inputId == null)
    return null

  animations = [].extend(animations, params?.extraAnimations ?? [])
  let textCmp = mkTextHint(text, params)
  let inputHintBlock = mkInputHintBlock(inputId, textCmp ? padding : null)
  return tipBack.__merge({
    size
    animations
    children = [
      inputHintBlock
      textCmp
      extraCmp
    ]
  }, params?.style ?? {})
}

function tipText(params) {
  let { text = null, size = SIZE_TO_CONTENT, animations = defTipAnimations } = params
  if (text == null)
    return null

  return tipBack.__merge({
    size
    animations
    children = mkTextHint(text, params)
  }, params?.style ?? {})
}

function tipAlternate(params) {
  let { textsInputs = [], size = SIZE_TO_CONTENT, animations = defTipAnimations } = params
  let watch = textsInputs.map(@(data) mkHasBinding(data.inputId))
  return function() {
    let idx = watch.findindex(@(w) w.get())
    if (idx == null)
      return { watch }

    let { text = null, inputId = null } = textsInputs[idx]
    if (text == null && inputId == null)
      return { watch }

    let textCmp = mkTextHint(text, params)
    let inputHintBlock = mkInputHintBlock(inputId, textCmp ? padding : null)
    return tipBack.__merge({
      watch
      size
      animations
      children = [
        inputHintBlock
        textCmp
      ]
    }, params?.style ?? {})
  }
}

return freeze({
  tipCmp
  tipText
  tipAlternate
  mkInputHintBlock
  defTipAnimations
})
