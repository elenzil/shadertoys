



void mainImage(out vec4 RGBA, in vec2 XY)
{

    ivec2 IJ = ivec2(XY);
    vec2  UV = XY / iResolution.xy;
    vec2  uv = (XY - iResolution.xy / 2.0) / (0.5 * min(iResolution.x, iResolution.y));

    vec4 bufa = texelFetch(iChannel0, IJ, 0);


    RGBA.rgba = bufa;

    RGBA.b = smoothstep(0.9, 1.0, length(uv));
    
    if (XY.y < 50.0) {
        RGBA.rgb += vec3(sin(iTime) * 0.5 + 0.5);
    }
}

#ifdef GRIMOIRE
out vec4 fragColor; void main() { mainImage(fragColor, gl_FragCoord.xy); }
#endif
