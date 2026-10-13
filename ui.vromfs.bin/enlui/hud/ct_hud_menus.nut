from "%ui/hud/state/interactive_state.nut" import hudIsInteractive
from "%ui/ui_library.nut" import *

let hudMenusContainer = {value = null}

let hudMenusGen = Watched(0)

function hudMenus(menus){
  hudMenusGen.modify(@(v)v+1)
  hudMenusContainer.value = menus
}
let getHudMenus = @() hudMenusContainer.value












function closeMenu_int(menu){
  if (menu?.show.get() == true)
    log($"HudMenus: Close {menu.id}")
  if ("close" in menu)
    menu.close()
  else
    menu.show.set(false)
}

function openMenu_int(menu, menusDescr){
  log($"HudMenus: Open {menu.id}")
  let requestedMenuGroup = menu?.group ?? 100
  let curOpenMenus = []
  foreach (other in menusDescr) {
    if (!other?.show.get() || other.id == menu.id)
      continue
    let foundGroup = (other?.group ?? 100)
    if (requestedMenuGroup > foundGroup)
      return
    curOpenMenus.append(other)
  }
  if (menu?.open != null)
    menu.open()
  else
    menu.show.set(true)
  curOpenMenus.each(@(v) closeMenu_int(v))
}
function closeMenu(id){
  let menusDescr = getHudMenus()
  let menu = menusDescr.findvalue(@(v) v.id == id)
  closeMenu_int(menu)
}

function openMenu(id){
  let menusDescr = getHudMenus()
  let menu = menusDescr.findvalue(@(v) v.id == id)
  openMenu_int(menu, menusDescr)
}

function switchMenu(id){
  let menusDescr = getHudMenus()
  let menu = menusDescr.findvalue(@(v) v.id == id)
  if (!menu?.show.get()){
    openMenu_int(menu, menusDescr)
  }
  else
    closeMenu_int(menu)
}

function mkMenuEventHandlers(menu) {
  let eventName = menu?.event
  let holdToToggleDurMsec = menu?.holdToToggleDurMsec() ?? 500
  if (!( isObservable(menu?.show)) && !("close" in menu && "open" in menu))
    return {}

  function endEvent(event){
    if ((event?.dur ?? 0) > holdToToggleDurMsec || event?.appActive==false)
      closeMenu_int(menu)
  }
  return {
    [eventName] = @(_event) switchMenu(menu.id),
    [$"{eventName}:end"] = endEvent
  }
}

function menusUi() {
  let watch = [hudMenusGen, hudIsInteractive]
  let children = []
  let eventHandlers = {}

  let menus_descr = getHudMenus() ?? []
  foreach (menu in menus_descr) {
    if (menu?.event != null) {
      eventHandlers.__update(mkMenuEventHandlers(menu))
    }
    if (isObservable(menu?.show)) {
      watch.append(menu.show)
      if (menu?.show?.get())
        children.append(menu?.menu)
    }
    else {
      children.append(menu?.menu)
    }
  }
  return {
    size = FLEX
    watch
    children
    eventHandlers
  }
}

return {
  hudMenus
  openMenu
  closeMenu
  menusUi
}
