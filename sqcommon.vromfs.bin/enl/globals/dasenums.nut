

enum ContextCommand {  
  ECC_DISABLED = 0
  ECC_NONE = 1
  ECC_CANCEL = 2
  ECC_REVIVE = 3
  ECC_BRING_AMMO = 4
  ECC_DEFEND_POINT = 5
  ECC_ATTACK_TARGET = 6
  ECC_BUILD = 7
  ECC_PLANT_BOMB = 8
  ECC_DEFUSE_BOMB = 9
}
const ContextCommand_COUNT = 10

enum HitcamResult {  
  EMPTY = 0
  RICOCHET = 1
  NOT_PENETRATE = 2
  INEFFECTIVE = 3
  POSSIBLE_EFFECTIVE = 4
  EFFECTIVE = 5
}
const HitcamResult_COUNT = 6

enum HitResult {  
  HIT_RES_NONE = 0
  HIT_RES_NORMAL = 1
  HIT_RES_DOWNED = 2
  HIT_RES_KILLED = 3
}
const HitResult_COUNT = 4

enum MedicHealState {  
  MHS_NONE = 0
  MHS_NEED_HEAL = 1
  MHS_NEED_REVIVE = 2
}
const MedicHealState_COUNT = 3

enum SquadBehaviour {  
  ESB_AGGRESSIVE = 0
  ESB_PASSIVE = 1
}
const SquadBehaviour_COUNT = 2

enum SquadFormationSpread {  
  ESFN_CLOSEST = 0
  ESFN_STANDARD = 1
  ESFN_WIDE = 2
}
const SquadFormationSpread_COUNT = 3

enum SquadMateOrder {  
  ESMO_NO_ORDER = 0
  ESMO_BRING_AMMO = 1
  ESMO_HEAL = 2
  ESMO_ARTILLERY = 3
  ESMO_BUILD = 4
  ESMO_ATTACK_TARGET = 5
  ESMO_DEFEND_POINT = 6
  ESMO_USE_VEHICLE = 7
  ESMO_DEFUSE_BOMB = 8
  ESMO_PLANT_BOMB = 9
  ESMO_MORTAR_ATTACK = 10
}
const SquadMateOrder_COUNT = 11

enum SquadOrder {  
  ESO_FOLLOW_ME = 0
  ESO_DEFEND_POINT = 1
  ESO_USE_VEHICLE = 2
}
const SquadOrder_COUNT = 3

enum CanTerraformCheckResult {  
  Successful = 0
  OutOfHeightMap = 1
  DisallowedMaterials = 2
  NearByObjects = 3
  NearByBuildingPreview = 4
}
const CanTerraformCheckResult_COUNT = 5

return {
  ContextCommand
  ContextCommand_COUNT
  HitcamResult
  HitcamResult_COUNT
  HitResult
  HitResult_COUNT
  MedicHealState
  MedicHealState_COUNT
  SquadBehaviour
  SquadBehaviour_COUNT
  SquadFormationSpread
  SquadFormationSpread_COUNT
  SquadMateOrder
  SquadMateOrder_COUNT
  SquadOrder
  SquadOrder_COUNT
  CanTerraformCheckResult
  CanTerraformCheckResult_COUNT
}