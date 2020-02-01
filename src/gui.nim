import rapid/gfx
import rapid/res/images
import rapid/res/textures
import rdgui/button
import rdgui/control
import rdgui/event
import rdgui/windows

import common
import objects
import tools

const
  ToolIconPngs = [
    toolCursor: slurp("data/icons/cursor.png"),
    toolLineSegment: slurp("data/icons/lineSegment.png"),
    toolLight: slurp("data/icons/light.png"),
  ]

type
  MainWindow* = ref object of Window

var
  wm*: WindowManager
  toolImpls* = [
    toolCursor: cursorImpl(),
    toolLineSegment: lineSegmentImpl(),
    toolLight: lightImpl(),
  ]
  editorOverlay* = on

FloatingWindow.renderer(Delightful, window):
  const Background = gray(0x22)
  ctx.begin()
  ctx.color = Background
  ctx.rect(0, 0, window.width, window.height)
  ctx.draw()
  BoxChildren(ctx, step, window)

method onEvent*(win: MainWindow, event: UiEvent) =
  if event.kind == evKeyPress:
    if event.key == keySlash:
      editorOverlay = not editorOverlay
      event.consume()
    elif event.key == keyV:
      surface.vsync = not surface.vsync
      echo "vsync: ", surface.vsync
  if not event.consumed:
    toolImpls[tool].uiEventImpl(event)

MainWindow.renderer(Default, window):
  discard window
  for obj in world:
    obj.draw(ctx)
  if editorOverlay == on:
    for obj in world:
      obj.editorDraw(ctx)
  toolImpls[tool].drawImpl(ctx)

proc initMainWindow*(win: MainWindow, wm: WindowManager, rwin: RWindow) =
  win.initWindow(wm, 0, 0, rwin.width.float, rwin.height.float,
                 renderer = MainWindowDefault)
  rwin.onResize do (width, height: Natural):
    win.width = width.float
    win.height = height.float

proc newMainWindow*(wm: WindowManager, rwin: RWindow): MainWindow =
  new(result)
  result.initMainWindow(wm, rwin)

proc ButtonTool(base: ControlRenderer, icon: RTexture,
                t: Tool): ControlRenderer =
  const
    ColorUnselected = gray(164)
    ColorSelected = gray(255)
  Button.prenderer(IconImpl, button):
    base(ctx, step, button)
    ctx.begin()
    ctx.color =
      if tool == t: ColorSelected
      else: ColorUnselected
    ctx.texture = icon
    ctx.rect(4, 4, 24, 24)
    ctx.color = gray(255)
    ctx.draw()
    ctx.noTexture
  result = ButtonIconImpl

proc toolButton(x, y: float, t: Tool): Button =
  let img = readRImagePng(ToolIconPngs[t])
  result = newButton(x, y, 32, 32, ButtonTool(ButtonRd, newRTexture(img), t))
  result.onClick = proc () =
    tool = t

proc initGui*(win: RWindow) =
  wm = newWindowManager(win)

  block addMainWindow:
    var main = wm.newMainWindow(win)
    wm.add(main)

  block addDock:
    var dock = wm.newFloatingWindow(0, 0, 128, 48, FloatingWindowDelightful)
    dock.draggable = false
    wm.add(dock)

    var x = 8.0
    for t in low(Tool)..high(Tool):
      dock.add(toolButton(x, 8, t))
      x += 40
