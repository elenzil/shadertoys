#ifdef GRIMOIRE
#include <common.glsl>
#endif


vec3 sky(in vec3 rd);
mat2 rot2(in float theta);
vec3 directionToColor(in vec3 dir);

float opUnion(in float a, in float b);
float opMinus(in float a, in float b);
float opIntsc(in float a, in float b);

float sdSphere(in vec3 p, in vec3 c, in float r) {
    return length(p - c) - r;
}

float sdCylZ(in vec3 p, in vec3 c, in float r) {
    return length(p.xy - c.xy) - r;
}

float sdCylY(in vec3 p, in vec3 c, in float r) {
    return length(p.xz - c.xz) - r;
}

float map(in vec3 p) {

    float d = 1e9;
    
    vec3 p1 = p;
    vec3 p2 = p;
    p1.yz *= sin((p1.y - sin(iTime * 0.343) * 0.9) * 60.0) * 0.04 + 1.0;
    p2.yz *= sin((p2.y - sin(iTime * 0.443) * 0.9) * 30.0) * 0.01 + 1.0;

    
    d = opUnion(d, sdSphere(p , vec3(0.0,  6.0, 0.0)                      , 5.0));
    d = opMinus(d, sdSphere(p , vec3(0.0,  6.0, 0.0)                      , 4.8));
    d = opMinus(d, sdSphere(vec3(abs(p.x), p.yz) , vec3(0.9, 1.8, 0.0)   , 1.0 + sin(gTime) * 0.1));
    d = opIntsc(d, sdSphere(vec3(abs(p.x), p.yz) , vec3(0.9, 1.8, 0.0)   , 1.3));
    d = opUnion(d, sdSphere(p1, vec3( 1.1, sin(iTime * 0.343) * 0.9, 0.0), 0.5));
    d = opUnion(d, sdSphere(p2, vec3(-1.1, sin(iTime * 0.443) * 0.9, 0.0), 0.5));
    d = opUnion(d, sdCylY  (vec3(p.xy, abs(p.z)) , vec3(0.0, 0.0, 6.0), 1.0));
    
    return d;
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

const float closeEps = 0.0001;

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
        t += d * 0.9;
        if (t > 150.0) {
            return t;
        }
    }
    return t;
}

vec3 diffuse(in vec3 n) {
    vec3 d1 = vec3(1.0, 1.0, 0.5) * (0.5 + 0.5 * dot(normalize(vec3( 0.0,  1.0, 0.0)), n));
    vec3 d2 = vec3(0.5, 1.0, 1.0) * (0.5 + 0.5 * dot(normalize(vec3(-1.0,  0.0, 0.0)), n));
    vec3 d3 = vec3(1.0, 1.0, 1.0) * (0.5 + 0.5 * dot(normalize(vec3( 1.0,  0.0, 0.0)), n));
    vec3 col = vec3(0.0);
    col += d1;
  //  col += d2;
    col += d3;
    col /= 3.0;
    return col;
}

vec3 ambient(in vec3 n) {
    return sky(-n);
}

vec3 shade(in vec3 ro, in vec3 rd, in float t, in int bouncesLeft) {
    vec3 col = vec3(0.0);
    float acc = 0.0;
    
    vec3 p = ro;
    
    while (bouncesLeft > 0) {
        p += rd * t;
        
        bouncesLeft -= 1;
        
        if (t > 100.0) {
            col += sky(rd);
            acc += 1.0;
            break;
        }
        else {
            vec3 n = calcNormal(p);
            col += diffuse(n) * 3.0;
            acc += 3.0;
            
            float fres = 1.0 - (dot(n, rd) * 0.5 + 0.5);
            acc += 1.0 - fres;
            
            rd = reflect(rd, n);
            
            t = march(p + n * closeEps * 5.0, rd);
            
        }
    }
    
    col /= acc;
    
    return col;
    
}

void mainImage( out vec4 RGBA, in vec2 XY )
{
    setupCoords(iResolution.xy, 0.78);
    setupTime(iTime);

    // pixel epsilon for smoothstep
    float smoothEps = gWorldFromScreenFac * 2.5;

    
    // draw something
    
    vec2 uv = worldFromScreen(XY);
    vec2 ms = worldFromScreen(iMouse.xy);
    
    vec3 cp = vec3(cos(gTime * 0.1), -0.2, sin(gTime * 0.1)) * 4.0;
    vec3 lt = vec3(0.0, 0.5, 0.0);
    vec3 cf = normalize(lt - cp);
    vec3 cr = cross(cf, vec3(0.0, 1.0, 0.0));
    vec3 cu = cross(cf, cr);
    vec3 ro = cp;
    vec3 rd = normalize(cf + (cr * uv.x + cu * uv.y) * 0.4);
    
    
    const int maxSteps = 100;
    
    float t = march(ro, rd);
    vec3 col = shade(ro, rd, t, 17);
    
    RGBA = vec4(col, 1.0);
}



//////////////////////////////////////////////////////////////////////////////

vec3 sky(in vec3 rd) {
    vec3 col = rd * 0.5 + 0.5;
    col /= max(col.r, max(col.g, col.b));
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


#ifdef GRIMOIRE
out vec4 fragColor; void main() { mainImage(fragColor, gl_FragCoord.xy); }
#endif
