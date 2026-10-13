import "%dngscripts/ecs.nut" as ecs
from "dagor.debug" import logerr
from "%sqstd/math.nut" import PI, fabs
from "string" import format
from "%sqstd/string.nut" import toIntegerSafe, isStringFloat
from "dagor.math" import Point3, Point4, TMatrix
from "math" import clamp
from "%enlSqGlob/library_logs.nut" import *
from "types" import Bool, Float

const VERSION = 0



const VEH_AGE_BASE = 100
const VEH_AGE_MIN = 14
const VEH_AGE_MAX = 100
const VEH_SCALE_BASE = 100
const VEH_SCALE_MIN = 20
const VEH_SCALE_MAX = 180
const VEH_ROTATION_BASE = 0
const VEH_ROTATION_MIN = -180
const VEH_ROTATION_MAX = 180


function cutOffRightZeros(str) {
  let dotIdx = str.indexof(".")
  if (dotIdx == null)
    return str

  local idx = str.len()
  while (idx > dotIdx) {
    let last = str[idx - 1]
    if (last != 48 && last != 46)
      break
    idx--
  }

  return str.slice(0, idx)
}

let boolToString = @(v) !(v instanceof Bool) ? ""
  : v == true ? "1"
  : ""

let floatToString = @(v) !(v instanceof Float) ? ""
  : fabs(v) < 0.001 ? ""
  : cutOffRightZeros(format("%.3f", v))

let point3ToString = @(v) !(v instanceof Point3) ? ""
  : ",".concat(floatToString(v.x), floatToString(v.y), floatToString(v.z))

let point4ToString = @(v) !(v instanceof Point4) ? ""
  : ",".concat(floatToString(v.x), floatToString(v.y), floatToString(v.z), floatToString(v.w))


let stringToBool = @(str) str == "1" ? true : false

let stringToFloat = @(str) isStringFloat(str) ? str.tofloat() : 0.0

function stringToPoint3(str) {
  let strData = str.split(",")
  return Point3(stringToFloat(strData?[0] ?? "0"),
    stringToFloat(strData?[1] ?? "0"),
    stringToFloat(strData?[2] ?? "0"))
}

function stringToPoint4(str) {
  let strData = str.split(",")
  return Point4(stringToFloat(strData?[0] ?? "0"),
    stringToFloat(strData?[1] ?? "0"),
    stringToFloat(strData?[2] ?? "0"),
    stringToFloat(strData?[3] ?? "0"))
}

let matrixToString = @(v) !(v instanceof TMatrix) ? ""
  : "?".concat(point3ToString(v[0]), point3ToString(v[1]), point3ToString(v[2]), point3ToString(v[3]))

function stringToMatrix(str) {
  let strData = str.split("?")
  let tm = TMatrix()
  for(local i = 0; i < 4; ++i)
    tm.setcol(i, stringToPoint3(strData?[i] ?? ""))
  return tm
}

let decalConfig = freeze([
  { key = "twoSided", valType = "bool", encode = boolToString, decode = stringToBool }
  { key = "dProj0", valType = "Point4", encode = point4ToString, decode = stringToPoint4 }
  { key = "locPos0", valType = "Point3", encode = point3ToString, decode = stringToPoint3 }
  { key = "oppositeMirrored", valType = "bool", encode = boolToString, decode = stringToBool }
  { key = "scale", valType = "float", encode = floatToString, decode = stringToFloat }
  { key = "mirrored", valType = "bool", encode = boolToString, decode = stringToBool }
  { key = "locNorm0", valType = "Point3", encode = point3ToString, decode = stringToPoint3 }
  { key = "vProj0", valType = "Point4", encode = point4ToString, decode = stringToPoint4 }
  { key = "uProj0", valType = "Point4", encode = point4ToString, decode = stringToPoint4 }
  { key = "rotation", valType = "float", encode = floatToString, decode = stringToFloat }
  { key = "uProj1", valType = "Point4", encode = point4ToString, decode = stringToPoint4 }
  { key = "vProj1", valType = "Point4", encode = point4ToString, decode = stringToPoint4 }
  { key = "dProj1", valType = "Point4", encode = point4ToString, decode = stringToPoint4 }
  { key = "locPos1", valType = "Point3", encode = point3ToString, decode = stringToPoint3 }
  { key = "locNorm1", valType = "Point3", encode = point3ToString, decode = stringToPoint3 }
])

let decorConfig = freeze([
  { key = "relativeTm", valType = "TMatrix", encode = matrixToString, decode = stringToMatrix },
  { key = "nodeName", valType = "string", encode = @(v) v, decode = @(v) v },
])

let codecCfgByVer = {
  vehDecal = {
    [0] = decalConfig
  }
  vehDecorator = {
    [0] = decorConfig
  }
}

foreach(key, cfg in codecCfgByVer)
  assert(VERSION in cfg, $"No {key} string convertor with {VERSION} version")


let decalToString = @(decal, cType) "{0}:{1}"
  .subst(VERSION, ";".join(codecCfgByVer[cType][VERSION]
    .map(@(data) data.encode(decal?[data.key]) ?? "")
  ))

function stringToDecal(decalStr, cType, textureName = "", slot = -1) {
  let baseList = decalStr.split(":")
  if (baseList.len() != 2)
    return logerr($"Wrong decor save format")

  if (cType not in codecCfgByVer)
    return logerr($"No decor string convertor with /*{cType}*/ type")

  let ver = toIntegerSafe(baseList[0], -1, false)
  if (ver not in codecCfgByVer[cType])
    return logerr($"No decor string convertor with /*{ver}*/ version")

  let strData = (baseList?[1] ?? "").split(";")
  let decal = {}
  foreach (key, cfg in codecCfgByVer[cType][ver]) {
    let str = strData?[key] ?? ""
    decal[cfg.key] <- cfg.decode(str) ?? str
  }

  return decal.__update({ textureName, slot })
}

function decalToCompObject(decal) {
  let decalCompObject = ecs.CompObject()
  foreach (key, val in decal)
    decalCompObject[key] <- val

  return decalCompObject
}


function getTemplateByName(templateName) {
  if (templateName == null)
    return null

  let DB = ecs.g_entity_mgr.getTemplateDB()
  return DB.getTemplateByName(templateName)
}

function getBaseVehicleSkin(templateName) {
  if (templateName == null)
    return null

  let vehTemplate = getTemplateByName(templateName)
  return vehTemplate == null ? null
    : vehTemplate.getCompValNullable("animchar__objTexReplace")?.getAll()
}

function getVehSkins(templateName) {
  if (templateName == null)
    return []

  let vehTemplate = getTemplateByName(templateName)
  if (vehTemplate == null)
    return []

  let skinTemplate = getTemplateByName(vehTemplate.getCompValNullable("skin__template"))
  if (skinTemplate == null)
    return []

  let skinsList = skinTemplate.getCompValNullable("skin__objTexReplace")?.getAll()
  if (skinsList != null) {
    let baseTexture = getBaseVehicleSkin(templateName)?.values()?[0]
    let isUndefined = baseTexture == null
    return skinsList.filter(@(s)
      s?.objTexReplace.findvalue(@(replacement, basic)
        replacement == baseTexture || (isUndefined && basic == replacement)) == null)
  }

  let info = skinTemplate.getCompValNullable("skin__info")
  return info?.getAll() ?? []
}

let getSkinParam = @(str, minVal, maxVal, baseVal)
  clamp(toIntegerSafe(str, baseVal, false), minVal, maxVal)

function skinDetailsToParams(details) {
  let [ age = null, scale = null, rotation = null ] = details.split(",")
  return {
    age = getSkinParam(age, VEH_AGE_MIN, VEH_AGE_MAX, VEH_AGE_BASE)
    scale = getSkinParam(scale, VEH_SCALE_MIN, VEH_SCALE_MAX, VEH_SCALE_BASE)
    rotation = getSkinParam(rotation, VEH_ROTATION_MIN, VEH_ROTATION_MAX, VEH_ROTATION_BASE)
  }
}


let toRadians = @[pure](angle) angle * PI / 180

function skinDetailsToViewParams(details) {
  let [ age = null, scale = null, rotation = null ] = details.split(",")
  return {
    age = getSkinParam(age, VEH_AGE_MIN, VEH_AGE_MAX, VEH_AGE_BASE) / 100.0
    scale = getSkinParam(scale, VEH_SCALE_MIN, VEH_SCALE_MAX, VEH_SCALE_BASE) / 100.0
    rotation = toRadians(getSkinParam(rotation, VEH_ROTATION_MIN,
      VEH_ROTATION_MAX, VEH_ROTATION_BASE))
  }
}

let skinDataExcludes = {
  objTexReplace = {}
  objTexSet = {}
  id = {}
}

let getVehSkinById = @(gametemplate, id) getVehSkins(gametemplate).findvalue(@(s) s.id == id)

function readSkinFromTemplate(gametemplate, skin) {
  let res = {}
  if (skin == null)
    return res

  let { skinId = "", details = "", hasUnique = false } = skin
  res.details <- details
  if (skinId == "")
    return res

  let camouflageData = getVehSkinById(gametemplate, skinId)
  if (camouflageData != null) {
    camouflageData.filter(@(_, k) k not in skinDataExcludes).each(@(v, k) res[k] <- v)
    if ("objTexReplace" in camouflageData)
      res.animchar__objTexReplace <- camouflageData.objTexReplace
    if ("objTexSet" in camouflageData && !hasUnique)
      res.animchar__objTexSet <- camouflageData.objTexSet
  }

  if (hasUnique) {
    let objTexSet = ecs.g_entity_mgr.getTemplateDB()
      .getTemplateByName(gametemplate)?.getCompValNullable("animchar__objTexSet").getAll()
    if (objTexSet != null)
      res.animchar__objTexSet <- objTexSet
  }

  return res
}

function skinDataForIcon(skin) {
  let res = {}
  let {
    animchar__objTexReplace = null, animchar__objTexSet = null,
    attach_decorators__templates = null, details = ""
  } = skin

  if (animchar__objTexReplace != null)
    res.objTexReplace <- animchar__objTexReplace
  if (animchar__objTexSet != null)
    res.objTexSet <- animchar__objTexSet
  if (attach_decorators__templates != null)
    res.attach_decorators__templates <- attach_decorators__templates

  if (details != "") {
    let skinParams = skinDetailsToViewParams(details)
    res.vehicle_camo_condition <- skinParams.age
    res.vehicle_camo_scale <- skinParams.scale
    res.vehicle_camo_rotation <- skinParams.rotation
  }
  return res
}

return freeze({
  decalToString
  stringToDecal
  decalToCompObject
  skinDetailsToParams
  skinDetailsToViewParams
  getTemplateByName
  getBaseVehicleSkin
  getVehSkins
  getSkinParam
  getVehSkinById
  readSkinFromTemplate
  skinDataForIcon
  VEH_AGE_BASE
  VEH_AGE_MIN
  VEH_AGE_MAX
  VEH_SCALE_BASE
  VEH_SCALE_MIN
  VEH_SCALE_MAX
  VEH_ROTATION_BASE
  VEH_ROTATION_MIN
  VEH_ROTATION_MAX
})
