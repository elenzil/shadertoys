// common stuff
const vec3  fv3_1   = vec3(1.0, 1.0, 1.0);
const vec3  fv3_0   = vec3(0.0, 0.0, 0.0);
const vec3  fv3_x   = vec3(1.0, 0.0, 0.0);
const vec3  fv3_y   = vec3(0.0, 1.0, 0.0);
const vec3  fv3_z   = vec3(0.0, 0.0, 1.0);
const vec2  fv2_1   = vec2(1.0, 1.0);
const vec2  fv2_0   = vec2(0.0, 0.0);
const vec2  fv2_x   = vec2(1.0, 0.0);
const vec2  fv2_y   = vec2(0.0, 1.0);
const float PI      = 3.14159265359;
const float TAU     = PI * 2.0;

// less common
const float camZoom    = 1.0;
const float rmMaxSteps = 50.0;
const float rmEpsilon  = 0.01;

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

// based on https://www.shadertoy.com/view/Wtf3Df
vec3 getRayDirection(in vec3 ro, in vec3 lookAt, in vec2 uv) {
  vec3 ol       = normalize(lookAt - ro);
  vec3 screenRt = cross(ol      , fv3_y); // world Up
  vec3 screenUp = cross(screenRt, ol   );
  vec3 rd       = normalize(uv.x * screenRt + uv.y * screenUp + ol * camZoom);
  return rd;
}

mat2 rot2(float t) {
  float s = sin(t);
  float c = cos(t);
  return mat2(s, c, -c, s);
}

float sdf(vec3 p) {
  float mi = 10.0;
  vec2 mp = p.xz;
  mp.x += 0.25;
  mp *= rot2(iTime * -1.2);
  mp *= 0.1;
  mp.x -= 0.25;  
  float iters = mandelEscapeIters(mp, mi);

  return p.y - iters/mi * 5.0 + sin(p.x * 0.1 + iTime) * 2.0;
}

vec3 march(in vec3 p, in vec3 rd, out float numSteps) {
  for (float numSteps = 0.0; numSteps < rmMaxSteps; ++numSteps) {
    float d = sdf(p);
    if (d < rmEpsilon) {
      return p;
    }
    p += rd * d;
  }
  return p;
}

void mainImage(out vec4 RGBA, in vec2 XY)
{
  float smallWay = min(iResolution.x, iResolution.y);
  vec2  uv = (XY * 2.0 - fv2_1 * iResolution.xy)/smallWay;
  float t  = iTime * TAU * 0.01;
  vec3  ro = vec3( vec2(cos(t), sin(t)) * 20.0, 20.0).xzy;
  vec3  la = vec3( 0.0, 0.0,  0.0);
  vec3  rd = getRayDirection(ro, la, uv);

  float numSteps;
  vec3 surf = march(ro, rd, numSteps);
  float dist = length(ro - surf);

  const float checkSize = 10.0;
  float bright = float((mod(surf.x, checkSize * 2.0) > checkSize) ^^ (mod(surf.z, checkSize * 2.0) > checkSize));
  bright = mix(bright, 0.5, clamp(0.0, 1.0, dist/180.0 + 0.1));

  RGBA.rgb = vec3(bright);
  RGBA.a   = 1.0;
}


// grimoire bindings
out vec4 fragColor; void main() { mainImage(fragColor, gl_FragCoord.xy); }
