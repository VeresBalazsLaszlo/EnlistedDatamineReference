from "%gdkLib/impl/privileges.nut" import retrieve_current_state, resolve_with_ui, Privilege, State

function try_resolve_privilege(privilege, callback) {
  retrieve_current_state(privilege, function(rcs_success, rcs_state) {
    if (rcs_success && rcs_state == State.ResolutionRequired) {
      resolve_with_ui(privilege, function(rwu_success, rwu_state) {
        callback?(rwu_success && rwu_state == State.Allowed)
      })
      return
    }
    callback?(rcs_success && rcs_state == State.Allowed)
  })
}


function try_resolve_multiplayer_privilege(callback) {
  try_resolve_privilege(Privilege.Multiplayer, callback)
}


function try_resolve_crossplay_privilege(callback) {
  try_resolve_privilege(Privilege.CrossPlay, callback)
}


return {
  try_resolve_multiplayer_privilege
  try_resolve_crossplay_privilege
}
