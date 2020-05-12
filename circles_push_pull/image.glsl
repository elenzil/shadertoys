


mat2 rot(in float rads) {
    return mat2(sin(rads), cos(rads), -cos(rads), sin(rads));
}

float trapezoid(in float t) {
    /*
            t    f(t)
            0    0
            1    1
            2    1
            3    0
    */

    if (t < 1.0) {
        return t;
    }
    if (t < 2.0) {
        return 1.0;
    }
    if (t < 3.0) {
        return 1.0 - (t - 2.0);
    }
    return 0.0;
}

void mainImage(out vec4 RGBA, in vec2 XY)
{
    RGBA.a   = 1.0;

    float rad = (sin(iTime * 0.1) * 0.5 + 0.5) * 200.0 + 100.0;

    rad = 60.0;

    float lw  = 5.0;

    XY -= iResolution.xy * 0.5;
    XY *= rot(-iTime * 0.02);

    vec3 cot = vec3(0.7);
    vec3 cin = vec3(0.8);

    vec2 xy = XY;
    int it = int(iTime);
    if (XY.x > -rad / 2.0 && XY.x < rad / 2.0) {
        cin = vec3(1.0);
        xy.y += rad * trapezoid(mod(iTime      , 4.0)) - 0.5;
    }
    if (XY.y > -rad / 2.0 && XY.y < rad / 2.0) {
        cin = vec3(1.0);
        xy.x += rad * trapezoid(mod(iTime + 1.0, 4.0)) - 0.5;
    }

    /*
    ivec2 ij = ivec2(xy / rad);
    if (ij.x == ij.y && ij.x == 0) {
        cin = vec3(1.0, 0.0, 0.0);
    }
    */


    // cin *= sin(length(xy) * 0.1) * 0.2 + 0.8;

    // xy.y += sin((XY.x / rad + 0.5) * 3.1415 * 5.0 + iTime) * 2.0;
    // xy.x += sin((XY.y / rad + 0.5) * 3.1415 * 5.0 + iTime) * 2.0;

    vec2 uv = (mod(xy - rad/2.0, rad) - rad/2.0) * 2.0;


    float c = smoothstep(0.0, lw, abs(rad - length(uv) - 2.0 * lw / 2.0));
    vec3 rgb = vec3(c);

    if (length(uv) > rad - lw) {
        rgb *= cot;
    }
    else if (length(uv) < rad - lw) {
        rgb *= cin;
    }

    

    RGBA.rgb = rgb;
}

#ifdef GRIMOIRE
out vec4 fragColor; void main() { mainImage(fragColor, gl_FragCoord.xy); }
#endif
