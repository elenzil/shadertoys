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
const float MAX_FLOAT = intBitsToFloat(0x7f7fffff);


// less common
const float rmMaxSteps = 150.0;
const float rmMaxDist  = 150.0;
const float rmEpsilon  =   0.01;
const float grEpsilon  =   0.001;

const vec3  fogColor   = vec3(0.0);
const float shadowFac  = 0.02;           // 1.0 for no shadows, 0.0 for black.

float gT = 0.0;

#define mat_no_hit -1
#define mat_0       0
#define mat_1       1
#define mat_2       2
#define mat_3       3
#define mat_4       4

vec3 colors[7] = vec3[7] (
    vec3(1.0, 1.0, 0.0),          // yellowish
    vec3(0.5, 1.0, 1.0),          // cyanish
    vec3(0.4, 0.1, 0.1),          // reddish
    vec3(0.7, 0.0, 0.1),          // magenta
    vec3(0.1, 0.9, 0.3),          // greenish
    vec3(1.0, 0.5, 0.7),          // pinkish
    vec3(0.8, 0.8, 0.8)           // whitish
);

struct SurfaceHit {
    int  material;
    vec3 position;
};

// from IQ's https://www.shadertoy.com/view/XlcSz2
float checkers2D(vec2 p)
{
    vec2 ddx = dFdx(p); 
    vec2 ddy = dFdy(p); 

    vec2 w = max(abs(ddx), abs(ddy)) + 0.01;
    vec2 i = 2.0*(abs(fract((p-0.5*w)/2.0)-0.5)-abs(fract((p+0.5*w)/2.0)-0.5))/w;
    return 0.5 - 0.5*i.x*i.y;                  
}

vec3 albedo(in SurfaceHit sh) {
    switch(sh.material) {
        default:
            return vec3(0e0, 0e0, 1e3);
        case mat_no_hit:
            return vec3(1e3, 0e0, 1e3);
        case mat_0:
            return colors[4] * (0.7 + 0.3 * checkers2D(vec2(sh.position.y - gT * 3.0, 0.1) * 1.0));
        case mat_1:
            return colors[5] * (0.7 + 0.3 * checkers2D(vec2(sh.position.y + gT * 3.0, 0.1) * 1.0));
        case mat_2:
            return mix(colors[1], colors[2], checkers2D(sh.position.xz * 0.1));
        case mat_3:
            return colors[3];
        case mat_4:
            return colors[6];
    }
}


// based on https://www.shadertoy.com/view/Wtf3Df
vec3 getRayDirection(in vec3 ro, in vec3 lookAt, in vec2 uv, float zoom) {
  vec3 ol       = normalize(lookAt - ro);
  vec3 screenRt = cross(ol      , fv3_y); // world Up
  vec3 screenUp = cross(screenRt, ol   );
  vec3 rd       = normalize(uv.x * screenRt + uv.y * screenUp + ol * zoom);
  return rd;
}

float sdfSphere(in vec3 p, float radius) {
  return length(p) - radius;
}

float sdfCylinderX(in vec3 p, float radius) {
  return length(p.yz) - radius;
}

float sdfFloor(in vec3 p, float height) {
  return p.y - height;
}

float sdf(in vec3 p, out int material) {
  const float sphRad = 5.0;

  float d = MAX_FLOAT;
  float D;
  int   m = mat_no_hit;

  D = sdfSphere(p + fv3_x * -0.3 * sphRad,  sphRad);
  d = min(d, D);
  m = d == D ? mat_0 : m;

  D = sdfSphere(p + fv3_x * +0.3 * sphRad,  sphRad);
  d = max(d, 1.0-D);
  m = d == 1.0-D ? mat_1 : m;

  D = sdfCylinderX(p, sphRad * 0.25);
  d = max(d, 1.0-D);
  m = d == 1.0-D ? mat_3 : m;

  D = sdfSphere(p + fv3_x * -0.9 * sphRad,  sphRad * 0.125);
  d = min(d, D);
  m = d == D ? mat_4 : m;

  D = sdfFloor (p, -sphRad);
  d = min(d, D);
  m = d == D ? mat_2 : m;

  material = m;

  return d;
}

// from http://jamie-wong.com/2016/07/15/ray-marching-signed-distance-functions
vec3 estimateNormal(vec3 p) {
  const float e = grEpsilon;
  int unused;
  return normalize(vec3(
    sdf(vec3(p.x + e, p.y    , p.z     ), unused) - sdf(vec3(p.x - e, p.y    , p.z    ), unused),
    sdf(vec3(p.x    , p.y + e, p.z     ), unused) - sdf(vec3(p.x    , p.y - e, p.z    ), unused),
    sdf(vec3(p.x    , p.y    , p.z  + e), unused) - sdf(vec3(p.x    , p.y    , p.z - e), unused)
  ));
}


SurfaceHit march(in vec3 p, in vec3 rd, out float numSteps) {
  SurfaceHit sh; // = SurfaceHit(mat_no_hit, vec3(0.0));

  float distTotal = 0.0;
  for (numSteps = 0.0; (numSteps < rmMaxSteps) && (distTotal <= rmMaxDist); ++numSteps) {
    int mat;
    float d = sdf(p, mat);
    if (d < rmEpsilon) {
      sh.material = mat;          
      sh.position = p;
      return sh;
    }
    p += rd * d;
    distTotal += d;
  }
  sh.material = mat_no_hit;
  sh.position = p;
  return sh;
}

void mainImage(out vec4 RGBA, in vec2 XY)
{
  RGBA.a   = 1.0;

  float smallWay = min(iResolution.x, iResolution.y);
  vec2  uv = (XY * 2.0 - fv2_1 * iResolution.xy)/smallWay;
  gT  = iTime * TAU * 0.01;
  vec3  ro = vec3( vec2(cos(gT), sin(gT)) * 30.0, 12.0).xzy;
  vec3  la = vec3( 0.0, 0.0, 0.0);
  float zoom = 3.2;
  vec3  rd = getRayDirection(ro, la, uv, zoom);

  vec3  rgb = fogColor;

  vec3  ld = normalize(vec3(sin(gT * -3.0), 2.0 * (sin(gT * 5.0) * 0.49 + 0.51), cos(gT * -3.0)));

  float numSteps;
  SurfaceHit sh = march(ro, rd, numSteps);
  if (sh.material != mat_no_hit) {
    rgb = albedo(sh);

    vec3 nrm = estimateNormal(sh.position);

    // shading
    float shadeFac = max(shadowFac, dot(ld, nrm));

    // shadow
    float unused;
    SurfaceHit shsh = march(sh.position + nrm * 0.1, ld, unused);
    if (shsh.material != mat_no_hit) {
      shadeFac = shadowFac;
    }

    rgb *= shadeFac;

    // fog
    float dist = length(ro - sh.position);
    rgb = mix(rgb, fogColor, clamp(dist/rmMaxDist - 0.1, 0.0, 1.0));
  }

  // gamma
  rgb = pow(rgb, vec3(0.4545));
  
  // ray steps
  // RGBA.r += numSteps / rmMaxSteps;

  RGBA.rgb = rgb;
}


// grimoire bindings
out vec4 fragColor; void main() { mainImage(fragColor, gl_FragCoord.xy); }
