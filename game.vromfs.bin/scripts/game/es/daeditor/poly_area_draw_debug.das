options no_aot
require ecs
require DagorMath
require DagorDebug3D
require math.color



def get_radius(dist : float) : float
  let radiusMinMax = float2(0.3, 4.5)
  let radiusDistScale = float2(10.0, 600.0)
  return cvt(dist, radiusDistScale.x, radiusDistScale.y, radiusMinMax.x, radiusMinMax.y)


def get_color_from_eid(eid : EntityId)
  var seed = int(uint(eid))
  return rnd_color(seed)


[es(no_order)]
def poly_area_editor_draw(info : UpdateStageInfoRenderDebug;
                          poly_area_editor__areasEids : EidList;
                          poly_area_editor__traceFrom : float3;
                          poly_area_editor__cursorPosition : float3;
                          poly_area_editor__highlightedAreaEid : EntityId;
                          poly_area_editor__highlightedAreaPointIndex : int;
                          poly_area_editor__highlightedAreaPointIndex2 : int)
  begin_draw_cached_debug_lines(false, false, false)

  let cursorColor = E3DCOLOR(0xFFFFFFFF)
  let cursorRadiusMult = 1.5
  let highlightedPointRadiusMult = 2.5
  let cursorRadius = get_radius(length(poly_area_editor__traceFrom - poly_area_editor__cursorPosition)) * cursorRadiusMult

  draw_cached_debug_sphere(poly_area_editor__cursorPosition,
                           cursorRadius,
                           cursorColor,
                           24)

  // ideally we should have something like poly_area__name to use here
  // but we only have two types of poly areas for now so lets avoid unnecessary string copies or tracks
  // and just use those names directly
  find_query() <| $ [es] (camera__active : bool; transform : float3x4)
    if !camera__active
      return false

    query(poly_area_editor__highlightedAreaEid) <| $ [es] (battleAreaId : string = ""; capzone__areaId : string = "")
      let text = "{battleAreaId}{capzone__areaId}"
      let textMarkPos = poly_area_editor__cursorPosition - transform[1] * cursorRadius * 4.0
      add_debug_text_mark(textMarkPos, text, -1, 0f, get_color_from_eid(poly_area_editor__highlightedAreaEid))
    return true

  for areaEid in poly_area_editor__areasEids
    query(areaEid) <| $ [es] (poly_area__points : Point3List)
      let color = get_color_from_eid(areaEid)

      let isHighlightedArea = poly_area_editor__highlightedAreaEid == areaEid
      let pointsCount = length(poly_area__points)
      for i in range(0, pointsCount)
        let nextI = (i + 1) % pointsCount
        draw_cached_debug_line(poly_area__points[i], poly_area__points[nextI], color)

        let rad = get_radius(length(poly_area_editor__traceFrom - poly_area__points[i]))

        let isDrawnPointHighlighted = isHighlightedArea && poly_area_editor__highlightedAreaPointIndex == i && poly_area_editor__highlightedAreaPointIndex2 == -1
        draw_cached_debug_sphere(poly_area__points[i],
                                 isDrawnPointHighlighted ? rad * highlightedPointRadiusMult : rad,
                                 isDrawnPointHighlighted ? lerp_color(color, E3DCOLOR(0xFF000000), 0.7) : color,
                                 9)

      if isHighlightedArea
        let prevToHighlightedIndex = poly_area_editor__highlightedAreaPointIndex > 0 ? poly_area_editor__highlightedAreaPointIndex - 1 : pointsCount - 1

        let isExactPointHighlight = poly_area_editor__highlightedAreaPointIndex2 == -1
        let i1 = isExactPointHighlight ? prevToHighlightedIndex : poly_area_editor__highlightedAreaPointIndex
        let i2 = isExactPointHighlight ? (poly_area_editor__highlightedAreaPointIndex + 1) % pointsCount : poly_area_editor__highlightedAreaPointIndex2

        draw_cached_debug_line(poly_area__points[i1], poly_area_editor__cursorPosition, cursorColor)
        draw_cached_debug_line(poly_area_editor__cursorPosition, poly_area__points[i2], cursorColor)

  end_draw_cached_debug_lines()
