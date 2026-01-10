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


float D_GGX(float NoH, float rough) {
  float a  = rough * rough;
  float a2 = a * a;

  float denom = (NoH * NoH) * (a2 - 1.0) + 1.0;
  return a2 / max(3.14159265 * denom * denom, 1e-6);
}

float G_SchlickGGX(float NoX, float rough) {
  float r = rough + 1.0;
  float k = (r * r) / 8.0;   // UE4 / Disney formulation

  return NoX / max(NoX * (1.0 - k) + k, 1e-6);
}

float G_Smith(float NoV, float NoL, float rough) {
  float gv = G_SchlickGGX(NoV, rough);
  float gl = G_SchlickGGX(NoL, rough);
  return gv * gl;
}

// principled brdf
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

  // Base reflectance
  vec3 albedo = texColor.rgb;
  vec3 F0 = mix(vec3(0.04), albedo, u_Metallic);

  // Specular BRDF
  float D = D_GGX(NoH, roughCol);
  float G = G_Smith(NoV, NoL, roughCol);
  vec3  F = fresnelSchlick(VoH, F0);

  vec3 specular = (D * G * F) / max(4.0 * NoV * NoL, 0.001);

  // Diffuse (energy conserving)
  vec3 kd = (1.0 - F) * (1.0 - u_Metallic);
  vec3 diffuse = kd * albedo / 3.14159265;

  // Final lighting

  // ===== DIRECT LIGHT =====
  vec3 lighting = (diffuse + specular) * NoL;

  if (shadowEnabled) {
    vec4 lightSpacePos = u_SunMVP * vec4(vPosition, 1.0);
    float shadow = sampleShadow(lightSpacePos, N, L);
    float shadowStrength = mix(1.0, shadow, clamp(NoL, 0.0, 1.0));
    lighting *= shadowStrength;
  }

  // ===== INDIRECT DIFFUSE (IBL) =====
  vec3 irradiance = Texel(irradianceMap, N).rgb;

  vec3 F_ibl = fresnelSchlick(NoV, F0);
  vec3 kD_ibl = (1.0 - F_ibl) * (1.0 - u_Metallic);

  vec3 indirectDiffuse = kD_ibl * irradiance * albedo * aoCol;
  lighting += indirectDiffuse;

  // ===== INDIRECT SPECULAR (IBL) =====
  if (reflectionsEnabled) {
    vec3 R = reflect(-V, N);
    vec3 env = Texel(reflectionMap, R * vec3(1.0,-1.0,1.0)).rgb;

    vec3 kS = F_ibl;
    vec3 iblSpec = env * kS * (1.0 - roughCol);
    lighting += iblSpec;
  }

  return vec4(lighting, 1.0);
}
#endif