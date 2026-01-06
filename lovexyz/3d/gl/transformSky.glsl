uniform mat4 u_MVP;

vec4 position(mat4 transform_projection, vec4 vertex_position)
{
  return u_MVP * vertex_position;
}