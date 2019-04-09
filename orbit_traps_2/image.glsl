
const vec3 fv3_1 = vec3(1.0, 1.0, 1.0);
const vec2 fv2_1 = vec2(1.0, 1.0);

void mainImage(out vec4 outRGBA, in vec2 XY)
{
  vec2 UV = XY/iResolution.y;

  float  f = dot(sin(UV * 3.14159 * 2.0 * 5.0), fv2_1) * 0.25 + 0.5;
  vec3 rgb = vec3(f);

  outRGBA = vec4(rgb, 1.0);
}


// grimoire bindings
out vec4 fragColor; void main() { mainImage(fragColor, gl_FragCoord.xy); }
