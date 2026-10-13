import "%darg/darg_library.nut" as darg_library
import "%enlSqGlob/library_logs.nut" as logs
import "daRg" as darg
from "%dngscripts/localizations.nut" import loc
from "console" import register_command, command
from "dagor.workcycle" import defer
from "%ui/state/safeArea.nut" import safeAreaAmount
from "%sqstd/frp.nut" import Watched, WatchedImmediate, Computed, FRP_INITIAL, make_all_observables_immutable, isObservable
from "math" import clamp, min, max

enum Layers {
  Default
  Upper
  ComboPopup
  MsgBox
  Blocker
  Tooltip
  Inspector
}

let export = {
  loc
  console_register_command = register_command
  console_command = command
  defer
}

let hdpx = @[pure](pixels) darg_library.hdpx(pixels) * safeAreaAmount.get()
let hdpxi = @[pure](pixels) hdpx(pixels).tointeger()
let fsh = @[pure](v) darg_library.fsh(v) * safeAreaAmount.get()

let enlistedLibrary = darg_library.__merge({
  hdpx,
  hdpxi,
  fsh,
})




















return freeze(export.__update(
  {Watched, WatchedImmediate, Computed, FRP_INITIAL, make_all_observables_immutable, min, max, clamp, Layers, isObservable},
  darg,
  logs,
  enlistedLibrary,
  require("%sqstd/functools.nut"),
  {DngBhv = require("dng.behaviors")}
))
