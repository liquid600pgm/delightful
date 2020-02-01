import algorithm
import math
import options

import rapid/gfx

import common

type
  LineSegment* = tuple
    a, b: Vec2[float]
  Intersection* = tuple
    pos: Vec2[float]
    t: float

proc intersect*(ray, seg: LineSegment): Option[Intersection] =
  ## I have no idea how this works, but if it works, don't touch it.
  # compute some basic rudimentary shit that this requires
  let
    rp = ray.a
    rd = ray.b - ray.a
    sp = seg.a
    sd = seg.b - seg.a
    rmag = sqrt(dot(rd, rd))
    smag = sqrt(dot(sd, sd))
  # check if they're parallel
  if rd / rmag == sd / smag:
    return none(Intersection)
  # compute the magic T1 and T2 that nobody understands what they do
  let
    t2 = (rd.x * (sp.y - rp.y) + rd.y * (rp.x - sp.x)) /
         (sd.x * rd.y - sd.y * rd.x)
    t1 = (sp.x + sd.x * t2 - rp.x) / rd.x
  # limits
  if t1 < 0 or t2 < 0 or t2 > 1:
    return none(Intersection)
  # aand off we go
  result = some (pos: rp + rd * t1, t: t1)

proc findIntersection*(ray: LineSegment,
                       segs: seq[LineSegment]): Option[Intersection] =
  result = none(Intersection)
  for seg in segs:
    let intersection = ray.intersect(seg)
    if intersection.isSome:
      if result.isNone or intersection.get.t < result.get.t:
        result = intersection

proc angleBetween(a, b: Vec2[float]): float =
  result = arctan2(b.y - a.y, b.x - a.x)

proc raycast*(ctx: RGfxContext, light: Vec2[float], segs: seq[LineSegment]) =
  var intersections: seq[Intersection]
  for seg in segs:
    for vertex in [seg.a, seg.b]:
      var baseAngle = angleBetween(light, vertex)
      if baseAngle.abs in [PI / 2, 3 * PI / 2]:
        baseAngle += 0.00001
      for angle in [baseAngle - 0.0001, baseAngle, baseAngle + 0.0001]:
        let
          rayDir = vec2(cos(angle), sin(angle))
          ray = LineSegment (light, light + rayDir)
          intersection = ray.findIntersection(segs)
        if intersection.isSome:
          intersections.add(intersection.get)
  intersections.sort do (a, b: Intersection) -> int:
    let
      angleA = angleBetween(light, a.pos)
      angleB = angleBetween(light, b.pos)
    result = cmp(angleA, angleB)
  for i, intersection in intersections:
    let
      pos1 = intersection.pos
      pos2 = intersections[(i + 1) mod intersections.len].pos
    ctx.tri((light.x, light.y, White),
            (pos1.x, pos1.y, White),
            (pos2.x, pos2.y, White))
