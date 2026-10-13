import "%ui/hud/components/mkUnitHp.nut" as mkUnitHp
import "%ui/components/faComp.nut" as faComp
from "dagor.system" import DBGLEVEL
from "%ui/style/fontsStyle.nut" import fontSub, fontBody, fontHeading2
from "%ui/helpers/timers.nut" import mkCountdownTimerPerSec
from "%ui/helpers/time.nut" import secondsToStringLoc
from "%ui/style/designConst.nut" import smallPadding, midPadding, bigPadding, defTxtColor, titleTxtColor, blurBgFillColor, negativeTxtColor
from "%ui/hud/state/zombie_zones_state.nut" import zombieBosses, getZombieBossWatch, zombieArenas, sessionEndTime, getZombieArenaWatch, aliveCratersCount, activeCratersCount
  , zombieRadios, getZombieRadioWatch, numTokens, objectiveTokens, evacuationEnabled, evacuationTimeLeft, patrolsDebugTime
  , patrolsCount, patrolsOverrideState, patrolsProgress, patrolsWave, selfresCount
from "%ui/ui_library.nut" import *

const TOKEN_ICON = "!ui/uiskin/currency/halloween_token.svg:{0}:{0}:K"
const tokenIconSize = hdpxi(22)
const zombieModeUiColor = Color(255,255,255)

function arenaCtor(zoneWatch) {
  return @() zoneWatch.get().active ? {
    flow = FLOW_HORIZONTAL
    watch = zoneWatch
    children = [
      {
        rendObj = ROBJ_TEXT
        text = $"Progress: {zoneWatch.get().kills} / {zoneWatch.get().killsRequire} "
        color = zombieModeUiColor
      }.__update(fontBody)

      {
        rendObj = ROBJ_TEXT
        text = $"Arena wave: {zoneWatch.get().curWave} "
        color = zombieModeUiColor
      }.__update(fontBody)

      function() {
        let arenaTimer = Computed(@() zoneWatch.get()?.nextWaveTime)
        let arenaCountDownTimer = mkCountdownTimerPerSec(arenaTimer) 
        return {
          watch = arenaTimer
          children = [
            @() zoneWatch.get().nextWaveTime > 0 ? {
              rendObj = ROBJ_TEXT
              watch = arenaCountDownTimer
              text = $"Next wave: {arenaCountDownTimer.get()}"
              color = zombieModeUiColor
            }.__update(fontBody) : {watch = arenaCountDownTimer}
          ]
        }
      }
    ]
  } : {watch = zoneWatch}
}


function radioCtor(zoneWatch) {
  let radioTimer = Computed(@() zoneWatch.get()?.nextActivationAfterTime)
  let radioCountDownTimer = mkCountdownTimerPerSec(radioTimer) 
  return @() zoneWatch.get().active ? {
    watch = [radioTimer, zoneWatch]
    flow = FLOW_HORIZONTAL
    children = [
      {
        watch = [radioCountDownTimer]
        rendObj = ROBJ_TEXT
        text = $"Progress: {(radioCountDownTimer.get()  > 0 || !zoneWatch.get().objectiveActive ? 0 : 1) + zoneWatch.get().curWaveId} / {zoneWatch.get().wavesCount} "
        color = zombieModeUiColor
      }.__update(fontBody)
      @() radioCountDownTimer.get() > 0 ? {
          rendObj = ROBJ_TEXT
          watch = radioCountDownTimer
          text = $"Next plant: {radioCountDownTimer.get()}"
          color = zombieModeUiColor
          }.__update(fontBody) : {watch = radioCountDownTimer}
    ]
  } : {watch = zoneWatch}
}

function bossCtor(zoneWatch) {
  return @() zoneWatch.get().active ? {
    watch = [zoneWatch]
    flow = FLOW_HORIZONTAL
    children = {
      rendObj = ROBJ_TEXT
      text = $"Boss HP: {zoneWatch.get().hp} / {zoneWatch.get().maxHp}"
      color = zombieModeUiColor
    }.__update(fontBody)
  } : {watch = zoneWatch}
}
let arenaWidget = memoize(@(arenaEid) arenaCtor(getZombieArenaWatch(arenaEid)))

let arenasBlock = @() {
  watch = [zombieArenas]
  flow = FLOW_VERTICAL
  hplace = ALIGN_CENTER
  children = zombieArenas.get().keys().map(@(zEid) arenaWidget(zEid))
}

let radioWidget = memoize(@(arenaEid) radioCtor(getZombieRadioWatch(arenaEid)))
let radioBlock = @() {
  watch = [zombieRadios]
  flow = FLOW_VERTICAL
  hplace = ALIGN_CENTER
  children = zombieRadios.get().keys().map(@(zEid) radioWidget(zEid))
}

let bossWidget = memoize(@(arenaEid) bossCtor(getZombieBossWatch(arenaEid)))
let bossesBlock = @() {
  flow = FLOW_VERTICAL
  watch = [zombieBosses]
  hplace = ALIGN_CENTER
  children = zombieBosses.get().keys().map(@(zEid) bossWidget(zEid))
}

let showPlayerTokens = memoize(function(tokens) {
  return {
    rendObj = ROBJ_TEXT
    color = zombieModeUiColor
    text = $"You have: {tokens} tokens"
  }
})

let tokensBlock = @() {
  watch = [numTokens]
  flow = FLOW_VERTICAL
  hplace = ALIGN_CENTER
  children = showPlayerTokens(numTokens.get()).__update(fontBody)
}

let evacuationBlock = @() {
  watch = [evacuationEnabled]
  flow = FLOW_VERTICAL
  hplace = ALIGN_CENTER
  children = evacuationEnabled.get() ? [
    {
      rendObj = ROBJ_TEXT
      text = "Evacuation"
      color = zombieModeUiColor
    }.__update(fontBody)
    @() evacuationTimeLeft.get() > 0 ? {
      rendObj = ROBJ_TEXT
      watch = evacuationTimeLeft
      text = $"End time: {evacuationTimeLeft.get()}"
      color = zombieModeUiColor
    }.__update(fontBody) : {watch = evacuationTimeLeft}
  ] : null
}

let cratersBlock = @() {
  watch = [activeCratersCount]
  flow = FLOW_VERTICAL
  hplace = ALIGN_CENTER
  children = activeCratersCount.get() > 0? [
    @() {
      rendObj = ROBJ_TEXT
      watch = [aliveCratersCount, activeCratersCount]
      text = $"Attack craters {aliveCratersCount.get()} / {activeCratersCount.get()}"
      color = zombieModeUiColor
    }.__update(fontBody)
  ] : null
}

let patrolsBlock = @() {
  flow = FLOW_HORIZONTAL
  hplace = ALIGN_CENTER
  children = [
    @() {
      rendObj = ROBJ_TEXT
      watch = [patrolsDebugTime]
      text = patrolsDebugTime.get() > 0 ? $"Patrols activate time {patrolsDebugTime.get()} " : "Patrols waiting respawn. "
      color = zombieModeUiColor
    }.__update(fontBody)
    @() {
      rendObj = ROBJ_TEXT
      watch = [patrolsCount]
      text = $"Count: {patrolsCount.get()} "
      color = zombieModeUiColor
    }.__update(fontBody)
    @() {
      rendObj = ROBJ_TEXT
      watch = [patrolsWave]
      text = $"Last Wave: {patrolsWave.get()} "
      color = zombieModeUiColor
    }.__update(fontBody)
    @() {
      rendObj = ROBJ_TEXT
      watch = [patrolsOverrideState, patrolsProgress]
      text = $"Overrided: {patrolsProgress.get()} / {patrolsOverrideState.get()} "
      color = zombieModeUiColor
    }.__update(fontBody)
  ]
}

let gameModeDebugBlock = {
  hplace = ALIGN_LEFT
  flow = FLOW_VERTICAL
  valign = ALIGN_TOP
  gap = fsh(1)
  children = [
    tokensBlock
    patrolsBlock
    evacuationBlock
    arenasBlock
    radioBlock
    cratersBlock
    bossesBlock
  ]
}


let isDebugNeeded = Watched(false)
let isInfoNeeded = Watched(DBGLEVEL > 0)

const infoBlockWidth = hdpx(300)
const bossInfoBlockWidth = hdpx(460)
let radioIcon = faComp("wifi", { fontSize = hdpx(32), color = titleTxtColor })

let headerTxtStyle = {
  margin = [smallPadding, 0]
}.__update(fontSub)

let blurStyle = {
  rendObj = ROBJ_WORLD_BLUR_PANEL
  fillColor = blurBgFillColor
  color = 0xFFBBBBBB
}

let mkText = @(text, override = {}) {
  rendObj = ROBJ_TEXT
  color = titleTxtColor
  text
}.__update(fontSub, override)

let mkTextArea = @(text, override = {}) {
  size = FLEX_H
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  color = defTxtColor
  text
}.__update(fontSub, override)

let mkTextWithBlink = @(text, override = {}) {
  key = $"{text}"
  rendObj = ROBJ_TEXT
  color = titleTxtColor
  text
  transform = { pivot = [0.5, 1] }
  animations = [
    { prop = AnimProp.scale, from = [1, 1], to = [2, 2], duration = 0.2, play = true }
    { prop = AnimProp.scale, from = [2, 2], to = [1, 1], duration = 0.3, delay = 0.2, play = true }
    { prop = AnimProp.color, from = titleTxtColor, to = 0xFFFF0000, delay = 0.8, duration = 0.2, play = true }
    { prop = AnimProp.color, from = titleTxtColor, to = 0xFFFF0000, delay = 1.2, duration = 0.2, play = true }
    { prop = AnimProp.color, from = titleTxtColor, to = 0xFFFF0000, delay = 1.6, duration = 0.2, play = true }
  ]
}.__update(fontHeading2, override)


function mkEliteWidget(elite) {
  let { active = false, hp = -1, maxHp = -1 } = elite
  return !active ? null : {
    size = FLEX_H
    children = mkUnitHp(hp, maxHp)
  }
}

function mkBossWidget(boss) {
  let { active = false, hp = -1, maxHp = -1, nameLocId = "",  agressive = true} = boss
  return !active || !agressive ? null : {
    size = const [bossInfoBlockWidth, SIZE_TO_CONTENT]
    flow = FLOW_VERTICAL
    halign = ALIGN_CENTER
    children = [
      nameLocId == "" ? null : mkText(loc(nameLocId), headerTxtStyle)
      mkUnitHp(hp, maxHp, { height = hdpx(12) })
    ]
  }
}


function mkElitesBlockUi() {
  let elitesData = Computed(function() {
    let elites = []
    let bosses = []
    foreach (elite in zombieBosses.get()) {
      let { maxHp = 0, hp = 0 } = elite
      if (maxHp <= 1000 && hp > 0)
        elites.append(elite)
      if (maxHp > 1000 && hp > 0)
        bosses.append(elite)
    }
    return { elites, bosses }
  })
  return function() {
    let watch = elitesData
    let { elites, bosses } = elitesData.get()
    if (elites.len() == 0 && bosses.len() == 0)
      return { watch }

    return {
      watch
      size = FLEX_H
      children = [
        {
          size = FLEX_H
          flow = FLOW_VERTICAL
          margin = const [sh(10),0,0,0]
          padding = bigPadding
          children = [
            {
              flow = FLOW_HORIZONTAL
              gap = smallPadding
              valign = ALIGN_BOTTOM
              children = [
                mkText(loc("zombieMod/killElites"), headerTxtStyle)
                mkTextWithBlink(elites.len() + bosses.len())
              ]
            }
            elites.len() == 0 ? null
              : {
                  size = FLEX_H
                  flow = FLOW_VERTICAL
                  gap = smallPadding
                  children = elites.map(mkEliteWidget)
                }
            mkTextArea(loc("zombieMod/killElites/desc"))
          ]
        }.__update(blurStyle)
        {
          size = 0
          pos = [sw(50) - fsh(2), fsh(5)]
          halign = ALIGN_CENTER
          children = bosses.len() == 0 ? null
            : {
                padding = midPadding
                flow = FLOW_VERTICAL
                gap = smallPadding
                children = bosses.map(mkBossWidget)
              }.__update(blurStyle)
        }
      ]
    }
  }
}


function cratersBlockUi() {
  let watch = activeCratersCount
  if (activeCratersCount.get() <= 0)
    return { watch }

  return {
    watch
    size = FLEX_H
    flow = FLOW_VERTICAL
    margin = const [sh(10),0,0,0]
    padding = bigPadding
    children = [
      {
        flow = FLOW_HORIZONTAL
        gap = midPadding
        valign = ALIGN_BOTTOM
        children = [
          mkText(loc("zombieMod/destroyGates"), headerTxtStyle)
          @() {
            watch = aliveCratersCount
            children = mkTextWithBlink(aliveCratersCount.get())
          }
        ]
      }
      mkTextArea(loc("zombieMod/destroyGates/desc"))
    ]
  }.__update(blurStyle)
}


let mkNegativeBlink = @(key) {
  key
  size = FLEX
  rendObj = ROBJ_SOLID
  color = negativeTxtColor
  opacity = 0.7
  animations = [
    { prop = AnimProp.opacity, from = 0, to = 0.7, duration = 0.3, play = true }
    { prop = AnimProp.opacity, from = 0.7, to = 0, duration = 0.7, delay = 0.3, play = true }
  ]
}


local prevActivationAfterTime = -1

let mkRadioBlockUi = @(zombieCountDownTimer) function () {
  let watch = zombieRadios
  if (zombieRadios.get().len() <= 0)
    return { watch }

  let activeRadio = zombieRadios.get().findvalue(@(v) v?.active ?? false)
  if (activeRadio == null)
    return { watch }

  let {
    objectiveActive = false, curWaveId = 0, wavesCount = 0, activationPeriod = -1,
    nextActivationAfterTime = -1
  } = activeRadio
  return {
    watch
    size = FLEX_H
    flow = FLOW_VERTICAL
    margin = const [sh(10),0,0,0]
    padding = bigPadding
    children = [
      {
        flow = FLOW_HORIZONTAL
        gap = midPadding
        valign = ALIGN_BOTTOM
        children = [
          mkText(loc("zombieMod/useRadio"), headerTxtStyle)
          function() {
            let isInProgress = zombieCountDownTimer.get() > 0 || !objectiveActive
            let count = wavesCount - (curWaveId + (isInProgress ? 0 : 1))
            return {
              watch = zombieCountDownTimer
              children = mkTextWithBlink(count)
            }
          }
        ]
      }
      function() {
        if (zombieCountDownTimer.get() <= 0) {
          prevActivationAfterTime = -1
          return { watch = zombieCountDownTimer }
        }

        let hasBlink = prevActivationAfterTime > 0 && prevActivationAfterTime < nextActivationAfterTime
        prevActivationAfterTime = nextActivationAfterTime

        return {
          watch = zombieCountDownTimer
          size = FLEX_H
          children = [
            mkUnitHp(activationPeriod - zombieCountDownTimer.get(), activationPeriod,
            { color = titleTxtColor }, radioIcon,
            hasBlink ? mkNegativeBlink(nextActivationAfterTime) : null)
          ]
        }
      }
      mkTextArea(loc("zombieMod/useRadio/desc"))
    ]
  }.__update(blurStyle)
}


let mkArenasBlockUi = @(zombieCountDownTimer) function () {
  let watch = zombieArenas
  if (zombieArenas.get().len() <= 0)
    return { watch }

  let activeArena = zombieArenas.get().findvalue(@(v) v?.active ?? false)
  if (activeArena == null)
    return { watch }

  let { killsRequire = 0, kills = 0, bossRelHp = -1, nameLocId = "" } = activeArena

  let arenaContent = bossRelHp <= 0
    ? [
        {
          flow = FLOW_HORIZONTAL
          gap = midPadding
          valign = ALIGN_BOTTOM
          children = [
            mkText(loc("zombieMod/killDemons"), headerTxtStyle)
            mkTextWithBlink(killsRequire - kills)
          ]
        }
        function() {
          if (zombieCountDownTimer.get() <= 0)
            return { watch = zombieCountDownTimer }

          return {
            watch = zombieCountDownTimer
            children = mkText(loc("zombieMod/nextWaveTime", {
              count = secondsToStringLoc(zombieCountDownTimer.get())
            }))
          }
        }
        mkTextArea(loc("zombieMod/killDemons/desc"))
      ]
    : mkText(loc("zombie/killBoss"), headerTxtStyle)

  return {
    watch
    size = FLEX_H
    children = [
      {
        size = FLEX_H
        flow = FLOW_VERTICAL
        margin = const [sh(10),0,0,0]
        padding = bigPadding
        children = arenaContent
      }.__update(blurStyle)
      {
        size = 0
        pos = [sw(50) - fsh(2), fsh(5)]
        halign = ALIGN_CENTER
        children = bossRelHp <= 0 ? null
          : {
              padding = midPadding
              children = mkBossWidget({ active = true, hp = bossRelHp, maxHp = 1, nameLocId })
            }.__update(blurStyle)
      }
    ]
  }
}


function evacuationBlockUi() {
  let watch = evacuationEnabled
  if (!evacuationEnabled.get())
    return { watch }

  return {
    watch
    size = FLEX_H
    flow = FLOW_VERTICAL
    margin = const [sh(10),0,0,0]
    padding = bigPadding
    children = [
      function() {
        let timeLeft = evacuationTimeLeft.get()
        if (timeLeft <= 0)
          return { watch = evacuationTimeLeft }

        return {
          watch = evacuationTimeLeft
          flow = FLOW_HORIZONTAL
          gap = midPadding
          valign = ALIGN_BOTTOM
          children = [
            mkText(loc("zombieMod/evacuation"), headerTxtStyle)
            mkTextWithBlink(secondsToStringLoc(evacuationTimeLeft.get()))
          ]
        }
      }
      mkTextArea(loc("zombieMod/evacuation/desc"))
    ]
  }.__update(blurStyle)
}


let tokenIcon = {
  rendObj = ROBJ_IMAGE
  size = const [tokenIconSize, tokenIconSize]
  image = Picture(TOKEN_ICON.subst(tokenIconSize))
}

let tokensBlockUi = {
  size = FLEX_H
  flow = FLOW_VERTICAL
  margin = [smallPadding, 0]
  padding = bigPadding
  children = [
    @() {
      watch = selfresCount
      flow = FLOW_HORIZONTAL
      gap = midPadding
      valign = ALIGN_CENTER
      children = [
        mkText(loc("zombieMod/selfres"), headerTxtStyle)
        mkTextWithBlink(selfresCount.get())
      ]
    }
    function() {
      let watch = numTokens
      if (numTokens.get() <= 0)
        return { watch }

      return {
        watch
        size = FLEX_H
        flow = FLOW_HORIZONTAL
        gap = midPadding
        valign = ALIGN_CENTER
        children = [
          mkTextArea(loc("zombieMod/tokens"), { size = const [pw(75), SIZE_TO_CONTENT] })
          mkTextWithBlink(numTokens.get())
          tokenIcon
        ]
      }
    }
    function(){
      let watch = objectiveTokens
      if (objectiveTokens.get() <= 0)
        return { watch }

      return {
        watch
        size = FLEX_H
        flow = FLOW_HORIZONTAL
        gap = midPadding
        valign = ALIGN_CENTER
        children = [
          mkTextArea(loc("zombieMod/objectiveTokens"), { size = const [pw(75), SIZE_TO_CONTENT] })
          mkTextWithBlink(objectiveTokens.get())
          tokenIcon
        ]
      }
    }
  ]
}.__update(blurStyle)


function mkSessionEndTimerUi(zombieSessionEndTimer) {
  return function() {
    let watch = zombieSessionEndTimer
    return zombieSessionEndTimer.get() <= 0
      ? { watch }
      : {
          watch
          size = 0
          flow = FLOW_VERTICAL
          gap = bigPadding
          pos = const [sw(50) - fsh(2), fsh(15)]
          halign = ALIGN_CENTER
          children = [
            mkText(loc("zombieMod/sessionEndTimer"), fontBody)
            mkTextWithBlink(secondsToStringLoc(zombieSessionEndTimer.get()))
          ]
        }
  }
}


function mkGameModeBlock() {
  let zombieTimeStamp = Computed(function() {
    let activeRadio = zombieRadios.get().findvalue(@(v) v?.active ?? false)
    if (activeRadio != null)
      return activeRadio?.nextActivationAfterTime ?? -1

    let activeArena = zombieArenas.get().findvalue(@(v) v?.active ?? false)
    return activeArena?.nextWaveTime ?? -1
  })
  let zombieCountDownTimer = mkCountdownTimerPerSec(zombieTimeStamp)
  let zombieSessionEndTimer = mkCountdownTimerPerSec(sessionEndTime)

  return {
    size = const [infoBlockWidth, SIZE_TO_CONTENT]
    children = [
      {
        size = FLEX_H
        flow = FLOW_VERTICAL
        pos = const [0, fsh(6)]
        children = [
          mkElitesBlockUi()
          cratersBlockUi
          mkRadioBlockUi(zombieCountDownTimer)
          mkArenasBlockUi(zombieCountDownTimer)
          evacuationBlockUi
          tokensBlockUi
        ]
      }
      mkSessionEndTimerUi(zombieSessionEndTimer)
    ]
  }
}

console_register_command(@() isDebugNeeded.set(!isDebugNeeded.get()), "switchZombieDebug")
console_register_command(@() isInfoNeeded.set(!isInfoNeeded.get()), "switchZombieInfo")

return @() {
  watch = isDebugNeeded
  children = isDebugNeeded.get() ? gameModeDebugBlock : mkGameModeBlock()
}
