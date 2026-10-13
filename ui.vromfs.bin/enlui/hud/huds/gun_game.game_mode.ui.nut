import "%ui/components/faComp.nut" as faComp
from "%dngscripts/ecs.nut" import INVALID_ENTITY_ID
from "%ui/hud/style.nut" import TEAM0_COLOR_FG, TEAM1_COLOR_FG
from "%ui/style/fontsStyle.nut" import fontBody
from "%ui/hud/state/local_player.nut" import localPlayerTeam, localPlayerEid
from "%ui/hud/state/gun_game_state.nut" import gunGameFriendlyTeamProgress, gunGameEnemyTeamProgress, gunGamePlayerProgress, gunGameLevelCount, gunGameLevelKillsDone, gunGameLevelKillsRequire, gunGameLeaderPlayerEid
  , gunGameLeaderName, gunGameLeaderTeam, gunGameLeaderIcon, gunGamePlayerIcon, gunGameKillsNeedToLead
from "%ui/helpers/remap_nick.nut" import remap_others
from "%ui/ui_library.nut" import *

const LEVELS_COLOR_BG = Color(100,100,100,200)
const pointSize = hdpxi(12)
const lineWidth = hdpx(20)
const lineHeight = hdpx(3)
const levelGap = hdpx(1)
const levelSpacing = pointSize + lineWidth + levelGap
const killIconSize = hdpxi(32)
const baseGap = hdpx(5)

const playerBgColor = 0xFF9AFFA2
let leaderBgColor = TEAM1_COLOR_FG
const panelBgColor = 0xCC2B353D


let levelsPointImage = Picture("ui/skin#train/train_point.svg:{0}:{1}"
  .subst(pointSize, pointSize))


let levelsSpacingLine = {
  vplace = ALIGN_CENTER
  size = const [lineWidth, lineHeight]
  rendObj = ROBJ_SOLID
  color = LEVELS_COLOR_BG
}


const enemyIconSize = hdpxi(24)
const playerIconSize = hdpxi(50)
const playerFrameSize = playerIconSize + hdpx(2)
const playerImageSize = playerIconSize * 3
const playerIconOffset = hdpx(28)
const enemyIconOffset = -hdpx(35)
const pointerSize = hdpx(11)


let mpPointer = @(fillColor, offset, vplace, poly) {
  size = const [pointerSize, pointerSize]
  pos = [0, offset]
  vplace
  rendObj = ROBJ_VECTOR_CANVAS
  fillColor
  commands = [
    [ VECTOR_WIDTH, 2 ],
    [ VECTOR_COLOR, fillColor ],
    poly
  ]
}

let upPointer = mpPointer(playerBgColor, -hdpx(12), ALIGN_TOP,
  [ VECTOR_POLY, 0, 100, 50, 0, 100, 100 ])
let downPointer = mpPointer(leaderBgColor, hdpx(8), ALIGN_BOTTOM,
  [ VECTOR_POLY, 0, 0, 50, 100, 100, 0 ])


function mkImage(iName, iSize) {
  return {
    size = [iSize, iSize]
    rendObj = ROBJ_IMAGE
    image = Picture($"!ui/portraits/event/{iName}.avif")
  }
}


let mkPlayerIcon = @(iName, iSize) {
  size = [iSize, iSize]
  rendObj = ROBJ_VECTOR_CANVAS
  fillColor = 0
  commands = [
    [ VECTOR_WIDTH, hdpx(10) ],
    [ VECTOR_COLOR, playerBgColor ],
    [ VECTOR_ELLIPSE, 50, 50, 50, 50 ],
  ]
  children = mkImage(iName, iSize)
}

let enemyMarkerUi = @() {
  watch = gunGameLeaderIcon
  pos = const [0, enemyIconOffset]
  halign = ALIGN_CENTER
  rendObj = ROBJ_VECTOR_CANVAS
  fillColor = 0
  commands = [
    [ VECTOR_WIDTH, hdpx(5) ],
    [ VECTOR_COLOR, leaderBgColor ],
    [ VECTOR_ELLIPSE, 50, 50, 50, 50 ],
  ]
  children = [
    downPointer
    mkImage(gunGameLeaderIcon.get(), enemyIconSize)
  ]
}


let killAnim = [
  { prop = AnimProp.opacity, from = 0, to = 1, duration = 0.3, play = true }
  { prop = AnimProp.translate, from = [0, -killIconSize], to = [0, 0],
    duration = 0.3, play = true }
  { prop = AnimProp.scale, from = [1, 1], to = [1.3, 0.7], duration = 0.2,
    delay = 0.3, play = true }
  { prop = AnimProp.scale, from = [1.3, 0.7], to = [1, 1], duration = 0.1,
    delay = 0.5, play = true }
  { prop = AnimProp.color, from = panelBgColor, to = TEAM1_COLOR_FG,
    duration = 0.3, delay = 0.3, play = true }
  { prop = AnimProp.color, from = TEAM1_COLOR_FG, to = panelBgColor,
    duration = 0.2, delay = 0.5, play = true }
]

function killsInfoUi() {
  let killsDone = gunGameLevelKillsDone.get()
  let killsRequire = gunGameLevelKillsRequire.get()
  return {
    watch = [gunGameLevelKillsDone, gunGameLevelKillsRequire]
    pos = const [playerFrameSize / 2, 0]
    padding = const [0, 0, 0, playerFrameSize / 2 + baseGap]
    flow = FLOW_HORIZONTAL
    hplace = ALIGN_LEFT
    valign = ALIGN_CENTER
    halign = ALIGN_RIGHT
    rendObj = ROBJ_BOX
    borderRadius = playerFrameSize / 2
    fillColor = playerBgColor
    children = [
      {
        rendObj = ROBJ_TEXT
        text = $"{killsDone}/{killsRequire}"
        color = panelBgColor
      }.__update(fontBody)
      {
        key = $"{killsDone}/{killsRequire}"
        size = [killIconSize, killIconSize]
        margin = [baseGap, baseGap, baseGap, 0]
        rendObj = ROBJ_IMAGE
        image = Picture("ui/skin#skull_white.svg:{0}:{0}".subst(killIconSize))
        color = panelBgColor
        transform = { pivot = [0.5, 1] }
        animations = killsDone > 0 && killsDone < killsRequire ? killAnim : null
      }
    ]
  }
}


let playerIconStyle = {
  transform = { pivot = [0.5, 0] }
  animations = [
    { prop = AnimProp.opacity, from = 0, to = 0, duration = 2.3, play = true }
    { prop = AnimProp.scale, from = [1, 1], to = [1.2, 0.9], duration = 0.1,
      delay = 2.3, play = true }
    { prop = AnimProp.scale, from = [1.2, 0.9], to = [1, 1], duration = 0.1,
      delay = 2.4, play = true }
  ]
}

function mkPlayerImageStyle(level, total) {
  let xOffset = ((total / 2).tointeger() - level + 1) * levelSpacing
  return {
    vplace = ALIGN_TOP
    opacity = 0
    transform = { pivot = [0.5, 0] }
    animations = [
      { prop = AnimProp.scale, from = [0.1, 0.1], to = [1.2, 1.2], duration = 0.3,
        play = true }
      { prop = AnimProp.scale, from = [1.2, 1.2], to = [1, 1], duration = 0.2,
        delay = 0.3, play = true }
      { prop = AnimProp.scale, from = [1, 1], to = [0.33, 0.33], duration = 0.3,
        delay = 2, play = true }
      { prop = AnimProp.opacity, from = 0, to = 1, duration = 0.3, play = true }
      { prop = AnimProp.opacity, from = 1, to = 1, duration = 2, delay = 0.3, play = true }
      { prop = AnimProp.translate, from = [xOffset, hdpx(100)], to = [xOffset, hdpx(100)],
        duration = 2, play = true }
      { prop = AnimProp.translate, from = [xOffset, hdpx(100)], to = [0, 0], duration = 0.3,
        delay = 2, play = true }
    ]
  }
}


function mkPlayerMarkerUi(level, total) {
  let watch = gunGamePlayerIcon
  return function() {
    if (gunGamePlayerIcon.get() == "")
      return { watch }

    return {
      watch
      size = FLEX
      halign = ALIGN_CENTER
      children = {
        size = const [playerFrameSize, playerFrameSize]
        pos = const [0, playerIconOffset]
        valign = ALIGN_CENTER
        halign = ALIGN_CENTER
        children = [
          {
            size = FLEX
            valign = ALIGN_CENTER
            halign = ALIGN_CENTER
            rendObj = ROBJ_VECTOR_CANVAS
            fillColor = playerBgColor
            commands = [
              [ VECTOR_WIDTH, hdpx(5) ],
              [ VECTOR_COLOR, playerBgColor ],
              [ VECTOR_ELLIPSE, 50, 50, 50, 50 ],
            ]
            children = [
              upPointer
              killsInfoUi
              mkImage(gunGamePlayerIcon.get(), playerIconSize)
            ]
          }.__update(playerIconStyle)
          mkPlayerIcon(gunGamePlayerIcon.get(), playerImageSize)
            .__update(mkPlayerImageStyle(level, total))
        ]
      }
    }
  }
}


function mkLevelsPoint(level, total) {
  let pColor = Computed(function() {
    let teamProgress = gunGameFriendlyTeamProgress.get()
    let enemyProgress = gunGameEnemyTeamProgress.get()
    return level <= teamProgress ? TEAM0_COLOR_FG
      : level <= enemyProgress ? TEAM1_COLOR_FG
      : LEVELS_COLOR_BG
  })

  let hasLeaderMarker = Computed(function() {
    let leaderPlayerEid = gunGameLeaderPlayerEid.get()
    if (leaderPlayerEid == INVALID_ENTITY_ID
        || leaderPlayerEid == localPlayerEid.get()
        || gunGameLeaderIcon.get() == "")
      return false

    let leaderLevel = max(gunGameFriendlyTeamProgress.get(), gunGameEnemyTeamProgress.get())
    return leaderLevel == level
  })

  let hasPlayerMarker = Computed(function() {
    return gunGamePlayerProgress.get() == level && gunGamePlayerIcon.get() != ""
  })

  return {
    size = const [pointSize, pointSize]
    children = [
      @() {
        watch = [ pColor, hasLeaderMarker ]
        size = FLEX
        halign = ALIGN_CENTER
        rendObj = ROBJ_IMAGE
        image = levelsPointImage
        color = pColor.get()
        children = hasLeaderMarker.get() ? enemyMarkerUi : null
      }
      @() {
        watch = hasPlayerMarker
        size = FLEX
        children = hasPlayerMarker.get() ? mkPlayerMarkerUi(level, total) : null
      }
    ]
  }
}


let blockStyle = {
  padding = hdpx(5)
  rendObj = ROBJ_BOX
  borderRadius = hdpx(8)
  fillColor = panelBgColor
}

function progressBlockUi() {
  let total = gunGameLevelCount.get()
  let children = [mkLevelsPoint(0, total)]
  for (local i = 1; i < total; i++) {
    children.append(levelsSpacingLine)
    children.append(mkLevelsPoint(i, total))
  }

  return {
    watch = gunGameLevelCount
    flow = FLOW_HORIZONTAL
    gap = levelGap
    children
  }.__update(blockStyle)
}


let youAreLeaderObject = {
  flow = FLOW_HORIZONTAL
  gap = baseGap
  valign = ALIGN_CENTER
  children = [
    faComp("check", {
      fontSize = hdpxi(32)
      color = playerBgColor
    })
    {
      rendObj = ROBJ_TEXT
      color = playerBgColor
      text = loc("gun_game/youAreLeader")
    }.__update(fontBody)
  ]
}


function levelsNeedToLeadUi() {
  let watch = [gunGameFriendlyTeamProgress, gunGameEnemyTeamProgress, gunGamePlayerProgress]
  let leaderLevel = max(gunGameFriendlyTeamProgress.get(), gunGameEnemyTeamProgress.get())
  let playerLevel = gunGamePlayerProgress.get()
  let levels = leaderLevel - playerLevel
  if (levels <= 0)
    return { watch }

  return {
    watch
    flow = FLOW_HORIZONTAL
    padding = baseGap
    valign = ALIGN_CENTER
    rendObj = ROBJ_BOX
    borderRadius = playerFrameSize / 2
    fillColor = TEAM1_COLOR_FG
    children = [
      {
        rendObj = ROBJ_TEXT
        color = panelBgColor
        text = $"+{levels}"
      }.__update(fontBody)
      {
        size = [killIconSize, killIconSize]
        rendObj = ROBJ_IMAGE
        image = Picture("ui/skin#research/secondary_weap_slot_upgrade_icon.svg:{0}:{0}"
          .subst(killIconSize))
        color = panelBgColor
      }
    ]
  }
}


function leaderBlockUi() {
  let hasNoLeader = gunGameLeaderPlayerEid.get() == INVALID_ENTITY_ID
  let isPlayerLeader = gunGameLeaderPlayerEid.get() == localPlayerEid.get()
  let isYourTeamLeader = gunGameLeaderTeam.get() == localPlayerTeam.get()

  return {
    watch = [
      gunGameLeaderPlayerEid, gunGameLeaderName, gunGameLeaderTeam,
      localPlayerEid, localPlayerTeam
    ]
    size = const [0, SIZE_TO_CONTENT]
    flow = FLOW_HORIZONTAL
    valign = ALIGN_CENTER
    children = hasNoLeader ? null
      : isPlayerLeader ? youAreLeaderObject
      : [
          {
            rendObj = ROBJ_TEXT
            text = loc("gun_game/currentLeader")
          }.__update(fontBody)
          {
            halign = ALIGN_CENTER
            valign = ALIGN_BOTTOM
            children = [
              {
                rendObj = ROBJ_TEXT
                color = isYourTeamLeader ? TEAM0_COLOR_FG : TEAM1_COLOR_FG
                text = remap_others(gunGameLeaderName.get())
              }.__update(fontBody)
              {
                size = 0
                pos = [0, pointerSize]
                halign = ALIGN_CENTER
                children = levelsNeedToLeadUi
              }
            ]
          }
        ]
  }
}


let gunGameModeUi = {
  flow = FLOW_HORIZONTAL
  gap = fsh(3)
  margin = const [hdpx(25), 0, hdpx(60), 0]
  valign = ALIGN_CENTER
  children = [
    progressBlockUi
    leaderBlockUi
  ]
}


let hasDebugInfo = Watched(false)
console_register_command(@() hasDebugInfo.set(!hasDebugInfo.get()), "gunGame.debug")

function gunGameModeDebugUi() {
  let watch = hasDebugInfo
  if (!hasDebugInfo.get())
    return { watch }

  return {
    watch
    size = 0
    pos = const [0, sh(94)]
    halign = ALIGN_CENTER
    valign = ALIGN_BOTTOM
    children = {
      flow = FLOW_HORIZONTAL
      padding = lineHeight
      halign = ALIGN_CENTER
      rendObj = ROBJ_SOLID
      color = panelBgColor
      children = [
        function() {
          local str = "PLAYER INFO:"
          str = $"{str}\n  - localPlayerEid: {localPlayerEid.get()}"
          str = $"{str}\n  - localPlayerTeam: {localPlayerTeam.get()}"
          str = $"{str}\n  - gunGamePlayerProgress: {gunGamePlayerProgress.get()}\n"
          str = $"{str}\n  - icon: {gunGamePlayerIcon.get()}"
          str = $"{str}\n  - gunGameKillsNeedToLead: {gunGameKillsNeedToLead.get()}"
          return {
            watch = [localPlayerEid, gunGamePlayerProgress, gunGamePlayerIcon,
              localPlayerTeam, gunGameKillsNeedToLead]
            size = const [sw(18), SIZE_TO_CONTENT]
            rendObj = ROBJ_TEXTAREA
            behavior = Behaviors.TextArea
            text = str
          }
        }
        function() {
          local str = "LEADER INFO:"
          str = $"{str}\n  - gunGameLeaderPlayerEid: {gunGameLeaderPlayerEid.get()}"
          str = $"{str}\n  - gunGameLeaderTeam: {gunGameLeaderTeam.get()}"
          str = $"{str}\n  - gunGameFriendlyTeamProgress: {gunGameFriendlyTeamProgress.get()}"
          str = $"{str}\n  - gunGameEnemyTeamProgress: {gunGameEnemyTeamProgress.get()}"
          str = $"{str}\n  - icon: {gunGameLeaderIcon.get()}"
          str = $"{str}\n  - name: {gunGameLeaderName.get()}"
          return {
            watch = [gunGameFriendlyTeamProgress, gunGameEnemyTeamProgress,
              gunGameLeaderPlayerEid, gunGameLeaderIcon, gunGameLeaderName,
              gunGameLeaderTeam]
            size = const [sw(18), SIZE_TO_CONTENT]
            rendObj = ROBJ_TEXTAREA
            behavior = Behaviors.TextArea
            text = str
          }
        }
      ]
    }
  }
}


let gunGameModeWithDebugUi = freeze({
  halign = ALIGN_CENTER
  children = [
    gunGameModeUi
    gunGameModeDebugUi
  ]
})

return gunGameModeWithDebugUi
