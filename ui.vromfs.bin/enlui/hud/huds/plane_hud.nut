import "%dngscripts/ecs.nut" as ecs
from "ecs.computed" import mkEcsComputed
from "%ui/components/text.nut" import dtext
from "%sqstd/math.nut" import round_by_value
from "%ui/helpers/time.nut" import secondsToString
from "%ui/hud/state/plane_hud_state.nut" import showFuel
from "%ui/style/designConst.nut" import titleTxtColor
from "%ui/ui_library.nut" import *











let defCaption = @(obj) loc(obj.locId)

let defTransform = @(_obj, val) round_by_value(val, 1)

let transformPercentsFunc =  @(_obj, val) round_by_value(val*100, 1)



let transformTimeFunc = @(_obj, val) secondsToString(val)

let transformBoolFunc =@(obj, val) loc(obj.boolValues[val ? 1 : 0])

let transformEnumFunc = @(obj, val) loc(obj.enumValues[val])

let defStyle = {
  color = titleTxtColor
  fontFx = FFT_GLOW
  fontFxColor = 0xCC000000
  fontFxFactor = 64
  fontFxOffsY = hdpx(0.9)
}
let hText = calc_str_box(dtext("THROTTLE:   100%"))

function mkCaption(obj) {
  let captionFunc = obj?.captionFunc ?? defCaption
  return @() {
    children = [dtext(captionFunc(obj), defStyle), dtext(":",defStyle)]
    flow = FLOW_HORIZONTAL
  }
}

function mkValue(obj){
  let transformFunc = obj?.transformFunc ?? defTransform
  let watch = obj.watch
  let watches = obj.values().filter(@(v) isObservable(v))
  return @() {
    children = dtext(watch.get() != null ? transformFunc(obj, watch.get()).tostring() : "", defStyle)
    watch = watches
  }
}

function mkExistIndicator(obj){
  let watch = obj.watch
  let locId = obj.locId
  let watches = obj.values().filter(@(v) isObservable(v))
  return function() {
    return {
      children = watch.get() ? dtext(loc(locId), defStyle) : null
      size = watch.get()!=null ? hText : null
      watch = watches
    }
  }
}



let state = [
  
  {comp = "plane_view__tasKMHInt",           locId="plane_hud/Tas",  typ = ecs.TYPE_INT}
  
  {comp = "plane_view__altitudeInt",      locId="plane_hud/Alt",  typ = ecs.TYPE_INT}
  

  
  {comp = "plane_view__is_throttle_control_active", locId = "", typ = ecs.TYPE_BOOL, show = false }
  {comp = "plane_view__throttle",
    compShow = "plane_view__is_throttle_control_active",
    locId="plane_hud/Thr",  typ = ecs.TYPE_FLOAT, transformFunc = transformPercentsFunc }
  {comp = "plane_view__is_climb_control_active", locId = "", typ = ecs.TYPE_BOOL, show = false }
  {comp = "plane_view__climb",
    compShow = "plane_view__is_climb_control_active",
    locId="plane_hud/Clb",  typ = ecs.TYPE_FLOAT, transformFunc = transformPercentsFunc}
  {comp = "plane_view__has_gear_control", locId = "", typ = ecs.TYPE_BOOL, show = false }
  {comp = "plane_view__gear_position",
    compShow = "plane_view__has_gear_control",
    locId="plane_hud/Gear",  typ = ecs.TYPE_BOOL,
    boolValues = ["plane_hud/GearUp", "plane_hud/GearDown"], transformFunc = transformBoolFunc}
  {comp = "plane_view__has_flaps_control", locId = "", typ = ecs.TYPE_BOOL, show = false }
  {comp = "flaps_position",
    compShow = "plane_view__has_flaps_control",
    locId="plane_hud/Flaps", typ = ecs.TYPE_INT,
    enumValues = ["plane_hud/FlapsUp", "plane_hud/FlapsCombat", "plane_hud/FlapsTakeoff", "plane_hud/FlapsLanding"], transformFunc = transformEnumFunc}
  {comp = "plane_view__hasAirBrakes", locId = "", typ = ecs.TYPE_BOOL, show = false }
  {comp = "plane_view__isAirBrakesActive",
    compShow = "plane_view__hasAirBrakes",
    locId="plane_hud/AirBrakes", typ = ecs.TYPE_BOOL,
    boolValues = ["plane_hud/AirBrakesUp", "plane_hud/AirBrakesDown"], transformFunc = transformBoolFunc}



  
  {comp = "plane_view__fuel_time",  locId="plane_hud/Fuel", typ = ecs.TYPE_FLOAT, transformFunc = transformTimeFunc, watchShow=showFuel}





























]

let plane = mkEcsComputed({
  comps = state.map(@(obj) [obj.comp, obj.typ, null])
  comps_rq = ["airplane", "heroVehicle"]
  comps_no = ["deadEntity"]
  tags = "gameClient"
})



state.each(function(obj) {
  let { comp, compShow = null } = obj
  obj.watch <- Computed(@() plane.get()?[comp])
  if (compShow != null) 
    obj.watchShow <- Computed(@() plane.get()?[compShow])
  let watchShow = obj?.watchShow
  obj.isActiveWatch <- Computed(@() plane.get()?[comp] != null && (watchShow?.get() ?? true))
})


let enginesDamage = mkEcsComputed({
  comps = [
    ["plane_view_engine__isWaterLeaking", ecs.TYPE_BOOL_LIST],
    ["plane_view_engine__isWaterLow", ecs.TYPE_BOOL_LIST],
    ["plane_view_engine__isOilLeaking", ecs.TYPE_BOOL_LIST],
    ["plane_view_engine__isOilLow", ecs.TYPE_BOOL_LIST],
    ["plane_view_engine__isEngineDead", ecs.TYPE_BOOL_LIST],
    ["plane_view_engine__engineWarnLevel", ecs.TYPE_INT_LIST],
    ["plane_view_engine__waterWarnLevel", ecs.TYPE_INT_LIST],
    ["plane_view_engine__oilWarnLevel", ecs.TYPE_INT_LIST],
    ["plane_view_engine__waterTemp", ecs.TYPE_INT_LIST],
    ["plane_view_engine__oilTemp", ecs.TYPE_INT_LIST],
    ["plane_view_engine__headTemp", ecs.TYPE_INT_LIST]
  ]
  comps_rq = ["vehicleWithWatched"]
  comps_no = ["deadEntity"]
  tags = "ui"
})



local enginesState = array(4) 
  .map(@(_, i) {
    
    active = Computed(@() i < (enginesDamage.get()?.plane_view_engine__headTemp?.len() ?? 0))
    engineTemp = Computed(@() enginesDamage.get()?.plane_view_engine__headTemp?[i] ?? 0)
    headState = Computed(function() {
      let damage = enginesDamage.get()
      return {
        warn = damage?.plane_view_engine__engineWarnLevel?[i] ?? 0
        dead = damage?.plane_view_engine__isEngineDead?[i] ?? false
      }
    })
    waterTemp = Computed(@() enginesDamage.get()?.plane_view_engine__waterTemp?[i] ?? 0)
    waterState = Computed(function() {
      let damage = enginesDamage.get()
      return {
        leak = damage?.plane_view_engine__isWaterLeaking?[i] ?? false
        low = damage?.plane_view_engine__isWaterLow?[i] ?? false
        warn = damage?.plane_view_engine__waterWarnLevel?[i] ?? 0
      }
    })
    oilTemp = Computed(@() enginesDamage.get()?.plane_view_engine__oilTemp?[i] ?? 0)
    oilState = Computed(function() {
      let damage = enginesDamage.get()
      return {
        leak = damage?.plane_view_engine__isOilLeaking?[i] ?? false
        low = damage?.plane_view_engine__isOilLow?[i] ?? false
        warn = damage?.plane_view_engine__oilWarnLevel?[i] ?? 0
      }
    })
  })

let warnColors = [
  Color(255, 255, 255)
  Color(255, 180, 0)
  Color(255, 90,  0)
  Color(255, 0,   0)
]

let warnStyle = defStyle.__merge({color = Color(255, 90, 0)})
let warnColor = @(level)
  warnColors[clamp(level, 0, warnColors.len() - 1)]

function mkEngineValue(temperature, engineState) {
  return function() {
    let temperatureVal = round_by_value(temperature.get(), 1)
    let warn = engineState.get()?.dead ? loc("plane_hud/EngineDead")
      : engineState.get()?.low ? loc("plane_hud/WaterOilLow")
      : engineState.get()?.leak ? loc("plane_hud/WaterOilLeak")
      : ""
    return {
      children = (engineState.get()?.warn ?? 0) > 0 ? [
        dtext(loc("plane_hud/ValueCelsius", temperatureVal.tostring(), {val=temperatureVal}), defStyle.__merge({color = warnColor(engineState.get()?.warn ?? 0)}))
        dtext(warn, warnStyle)
      ] : []
      flow = FLOW_HORIZONTAL
      gap = hdpx(10)
      watch = [temperature, engineState]
    }
  }
}

function mkEngineCaption(text, engineState) {
  return @() {
    watch = [engineState]
  }.__update(
    (engineState.get()?.warn ?? 0) > 0
      ? {
          children = [dtext(text, defStyle), dtext(":",defStyle)]
          flow = FLOW_HORIZONTAL
        }
      : {}
  )
}

function addEngineCaptionValues(captions, values, engines, locId, stateTemp, stateWarn) {
  let hasManyEngines = engines.len() > 1
  engines.each(function(engine, i) {
    captions.append(mkEngineCaption(loc(locId, {i = hasManyEngines ? i + 1 : ""}), engine[stateWarn]))
    values.append(mkEngineValue(engine[stateTemp], engine[stateWarn]))
  })
}

let planeState = state.filter(@(obj) "watch" in obj).reduce(function(memo, obj) {memo[obj.comp] <- obj.watch; return memo;}, {})
return freeze({
  planeState
  mkExistIndicator 

  function planeHud(){
    let captions = []
    let values = []
    foreach (obj in state) {
      if (obj?.isActiveWatch.get() && obj?.show!=false ) {
        captions.append(obj?.mkCaption(obj) ?? mkCaption(obj))
        values.append(obj?.mkValue(obj) ?? mkValue(obj))
      }
    }
    let activeEngines = enginesState.filter(@(engine) engine.active.get())
    addEngineCaptionValues(captions, values, activeEngines, "plane_hud/EngineTemp", "engineTemp", "headState")
    addEngineCaptionValues(captions, values, activeEngines, "plane_hud/Water", "waterTemp", "waterState")
    addEngineCaptionValues(captions, values, activeEngines, "plane_hud/Oil", "oilTemp", "oilState")
    let watches = state.filter(@(obj) "isActiveWatch" in obj).map(@(obj) obj.isActiveWatch).extend(enginesState.map(@(engine) engine.active))
    return {
      flow = FLOW_HORIZONTAL
      gap = hdpx(5)
      children = [
        {children=captions, flow=FLOW_VERTICAL, gap = hdpx(3)}
        
        
        
        {size = 0 children = {children=values,   flow=FLOW_VERTICAL, gap = hdpx(3)}}
      ]
      watch = watches
    }
  }
})
