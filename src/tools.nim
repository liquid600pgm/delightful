import rapid/gfx
import rdgui/event

import common
import objects
import raycaster

type
  ToolImpl* = object
    drawImpl*: proc (ctx: RGfxContext)
    uiEventImpl*: proc (event: UiEvent)

proc cursorImpl*(): ToolImpl =

  proc drawImpl(ctx: RGfxContext) =
    discard

  proc uiEventImpl(event: UiEvent) =
    for obj in world:
      obj.uiEvent(event)
      if event.consumed:
        break
    if not event.consumed:
      if event.kind == evMousePress:
        selectedObject = nil

  result = ToolImpl(drawImpl: drawImpl, uiEventImpl: uiEventImpl)

proc lineSegmentImpl*(): ToolImpl =
  var
    placing = false
    start, anchor: Vec2[float]

  proc mouseNearStart(): bool =
    result = mouseInCircle(start.x, start.y, 8) and start != anchor

  proc adjustedMousePos(): Vec2[float] =
    result = vec2(win.mouseX, win.mouseY)
    if mouseNearStart():
      result = start

  proc drawImpl(ctx: RGfxContext) =
    ctx.begin()
    ctx.color =
      if placing: rgb(0, 255, 255)
      elif mouseNearStart(): rgb(0, 255, 0)
      else: rgb(0, 0, 255)
    ctx.lcircle(win.mouseX, win.mouseY, 8)
    if placing:
      var mouse = adjustedMousePos()
      ctx.color = gray(255, 127)
      ctx.line((anchor.x, anchor.y), (mouse.x, mouse.y))
    ctx.color = gray(255)
    ctx.draw(prLineShape)

  proc uiEventImpl(event: UiEvent) =
    if event.kind == evMousePress:
      if event.mouseButton == mb1:
        if placing:
          let line = LineSegment (a: anchor, b: adjustedMousePos())
          echo "placing new segment ", line
          world.add(Segment(lineSegment: line))
        anchor = adjustedMousePos()
        if not placing:
          placing = true
          start = anchor
      elif event.mouseButton == mb2:
        if not placing:
          tool = toolCursor
        placing = false

  result = ToolImpl(drawImpl: drawImpl, uiEventImpl: uiEventImpl)

proc lightImpl*(): ToolImpl =

  proc drawImpl(ctx: RGfxContext) =
    ctx.begin()
    ctx.color = rgba(255, 0, 0, 127)
    ctx.lcircle(win.mouseX, win.mouseY, 16)
    ctx.color = gray(255)
    ctx.draw(prLineShape)

  proc uiEventImpl(event: UiEvent) =
    if event.kind == evMousePress:
      if event.mouseButton == mb1:
        echo "placing new light at ", win.mousePos
        world.add(Light(pos: vec2(win.mouseX, win.mouseY),
                        radius: 256))
      elif event.mouseButton == mb2:
        tool = toolCursor

  result = ToolImpl(drawImpl: drawImpl, uiEventImpl: uiEventImpl)
