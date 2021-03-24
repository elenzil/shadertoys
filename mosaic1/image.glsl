#ifdef GRIMOIRE
#include <common.glsl>
#endif

const float cellZoom = 1.0 / 0.4;  // larger = smaller cell contents

const float smoothEpsilon = 5.0 / cellSize;
const float smoothLimA    = +smoothEpsilon;
const float smoothLimB    = -smoothEpsilon;

float opUnn(float a, float b) {
    return min(a, b);
}

float opInt(float a, float b) {
    return max(a, b);
}

float smst(float t) {
    return smoothstep(smoothLimA, smoothLimB, t);
}

float map_topHalf(vec2 p) {
    return -p.y;
}

float map_leftHalf(vec2 p) {
    return -p.x;
}

// a circle
float map_0000_0000(vec2 p) {
    return dot(p, p) - 1.0;
}

// a vertical bar
float map_0001_0001(vec2 p) {
    return abs(p.x) - 1.0;
}

// 4-way intersection
float map_0101_0101(vec2 p) {
    return opUnn(map_0001_0001(p), map_0001_0001(p.yx));
}

// a cul-de-sac going upwards
float map_0000_0001(vec2 p) {
    return opUnn(map_0000_0000(p), opInt(map_topHalf(p), map_0001_0001(p)));
}

// an elbow top to right
float map_0100_0001(vec2 p) {
    return opUnn(map_0000_0001(p), map_0000_0001(p.yx));
}

// a T with trunk to the right
float map_0101_0001(vec2 p) {
    return opUnn(map_0001_0001(p), map_0000_0001(p.yx));
}

float map(vec2 xy, int patternID) {
    vec2 Xy = vec2(-xy.x,  xy.y);
    vec2 xY = vec2( xy.x, -xy.y);
    vec2 XY = -xy;
    vec2 yx =  xy.yx;
    vec2 Yx = vec2(-xy.y,  xy.x);
    vec2 yX = vec2( xy.y, -xy.x);

    switch (patternID) {
        case -1: return 2.0;
        default: return 2.0;


        /////////////////////////////////////////////////
        // core simple patterns

        // dot
        case 0x00: return map_0000_0000(xy); // 0000_0000

        // end from up
        case 0x01: return map_0000_0001(xy); // 0000_0001

        // vertical pipe
        case 0x11: return map_0001_0001(xy); // 0001_0001

        // elbow top to right
        case 0x41: return map_0100_0001(xy); // 0100_0001

        // T to right
        case 0x51: return map_0101_0001(xy); // 0101_0001

        // plus
        case 0x55: return map_0101_0101(xy); // 0101_0101

        /////////////////////////////////////////////////
        // reflection & rotations of the simple patterns

        // end
        case 0x02: return map_0000_0001(yX); // 0000_0010
        case 0x04: return map_0000_0001(xY); // 0000_0100
        case 0x08: return map_0000_0001(yx); // 0000_1000

        // pipe
        case 0x44: return map_0001_0001(yx); // 0100_0100


        // elbow
        case 0x05: return map_0100_0001(Xy); // 0000_0101
        case 0x50: return map_0100_0001(xY); // 0101_0000
        case 0x14: return map_0100_0001(XY); // 0001_0100

        // T
        case 0x15: return map_0101_0001(Xy); // 0001_0101
        case 0x45: return map_0101_0001(yx); // 0100_0101
        case 0x54: return map_0101_0001(Yx); // 0101_0100
    }
}

bool wiggle = false;

vec3 fillCell(vec2 p, int patternID) {
    vec2  pz     = p * cellZoom;
    if (wiggle) {
        pz.x += cos(p.y * 3.14159 * 2.0 + iTime) * 0.15;
        pz.y += cos(p.x * 3.14159 * 2.0 + iTime) * 0.15;
    }
    float d      = map(pz, patternID);
    vec3  rgb    = vec3(smst(d));
    rgb.g = max(rgb.g, smst(1.0 - max(abs(p.x), abs(p.y))));
    return vec3(rgb);
}

int fetchPattern(ivec2 NM) {
    const ivec2 offset = ivec2(0, 1);

    float c = texelFetch(iChannel0, NM + offset, 0).x;

    if (c == 0) {
        return -1;
    }

    return 0;
}

void mainImage(out vec4 RGBA, in vec2 XY) {
    ivec2 IJ = ivec2(XY);
    ivec2 NM = IJ / cellSize;
    vec2  p  = vec2(IJ - (NM * cellSize)) / float(cellSize) * 2.0 - 1.0;

    int patternID = NM.x + NM.y * 16;

    patternID = patternID % 0x100;

    patternID = fetchPattern(NM);


    vec3 rgb = fillCell(p, patternID);

    if (max(NM.x, NM.y) >= 16) {
            rgb *= 0.0;
    }


    RGBA.rgba = vec4(rgb, 1.0);
}

#ifdef GRIMOIRE
out vec4 fragColor; void main() { mainImage(fragColor, gl_FragCoord.xy); }
#endif
