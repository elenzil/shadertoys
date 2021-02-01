// Fork of "ess de eff runner 1" by elenzil. https://shadertoy.com/view/3ldyzM
// 2021-01-02 16:41:48

#ifdef GRIMOIRE
#include <common.glsl>
#endif

float dirtLevel(float gx)
{
    float drtLev = -0.2;
    // high freq
    drtLev += sin(gx * 7.0 - cos(gx * 2.31) * 1.7) * 0.05;
    // low freq
    drtLev += sin(gx * 1.1 + sin(gx * 0.4 ) * 1.4) * 0.3;
    return drtLev;
}

vec2 dirtNormal(float gx, float dirtLevelAtGx) {
    const float eps = 0.001;
    float gxp = gx + eps;
    float dlp = dirtLevel(gxp);
    return normalize(vec2(-(dlp - dirtLevelAtGx), eps));
}

void mainImage(out vec4 RGBA, in vec2 XY) {
    ivec2 IJ = ivec2(XY);
    float smallRes = min(iResolution.x, iResolution.y);

    vec2  p = (XY - iResolution.xy * 0.5) / smallRes * 2.0;
    p *= 1.1;
    float d = sdScene(p, MYTIME);

    d = p.y + 1.0;

    float c = smoothstep(0.99, 1.01, d);
    vec3  rgb = vec3(c);

    vec2 g = p;

    float scrollSpeed = 0.02;
    g.x += MYTIME * scrollSpeed;

    const vec3 skyTop = vec3(0.1, 0.0, 0.4);
    const vec3 skyBot = vec3(0.7, 0.5, 0.4);
    float skyF = p.y * 0.5 + 0.5;
    rgb = mix(skyBot, skyTop, skyF);

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

    float bpx = sin(MYTIME * 0.08);
    vec2 bc = vec2(bpx + MYTIME * scrollSpeed, 0.0);
    float drtLevC = dirtLevel(bc.x);
    bc.y = drtLevC;
    bc.y += 0.05;
    bc += dirtNormal(bc.x, drtLevC) * 0.03;

    // todo: calculate velocity of ball
    // rgb += rendPlayer(g, bc, ballVel)

    rgb += smoothstep(5.1, 5.0, length(g - bc) * 95.0) * 0.2;
    

    RGBA.rgba = vec4(rgb, 1.0);
}

#ifdef GRIMOIRE
out vec4 fragColor; void main() { mainImage(fragColor, gl_FragCoord.xy); }
#endif
