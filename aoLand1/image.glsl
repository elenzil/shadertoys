#ifdef GRIMOIRE
#include <common.glsl>
#endif

const int gPerfMaterials       = DEVEL;
const int gPerfSceneComplexity = DEVEL;
bool gDebugPerf = true;
mat2 gSceneRot  = mat2(1.0, 0.0, 0.0, 1.0);
const float gutter = 0.175;
const float gutterInv = 1.0 - gutter;

// positive for cross-eyed, make negative for wall-eyed viewing.
const float stereoSeparation = 0.4;

//--------------------------------------------------------------------------------


// I forget the location, but this pattern is from IQ.

vec2 opUnion(in vec2 q1, in vec2 q2) {
    return q1.x < q2.x ? q1 : q2;
}

vec2 opSubtraction(in vec2 q1, in vec2 q2) {
    return -q1.x > q2.x ? vec2(-q1.x, q1.y) : q2;
}

float opUnion( float d1, float d2 ) { return min(d1,d2); }

float opSubtraction( float d1, float d2 ) { return max(-d1,d2); }

float opIntersection( float d1, float d2 ) { return max(d1,d2); }

// swap args from stock subtraction().
vec2 opMinus( in vec2 q1, in vec2 q2 ) { return opSubtraction(q2, q1); }

//--------------------------------------------------------------------------------

// https://www.iquilezles.org/www/articles/distfunctions/distfunctions.htm
float sdCappedCylinder( vec3 p, float h, float r )
{
  vec2 d = abs(vec2(length(p.xz),p.y)) - vec2(h,r);
  return min(max(d.x,d.y),0.0) + length(max(d,0.0));
}

float sdCylinder( vec3 p, float r )
{
  return length(p.xz) - r;
}

float sdSlab(in vec3 p, float r) {
    return abs(p.y) - r;
}

float sdCappedCylinderPrecomputedQ(vec2 q, float h, float r)
{
  vec2 d = abs(q) - vec2(h,r);
  return min(max(d.x,d.y),0.0) + length(max(d,0.0));
}

// https://www.iquilezles.org/www/articles/distfunctions/distfunctions.htm
float sdCrateBox( vec3 p, vec3 b, float e )
{
       p = abs(p  )-b;
  vec3 q = abs(p+e)-e;
  return min(min(
      length(max(vec3(p.x,q.y,q.z),0.0))+min(max(p.x,max(q.y,q.z)),0.0),
      length(max(vec3(q.x,p.y,q.z),0.0))+min(max(q.x,max(p.y,q.z)),0.0)),
      length(max(vec3(q.x,q.y,p.z),0.0))+min(max(q.x,max(q.y,p.z)),0.0));
}

float sdSphere( in vec3 pos, in float r ) {
    return length(pos) - r;
}


// adapted from https://stackoverflow.com/a/26127012
float sdFibSphere(in vec3 pos, in float rad1, in float rad2) {

    float d = 1e9;
    
    // early-out.
    // this approach to bounding volume destroys exactness of SDF.
    // discussion in https://www.shadertoy.com/view/ssBXRG
    float sdBounds = abs(sdSphere(pos, rad1)) - rad2;
    if (sdBounds > rad2 * 0.2) {
        return sdBounds;
    }

    // golden angle
    const float phi = 3.14159265359 * (3.0 - sqrt(5.0));
    
    const float num           = gPerfSceneComplexity == DEVEL ? 10 : (gPerfSceneComplexity == DRAFT ? 30 : 50);
    const float num_minus_one = num - 1.0;
    
    for (float n = 0.0; n < num; ++n) {
        // y goes from 1 to -1
        float y = 1.0 - (n / num_minus_one * 2.0);
        
        // radius at y
        float radius = sqrt(1.0 - y * y);
        
        // shrink the ones near the top
        float rad2Fac = smoothstep(1.0, 0.0, abs(y)) * 0.4 + 0.6;
        
        float theta = phi * n;
        
        float x = cos(theta) * radius;
        float z = sin(theta) * radius;
        
        d = min(d, sdSphere(pos - vec3(x, y, z) * rad1, rad2 * rad2Fac));
    }
    
    return d;
}
    

float sdTheMainAttraction(in vec3 pos) {
    const vec3 fibPos = vec3(0.0, 0.06, 0.0);
    return sdFibSphere(pos - fibPos, 0.6, 0.18);

}

//-----------------------------------------------------------------------


// set up scene position of stuff once per pixel
const float gBevels        = 0.02;

vec3  gCamPos;
vec3  gPosMain;
vec3  gTablePos;
float gTableRad;
float gTableThick;

void configMap() {
 
    gPosMain      = vec3(0.0, 0.3, 0.0);
    
    gTablePos     = vec3(0.0, -0.4, 0.0);
    
    float tableMod = smoothstep(1.0, -2.0, gCamPos.y - gTablePos.y);
    gTableRad     = 0.9;
    gTableThick   = 0.01;
}

// return.x = distance
// return.y = material
vec2 map(in vec3 p) {

    p.xz *= gSceneRot;

    vec2 Q  = vec2(1e9, 0.0);
    const float modSize = 0.3;
    vec3 p1 = vec3(p.x, mod(p.y + modSize / 2.0, modSize) - modSize / 2.0, p.z);

    
    // table
    Q = opUnion(Q, vec2(sdCappedCylinder(p    -       gTablePos, gTableRad, gTableThick), 3.0));    
    Q.x -= gBevels;
    
    Q = opUnion(Q, vec2(sdTheMainAttraction(p - gPosMain), 1.0));

    return Q;
}

const float closeEps = 0.001;

vec2 march(in vec3 ro, in vec3 rd) {
    const int maxSteps = 100;

    vec2 Q = vec2(1e9);

    vec3 p = ro;
    float t = 0.0;
    for (int n = 1; n <= maxSteps; ++n) {
        Q = map(ro + rd * t);
        float closeEnoughEps = (n == maxSteps ? 0.2 : closeEps);
        if (Q.x < closeEnoughEps) {
            return vec2(t, Q.y);
        }
        t += Q.x;
        if (t > 200.0) {
            return vec2(t, Q.y);
        }
    }
    return vec2(t, Q.y);
}


// IQ: https://www.iquilezles.org/www/articles/normalsSDF/normalsSDF.htm
vec3 calcNormal( in vec3 p ) // for function f(p)
{
    const float h = 0.002;      // replace by an appropriate value
    vec3 n = vec3(0.0);
    for( int i=ZERO; i<4; i++ )
    {
        vec3 e = 0.5773*(2.0*vec3((((i+3)>>1)&1),((i>>1)&1),(i&1))-1.0);
        n += e * map(p + e*h).x;
    }
    return normalize(n);
}


const float AOFactorMin = 0.5;
const float AOFactorMax = 1.0;
float calcAOFactor(in vec3 p, in vec3 n) {
    const float sampleDist = 0.03;
    float dist = smoothstep(0.0, sampleDist, map(p + n * sampleDist).x);
    return mix(AOFactorMin, AOFactorMax, (dist));
}

vec3 dirToRGB(in vec3 rd) {
    float tht = atan(rd.z, rd.x);
    float phi = acos(dot(normalize(rd), vec3(0.0, 1.0, 0.0)));
    vec3 col = rd * 0.5 + 0.5;
    col *= smoothstep(0.002, -0.002, sin(tht       * 4.0)) * -0.3 + 1.0;
    col *= smoothstep(0.002, -0.002, sin(phi * 2.0 * 4.0)) * -0.3 + 1.0;
    col = mix(col, col / max(col.r, max(col.g, col.b)), 0.2);
    return col;
}

vec3 dirToRGB2(in vec3 rd) {
    vec3 col = rd * 0.5 + 0.5;
    return col;
}

vec3 sky(in vec3 rd) {
    return vec3(0.7);
    vec3 col = dirToRGB(rd);
//  col = normalize(col);
    col = col * 0.3;
    col *= smoothstep(-0.01, 0.01, rd.y + 0.03) * 0.5 + 0.5;
    return col;
}

//------------------------------------------------------------------------------

vec3 render(in vec3 ro, in vec3 rd) {
    vec3 rgb = vec3(0.0);

    int bouncesLeft = 2;

    vec3 contributionLeft = vec3(1.0);

    while (bouncesLeft >= 0 && maxComponent(contributionLeft) > 0.001) {
        bouncesLeft -= 1;
        vec2 q = march(ro, rd);
        vec3 p = ro + q.x * rd;
        if (length(p) > 150.0) {
            rgb += sky(rd) * contributionLeft;
            break;
        }

        vec3 normal = calcNormal(p);

        float reflectivity = 0.5;


        contributionLeft *= reflectivity;
          
        ro = p + normal * 0.05;
        rd = reflect(rd, normal);
    }

    if (bouncesLeft < 0) {
        rgb += sky(rd) * contributionLeft;
    }

    return rgb;
}



void mainImage( out vec4 RGBA, in vec2 XY ) {
    vec4 persistedInfo = texelFetch(iChannel0, ivec2(0, 0), 0);
    
    bool stereo = iMouse.x < iResolution.x * gutter && iMouse.y > iResolution.y * gutterInv;
    bool leftEye = XY.x > iResolution.x / 2.0;
    
    vec2 Res = iResolution.xy;
    Res.x   *= stereo ? 0.5 : 1.0;
    XY.x    -= (stereo && leftEye) ? iResolution.x / 2.0 : 0.0;

    setupCoords(Res, 4.2);
    setupTime(iTime);
    vec2  uv        = worldFromScreen(XY);
    vec2  ms        = persistedInfo.xy / iResolution.xy * 2.0 - 1.0;
    float smoothEps = gWorldFromScreenFac * 2.0;

    // look-from and look-to points
    // right-handed system where x is right, y is up, z is forward.
    float t = gTime * 0.23;
    vec3 trgPt = vec3(0.0, 0.1, 0.0);
    
    float camTht = -ms.x * PI * 1.25;
    float camPhi = ms.y;
    
    bool defaultView = stereo;
    if (false) {
        // no-op
    }
    else if (defaultView) {
        camPhi = -20.0 * DEG2RAD;
    }
    
    mat2 camThtRot2 = rot2(camTht);
    mat2 camPhiRot2 = rot2(camPhi);
        
    gSceneRot = rot2(gTime * PI * 2.0 / 30.0);

    
    vec3 camPt = vec3(0.0, 0.0, -1.0);
    camPt *= 5.0;
    camPt.yz *= camPhiRot2;
    camPt.xz *= camThtRot2;
    
    // camera's forward, right, and up vectors. right-handed.
    vec3 camFw = normalize(trgPt - camPt);
    vec3 camRt = normalize(cross(camFw, vec3(0.0, 1.0, 0.0)));
    vec3 camUp = cross(camRt, camFw);
    
    if (stereo) {
        camPt += camRt * (leftEye ? -1.0 : 1.0) * stereoSeparation / 2.0;
        camFw = normalize(trgPt - camPt);
        camRt = normalize(cross(camFw, vec3(0.0, 1.0, 0.0)));
        camUp = cross(camRt, camFw);
    }
    
    gCamPos = camPt;
    configMap();

    // ray origin and direction
    vec3 ro    = camPt;
    vec3 rd    = normalize(camFw + uv.x * camRt + uv.y * camUp);

    vec3 rgb = render(ro, rd);

    // Vignette from Ippokratis https://www.shadertoy.com/view/lsKSWR
    vec2 pq = XY / Res;   
    pq *=  1.0 - pq.yx;    
    float vig = pq.x*pq.y * 200.0;    
    vig = pow(vig, 0.15);
    rgb *= vig;

    rgb = sqrt(rgb);

    RGBA = vec4(rgb, 1.0);
}


#ifdef GRIMOIRE
out vec4 fragColor; void main() { mainImage(fragColor, gl_FragCoord.xy); }
#endif
