// Fork of "ess de eff runner 1" by elenzil. https://shadertoy.com/view/3ldyzM
// 2021-01-02 16:41:48

#ifdef GRIMOIRE
#include <common.glsl>
#endif

void mainImage(out vec4 RGBA, in vec2 XY) {
    ivec2 IJ = ivec2(XY);
    float smallRes = min(iResolution.x, iResolution.y);

    vec2  p = (XY - iResolution.xy * 0.5) / smallRes * 2.0;
    p *= 1.1;

    vec2 g = p;

    g.x += MYTIME * scrollSpeed;

    const vec3 skyTop = vec3(0.1, 0.0, 0.4);
    const vec3 skyBot = vec3(0.7, 0.5, 0.4);
    float skyF = p.y * 0.5 + 0.5;
    vec3 rgb = mix(skyBot, skyTop, skyF);

    const vec3 drtTop = vec3(0.4, 0.2, 0.1);
    const vec3 drtBot = vec3(0.6, 0.3, 0.1);
    float drtF = g.y * 2.0 + 2.0;
    vec3 drt = mix(drtBot, drtTop, drtF);
    float drtLev = dirtLevel(g.x);
    drt += smoothstep(0.6, 0.99, sin((g.x      ) * 61.0)) * 0.1 * max(0.0, drtF * 2.0 - 1.5 - drtLev * 2.0);
    drt -= smoothstep(0.6, 0.99, sin((g.x + 0.25) * 61.0)) * 0.1 * max(0.0, drtF * 2.0 - 1.5 - drtLev * 2.0);
    rgb = mix(rgb, drt, smoothstep(drtLev + 0.01, drtLev - 0.01, p.y));

    if (abs(drtLev - g.y + 0.01) < 0.01) {
        rgb.rb += -0.3;
    }

    for (int n = 0; n < numBalls; ++n) {
    vec4 ballInfo = texelFetch(iChannel0, ivec2(n, 0), 0);
    vec2 bc = ballInfo.xy;
    rgb += smoothstep(5.1, 5.0, length(g - bc) * 95.0) * 0.2;
    }
    

    RGBA.rgba = vec4(rgb, 1.0);
}

#ifdef GRIMOIRE
out vec4 fragColor; void main() { mainImage(fragColor, gl_FragCoord.xy); }
#endif
