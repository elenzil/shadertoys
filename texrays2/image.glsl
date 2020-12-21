#ifdef GRIMOIRE
#include <common.glsl>
#endif

const float epsilonGradient = 0.0001;

float gMyTime = 0.0;



// https://www.iquilezles.org/www/articles/distfunctions2d/distfunctions2d.htm
float opUnion( float d1, float d2 ) {  return min(d1,d2); }
float opSubtraction( float d1, float d2 ) { return max(-d1,d2); }
float opSubtraction2( float d1, float d2 ) { return max(d1,-d2); }
float opIntersection( float d1, float d2 ) { return max(d1,d2); }
float sdCircle( vec2 p, float r )
{
    return length(p) - r;
}

float sdAnnulus(in vec2 p, in float r1, in float r2) {
    return opSubtraction2(sdCircle(p, r2), sdCircle(p, r1));
}

float sdPentagon( in vec2 p, in float r )
{
    const vec3 k = vec3(0.809016994,0.587785252,0.726542528);
    p.x = abs(p.x);
    p -= 2.0*min(dot(vec2(-k.x,k.y),p),0.0)*vec2(-k.x,k.y);
    p -= 2.0*min(dot(vec2( k.x,k.y),p),0.0)*vec2( k.x,k.y);
    p -= vec2(clamp(p.x,-r*k.z,r*k.z),r);    
    return length(p)*sign(p.y);
}

float sdAnnularPentagon(in vec2 p, in float r1, in float r2) {
    return opSubtraction2(sdPentagon(p, r2), sdPentagon(p, r1));
}

mat2 rot2(float radians) {
    float s = sin(radians);
    float c = cos(radians);
    return mat2(s, c, -c, s);
}

float sdScene(in vec2 p) {
    float width = 0.03;

    float d = 1e9;

    mat2 r1 = rot2(gMyTime * 0.1);
    vec2 sep = vec2(0.3, 0.0);

    float pentRad = 0.5;
    float pr;

    pr = pentRad - 0.2 * (sin(gMyTime * 0.2) * 0.5 + 0.5);
    d = opUnion(d, sdAnnularPentagon(r1 * (p + sep), pr - width, pr));

    pr = pentRad - 0.2 * (cos(gMyTime * 0.2) * 0.5 + 0.5);
    d = opUnion(d, sdAnnularPentagon((p - sep) * r1, pr - width, pr));
    
    float circRad = 1.5;
    d = opUnion(d, sdAnnulus(p, circRad - width, circRad));

    return d;
}

vec2 gradScene(in vec2 p, in float d_at_p) {
    float dex = sdScene(p + vec2(epsilonGradient, 0.0));
    float dey = sdScene(p + vec2(0.0, epsilonGradient));
    return vec2(dex - d_at_p, dey - d_at_p);
}

void mainImage(out vec4 RGBA, in vec2 XY) {
    ivec2 IJ = ivec2(XY);
    
    // fetch scene SDF plus gradient and gradient magnitude
    vec4  sd = texelFetch(iChannel1, IJ, 0);

    float d   = sd.x;
    vec2  g   = sd.yz;
    vec2  gn  = g / sd.w;
    vec2  gnu = gn * 0.5 + 0.5;

    float c = 0.0;
    vec3  rgb = vec3(c);
//    rgb.yz *= gnu * 0.7;
    // rgb.yz *= g * 5000.0;
    // rgb.x  *= length(g) * 5000.0;

//        vec2 uv = smallRes * q / (2.0 * iResolution.xy) + 0.5;


    rgb += 0.5 * smoothstep(0.03, 0.0, d);
    
    float smallRes = min(iResolution.x, iResolution.y);
    vec2  p  = (XY - iResolution.xy * 0.5) / smallRes * 2.0;
    
  //  rgb = vec3(0.0);
    
    vec2 part1 = texelFetch(iChannel0, ivec2(0), 0).xy;
    rgb += smoothstep(0.01, 0.0, length(part1 - p) - ballRad);

    ivec2 pij = ivec2((iResolution.xy + part1 * smallRes) / 2.0);

    vec4 sdp1 = texelFetch(iChannel1, ivec2(pij), 0);

#if 0
    // calculate vector to zero
    float sdfVal = sdp1.x;
    vec2  sdfGrd = sdp1.yz;
    vec2  closestZero = part1 - sdp1.x * sdp1.yz / sdp1.w;
    rgb += smoothstep(0.01, 0.0, length(closestZero - p) - 0.1);
#endif

    RGBA.rgba = vec4(rgb, 1.0);
}

#ifdef GRIMOIRE
out vec4 fragColor; void main() { mainImage(fragColor, gl_FragCoord.xy); }
#endif
