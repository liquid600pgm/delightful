const
  RadialBlur* = """
    uniform vec2 center;
    uniform float samples;
    uniform float strength;

    vec4 rEffect(vec2 pos) {
      float radius = distance(center, pos) * strength;

      vec4 accum = vec4(0.0);
      float den = 0.0;
      for (float y = -samples; y <= samples; ++y) {
        for (float x = -samples; x <= samples; ++x) {
          vec2 offset = vec2(x, y) * radius;
          accum += rPixel(pos + offset);
          ++den;
        }
      }
      accum /= den;

      return accum;
    }
  """
