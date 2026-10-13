import "utf8" as utf8
from "dagor.debug" import logerr
from "%ui/options/bigQuery.nut" import bqSendEvent
from "dagor.time" import get_time_msec
from "%ui/options/onlineSettings.nut" import settings, onlineSettingUpdated
from "%ui/ui_library.nut" import *
from "types" import Integer













































const SKIP_DELAY_DEFAULT = 3.0
const SKIP_DELAY_AFTER_NEXT_KEY = 2.0
const SEEN_ID = "seen/tutorial"

local tutorialConfig = null


let state = Watched({
  version = 0 
  step = 0
})


let seenTutorials = Computed(function() {
  if (!onlineSettingUpdated.get())
    return {}

  return settings.get()?[SEEN_ID] ?? {}
})

function markSeenTutorial(id) {
  if (id not in seenTutorials.get())
    settings.mutate(function(set) {
      let saved = clone (set?[SEEN_ID] ?? {})
      saved[id] <- true
      set[SEEN_ID] <- saved
    })
}

console_register_command(@() settings.mutate(@(s) s.$rawdelete(SEEN_ID)), "meta.resetSeenTutorials")


let tutorialConfigVersion = Computed(@() state.get().version)
let stepIdx = Computed(@() state.get().step)
let nextKeyAllowed = Watched(false)
let skipKeyAllowed = Watched(false)
local stepStartTime = 0
state.subscribe(function(_) { stepStartTime = get_time_msec() })

let sendCurStepBq = @(status) "id" not in tutorialConfig ? null
  : bqSendEvent("ui_tutorial", {
      id = tutorialConfig.id
      step = tutorialConfig?.steps[stepIdx.get()].id ?? stepIdx.get()
      status = status
    })

function onStepStatus(status) {
  sendCurStepBq(status)
  tutorialConfig?.onStepStatus(tutorialConfig?.steps[stepIdx.get()].id ?? stepIdx.get(), status)
}

function setTutorialConfig(config) {
  if (config != null && tutorialConfig != null) {
    logerr($"Try to start tutorial /*{config?.id}*/ while other tutorial in progress /*{tutorialConfig?.id}*/")
    return
  }
  onStepStatus("tutorial_finished")

  tutorialConfig = config
  state.set({
    version = state.get().version + 1
    step = 0
  })
  tutorialConfig?.steps[0].beforeStart() 

  onStepStatus("tutorial_started")
}

function finishTutorial() {
  markSeenTutorial(tutorialConfig.id)
  setTutorialConfig(null)
}

function goToStep(idxOrId) {
  if (tutorialConfig == null)
    return
  let { steps = [] } = tutorialConfig
  let idx = idxOrId instanceof Integer ? idxOrId
    : (steps.findindex(@(s) s?.id == idxOrId) ?? -1)
  steps?[stepIdx.get()].onFinish()

  if (idx in steps) { 
    steps?[idx].beforeStart()
    state.mutate(@(s) s.step <- idx)
    return
  }

  if (idx != idxOrId)
    logerr($"Try to move to not exist tutorial step /*{idxOrId}*/ in the tutorial /*{tutorialConfig?.id}*/. Finalize tutorial.")
  finishTutorial()
}

let nextStep = @() goToStep(stepIdx.get() + 1)

function skipStepImpl() {
  let step = tutorialConfig?.steps[stepIdx.get()]
  let onNextKey = step?.onNextKey ?? step?.objects[0].onClick
  if (!onNextKey?())
    nextStep()
}

function nextStepByDefaultHotkey() {
  onStepStatus("step_success")
  skipStepImpl()
}

function skipCurTutorial() {
  finishTutorial()
}


let calcNextDelayByText = @(text)
  clamp(0.03 * utf8(text).charCount(), 1.0, 5.0)

let allowNextKey = @() nextKeyAllowed.set(true)
let allowSkipKey = @() skipKeyAllowed.set(true)
function updateNextKeyTimer() {
  local { nextKeyDelay = null, skipKeyDelay = null, text = "" } = tutorialConfig?.steps[stepIdx.get()]
  gui_scene.clearTimer(allowNextKey)
  gui_scene.clearTimer(allowSkipKey)
  skipKeyAllowed.set(false)

  if (nextKeyDelay == null) {
    nextKeyAllowed.set(false)
    gui_scene.resetTimeout(skipKeyDelay ?? SKIP_DELAY_DEFAULT, allowSkipKey)
    return
  }

  if (nextKeyDelay < 0)
    nextKeyDelay = calcNextDelayByText(isObservable(text) ? text.get() : text)

  if (nextKeyDelay == 0) {
    nextKeyAllowed.set(true)
    gui_scene.resetTimeout(skipKeyDelay ?? SKIP_DELAY_DEFAULT, allowSkipKey)
  }
  else {
    nextKeyAllowed.set(false)
    gui_scene.resetTimeout(nextKeyDelay, allowNextKey)
    gui_scene.resetTimeout(skipKeyDelay ?? (nextKeyDelay + SKIP_DELAY_AFTER_NEXT_KEY), allowSkipKey)
  }
}
state.subscribe(@(_) updateNextKeyTimer())


console_register_command(finishTutorial, "tutorial.closeCurrentTutorial")

return {
  isTutorialActive = Computed(@() tutorialConfigVersion.get() > 0 && tutorialConfig != null)
  tutorialConfigVersion
  getTutorialConfig = @() tutorialConfig != null ? freeze(tutorialConfig) : null
  setTutorialConfig
  stepIdx
  nextKeyAllowed
  goToStep = function(idxOrId) {
    onStepStatus("step_success")
    goToStep(idxOrId)
  }
  nextStep = function() {
    onStepStatus("step_success")
    nextStep()
  }
  nextStepByDefaultHotkey
  finishTutorial
  skipCurTutorial
  seenTutorials
  getTimeAfterStepStart = @() 0.001 * (get_time_msec() - stepStartTime)
}
