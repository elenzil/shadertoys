#ifdef GRIMOIRE
#include <common.glsl>
#endif

float opUnion(in float a, in float b);
float opMinus(in float a, in float b);
float opIntsc(in float a, in float b);

float sdPlaneY(in vec3 p);
float sdBoxFrame(in vec3 p, in vec3 b, in float e);
vec3 sky(in vec3 dir);


float gMapCalls;


float map(in vec3 p, out vec3 localCoords, out int material) {
    float d     = 1e9;
    localCoords = vec3(0.0);
    material    = 1;

    vec3 P;

    P = p;
    d = opUnion(d, sdBoxFrame(p, vec3(1.0), 0.0) - 0.2);

    return d;
}


// IQ: https://www.iquilezles.org/www/articles/normalsSDF/normalsSDF.htm
vec3 calcNormal( in vec3 p ) // for function f(p)
{
    vec3 unused1;
    int unused2;
    const float h = 0.002;      // replace by an appropriate value
    vec3 n = vec3(0.0);
    for( int i=ZERO; i<4; i++ )
    {
        vec3 e = 0.5773*(2.0*vec3((((i+3)>>1)&1),((i>>1)&1),(i&1))-1.0);
        n += e*map(p+e*h, unused1, unused2);
    }
    return normalize(n);
}

const float closeEps = 0.002;

float march(in vec3 ro, in vec3 rd) {
    const int maxSteps = 100;

    vec3 localCoords;
    int  material;

    float t = 0.0;
    for (int n = ZERO; n < maxSteps; ++n) {
        float d = map(ro + rd * t, localCoords, material);
        float closeEnoughEps = (n == maxSteps ? 0.2 : closeEps);
        if (d < closeEnoughEps) {
            return t;
        }
        t += d * 0.85;
        if (t > 200.0) {
            return t;
        }
    }
    return t;
}

vec3 lightDirection = normalize(vec3(-2.0, -1.0, 0.7));

float calcDiffuseAmount(in vec3 p, in vec3 n) {
    return clamp(dot(n, -lightDirection), 0.0, 1.0);
}

const float AOFactorMin = 0.2;
const float AOFactorMax = 1.0;
float calcAOFactor(in vec3 p, in vec3 n) {
    vec3 unused1;
    int unused2;
    const float sampleDist = 0.4;
    float dist = smoothstep(0.0, sampleDist, map(p + n * sampleDist, unused1, unused2));
    return mix(AOFactorMin, AOFactorMax, (dist));
}

float calcShadowLight(in vec3 p) {
    float t = march(p - lightDirection * 0.05, -lightDirection);
    return t > 40.0 ? 1.0 : 0.0;
}

float maxComponent(in vec3 v) {
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
    return vec3(0.7);
}

vec3 getReflectivity(in int material, in vec3 pCrt, in pol3 pPol) {
    return vec3(0.7);
}

vec3 render(in vec3 ro, in vec3 rd) {

    vec3 col = vec3(0.0);

    int bouncesLeft = 3;

    vec3 contributionLeft = vec3(1.0);

    while (bouncesLeft >= 0 && maxComponent(contributionLeft) > 0.001) {
        bouncesLeft -= 1;
        float t = march(ro, rd);
        vec3 p = ro + t * rd;
        if (length(p) > 150.0) {
            col += sky(rd) * contributionLeft;
            break;
        }

        vec3 normal = calcNormal(p);

        vec3 ptCrt;
        int material;
        map(p, ptCrt, material);
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
    setupCoords(iResolution.xy, 1.5);
    setupTime(persistedInfo[2]);
    vec2  uv        = worldFromScreen(XY);
    float luv       = length(uv);
    vec2  ms        = worldFromScreen(iMouse.xy) * 1.5;
    float smoothEps = gWorldFromScreenFac * 2.0;

    // look-from and look-to points
    // right-handed system where x is right, y is up, z is forward.
    float dt = 0.5;
    float t = gTime * 0.23;
    vec3 trgPt = vec3(0.0);
    
    vec3 col = vec3(0.0);

    float camTheta = t + ms.x * 1.5;
    float camAlttd = sin(t * 0.32) * 0.2 - ms.y * 0.8;
    vec3 camPt = vec3(cos(camTheta), camAlttd, sin(camTheta)) * 5.0;
    
    // camera's forward, right, and up vectors. right-handed.
    vec3 camFw = normalize(trgPt - camPt);
    vec3 camRt = cross(camFw, vec3(0.0, 1.0, 0.0));
    vec3 camUp = cross(camRt, camFw);

    // ray origin and direction
    vec3 ro    = camPt;
    vec3 rd    = normalize(camFw + uv.x * camRt + uv.y * camUp);
    
    const int maxSteps = 100;
    
    gMapCalls = 0.0;

    col += render(ro, rd);

    float outCircle = smoothstep(-smoothEps, smoothEps, luv - 1.0);
    col *= 1.0 - 0.1 * outCircle * pow(luv, 1.5);

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

float sdPlaneY(in vec3 p)
{
    return p.y;
}

// IQ: https://www.iquilezles.org/www/articles/distfunctions/distfunctions.htm
float sdBoxFrame(in vec3 p, in vec3 b, in float e )
{
  p = abs(p  )-b;
  vec3 q = abs(p+e)-e;
  return min(min(
      length(max(vec3(p.x,q.y,q.z),0.0))+min(max(p.x,max(q.y,q.z)),0.0),
      length(max(vec3(q.x,p.y,q.z),0.0))+min(max(q.x,max(p.y,q.z)),0.0)),
      length(max(vec3(q.x,q.y,p.z),0.0))+min(max(q.x,max(q.y,p.z)),0.0));
}

#ifdef GRIMOIRE
out vec4 fragColor; void main() { mainImage(fragColor, gl_FragCoord.xy); }
#endif
