varying vec3 vNormal;
varying float vDepth;
varying vec3 vPosition;

uniform Image shadowMap;

uniform mat4 u_SunMVP;
uniform vec3 u_LightDir;
uniform vec3 u_CamPosWorld;
uniform number u_Ambient;
uniform number u_Shininess;
uniform number u_Specular;
uniform vec2 u_ShadowMapSize;

const float shadowDetail = 2.0;

float rand(vec2 co)
{
    return fract(sin(dot(co, vec2(127856.9898,77567.233))) * 43.5453);
}

float linearizeDepth(float d)
{
    float near = 0.1;
    float far  = 500.0;
    return (2.0 * near) / (far + near - d * (far - near));
}

highp float sampleShadow(vec4 lightSpacePos,vec3 N, vec3 L)
{
    vec3 proj = lightSpacePos.xyz / lightSpacePos.w;
    vec2 uv = proj.xy * 0.5 + 0.5;

    if (uv.x <= 0.0 || uv.x >= 1.0 || uv.y <= 0.0 || uv.y >= 1.0)
        return 1.0;
        
    highp float currentDepth = proj.z;

    highp float bias = max(0.0005 * (1.0 - dot(N, L)), 0.0003);
    highp float shadow = 0.0;

    highp vec2 texelSize = 1.0 / u_ShadowMapSize / shadowDetail;
    highp float angle = rand(gl_FragCoord.xy) * 6.2831853;
    mat2 rot = mat2(cos(angle), -sin(angle),
                            sin(angle),  cos(angle));

    float weightSum = 0.0;
    
    for (int x = -int(shadowDetail/2.0); x <= int(shadowDetail/2.0); x++)
    {
        for (int y = -int(shadowDetail/2.0); y <= int(shadowDetail/2.0); y++)
        {
            vec2 p = vec2(float(x), float(y));
    
            vec2 offset = rot * p * texelSize;
    
            highp float depth = Texel(shadowMap, uv + offset).r;
            shadow += ((currentDepth - bias > depth) ? 0.0 : 1.0);
            weightSum += 1.0;
        }
    }
    
    shadow /= weightSum;

    return shadow;
}

vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords)
{
    vec3 N = normalize(vNormal);
    vec3 L = normalize(u_LightDir);
    vec3 V = normalize(vPosition - u_CamPosWorld);
    
    // shadows
    
    vec4 lightSpacePos = u_SunMVP * vec4(vPosition, 1.0);
    float NoL = max(dot(N, L), 0.0);
    float shadow = sampleShadow(lightSpacePos,N,L);
    
    // shadow = mix(1.0, shadow, clamp(NoL, 0.0, 1.0));
    float shadowStrength = mix(1.0, shadow, clamp(NoL, 1.0-u_Ambient, 1.0));
    
    // lighting
    float diff = NoL;
    vec3 H = normalize(L + V);
    float spec = pow(min(max(dot(N,H),0.0),1.0), u_Shininess);

    spec *= shadowStrength;
    diff *= shadowStrength;
    
    float lighting = (u_Ambient + diff);
    // base texture color
    vec4 texColor = Texel(tex, texture_coords) * color;
    texColor.rgb *= lighting;
    texColor.rgb += vec3(spec * u_Specular);
    
    return vec4(texColor.rgb, 1.0);
}