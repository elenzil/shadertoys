struct lineSeg_t {
    vec2  ptA;
    vec2  ptB;
};

float uvScale = 1.0;

float outlineCircle(vec2 pt, vec2 c, float r, float width) {
    return smoothstep(r, r - width, length(pt - c));
}

vec4 renderPolygon(vec2 pt) {
    int topLine = int(iResolution.y) - 1;
    int numSides = int(texelFetch(iChannel0, ivec2(0, topLine), 0).r);

    float c = 0;

    for (int n = 0; n < numSides; ++n) {
        vec4 txl = texelFetch(iChannel0, ivec2(n + 1, topLine), 0);
        lineSeg_t ls = lineSeg_t(txl.xy, txl.zw);

        c += outlineCircle(pt, ls.ptA,sin(iTime) * 40.0 + 40.0, 2.0 * uvScale) * 0.1;
    }

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

    RGBA.b = smoothstep(1.0 - 2.0 * uvScale, 1.0, length(xy) - 200.0);
    RGBA.r = 1.0 - smoothstep(1.0 - 2.0 * uvScale, 1.0, length(xy) - 100.0);
    RGBA = (RGBA + renderPolygon(xy)) * 0.5;
    
    if (XY.y < 50.0) {
        RGBA.rgb *= vec3(sin(iTime * 3.0 + (UV.x * 12.0)) * 0.5 + 0.5);
    }

}

#ifdef GRIMOIRE
out vec4 fragColor; void main() { mainImage(fragColor, gl_FragCoord.xy); }
#endif
