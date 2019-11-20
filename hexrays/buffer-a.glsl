
void mainImage(out vec4 RGBA, in vec2 XY) {
    RGBA = vec4(1.0);
}

#ifdef GRIMOIRE
out vec4 fragColor; void main() { mainImage(fragColor, gl_FragCoord.xy); }
#endif
