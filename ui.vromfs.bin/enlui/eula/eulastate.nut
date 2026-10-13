from "dagor.system" import dgs_get_settings
from "settings" import set_setting_by_blk_path_and_save
from "app" import get_circuit_conf
from "dagor.localize" import processHypenationsCN, processHypenationsJP
from "dagor.fs" import read_text_from_file, file_exists
from "%sqstd/json.nut" import loadJson
from "%dngscripts/globalState.nut" import nestWatched
from "%ui/options/onlineSettings.nut" import settings
from "%ui/state/clientState.nut" import gameLanguage, isChineseLanguage, isJapaneseLanguage
from "%ui/login/regionalOperator.nut" import isRegionalOperator, getOperatorTag
from "%dngscripts/platform.nut" import is_sony
from "%ui/ui_library.nut" import *

const NO_VERSION = -1

let eulaLog = with_prefix("[EULA] ")
let acceptedVersion = nestWatched("acceptedEULAVersion", null)

let circuitConf = get_circuit_conf()
let eulaPath = circuitConf?.eulaPath
  ?? "eula/eula.json"

eulaLog($"path: {eulaPath}, language: {gameLanguage}")

local acceptedEULAKey = "acceptedEULA"
local beforeLoginEULAKey = "acceptedEulaVersionBeforeLogin"
if (isRegionalOperator) {
  acceptedEULAKey = $"{getOperatorTag()}_EULA"
  beforeLoginEULAKey = acceptedEULAKey
}

let isNoVersion = @(version) version == NO_VERSION || version == 0

let json_load = @(file)
  loadJson(file, { logger = eulaLog, load_text_file = read_text_from_file })

function loadConfig(fileName) {
  let config = file_exists(fileName) ? json_load(fileName) : null
  local curLang = gameLanguage.tolower()
  if (!(curLang in config))
    curLang = "english"
  return {
    version = config?[curLang].version ?? NO_VERSION
    filePath = config?[curLang].file
  }
}

local eulaConfig
local eulaDocument

function getEulaConfig() {
  if (!eulaConfig) {
    eulaConfig = loadConfig(eulaPath)
    eulaLog("config:", eulaConfig)
  }
  return eulaConfig
}

local postProcessEulaText = function(text) {
  if (isChineseLanguage)
    return processHypenationsCN(text)
  if (isJapaneseLanguage)
    return processHypenationsJP(text)
  return text
}

if (is_sony) {
  let { getRegion, region } = require("sony")
  postProcessEulaText = function(text) {
    local eulaTxt = text
    if (isChineseLanguage)
      eulaTxt = processHypenationsCN(eulaTxt)
    else if (isJapaneseLanguage)
      eulaTxt = processHypenationsJP(eulaTxt)
    let regionKey = getRegion() == region.SCEA ? "scea" : "scee"
    let regionText = loc($"sony/{regionKey}")
    return $"{eulaTxt}{regionText}"
  }
}

let getVersion = @() getEulaConfig()?.version ?? NO_VERSION

function getDocument() {
  if (eulaDocument)
    return eulaDocument

  let { filePath = null } = getEulaConfig()
  if (filePath == null)
    return null

  eulaDocument = read_text_from_file(filePath)
  eulaDocument = postProcessEulaText("\x09".join(eulaDocument.split("\xE2\x80\x8B")))
  return eulaDocument
}

let getAcceptedConfigVersion = @() acceptedVersion.get()
  ?? dgs_get_settings()?[beforeLoginEULAKey]
  ?? NO_VERSION

function setAcceptedConfigVersion() {
  let version = getVersion()
  if (isNoVersion(version))
    return

  acceptedVersion.set(version)
  set_setting_by_blk_path_and_save(beforeLoginEULAKey, version)
}

let getAcceptedOnlineVersion = @() acceptedVersion.get()
  ?? settings.get()?[acceptedEULAKey]
  ?? NO_VERSION

function setAcceptedOnlineVersion() {
  let version = getVersion()
  if (isNoVersion(version))
    return

  acceptedVersion.set(version)
  settings.mutate(@(config) config[acceptedEULAKey] <- version)
}

return {
  isNoVersion
  getVersion
  getDocument
  getAcceptedConfigVersion
  setAcceptedConfigVersion
  getAcceptedOnlineVersion
  setAcceptedOnlineVersion
}