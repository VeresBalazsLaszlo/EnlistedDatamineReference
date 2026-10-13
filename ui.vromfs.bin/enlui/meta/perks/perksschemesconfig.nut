from "%ui/meta/configs.nut" import mkComputedConfigGet

let perkSchemes = mkComputedConfigGet("perkSchemes", {})
let soldierSchemes = mkComputedConfigGet("soldierSchemes", {})
let perkTrees = mkComputedConfigGet("perkTrees", {})
let perkTreesSpecial = mkComputedConfigGet("perkTreesSpecial", {})
let perkSlotsByTiers = mkComputedConfigGet("perkSlotsByTiers", [])

return {
  perkSchemes
  soldierSchemes
  perkTrees
  perkTreesSpecial
  perkSlotsByTiers
}
