import rapid/gfx
import rapid/gfx/text
import rdgui/windows

import common
import gui
import objects

win = initRWindow()
  .size(800, 600)
  .title("delightful")
  .antialiasLevel(8)
  .open()
surface = win.openGfx()

initResources()
initGui(win)
initWorld()

var lastTime = time()
surface.loop:
  init ctx:
    ctx.lineSmooth = true
  draw ctx, step:
    let deltaTime = time() - lastTime
    lastTime = time()
    ctx.clear(Black)
    wm.draw(ctx, step)
    ctx.text(fontPlex, 4, 4, $int(1 / deltaTime) & " fps",
             w = surface.width - 8, h = surface.height - 8,
             vAlign = taBottom, hAlign = taLeft)
  update:
    updateWorld()
