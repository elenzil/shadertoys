#include <common.glsl>

float uvScale = 1.0;

float gMyTime  = 0.0;
float gMyTime2 = 0.0;

float dAnnulus(in vec2 p, in vec2 c, float r, float lr) {
    float dpc = length(p - c);
    float d1  = dpc - (r - lr);
    float d2  = dpc - (r + lr);
    float d   = max(-d1, d2);
    return d;
}

void mainImage(out vec4 RGBA, in vec2 XY) {
    gMyTime  = iTime * PI2;
    gMyTime2 = gMyTime * 0.1; 

    float lr  = 0.05;
    float lr1 = 0.05;
    float lr2 = 0.03;
    float lr3 = 0.02;

    vec2  xy  = XY - iResolution.xy / 2.0;
    vec2  UV  = XY / iResolution.xy;
    uvScale   = 2.0 / min(iResolution.x, iResolution.y);
    uvScale *= 2.0;
    vec2  uv  = (XY - iResolution.xy / 2.0) * uvScale;

    uv *= rot2(gMyTime2 * 0.321);

    float d = 1e9;
    float suk = 0.04;

    int pattern = int(sin(gMyTime * 0.1) + 1.0);
    if (pattern < 0) {
        pattern = 0;
    }
    else if (pattern > 1) {
        pattern = 1;
    }

    if (pattern == 0) {
        vec2 p1 = vec2(sin(gMyTime2 * 0.7) * 1.2, cos(gMyTime2 * 0.7 * 3.0 + PI) * 0.3);
        vec2 p2 = -p1;
        vec2 p3 = rot2(gMyTime2 *  1.0) * vec2(-1.45, 0.0);
        vec2 p4 = -p3;
        vec2 p5 = vec2(-p3.x, p3.y);
        vec2 p6 = -p5;

        d = opSmoothUnion(d, dAnnulus(uv, vec2( 0.0,  0.0), 1.5 , lr), suk);
        // d = opSmoothUnion(d, dAnnulus(uv, vec2(-0.5,  0.0), 1.0 , lr), suk);
        // d = opSmoothUnion(d, dAnnulus(uv, vec2( 0.5,  0.0), 1.0 , lr), suk);
        // d = opSmoothUnion(d, dAnnulus(uv, vec2( 0.0, -0.5), 1.0 , lr), suk);
        // d = opSmoothUnion(d, dAnnulus(uv, vec2( 0.0,  0.5), 1.0 , lr), suk);
        d = opSmoothUnion(d, dAnnulus(uv, p1, 0.3, lr), suk);
        d = opSmoothUnion(d, dAnnulus(uv, p2, 0.3, lr), suk);
        d = opSmoothUnion(d, sdCapsule2(uv, p3, p4, lr * 0.5), suk);
        d = opSmoothUnion(d, sdCapsule2(uv, p5, p6, lr * 0.5), suk);
        d = opSmoothUnion(d, sdCapsule2(uv, p1, p6, lr * 0.5), suk);
        d = opSmoothUnion(d, sdCapsule2(uv, p1, p4, lr * 0.5), suk);
        d = opSmoothUnion(d, sdCapsule2(uv, p2, p5, lr * 0.5), suk);
        d = opSmoothUnion(d, sdCapsule2(uv, p2, p3, lr * 0.5), suk);
    }
    else if (pattern == 1) {
        const float inset = 0.99;

        vec2  c1c = vec2(0.0, 0.0);
        float c1r = 1.5;

        vec2  d11  = vec2(-c1r * inset, 0.0);
        vec2  d12  = vec2( 0.0, c1r * 0.5);
        vec2  d13  = -d11;
        vec2  d14  = -d12;

        vec2  d21  = d11.yx;
        vec2  d22  = d12.yx;
        vec2  d23  = -d21;
        vec2  d24  = -d22;

        vec2  c2c = vec2(0.0, 0.0);
        float c2r = c1r * 0.3;

        d = opSmoothUnion(d, dAnnulus(uv, c1c, c1r, lr1), suk);

        d = opSmoothUnion(d, sdCapsule2(uv, d11, d12, lr2), suk);
        d = opSmoothUnion(d, sdCapsule2(uv, d12, d13, lr2), suk);
        d = opSmoothUnion(d, sdCapsule2(uv, d13, d14, lr2), suk);
        d = opSmoothUnion(d, sdCapsule2(uv, d14, d11, lr2), suk);
        d = opSmoothUnion(d, sdCapsule2(uv, d21, d22, lr2), suk);
        d = opSmoothUnion(d, sdCapsule2(uv, d22, d23, lr2), suk);
        d = opSmoothUnion(d, sdCapsule2(uv, d23, d24, lr2), suk);
        d = opSmoothUnion(d, sdCapsule2(uv, d24, d21, lr2), suk);

        d = opSmoothUnion(d, dAnnulus(uv, c2c, c2r, lr3), suk);
    }

    float c1 = smoothstep(0.0 , 0.01, d);
    float c2 = mix       (0.01, 6.0 , d);
    float c  = mix       (c1  , c2  , 0.65);

    vec3 rgb = mix(vec3(0.6, 0.0, 0.7), vec3(0.0), c);

    rgb += vec3(0.6, 0.6, 0.0) * smoothstep(0.03, 0.0, abs(d));

    RGBA = vec4(rgb, 1.0);

}

#ifdef GRIMOIRE
out vec4 fragColor; void main() { mainImage(fragColor, gl_FragCoord.xy); }
#endif
