// buffer A runs a raytrace of a single ray through a hexagon
// outputs a bunch of line segments for rendering.

#include <common.glsl>

float gMyTime = 0.0;

void mainImage(out vec4 RGBA, in vec2 XY) {

    gMyTime = iTime * PI2;

    vec2 uv = XY / min(iResolution.x, iResolution.y);

    float zoom = 20.0;

    float s = sin(uv.x * zoom) * sin(uv.y * zoom + gMyTime * 0.3) * 0.5 + 0.5;
    s = smoothstep(0.4, 0.6, s) * 0.9 + 0.1;

    RGBA = vec4(vec3(s), 1.0);
}

#ifdef GRIMOIRE
out vec4 fragColor; void main() { mainImage(fragColor, gl_FragCoord.xy); }
#endif
