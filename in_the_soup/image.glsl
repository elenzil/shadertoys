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
const float rmMaxSteps = 100.0;
const float rmMaxDist  = 180.0;
const float rmEpsilon  =   0.001;
const float grEpsilon  =   0.001;
#define SMOOTH_MANDEL 1

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
  for (float n = 0.0; n < maxIters; n += 1.0) {
    Z  = complexMul(Z, Z) + C;
    if (dot(Z, Z) > 4.0) {
      return n;
    }
  }
  return maxIters;
}

// adapted from IQ
// http://iquilezles.org/www/articles/distancefractals/distancefractals.htm
float mandelDist(in vec2 c, float numIters)
{
  vec2  z = vec2(0.0, 0.0);
  vec2 dz = vec2(0.0, 0.0);
  
  float m2;
  for (float n = 0.0; n < numIters; ++n) {
    dz = 2.0 * complexMul(z, dz) + fv2_x;
    z  = complexMul(z, z) + c;

    m2 = dot(z, z);
    if (m2 > 1.0e10) {
      break;
    }
  }
  
  // distance estimation: G/|G'|
  return sqrt(m2 / dot(dz, dz)) * 0.5 * log(m2);
}

// based on https://www.shadertoy.com/view/Wtf3Df
vec3 getRayDirection(in vec3 ro, in vec3 lookAt, in vec2 uv, float zoom) {
  vec3 ol       = normalize(lookAt - ro);
  vec3 screenRt = cross(ol      , fv3_y); // world Up
  vec3 screenUp = cross(screenRt, ol   );
  vec3 rd       = normalize(uv.x * screenRt + uv.y * screenUp + ol * zoom);
  return rd;
}

mat2 rot2(float t) {
  float s = sin(t);
  float c = cos(t);
  return mat2(s, c, -c, s);
}

float sdfCircle2D(in vec2 p, in vec2 c, float r) {
  return length(p - c) - r;
}

float sdf(in vec3 p, out float bright) {
  float mi = 20.0;
  vec2 mp = p.xz;
  mp.x += 0.35;
  mp *= rot2(iTime * -0.2);
  mp *= 0.05;
  mp.x -= 0.25;  
  bright = 1.0;
  #if SMOOTH_MANDEL
  float iters        = mandelDist(mp, mi);
  bright = smoothstep(-0.001, 0.001, iters);
  iters = max(0.0, iters);
  iters = 1.0 / (iters + 0.1);
  float mandelHeight = 0.4 * mi;
  #else
  float iters        = mandelEscapeIters(mp, mi);
  float mandelHeight =  2.0;
  #endif

  // altitude above plane
  float dist = p.y;

  // some waves
  dist += sin(p.x * 0.1 + iTime) * 2.0;

  // the mandelbrot set
  dist -= iters/mi * mandelHeight;

  /*
  // some pillars
  const float pillarDist = 60.0;
  const float pillarRad  = 10.0;
  dist = min(dist, sdfCircle2D(p.xz, pillarDist * vec2(-1.0, -1.0), pillarRad));
  dist = min(dist, sdfCircle2D(p.xz, pillarDist * vec2(-1.0,  1.0), pillarRad));
  dist = min(dist, sdfCircle2D(p.xz, pillarDist * vec2( 1.0,  1.0), pillarRad));
  dist = min(dist, sdfCircle2D(p.xz, pillarDist * vec2( 1.0, -1.0), pillarRad));
  */

  return dist;
}

// from http://jamie-wong.com/2016/07/15/ray-marching-signed-distance-functions
vec3 estimateNormal(vec3 p) {
  const float e = grEpsilon;
  float unused;
  return normalize(vec3(
    sdf(vec3(p.x + e, p.y    , p.z     ), unused) - sdf(vec3(p.x - e, p.y    , p.z    ), unused),
    sdf(vec3(p.x    , p.y + e, p.z     ), unused) - sdf(vec3(p.x    , p.y - e, p.z    ), unused),
    sdf(vec3(p.x    , p.y    , p.z  + e), unused) - sdf(vec3(p.x    , p.y    , p.z - e), unused)
  ));
}


vec3 march(in vec3 p, in vec3 rd, out float numSteps, out float bright) {
  float distTotal = 0.0;
  for (numSteps = 0.0; numSteps < rmMaxSteps; ++numSteps) {
    float d = sdf(p, bright);
    if ((d < rmEpsilon) || (distTotal > rmMaxDist)) {
      return p;
    }
    p += rd * d;
    distTotal += d;
  }
  return p;
}

void mainImage(out vec4 RGBA, in vec2 XY)
{
  RGBA.a   = 1.0;

  float smallWay = min(iResolution.x, iResolution.y);
  vec2  uv = (XY * 2.0 - fv2_1 * iResolution.xy)/smallWay;
  float t  = iTime * TAU * 0.01;
  vec3  ro = vec3( vec2(cos(t), sin(t)) * 40.0, 10.0).xzy;
  vec3  la = vec3( 0.0, 0.0,  0.0);
  const float zoom = 3.2;
  vec3  rd = getRayDirection(ro, la, uv, zoom);

  float numSteps;
  float sdfBright;
  vec3 surf = march(ro, rd, numSteps, sdfBright);
  float dist = length(ro - surf);

  const float checkSize = 20.0;
  // float bright = float((mod(surf.x, checkSize * 2.0) > checkSize) ^^ (mod(surf.z, checkSize * 2.0) > checkSize));
  float bright = 1.0;
  bright = bright * 0.05 + 0.95;
 // bright = 0.95;

  // shading
  bright *= max(0.3, dot(fv3_x, estimateNormal(surf)));

  vec3 rgb = vec3(bright);

  rgb.rg *= sdfBright * 0.7 + 0.3;
  rgb.b  *= sdfBright * 0.3 + 0.7;


  // fog
  rgb *= 1.0 + surf.y * 0.2 - 0.5;
  rgb = mix(rgb, vec3(0.5), clamp(dist/rmMaxDist - 0.1, 0.0, 1.0));

  // gamma
  rgb = pow(rgb, vec3(0.4545));
  
  // ray steps
  // RGBA.r += numSteps / rmMaxSteps;

  RGBA.rgb = rgb;

}


// grimoire bindings
out vec4 fragColor; void main() { mainImage(fragColor, gl_FragCoord.xy); }
