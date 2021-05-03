// @oneshade's recent parabola stuff made me wonder if a working MiraScope was possible.
// This was previously done by @benburrill [url]https://www.shadertoy.com/view/wtKGzd[/url] , that I could find.
// UL: Cross-eyed stereo.
// LL: Cut-Away.
// R: Matte interior.


#ifdef GRIMOIRE
#include <common.glsl>
#endif

bool gDemoView  = false;
bool gDebugView = false;
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

//-----------------------------------------------------------------------


// set up scene position of stuff once per pixel
const float gMiraThickness = 0.01;
const float gMiraSep       = 0.3;
const float gMiraHole      = 0.25;
const float gTableThick    = 0.01;


vec3 gPosMira;
vec3 gPosColumn;
vec3 gPosCrate;
vec3 gCrateSize;
vec3 gPosTable;

void configMap() {
    const float columnDist = 0.565;
    const float crateSize = 0.07;
    const float crateLift = 0.014;
 
    gPosMira   = vec3(0.0);
    gPosColumn = vec3(columnDist, -0.22, columnDist);
    gPosCrate  = vec3(0.0, -gMiraSep + crateSize + gMiraThickness + crateLift, 0.0);
    gCrateSize = vec3(crateSize);
    
    gPosTable  = vec3(0.0, - gMiraSep - gMiraThickness - gTableThick - 0.1, 0.0);
}

// return.x = distance
// return.y = material
vec2 map(in vec3 p) {

    p.xz *= gSceneRot;

    vec2 Q = vec2(1e9, 0.0);


    // mirascope
    Q = opUnion(Q, vec2(sdMiraScope(p - gPosMira, gMiraSep, gMiraThickness, gMiraHole), 1.0)) ;

    // 4 colums
    vec3 pAbs = vec3(abs(p.xz), p.y).xzy;
    Q = opUnion(Q, vec2(sdCappedCylinder(pAbs - gPosColumn, 0.03, 0.4), 3.0));
    
    if (gDebugView) {
        // slice off half the mirascope + columns
        Q = opSubtraction(vec2(p.z, 2), Q);
    }

    Q = opUnion(Q, vec2(sdCrateBox(p - gPosCrate, vec3(gCrateSize), 0.0) - 0.01, 4.0));
    Q = opUnion(Q, vec2(sdCappedCylinder(p    -       gPosTable, 0.9, gTableThick), 3.0));    

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

vec3 lightDirection = normalize(vec3(1.0, -4.0, -0.5));

float calcDiffuseAmount(in vec3 p, in vec3 n) {
    return clamp(dot(n, -lightDirection), 0.0, 1.0);
}

const float AOFactorMin = 0.5;
const float AOFactorMax = 1.0;
float calcAOFactor(in vec3 p, in vec3 n) {
    const float sampleDist = 0.03;
    float dist = smoothstep(0.0, sampleDist, map(p + n * sampleDist).x);
    return mix(AOFactorMin, AOFactorMax, (dist));
}

float calcShadowLight(in vec3 p) {
    float t = march(p - lightDirection * 0.01, -lightDirection).x;
    return t > 40.0 ? 1.0 : 0.0;
}

const vec3 albedo1 = vec3(0.0, 0.6, 1.0);
const vec3 albedo2 = vec3(0.7, 0.2, 0.3);
const vec3 albedo3 = vec3(0.5, 0.1, 0.2);
const vec3 albedo4 = vec3(1.0, 1.0, 0.2);
const vec3 albedo5 = vec3(1.0, 0.2, 0.2);

vec3 dirToRGB(in vec3 rd) {
    float tht = atan(rd.z, rd.x);
    float phi = acos(dot(normalize(rd), vec3(0.0, 1.0, 0.0)));
    vec3 col = rd * 0.5 + 0.5;
    col *= smoothstep(0.002, -0.002, sin(tht       * 4.0)) * -0.3 + 1.0;
    col *= smoothstep(0.002, -0.002, sin(phi * 2.0 * 4.0)) * -0.3 + 1.0;
    col = mix(col, col / max(col.r, max(col.g, col.b)), 0.2);
    return col;
}

vec3 sky(in vec3 rd) {
    vec3 col = normalize(dirToRGB(rd));
    col *= rd.y < 0.0 ? 0.5 : 1.0;
    col = col * 0.1 + 0.1;
    return col;
}

vec3 getAlbedo(in int material, in vec3 pCrt, in pol3 pPol) {
    if (material == 1 || material == 2) {
        float th = mod((pPol.tht + 0.5 + pPol.rho * 7.0 * sign(pCrt.y)) * 5.0, PI * 2.0) / 5.0 - 0.5;
        float rh = mod((pPol.rho * 5.0 + 1.15), 1.0) - 0.5;
        float x = length(vec2(th, rh) * 5.0) - 2.0;
        float c = smoothstep(0.17, 0.0, x);
        c = c * 0.2 + 0.1;

        vec3 rgb1 = vec3(0.2);
        vec3 rgb2 = vec3(c);
        
        if (material == 2) {
            return rgb2;
        }
        else {
            if (gDemoView) {
                return mix(rgb1, rgb2, smoothstep(-0.4, 0.4, sin(gTime * 2.0)));
            }
        }
    }
    else if (material == 3) {
        return vec3(0.2);
    }
    else if (material == 4) {
        vec3 rgb = dirToRGB(normalize(pCrt - gPosCrate));
        rgb /= length(rgb);
        return rgb;
    }
    else {
        return vec3(1e9, 0.0, 1e9);
    }
}

vec3 getReflectivity(in int material, in vec3 pCrt, in pol3 pPol) {
    if (material == 1) {
        vec3 rgb = vec3(0.9);
        if (gDemoView) {
            return mix(rgb, vec3(0.0), smoothstep(-0.4, 0.4, sin(gTime)));
        }
        else {
            return rgb;
        }
    }
    else if (material == 2) {
        return vec3(0.0);
    }
    else if (material == 3) {
        return vec3(0.2);
    }
    else if (material == 4) {
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

    int bouncesLeft = 20;

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

        // distinguish inside and outside of mirascope
        if (material == 1) {
            if (dot(p, normal) > 0.0 || abs(normal.y) < 0.7) {
                material = 2;
            }
        }

        float incomingLight = 1.0;
        incomingLight = min(incomingLight, calcDiffuseAmount(p, normal));
        incomingLight = min(incomingLight, calcShadowLight(p));
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
    setupTime(persistedInfo[2]);
    vec2  uv        = worldFromScreen(XY);
    vec2  ms        = iMouse.xy / iResolution.xy * 2.0 - 1.0;
    float smoothEps = gWorldFromScreenFac * 2.0;

    // look-from and look-to points
    // right-handed system where x is right, y is up, z is forward.
    float t = gTime * 0.23;
    vec3 trgPt = vec3(0.0, -0.2, 0.0);
    
    float camTheta = -ms.x * PI * 1.25;
    float camAlttd = sin(t * 0.32) * 0.2 - (ms.y - 0.9) * 3.0;
    
    bool defaultView = stereo || length(iMouse.xy) < 1.0;
    gDebugView      = !defaultView && (length(iMouse.xy) < iResolution.x * gutter);
    if (gDebugView) {
        camTheta = sin(iTime * 0.10) * 0.1;
        camAlttd = sin(iTime * 0.12) * 0.1;
    }
    else if (defaultView) {
        camAlttd = 1.1;
    }
    
    gDemoView = gDebugView || iMouse.x > iResolution.x * gutterInv;
    
    vec3 camPt = vec3(sin(camTheta), camAlttd, cos(camTheta)) * (gDebugView ? 1.7 : 4.0);
    
    // camera's forward, right, and up vectors. right-handed.
    vec3 camFw = normalize(trgPt - camPt);
    vec3 camRt = cross(camFw, vec3(0.0, 1.0, 0.0));
    vec3 camUp = cross(camRt, camFw);
    
    if (stereo) {
        camPt += camRt * (leftEye ? -1.0 : 1.0) * stereoSeparation / 2.0;
        camFw = normalize(trgPt - camPt);
        camRt = cross(camFw, vec3(0.0, 1.0, 0.0));
        camUp = cross(camRt, camFw);
    }

    // ray origin and direction
    vec3 ro    = camPt;
    vec3 rd    = normalize(camFw + uv.x * camRt + uv.y * camUp);

    gSceneRot = rot2(gTime * PI * 2.0 / 30.0);

    configMap();
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
