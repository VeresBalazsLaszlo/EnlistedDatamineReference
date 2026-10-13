from "%enlSqGlob/appInfo.nut" import yup_version, exe_version
from "app" import get_circuit
from "vromfs" import get_updated_game_version, get_vromfs_dump_version
from "%ui/state/appState.nut" import isInBattleState
from "dagor.fs" import file_exists
from "%sqstd/frp.nut" import subscribeAndInit
from "%ui/ui_library.nut" import *
from "math" import max

let { Version } = require("%sqstd/version.nut")

const HQ_PACK_CHECK_FILE_PATH = "content.hq/hq_tex/res/grp_hdr.vromfs.bin"

let updatedGameVersion = Watched(0)
let mainVromfsVersion = Watched(0)

function updateVromsVersion(inBattle){
  if (inBattle)
    return

  
  
  
  let isMoonCircuit = ["moon","internal"].contains(get_circuit())
  updatedGameVersion.set(isMoonCircuit ? 0 : get_updated_game_version())

  mainVromfsVersion.set(get_vromfs_dump_version("content/enlisted/enlisted-game.vromfs.bin"))
}

subscribeAndInit(updateVromsVersion, isInBattleState)

let maxVersionInt = Computed(@() max(
  (updatedGameVersion.get() ?? 0),
  (mainVromfsVersion.get() ?? 0),
  Version(exe_version.get() ?? 0).toint(),
  Version(yup_version.get() ?? 0).toint()
))

let maxVersionStr = Computed(@() Version(maxVersionInt.get()).tostring() )

let isMinimalClient = @() !file_exists(HQ_PACK_CHECK_FILE_PATH)

return {
  maxVersionInt
  maxVersionStr
  isMinimalClient
}
