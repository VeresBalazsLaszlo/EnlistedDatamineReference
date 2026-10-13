import "%enlSqGlob/userInfo.nut" as userInfo
from "%ui/charClient/appIdMapping.nut" import construct_known_project_id
from "dagor.debug" import debug
from "eventbus" import eventbus_subscribe
import "sep_client" as sep_client
































let utils        = require("%ui/charClient/charClientUtils.nut")



function CharClientEvent(settings) {
  let {
    name = null,
    sepServiceName = null,
    mode = "eventbus",
    isSingleHandler = false,
    client = null, 
    handlers = null, 
    executors = null, 
  } = settings
  let { event = $"charclient.{name}" } = settings
  let isSepEnabled = sep_client.isEnabled() && sepServiceName != null
  local doRequest = null
  local previousAuthToken = ""

  assert(typeof name == "string")
  assert(client != null)
  assert(typeof handlers == "table")
  assert(executors == null || typeof executors == "table")

  debug($"CharClientEvent: name: {name}; SEP enabled: {isSepEnabled}; sepServiceName: {sepServiceName}")


  function request(handler, params = {}, context = null) {
    let func = $"{name}.{handler} request"
    let paramsExt = clone params
    let headers = clone (paramsExt?.headers ?? {})
    paramsExt.headers <- headers

    local { token = null } = headers
    if (!token && "userid" not in headers)
      token =  userInfo.get()?.token
    if (token == null) {
      debug($"Absent token for {func}")
      return
    }

    headers.token <- token

    debug($"{func} {utils.shortValue(paramsExt)}{utils.shortValue(context)}")
    if (!isSingleHandler)
      assert(handler in handlers, @()$"{func}: Unknown handler '{handler}'")
    else
      assert(handlers.len() == 1, @() $"{func}: single handler is not defined")

    let pair = handler.split(":")  
    paramsExt.action <- pair[0]
    let contextExt = pair.len() < 2 ? context
      : (context ?? {}).__merge({ ["$extra"] = pair[1] })

    if ("projectid" not in headers)
      headers.projectid <- construct_known_project_id(headers?["appid"])
    headers.$rawdelete("appid")

    doRequest(paramsExt, contextExt)
  }


  function call(table, key, result, context, label, msg) {
    let callback = table?[key]
    assert(typeof callback == "function", @()$"{label} call({key}): type={typeof callback}")

    let nargs = callback.getfuncinfos().parameters.len() - 1
    assert(nargs == 1 || nargs == 2, @()$"{label} call({key}): nargs={nargs}")

    if (executors != null)
      callback.bindenv(executors)
    let output = (nargs == 1) ? callback(result) : callback(result, context)

    if (output == null)
      debug($"{label} {msg}")
    else
      debug($"{label} {msg}: {utils.shortKeyValue(output)}")
  }


  function process(result) {
    
    
    assert("$action" in result, @()$"{name} process: No '$action' in result")
    let action = result["$action"]
    let context = result?["$context"]
    let extra = context?["$extra"]
    let handler = isSingleHandler ? handlers.findindex(@(_) true)
      : extra == null ? action
      : $"{action}:{extra}"
    let label = $"{name}.{handler}"
    assert(handler in handlers, @()$"{label} process: No handler '{handler}'")

    
    let { response = null, success = true, id = null } = result

    if (!success || "error" in result) {
      if (!success && "error" in response) {
        result = response.__merge({ id }) 
      }
      else {
        let err = result?.error ?? response?.error ?? "unknown error"
        result = { success = false, error = err, id }
      }

      debug($"{label} error: {utils.shortKeyValue(result?.error)}")
    }

    let executeBefore = context?.executeBefore
    if (executeBefore != null) {
      call(executors, executeBefore, result, context, label, $"executeBefore({executeBefore})")
    }

    call(handlers, handler, result, context, label, "completed")

    let executeAfter = context?.executeAfter
    if (executeAfter != null) {
      call(executors, executeAfter, result, context, label, $"executeAfter({executeAfter})")
    }
  }


  function requestEventBus(params, context) {
    client.requestEventBus(params, event, context)
  }


  function requestLegacy(params, context) {
    client.request(params, function(result) {
      result["$action"] <- params.action
      if (context != null)
        result["$context"] <- context
      process(result)
    })
  }


  function generate_next_message_id() {
    return sep_client.generateMessageId()
  }


  function httpRequestEx(rpcParams, actionParams, context, token) {
    let headers = {token}
    if (rpcParams?.projectId != null)
      headers.projectid <- rpcParams?.projectId
    if (rpcParams?.profileId != null)
      headers.userid <- rpcParams?.profileId
    if (rpcParams?.transactId != null)
      headers.transactid <- rpcParams?.transactId

    let reqData = {
      method = rpcParams.action
      id = (rpcParams?.messageId ?? generate_next_message_id()).tostring()
      jsonrpc = "2.0"
    }
    if (actionParams != null)
      reqData.params <- actionParams

    rpcParams.headers <- headers
    rpcParams.data <- reqData

    request(rpcParams.action, rpcParams, context)
  }


  function sepRequestEx(rpcParams, actionParams, context, token) {
    if (previousAuthToken != token) {
      previousAuthToken = token
      sep_client.updateAuthToken(token)
    }

    rpcParams.service <- sepServiceName

    sep_client.rpcRequest(rpcParams, actionParams, event, context)
  }

  function requestEx(rpcParams = {}, actionParams = {}, context = null) {
    let rpcParamsExt = clone rpcParams
    let token = rpcParamsExt?.token ?? userInfo.get()?.token
    if ("projectId" not in rpcParamsExt && "appId" in rpcParamsExt)
      rpcParamsExt.projectId <- construct_known_project_id(rpcParamsExt.appId)

    if (isSepEnabled)
      sepRequestEx(rpcParamsExt, actionParams, context, token)
    else
      httpRequestEx(rpcParamsExt, actionParams, context, token)
  }


  function init() {
    debug($"CharClientEvent({name}): {mode}")
    if (mode == "eventbus") {
      doRequest = requestEventBus
      eventbus_subscribe(event, process)
    }
    else if (mode == "legacy") {
      doRequest = requestLegacy
    }
  }


  init()
  return {
    generate_next_message_id
    request
    requestEx
  }
}


return CharClientEvent
