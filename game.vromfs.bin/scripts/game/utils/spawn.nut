import "%dngscripts/ecs.nut" as ecs


function createInventory(inventory) {
  let itemContainer = ecs.CompEidList()
  foreach (item in inventory) {
    let count = item?.count ?? 1
    for (local i = 0; i < count; i++) {
      itemContainer.append(ecs.EntityId(ecs.g_entity_mgr.createEntity(item.gametemplate, {})))
    }
  }
  return [ itemContainer, ecs.TYPE_EID_LIST ]
}

return {
  createInventory
}
