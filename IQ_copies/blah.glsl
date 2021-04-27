#ifdef GRIMOIRE
#include <common.glsl>
#endif

#define AA 0


float opUnion(in float a, in float b, out bool aWins);
float opMinus(in float a, in float b);
float opIntsc(in float a, in float b);
float opExtrusion( in vec3 p, in float d, in float h );
float opOnion( in float sdf, in float thickness );

float sdPlaneY(in vec3 p);
float sdBoxFrame(in vec3 p, in vec3 b, in float e);
vec3 sky(in vec3 dir);
float fineNoise(in vec3 p);


float gMapCalls;

float gSceneTheta = 0.0;

float map(in vec3 p, out vec3 localCoords, out int material) {
    float d     = 1e9;
    localCoords = p;
    material    = 1;
    
    vec3 P;
    bool aWins;

    P = p;
    P.xz *= rot2(gSceneTheta);
    d = opUnion(d, sdBoxFrame(P, vec3(1.0), 0.0) - 0.2, aWins);
    if (!aWins) {
        material = 1;
        localCoords = P;
    }
    
//    d = opOnion(d, 0.01);
    
  //  d = opIntsc(d, p.y - 0.9);

    P = vec3(p.x, p.y + 1.2, p.z);
    d = opUnion(d, sdPlaneY(P), aWins);
    if (!aWins) {
        material = 0;
        localCoords = P;
    }
    
/*  P = p;
   // P.xz *= rot2(gTime * 0.3);
    vec2 q = vec2( length(P.xz), P.y );
    d = opUnion(d, sdParabola(q, 0.1, 0.1), aWins);
    if (!aWins) {
        material = 1;
        localCoords = P;
    }*/


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
        t += d;
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

vec3 getAlbedo(in int material, in vec3 pCrt, in pol3 pPol) {
    float tmp = smoothstep(0.88, 0.92, sin(0.5/(dot(pCrt, pCrt)) * 50.0 + gTime * 6.0));
    switch (material) {
        case 0: return vec3(0.2);
        case 1: return vec3(tmp);
    }
    return vec3(1e9, 0.0, 1e9);
}

vec3 getReflectivity(in int material, in vec3 pCrt, in pol3 pPol) {
    switch (material) {
        case 0: return vec3(fineNoise(pCrt * 3.0));
        case 1: return vec3(0.5);
    }
    return vec3(1e9, 1e9, 0.0);
}

vec3 render(in vec3 ro, in vec3 rd) {

    vec3 col = vec3(0.0);

    int bouncesLeft = 3;

    vec3 contributionLeft = vec3(1.0);

    while (bouncesLeft >= 0 && maxComponent(contributionLeft) > 0.001) {
        bouncesLeft -= 1;
        float t = march(ro, rd);
        vec3 p = ro + t * rd;
        if (length(p) > 20.0) {
            
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

        float fres = 0.2 + 0.8 * clamp(pow(1.0 - abs(dot(rd, normal) - 0.1), 2.0), 0.0, 1.0);

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
    
    gMapCalls = 0.0;
    vec3 col = vec3(0.0);

    gSceneTheta = ms.x * -1.5;
    float camTheta = t;
    float camAlttd = sin(t * 0.32) * 0.2 - ms.y * 0.8;
    camAlttd = max(camAlttd, -0.1);
    vec3 camPt = vec3(cos(camTheta), camAlttd, sin(camTheta)) * 5.0;
    
    // camera's forward, right, and up vectors. right-handed.
    vec3 camFw = normalize(trgPt - camPt);
    vec3 camRt = cross(camFw, vec3(0.0, 1.0, 0.0));
    vec3 camUp = cross(camRt, camFw);

    vec2 aaD = worldFromScreen(vec2(1.0));
    bool leftSide = true ; // XY.x < iResolution.x / 2.0;
    float accum = 0.0;
    for (float aax = -0.5; aax <= 0.5; aax += 0.5) {
        for (float aay = -0.5; aay <= 0.5; aay += 0.5) {
            // ray origin and direction
            vec3 ro    = camPt;
            vec3 rd    = normalize(camFw + (uv.x + aax * gWorldFromScreenFac) * camRt + (uv.y + aay * gWorldFromScreenFac) * camUp);
            const int maxSteps = 100;    
            col += render(ro, rd);
            accum += 1.0;
            if (leftSide) {
                break;
            }
        }
        if (leftSide) {
            break;
        }
    }
    col /= accum;

    float outCircle = smoothstep(-smoothEps, smoothEps, luv - 1.0);
    col *= 1.0 - 0.1 * outCircle * pow(luv, 1.5);

  //  col.r = gMapCalls / 200.0;
  
    col = pow(col, vec3(1.0 / 2.2));

// col *= 1.0 + 0.5 * smoothstep(2.0, 0.0, abs(XY.x - iResolution.x/2.0));
    
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

    float lightDot = -dot(rd, lightDirection);
    lightDot = smoothstep(0.95, 1.0, lightDot);
    col *= 1.0 + 0.5 * lightDot;

    col *= rd.y < 0.0 ? 0.5 : 1.0;
    return col;
}

// dir is unit-length
vec3 directionToColor(in vec3 dir) {
    vec3 ret = dir * 0.5 + 0.5;
    return ret;
}


float opUnion(in float a, in float b, out bool aWins) {
    aWins = a < b;
    return aWins ? a : b;
}

float opMinus(in float a, in float b) {
    return max(a, -b);
}

float opIntsc(in float a, in float b) {
    return max(a, b);
}

// https://iquilezles.untergrund.net/www/articles/distfunctions/distfunctions.htm
float opExtrusion( in vec3 p, in float d, in float h )
{
    vec2 w = vec2( d, abs(p.z) - h );
    return min(max(w.x,w.y),0.0) + length(max(w,0.0));
}


float opOnion( in float sdf, in float thickness )
{
    return abs(sdf)-thickness;
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




// noise from IQ: https://www.shadertoy.com/view/4sfGzS
float hash(vec3 p)  // replace this by something better
{
    p  = fract( p*0.3183099+.1 );
    p *= 17.0;
    return fract( p.x*p.y*p.z*(p.x+p.y+p.z) );
}

float noise( in vec3 x )
{
    vec3 i = floor(x);
    vec3 f = fract(x);
    f = f*f*(3.0-2.0*f);
    
    return mix(mix(mix( hash(i+vec3(0,0,0)), 
                        hash(i+vec3(1,0,0)),f.x),
                   mix( hash(i+vec3(0,1,0)), 
                        hash(i+vec3(1,1,0)),f.x),f.y),
               mix(mix( hash(i+vec3(0,0,1)), 
                        hash(i+vec3(1,0,1)),f.x),
                   mix( hash(i+vec3(0,1,1)), 
                        hash(i+vec3(1,1,1)),f.x),f.y),f.z);
}


const mat3 m = mat3( 0.00,  0.80,  0.60,
                    -0.80,  0.36, -0.48,
                    -0.60, -0.48,  0.64 );
                    
float fineNoise(in vec3 p) {
    vec3 q = 2.0 * p;
    float f;
    f  = 0.5000*noise( q ); q = m*q*2.01;
    f += 0.2500*noise( q ); q = m*q*2.02;
    f += 0.1250*noise( q ); q = m*q*2.03;
    f += 0.0625*noise( q ); q = m*q*2.01;
    return f;
}

#ifdef GRIMOIRE
out vec4 fragColor; void main() { mainImage(fragColor, gl_FragCoord.xy); }
#endif
