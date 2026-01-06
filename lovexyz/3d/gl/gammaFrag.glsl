vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords)
{
  vec4 texColor = Texel(tex, texture_coords) * color;
  return vec4(texColor.rgb,1.0);
}