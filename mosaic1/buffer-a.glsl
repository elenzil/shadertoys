
#ifdef GRIMOIRE
#include <common.glsl>
#endif

// 0, 0:
// x = is mouse down
// y = did mouse just become down this very frame
// z = writing or erasing


void mainImage(out vec4 RGBA, in vec2 XY) {
    ivec2 IJ = ivec2(XY);
    ivec2 NM = IJ / cellSize;

    if (iFrame < 1) {
        RGBA = vec4(0.0);
    }
    else {
        RGBA = texelFetch(iChannel0, IJ, 0);
    }

    vec4 mouseInfo = texelFetch(iChannel0, ivec2(0), 0);

    bool mouseIsDown  = iMouse.z > 0;
    bool mouseWasDown = mouseInfo.x == 1.0;
    bool mouseJustBecameDown = mouseIsDown && !mouseWasDown;

    float writeVal = mouseInfo.z;
    ivec2 mNM = ivec2(iMouse.xy) / cellSize;

    if (mouseJustBecameDown) {
        // read the bitmap
       vec4 bitmapInfo = texelFetch(iChannel0, mNM + ivec2(0, 1), 0);
       writeVal = 1.0 - bitmapInfo.x;
    }

    if (IJ.y == 0) {
        if (IJ.x == 0) {
            RGBA.x = float(mouseIsDown);
            RGBA.y = float(mouseJustBecameDown);
            RGBA.z = writeVal;
        }
    }

    if (mouseIsDown) {
        if (IJ == mNM + ivec2(0, 1)) {
            RGBA.x = writeVal;
        }
    }
}

#ifdef GRIMOIRE
out vec4 fragColor; void main() { mainImage(fragColor, gl_FragCoord.xy); }
#endif

