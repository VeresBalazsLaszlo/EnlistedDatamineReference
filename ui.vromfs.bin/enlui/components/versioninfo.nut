from "%enlSqGlob/appInfo.nut" import isProductionCircuit, circuit, version, build_number
from "%ui/style/fontsStyle.nut" import fontSub
from "%ui/state/client_version.nut" import isMinimalClient
from "%ui/hud/menus/options/other_options.nut" import isMinimizeWarnings
from "%ui/ui_library.nut" import *

let versionInfo = Computed(function() {
  let buildNum = build_number.get() ?? ""
  let versionNum = version.get() ?? ""
  local ver = $"version: {versionNum}"
  if (isMinimalClient() && isMinimizeWarnings.get())
    ver = $"{ver} (Minimal client)"

  if (!isProductionCircuit.get())
    ver = $"build: {buildNum} {ver}@{circuit.get()}"

  return ver
})

let version_info = @() {
  text = versionInfo.get()
  rendObj = ROBJ_TEXT
  watch = versionInfo
  hplace = ALIGN_RIGHT
  vplace = ALIGN_BOTTOM
  pos = const [-hdpx(18), -hdpx(2)]
  opacity = 0.2
  zOrder = Layers.MsgBox
}.__update(fontSub)

return version_info
