from "%darg/ui_imports.nut" import *
from "dagor.workcycle" import defer
from "types" import Array

function mkMsgbox(id, defStyling = require("%ui/components/msgbox.style.nut")){
  let widgets = persist($"{id}_widgets", @() [])
  let msgboxGeneration = persist($"{id}_msgboxGeneration", @() Watched(0))
  let incGen = @() msgboxGeneration.modify(@(v) v+1)

  let hasMsgBoxes = Computed(@() msgboxGeneration.get() >= 0 && widgets.len() > 0)

  function getCurMsgbox(){
    if (widgets.len()==0)
      return null
    return widgets.top()
  }

  

  function addWidget(w) {
    widgets.append(w)
    defer(incGen)
  }

  function removeWidget(w, uid=null) {
    let idx = widgets.indexof(w) ?? (uid!=null ? widgets.findindex(@(v) v?.uid == uid) : null)
    if (idx == null)
      return
    widgets.remove(idx)
    incGen()
  }

  function removeAllMsgboxes() {
    widgets.clear()
    incGen()
  }

  function updateWidget(w, uid){
    let idx = widgets.findindex(@(wd) wd.uid == uid)
    if (idx == null)
      addWidget(w)
    else {
      widgets.remove(idx)
      addWidget(w)
    }
  }

  function removeMsgboxByUid(uid) {
    let idx = widgets.findindex(@(w) w.uid == uid)
    if (idx == null)
      return false
    widgets.remove(idx)
    incGen()
    return true
  }

  function isMsgboxInList(uid) {
    return widgets.findindex(@(w) w.uid == uid) != null
  }

  
  
  
  
  
  
  
  
  
  
  
  
  
  

  let skip = {skip=true}
  let skpdescr = {description = skip}
  let defaultButtons = [{text="OK" customStyle={hotkeys=[["^Esc | Enter", skpdescr]]}}]


  function show(params, styling=defStyling) {
    let self = {v = null}
    let uid = params?.uid ?? {}
    log($"[MSGBOX] show uid:'{uid}' text:'{params?.text}'")

    function doClose() {
      removeWidget(self.v, uid)
      if ("onClose" in params && params.onClose)
        params.onClose()

      log($"[MSGBOX] closed uid:'{uid}' text:'{params?.text}'")
    }

    function handleButton(button_action) {
      if (button_action) {
        if (button_action?.getfuncinfos?().parameters.len()==2) {
          
          button_action({doClose})
          return 
        }

        button_action()
      }

      doClose()
    }

    local btnsDesc = params?.buttons ?? defaultButtons
    if (!(isObservable(btnsDesc)))
      btnsDesc = Watched(btnsDesc)

    local defCancel = null
    local initialBtnIdx = null

    foreach (idx, bd in btnsDesc.get()) {
      if (bd?.isCurrent)
        initialBtnIdx = idx
      if (bd?.isCancel)
        defCancel = bd
    }

    let curBtnIdx = Watched(initialBtnIdx ?? 0)

    function moveBtnFocus(dir) {
      curBtnIdx.set((curBtnIdx.get() + dir + btnsDesc.get().len()) % btnsDesc.get().len())
    }

    function activateCurBtn() {
      log($"[MSGBOX] handling active button:'{btnsDesc.get()[curBtnIdx.get()]?.text}' uid:'{uid}' text:'{params?.text}'")
      handleButton(btnsDesc.get()[curBtnIdx.get()]?.action)
    }

    let buttonsBlockKey = {}

    function buttonsBlock() {
      return @() {
        watch = btnsDesc
        key = buttonsBlockKey
        size = SIZE_TO_CONTENT
        flow = FLOW_HORIZONTAL
        valign = ALIGN_CENTER
        gap = hdpx(40)
        margin = const [fsh(2),0]

        children = btnsDesc.get().map(function(desc, idx) {
          let conHover = desc?.onHover
          function onHover(on){
            if (!on)
              return
            curBtnIdx.set(idx)
            conHover?()
          }
          let onAttach = (initialBtnIdx != null && initialBtnIdx==idx
            && styling?.moveMouseCursor.get())
            ? @(elem) move_mouse_cursor(elem)
            : null
          local behavior = desc?.customStyle?.behavior ?? desc?.customStyle?.behavior
          behavior = behavior instanceof Array ? behavior : [behavior]
          behavior.append(Behaviors.Button)
          let customStyle = (desc?.customStyle ?? {}).__merge({
            onHover
            behavior
            onAttach
          })
          function onClick() {
            log($"[MSGBOX] clicked '{desc?.text}' button: text = '{params?.text}'")
            handleButton(desc?.action)
          }
          return styling.button(desc.__merge({customStyle = customStyle, key=desc}), onClick)
        })

        hotkeys = [
          [styling?.closeKeys ?? "Esc", {action= @() handleButton(params?.onCancel ?? defCancel?.action), description = styling?.closeTxt}],
          [styling?.rightKeys ?? "Right | Tab", {action = @() moveBtnFocus(1) description = skip}],
          [styling?.leftKeys ?? "Left", {action = @() moveBtnFocus(-1) description = skip}],
          [styling?.activateKeys ?? "Space | Enter", {action= activateCurBtn, description= skip}],
          [styling?.maskKeys ?? "", {action = @() null, description = skip}]
        ]
      }
    }

    let rootUpperDecor = styling?.rootUpperDecor
    let rootLowerDecor = styling?.rootLowerDecor

    let root = styling.Root.__merge({
      key = uid
      flow = FLOW_VERTICAL
      halign = ALIGN_CENTER
      children = [
        rootUpperDecor
        styling.messageText(params.__merge({ handleButton }))
        buttonsBlock()
        rootLowerDecor
      ]
    })

    self.v = styling.BgOverlay.__merge({
      uid
      stopMouse = true
      children = [styling.BgOverlay?.children, root]
    })

    updateWidget(self.v, uid)

    return self
  }
  let msgboxComponent = @(){watch=msgboxGeneration children = getCurMsgbox()}

  return {
    showMsgbox = show
    getCurMsgbox
    msgboxGeneration
    removeAllMsgboxes
    isMsgboxInList
    removeMsgboxByUid
    msgboxComponent
    msgboxStyling = defStyling
    hasMsgBoxes
  }
}
return mkMsgbox