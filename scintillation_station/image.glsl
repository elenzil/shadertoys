/*
    scintillation station
*/

// common stuff
const vec3  fv3_1      = vec3(1.0, 1.0, 1.0);
const vec3  fv3_0      = vec3(0.0, 0.0, 0.0);
const vec3  fv3_x      = vec3(1.0, 0.0, 0.0);
const vec3  fv3_y      = vec3(0.0, 1.0, 0.0);
const vec3  fv3_z      = vec3(0.0, 0.0, 1.0);
const vec2  fv2_1      = vec2(1.0, 1.0);
const vec2  fv2_0      = vec2(0.0, 0.0);
const vec2  fv2_x      = vec2(1.0, 0.0);
const vec2  fv2_y      = vec2(0.0, 1.0);
const float PI         = 3.14159265359;
const float TAU        = PI * 2.0;
const float DEG_TO_RAD = TAU / 360.0;
const float MAX_FLOAT  = intBitsToFloat(0x7f7fffff);


// less common
const float rmMaxSteps = 600.0;
const float rmMaxDist  = 100.0;
const float fgMaxDist  = 250.0;
const float rmEpsilon  =   0.001;
const float grEpsilon  =   0.00001;

const float shadowFac  = 0.1;           // 1.0 for no shadows, 0.0 for black.
const vec3  clr_fog    = vec3(shadowFac);
const float sphRad     = 5.0;

#define SHADING 1
#define SHADOWS 1


float gT = 0.0;

#define mat_no_hit -1
#define mat_0       0
#define mat_1       1
#define mat_2       2
#define mat_3       3

#define clr_cyn vec3(0.5, 0.8, 0.8)
#define clr_er1 vec3(1e3, 0e0, 0e0)
#define clr_er2 vec3(1e3, 0e0, 1e3)
#define clr_er3 vec3(0e0, 0e0, 1e3)
#define clr_grn vec3(0.1, 0.9, 0.3)
#define clr_mag vec3(0.7, 0.0, 0.1)
#define clr_pnk vec3(1.0, 0.5, 0.7)
#define clr_red vec3(0.4, 0.2, 0.2)
#define clr_wht vec3(0.8, 0.8, 0.8)
#define clr_yel vec3(1.0, 1.0, 0.0)

struct SurfaceHit {
    int  material;
    vec3 position;
};

mat2 rot2(float rads) {
  float s = sin(rads);
  float c = cos(rads);
  return mat2(s, c, -c, s);
}

// from IQ's https://www.shadertoy.com/view/XlcSz2
float checkers2D(vec2 p)
{
    vec2 ddx = dFdx(p); 
    vec2 ddy = dFdy(p); 

    vec2 w = max(abs(ddx), abs(ddy)) + 0.01;
    vec2 i = 2.0*(abs(fract((p-0.5*w)/2.0)-0.5)-abs(fract((p+0.5*w)/2.0)-0.5))/w;
    return 0.5 - 0.5*i.x*i.y;                  
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

// from IQ's https://www.iquilezles.org/www/articles/distfunctions/distfunctions.htm
float sdfBox(in vec3 p, in vec3 b)
{
  vec3 d = abs(p) - b;
  return length(max(d, 0.0))
         + min(max(d.x, max(d.y, d.z)), 0.0); // remove this line for an only partially signed sdf 
}


float sdfItems(in vec3 p, out int material) {
  float d = MAX_FLOAT;
  float D;
  int   m = mat_no_hit;

  D = sdfBox(p + fv3_y * -2.0,  vec3(sphRad));
  d = min(d, D);
  m = d == D ? mat_3 : m;

  D = sdfBox(p + fv3_y * (-2.0 + sphRad *  0.0 / 5.0), vec3(1e3, sphRad / 5.0, 1e3));
  d = max(d, -D);

  D = sdfBox(p + fv3_y * (-2.0 + sphRad *  3.0 / 5.0), vec3(1e3, sphRad / 5.0, 1e3));
  d = max(d, -D);

  D = sdfBox(p + fv3_y * (-2.0 + sphRad * -3.0 / 5.0), vec3(1e3, sphRad / 5.0, 1e3));
  d = max(d, -D);

  material = m;

  return d;
}

float sdf(in vec3 p, out int material) {
  float D;
  int   m;

  float d = sdfItems(p, m);

  D = sdfFloor (p, -sphRad - 1.0);
  d = min(d, D);
  m = d == D ? mat_1 : m;

  material = m;

  return d;
}

float sdfItems(in vec3 p) {
    int unused;
    return sdfItems(p, unused);
}

float sdf(in vec3 p) {
    int unused;
    return sdf(p, unused);
}

vec3 albedo(in SurfaceHit sh) {
    if (false) {
        // noop
    }
    else if (sh.material == mat_no_hit) {
        return clr_fog;
    }
    else if (sh.material == mat_0) {
        return clr_pnk * (0.7 + 0.3 * checkers2D(vec2(sh.position.y - gT * 3.0, 0.1) * 1.0));
    }
    else if (sh.material == mat_1) {
        float dst = sdfItems(vec3(sh.position.x, 0.0, sh.position.z));
        vec3 ret;
        if (dst > 0.0) {
          ret = mix(clr_red, clr_cyn, pow(cos(1.0 * dst) * 0.5 + 0.5, 8.0));
        }
        else {
          ret = mix(clr_grn * 0.1, clr_cyn * 0.1, pow(cos(1.0 * dst) * 0.5 + 0.5, 8.0));
        }
        return ret;
    }
    else if (sh.material == mat_2) {
        return mix(clr_yel, clr_yel * 2.0, checkers2D(vec2(sh.position.y - gT * 3.0, 0.1) * 1.0));
    }
    else if (sh.material == mat_3) {
        return clr_grn;
    }
    else {
        return clr_er1;
    }
}

// from http://jamie-wong.com/2016/07/15/ray-marching-signed-distance-functions
vec3 estimateNormal(in vec3 p) {
  const float e = grEpsilon;
  return normalize(vec3(
    sdf(vec3(p.x + e, p.y    , p.z     )) - sdf(vec3(p.x - e, p.y    , p.z    )),
    sdf(vec3(p.x    , p.y + e, p.z     )) - sdf(vec3(p.x    , p.y - e, p.z    )),
    sdf(vec3(p.x    , p.y    , p.z  + e)) - sdf(vec3(p.x    , p.y    , p.z - e))
  ));
}

vec3 fixNormal(in vec3 p, in vec3 nrm) {
  vec3[6] candidates = vec3[6] (
    fv3_x, fv3_y, fv3_z, -fv3_x, -fv3_y, -fv3_z
  );

  int   closestNdx = 0;
  float closestAmt = -MAX_FLOAT;

  for (int n = 0; n < 6; ++n) {
    float dp = dot(candidates[n], nrm);
    if (dp > closestAmt) {
      closestAmt = dp;
      closestNdx = n;
    }
  }

  return candidates[closestNdx];
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
    gT  = iTime * TAU * 0.01;
    RGBA.a   = 1.0;

    vec2 xy = XY;

    float pixelation = floor(fract(gT) * 4.0 + 1.0);
    xy = floor(xy / pixelation + 0.5) * pixelation;

    float smallWay = min(iResolution.x, iResolution.y);
    vec2  uv = (xy * 2.0 - fv2_1 * iResolution.xy)/smallWay;
    float camAngDeg = gT * 100.0;
    float camDist = 30.0;
    vec3  ro = vec3(camDist * cos(camAngDeg * DEG_TO_RAD), 12.0, camDist * sin(camAngDeg * DEG_TO_RAD));
    vec3  la = vec3( 0.0, 0.0, 0.0);
    float zoom = 3.2;
    vec3  rd = getRayDirection(ro, la, uv, zoom);

    vec3  rgb = clr_fog;

    float lightAngDeg =  gT * -100.0 + 90.0;

    vec3  ld = normalize(vec3(sin(lightAngDeg * DEG_TO_RAD), 1.0, cos(lightAngDeg * DEG_TO_RAD)));

    float numSteps;
    SurfaceHit sh = march(ro, rd, numSteps);
    rgb = albedo(sh);

    vec3 nrm = estimateNormal(sh.position - rd * grEpsilon * 2.0);

    if (XY.x > iResolution.x / 2.0) {
      nrm = fixNormal(sh.position, nrm);
    }

    float shadeFac = 1.0;

    #if SHADING
    // shading
    shadeFac = max(shadowFac, dot(ld, nrm));
    #endif

    float unused;
    #if SHADOWS
    // shadow
    SurfaceHit shsh = march(sh.position + nrm * 0.01, ld, unused);
    if (shsh.material != mat_no_hit) {
        shadeFac = shadowFac;
    }
    #endif

    rgb *= shadeFac;

    // fog
    float dist = length(ro - sh.position);
    rgb = mix(rgb, clr_fog, clamp(dist/fgMaxDist - 0.1, 0.0, 1.0));

    // visible borders
    if (abs(XY.x - iResolution.x / 2.0) < 1.5) {
        rgb = vec3(0.0);
    }

    // gamma
    // rgb = pow(rgb, vec3(0.4545));
    rgb = pow(rgb, vec3(0.6));
  
    // ray steps
    // RGBA.r += numSteps / rmMaxSteps;

    RGBA.rgb = rgb;
}


// grimoire bindings
out vec4 fragColor; void main() { mainImage(fragColor, gl_FragCoord.xy); }
