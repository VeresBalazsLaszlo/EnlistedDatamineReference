#default:forbid-root-table

import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/library_logs.nut" import *

require("%enlSqGlob/offline_mode.nut")

ecs.clear_vm_entity_systems()

require("%enlSqGlob/sqevents.nut")
let {DBGLEVEL} = require("dagor.system")
let {logerr} = require("dagor.debug")
let {scan_folder} = require("dagor.fs")
let {flatten} = require("%sqstd/underscore.nut")
let registerScriptProfiler = require("%sqstd/regScriptProfiler.nut")
require("%sqstd/regScriptDebugger.nut")(debugTableData)

let use_realfs = (DBGLEVEL > 0) ? true: false

let external_modules = ["%scripts/game"]
let scanInModule = @(module) scan_folder({root=$"{module}/es", vromfs = true, realfs = use_realfs, recursive = true, files_suffix=".nut"})
let files = flatten(external_modules.map(scanInModule))

registerScriptProfiler("game")

if (!ecs.has_tag("inside_tools")) {
  foreach (i in files) {
    try {
      print($"require: {i}\n")
      require(i)
    } catch (e) {
      logerr($"Module /*{i}*/ was not loaded - see log for details")
    }
  }
  require("utils/squad_spawn_bot.nut")
  require("%scripts/game/utils/update_local_player_name.nut")
  require("%scripts/game/report_logerr.nut")
} else {
  require("%scripts/game/es/on_gameapp_start.nut")
}

print("enlisted game scripts init finished\n")
