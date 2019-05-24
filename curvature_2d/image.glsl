// orion elenzil 20190522

const float PI        = 3.14159265359;
const float TAU       = PI * 2.0;
const float Scale     = 10.0;
const float LineWidth = 5.0;

// #define AA 2.0

// adapted from iq's exact sdfBox()
// https://www.iquilezles.org/www/articles/distfunctions/distfunctions.htm
float sdfRect(in vec2 p, in vec2 r) {
    vec2 d = abs(p) - r;
    return length(max(d, 0.0))
        + min(max(d.x, d.y), 0.0);
}

float sdfScene(in vec2 p) {
    float ret = 1e20;

    ret = min(ret, sdfRect(p, vec2(2.0, 3.0)));

    return ret;
}

vec2 sdfGradient(in vec2 p, in float eps) {
    return vec2(
        sdfScene(vec2(p.x - eps, p.y)) - sdfScene(vec2(p.x + eps, p.y)),
        sdfScene(vec2(p.x, p.y - eps)) - sdfScene(vec2(p.x, p.y + eps))
    );
}

float sdfSceneBeveled(in vec2 p, in float r) {
    vec2  g1 = sdfGradient(p, 0.001);
    vec2  g2 = sdfGradient(p, 0.010);
    float dg = length(g1 - g2);

    return sdfScene(p) + dg * r * 100.0;
}

void mainImage(out vec4 RGBA, in vec2 XY) {
    RGBA.a   = 1.0;
    float sf = min(iResolution.x, iResolution.y) / Scale;
    vec2  uv = (XY * 2.0 - iResolution.xy)/sf;
    float t  = iTime * TAU / 5.0;

    float dist = sdfSceneBeveled(uv, 0.5);
    float f = sin(dist * 3.0 - t) * 0.2 + 0.7;

    vec3 rgb = vec3(f);

    rgb = mix(rgb, vec3(0.3, 0.2, 0.0), smoothstep(LineWidth, 0.0, abs(dist) * sf));

    RGBA.rgb = rgb;
}

// grimoire bindings
out vec4 fragColor; void main() { mainImage(fragColor, gl_FragCoord.xy); }
