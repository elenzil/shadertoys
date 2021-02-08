// Fork of "ess de eff runner 1" by elenzil. https://shadertoy.com/view/3ldyzM
// 2021-01-02 16:41:48

#ifdef GRIMOIRE
#include <common.glsl>
#endif

void rendBall(inout vec3 rgb, in vec2 p, in vec2 c, in float r, in float theta, in float w) {

    const float numSpokes = 4.0;

    vec2 cp = p - c;
    float distSq = dot(cp, cp);
    float rSq = r * r;
    if ((distSq > rSq * 1.6) || (distSq < rSq * 0.7)) {
        return;
    }

    float dist = sqrt(distSq);

    float ang = atan(cp.y, cp.x);

    ang += sin(dist * 300.0) * 0.05;

    vec3 col = vec3(sin(ang * numSpokes + theta) * 0.45 + 0.55);

    rgb = mix(rgb, col, smoothstep(w + 0.01, w, abs(dist - r)));

}

void mainImage(out vec4 RGBA, in vec2 XY) {
    ivec2 IJ = ivec2(XY);
    float smallRes = min(iResolution.x, iResolution.y);

    vec2  p = (XY - iResolution.xy * 0.5) / smallRes * 2.0;
    p *= 1.1;

    vec2 g = p;

    g.x += MYTIME * scrollSpeed;

    // sky
    const vec3 skyTop = vec3(0.1, 0.0, 0.4);
    const vec3 skyBot = vec3(0.7, 0.5, 0.4);    
    float skyF = p.y * 0.5 + 0.5;
    vec3 rgb = mix(skyBot, skyTop, skyF);

    float drtLev = dirtLevel(g.x);

    // grass
    if (g.y < drtLev + 0.015 - min(0.0, drtLev * 0.05)) {
        rgb = mix(rgb, vec3(0.0, 0.3, 0.0), 0.7);
    }

    // wheel in the sky keeps on turning
    vec3 tmp3 = rgb;
    rgb = mix(tmp3, rendBall(rgb, g, screenToGame(vec2(0.0, 0.2), MYTIME, scrollSpeed), 0.6, iTime * 0.91, 0.05), 0.2);

    // dirt
    const vec3 drtTop = vec3(0.4, 0.2, 0.1);
    const vec3 drtBot = vec3(0.6, 0.3, 0.1);
    float drtF = g.y * 2.0 + 2.0;
    vec3 drt = mix(drtBot, drtTop, drtF);
    drt += smoothstep(0.6, 0.99, sin((g.x       ) * 61.0)) * 0.1 * max(0.0, drtF * 2.0 - 1.5 - drtLev * 2.0);
    drt -= smoothstep(0.6, 0.99, sin((g.x + 0.25) * 61.0)) * 0.1 * max(0.0, drtF * 2.0 - 1.5 - drtLev * 2.0);
    rgb = mix(rgb, drt, smoothstep(drtLev + 0.01, drtLev - 0.01, p.y));


    for (int n = 0; n < numBalls; ++n) {
        vec4 ballInfo1 = texelFetch(iChannel0, ivec2(n, 0), 0);
        vec4 ballInfo2 = texelFetch(iChannel0, ivec2(n, 1), 0);
        vec2 bc = ballInfo1.xy;
//        rgb += smoothstep(5.1, 5.0, length(g - bc) * 95.0) * 0.2;
        rgb = rendBall(rgb, g, bc, ballRad, ballInfo2.x, 0.005);
    }
    

    RGBA.rgba = vec4(rgb, 1.0);
}

#ifdef GRIMOIRE
out vec4 fragColor; void main() { mainImage(fragColor, gl_FragCoord.xy); }
#endif
