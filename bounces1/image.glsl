#ifdef GRIMOIRE
#include <common.glsl>
#endif


vec3 sky(in vec3 rd);
mat2 rot2(in float theta);
vec3 directionToColor(in vec3 dir);

float opUnion(in float a, in float b);
float opMinus(in float a, in float b);
float opIntsc(in float a, in float b);
float opUnion2(inout vec3 localSpace, in vec3 bSpace, in float a, in float b);
float opMinus2(inout vec3 localSpace, in vec3 bSpace, in float a, in float b);
float opIntsc2(inout vec3 localSpace, in vec3 bSpace, in float a, in float b);

float sdSphere(in vec3 p, in float r);
float sdCylZ(in vec3 p, in vec3 c, in float r);
float sdCylY(in vec3 p, in vec3 c, in float r);

float gMapCalls;

#define FOO                                               \
    gMapCalls += 1.0;                                     \
    float d = 1e9;                                        \
    p.y *= -1.0;                                          \
    vec3 P;                                               \
    P = p - vec3(0.0,  6.0, 0.0);                         \
    d = UN(ARGS123, sdSphere(P, 5.0));                    \
    P = p - vec3(0.0,  6.0, 0.0);                         \
    d = MI(ARGS123, sdSphere(P, 4.8));                    \
    P = vec3(abs(p.x), p.yz) - vec3(0.9, 1.8, 0.0);       \
    d = MI(ARGS123, sdSphere(P, 1.0 + sin(gTime) * 0.1)); \
    P = vec3(abs(p.x), p.yz) - vec3(0.9, 1.8, 0.0);       \
    d = IN(ARGS123, sdSphere(P, 1.3));                    \
    P = p - vec3( 1.1, sin(iTime * 0.343) * 0.9, 0.0);    \
    P.yz *= rot2(gTime * 1.0);                            \
    d = UN(ARGS123, sdSphere(P, 0.7));                    \
    P = p - vec3(-1.1, sin(iTime * 0.443) * 0.9, 0.0);    \
    P.zx *= rot2(abs(sin(iTime * 0.443 * 0.5 - PI/4.0)) * 15.0);                            \
    d = UN(ARGS123, sdSphere(P, 0.7));


float map(in vec3 p) {
#define UN opUnion
#define MI opMinus
#define IN opIntsc
#define ARGS123 d
    FOO
    return d;
}

vec3 localCoords(in vec3 p) {
#undef UN
#undef MI
#undef IN
#undef ARGS123
#define UN opUnion2
#define MI opMinus2
#define IN opIntsc2
#define ARGS123 localSpace, P, d
    vec3 localSpace = vec3(0.0);
    FOO
    return localSpace;
}

// IQ: https://www.iquilezles.org/www/articles/normalsSDF/normalsSDF.htm
vec3 calcNormal( in vec3 p ) // for function f(p)
{
    const float h = 0.0001;      // replace by an appropriate value
    vec3 n = vec3(0.0);
    for( int i=ZERO; i<4; i++ )
    {
        vec3 e = 0.5773*(2.0*vec3((((i+3)>>1)&1),((i>>1)&1),(i&1))-1.0);
        n += e*map(p+e*h);
    }
    return normalize(n);
}

const float closeEps = 0.0005;

float march(in vec3 ro, in vec3 rd) {
    const int maxSteps = 100;
    
    vec3 p = ro;
    float t = 0.0;
    for (int n = 1; n <= maxSteps; ++n) {
        float d = map(ro + rd * t);
        float closeEnoughEps = (n == maxSteps ? 0.2 : closeEps);
        if (d < closeEnoughEps) {
            return t;
        }
        t += d * 1.0;
        if (t > 150.0) {
            return t;
        }
    }
    return t;
}

float ambient = 0.2;

float calcDiffuseAmount(in vec3 p, in vec3 n) {
    vec3 lightDirection = normalize(vec3(-1.0));
    float ret = dot(n, -lightDirection);
    ret = ambient + (ret * (1.0 - ambient));
    return ret;
}

const float AOFactorMin = 0.5;
const float AOFactorMax = 1.0;
float calcAOFactor(in vec3 p, in vec3 n) {
    const float sampleDist = 0.2;
    float dist = smoothstep(0.0, sampleDist, map(p + n * sampleDist));
    return mix(AOFactorMin, AOFactorMax, (dist));
}

float maxPart(in vec3 v) {
    return max(v.x, max(v.y, v.z));
}

vec3 render(in vec3 ro, in vec3 rd) {

    vec3 col = vec3(0.0);

    int bouncesLeft = 5;

    vec3 contributionLeft = vec3(1.0);

    vec3 albedo1 = vec3(0.0, 0.4, 0.7) * (sin(gTime * 0.44) * 0.2 + 0.8);
    vec3 albedo2 = vec3(0.7, 0.2, 0.3) * (sin(gTime * 0.34) * 0.2 + 0.8);
    vec3 albedo3 = vec3(0.6, 0.4, 0.5) * (sin(gTime * 0.24) * 0.2 + 0.8);
    vec3 reflectAmount = vec3(0.7, 0.6, 0.0) * (sin(gTime * 0.3) * 0.5 + 0.5);

    while (bouncesLeft > 0 && maxPart(contributionLeft) > 0.0) {
        bouncesLeft -= 1;
        float t = march(ro, rd);
        vec3 p = ro + t * rd;
        if (length(p) > 100.0) {
            col += sky(rd) * contributionLeft;
            break;
        }

        vec3 localPoint = localCoords(p);
        float tht = atan(localPoint.z, localPoint.x);
        float phi = acos(dot(normalize(localPoint), vec3(0.0, 1.0, 0.0)));
        vec3 alb = albedo1;
        float vertStripes = smoothstep(-0.05, 0.05, sin(tht * 5.0));
        alb = mix(alb, albedo2, vertStripes);
        alb = mix(alb, albedo3, 0.7 * smoothstep(0.29, 0.3, abs(phi - PI/2.0)));

        vec3 n = calcNormal(p);
        vec3 dif = calcDiffuseAmount(p, n) * alb;
        dif *= calcAOFactor(p, n);
        // dif = alb;


        float fres = 1.0 - abs(dot(rd, n)) * 0.5;
        reflectAmount *= fres;
        reflectAmount *= 1.0 - vertStripes * 0.8;
        col += dif * (1.0 - reflectAmount) * contributionLeft;
        contributionLeft *= reflectAmount;

        ro = p + n * 0.05;
        rd = reflect(rd, n);
    }

    return col;
}

void mainImage( out vec4 RGBA, in vec2 XY )
{
    setupCoords(iResolution.xy, 0.98);
    setupTime(iTime);
    vec2  uv        = worldFromScreen(XY);
    float luv       = length(uv);
    vec2  ms        = worldFromScreen(iMouse.xy);
    float smoothEps = gWorldFromScreenFac * 2.0;

    // look-from and look-to points
    // right-handed system where x is right, y is up, z is forward.
    float dt = 0.5;
    float t = gTime * 0.23;
    vec3 camPt = vec3(cos(t), sin(t * 0.12) * 0.2 + 0.3, sin(t)) * 3.0;
    vec3 trgPt = vec3(0.0);

    // camera's forward, right, and up vectors. right-handed.
    vec3 camFw = normalize(trgPt - camPt);
    vec3 camRt = cross(camFw, vec3(0.0, 1.0, 0.0));
    vec3 camUp = cross(camRt, camFw);

    // mess with camPt, just for fun
    float messFac = luv < 1.0 ? 0.0 : 2.0 * (luv - 1.0);
    camPt += camFw * messFac;

    // ray origin and direction
    vec3 ro    = camPt;
    vec3 rd    = normalize(camFw + uv.x * camRt / (1.0 + messFac * 1.0) + uv.y * camUp / (1.0 + messFac * 1.0));
    
    const int maxSteps = 100;
    
    gMapCalls = 0.0;

    vec3 col = render(ro, rd);

    float outCircle = smoothstep(-smoothEps, smoothEps, luv - 1.0);
    col *= 1.0 - 0.1 * outCircle * pow(luv, 1.5);
    col = mix(col, vec3(col.x + col.y + col.z) / 6.0, outCircle * clamp(0.0, 1.0, 2.0 * (luv - 1.0)));
    col *= 1.0 + smoothstep(smoothEps, -smoothEps, abs(luv - 1.0));

  //  col.r = gMapCalls / 200.0;
    
    RGBA = vec4(col, 1.0);
}



//////////////////////////////////////////////////////////////////////////////

vec3 sky(in vec3 rd) {
    vec3 col = rd * 0.5 + 0.5;
    col = mix(col, col / max(col.r, max(col.g, col.b)), 0.2);
    col *= rd.y < 0.0 ? 0.9 : 1.0;
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

float opUnion2(inout vec3 localSpace, in vec3 bSpace, in float a, in float b) {
    if (a < b) {
        return a;
    }
    else {
        localSpace = bSpace;
        return b;
    }
}

float opMinus2(inout vec3 localSpace, in vec3 bSpace, in float a, in float b) {
    return opMinus(a, b);
}

float opIntsc2(inout vec3 localSpace, in vec3 bSpace, in float a, in float b) {
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
