// orion elenzil 20190528

void mainImage(out vec4 RGBA, in vec2 XY) {
    ivec2 IJ = ivec2(XY);

    if (any(greaterThan(IJ, ivec2(1, 1)))) {
        discard;
    }

    if (iFrame < 3) {
        RGBA = vec4(0.0);
        return;
    }


    RGBA = texelFetch(iChannel0, IJ, 0);

    if (iMouse.z > 0.0) {
        if (RGBA.r == 0.0) {
            RGBA.r = iTime;
        }
    }
    else {
        RGBA.r = 0.0;
    }
}


#ifdef GRIMOIRE
out vec4 fragColor; void main() { mainImage(fragColor, gl_FragCoord.xy); }
#endif
