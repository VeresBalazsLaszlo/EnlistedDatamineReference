import "%dngscripts/ecs.nut" as ecs
from "ecs.computed" import mkEcsComputedEidMap
from "%daeditor/ec_to_watched.nut" import mkFrameIncrementObservable
from "dagor.fs" import scan_folder
from "%ui/ui_library.nut" import *

let { selectedNoPrefabs, selectedNoPrefabsSetKeyVal, selectedNoPrefabsDeleteKey } = mkFrameIncrementObservable({}, "selectedNoPrefabs")

const USER_PREFABS_FOLDER = "userPrefabs"
const PREFAB_EXT =".blk"

let isPrefabTool = Watched(false)

function getPrefabsInLibrary() {
  let files = scan_folder({root = USER_PREFABS_FOLDER, vromfs = false, realfs = true, recursive = false, files_suffix = PREFAB_EXT})
  return files.map(@(v) v.slice(USER_PREFABS_FOLDER.len()+1, -PREFAB_EXT.len()))
}

let prefabsLibrary = Watched(getPrefabsInLibrary())

let selectedPrefabRows = mkEcsComputedEidMap({
  comps = [["prefab__name", ecs.TYPE_STRING], ["prefab__id", ecs.TYPE_INT]]
  comps_rq = ["daeditor__selected"]
})

let selectedPrefabs = Computed(function() {
  let res = {}
  foreach (eid, row in selectedPrefabRows.get())
    res[eid] <- { name = row.prefab__name, id = row.prefab__id }
  return res
})

let selectedPrefab = Computed(function() {
  let rows = selectedPrefabRows.get()
  let eids = rows.keys()
  if (eids.len() != 1)
    return null
  let eid = eids[0]
  let row = rows[eid]
  return { name = row.prefab__name, id = row.prefab__id, eid }
})


let selectedPrefabObjectRows = mkEcsComputedEidMap({
  comps = [["prefab__parentId", ecs.TYPE_INT]]
  comps_rq = ["daeditor__selected"]
})

let selectedPrefabObjects = Computed(function() {
  let res = {}
  foreach (eid, _row in selectedPrefabObjectRows.get())
    res[eid] <- true
  return res
})

ecs.register_es("selected_not_prefab_objects_ui", {
  onInit = @(eid, _comp) selectedNoPrefabsSetKeyVal(eid, true)
  onDestroy = @(eid, _comp) selectedNoPrefabsDeleteKey(eid)
},
{
  comps_rq=["daeditor__selected"],
  comps_no=["prefab__id", "prefab__parentId"]
})

return {
  isPrefabTool
  selectedPrefabs
  selectedPrefabObjects
  selectedNoPrefabs
  selectedPrefab
  prefabsLibrary
  getPrefabsInLibrary
}
