/////////////////////////
//
// dynamics.
// for each object:
// d1 = ivec2(n * 2, n * 2    )
// d2 = ivec2(n * 2, n * 2 + 1)
//
// d1.xy = particle position
// d1.z  = particle theta
// d1.w  = particle radius
//
// d2.xy = particle velocity (dPosition)
// d2.z  = angular speed     (dTheta)
// d2.w  = unused
//



#ifdef GRIMOIRE
#include <common.glsl>
#endif

const float playerOffsetX = -0.2;
const float playerRad     =  0.02;

void mainImage(out vec4 RGBA, in vec2 XY) {

    ivec2  IJ = ivec2(XY);
    int     n = IJ.x;
    vec4   d1 = texelFetch(iChannel0, ivec2(n, 0), 0);
    vec4   d2 = texelFetch(iChannel0, ivec2(n, 1), 0);
    vec2  pos = d1.xy;
    vec2  vel = d2.xy;
    float ang = d1.z;
    float avl = d2.z;
    float rad = d1.w;

    if (iFrame == 0) {
        pos = screenToGame(vec2(playerOffsetX, 0.0), MYTIME, scrollSpeed);
        vel = vec2(0.0);
        ang = 0.0;
        avl = 0.0;
        if (n == 0) {
            rad = playerRad;
        }
        else {
            // radius 0 means no render.
            rad = 0.0;
        }
    }

    float drtLev    = dirtLevel(pos.x);
    float drtLevRad = drtLev + rad;

    if (n == 0) {
        pos.y = drtLevRad;
    }



    RGBA = vec4(pos, vel);
}

#ifdef GRIMOIRE
out vec4 fragColor; void main() { mainImage(fragColor, gl_FragCoord.xy); }
#endif

