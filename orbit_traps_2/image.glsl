// common stuff
const vec3 fv3_1  = vec3(1.0, 1.0, 1.0);
const vec3 fv3_0  = vec3(0.0, 0.0, 0.0);
const vec3 fv3_x  = vec3(1.0, 0.0, 0.0);
const vec3 fv3_y  = vec3(0.0, 1.0, 0.0);
const vec3 fv3_z  = vec3(0.0, 0.0, 1.0);
const vec2 fv2_1  = vec2(1.0, 1.0);
const vec2 fv2_0  = vec2(0.0, 0.0);
const vec2 fv2_x  = vec2(1.0, 0.0);
const vec2 fv2_y  = vec2(0.0, 1.0);
const float PI    = 3.14159265359;
const float TWOPI = PI * 2.0;

vec2 complexMul(in vec2 A, in vec2 B) {
  return vec2((A.x * B.x) - (A.y * B.y), (A.x * B.y) + (A.y * B.x));
}

struct POI {
  vec2  center;
  float range;
  float maxIter;
};
vec4 poiToVec4(in POI poi) {return vec4(poi.center, poi.range, poi.maxIter);}
POI vec4ToPOI(in vec4 v) {return POI(v.xy, v.z, v.w);}


float mandelEscapeIters(in vec2 C, in float maxIters) {
  vec2 Z = C;
  for (float n = 0; n < maxIters; n += 1.0) {
    Z  = complexMul(Z, Z) + C;
    if (dot(Z, Z) > 4.0) {
      return n;
    }
  }
  return maxIters;
}

void mainImage(out vec4 outRGBA, in vec2 XY)
{
  float smallWay = min(iResolution.x, iResolution.y);
  vec2 uv = (XY * 2.0 - fv2_1 * iResolution.xy)/smallWay;

  float t = iTime * 0.1;

  POI poi = vec4ToPOI(texelFetch(iChannel0, ivec2(2, 0), 0));
  
  vec2 C = uv * poi.range + poi.center;
  float f = mandelEscapeIters(C, poi.maxIter) / poi.maxIter;
  f = pow(f, 1.0/3.0);
  vec3 rgb = vec3(f);


  rgb *= 1.0 - 0.1 * smoothstep(3.0/smallWay, 0.0, abs(f - 1.0));

  rgb += texture(iChannel0, XY/iResolution.xy).rgb * 0.91;
  rgb /= 1.1;

  outRGBA = vec4(rgb, f);
}


// grimoire bindings
out vec4 fragColor; void main() { mainImage(fragColor, gl_FragCoord.xy); }
