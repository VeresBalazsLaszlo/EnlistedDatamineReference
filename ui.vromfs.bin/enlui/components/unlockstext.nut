from "%ui/helpers/time.nut" import secondsToHoursLoc
from "%ui/ui_library.nut" import *



let locKeyByName = {
  
  
}

let requiredTime = @(progress) progress.__merge({
  current = secondsToHoursLoc(progress.current)
  required = secondsToHoursLoc(progress.required)
})

let customLocParams = {
  battle_time = requiredTime
}


function getProgressLoc(unlockDesc, progress) {
  local { required = null, current = null } = progress
  let { name, periodic = false } = unlockDesc
  let locKey = locKeyByName?[name] ?? name

  if (periodic && required != null && current != null) {
    let { stages, startStageLoop } = unlockDesc
    local { stage } = progress
    let loopIndex = startStageLoop - 1
    if (stage > loopIndex)
      stage = loopIndex + (stage - loopIndex) % (stages.len() - loopIndex)
    let interval = stages[stage].progress
    current = current + interval - required
    required = interval
  }

  let divider = unlockDesc?.meta.descProgressDiv.tointeger() ?? 0
  if (divider > 0 && required != null && current != null) {
    current = current / divider
    required = required / divider
  }

  progress = progress.__merge({ current, required })
  return locKey in customLocParams ? customLocParams[locKey](progress) : progress
}

function getDescription(unlockDesc, progress, locParams) {
  let progressLoc = getProgressLoc(unlockDesc, progress)
  local descLocId = $"unlock/{unlockDesc.name}/desc"
  if (progress.required == 1)
    descLocId = $"{descLocId}/single"

  let localization = loc(descLocId, progressLoc)
  if (localization != descLocId)
    return localization

  if (unlockDesc?.localization.nameLocId != null)
    return loc(unlockDesc.localization.nameLocId, locParams ?? unlockDesc?.locParams ?? {})

  return (unlockDesc?.localization?.name ?? "").len() > 0
    ? unlockDesc?.localization?.name
    : unlockDesc.name
}

return {
  getDescription
}
