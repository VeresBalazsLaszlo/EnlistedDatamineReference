require ecs


[es(track=itemContainer, on_event=(EventOnLootUse, EventUpdatedItemContainer), on_appear, tag=server)]
def calculate_heal_and_repair_items_count(evt : Event;
                                          itemContainer : EidList;
                                          var total_kits__selfHeal : int&;
                                          var total_kits__targetHeal : int&;
                                          var total_kits__targetRepair : int&;
                                          var total_kits__targetOnlyHeal : int&;
                                          var total_kits__selfRevive : int&;
                                          var total_kits__selfRessurrect : int&;
                                          var total_kits__targetRevive : int&)
  total_kits__selfHeal = 0
  total_kits__targetHeal = 0
  total_kits__targetRepair = 0
  total_kits__targetOnlyHeal = 0
  total_kits__selfRevive = 0
  total_kits__selfRessurrect = 0
  total_kits__targetRevive = 0
  for itemEid in itemContainer
    query(itemEid) <| $ [es] (item__healAmount : float const?;
                              item__reviveAmount : float const?;
                              item__repairAmount : int const?;
                              item__useTime : float const?;
                              item__useTimeToTarget : float const?;
                              item__useCount : int const?;
                              item__targetUseOnly : Tag const?;
                              item__canResurrect : Tag const?)
      let hasHeal = item__healAmount != null
      let hasRevive = item__reviveAmount != null
      let hasResurrect = item__canResurrect != null
      let hasTargetUseOnly = item__targetUseOnly != null
      let hasUseTime = item__useTime != null
      let hasUseTimeToTarget = item__useTimeToTarget != null

      let heal = hasHeal && !hasResurrect
      let revive = hasRevive && !hasResurrect
      let ressurrect = hasResurrect
      let targetOnly = hasTargetUseOnly && !hasResurrect
      let self = hasUseTime && !targetOnly
      let target = hasUseTimeToTarget && !hasResurrect

      let uses = item__useCount ?? 1

      total_kits__selfHeal += heal && self ? uses : 0
      total_kits__targetHeal += heal && target ? uses : 0
      total_kits__targetRepair += item__repairAmount != null ? *item__repairAmount : 0
      total_kits__targetOnlyHeal += heal && target && targetOnly ? uses : 0
      total_kits__selfRevive += revive && self ? uses : 0
      total_kits__selfRessurrect += ressurrect && self ? uses : 0
      total_kits__targetRevive += revive && target ? uses : 0
