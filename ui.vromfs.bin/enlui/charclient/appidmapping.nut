from "app" import get_app_id








let mappingOldAppIdToProjectId = {
  
  [1131]  = "enlisted_pc",
  [1132]  = "enlisted_xbox",
  [1178]  = "enlisted_psn",

  

  
  [-404] = ""
}


function known_old_appid_to_projectid(app_id) {
  let result = mappingOldAppIdToProjectId?[app_id]
  if (result == null)
    return { ok = false, value = $"project_id_from_unknown_app_id_{app_id}" }
  return { ok = true, value = result }
}


function construct_known_project_id(custom_app_id = null) {
  let app_id = custom_app_id || get_app_id()
  return known_old_appid_to_projectid(app_id).value
}


return {
  construct_known_project_id
}
