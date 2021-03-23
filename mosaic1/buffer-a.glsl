/////////////////////////
// this buffer is the dynamics, based on the SDF

#ifdef GRIMOIRE
#include <common.glsl>
#endif

vec3 someColors(in vec2 XY) {

//    return vec3((int(XY.x) / 50) % 2);

    float smallRes = min(iResolution.x, iResolution.y);
    vec2  p = (XY - iResolution.xy * 0.5) / smallRes * 2.0;

    p *= PI2;

    vec3 rgb;

    p *= rot2(iTime *  0.1);
    rgb.r = cos(p.x * 1.23) + cos(p.y * 1.04);
    p *= rot2(iTime * -0.15);
    rgb.g = cos(p.x * 1.31) + cos(p.y * 1.24);
    p *= rot2(iTime *  0.1);
    rgb.b = cos(p.x * 1.21) + sin(p.y * 1.41);

    rgb = rgb * 0.25 + 0.5;

    rgb *= vec3(sin(length(p) * 1.5) * 0.1 + 0.9);

    return rgb;
}

float meas(in vec3 rgb) {
    return dot(rgb, rgb);
}

const ivec2 iUp = ivec2( 0, 1);
const ivec2 iUL = ivec2(-1, 1);
const ivec2 iUR = ivec2( 1, 1);

bool amRight(int i) {
    return bool(i & 0x1);
}

void mainImage(out vec4 RGBA, in vec2 XY) {
    float f = sin(iTime * 0.5) * 0.2 + 0.8;
    float g = sin((XY.x - iResolution.x * 0.5) * 0.04 * f);
    bool reset = (iFrame == 0 || iMouse.z > 10.0); 
    if (reset || (XY.y > iResolution.y * 0.75 + g * iResolution.y * 0.1 * f * f * f)) {
        RGBA = vec4(someColors(XY), 1.0);
        RGBA.a = g;
        return;
    }

    ivec2 IJ = ivec2(XY);
    RGBA = texelFetch(iChannel0, IJ + iUp, 0);
    g = RGBA.a;
    RGBA.rgb *= (g * 0.002 + 0.998);

    if (XY.y > iResolution.y * 0.5) {
        return;
    }

  //  return;

    int offX = IJ.y & 0x1;

    bool amR = amRight(IJ.x + offX);
    bool amL = !amR;

    vec4 rgbaOther;
    if (amR) {
        rgbaOther = texelFetch(iChannel0, IJ + iUL, 0);
    }
    else {
        rgbaOther = texelFetch(iChannel0, IJ + iUR, 0);
    }

    for (int n = 0; n < 4; ++n) {
        float magSqSelf = dot(RGBA     [n], RGBA     [n]);
        float magSqOthr = dot(rgbaOther[n], rgbaOther[n]);

        if (amL && (magSqOthr < magSqSelf) && (XY.x < iResolution.x  - 1.0)) {
            RGBA[n] = rgbaOther[n];
        }
        else if (amR && (magSqOthr >= magSqSelf) && (XY.x > 0.0)) {
            RGBA[n] = rgbaOther[n];
        }
    }

}

#ifdef GRIMOIRE
out vec4 fragColor; void main() { mainImage(fragColor, gl_FragCoord.xy); }
#endif

