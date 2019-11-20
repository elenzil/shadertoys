


mat2 rot(in float rads) {
    return mat2(sin(rads), cos(rads), -cos(rads), sin(rads));
}

void mainImage(out vec4 RGBA, in vec2 XY)
{
    RGBA.a   = 1.0;

    XY -= iResolution.xy * 0.5;
    XY *= rot(-iTime);
    XY += iResolution.xy * 0.5;

    float c = int(XY.x)/40%2 ^ int(XY.y)/40%2;
    vec3 rgb = vec3(c);
    RGBA.rgb = rgb;
}

#ifdef GRIMOIRE
out vec4 fragColor; void main() { mainImage(fragColor, gl_FragCoord.xy); }
#endif
