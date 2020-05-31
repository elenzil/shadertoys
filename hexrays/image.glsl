struct lineSeg_t {
    vec2  ptA;
    vec2  ptB;
};

struct lineSegEx_t {
    lineSeg_t pts;
    float     len;  // |a->b|
    vec2      dir;  // a->b, normalized
    vec2      nrm;  // dir rotated 90 deg ccw
                    // todo precalc this stuff in bufferA
};

float uvScale = 1.0;

float leftHandDistLine(in vec2 pt, in lineSegEx_t lse) {
    vec2 ptA_pt = pt - lse.pts.ptA;
    return dot(ptA_pt, lse.nrm);
}

float lineCircle(in vec2 pt, in vec2 c, in float r, in float width) {
    return smoothstep(width + 4.0, width, abs(length(pt - c) - r));
}

float lineSegment(in vec2 pt, in lineSegEx_t lse, in float width) {

    float d = leftHandDistLine(pt, lse);
    return smoothstep(width + 4.0, width, abs(d));
}

lineSegEx_t calcLineSegDetails(in lineSeg_t ls) {
    lineSegEx_t lse;

    lse.pts = ls;
    vec2 vAB = ls.ptB - ls.ptA;
    lse.len = length(vAB);
    lse.dir = vAB / lse.len;
    lse.nrm = vec2(-lse.dir.y, lse.dir.x);

    return lse;
}

vec4 renderPolygon(vec2 pt) {
    int topLine = int(iResolution.y) - 1;
    int numSides = int(texelFetch(iChannel0, ivec2(0, topLine), 0).r);

    float c = 0;

    for (int n = 0; n < numSides; ++n) {
        vec4 txl = texelFetch(iChannel0, ivec2(n + 1, topLine), 0);
        lineSeg_t ls = lineSeg_t(txl.xy, txl.zw);

        lineSegEx_t lse = calcLineSegDetails(ls);

        c += lineCircle (pt, ls.ptA, lse.len / 2.0, 4.0);
        c += lineSegment(pt, lse, 4.0);
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
