
void mainImage(out vec4 outRGBA, in vec2 XY)
{
    discard;
}


// grimoire bindings
out vec4 fragColor; void main() { mainImage(fragColor, gl_FragCoord.xy); }
