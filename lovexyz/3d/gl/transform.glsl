attribute vec3 VertexNormal;

uniform mat4 u_MVP;
uniform mat4 u_ModelMatrix;

varying vec3 vPosition;
varying float vDepth;
varying vec3 vNormal;


vec4 position(mat4 transform_projection, vec4 vertex_position)
{
  vec4 final = u_MVP * u_ModelMatrix * vertex_position;
  vNormal = normalize((u_ModelMatrix * vec4(VertexNormal, 0.0)).xyz);
  vPosition = (u_ModelMatrix * vec4(vertex_position.xyz, 1.0)).xyz;
  vDepth = final.z;
  
  return final;
}