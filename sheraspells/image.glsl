#include <common.glsl>

float uvScale = 1.0;

float dAnnulus(in vec2 p, in vec2 c, float r, float lw) {
    float dpc = length(p - c);
    float d1  = dpc - (r - lw * 0.5);
    float d2  = dpc - (r + lw * 0.5);
    float d   = max(-d1, d2);
    return d;
}

void mainImage(out vec4 RGBA, in vec2 XY) {
    float lw = 0.1;

    vec2  xy  = XY - iResolution.xy / 2.0;
    vec2  UV  = XY / iResolution.xy;
    uvScale   = 2.0 / min(iResolution.x, iResolution.y);
    uvScale *= 1.3;
    vec2  uv  = (XY - iResolution.xy / 2.0) * uvScale;

    float d = 1e9;
    float suk = 0.08;

    d = opSmoothUnion(d, dAnnulus(uv, vec2(-0.5, 0.0), 1.0 , lw), suk);
    d = opSmoothUnion(d, dAnnulus(uv, vec2( 0.5, 0.0), 1.0 , lw), suk);
    d = opSmoothUnion(d, dAnnulus(uv, vec2( 0.0, 0.0), 0.3, lw), suk);

    float c1 = smoothstep(0.0 , 0.01, d);
    float c2 = mix       (0.01, 4.0 , d);
    float c  = mix       (c1  , c2  , 0.65);

    vec3 rgb = mix(vec3(0.6, 0.0, 0.7), vec3(0.0), c);

    RGBA = vec4(rgb, 1.0);

}

#ifdef GRIMOIRE
out vec4 fragColor; void main() { mainImage(fragColor, gl_FragCoord.xy); }
#endif
