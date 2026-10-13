from "app" import get_circuit_conf
from "settings" import get_setting_by_blk_path


let circuitConf = get_circuit_conf()
let operatorTags = circuitConf?.externalOperatorTags.split(",").sort()
  ?? get_setting_by_blk_path("externalOperatorTags")?.split(",").sort()
  ?? []
let migrationUrl = circuitConf?.regionalMigrationUrl
  ?? get_setting_by_blk_path("regionalMigrationUrl")
  ?? "https://enlisted.net/ru/migration"
let migratedUrl = circuitConf?.postMigrationUrl
  ?? get_setting_by_blk_path("postMigrationUrl")
  ?? ""

let findAny = @(list, search) list.findvalue(@(tag) search.contains(tag)) != null

let isRegionalOperator = operatorTags.len() > 0
let getOperatorTag = @(index = 0) operatorTags?[index]

let hasGlobalMigrated = @(globalTags) findAny(globalTags, const ["extop_el"])
let hasGlobalAccount = @(regionalTags, globalTags) !findAny(globalTags, operatorTags)
  && findAny(regionalTags, const ["migrated_from_gj"])
  && findAny(globalTags, const ["player_el", "customer_el"])

return {
  migrationUrl
  migratedUrl
  isRegionalOperator
  getOperatorTag
  hasGlobalMigrated
  hasGlobalAccount
}