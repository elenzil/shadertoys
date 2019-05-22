const float PI        = 3.14159265359;
const float TAU     = PI * 2.0;

vec2 complexMul(in vec2 A, in vec2 B) {
    return vec2((A.x * B.x) - (A.y * B.y), (A.x * B.y) + (A.y * B.x));
}

// https://github.com/hughsk/glsl-hsv2rgb/blob/master/index.glsl
vec3 hsv2rgb(in vec3 c) {
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}


struct POI {
    vec2    center;
    float range;
    float maxIter;
};


float mandelEscapeIters(in vec2 C, in float maxIter, in float homeRadius, out float cycleLength1, out float cycleLength2) {
    vec2 Z = C;
    vec2 orbitCenter1 = 0.3 * vec2(cos(iTime * 1.00), sin(iTime * 1.00));
    vec2 orbitCenter2 = orbitCenter1 / 0.3 * 0.2;
    cycleLength1 = 0.0;
    cycleLength2 = 0.0;
    for (float n = 0; n < maxIter; n += 1.0) {
        Z    = complexMul(Z, Z) + C;
        if (cycleLength1 == 0.0 && abs(1.0 - length(Z - orbitCenter1)) < 0.015) {
            cycleLength1 = n;
        }
        if (cycleLength2 == 0.0 && abs(0.2 - length(Z - orbitCenter2)) < 0.01) {
            cycleLength2 = n;
        }
        if (dot(Z, Z) > 4.0) {
            return n;
        }
    }
    return maxIter;
}

void mainImage(out vec4 RGBA, in vec2 XY)
{
    RGBA.a  = 1.0;
    float smallWay = min(iResolution.x, iResolution.y);
    vec2 uv = (XY * 2.0 - iResolution.xy)/smallWay;
    float t = iTime * TAU / 5.0;

    const POI poi1 = POI(vec2(-.7105, 0.2466), 0.04, 200.0);
    const POI poi2 = POI(vec2(-.600, 0.0000), 0.900, 50.0);
    const POI poi  = poi2;

    float rng = poi.range;// * (1.0 + sin(t) * 0.1);
    
    vec2  C   = uv * rng + poi.center;
    float cycleLength1;
    float cycleLength2;
    float escapeIters = mandelEscapeIters(C, poi.maxIter, poi.range * 0.2, cycleLength1, cycleLength2);
    float f   =  escapeIters / poi.maxIter;
    if (escapeIters == poi.maxIter) {
        f = 0.0;
    }
    f = pow(f, 0.6);
    f *= 0.82;

    vec3 rgb  = vec3(f);

    if (cycleLength1 > 0.0) {
        const float spectrumSamples = 20.0;
        rgb += vec3(sin(cycleLength1 / spectrumSamples * TAU) * 0.2 + 0.4);
    }
    if (cycleLength2 > 0.0) {
        const float spectrumSamples = 30.0;
        rgb += hsv2rgb(vec3(mod(cycleLength2,  spectrumSamples) / spectrumSamples, 0.9, 0.8));
    }

    RGBA.rgb = rgb;
}

// grimoire bindings
out vec4 fragColor; void main() { mainImage(fragColor, gl_FragCoord.xy); }
