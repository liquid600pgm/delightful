import rapid/gfx
import rapid/gfx/text
import rapid/world/aabb
import rdgui/control
import rdgui/event
import rdgui/slider
import rdgui/windows

import common
import guistyles
import raycaster

{.push warning[LockLevel]: off.}

#--
# Types
#--

type
  WorldObject* = ref object of RootObj
    isGarbage: bool
  Segment* = ref object of WorldObject
    lineSegment*: LineSegment
    dragging, draggingA, draggingB: bool
    dragLastPos: Vec2[float]
  Light* = ref object of WorldObject
    pos*: Vec2[float]
    radius*: float
    color*: RColor
    dragging: bool

var
  world*: seq[WorldObject]
  selObj*, lastSelObj*: WorldObject
  selObjectProperties*: FloatingWindow

#--
# Base implementation
#--

method draw*(obj: WorldObject, ctx: RGfxContext) {.base.} = discard
method editorDraw*(obj: WorldObject, ctx: RGfxContext) {.base.} = discard
method uiEvent*(obj: WorldObject, event: UiEvent) {.base.} = discard
method propertiesWindow*(obj: WorldObject): FloatingWindow {.base.} = discard

proc delete*(obj: WorldObject) =
  obj.isGarbage = true

proc updateWorld*() =
  var garbage: seq[int]
  for i, obj in world:
    if obj.isGarbage:
      garbage.add(i)
  for i in countdown(garbage.len - 1, 0):
    world.delete(garbage[i])

proc updatePropertiesWindowPos() =
  if selObjectProperties != nil:
    selObjectProperties.pos =
      vec2(surface.width - selObjectProperties.width, 0.0)

proc spawnObject*(obj: WorldObject) =
  var obj = obj
  if obj of Light and lastSelObj of Light:
    var light = obj.Light
    light.color = lastSelObj.Light.color
    light.radius = lastSelObj.Light.radius
  world.add(obj)

proc selectObject*(obj: WorldObject) =
  if selObjectProperties != nil:
    selObjectProperties.close()
  selObj = obj
  if selObj != nil:
    lastSelObj = selObj
    selObjectProperties = selObj.propertiesWindow()
  else:
    selObjectProperties = nil
  if selObjectProperties != nil:
    updatePropertiesWindowPos()
    selObjectProperties.draggable = false
    wm.add(selObjectProperties)

proc initWorld*() =
  win.onResize do (width, height: Natural):
    updatePropertiesWindowPos()

#--
# Light implementation
#--

method draw*(light: Light, ctx: RGfxContext) =
  var segs: seq[LineSegment] = @[
    (vec2(0.0, 0.0), vec2(surface.width, 0.0)),
    (vec2(surface.width, 0.0), vec2(surface.width, surface.height)),
    (vec2(surface.width, surface.height), vec2(0.0, surface.height)),
    (vec2(0.0, surface.height), vec2(0.0, 0.0)),
  ]
  for obj in world:
    if obj of Segment:
      segs.add(obj.Segment.lineSegment)
  ctx.clearStencil(0)
  ctx.stencil(saReplace, 255):
    ctx.begin()
    ctx.raycast(light.pos, segs)
    ctx.draw()
  ctx.stencilTest = (scEq, 255)
  ctx.begin()
  ctx.texture = texLight
  ctx.color = light.color
  ctx.rect(light.pos.x - light.radius, light.pos.y - light.radius,
           light.radius * 2, light.radius * 2)
  ctx.color = gray(255)
  ctx.blendMode = bmAdd
  ctx.draw()
  ctx.blendMode = bmNormal
  ctx.noTexture
  ctx.noStencilTest

method editorDraw*(light: Light, ctx: RGfxContext) =
  const
    NormalColor = rgb(255, 0, 0)
    SelectedColor = rgb(255, 255, 0)
  ctx.begin()
  ctx.color =
    if light.WorldObject == selObj: SelectedColor
    else: NormalColor
  ctx.lcircle(light.pos.x, light.pos.y, 16)
  ctx.color = gray(255)
  ctx.draw(prLineShape)

method uiEvent*(light: Light, event: UiEvent) =
  if tool == toolCursor:
    if event.kind == evMousePress:
      if mouseInCircle(light.pos.x, light.pos.y, 16):
        if event.mouseButton == mb1:
          selectObject(light)
          light.dragging = true
        elif event.mouseButton == mb2:
          light.delete()
        event.consume()
    elif event.kind == evMouseRelease:
      light.dragging = false
    elif event.kind == evMouseMove and light.dragging:
      light.pos = vec2(win.mouseX, win.mouseY)

method propertiesWindow*(light: Light): FloatingWindow =
  result = wm.newFloatingWindow(0, 0, 192, 92,
                                FloatingWindowDelightful
                                  .FloatingWindowTitle("Light"))

  var y = 32.0
  template slider(property, name, min, max, step) =

    let
      labelW = round(fontPlex.widthOf(name) / 8.0) * 8.0
      x = 16.0 + labelW
      slider = newSlider(x, y, 132 - labelW, 12, min, max,
                         value = property, step,
                         SliderDelightful(name))
    slider.onChange = proc (oldVal, newVal: float) =
      property = newVal
    result.add(slider)
    y += 20

  slider(light.color.red, "R", 0, 1, 0.01)
  slider(light.color.green, "G", 0, 1, 0.01)
  slider(light.color.blue, "B", 0, 1, 0.01)
  slider(light.radius, "Radius", 64, 1024, 1)

  result.height = y + 4

#--
# Segment implementation
#--

method editorDraw*(seg: Segment, ctx: RGfxContext) =
  let (a, b) = seg.lineSegment
  ctx.begin()
  ctx.color =
    if seg.WorldObject == selObj: rgb(255, 255, 0)
    else: gray(255)
  ctx.line((a.x, a.y), (b.x, b.y))
  ctx.color = rgb(255, 0, 255)
  if seg.draggingA:
    ctx.lcircle(a.x, a.y, 8)
  if seg.draggingB:
    ctx.lcircle(b.x, b.y, 8)
  ctx.color = gray(255)
  ctx.draw(prLineShape)

method uiEvent*(seg: Segment, event: UiEvent) =
  if tool == toolCursor:
    if event.kind == evMousePress:
      let (a, b) = seg.lineSegment
      if event.mouseButton == mb1:
        seg.dragLastPos = vec2(win.mouseX, win.mouseY)
        if mouseInCircle(a.x, a.y, 8.0):
          seg.draggingA = true
        elif mouseInCircle(b.x, b.y, 8.0):
          seg.draggingB = true
        elif mouseNearLine(a, b, 8.0):
          seg.draggingA = true
          seg.draggingB = true
          selectObject(seg)
          event.consume()
      elif event.mouseButton == mb2 and mouseNearLine(a, b, 8.0):
        seg.delete()
    elif event.kind == evMouseRelease:
      seg.draggingA = false
      seg.draggingB = false
    elif event.kind == evMouseMove:
      let dpos = vec2(win.mouseX, win.mouseY) - seg.dragLastPos
      if seg.draggingA:
        seg.lineSegment.a += dpos
      if seg.draggingB:
        seg.lineSegment.b += dpos
      seg.dragLastPos = vec2(win.mouseX, win.mouseY)

{.pop.}
