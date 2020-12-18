// buffer A runs a raytrace of a single ray through a hexagon
// outputs a bunch of line segments for rendering.

#include <common.glsl>

float gMyTime = 0.0;

void mainImage(out vec4 RGBA, in vec2 XY) {

    gMyTime = iTime * PI2;

    float zoom = 0.1;

    float s = sin(XY.x * zoom) * sin(XY.y * zoom + gMyTime * 0.3) * 0.5 + 0.5;

    RGBA = vec4(vec3(s), 1.0);
}

#ifdef GRIMOIRE
out vec4 fragColor; void main() { mainImage(fragColor, gl_FragCoord.xy); }
#endif
