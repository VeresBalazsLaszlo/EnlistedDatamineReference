from "%ui/options/onlineSettings.nut" import settings
from "dagor.workcycle" import defer
from "%sqstd/frp.nut" import Computed

function mkOnlineSaveData(saveId, defValueFunc = @() null, validateFunc = @(v) v) {
  let watch = Computed(@() settings.get()?[saveId] ?? defValueFunc?())
  function setValue(value) {
    let v = validateFunc(value ?? defValueFunc())
    defer(@() settings.mutate(@(val) val[saveId] <- v))
  }
  return {
    watch
    setValue
  }
}

return {
  mkOnlineSaveData
}