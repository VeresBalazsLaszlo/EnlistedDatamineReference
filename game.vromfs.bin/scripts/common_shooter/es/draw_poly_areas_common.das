module draw_poly_areas_common shared
require ecs
require ecs.common
require DagorMath
require DagorConsole
require DagorSystem
require DagorDebug3D

def point2_to_point3_height(inPoint, height)
  return float3(inPoint.x, height, inPoint.y)

def draw_poly_area(areaPoints : Point2List&;
                   minHeight : float;
                   maxHeight : float;
                   color : E3DCOLOR)
  for i in iter_range(areaPoints)
    let nextPointId = (i + 1) % length(areaPoints)
    //line 1 (vertical)
    var pointStart = point2_to_point3_height(areaPoints[i], minHeight)
    var pointEnd = point2_to_point3_height(areaPoints[i], maxHeight)
    draw_debug_line_buffered(pointStart, pointEnd, color, 1)
    //line 2 (diag0)
    pointStart = point2_to_point3_height(areaPoints[i], minHeight)
    pointEnd = point2_to_point3_height(areaPoints[nextPointId], maxHeight)
    draw_debug_line_buffered(pointStart, pointEnd, color, 1)
    //line 3 (diag1)
    pointStart = point2_to_point3_height(areaPoints[i], maxHeight)
    pointEnd = point2_to_point3_height(areaPoints[nextPointId], minHeight)
    draw_debug_line_buffered(pointStart, pointEnd, color, 1)
    //line 4 (horizontal0)
    pointStart = point2_to_point3_height(areaPoints[i], minHeight)
    pointEnd = point2_to_point3_height(areaPoints[nextPointId], minHeight)
    draw_debug_line_buffered(pointStart, pointEnd, color, 1)
    //line 4 (horizontal1)
    pointStart = point2_to_point3_height(areaPoints[i], maxHeight)
    pointEnd = point2_to_point3_height(areaPoints[nextPointId], maxHeight)
    draw_debug_line_buffered(pointStart, pointEnd, color, 1)