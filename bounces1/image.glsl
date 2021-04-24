


#ifdef GRIMOIRE
#include <common.glsl>
#endif

// TODO TODO TODO
// Move the calculation of object positions into a once-per-pixel calculation.

vec3 sky(in vec3 rd);
mat2 rot2(in float theta);
vec3 directionToColor(in vec3 dir);

float opUnion(in float a, in float b);
float opMinus(in float a, in float b);
float opIntsc(in float a, in float b);
float opUnion2(inout vec3 localSpace, in vec3 bSpace, inout int material, in int bMaterial, in float a, in float b);
float opMinus2(inout vec3 localSpace, in vec3 bSpace, inout int material, in int bMaterial, in float a, in float b);
float opIntsc2(inout vec3 localSpace, in vec3 bSpace, inout int material, in int bMaterial, in float a, in float b);

float sdSphere(in vec3 p, in float r);
float sdCylZ(in vec3 p, in vec3 c, in float r);
float sdCylY(in vec3 p, in vec3 c, in float r);

float gMapCalls;

vec3  gSph1Pos;
float gSph1Rad;
mat2  gSPh1Rot;
vec3  gSph2Pos;
float gSph2Rad;
mat2  gSPh2Rot;
vec3  gSph3Pos;
float gSph3Rad;
float gSphMod;

void configScene() {
    // move a bunch of trig etc out of the core map() routine and into once-per-fragment globals.
    gSph1Pos    = vec3( 1.1, sin(gTime * 0.343) * 0.9, 0.0);
    gSph1Rad    = smoothstep(7.0, 30.0, gTime) * 0.7 + 0.01;
    gSPh1Rot    = rot2(gTime * 0.81);
    gSph2Pos    = vec3(-1.1, sin(gTime * 0.443) * 0.9, 0.0);
    gSph2Rad    = smoothstep(5.0, 20.0, gTime) * 0.7 + 0.01;
    gSPh2Rot    = rot2(abs(sin(gTime * 0.443 * 0.5 - PI/4.0)) * 15.0);
    gSphMod     = sin(gTime * 0.231) * 25.0 + 25.0;

    gSph3Rad    = 30.0;
    gSph3Pos    = vec3(0.0, gSph3Rad + 1.7, 0.0);

}

// this #define is a super awkward way of
// having two versions of the map() function,
// one which worries about local coordinates and one which doesn't.
#define FOO                                               \
    int bMat = 0;                                         \
    gMapCalls += 1.0;                                     \
    float d = 1e9;                                        \
    p.y *= -1.0;                                          \
    vec3 P;                                               \
                                                          \
    /* ground thing */                                    \
    /*
    bMat = 0;                                             \
    P = p - vec3(0.0,  6.0, 0.0);                         \
    d = UN(VARIABLE_ARGS, sdSphere(P, 5.0));              \
    P = p - vec3(0.0,  6.0, 0.0);                         \
    d = MI(VARIABLE_ARGS, sdSphere(P, 4.9));              \
    P = vec3(abs(p.x), p.yz) - vec3(0.9, 0.9, 0.0);       \
    d = MI(VARIABLE_ARGS, sdSphere(P, gSph3Rad));         \
    P = vec3(abs(p.x), p.yz) - vec3(0.9, 1.8, 0.0);       \
    d = IN(VARIABLE_ARGS, sdSphere(P, 1.3));              \
    */ \
    bMat = 0;                                             \
                                                          \
    /* ball 1 */                                          \
    bMat = 1;                                             \
    P = p - gSph1Pos;                                     \
    P.yz *= gSPh1Rot;                                     \
    float sphPerturb = 0.004 * (-1.0 + 2.0 * smoothstep(-0.8, 0.8, (sin(P.y * gSphMod) + sin(P.x * gSphMod) + sin(P.z * gSphMod)))); \
    d = UN(VARIABLE_ARGS, sdSphere(P, gSph1Rad) + sphPerturb); \
    /* ball 2 */                                          \
    bMat = 2;                                             \
    P = p - gSph2Pos;                                     \
    P.zx *= gSPh2Rot;                                     \
    d = UN(VARIABLE_ARGS, sdSphere(P, gSph2Rad));         \
    /* ball 3 */                                          \
    bMat = 3;                                             \
    P = p - gSph3Pos;                                     \
    P.y += sin(dot(p.xz, p.xz) * 0.3 - gTime) * 0.1; \
    d = UN(VARIABLE_ARGS, sdSphere(P, gSph3Rad));         \
    /* Blank Line */


// returns just the SDF without calculating local coordinates, material, etc.
float map(in vec3 p) {
#define UN opUnion
#define MI opMinus
#define IN opIntsc
#define VARIABLE_ARGS d
    FOO
    return d;
}

// returns the local coords.
vec3 localCoords(in vec3 p, out int mat) {
#undef UN
#undef MI
#undef IN
#undef VARIABLE_ARGS
#define UN opUnion2
#define MI opMinus2
#define IN opIntsc2
#define VARIABLE_ARGS localSpace, P, mat, bMat, d
    mat = -1;
    vec3 localSpace = vec3(0.0);
    FOO
    return localSpace;
}

// IQ: https://www.iquilezles.org/www/articles/normalsSDF/normalsSDF.htm
vec3 calcNormal( in vec3 p ) // for function f(p)
{
    const float h = 0.002;      // replace by an appropriate value
    vec3 n = vec3(0.0);
    for( int i=ZERO; i<4; i++ )
    {
        vec3 e = 0.5773*(2.0*vec3((((i+3)>>1)&1),((i>>1)&1),(i&1))-1.0);
        n += e*map(p+e*h);
    }
    return normalize(n);
}


const float closeEps = 0.002;

float march(in vec3 ro, in vec3 rd) {
    const int maxSteps = 100;

    float d1 = map(ro);

    vec3 p = ro;
    float t = 0.0;
    for (int n = 1; n <= maxSteps; ++n) {
        float d = map(ro + rd * t);
        float closeEnoughEps = (n == maxSteps ? 0.2 : closeEps);
        if (d < closeEnoughEps) {
            return t;
        }
        t += d;
        if (t > 200.0) {
            return t;
        }
    }
    return t;
}

vec3 lightDirection = normalize(vec3(-2.0, -1.0, 0.2));

float calcDiffuseAmount(in vec3 p, in vec3 n) {
    return clamp(dot(n, -lightDirection), 0.0, 1.0);
}

const float AOFactorMin = 0.2;
const float AOFactorMax = 1.0;
float calcAOFactor(in vec3 p, in vec3 n) {
    const float sampleDist = 0.4;
    float dist = smoothstep(0.0, sampleDist, map(p + n * sampleDist));
    return mix(AOFactorMin, AOFactorMax, (dist));
}

float calcShadowLight(in vec3 p) {
    float t = march(p - lightDirection * 0.05, -lightDirection);
    return t > 40.0 ? 1.0 : 0.0;
}

float maxPart(in vec3 v) {
    return max(v.x, max(v.y, v.z));
}

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

const vec3 albedo1 = vec3(0.0, 0.6, 1.0);
const vec3 albedo2 = vec3(0.7, 0.2, 0.3);
const vec3 albedo3 = vec3(0.5, 0.1, 0.2);
const vec3 albedo4 = vec3(1.0, 1.0, 0.2);
const vec3 albedo5 = vec3(1.0, 0.2, 0.2);


void calcMaterialCommons(in int material, in vec3 pCrt, in pol3 pPol) {
}


vec3 getAlbedo(in int material, in vec3 pCrt, in pol3 pPol) {
    if (material == 1 || material == 2) {
        float dots = smoothstep(0.005, -0.005, length(vec2(pPol.phi * 2.5 * 2.0, sin((pPol.tht + 2.2) * 5.0 / 1.0))) - 0.4);
        vec3 alb = albedo1;
        alb = mix(alb, albedo3, 0.7 * smoothstep(0.25, 0.3, abs((pPol.phi) * 2.0 + cos(pPol.tht * 5.0) * 0.3)));
        alb = mix(alb, material == 1 ? albedo4 : albedo5, dots);
        return alb;
    }
    else if (material == 0) {
        return vec3(0.7);
    }
    else if (material == 3) {
        return vec3(0.1, 0.0, 0.0);
    }
    else {
        discard;
    }
}

vec3 getReflectivity(in int material, in vec3 pCrt, in pol3 pPol) {

    if (material == 0) {
        return vec3(0.0);
    }
    else if (material <= 2) {
        vec3 reflectAmount = vec3(1.0, 0.8, 0.5) * (sin(gTime * 0.3) * 0.45 + 0.55);

        float vertStripes = smoothstep(-0.02, 0.02, sin(pPol.tht * 5.0 + pPol.phi * 4.0) - 0.7);

        float lid = smoothstep(0.27, 0.269, abs(pPol.phi) * 0.2);

        if (material == 0) {
            reflectAmount *= 0.0;
        }
        reflectAmount *= 0.2 + 0.8 * ((1.0 - vertStripes) * lid);
        return reflectAmount;
    }
    else if (material <= 3) {
        return vec3(0.7, 0.0, 0.1);
    }
    else {
        discard;
    }
}

vec3 render(in vec3 ro, in vec3 rd) {

    vec3 col = vec3(0.0);

    int bouncesLeft = 4;

    vec3 contributionLeft = vec3(1.0);

    while (bouncesLeft >= 0 && maxPart(contributionLeft) > 0.001) {
        bouncesLeft -= 1;
        float t = march(ro, rd);
        vec3 p = ro + t * rd;
        if (length(p) > 150.0) {
            col += sky(rd) * contributionLeft;
            break;
        }

        vec3 normal = calcNormal(p);

        int material;
        vec3 ptCrt = localCoords(p, material);
        pol3 ptSph = sphericalFromCartesian(ptCrt);


        float incomingLight = 1.0;
        incomingLight = min(incomingLight, calcDiffuseAmount(p, normal));
        incomingLight = min(incomingLight, calcShadowLight(p));
        float ambient = 0.05 * calcAOFactor(p, normal);
        incomingLight += ambient;

        float fres = 0.4 + 0.8 * clamp(pow(1.0 - abs(dot(rd, normal) - 0.1), 2.0), 0.0, 1.0);

        calcMaterialCommons(material, ptCrt, ptSph);

        vec3 reflectivity = fres * getReflectivity(material, ptCrt, ptSph);
        vec3 diffuse = incomingLight * getAlbedo(material, ptCrt, ptSph);
        
        col += diffuse * (1.0 - reflectivity) * contributionLeft;
        contributionLeft *= reflectivity;
          
        ro = p + normal * 0.05;
        rd = reflect(rd, normal);
    }

    return col;
}

void mainImage( out vec4 RGBA, in vec2 XY )
{
    vec4 persistedInfo = texelFetch(iChannel0, ivec2(0, 0), 0);
    setupCoords(iResolution.xy, 0.97);
    setupTime(persistedInfo[2]);
    vec2  uv        = worldFromScreen(XY);
    float luv       = length(uv);
    vec2  ms        = worldFromScreen(iMouse.xy);
    float smoothEps = gWorldFromScreenFac * 2.0;

    configScene();

    // look-from and look-to points
    // right-handed system where x is right, y is up, z is forward.
    float dt = 0.5;
    float t = gTime * 0.23;
    vec3 trgPt = vec3(0.0);
    
    float lookChoice = smoothstep(-0.1, 0.1, sin(t * 0.41));
    trgPt = mix(gSph1Pos, gSph2Pos, lookChoice);
    trgPt.y *= -1.0;

    vec3 col = vec3(0.0);

    vec3 camPt = vec3(cos(t), sin(t * 0.32) * 0.4, sin(t)) * -3.7;
    
    // camera's forward, right, and up vectors. right-handed.
    vec3 camFw = normalize(trgPt - camPt);
    vec3 camRt = cross(camFw, vec3(0.0, 1.0, 0.0));
    vec3 camUp = cross(camRt, camFw);
    
    

    // mess with camPt, just for fun
    float messAmt = luv < 1.0 ? 0.0 : 0.2 * (luv - 1.0);
    camPt += camRt * messAmt;

    // ray origin and direction
    vec3 ro    = camPt;
    vec3 rd    = normalize(camFw + uv.x * camRt / (1.0 + messAmt * 2.0) + uv.y * camUp / (1.0 + messAmt * 2.0));
    
    const int maxSteps = 100;
    
    gMapCalls = 0.0;

    col += render(ro, rd);

    float outCircle = smoothstep(-smoothEps, smoothEps, luv - 1.0);
    col *= 1.0 - 0.1 * outCircle * pow(luv, 1.5);
    col = mix(col, vec3(col.x + col.y + col.z) / 6.0, outCircle * clamp(0.0, 1.0, 2.0 * (luv - 1.0)));
    col *= 1.0 + smoothstep(smoothEps, -smoothEps, abs(luv - 1.0));

  //  col.r = gMapCalls / 200.0;
  
    col = pow(col, vec3(1.0 / 2.2));
    
    RGBA = vec4(col, 1.0);
}



//////////////////////////////////////////////////////////////////////////////

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

mat2 rot2(in float theta) {
    float c = cos(theta);
    float s = sin(theta);
    return mat2(c, s, -s, c);
    
}

// dir is unit-length
vec3 directionToColor(in vec3 dir) {
    vec3 ret = dir * 0.5 + 0.5;
    return ret;
}


float opUnion(in float a, in float b) {
    return min(a, b);
}

float opMinus(in float a, in float b) {
    return max(a, -b);
}

float opIntsc(in float a, in float b) {
    return max(a, b);
}

float opUnion2(inout vec3 localSpace, in vec3 bSpace, inout int material, in int bMaterial, in float a, in float b) {
    if (a < b) {
        return a;
    }
    else {
        localSpace = bSpace;
        material = bMaterial;
        return b;
    }
}

float opMinus2(inout vec3 localSpace, in vec3 bSpace, inout int material, in int bMaterial, in float a, in float b) {
    return opMinus(a, b);
}

float opIntsc2(inout vec3 localSpace, in vec3 bSpace, inout int material, in int bMaterial, in float a, in float b) {
    return opIntsc(a, b);
}

float sdSphere(in vec3 p, in float r) {
    return length(p) - r;
}

float sdCylZ(in vec3 p, in vec3 c, in float r) {
    return length(p.xy - c.xy) - r;
}

float sdCylY(in vec3 p, in vec3 c, in float r) {
    return length(p.xz - c.xz) - r;
}

float sdPlaneY(in vec3 p)
{
    return p.y;
}


#ifdef GRIMOIRE
out vec4 fragColor; void main() { mainImage(fragColor, gl_FragCoord.xy); }
#endif
