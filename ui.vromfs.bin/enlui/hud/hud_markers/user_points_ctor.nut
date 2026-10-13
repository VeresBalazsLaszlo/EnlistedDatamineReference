from "%ui/hud/hud_markers/components/hud_markers_components.nut" import makeArrow
from "%ui/style/fontsStyle.nut" import fontBody
from "%ui/style/designConst.nut" import selectedTxtColor
from "%ui/hud/state/human_teammates.nut" import groupmateIds
from "%ui/state/teammate_markers_state.nut" import teammateMarkersState, MARKER_COLOR, MARKER_INDEX
from "%ui/ui_library.nut" import *

let { user_points_by_type } = require("%ui/hud/state/user_points.nut")


const myMainUserMarkColor = Color(250,250,50,250)
const forMainUserMarkColor = Color(180,180,250,250)
const forEnemyMarkColor = Color(255,115,83,250)
const myEnemyMarkColor = Color(251,24,34,250)


const teammateMarkColor = Color(0,255,255,250)
const myDefMarkColor = Color(250,250,50,250)
const forDefMarkColor = Color(180,180,250,250)

let markSz = [hdpxi(21), hdpxi(28)]
let vehicleMarkSz = [hdpxi(32), hdpxi(32)]
let buildingMarkSz = vehicleMarkSz
let main_user_mark = Picture("ui/skin#map_pin.svg:{0}:{1}".subst(markSz[0],markSz[1]))
let enemy_user_mark = Picture("ui/skin#unit_inner.svg:{0}:{1}".subst(markSz[0],markSz[1]))
const arrowOffset = fsh(2)
let markerIndexSize = [hdpxi(20), hdpxi(20)]
let markerIndexOffset = -markerIndexSize[1] - arrowOffset

let enemyMarkAnimation = [{ prop = AnimProp.color, from = forEnemyMarkColor, to = Color(255,200,200),
  duration = 0.7, play = true, loop = true, easing = Blink, globalTimer = true, id = "def" }]
let myEnemyMarkAnimation = [{ prop = AnimProp.color, from = myEnemyMarkColor, to = Color(100,0,0),
  duration = 0.7, play = true, loop = true, easing = Blink, globalTimer = true, id = "my" }]
let tmEnemyMarkAnimation = [{ prop = AnimProp.color, from = Color(0,100,100), to = Color(200,255,255),
  duration = 0.7, play = true, loop = true, easing = Blink, globalTimer = true, id = "tm" }]

let mkArrow = memoize(@(color) makeArrow({color, yOffs = arrowOffset, anim = null}))

let mkSquadMemberId = memoize(@(color, squadMemberId, anim) {
  rendObj = ROBJ_SOLID
  size = markerIndexSize
  pos = [0, markerIndexOffset]
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  color
  animations = anim
  key = anim?[0].id ? "{0}_{1}_{2}".subst(squadMemberId ?? "", color, anim[0].id) : null
  children = squadMemberId == null ? null : {
    rendObj = ROBJ_TEXT
    color = selectedTxtColor
    text = squadMemberId + 1
  }.__update(fontBody)
})

let mkPointMarkerCtor = kwarg(function(image = null, myColor = myDefMarkColor,
  foreignColor = forDefMarkColor, yOffs = 0, size = null, animation = null, tmStateWatch = null
) {
  let mkIcon = memoize(@(ico, color, anims, iconSize) freeze({
    rendObj = ROBJ_IMAGE
    size = iconSize ?? markSz
    pos = [0, sh(yOffs)]
    color
    image = ico
    animations = anims
    key = anims?[0].id ? $"{color}_{anims?[0].id}" : null
  }))

  return function(eid, data) {
    let { byLocalPlayer = false, customIcon = null, squadMemberId = null } = data
    let isTeammate = squadMemberId != null

    return function() {
      let tmState = tmStateWatch?.get()
      let needColor = tmStateWatch && isTeammate && ((tmState & MARKER_COLOR) != 0)
      let needIndex = tmStateWatch && isTeammate && (groupmateIds.get().len() > 1) && ((tmState & MARKER_INDEX) != 0)

      let color = byLocalPlayer ? myColor
        : needColor ? teammateMarkColor
        : foreignColor
      let anim = byLocalPlayer ? myEnemyMarkAnimation
        : needColor ? tmEnemyMarkAnimation
        : animation

      return {
        data = {
          eid
          minDistance = 0.7
          maxDistance = 10000
          distScaleFactor = 0.5
          clampToBorder = true
        }
        watch = tmStateWatch
        halign = ALIGN_CENTER
        valign = ALIGN_BOTTOM
        transform = true
        key = eid
        sortOrder = eid
        children = [
          mkIcon(customIcon ?? image, color, anim, size)
          customIcon == null ? mkArrow(color) : null
          needIndex ? mkSquadMemberId(color, squadMemberId, anim) : null
        ]
      }
    }
  }
})
let ctor_by_type = {
  enemy_user_point = mkPointMarkerCtor({
    image = enemy_user_mark,
    myColor = myEnemyMarkColor,
    foreignColor = forEnemyMarkColor,
    yOffs = -1,
    size = markSz,
    animation = enemyMarkAnimation,
    tmStateWatch = teammateMarkersState
  })
  main_user_point = mkPointMarkerCtor({image = main_user_mark, myColor = myMainUserMarkColor, foreignColor = forMainUserMarkColor})
  enemy_vehicle_user_point = mkPointMarkerCtor({myColor = myEnemyMarkColor, foreignColor = forEnemyMarkColor, yOffs=-1, size=vehicleMarkSz})
  enemy_building_user_point = mkPointMarkerCtor({myColor = myEnemyMarkColor, foreignColor = forEnemyMarkColor, size = buildingMarkSz})
}
return [
  "main_user_point",
  "enemy_user_point",
  "enemy_vehicle_user_point",
  "enemy_building_user_point"
].reduce(function(res, typ){
    let watch = user_points_by_type[typ]
    let c = memoize(@(eid) ctor_by_type[typ](eid, watch.get()[eid]))
    res[$"{typ}_ctor"] <- { watch, ctor = @() watch.get().keys().map(c) }
    return res
  },
  {}
)
