/////////////////////////
// this buffer is the SDF scene


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

    mat2 r1 = rot2(gMyTime * 0.01);
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
    gMyTime = iTime * 3.14159 * 2.0 * 0.0;

    float smallRes = min(iResolution.x, iResolution.y);

    vec2  p  = (XY - iResolution.xy * 0.5) / smallRes * 2.0;

    float d   = sdScene(p);
    vec2  g   = gradScene(p, d);
    float gm  = length(g);

    RGBA.rgba = vec4(d, g.x, g.y, gm);
}

#ifdef GRIMOIRE
out vec4 fragColor; void main() { mainImage(fragColor, gl_FragCoord.xy); }
#endif
