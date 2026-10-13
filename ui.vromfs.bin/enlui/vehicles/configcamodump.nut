from "%ui/soldiers/model/all_items_templates.nut" import allItemTemplates
from "%enlSqGlob/vehDecorUtils.nut" import getVehSkins
from "%ui/vehicles/vehDecorState.nut" import unsuitableSkinsById
from "%ui/components/itemsInfo.nut" import trimUpgradeSuffix
from "io" import file
from "dagor.fs" import dir_exists
from "%ui/ui_library.nut" import *


const RENAME_FILE_NAME = "vehCamouflageConfig"
const RENAME_FILE_PATH = "../profileServer/config"
const SUBTYPES = ["tank", "truck", "bike", "jeep"]

function collectSkinsByTemplate() {
  let result = {}
  foreach (templates in allItemTemplates.get()) {
    foreach (id, template in templates) {
      let { gametemplate = null, itemsubtype = null } = template
      if (gametemplate == null || !SUBTYPES.contains(itemsubtype))
        continue

      let tpl = trimUpgradeSuffix(id)
      if (tpl in result)
        continue

      let skins = getVehSkins(gametemplate)
      if (skins.len() == 0)
        continue

      result[tpl] <- skins
        .map(@(v) v.id.tolower())
        .totable()
        .keys() 
        .sort()
    }
  }
  return result
}

function writeSkinsToFile() {
  let fileName = $"{RENAME_FILE_NAME}.das"
  let filePath = dir_exists(RENAME_FILE_PATH) ? $"{RENAME_FILE_PATH}/{fileName}" : fileName
  let output = file(filePath, "wt+")

  let skinsByTemplate = collectSkinsByTemplate()
  let orderedNames = skinsByTemplate.keys().sort()
  let disabledSkins = unsuitableSkinsById.get()

  output.writestring($"options gen2\n\nlet shared \{\n  vehCamouflageCfg <- \{")
  local commaOutside = false
  foreach (tpl in orderedNames) {
    output.writestring(commaOutside ? ",\n" : "\n")
    commaOutside = true
    output.writestring($"    \"{tpl}\" => [")
    local commaInside = false
    foreach (skin in skinsByTemplate[tpl]) {
      if (disabledSkins?[skin][tpl] ?? false) {
        log($"unsuitableSkins: skip {skin} for {tpl}")
        continue
      }

      output.writestring(commaInside ? ",\n" : "\n")
      commaInside = true
      output.writestring($"      \"{skin}\"")
    }
    output.writestring("\n    ]")
  }
  output.writestring("\n  }\n}\n")
  output.close()

  console_print($"Camouflage table is saved to {filePath}")
}

console_register_command(writeSkinsToFile, "vehicle.skins_to_profile")
