varying float vDepth;

vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords)
{
  return vec4(vec3(vDepth),1.0);
}