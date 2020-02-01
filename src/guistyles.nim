import rapid/gfx
import rapid/gfx/text
import rdgui/control
import rdgui/slider
import rdgui/windows

import common

FloatingWindow.renderer(Delightful, window):
  const Background = gray(0x22)
  ctx.begin()
  ctx.color = Background
  ctx.rect(0, 0, window.width, window.height)
  ctx.color = gray(255)
  ctx.draw()
  BoxChildren(ctx, step, window)

proc FloatingWindowTitle*(base: ControlRenderer,
                          title: string): ControlRenderer =
  FloatingWindow.prenderer(TitleImpl, window):
    base(ctx, step, window)
    ctx.text(fontPlex, 4, 4, title,
             w = window.width - 8, h = window.height - 8,
             hAlign = taCenter, vAlign = taTop)
  result = FloatingWindowTitleImpl

proc SliderDelightful*(name: string): ControlRenderer =
  Slider.prenderer(DelightfulImpl, slider):
    ctx.text(fontPlex, -6, -2, name, h = slider.height,
             hAlign = taRight, vAlign = taMiddle)
    ctx.begin()
    ctx.rect(0, slider.height / 2 - 1, slider.width, 2)
    let x = (slider.value - slider.min) / (slider.max - slider.min) *
            slider.width
    ctx.rect(x, 0, 2, slider.height)
    ctx.draw()
    ctx.text(fontPlex, slider.width + 6, -2, $int(slider.value),
             h = slider.height, vAlign = taMiddle)
  result = SliderDelightfulImpl

