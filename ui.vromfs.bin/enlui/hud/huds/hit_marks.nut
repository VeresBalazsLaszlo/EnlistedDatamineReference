import "%sqstd/underscore.nut" as u
from "%enlSqGlob/dasenums.nut" import HitResult
from "dagor.math" import Point3
from "math" import cos, sin, PI
from "%ui/hud/state/hit_marks_es.nut" import hitMarks, downedColor, hitColor, killColor, killSize, hitSize, killTtl
  , hitTtl, showWorldKillMark
from "%ui/hud/state/hudOptionsState.nut" import showCrosshairHints
from "%sqstd/frp.nut" import subscribeAndInit
from "%ui/ui_library.nut" import *

let animations = [
  { prop=AnimProp.opacity, from=0.2, to=1, duration=0.1, play=true, easing=InCubic }
  { prop=AnimProp.opacity, from=1, to=0, duration=0.25, playFadeOut=true, easing=OutCubic }
  { prop = AnimProp.scale, from =[0.25, 0.25], to = [1, 1], duration = 0.1, easing = InCubic, play = true}
]

function mkAnimations(duration=0.4, appearPart = 0.15, stayPart = 0.25, fadePart = 0.65){
  duration = min(duration, 100)
  let appearDur = appearPart*duration
  let stayDur = stayPart*duration
  let fadeDur = fadePart*duration
  let fadeOutTrigger = {}
  let fadedTrigger = {}
  return [
    { prop=AnimProp.opacity, from=0.1, to=1.0, duration=appearDur, play=true, easing=InCubic, onExit=fadeOutTrigger}
    { prop=AnimProp.opacity, from=1.0, to=0.0, delay = stayDur, duration=fadeDur, easing = InCubic, trigger=fadeOutTrigger, onExit=fadedTrigger}
    { prop=AnimProp.opacity, from=0.0, to=0.0, duration=max(duration*3,100), trigger=fadedTrigger}

    { prop=AnimProp.scale, from=[1,1], to=[1.2,1.2], duration=0.15, playFadeOut=true, easing = InOutCubic}
  ]
}

function build_hitmarks_commands(marksCount) {
  let commands = [[VECTOR_WIDTH, hdpx(1.8)]]
  const markSize = 100
  const percentile = 0.5
  let initAngle = PI * 0.5 / (marksCount + 1);
  let center = {
    x = 50
    y = 50
  }
  for (local markId = 0; markId < marksCount; ++markId) {
    
    for (local i = 0; i < 2; ++i) {
      let angle = initAngle*(markId + 1) - PI*0.5*i
      let c = cos(angle)
      let s = sin(angle)
      for (local j = -1; j <= 1; j += 2) {
        let coor = {
          x = markSize * c * j
          y = markSize * s * j
        }
        commands.append([VECTOR_LINE,
          center.x + coor.x * percentile, center.y + coor.y * percentile,
          center.x + coor.x, center.y + coor.y])
      }
    }
  }
  return commands
}

const maxHitCount = 1
let hitHairMap = {}
for(local i = 1; i <= maxHitCount; i += 2)
  hitHairMap[i] <- build_hitmarks_commands(i)

let simpleHitMark = hitHairMap[1]


local hitMarkParams
local posHitMarksParams
local showWorldKillMarkCached
function updateLocalCache(...){
  let commonHitMarkAnims = mkAnimations(hitTtl.get()/3.0) 
  let commonKillMarkAnims = mkAnimations(killTtl.get()/3.0)
  hitMarkParams = {
    [HitResult.HIT_RES_NORMAL] = {size = hitSize.get(), color = hitColor.get(), animations = commonHitMarkAnims},
    [HitResult.HIT_RES_DOWNED] = {size = killSize.get(), color = downedColor.get(), animations = commonHitMarkAnims},
    [HitResult.HIT_RES_KILLED] = {size = killSize.get(), color = killColor.get(), animations = commonKillMarkAnims}
  }
  showWorldKillMarkCached = showWorldKillMark.get()
  posHitMarksParams = {
    [HitResult.HIT_RES_NORMAL] = {rendObj = ROBJ_VECTOR_CANVAS commands = simpleHitMark size = hitSize.get() transform = true color = hitColor.get()},
    [HitResult.HIT_RES_DOWNED] = {rendObj = ROBJ_VECTOR_CANVAS commands = simpleHitMark size = killSize.get() transform = true color = downedColor.get()},
    [HitResult.HIT_RES_KILLED] = {rendObj = ROBJ_VECTOR_CANVAS commands = simpleHitMark size = killSize.get() transform = true color = killColor.get()},
  }
}
{
  [downedColor, hitColor, killColor, killSize, hitSize, killTtl, hitTtl, showWorldKillMark]
    .map(@(v) v.subscribe(updateLocalCache))
}
updateLocalCache()








let currentHitMark = Watched(null)
let posHitMarks = Watched([])

function isPositionalHitMark(v){
  if (v?.hitPos==null)
    return false
  if (showWorldKillMarkCached){
    return v?.isMelee || (!v?.isKillHit && !v?.isDownedHit)
  }
  return v?.isMelee
}
function updateHitMarks(hitMarksRes){
  let res = u.partition(hitMarksRes, isPositionalHitMark)
  posHitMarks.set(res[0])
  let hitms = res[1]
  currentHitMark.set((hitms?.len() ?? 0)>0 ? hitms?[hitms.len()-1] : null)
}
subscribeAndInit(updateHitMarks, hitMarks)

function hitHair() {
  if (!showCrosshairHints.get())
    return { watch = showCrosshairHints }

  let curHitMark = currentHitMark.get()
  let key = curHitMark?.id ?? {}
  return {
    watch = [currentHitMark, showCrosshairHints]
    size = SIZE_TO_CONTENT
    children = {
      rendObj = ROBJ_VECTOR_CANVAS
      transform = true
      key = key
      commands = curHitMark!=null && !curHitMark.isImmunityHit ? simpleHitMark : null
    }.__update(hitMarkParams?[curHitMark?.hitRes] ?? hitMarkParams[HitResult.HIT_RES_NORMAL])
  }
}

function mkPosHitMark(mark){
  let pos = mark.hitPos
  return {
    data = {
      minDistance = 0.1
      clampToBorder = true
      worldPos = Point3(pos[0], pos[1], pos[2])
    }
    animations = animations
    transform = true
    children = posHitMarksParams?[mark?.hitRes] ?? posHitMarksParams[HitResult.HIT_RES_NORMAL]
    key = mark?.id ?? {}
  }
}

function posHitMarksComp() {
  return {
    watch = [posHitMarks]
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    size = const [sw(100), sh(100)]
    children = posHitMarks.get().map(mkPosHitMark)
    behavior = DngBhv.Projection
  }
}

return {
  hitMarks = hitHair
  posHitMarks = posHitMarksComp
}
