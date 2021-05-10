// sky from @Gijs's [url=https://www.shadertoy.com/view/7dSSzy]Basic : Less Simple Atmosphere[/url].

// Fork of "mirascope" by elenzil. https://shadertoy.com/view/NdjXzw
// 2021-05-07 16:22:59



#ifdef GRIMOIRE
#include <common.glsl>
#endif

bool gDemoView  = false;
const bool gDebugView = false;
mat2 gSceneRot  = mat2(1.0, 0.0, 0.0, 1.0);
const float gutter = 0.175;
const float gutterInv = 1.0 - gutter;

// positive for cross-eyed, make negative for wall-eyed viewing.
const float stereoSeparation = 0.4;

struct pol3 {
    float rho;
    float tht;
    float phi;
};

pol3 sphericalFromCartesian(in vec3 cartesian) {
    pol3 ret;

    ret.tht = atan(cartesian.z, cartesian.x);
    ret.phi = acos(dot(normalize(cartesian), vec3(0.0, 1.0, 0.0))) - PI/2.0;
    ret.rho = length(cartesian);

    return ret;
}

float maxPart(vec3 v) {
    return max(v.x, max(v.y, v.z));
}

//--------------------------------------------------------------------------------

// direction to the light
vec3 gLightDirection = normalize(vec3(-1.0, 2.0, 0.5));

//--------------------------------------------------------------------------------

vec3  SUN_COLOR = vec3(1.0,1.0,1.0);
vec3  SKY_SCATTERING = vec3(0.1, 0.3, 0.7);
// vec3  SUN_VECTOR;
float SUN_ANGULAR_DIAMETER = 0.08;
float CAMERA_HEIGHT = -0.3;


// Consider an atmosphere of constant density & isotropic scattering 
// Occupying, in the y axis, from -infty to 0
// This shaders ``solves'' that atmosphere analytically.

float atmosphereDepth(vec3 pos, vec3 dir)
{
    return max(-pos.y, 0.0)/ max(dir.y, 0.0);
}

vec3 transmittance(float l)
{
    return exp(-l * SKY_SCATTERING);
}

vec3 simple_sun(vec3 dir)
{
    //sometimes |dot(dir, SUN_VECTOR)| > 1 by a very small amount, this breaks acos
    float a = acos(clamp(dot(dir, gLightDirection),-1.0,1.0));
    float t = 0.005;
    float e = smoothstep(SUN_ANGULAR_DIAMETER*0.5 + t, SUN_ANGULAR_DIAMETER*0.5, a);
    return SUN_COLOR * e;
}

vec3 simple_sky(vec3 p, vec3 d)
{
    float l = atmosphereDepth(p, d);
    vec3 sun = simple_sun(d) * transmittance(l);
    float f = 1.0 - d.y / gLightDirection.y;
    float l2 = atmosphereDepth(p, gLightDirection);
    vec3 sk = simple_sun(gLightDirection) * transmittance(l2) / f * (1.0 - transmittance(f*l));
    return sun + sk;
}

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



// https://www.iquilezles.org/www/articles/distfunctions/distfunctions.htm
float sdParabola( in vec2 pos, in float k )
{
    pos.x = abs(pos.x);
    
    float ik = 1.0/k;
    float p = ik*(pos.y - 0.5*ik)/3.0;
    float q = 0.25*ik*ik*pos.x;
    
    float h = q*q - p*p*p;
    float r = sqrt(abs(h));

    float x = (h>0.0) ? 
        // 1 root
        pow(q+r,1.0/3.0) - pow(abs(q-r),1.0/3.0)*sign(r-q) :
        // 3 roots
        2.0*cos(atan(r,q)/3.0)*sqrt(p);
    
    return length(pos-vec2(x,k*x*x)) * sign(pos.x-x);
}

float sdSphere( in vec3 pos, in float r ) {
    return length(pos) - r;
}


float sdMiraScope(in vec3 pos, in float separation, in float thickness, in float holeRadius) {
    // convert pos to 2D by revolving it around Y
    vec2 p = vec2(length(pos.xz), pos.y);

    // an up and down facing parabola, a little apart
    float sdTop = sdParabola(vec2(p.x, p.y + separation),  0.5);
    float sdBot = sdParabola(vec2(p.x, p.y - separation), -0.5);

    // intersected
    float sdMira = max(sdTop, sdBot);

    // onioned
    sdMira = abs(sdMira) - thickness;

    // slice off the top so we can see inside!
    // sdMira = max(sdMira, p.y - separation * 0.9);
    
    // cut a hole in the top so we can see inside!
    // this has somewhat less visibility into the interior compared to slicing,
    // but avoids long thin wedges.
    sdMira = opSubtraction(sdCappedCylinderPrecomputedQ(vec2(p.x, p.y - separation + thickness), holeRadius, separation * 0.2 + thickness * 3.0), sdMira);

    return sdMira;
}


float sdGridOfSpheres(in vec3 pos) {
    float num = 3.0;
    float lim = 0.3;
    float rad = 0.75 * lim / (num - 1.0);
     
    pos.y -= lim + rad - 0.4;
    
    float step = (lim * 2.0) / (num - 1.0);
    
    float d = 1e9;
    
    vec3 c = vec3(0.0);
    
    for (c.x = -lim; c.x <= lim; c.x += step) {
    for (c.y = -lim; c.y <= lim; c.y += step) {
    for (c.z = -lim; c.z <= lim; c.z += step) {
        d = min(d, sdSphere(pos - c, rad));
    }}}
    return d;
}

/*
from https://stackoverflow.com/a/26127012
def fibonacci_sphere(samples=1):

    points = []
    phi = math.pi * (3. - math.sqrt(5.))  # golden angle in radians

    for i in range(samples):
        y = 1 - (i / float(samples - 1)) * 2  # y goes from 1 to -1
        radius = math.sqrt(1 - y * y)  # radius at y

        theta = phi * i  # golden angle increment

        x = math.cos(theta) * radius
        z = math.sin(theta) * radius

        points.append((x, y, z))

    return points
*/
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
    
    const float num           = 50.0;
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
    return sdFibSphere(pos, 0.6, 0.1);
}

//-----------------------------------------------------------------------


// set up scene position of stuff once per pixel
const float gBevels        = 0.01;

vec3  gCamPos;
vec3  gPosMain;
vec3  gTablePos;
float gTableRad;
float gTableThick;
float gTableHoleRad;

void configMap() {
 
    gPosMain      = vec3(0.0, 0.3, 0.0);
    
    gTablePos     = vec3(0.0, -0.4, 0.0);
    
    float tableMod = smoothstep(1.0, -2.0, gCamPos.y - gTablePos.y);
    gTableRad     = 0.9;
    gTableThick   = 0.01 + 0.6 * tableMod;
    gTablePos.y   += 0.6 * tableMod;
    gTableHoleRad = (gTableRad - gBevels * 2.0) * tableMod;
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
    Q = opMinus(Q, vec2(sdCylinder(p, gTableHoleRad), 3.0));
    Q = opMinus(Q, vec2(sdSlab(p1, 0.05), 3.0));
    Q.x -= gBevels;
    
    Q = opUnion(Q, vec2(sdTheMainAttraction(p - gPosMain), 1.0));
    Q = opUnion(Q, vec2(sdSphere(p - gPosMain, 0.2), 3.0));


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


float calcDiffuseAmount(in vec3 p, in vec3 n) {
    return clamp(dot(n, gLightDirection), 0.0, 1.0);
}

const float AOFactorMin = 0.5;
const float AOFactorMax = 1.0;
float calcAOFactor(in vec3 p, in vec3 n) {
    const float sampleDist = 0.03;
    float dist = smoothstep(0.0, sampleDist, map(p + n * sampleDist).x);
    return mix(AOFactorMin, AOFactorMax, (dist));
}

float calcShadowLight(in vec3 p) {
    float t = march(p, gLightDirection).x;
    return t > 40.0 ? 1.0 : 0.0;
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
    vec3 col = dirToRGB(rd);
//  col = normalize(col);
    col = col * 0.3;
    vec3 ss = simple_sky(vec3(0.0, -0.3, 0.0), vec3(rd.x, rd.y, rd.z));
    col = mix(col, ss, 0.5);    
    col *= smoothstep(-0.01, 0.01, rd.y + 0.03) * 0.5 + 0.5;
    return col;
}

vec3 getAlbedo(in int material, in vec3 pCrt, in pol3 pPol) {
    if (material == 1) {
        vec3 rgb = dirToRGB2(normalize(pCrt - gPosMain));
       rgb /= length(rgb);
        return rgb;
    }
    else if (material == 3) {
        return vec3(0.2);
    }
    else {
        return vec3(1e9, 0.0, 1e9);
    }
}

vec3 getReflectivity(in int material, in vec3 pCrt, in pol3 pPol) {
    return vec3(0.0);
    if (material == 1) {
        return vec3(0.2);
    }
    else if (material == 2) {
        return vec3(0.0);
    }
    else if (material == 3) {
        return vec3(0.2);
    }
    else {
        return vec3(0.0, 1e9, 0.0);
    }
}

vec3 getEmissive(in int material, in vec3 pCrt, in pol3 pPol) {
    return vec3(0.0);
}


//------------------------------------------------------------------------------

vec3 render(in vec3 ro, in vec3 rd) {
    vec3 rgb = vec3(0.0);

    int bouncesLeft = 4;

    vec3 contributionLeft = vec3(1.0);

    while (bouncesLeft >= 0 && maxPart(contributionLeft) > 0.001) {
        bouncesLeft -= 1;
        vec2 q = march(ro, rd);
        vec3 p = ro + q.x * rd;
        if (length(p) > 150.0) {
            rgb += sky(rd) * contributionLeft;
            break;
        }

        vec3 normal = calcNormal(p);

        vec3 ptCrt = p;
        ptCrt.xz *= gSceneRot;
        pol3 ptSph = sphericalFromCartesian(ptCrt);

        int material = int(q.y);

        float incomingLight = 1.0;
        incomingLight = min(incomingLight, calcDiffuseAmount(p, normal));
        if (incomingLight > 0.0) {
            incomingLight = min(incomingLight, calcShadowLight(p + normal * closeEps * 2.0));
        }
        float ambient = 0.2 * calcAOFactor(p, normal);
        incomingLight += ambient;

        float fres = 0.4 + 0.8 * clamp(pow(1.0 - abs(dot(rd, normal) - 0.1), 2.0), 0.0, 1.0);
        
        fres = 1.0;

        vec3 reflectivity = fres * getReflectivity(material, ptCrt, ptSph);
        vec3 diffuse = incomingLight * getAlbedo(material, ptCrt, ptSph);
        vec3 emissive = getEmissive(material, ptCrt, ptSph);
        
        rgb += diffuse * (1.0 - reflectivity) * contributionLeft;
        rgb += emissive * contributionLeft;
        contributionLeft *= reflectivity;
          
        ro = p + normal * 0.05;
        rd = reflect(rd, normal);
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
 //   gDebugView      = !defaultView && (length(iMouse.xy) < iResolution.x * gutter);
    if (gDebugView) {
        camTht = sin(iTime * 0.10) * 0.1;
        camPhi = sin(iTime * 0.12) * 0.1;
    }
    else if (defaultView) {
        camPhi = -20.0 * DEG2RAD;
    }
    
    mat2 camThtRot2 = rot2(camTht);
    mat2 camPhiRot2 = rot2(camPhi);
    
    gDemoView = gDebugView || iMouse.x > iResolution.x * gutterInv;
    
    gSceneRot = rot2(gTime * PI * 2.0 / 30.0);
    // anchor the light to the camera
    gLightDirection.xz *= -camThtRot2;

    
    vec3 camPt = vec3(0.0, 0.0, -1.0);
    camPt.yz *= camPhiRot2;
    camPt.xz *= camThtRot2;
    camPt *= gDebugView ? 1.7 : 4.0;
    
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
