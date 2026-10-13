require ecs
require ecs.safe
require strings
require vehicle
require math.base
require DagorMath
require DngUI
require DagorShaders
require DngCamera
require DagorDataBlock
require game.events_game
require DagorStdGuiRender
require gameLibs.render_events.render_events

let
  DEFAULT_SIGHT_COLOR = E3DCOLOR(0xFF000000)
  THOUSANDTH_MULT = 6283f

def private fov_to_deg(fov : float)
  return rad_to_deg(2.f * atan(safediv(1.f, fov)))

[es(tag=gameClient, REQUIRE=input__enabled, no_order)]
def udpate_cockpit_sight_cached_params(info : UpdateStageInfoAct;
                                       var cockpit__cameraDirCached : float3&;
                                       var turret_current_visual_shoot_tm_cached : float3x4&;
                                       cockpit__cameraDir : float3;
                                       turret_current_visual_shoot_tm : float3x4)
  cockpit__cameraDirCached = cockpit__cameraDir
  turret_current_visual_shoot_tm_cached = turret_current_visual_shoot_tm

def private calc_sight_position(cam_pos : float3; use_gun_dir : bool)
  var vehicleSightPos : float3
  find_query() <| $ [es(REQUIRE=vehicleWithWatched)] (cockpit__cameraDirCached : float3;
                                                      turret_current_visual_shoot_tm_cached : float3x4;
                                                      turretAimPosCached : float3)
    let dist = length(cam_pos - turretAimPosCached)
    if !use_gun_dir
      vehicleSightPos = cam_pos + cockpit__cameraDirCached * dist
      return true
    vehicleSightPos = turret_current_visual_shoot_tm_cached[3] + turret_current_visual_shoot_tm_cached[0] * dist
    return true

  return vehicleSightPos

def private draw_circle(center : float2; size : float2; segment : float2; line_width : float)
  let halfW = line_width * 0.5f
  var radius = size * 0.5
  radius = float2(abs(radius.x), abs(radius.y))
  let count = int(cvt(max(radius.x, radius.y) + halfW, 4f, 100f, 10f, 128f))
  let angleSteep = safediv(TWOPI, float(count))
  var angle = deg_to_rad(segment.x)
  var prevPtIn, prevPtOut = float2()

  let r = abs(radius.x)
  let rIn = r - halfW
  let rOut = r + halfW

  let tc0 = float2(0, 0)
  let tc1 = float2(0, 1)
  let tc2 = float2(1, 1)
  let tc3 = float2(1, 0)
  var draw = true
  for i in range(count + 1)
    if rad_to_deg(angle) > segment.y
      draw = false
      angle = deg_to_rad(segment.y)

    var s, c : float
    sincos(angle, s, c)

    let ptIn = center + float2(s, c) * rIn
    let ptOut = center + float2(s, c) * rOut
    if i > 0
      StdGuiRender_render_quad(prevPtIn, ptIn, ptOut, prevPtOut, tc0, tc1, tc2, tc3)

    prevPtIn = ptIn
    prevPtOut = ptOut
    angle += angleSteep

    if !draw
      break

def private draw_sight(eid : EntityId; persp_wk : float; persp_hk : float; opacity : float)
  query(eid) <| $ [es] (vehicle_sight__drawLines : Point4List;
                        vehicle_sight__drawLinesThousandth : BoolList;
                        vehicle_sight__drawText : StringList;
                        vehicle_sight__drawTextSize : FloatList;
                        vehicle_sight__drawTextPos : Point2List;
                        vehicle_sight__drawQuadTopLeft : Point2List;
                        vehicle_sight__drawQuadTopRight : Point2List;
                        vehicle_sight__drawQuadBottomLeft : Point2List;
                        vehicle_sight__drawQuadBottomRight : Point2List;
                        vehicle_sight__drawQuadThousandth : BoolList;
                        vehicle_sight__drawCircleSegment : Point2List;
                        vehicle_sight__drawCirclePos : Point2List;
                        vehicle_sight__drawCircleDiameter : FloatList;
                        vehicle_sight__drawCircleSize : FloatList;
                        vehicle_sight__drawCircleThousandth : BoolList;
                        vehicle_sight__bubbleDiameter : float = 0f;
                        vehicle_sight__bubbleScale : float = 0.15f;
                        vehicle_sight__useGunDir : bool = true;
                        vehicle_sight__fontSizeMult : float = 1.3f;
                        vehicle_sight__lineSizeMult : float = 1f;
                        vehicle_sight__color = DEFAULT_SIGHT_COLOR)
    find_query() <| $ [es(REQUIRE_NOT=free_cam)] (camera__active : bool;
                                                  transform aka cam_transform : float3x4;
                                                  fov : float;
                                                  fovLimits : float2;
                                                  isTpsView : bool = false)
      if !camera__active || isTpsView
        return false

      var color4 = uint4(vehicle_sight__color)
      color4[3] = uint(opacity * float(0xFF))
      let color = E3DCOLOR(color4)
      StdGuiRender_set_color(color)

      var uiViewTm : float3x4
      get_ui_view_tm(uiViewTm)

      let screenSize = StdGuiRender_screen_size()
      let halfScreen = screenSize * 0.5
      let sp = uiViewTm * calc_sight_position(cam_transform[3], vehicle_sight__useGunDir)
      let startPos = float2(safediv(sp.x, sp.z) * persp_wk * halfScreen.x, safediv(-sp.y, sp.z) * persp_hk * halfScreen.y) + halfScreen

      let fovInThousandth = (fov_to_deg(persp_wk) / 360.0f) * THOUSANDTH_MULT
      let oneThousandthSize = safediv(screenSize.x, fovInThousandth) * 2f

      let sizeMult = safediv(fovLimits.x, fov) * vehicle_sight__fontSizeMult
      let lineWidth = max(sizeMult, 1.35f) * 0.5f * vehicle_sight__lineSizeMult
      StdGuiRender_set_font(0, 1, 0)

      let prevBlendMode = StdGuiRender_get_alpha_blend()
      StdGuiRender_set_alpha_blend(BlendMode.PREMULTIPLIED)
      let line_indent = float2(0, 0)
      for drawLine, useThousandth in vehicle_sight__drawLines, vehicle_sight__drawLinesThousandth
        let dimMult = useThousandth ? oneThousandthSize : screenSize.y * sizeMult
        let from = startPos + dimMult * float2(drawLine[0], drawLine[1])
        let to = startPos + dimMult * float2(drawLine[2], drawLine[3])
        // Bug: for some reason if many line is draw by AA render part of UI is disappear
        StdGuiRender_render_line_aa(from, to, /*is_closed*/false, lineWidth, line_indent, color)
      StdGuiRender_set_alpha_blend(prevBlendMode)

      for text, textPos, size in vehicle_sight__drawText, vehicle_sight__drawTextPos, vehicle_sight__drawTextSize
        let dimMult = screenSize.y * sizeMult
        let pos = startPos + dimMult * textPos
        StdGuiRender_goto_xy(pos.x, pos.y)
        StdGuiRender_draw_str_scaled(size * 1.5f, string(text), length(text))

      let tc0 = float2(0, 0)
      let tc1 = float2(0, 1)
      let tc2 = float2(1, 1)
      let tc3 = float2(1, 0)
      assume quadTopLeft = vehicle_sight__drawQuadTopLeft
      assume quadTopRight = vehicle_sight__drawQuadTopRight
      assume quadBottomLeft = vehicle_sight__drawQuadBottomLeft
      assume quadBottomRight = vehicle_sight__drawQuadBottomRight
      assume quadThousandth = vehicle_sight__drawQuadThousandth
      for tl, tr, bl, br, useThousandth in quadTopLeft, quadTopRight, quadBottomLeft, quadBottomRight, quadThousandth
        let dimMult = useThousandth ? oneThousandthSize : screenSize.y * sizeMult

        let p1 = startPos + bl * dimMult
        let p2 = startPos + tl * dimMult
        let p3 = startPos + tr * dimMult
        let p4 = startPos + br * dimMult
        StdGuiRender_render_quad(p1, p2, p3, p4, tc0, tc1, tc2, tc3)

      assume circleSegment = vehicle_sight__drawCircleSegment
      assume circlePos = vehicle_sight__drawCirclePos
      assume circleDiameter = vehicle_sight__drawCircleDiameter
      assume circleSize = vehicle_sight__drawCircleSize
      assume circleThousandth = vehicle_sight__drawCircleThousandth
      for segment, pos, diameter, size, useThousandth in circleSegment, circlePos, circleDiameter, circleSize, circleThousandth
        let dimMult = useThousandth ? oneThousandthSize : screenSize.y * sizeMult
        draw_circle(startPos + dimMult * pos, float2(diameter, diameter) * dimMult, segment, size * sizeMult)

      if vehicle_sight__bubbleDiameter > 0f
        var rollAngle = 0f
        var pitchDeg = 0f
        find_query() <| $ [es(REQUIRE=vehicleWithWatched)] (transform : float3x4)
          rollAngle = -atan2(transform[2].y, transform[1].y)
          pitchDeg = rad_to_deg(asin(clamp(transform[0].y, -1f, 1f)))
          return true

        let dm = screenSize.y * sizeMult
        let degToPx = vehicle_sight__bubbleScale * dm
        let tickSpacing = 10f
        let numTicks = 5
        let lx = -0.19 * dm
        let rx = 0.19 * dm
        let tickLen = 0.015 * dm
        let textScale = 0.5 * sizeMult

        // Fixed vertical lines - left and right, rotated by roll
        let cosR = cos(rollAngle)
        let sinR = sin(rollAngle)
        let totalH = float(numTicks - 1) * tickSpacing * degToPx

        // Left vertical line
        let lvT = startPos + float2(lx * cosR + (totalH * 0.5) * sinR, lx * sinR - (totalH * 0.5) * cosR)
        let lvB = startPos + float2(lx * cosR - (totalH * 0.5) * sinR, lx * sinR + (totalH * 0.5) * cosR)
        StdGuiRender_render_line_aa(lvT, lvB, false, lineWidth, line_indent, color)

        // Right vertical line
        let rvT = startPos + float2(rx * cosR + (totalH * 0.5) * sinR, rx * sinR - (totalH * 0.5) * cosR)
        let rvB = startPos + float2(rx * cosR - (totalH * 0.5) * sinR, rx * sinR + (totalH * 0.5) * cosR)
        StdGuiRender_render_line_aa(rvT, rvB, false, lineWidth, line_indent, color)

        // Tick marks with pitch labels - scroll by pitch
        let baseDeg = floor(pitchDeg / tickSpacing) * tickSpacing
        for i in range(-numTicks, numTicks + 1)
          let deg = baseDeg + float(i) * tickSpacing
          let offsetY = (deg - pitchDeg) * degToPx
          if abs(offsetY) > totalH * 0.5 + 1f
            continue

          // Left tick - directed left (outward)
          let ltFrom = startPos + float2(lx * cosR + offsetY * sinR, lx * sinR - offsetY * cosR)
          let ltTo = startPos + float2((lx - tickLen) * cosR + offsetY * sinR, (lx - tickLen) * sinR - offsetY * cosR)
          StdGuiRender_render_line_aa(ltFrom, ltTo, false, lineWidth, line_indent, color)

          // Right tick - directed right (outward)
          let rtFrom = startPos + float2(rx * cosR + offsetY * sinR, rx * sinR - offsetY * cosR)
          let rtTo = startPos + float2((rx + tickLen) * cosR + offsetY * sinR, (rx + tickLen) * sinR - offsetY * cosR)
          StdGuiRender_render_line_aa(rtFrom, rtTo, false, lineWidth, line_indent, color)

          // Pitch text - left side
          let ltextX = lx - tickLen - 0.025 * dm
          let ltextPos = startPos + float2(ltextX * cosR + offsetY * sinR, ltextX * sinR - offsetY * cosR)
          StdGuiRender_goto_xy(ltextPos.x, ltextPos.y - 4f)
          let pitchStr = "{int(deg)}"
          StdGuiRender_draw_str_scaled(textScale, pitchStr, length(pitchStr))

          // Pitch text - right side
          let rtextX = rx + tickLen + 0.005 * dm
          let rtextPos = startPos + float2(rtextX * cosR + offsetY * sinR, rtextX * sinR - offsetY * cosR)
          StdGuiRender_goto_xy(rtextPos.x, rtextPos.y - 4f)
          StdGuiRender_draw_str_scaled(textScale, pitchStr, length(pitchStr))

      return true

[es(tag=ui)]
def vehicle_sight_draw_es(evt : RenderEventUI;
                          eid : EntityId;
                          cockpit__currentSlit : int;
                          cockpit__cameraTime : float;
                          cockpit__forwardOffsetTime : float;
                          cockpit__slitEids : EidList const?;
                          vehicle_sight__renderInSlit : int = 0)
  if cockpit__cameraTime < 1. && cockpit__cameraTime > 0.
    return
  let opacity = cockpit__forwardOffsetTime
  if cockpit__slitEids != null
    let slitEid = (*cockpit__slitEids)?[cockpit__currentSlit] ?? INVALID_ENTITY_ID
    if !!slitEid
      draw_sight(slitEid, evt.persp.wk, evt.persp.hk, opacity)
      return
  if cockpit__currentSlit == vehicle_sight__renderInSlit
    draw_sight(eid, evt.persp.wk, evt.persp.hk, opacity)

[es(tag=ui, on_appear, before=vehicle_sight_draw_es)]
def vehicle_sight_init_es(evt : Event;
                          vehicle_sight__blk : string;
                          var vehicle_sight__fontSizeMult : float&;
                          var vehicle_sight__lineSizeMult : float&;
                          var vehicle_sight__drawLines : Point4List;
                          var vehicle_sight__drawLinesThousandth : BoolList;
                          var vehicle_sight__drawText : StringList&;
                          var vehicle_sight__drawTextSize : FloatList&;
                          var vehicle_sight__drawTextPos : Point2List&;
                          var vehicle_sight__drawQuadTopLeft : Point2List;
                          var vehicle_sight__drawQuadTopRight : Point2List;
                          var vehicle_sight__drawQuadBottomLeft : Point2List;
                          var vehicle_sight__drawQuadBottomRight : Point2List;
                          var vehicle_sight__drawQuadThousandth : BoolList;
                          var vehicle_sight__drawCircleSegment : Point2List&;
                          var vehicle_sight__drawCirclePos : Point2List&;
                          var vehicle_sight__drawCircleDiameter : FloatList&;
                          var vehicle_sight__drawCircleSize : FloatList&;
                          var vehicle_sight__drawCircleThousandth : BoolList&)
  vehicle_sight__drawLines |> clear()
  vehicle_sight__drawLinesThousandth |> clear()
  vehicle_sight__drawText |> clear()
  vehicle_sight__drawTextPos |> clear()
  vehicle_sight__drawTextSize |> clear()
  vehicle_sight__drawQuadTopLeft |> clear()
  vehicle_sight__drawQuadTopRight |> clear()
  vehicle_sight__drawQuadBottomLeft |> clear()
  vehicle_sight__drawQuadBottomRight |> clear()
  vehicle_sight__drawQuadThousandth |> clear()
  vehicle_sight__drawCircleSegment |> clear()
  vehicle_sight__drawCirclePos |> clear()
  vehicle_sight__drawCircleDiameter |> clear()
  vehicle_sight__drawCircleSize |> clear()

  using() <| $(var blk : DataBlock)
    datablock_load(blk, vehicle_sight__blk)
    vehicle_sight__fontSizeMult = blk |> datablock_getReal("fontSizeMult", vehicle_sight__fontSizeMult)
    vehicle_sight__lineSizeMult = blk |> datablock_getReal("lineSizeMult", vehicle_sight__lineSizeMult)
    blk |> datablock_get_block("drawLines") <| $(drawLines)
      for i in urange(drawLines.blockCount)
        datablock_get_block(drawLines, i) <| $(drawLine)
          vehicle_sight__drawLines |> push(datablock_getPoint4(drawLine, "line", float4()))
          vehicle_sight__drawLinesThousandth |> push(datablock_getBool(drawLine, "thousandth", false))

    blk |> datablock_get_block("drawTexts") <| $(drawTexts)
      for i in urange(drawTexts.blockCount)
        datablock_get_block(drawTexts, i) <| $(drawText)
          vehicle_sight__drawText |> push(datablock_getStr(drawText, "text", ""))
          vehicle_sight__drawTextPos |> push(datablock_getPoint2(drawText, "pos", float2(0, 0)))
          vehicle_sight__drawTextSize |> push(datablock_getReal(drawText, "size", float(1)))

    blk |> datablock_get_block("drawQuads") <| $(drawQuads)
      for i in urange(drawQuads.blockCount)
        datablock_get_block(drawQuads, i) <| $(drawQuad)
          vehicle_sight__drawQuadTopLeft |> push(datablock_getPoint2(drawQuad, "tl", float2(0, 0)))
          vehicle_sight__drawQuadTopRight |> push(datablock_getPoint2(drawQuad, "tr", float2(0, 0)))
          vehicle_sight__drawQuadBottomLeft |> push(datablock_getPoint2(drawQuad, "bl", float2(0, 0)))
          vehicle_sight__drawQuadBottomRight |> push(datablock_getPoint2(drawQuad, "br", float2(0, 0)))
          vehicle_sight__drawQuadThousandth |> push(datablock_getBool(drawQuad, "thousandth", false))

    blk |> datablock_get_block("drawCircles") <| $(drawCircles)
      for i in urange(drawCircles.blockCount)
        datablock_get_block(drawCircles, i) <| $(drawCircle)
          vehicle_sight__drawCircleSegment |> push(datablock_getPoint2(drawCircle, "segment", float2(0, 0)))
          vehicle_sight__drawCirclePos |> push(datablock_getPoint2(drawCircle, "pos", float2(0, 0)))
          vehicle_sight__drawCircleDiameter |> push(datablock_getReal(drawCircle, "diameter", 0f))
          vehicle_sight__drawCircleSize |> push(datablock_getReal(drawCircle, "size", 0f))
          vehicle_sight__drawCircleThousandth |> push(datablock_getBool(drawCircle, "thousandth", false))

