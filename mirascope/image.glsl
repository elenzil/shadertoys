#ifdef GRIMOIRE
#include <common.glsl>
#endif

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

float sdBoundingBox( vec3 p, vec3 b, float e )
{
       p = abs(p  )-b;
  vec3 q = abs(p+e)-e;
  return min(min(
      length(max(vec3(p.x,q.y,q.z),0.0))+min(max(p.x,max(q.y,q.z)),0.0),
      length(max(vec3(q.x,p.y,q.z),0.0))+min(max(q.x,max(p.y,q.z)),0.0)),
      length(max(vec3(q.x,q.y,p.z),0.0))+min(max(q.x,max(q.y,p.z)),0.0));
}

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

float sdMiraScope(in vec3 pos, in float separation, in float thickness) {
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
    sdMira = max(sdMira, p.y - separation * 0.9);

    return sdMira;
}

//-----------------------------------------------------------------------

float map(in vec3 p) {
    float d = 1e9;

    const float sep = 0.3;
    const float boxScale = 0.3 * sep;
    d = min(d, sdBoundingBox((p - vec3(0.0, -sep * 0.6, 0.0)) / boxScale, vec3(1.0), 0.1) * boxScale);
    d = min(d, sdMiraScope(p - vec3(0.0, 0.0, 0.0), sep, 0.01)) ;

    return d;
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

const vec3 albedo1 = vec3(0.0, 0.6, 1.0);
const vec3 albedo2 = vec3(0.7, 0.2, 0.3);
const vec3 albedo3 = vec3(0.5, 0.1, 0.2);
const vec3 albedo4 = vec3(1.0, 1.0, 0.2);
const vec3 albedo5 = vec3(1.0, 0.2, 0.2);

vec3 getAlbedo(in int material, in vec3 pCrt, in pol3 pPol) {
    if (material == 1 || material == 2) {
        float dots = smoothstep(0.005, -0.005, length(vec2(pPol.phi * 2.5 * 2.0, sin((pPol.tht + 2.2) * 8.0 / 1.0))) - 0.4);
        vec3 alb = albedo1;
        alb = mix(alb, albedo3, 0.7 * smoothstep(0.25, 0.3, abs((pPol.phi) * 2.0 + cos(pPol.tht * 8.0) * 0.3)));
        alb = mix(alb, material == 1 ? albedo4 : albedo5, dots);
        return alb;
    }
    else if (material == 0) {
        return vec3(0.7);
    }
    else if (material == 3) {
        return vec3(0.1, 0.1, 0.1);
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
        return vec3(0.98);
    }
    else if (material <= 3) {
        return vec3(0.0, 0.2, 0.7);
    }
    else {
        discard;
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

    int bouncesLeft = 8;

    vec3 contributionLeft = vec3(1.0);

    while (bouncesLeft >= 0 && maxPart(contributionLeft) > 0.001) {
        bouncesLeft -= 1;
        float t = march(ro, rd);
        vec3 p = ro + t * rd;
        if (length(p) > 150.0) {
            rgb += sky(rd) * contributionLeft;
            break;
        }

        vec3 normal = calcNormal(p);

        vec3 ptCrt = p;
        pol3 ptSph = sphericalFromCartesian(ptCrt);


        int material = 1;

        float incomingLight = 1.0;
        incomingLight = min(incomingLight, calcDiffuseAmount(p, normal));
        incomingLight = min(incomingLight, calcShadowLight(p));
        float ambient = 0.5 * calcAOFactor(p, normal);
        incomingLight += ambient;

        float fres = 0.4 + 0.8 * clamp(pow(1.0 - abs(dot(rd, normal) - 0.1), 2.0), 0.0, 1.0);

        vec3 reflectivity = fres * getReflectivity(material, ptCrt, ptSph);
        vec3 diffuse = incomingLight * getAlbedo(material, ptCrt, ptSph);
        
        rgb += diffuse * (1.0 - reflectivity) * contributionLeft;
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
    vec2  ms        = worldFromScreen(iMouse.xy);
    float smoothEps = gWorldFromScreenFac * 2.0;

    // look-from and look-to points
    // right-handed system where x is right, y is up, z is forward.
    float t = gTime * 0.23;
    vec3 trgPt = vec3(0.0);
    
    float camTheta = t + ms.x * 2.5;
    float camAlttd = sin(t * 0.32) * 0.2 - ms.y * 20.0;
    vec3 camPt = vec3(cos(camTheta), camAlttd, sin(camTheta)) * 4.0;
    
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
