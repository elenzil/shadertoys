
#ifdef GRIMOIRE
#include <common.glsl>
#endif

// 0, 0:
// [0] = is mouse down
// [1] = is time frozen
// [2] = current time
// [3] = unused


void mainImage(out vec4 RGBA, in vec2 XY) {
    ivec2 IJ = ivec2(XY);

    if (iFrame == 0 || IJ.x != 0 || IJ.y != 0) {
        RGBA = vec4(0.0);
        return;
    }

    RGBA = texelFetch(iChannel0, IJ, 0);
    bool  mouseWasDown = RGBA[0] == 1.0;
    bool  timeIsFrozen = RGBA[1] == 1.0;
    float time         = RGBA[2];

    bool mouseIsDown = iMouse.z > 0;

    timeIsFrozen = timeIsFrozen ^^ (!mouseIsDown && mouseWasDown);

    if (!timeIsFrozen) {
        time += iTimeDelta;
    }

    RGBA[0] = mouseIsDown  ? 1.0 : 0.0;
    RGBA[1] = timeIsFrozen ? 1.0 : 0.0;
    RGBA[2] = time;

}

#ifdef GRIMOIRE
out vec4 fragColor; void main() { mainImage(fragColor, gl_FragCoord.xy); }
#endif

