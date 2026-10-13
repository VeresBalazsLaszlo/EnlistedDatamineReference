options gen2
module sound_occlusion_common shared
require math
require math.base
require DagorMath

def prevent_wall_sound_occlusion(pos, norm : float3; offset = 0.15) { // move sound away from the wall to prevent sound from becoming occluded by collision
  return pos + norm * offset
}

def prevent_wall_sound_occlusion(pos, norm, listener : float3; offset = 0.15) {
  let nrm = dot(listener - pos, norm) > 0. ? norm : -norm
  return pos + nrm * offset
}

def prevent_self_occlusion(pos, listener : float3; radius : float; var offset : float3&) : float3 {
  offset = listener - pos
  let distSq = length_sq(offset)
  if (distSq > square(radius)) {
    offset = (offset / sqrt(distSq)) * radius
  }
  return pos + offset
}
