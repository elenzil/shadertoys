#include <common.glsl>

float uvScale = 1.0;

float leftHandDistLine(in vec2 pt, in raySeg_t rs) {
    vec2 v = pt - rs.pnt;
    return dot(v, rs.nrm);
}

float rendCircle(in vec2 pt, in vec2 c, in float r, in float width) {
    return smoothstep(width + 4.0, width, abs(length(pt - c) - r));
}

float rendRaySeg(in vec2 pt, in raySeg_t rs, in float width) {

    float d = leftHandDistLine(pt, rs);
    return smoothstep(width + 4.0, width, abs(d));
}

vec4 renderPolygon(vec2 pt) {
    int topLine = int(iResolution.y) - 1;
    int numSides = int(texelFetch(iChannel0, ivec2(0, topLine), 0).r);

    float c = 0;

    for (int n = 0; n < numSides; ++n) {
        vec4 txl1 = texelFetch(iChannel0, ivec2((n * 2) + 0, topLine), 0);
        vec4 txl2 = texelFetch(iChannel0, ivec2((n * 2) + 1, topLine), 0);
        raySeg_t rs = unpackRaySeg(txl1, txl2);

        c += rendCircle(pt, rs.pnt, rs.len / 2.0, 4.0);
        //c += rendRaySeg(pt, rs, 4.0);
    }

//    c = min(1.0, c);

    return vec4(c);
}


void mainImage(out vec4 RGBA, in vec2 XY) {

    ivec2 IJ = ivec2(XY);
    vec2  xy = XY - iResolution.xy / 2.0;
    vec2  UV = XY / iResolution.xy;
    uvScale = 2.0 / min(iResolution.x, iResolution.y);
    vec2  uv = (XY - iResolution.xy / 2.0) * uvScale;

    vec4 bufa = texelFetch(iChannel0, IJ, 0);

    RGBA.rgba = bufa;

    RGBA = (RGBA + renderPolygon(xy)) * 0.5;
    
    if (XY.y < 50.0) {
        RGBA.r   += sin(iTime * 3.11 + (UV.x * 12.0)) * 0.5 + 0.5;
        RGBA.g   += sin(iTime * 3.22 + (UV.x * 12.0)) * 0.5 + 0.5;
        RGBA.b   += sin(iTime * 3.33 + (UV.x * 12.0)) * 0.5 + 0.5;
        RGBA.rgb -= smoothstep(0.9, 1.0, sin(iTime * 10.00 - (UV.x * 200.0 - UV.y * 10.0)));
    }

}

#ifdef GRIMOIRE
out vec4 fragColor; void main() { mainImage(fragColor, gl_FragCoord.xy); }
#endif
