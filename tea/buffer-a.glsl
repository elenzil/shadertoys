const float gutterWidth  =   50.0;


void mainImage(out vec4 RGBA, in vec2 XY) {
    ivec2 IJ = ivec2(XY);
    if (IJ.x + IJ.y > 0) {
        discard;
    }

    RGBA = texelFetch(iChannel0, IJ, 0);

    if (iFrame < 5) {
        RGBA.r = 50.0;
    }
    
    if (iMouse.z > 0.0 && iMouse.z < gutterWidth) {
        RGBA.r = iMouse.y;
    }

}

// grimoire bindings
out vec4 fragColor; void main() { mainImage(fragColor, gl_FragCoord.xy); }

