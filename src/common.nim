import math

import rapid/gfx
import rapid/gfx/text
import rapid/res/images
import rapid/res/textures

const
  Black* = gray(0)
  White* = gray(255)

  LightRes* {.intdefine.} = 256

type
  Tool* = enum
    toolCursor = "cursor"
    toolLineSegment = "lineSegment"
    toolLight = "light"

var
  win*: RWindow
  surface*: RGfx
  texLight*: RTexture
  fontPlex*: RFont
  tool* = toolCursor

proc dist2*(a, b: Vec2[float]): float =
  let
    dx = b.x - a.x
    dy = b.y - a.y
  result = dx * dx + dy * dy

proc dist*(a, b: Vec2[float]): float =
  result = dist2(a, b).sqrt

proc mouseInCircle*(x, y, r: float): bool =
  result = dist(vec2(win.mouseX, win.mouseY), vec2(x, y)) <= r

proc distanceToLine*(p, v, w: Vec2[float]): float =
  let l2 = dist2(v, w)
  if l2 == 0: return dist(p, v)
  let
    t = clamp(dot(p - v, w - v) / l2, 0, 1)
    projection = v + t * (w - v)
  return dist(p, projection)

proc mouseNearLine*(a, b: Vec2[float], r: float): bool =
  result = vec2(win.mouseX, win.mouseY).distanceToLine(a, b) < r

proc initResources*() =
  block genLightTexture:
    var pixels: seq[uint8]
    for y in 0..<LightRes:
      for x in 0..<LightRes:
        let
          fx = (y / LightRes) * 2 - 1
          fy = (x / LightRes) * 2 - 1
          i = max(0.0, 1.0 - dist(vec2(0.0, 0.0), vec2(fx, fy)))
          a = i.pow(4)
        pixels.add([255'u8, 255, 255, uint8(a * 255)])
    let image = newRImage(LightRes, LightRes, pixels[0].addr)
    texLight = newRTexture(image)
  block loadFont:
    const FontFile = slurp("data/IBMPlexSans-Regular.ttf")
    fontPlex = newRFont(FontFile, 14)
