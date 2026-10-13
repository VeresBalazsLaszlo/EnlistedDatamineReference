import "%ui/faceGen.nut" as faceGen
import "%dngscripts/ecs.nut" as ecs
from "%ui/helpers/menu_poses_for_weapons.nut" import allIdleAnims
from "%ui/soldiers/model/all_items_templates.nut" import allItemTemplates
from "%ui/ui_library.nut" import *

let { genFacesOverrides } = require("%ui/faceGen/animTree_gen_faces.nut")
let faceGenBase = require("%ui/faceGen/gen_faces.nut")

const EXPORT_TO_FILE = "gen_faces.nut"
const FACE_ID_COUNT = 51

let soldierOverrides = mkWatched(persist, "soldierOverrides", {})
let faceGenOverrides = mkWatched(persist, "faceGenOverrides", {})

let DB = ecs.g_entity_mgr.getTemplateDB()

let animcharToHead = Computed(function() {
  let res = {}
  allItemTemplates.get().each(@(armyTmpl) armyTmpl
    .filter(@(tmpl) tmpl?.itemtype == "head")
    .map(@(tmpl) tmpl.gametemplate)
    .each(function(key) {
      let animChar = DB.getTemplateByName(key)?.getCompValNullable("animchar__res")
      if (animChar != null && animChar not in res)
        res[animChar] <- key
    }))
  return res
})

let allSoldierHeads = Computed(@() animcharToHead.get().keys().sort())

let update = @(guid, data) guid == null ? null
  : soldierOverrides.mutate(@(tbl) tbl[guid] <- (tbl?[guid] ?? {}).__update(data))

let remove = @(guid, key)
  soldierOverrides.mutate(@(tbl) tbl?[guid].$rawdelete(key))

let soldierReset = @(guid) guid in soldierOverrides.get()
  ? soldierOverrides.mutate(@(v) v.$rawdelete(guid))
  : null

function soldierResetAll() {
  soldierOverrides.set({})
  faceGenOverrides.set({})
}

let isSoldierDisarmed = @(guid, data) data?[guid].isDisarmed ?? false

let setSoldierDisarmed = @(guid, isDisarmed)
  isSoldierDisarmed(guid, soldierOverrides.get()) == isDisarmed ? null
    : isDisarmed ? update(guid, { isDisarmed = true })
    : remove(guid, "isDisarmed")

let isSoldierSlotsSwap = @(guid, data) data?[guid].isSlotsSwap ?? false

let setSoldierSlotsSwap = @(guid, isSlotsSwap)
  isSoldierSlotsSwap(guid, soldierOverrides.get()) == isSlotsSwap ? null
    : isSlotsSwap ? update(guid, { isSlotsSwap = true })
    : remove(guid, "isSlotsSwap")

let getSoldierIdle = @(guid, data) data?[guid].idleAnim

let setSoldierIdle = @(guid, idleAnim)
  getSoldierIdle(guid, soldierOverrides.get()) == idleAnim ? null
    : allIdleAnims.contains(idleAnim) ? update(guid, { idleAnim })
    : remove(guid, "idleAnim")

function switchSoldierIdle(guid, dir) {
  let curAnim = getSoldierIdle(guid, soldierOverrides.get())
  let idx = allIdleAnims.indexof(curAnim)
  if (idx == null)
    return setSoldierIdle(guid, allIdleAnims[0])

  let length = allIdleAnims.len()
  setSoldierIdle(guid, allIdleAnims[(idx + dir + length) % length])
}

let getSoldierHead = @(guid, data) data?[guid].headId

let setSoldierHead = @(guid, headId)
  getSoldierHead(guid, soldierOverrides.get()) == headId ? null
    : allSoldierHeads.get().contains(headId) ? update(guid, { headId })
    : remove(guid, "headId")

function switchSoldierHead(guid, dir) {
  let headId = getSoldierHead(guid, soldierOverrides.get())
  let idx = allSoldierHeads.get().indexof(headId)
  if (idx == null)
    return setSoldierHead(guid, allSoldierHeads.get()[0])

  let length = allSoldierHeads.get().len()
  setSoldierHead(guid, allSoldierHeads.get()[(idx + dir + length) % length])
}

let getSoldierFace = @(guid, data) data?[guid].faceId

function setSoldierFace(guid, faceId) {
  faceId = faceId.tointeger()
  if (getSoldierFace(guid, soldierOverrides.get()) == faceId)
    return
  if (0 <= faceId && faceId < FACE_ID_COUNT)
    update(guid, { faceId })
  else
    remove(guid, "faceId")
}

function switchSoldierFace(guid, dir) {
  let faceId = getSoldierFace(guid, soldierOverrides.get())
  setSoldierFace(guid, faceId == null ? 0 : (faceId + dir + FACE_ID_COUNT) % FACE_ID_COUNT)
}

let getSoldierFaceGen = @(animChar, faceId) faceGenOverrides.get()?[animChar][faceId?.tostring()]

function faceGenRandomize(animChar, fromId, toId = -1) {
  toId = max(toId, fromId)
  if (!animChar || fromId < 0 || toId >= FACE_ID_COUNT)
    return

  faceGenOverrides.mutate(function(tbl) {
    let data = tbl?[animChar] ?? {}
    let config = genFacesOverrides?[animChar]
    for (local idx = fromId; idx <= toId; ++idx)
      data[idx.tostring()] <- faceGen(config)
    tbl[animChar] <- data
  })
}

function faceGenSave() {
  let facesNew = faceGenOverrides.get().keys()
  let facesSaved = faceGenBase.keys()
  let facesUsed = allSoldierHeads.get()
  let facesAll = [].extend(facesNew, facesSaved, facesUsed)
    .filter(@(key, idx, arr) arr.indexof(key) == idx)
    .sort()
  let lines = ["return {"]
  foreach (faceId in facesAll) {
    let dataNew = faceGenOverrides.get()?[faceId]
    let dataSaved = faceGenBase?[faceId]
    if (!facesUsed.contains(faceId))
      lines.append("  // DEPRECATED")
    else if (facesNew.contains(faceId))
      lines.append($"  // updated: {", ".join(dataNew?.keys().sort())}")
    lines.append($"  {faceId} = \{")
    for (local idx = 0; idx < FACE_ID_COUNT; ++idx) {
      let data = dataNew?[idx.tostring()] ?? dataSaved?[idx.tostring()]
      lines.append($"    [\"{idx}\"] = \{")
      if (data == null)
        lines.append("      // FIXME")
      else
        data.keys().sort().each(@(key) lines.append($"      {key} = {data[key]}"))
      lines.append("    },")
    }
    lines.append("  }")
  }
  lines.append("}")

  const fileName = EXPORT_TO_FILE
  let io = require("io")
  let file = io.file(fileName, "wt+")
  file.writestring("\n".join(lines))
  file.close()
  log($"Soldier face properties are saved to: {fileName}")
  return fileName
}

return {
  soldierOverrides
  soldierReset
  soldierResetAll

  isSoldierDisarmed = @(guid) isSoldierDisarmed(guid, soldierOverrides.get())
  mkSoldierDisarmed = @(guid) Computed(@() isSoldierDisarmed(guid, soldierOverrides.get()))
  setSoldierDisarmed

  isSoldierSlotsSwap = @(guid) isSoldierSlotsSwap(guid, soldierOverrides.get())
  mkSoldierSlotsSwap = @(guid) Computed(@() isSoldierSlotsSwap(guid, soldierOverrides.get()))
  setSoldierSlotsSwap

  getSoldierIdle = @(guid) getSoldierIdle(guid, soldierOverrides.get())
  mkSoldierIdle = @(guid) Computed(@() getSoldierIdle(guid, soldierOverrides.get()))
  setSoldierIdle
  switchSoldierIdle

  allSoldierHeads
  getSoldierHeadTemplate = @(guid) animcharToHead.get()?[getSoldierHead(guid, soldierOverrides.get())]
  mkSoldierHead = @(guid) Computed(@() getSoldierHead(guid, soldierOverrides.get()))
  setSoldierHead
  switchSoldierHead

  FACE_ID_COUNT
  getSoldierFace = @(guid) getSoldierFace(guid, soldierOverrides.get())
  mkSoldierFace = @(guid) Computed(@() getSoldierFace(guid, soldierOverrides.get()))
  setSoldierFace
  switchSoldierFace

  faceGenOverrides
  getSoldierFaceGen
  faceGenRandomize
  faceGenAll = @(animChar) faceGenRandomize(animChar, 0, FACE_ID_COUNT - 1)
  faceGenSave
}