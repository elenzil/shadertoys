#ifdef GRIMOIRE
#include <common.glsl>
#endif

bool gDebugView = false;

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

// I forget the location, but this pattern from IQ.

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

// return.x = distance
// return.y = material
vec2 map(in vec3 p) {
    vec2 Q = vec2(1e9, 0.0);
 
    const float miraThickness = 0.005;
    const float miraSep       = 0.3;
    const float miraHole      = 0.25;

    Q = opUnion(Q, vec2(sdMiraScope(p - vec3(0.0, 0.0, 0.0), miraSep, miraThickness, miraHole), 1.0)) ;
    
    float sphRad = 0.08;
    float cylH   = 0.01;
    float sphLift = (sin(gTime) * 0.5 + 0.5) * 0.0;
//    Q = opUnion(Q, vec2(sdSphere(p - vec3(0.0, -miraSep + sphRad + miraThickness + sphLift, 0.0), sphRad), 2.0));
//    Q = opUnion(Q, vec2(sdCappedCylinder(p - vec3(0.0, -miraSep + cylH + miraThickness + sphLift, 0.0), sphRad, cylH), 2.0)); 

    Q = opUnion(Q, vec2(sdCrateBox(p - vec3(0.0, -miraSep + sphRad + miraThickness + sphLift, 0.0), vec3(sphRad * 0.9), 0.0) - 0.005, 2.0));

    if (gDebugView) {
        Q = opSubtraction(vec2(-p.z, 2), Q);
    }

    return Q;
}

const float closeEps = 0.002;

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

vec3 lightDirection = normalize(vec3(1.0, -5.0, 1.0));

float calcDiffuseAmount(in vec3 p, in vec3 n) {
    return clamp(dot(n, -lightDirection), 0.0, 1.0);
}

const float AOFactorMin = 0.2;
const float AOFactorMax = 1.0;
float calcAOFactor(in vec3 p, in vec3 n) {
    const float sampleDist = 0.4;
    float dist = smoothstep(0.0, sampleDist, map(p + n * sampleDist).x);
    return mix(AOFactorMin, AOFactorMax, (dist));
}

float calcShadowLight(in vec3 p) {
    float t = march(p - lightDirection * 0.05, -lightDirection).x;
    return t > 40.0 ? 1.0 : 0.0;
}

const vec3 albedo1 = vec3(0.0, 0.6, 1.0);
const vec3 albedo2 = vec3(0.7, 0.2, 0.3);
const vec3 albedo3 = vec3(0.5, 0.1, 0.2);
const vec3 albedo4 = vec3(1.0, 1.0, 0.2);
const vec3 albedo5 = vec3(1.0, 0.2, 0.2);

vec3 getAlbedo(in int material, in vec3 pCrt, in pol3 pPol) {
    if (material == 1) {
        return vec3(0.82);
    }
    else if (material == 2) {
        return vec3(1.0, 1.0, 1.0);
    }
    else {
        return vec3(1e9, 0.0, 1e9);
    }
}

vec3 getReflectivity(in int material, in vec3 pCrt, in pol3 pPol) {
    if (material == 1) {
        return vec3(0.7);
    }
    else if (material == 2) {
        return vec3(0.0);
    }
    else {
        return vec3(0.0, 1e9, 0.0);
    }
}

vec3 getEmissive(in int material, in vec3 pCrt, in pol3 pPol) {
    if (material == 2) {
        return vec3(0.2, 0.0, 0.0);
    }
    else {
        return vec3(0.0);
    }
}


//------------------------------------------------------------------------------

vec3 sky(in vec3 rd) {
    float tht = atan(rd.z, rd.x);
    float phi = acos(dot(normalize(rd), vec3(0.0, 1.0, 0.0)));
    vec3 col = rd * 0.5 + 0.5;
    col *= smoothstep(0.002, -0.002, sin(tht       * 4.0)) * -0.3 + 1.0;
    col *= smoothstep(0.002, -0.002, sin(phi * 2.0 * 4.0)) * -0.3 + 1.0;
    col = mix(col, col / max(col.r, max(col.g, col.b)), 0.2);
    col *= rd.y < 0.0 ? 0.5 : 1.0;
    return col;
}

vec3 render(in vec3 ro, in vec3 rd) {
    vec3 rgb = vec3(0.0);

    int bouncesLeft = 14;

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
        pol3 ptSph = sphericalFromCartesian(ptCrt);


        int material = int(q.y);

        float incomingLight = 1.0;
        incomingLight = min(incomingLight, calcDiffuseAmount(p, normal));
        incomingLight = min(incomingLight, calcShadowLight(p));
        float ambient = 0.5 * calcAOFactor(p, normal);
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

    setupCoords(iResolution.xy, 4.4);
    setupTime(persistedInfo[2]);
    vec2  uv        = worldFromScreen(XY);
    vec2  ms        = iMouse.xy / iResolution.xy * 2.0 - 1.0;
    float smoothEps = gWorldFromScreenFac * 2.0;

    // look-from and look-to points
    // right-handed system where x is right, y is up, z is forward.
    float t = gTime * 0.23;
    vec3 trgPt = vec3(0.0);
    
    float camTheta = t - ms.x * PI * 1.25;
    float camAlttd = sin(t * 0.32) * 0.2 - ms.y * 8.0;
    
    gDebugView      = length(iMouse.xy) < gCanvasSmallRes * 0.1;
    if (gDebugView) {
        camTheta = sin(iTime * 0.10) * 0.1;
        camAlttd = sin(iTime * 0.12) * 0.1;
    }
    
    vec3 camPt = vec3(sin(camTheta), camAlttd, cos(camTheta)) * (gDebugView ? 2.0 : 4.0);
    
    // camera's forward, right, and up vectors. right-handed.
    vec3 camFw = normalize(trgPt - camPt);
    vec3 camRt = cross(camFw, vec3(0.0, 1.0, 0.0));
    vec3 camUp = cross(camRt, camFw);

    // ray origin and direction
    vec3 ro    = camPt;
    vec3 rd    = normalize(camFw + uv.x * camRt + uv.y * camUp);

    vec3 rgb = render(ro, rd);

    RGBA = vec4(rgb, 1.0);
}


#ifdef GRIMOIRE
out vec4 fragColor; void main() { mainImage(fragColor, gl_FragCoord.xy); }
#endif
