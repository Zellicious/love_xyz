uniform mat4 u_MVP;
varying vec3 vDir;

uniform CubeImage skybox;

#ifdef VERTEX
vec4 position(mat4 transform_projection, vec4 vertex_position)
{
    vDir = vertex_position.xyz;   // direction for cubemap
    return u_MVP * vertex_position;
}
#endif

#ifdef PIXEL
vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords)
{
    vec3 dir = normalize(vDir);
    dir.y = -dir.y;

    vec3 sky = Texel(skybox, dir).rgb;
    
    float luminance = dot(sky, vec3(0.299, 0.587, 0.114));

    if (luminance < 0.002) {
      sky = vec3(0.0);
    }
    return vec4(sky, 1.0);
}
#endif