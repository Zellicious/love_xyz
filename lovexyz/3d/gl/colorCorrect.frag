uniform float u_Brightness; // 1.0
uniform float u_Contrast; // 1.0
uniform float u_Saturation; // 1.0

vec4 effect(vec4 color, Image scene, vec2 uv, vec2 screenPos) {
  vec3 c = Texel(scene, uv).rgb;

  // saturation
  float luma = dot(c, vec3(0.2126, 0.7152, 0.0722));
  c = mix(vec3(luma), c, u_Saturation);

  // contrast (pivot at 0.5)
  c = (c - 0.5) * u_Contrast + 0.5;

  // brightness
  c *= u_Brightness;

  return vec4(c, 1.0);
}