#include <common.glsl>

const float epsilonGradient = 0.0001;

float gMyTime = 0;



// https://www.iquilezles.org/www/articles/distfunctions2d/distfunctions2d.htm
float opUnion( float d1, float d2 ) {  return min(d1,d2); }
float opSubtraction( float d1, float d2 ) { return max(-d1,d2); }
float opSubtraction2( float d1, float d2 ) { return max(d1,-d2); }
float opIntersection( float d1, float d2 ) { return max(d1,d2); }
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

    return d;
}

vec2 gradScene(in vec2 p, in float d_at_p) {
    float dex = sdScene(p + vec2(epsilonGradient, 0.0));
    float dey = sdScene(p + vec2(0.0, epsilonGradient));
    return vec2(dex - d_at_p, dey - d_at_p);
}

void mainImage(out vec4 RGBA, in vec2 XY) {
    gMyTime = iTime * 3.14159 * 2.0;

    float smallRes = min(iResolution.x, iResolution.y);

    ivec2 IJ = ivec2(XY);
    vec2  UV = XY / iResolution.xy;
    vec2  uv = (XY - iResolution.xy * 0.5) / smallRes * 2.0;;

    vec2 p = uv;

    float d   = sdScene(p);
    vec2  g   = gradScene(p, d);
    vec2  gn  = normalize(g);
    vec2  gnu = gn * 0.5 + 0.5;

    float c = 1.0;
    vec3  rgb = vec3(c);
    rgb.yz *= (gnu * 0.7) + 0.3;

    vec3  accum = vec3(0.0);
    float total = 0.0;
    vec2 q = UV;
    const float nEnd = 10.0;
    for (float n = 0.0; n < nEnd; ++n) {
        float contrib = (1.0 - (n + 1.0) / nEnd);
        accum += contrib * texture(iChannel0, q).rgb;
        total += contrib;

        q += gn * 0.01;
    }

    accum /= total;

    rgb *= accum;

    rgb += 0.4 * smoothstep(0.05, 0.0, d);
    rgb += 0.2 * smoothstep(0.005, 0.0, d);

    RGBA.rgba = vec4(rgb, 1.0);
}

#ifdef GRIMOIRE
out vec4 fragColor; void main() { mainImage(fragColor, gl_FragCoord.xy); }
#endif
