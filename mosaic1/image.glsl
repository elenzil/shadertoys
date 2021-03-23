// Fork of "ess de eff runner 1" by elenzil. https://shadertoy.com/view/3ldyzM
// 2021-01-02 16:41:48

#ifdef GRIMOIRE
#include <common.glsl>
#endif

void mainImage(out vec4 RGBA, in vec2 XY) {
    ivec2 IJ = ivec2(XY);

    vec3 rgb = texelFetch(iChannel0, IJ, 0).rgb;
    

    RGBA.rgba = vec4(rgb, 1.0);
}

#ifdef GRIMOIRE
out vec4 fragColor; void main() { mainImage(fragColor, gl_FragCoord.xy); }
#endif
