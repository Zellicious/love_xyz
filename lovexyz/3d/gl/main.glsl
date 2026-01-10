// the big boi

uniform mat4 u_MVP;
uniform mat4 u_ModelMatrix;

varying vec3 vNormal;
varying float vDepth;
varying vec3 vPosition;

uniform Image shadowMap;
uniform Image AOMap;
uniform Image RoughMap;
uniform CubeImage reflectionMap;
uniform CubeImage irradianceMap;

uniform mat4 u_SunMVP;
uniform vec3 u_LightDir;
uniform vec3 u_CamPosWorld;
uniform number u_ShadowSmoothness;
uniform number u_Metallic;

uniform vec2 u_ShadowMapTexel;

uniform bool shadowEnabled;
uniform bool simpleShadows;
uniform bool reflectionsEnabled;

#ifdef VERTEX
attribute vec3 VertexNormal;

vec4 position(mat4 transform_projection, vec4 vertex_position) {
  vec4 final = u_MVP * u_ModelMatrix * vertex_position;
  vNormal = normalize((u_ModelMatrix * vec4(VertexNormal, 0.0)).xyz);
  vPosition = (u_ModelMatrix * vec4(vertex_position.xyz, 1.0)).xyz;
  vDepth = final.z;

  return final;
}
#endif

#ifdef PIXEL

const float PI = 3.14159265;

highp float sampleShadow(vec4 lightSpacePos, vec3 N, vec3 L) {
  highp vec3 proj = lightSpacePos.xyz / lightSpacePos.w;
  highp vec2 uv = proj.xy * 0.5 + 0.5;

  vec2 d = uv - vec2(0.5);
  if (dot(d, d) > 0.25) // 0.5^2
    return 1.0;

  highp float currentDepth = proj.z;

  highp float bias = max(0.00075 * (1.0 - dot(N, L)), 0.0005);
  highp float shadow = 0.0;
  
  // PCF shadows, somehow still aliases
  if (!simpleShadows) {
    highp vec2 texelSize = 1.0 / u_ShadowMapTexel * u_ShadowSmoothness;
    for (int x = -2; x <= 2; x++) {
      for (int y = -2; y <= 2; y++) {
        vec2 p = vec2(float(x), float(y));
        highp vec2 offset = p * texelSize;
        highp float depth = Texel(shadowMap, uv + offset).r;
        shadow += ((currentDepth - bias > depth) ? 0.0: 1.0);
      }
    }

    shadow /= 25.0;
  } else {
    highp float depth = Texel(shadowMap, uv).r;
    shadow = ((currentDepth - bias > depth) ? 0.0: 1.0);
  }
  return shadow;
}


vec3 fresnelSchlick(float VoH, vec3 F0) {
  return F0 + (1.0 - F0) * pow(1.0 - VoH, 5.0);
}

// semi pbr blinn phong
vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords) {
  vec4 texColor = Texel(tex, texture_coords) * color;
  float aoCol = Texel(AOMap,texture_coords).r;
  float roughCol = Texel(RoughMap,texture_coords).r;

  roughCol = clamp(roughCol, 0.04, 1.0);

  // lighting

  vec3 N = normalize(vNormal);
  vec3 L = normalize(u_LightDir);
  vec3 V = normalize(vPosition - u_CamPosWorld);
  vec3 H = normalize(L + V);
  float NoL = max(dot(N, L), 0.0);
  float NoV = max(dot(N, V), 0.0);
  float NoH = max(dot(N, H), 0.0);
  float VoH = max(dot(V, H), 0.0);

  // Textures
  vec3 albedo = texColor.rgb;
  float roughness = clamp(roughCol, 0.01, 1.0);

  // Convert roughness to Blinn exponent
  float shininess = mix(128.0, 4.0, (1.0-roughness));

  vec3 F0 = mix(vec3(.04), albedo, u_Metallic);

  // Fresnel
  vec3 F = fresnelSchlick(NoV, F0);
  vec3 kS = F;
  vec3 kD = (1.0 - kS) * (1.0 - u_Metallic);
  vec3 diffuse = albedo * kD;

  float spec = pow(NoH, shininess);
  float specNorm = (shininess) / (2.0 * PI);
  vec3 specular = kS * spec * specNorm * albedo * (1.0-roughness);

  vec3 lighting = (diffuse + specular) * NoL;

  if (reflectionsEnabled) {
    vec3 R = reflect(-V, N);
    vec3 env = Texel(reflectionMap, R*vec3(-1.0,1.0,-1.0)).rgb;

    vec3 kS = F;
    vec3 iblSpec = env * kS * (1.0 - roughness);
    lighting += iblSpec;
  }

  if (shadowEnabled) {
    vec4 lightSpacePos = u_SunMVP * vec4(vPosition, 1.0);
    float shadow = sampleShadow(lightSpacePos, N, L);
    float shadowStrength = mix(1.0, shadow, clamp(NoL, 0.0, 1.0));
    lighting *= shadowStrength;
  }

  vec3 irradiance = Texel(irradianceMap, N).rgb;
  vec3 indirectDiffuse = kD * irradiance * albedo * aoCol;
  lighting += indirectDiffuse;

  return vec4(lighting, 1.0);
}
#endif