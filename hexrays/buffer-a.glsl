// buffer A runs a raytrace of a single ray through a hexagon
// outputs a bunch of line segments for rendering.

#include <common.glsl>

void mainImage(out vec4 RGBA, in vec2 XY) {

    int   polySides = 27;
    float polyRad   = 300.0;

    const float zoom = 1.0;

    ivec2 IJ = ivec2(XY / zoom);
    ivec2 Ij = ivec2(IJ.x, iResolution.y / zoom - IJ.y - 1);

    RGBA = vec4(0.0);

    if (Ij.y == 0) {
        // top row encodes the polygon
        if (Ij.x == 0) {
            // first pixel of top row has the number of sides
            RGBA.r = polySides;
        }
        else if (Ij.x - 1 < polySides) {
            // encode the point
            float thetaA = float(Ij.x - 1) * PI2 / float(polySides);
            thetaA += iTime * PI2 / 40.0;
            float thetaB = thetaA + PI2 / float(polySides);
            vec2 ptA = vec2(cos(thetaA), sin(thetaA)) * polyRad;
            vec2 ptB = vec2(cos(thetaB), sin(thetaB)) * polyRad;
            lineSeg_t ls = lineSeg_t(ptA, ptB);
            RGBA = vec4(ls.ptA, ls.ptB);
        }
    }
}

#ifdef GRIMOIRE
out vec4 fragColor; void main() { mainImage(fragColor, gl_FragCoord.xy); }
#endif
