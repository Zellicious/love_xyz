varying float vDepth;

uniform mat4 u_MVP;
uniform mat4 u_ModelMatrix;

#ifdef VERTEX

vec4 position(mat4 transform_projection, vec4 vertex_position) {
  highp vec4 final = u_MVP * u_ModelMatrix * vertex_position;
  vDepth = final.z;
  return final;
}

#endif

#ifdef PIXEL

vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords) {
  return vec4(vec3(vDepth), 1.0);
}

#endif