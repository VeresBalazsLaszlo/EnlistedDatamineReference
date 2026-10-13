from "%ui/ui_library.nut" import *




























let immutable_types = ["string", "float", "integer"]



local LayerManager = class{
  name = null
  generation = null
  state = null
  constructor(params){
    assert (immutable_types.contains(type(params?.name)), @() "'name' param is required fo windowsManager of immutable type (string, float, integer), to allow reload script by persist data, type '{0}' for '{1}'".subst(type(params?.name), params?.name))
    this.name = params.name
    this.generation = Watched(0)
    this.state = []
  }
  function add(component, uid=null){
    if (uid == null)
      uid = component
    let curId = this.state.findindex(@(v) v.uid == uid)
    if (curId == null) {
      this.state.append({component, uid})
    }
    else
      this.state[curId] = {component, uid}
    this.generation.modify(@(v) v+1)
  }

  function remove(uid){
    let curId = this.state.findindex(@(v) v.uid == uid)
    if (curId != null) {
      this.state.remove(curId)
      this.generation.modify(@(v) v+1)
    }
  }

  function getComponents(){
    return this.state.map(@(v) v.component)
  }

  function clear(){
    this.state.clear()
    this.generation.modify(@(v) v+1)
  }

  function getByUid(uid){
    let idx = this.state.findindex(@(v) v.uid == uid)
    return idx == null ? null : this.state[idx]
  }

  function isUidInList(uid){
    return this.state.findindex(@(v) v.uid == uid) != null
  }
}

return LayerManager