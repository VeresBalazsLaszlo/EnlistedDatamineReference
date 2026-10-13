from "%dngscripts/globalState.nut" import nestWatched

let editorActivness  = nestWatched("editorActivness", false)
let editorActivnessUpdate = @(v) editorActivness.set(v)
let uiInEditor = nestWatched("uiInEditor", false)
let uiInEditorUpdate = @(v) uiInEditor.set(v)


return {
  editorActivness, editorActivnessUpdate,
  uiInEditor, uiInEditorUpdate
}