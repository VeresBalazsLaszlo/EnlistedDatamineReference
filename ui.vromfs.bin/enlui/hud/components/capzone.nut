import "%ui/hud/components/capzoneProgress.nut" as capzoneProgress
import "%ui/hud/components/mkObjectiveProgress.nut" as mkObjectiveProgress
import "%dngscripts/ecs.nut" as ecs
from "%ui/style/fontsStyle.nut" import fontHeading2
from "%ui/hud/state/watched_hero.nut" import watchedHeroEid, watchedTeam
from "%ui/hud/state/capZones.nut" import getZoneWatch
from "%ui/hud/components/mkObjectiveIcon.nut" import mkObjectiveIcon
from "%ui/hud/replay/replayState.nut" import isReplayStopped
from "%ui/hud/state/replay_state.nut" import isReplay
from "%ui/hud/state/zombie_zones_state.nut" import isZombieObjectiveMode
from "%ui/ui_library.nut" import *






const ZONE_ANIM_NAME = "zone_blink"

const ZONE_TEXT_COLOR = Color(80,80,80,20)
const ZONE_BG_COLOR = Color(60, 60, 60, 60)
const ZONE_LOCK_COLOR = Color(160, 160, 160, 160)
const ZONE_LOCK_ENEMY_PRESENT_COLOR = Color(160, 160, 160, 160)

const zoneLockIconSize = hdpxi(21)


let baseZoneAppearAnims = const [
  { prop=AnimProp.scale, from=[2.5,2.5], to=[1,1], duration=0.4, play=true}
  { prop=AnimProp.opacity, from=0.0, to=1.0, duration=0.2, play=true}
]

let zombieZoneAppearAnims = freeze([
  { prop = AnimProp.scale, from = [2.5,2.5], to = [1,1], duration = 0.4, play = true }
  { prop = AnimProp.opacity, from = 0.0, to = 1.0, duration = 0.2, play = true }
  { prop = AnimProp.color, from = 0xFFFFFFFF, to = 0xFFFFFF00, easing = DoubleBlink,
    play = true, duration = 0.8, delay = 5, trigger = ZONE_ANIM_NAME,
    onFinish = @() anim_start(ZONE_ANIM_NAME) }
])

const highlightScale = 2.6

let animActive = const [
  { prop=AnimProp.scale, from=[7.5,7.5], to=[1,1], duration=0.3, play=true}
  { prop=AnimProp.translate, from=[0,sh(20)], to=[0,0], duration=0.4, play=true, easing=OutQuart}
  { prop=AnimProp.opacity, from=0.0, to=1.0, duration=0.25, play=true}
]


let capzonBlurback = memoize(@(height) {
    size = [height, height]
    rendObj = ROBJ_MASK
    image = Picture("ui/skin#white_circle.svg:{0}:{0}".subst(height.tointeger()))
    children = [{size = FLEX rendObj = ROBJ_WORLD_BLUR color = Color(220, 220, 220, 255)}]
  })

let capzonDarkback = memoize(@(height) {
    size = [height, height]
    rendObj = ROBJ_IMAGE
    image = Picture("ui/skin#white_circle.svg:{0}:{0}".subst(height.tointeger()))
    color = Color(0, 0, 0, 120)
  })

let capzoneHasEnemies = @(presenceTeamCount)
  presenceTeamCount.findindex(@(count, team) team.tointeger() != watchedTeam.get() && count > 0) != null

let enemyPresenceAnimation = [
  { prop=AnimProp.opacity, from=0.1, to=1.0, duration=1.0, play=true, loop=true, easing=CosineFull }
]


let capZoneTransitions = freeze([{ prop=AnimProp.translate, duration=0.2 }])

let mkZoneIcon = memoize(@(ownTeamIcon, height) Picture("{0}:{1}:{1}".subst(ownTeamIcon, height.tointeger())))
let lockZone = Picture("ui/skin#point_lock.svg:{0}:{0}".subst(zoneLockIconSize))
let mkZoneText = memoize(@(caption, animations){
    rendObj = ROBJ_TEXT
    text = loc(caption)
    color = ZONE_TEXT_COLOR
    halign  = ALIGN_CENTER
    valign = ALIGN_BOTTOM
    animations
  }.__update(fontHeading2)
)


function capzoneCtor(zoneWatch, params={}) {
  let { animAppear = null, canHighlight=true} = params
  let {eid} = zoneWatch.get()
  let watch = [
    zoneWatch, watchedTeam, watchedHeroEid, isReplay, isReplayStopped, isZombieObjectiveMode
  ]

  return function() {
    let zoneData = zoneWatch.get()
    let { active, wasActive, alwaysShow, locked, heroInsideEid, caption, ui_order,
      ownTeamIcon, presenceTeamCount } = zoneData
    if (!wasActive && !alwaysShow)
      return { ui_order, watch }

    let heroTeam = watchedTeam.get()
    let heroEid = watchedHeroEid.get()
    let size = params?.size ?? fsh(3)
    let highlight = canHighlight && active
      && (heroInsideEid != ecs.INVALID_ENTITY_ID && heroInsideEid == heroEid)
    let highlightedSize = highlight ? size * highlightScale : size
    let iconSz = highlightedSize / 1.5
    let blur_back = ("customBack" in params) ? params.customBack(highlightedSize)
      : (params?.useBlurBack ?? true) ? capzonBlurback(highlightedSize)
      : capzonDarkback(highlightedSize)

    let zoneProgress = active
      ? mkObjectiveProgress(zoneData, heroTeam, highlightedSize, !isReplay.get() || !isReplayStopped.get())
      : null
    if (active && ownTeamIcon != null) {
      zoneProgress.__update({ 
        image = mkZoneIcon(ownTeamIcon, highlightedSize)
        color = ZONE_BG_COLOR
      })
    }

    let margin = params?.margin ?? (size / 1.5).tointeger()
    let total = (params?.total ?? 0).tofloat()
    let idx = (params?.idx ?? 0).tofloat()
    const gap_v = hdpx(60)
    let hlCenteredOffset = [((total - 1.0) * 0.5 - idx) * (size + margin), size + gap_v]
    let isEnemyOnLockedZone = locked && capzoneHasEnemies(presenceTeamCount)
    let zoneAppearAnims = isZombieObjectiveMode.get()
      ? zombieZoneAppearAnims : baseZoneAppearAnims

    let innerZone = {
      flow = FLOW_VERTICAL
      halign = ALIGN_CENTER
      vplace = ALIGN_TOP
      gap = hdpx(20)
      children = [
        {
          halign  = ALIGN_CENTER
          valign = ALIGN_CENTER
          size = highlightedSize
          children = [
            blur_back
            zoneProgress
            !locked
              ? mkObjectiveIcon(zoneData, iconSz, heroTeam, params.__merge({
                  baseZoneAppearAnims = zoneAppearAnims
                }))
              : {
                  rendObj = ROBJ_IMAGE
                  image = lockZone
                  halign = ALIGN_CENTER
                  valign = ALIGN_CENTER
                  size = highlight ? zoneLockIconSize * highlightScale : zoneLockIconSize
                  transform = const {pivot = [0.5, 0.5]}
                  color = isEnemyOnLockedZone ? ZONE_LOCK_ENEMY_PRESENT_COLOR : ZONE_LOCK_COLOR
                  animations = isEnemyOnLockedZone ? enemyPresenceAnimation : null
                  key = presenceTeamCount
                  fValue = 0
                }
            !highlight ? null
              : {
                  halign = ALIGN_CENTER
                  animations = animAppear ?? zoneAppearAnims
                  children = capzoneProgress(iconSz)
                }
          ]
        }
        !highlight ? null : mkZoneText(caption, animAppear ?? zoneAppearAnims)
      ]
      transform = {
        translate = highlight ? hlCenteredOffset : const [0, 0]
      }
      transitions = capZoneTransitions
      animations = active ? (params?.animActive ?? animActive) : null
    }

    return {
      size
      margin = [0, margin]
      halign = ALIGN_CENTER
      valign = ALIGN_CENTER
      key = {}

      zoneData = { zoneEid = eid }
      children = innerZone
      watch
      ui_order
    }
  }
}

let capzoneWidget = memoize(@(zoneEid, params={})  capzoneCtor(getZoneWatch(zoneEid), params))

let capzoneGap = const { size = 0 }

return {
  capzoneWidget
  capzoneGap
}
