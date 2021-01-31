// Fork of "ess de eff runner 1" by elenzil. https://shadertoy.com/view/3ldyzM
// 2021-01-02 16:41:48

#ifdef GRIMOIRE
#include <common.glsl>
#endif


float gMyTime = 0.0;


void mainImage(out vec4 RGBA, in vec2 XY) {
    ivec2 IJ = ivec2(XY);
    
    gMyTime = iTime * 3.14159 * 2.0;

    float smallRes = min(iResolution.x, iResolution.y);

    vec2  p = (XY - iResolution.xy * 0.5) / smallRes * 2.0;
    float d = sdScene(p, gMyTime);

    float c = 0.0;
    vec3  rgb = vec3(c);

    rgb += 0.5 * smoothstep(3.0 / smallRes, 0.0, d);
 //   rgb += sin(d * 80.0) * 0.03;
    
    for (int n = 0; n < numBalls; ++n) {
        float ballT = float(n) / float(numBalls);
        vec2 part1 = texelFetch(iChannel0, ivec2(n, 0), 0).xy;
        float bc = smoothstep(1.0 / smallRes, 0.0, length(part1 - p) - ballRad(ballT));
        rgb.r += bc * 0.3;
        rgb.g += bc * 0.5;
        rgb.b += bc * 0.9;
    }


    RGBA.rgba = vec4(rgb, 1.0);
}

#ifdef GRIMOIRE
out vec4 fragColor; void main() { mainImage(fragColor, gl_FragCoord.xy); }
#endif
