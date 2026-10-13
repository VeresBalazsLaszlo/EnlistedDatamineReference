import "%ui/hud/style.nut" as style
from "%ui/style/fontsStyle.nut" import fontBody, fontSub
from "dm" import DM_PROJECTILE, DM_MELEE, DM_EXPLOSION, DM_ZONE, DM_COLLISION, DM_HOLD_BREATH, DM_FIRE
  , DM_GAS, DM_BACKSTAB, DM_BARBWIRE
from "%ui/hud/state/hudOptionsState.nut" import fontKillLog
from "%ui/style/killog_colors.nut" import MY_SQUAD_COLOR, MY_GROUP_COLOR, MY_TEAM_COLOR, ENEMY_TEAM_COLOR
from "%ui/components/rankPresentation.nut" import mkRankIcon
from "dagor.random" import rnd_int
from "%ui/hud/state/gun_game_state.nut" import isGunGameMode
from "%ui/ui_library.nut" import *

let { killLogState } = require("%ui/hud/state/kill_log_es.nut")
let defTextColor = style.DEFAULT_TEXT_COLOR

const MIN_RANK_TO_SHOW = 15

let BIG_SIZE_KILL_ICON = hdpxi(26)
let SMALL_SIZE_KILL_ICON = hdpxi(20)

let textElem = @(text, fontStyle = fontSub, color = null) {
  rendObj = ROBJ_TEXT
  text
  color
}.__update(fontStyle)

const killIconsHeadshot = "killlog/kill_headshot.svg"

let damageTypeIcons = {
  [DM_PROJECTILE]  = null, 
  [DM_MELEE]       = "killlog/kill_melee.svg",
  [DM_EXPLOSION]   = "killlog/kill_explosion.svg",
  [DM_ZONE]        = "killlog/kill_zone_wh.svg",
  [DM_COLLISION]   = "killlog/kill_collision.svg",
  [DM_HOLD_BREATH] = "killlog/kill_asphyxia.svg",
  [DM_BACKSTAB]    = "killlog/kill_backstab.svg",
  [DM_FIRE]        = "killlog/kill_fire.svg",
  [DM_GAS]         = "killlog/kill_fire.svg",
  [DM_BARBWIRE]    = null
}

let getPicture = memoize(function(name, sizeIcon) {
  return name!=null
    ? Picture("ui/skin#{0}:{1}:{1}".subst(name, sizeIcon))
    : null
})

let mkIcon = memoize(function(image, sizeIcon){
  return image != null ? {
    size = [sizeIcon, sizeIcon]
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    vplace = ALIGN_BOTTOM
    children = [
      {
        rendObj = ROBJ_IMAGE
        size = [sizeIcon, sizeIcon]
        image = image
      }
    ]
  } : null
})

function mkKillEventIcon(data, sizeIcon = hdpxi(20)) {
  let { isHeadshot = false, damageType = 0, typeIcon = "" } = data
  let imageName = typeIcon != "" ? typeIcon
    : isHeadshot ? killIconsHeadshot
    : damageTypeIcons?[damageType]
  return mkIcon(getPicture(imageName, sizeIcon), sizeIcon)
}

let killMsgAnim = [
  { prop=AnimProp.scale, from=[1,0.01], to=[1,1], duration=0.2, play=true, easing=OutCubic }
]

const BLUR_COLOR = 0x11000000

let blurBack = {
  rendObj = ROBJ_WORLD_BLUR
  size = FLEX
  color = BLUR_COLOR
}

function nameAndColor(entity) {
  local name = entity?.name
  local color = ENEMY_TEAM_COLOR

  if (entity?.isHero)
    return {
      name = loc("log/local_player")
      color = MY_SQUAD_COLOR
    }

  if (isGunGameMode.get())
    return { name, color }

  if (entity?.inMyGroup)
    return {
      name = (name ?? "") != ""? loc(name) : loc("log/squadmate")
      color = MY_GROUP_COLOR
    }

  if (entity?.inMyTeam)
    return {
      name = name != null && name != "" ? loc(name)
        : entity?.inMySquad ? loc("log/squadmate")
        : loc("log/teammate")
      color = (entity?.inMySquad ? MY_SQUAD_COLOR : MY_TEAM_COLOR)
    }

  return {
    name = name != null && name != "" ? loc(name) : ""
    color
  }
}

let padding = const [0, hdpx(5), 0, hdpx(5)]

let selfContainer = {
  rendObj = ROBJ_FRAME
  borderWidth = const [0, hdpx(3), 0, 0]
  color = MY_SQUAD_COLOR
  padding = const [0, hdpx(3), 0, 0]
}

let appendRank = @(textBlock, rank) (rank ?? 0) < MIN_RANK_TO_SHOW
  ? textBlock
  : {
      flow = FLOW_HORIZONTAL
      children = [textBlock, mkRankIcon(rank)]
    }

function message(data, fontStyle, sizeIcon) {
  local children = null

  let gunInfo = {
    flow = FLOW_HORIZONTAL
    gap = hdpx(5)
    children = [
      data?.gunName ? textElem(loc(data.gunName), fontStyle, defTextColor) : null
      mkKillEventIcon(data, sizeIcon)
    ]
  }
  let num = (data?.num ?? 1) == 1 ? null : {
    flow = FLOW_HORIZONTAL
    children = textElem(loc("common/amountShort", { count = data.num }), fontStyle)
  }
  if (data?.victim?.eid == data?.killer?.eid && data?.victim?.eid != null) {
    let { name, color } = nameAndColor(data.victim)
    children = data.victim.isHero
      ? textElem(loc("log/local_player_suicide"), fontStyle, color)
      : data.victim.vehicle ?
        [
          gunInfo
          textElem(name, fontStyle, color)
        ]
      : [
          appendRank(textElem(loc("log/player_suicide", { user = name }), fontStyle, color), data.victim.rank)
          gunInfo
        ]
  } else {
    let victimInfo = nameAndColor(data.victim)
    let killerInfo = nameAndColor(data.killer)
    children = [
      appendRank(textElem(killerInfo.name, fontStyle, killerInfo.color), data.killer.rank)
      gunInfo
      appendRank(textElem(victimInfo.name, fontStyle, victimInfo.color), data.victim.rank)
      num
    ]
  }

  return {
    children = [
      blurBack
      {
        size = SIZE_TO_CONTENT
        flow = FLOW_HORIZONTAL
        halign = ALIGN_RIGHT
        valign = ALIGN_CENTER
        children
        margin = [sizeIcon/4.0, 0]
        gap = hdpx(9)
        padding
        key = data
        transform = { pivot = [0, 0.5] }
        animations = killMsgAnim
      }
    ]
  }.__update(data?.killer.isHero ? selfContainer : {})
}

let itemAnim = [
  
  
  { prop=AnimProp.opacity, from=1, to=0, duration=0.2, playFadeOut=true}
  { prop=AnimProp.scale, from=[1,1], to=[1,0], duration=0.2, playFadeOut=true}
]

function killLogRoot() {
  let res = {watch = [killLogState.events, fontKillLog]}
  if (fontKillLog.get() == "off")
    return res
  let isFontBigStyle = fontKillLog.get() == "big"
  let fontStyle = isFontBigStyle ? fontBody : fontSub
  let sizeIcon = isFontBigStyle ? BIG_SIZE_KILL_ICON : SMALL_SIZE_KILL_ICON
  let children = killLogState.events.get().map(
    @(item) {
      size = SIZE_TO_CONTENT
      key = item
      color = style.MESSAGE_BG_END
      children = message(item, fontStyle, sizeIcon)
      transform = { pivot = [0, 0] }
      animations = itemAnim
    }
  )

  return res.__update({
    size   = const [fsh(30), fsh(50)]
    halign = ALIGN_RIGHT
    behavior = Behaviors.SmoothScrollStack
    speed = fsh(20)
    gap = hdpx(1)
    children
  })
}

function fakeLog() {
  let names = ["", "Bob", "Alice", "John", "Jane"]
  let killerEid = rnd_int(1, names.len())
  let victimEid = rnd_int(1, names.len())
  let rank = rnd_int(1, 20)
  let damageType = damageTypeIcons.keys()[rnd_int(0, damageTypeIcons.len() - 1)]
  killLogState.pushEvent({
    killer = { eid = killerEid, name = names[killerEid - 1], isHero = killerEid == 1, rank }
    victim = { eid = victimEid, name = names[victimEid - 1], isHero = victimEid == 1, isAlive = false, rank }
    damageType
    gunName = damageType ? $"Boomstick Mk {"".join(array(rnd_int(1, 3), "I"))}" : null
  })
}

console_register_command(fakeLog, "ui.killog")
console_register_command(@(num) array(num).each(@(_) fakeLog()), "ui.killogSome")

return killLogRoot
