uniform mat4 u_MVP;
uniform mat4 u_ModelMatrix;

varying vec3 vNormal;
varying float vDepth;
varying vec3 vPosition;

uniform Image shadowMap;
uniform CubeImage reflectionMap;

uniform mat4 u_SunMVP;
uniform vec3 u_LightDir;
uniform vec3 u_CamPosWorld;
uniform number u_Ambient;
uniform number u_Shininess;
uniform number u_Specular;
uniform number u_ReflectionStrength;
uniform number u_BaseReflectionStrength;
uniform vec2 u_ShadowMapTexel;

uniform bool shadowEnabled;
uniform bool specularEnabled;
uniform bool diffuseEnabled;
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
    highp vec2 texelSize = 1.0 / u_ShadowMapTexel;
    for (int x = -1; x <= 1; x++) {
      for (int y = -1; y <= 1; y++) {
        vec2 p = vec2(float(x), float(y));
        highp vec2 offset = p * texelSize;
        highp float depth = Texel(shadowMap, uv + offset).r;
        shadow += ((currentDepth - bias > depth) ? 0.0: 1.0);

      }
    }

    shadow /= 9.0;
  } else {
    highp float depth = Texel(shadowMap, uv).r;
    shadow = ((currentDepth - bias > depth) ? 0.0: 1.0);
  }
  return shadow;
}

vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords) {
  vec3 N = normalize(vNormal);
  vec3 L = normalize(u_LightDir);
  vec3 V = normalize(vPosition - u_CamPosWorld);
  
  highp float NoL = max(dot(N, L), 0.0);

  // lighting
  highp float diff = NoL;
  vec3 H = normalize(L + V);
  highp float spec = pow(min(max(dot(N, H), 0.0), 1.0), u_Shininess);

  if (shadowEnabled) {
    vec4 lightSpacePos = u_SunMVP * vec4(vPosition, 1.0);
    highp float shadow = sampleShadow(lightSpacePos, N, L);
    highp float shadowStrength = mix(1.0, shadow, clamp(NoL, 1.0-u_Ambient, 1.0));

    spec *= shadowStrength;
    diff *= shadowStrength;
  }
  vec4 texColor = Texel(tex, texture_coords) * color;
  if (reflectionsEnabled) {
    vec3 R = reflect(V, N);
    vec3 env = Texel(reflectionMap, R*vec3(1.0,-1.0,1.0)).rgb;
  
    float fresnel = u_BaseReflectionStrength + (1.0-u_BaseReflectionStrength) * pow(1.0 - max(dot(N, V), 0.0), 2.0);
    // float fresnel = pow(1.0 - max(dot(N, V), 0.0), 2.0);
    
    
    texColor.rgb = mix(
      texColor.rgb,
      env,
      u_ReflectionStrength * fresnel
    );
  }
  if (diffuseEnabled) {
    float lighting = (u_Ambient + diff);
    texColor.rgb *= lighting;
  }

  if (specularEnabled) {
    texColor.rgb += vec3(spec * u_Specular);
  }

  return vec4(texColor.rgb, 1.0);
}
#endif