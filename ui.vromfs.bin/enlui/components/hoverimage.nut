from "%ui/ui_library.nut" import *

const ATTRACT_PREFIX = "image_attract_"

let attraction = @(uid, angle, time, opacity = 1.0) [
  { trigger = $"{ATTRACT_PREFIX}{uid}", prop = AnimProp.rotate, from = 0, to = angle, duration = time, easing = Shake6 },
  { trigger = $"{ATTRACT_PREFIX}{uid}", prop = AnimProp.scale, from =[1.0, 1.0], to = [1.2, 1.2], duration = 0.3, easing = CosineFull },
  { trigger = $"{ATTRACT_PREFIX}{uid}", prop = AnimProp.opacity, from = 1, to = opacity, duration = 1.2 * time, easing = InCubic }
]

let transitions = const [
  { prop = AnimProp.scale, duration = 0.5, easing = OutCubic }
  { prop = AnimProp.opacity, duration = 0.3, easing = OutCubic }
]

let sizeAnimation = { prop = AnimProp.scale, from = [1.0, 1.0], to = [1.1, 1.1],
  duration = 2.0, easing = CosineFull, loop = true, play = true }

function create(sf, uid = 0, image = "", fallbackImage = null,
    size = FLEX, clip = false, brightness = 1, opacity = 1, pivot = [0.5, 0.5],
    pos = null, children = null, tint = null, hasSizeAnimation = false) {
  let animations = attraction(uid, 8, 1, opacity)
  if (hasSizeAnimation)
    animations.append(sizeAnimation)
  return {
    size = size
    clipChildren = clip
    pos = pos
    children = {
      size = size
      rendObj = ROBJ_IMAGE
      image = image
      tint = tint
      children = children
      fallbackImage = fallbackImage
      brightness = brightness
      opacity = opacity
      transform = {
        pivot = pivot
        scale = sf & S_HOVER ? const [1.1, 1.1] : const [1.0, 1.0]
      }
      transitions = transitions
      animations
    }
    transform = {
      pivot = pivot
      scale = sf & S_HOVER ? [1.1, 1.1] : [1.0, 1.0]
    }
    transitions = transitions
    animations = attraction(uid, 2, 1.2, 1)
  }
}

return {
  create = kwarg(create)
  attraction
  transitions
  attractToImage = @(uid) anim_start($"{ATTRACT_PREFIX}{uid}")
}
