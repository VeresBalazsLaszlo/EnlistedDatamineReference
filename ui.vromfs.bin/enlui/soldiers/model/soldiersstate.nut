from "%ui/soldiers/model/unseenWeaponry.nut" import soldiersUpgradeAlerts
from "%ui/soldiers/model/soldierPerks.nut" import notChosenPerkSoldiers
from "%ui/components/soldiersUiComps.nut" import mkAlertIcon, PERK_ALERT_SIGN, UPGRADE_ALERT_SIGN
from "%ui/ui_library.nut" import *

const DEF_KIND = "rifle"


let mkAlertInfo = @(soldierInfo, _sf, _isSelected) {
  flow = FLOW_HORIZONTAL
  hplace = ALIGN_RIGHT
  vplace = ALIGN_TOP
  children = [
    mkAlertIcon(UPGRADE_ALERT_SIGN, Computed(@()
      soldiersUpgradeAlerts.get()?[soldierInfo?.guid] ?? false
    ))
    mkAlertIcon(PERK_ALERT_SIGN, Computed(@() soldierInfo?.guid in notChosenPerkSoldiers.get()))
  ]
}


let curSoldierKind = Watched(DEF_KIND)


return {
  mkAlertInfo
  curSoldierKind
  DEF_KIND
}
