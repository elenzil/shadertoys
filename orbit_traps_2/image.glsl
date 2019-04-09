// common stuff
const vec3 fv3_1 = vec3(1.0, 1.0, 1.0);
const vec3 fv3_0 = vec3(0.0, 0.0, 0.0);
const vec3 fv3_x = vec3(1.0, 0.0, 0.0);
const vec3 fv3_y = vec3(0.0, 1.0, 0.0);
const vec3 fv3_z = vec3(0.0, 0.0, 1.0);
const vec2 fv2_1 = vec2(1.0, 1.0);
const vec2 fv2_0 = vec2(0.0, 0.0);
const vec2 fv2_x = vec2(1.0, 0.0);
const vec2 fv2_y = vec2(0.0, 1.0);

vec2 complexMul(in vec2 A, in vec2 B) {
  return vec2((A.x * B.x) - (A.y * B.y), (A.x * B.y) + (A.y * B.x));
}


void mainImage(out vec4 outRGBA, in vec2 XY)
{
  float smallWay = min(iResolution.x, iResolution.y);
  vec2 UV = (XY * 2.0 - fv2_1 * iResolution.xy)/smallWay;

  vec2 C = UV * 1.4 - 0.65 * fv2_x; // + offset stuff from bufferA
  vec2 Z = C;

  float maxIter = 100.0;
  float numIter =   0.0;
  for (; numIter < maxIter; ++numIter) {
    Z  = complexMul(Z, Z);
    Z += C;
    if (dot(Z, Z) > 16.0) {
      break;
    }
  }

  float  f = numIter/maxIter;
  f = pow(f, 1.0/3.0);
  vec3 rgb = vec3(f);

  rgb *= 1.0 - 0.1 * smoothstep(3.0/smallWay, 0.0, abs(f - 1.0));

  outRGBA = vec4(rgb, f);
}


// grimoire bindings
out vec4 fragColor; void main() { mainImage(fragColor, gl_FragCoord.xy); }
