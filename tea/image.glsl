/*
    orion elenzil 2019
    first marcher with shadows.

    click on the far right to show the marching steps.
*/

// boiler-plate
const vec3 fv3_1    = vec3(1.0, 1.0, 1.0);
const vec3 fv3_0    = vec3(0.0, 0.0, 0.0);
const vec3 fv3_x    = vec3(1.0, 0.0, 0.0);
const vec3 fv3_y    = vec3(0.0, 1.0, 0.0);
const vec3 fv3_z    = vec3(0.0, 0.0, 1.0);
const vec2 fv2_1    = vec2(1.0, 1.0);
const vec2 fv2_0    = vec2(0.0, 0.0);
const vec2 fv2_x    = vec2(1.0, 0.0);
const vec2 fv2_y    = vec2(0.0, 1.0);
const float PI      = 3.14159265359;
const float TAU     = PI * 2.0;

const float rmMaxSteps  = 180.0;
const float rmMaxDist   =  52.0;
const float rmEpsilon   =   0.002;
const float rmWhoaThere =   1.0;
const float grEpsilon   =   0.01;

vec3 rayDir(in vec2 uv, in vec3 ro, in vec3 lookTo, in vec3 worldUp, float zoom) {
    vec3 vOL = normalize(lookTo - ro);
    vec3 vRt = cross(vOL, worldUp);
    vec3 vUp = cross(vRt, vOL);
    vec3 vRy = normalize(vRt * uv.x + vUp * uv.y + vOL * zoom);
    return vRy;
}

float sdfGround(in vec3 p, float altitude) {
    return p.y - altitude;
}

float sdfSphere(in vec3 p, in vec3 c, float r) {
    return length(p - c) - r;
}

float sdfScene(in vec3 p) {
    float dist = 1e20;
    float t    = iTime * TAU / 30.0;
    float rad  = 1.2;
    float sep  = (sin(t) * 0.5 + 0.5) + rad;

    // four spheres
    dist = min(dist, sdfSphere(vec3(abs(p.x), p.y, abs(p.z)), vec3(sep, rad, sep), rad));
    
    // minus a wavy plane
    float cutPlaneSize = (sin(t * 0.72) * 0.51 + 0.5) * rad * 2.4;
    float cutPlaneDisp = (sin(p.x * 4.0) + sin(p.z * 4.0)) * 0.1;
    cutPlaneDisp += sin(length(p.xz) * 20.0 - t * 20.0) * 0.015;
    float cutPlane = max((p.y + cutPlaneDisp) - rad - cutPlaneSize * 0.5, -(p.y + cutPlaneDisp) + rad - cutPlaneSize * 0.5);

    dist = max(-cutPlane, dist);

    // ground
    dist = min(dist, sdfGround(p, 0.0));

    return dist;
}

vec3 sdfGradient(in vec3 p) {
    return vec3(sdfScene(p + fv3_x * grEpsilon) - sdfScene(p - fv3_x * grEpsilon),
                sdfScene(p + fv3_y * grEpsilon) - sdfScene(p - fv3_y * grEpsilon),
                sdfScene(p + fv3_z * grEpsilon) - sdfScene(p - fv3_z * grEpsilon));
}

void march(in vec3 ro, in vec3 rd, out float hitDist, out float steps, out float minDist) {
    
    minDist = 1e20;
    hitDist = 0.0;

    for (steps = 0.0; (steps < rmMaxSteps) && (hitDist < rmMaxDist); ++steps) {
        float dist = sdfScene(ro + rd * hitDist);
        minDist = min(minDist, dist);
        if (dist < rmEpsilon) {
            return;
        }
        hitDist += dist * rmWhoaThere;
    }

    hitDist = rmMaxDist;
}

void mainImage(out vec4 RGBA, in vec2 XY)
{
    RGBA.a   = 1.0;
    vec2  uv = (XY * 2.0 - iResolution.xy)/min(iResolution.x, iResolution.y);
    float t  = iTime * TAU / 100.0;

    float mouseAlt = iMouse.y < 1.0 ? 0.0 : iMouse.y / iResolution.y * 2.0 - 1.0;

    vec3  ro = vec3(vec2(cos(t), sin(t)) * 30.0, 7.0 + mouseAlt * 6.0).xzy;
    vec3  lt = vec3(0.0, 2.0, 0.0);
    float zm = 10.0;
    vec3  rd = rayDir(uv, ro, lt, fv3_y, zm);

    float hitDist, steps, minDist;
    march(ro, rd, hitDist, steps, minDist);
    vec3  hitPoint = ro + rd * hitDist;
    vec3  gradient = sdfGradient(hitPoint);
    vec3  normal   = normalize(gradient);

    vec3  lgtDir = normalize(vec3(cos(t * 2.0), -(sin(t * 0.2) * 0.5 + 0.6), sin(t * 2.0)));
    float lgtDot = dot(normal, -lgtDir);

    float b = max(0.0, lgtDot);

    if (lgtDot > 0.0) {
        // check for shadows
        float hitDist2, steps2, minDist2;
        // back away from the surface by a little more than epsilon.
        float softShadowSize = 0.1;
        float backAway = max(rmEpsilon * 1.1, 0.2);
        march(hitPoint + normal * backAway, -lgtDir, hitDist2, steps2, minDist2);
        float shadowAmt = float(hitDist2 > rmMaxDist * 0.9);
        shadowAmt *= smoothstep(rmEpsilon, softShadowSize, minDist2);
        shadowAmt = shadowAmt * 0.6 + 0.4;
        b *= shadowAmt;
        steps += steps2;
    }

    vec3  rgb    = vec3(b);

    float fogStart = 25.0;
    float fogAmt = clamp((hitDist - fogStart) / (rmMaxDist - fogStart), 0.0, 1.0);
    fogAmt = sqrt(fogAmt);
    vec3  fogClr = vec3(0.0, 0.07, 0.2);

    rgb = mix(rgb, fogClr, fogAmt);

    rgb = pow(rgb, vec3(0.4545));


    if (iMouse.z > iResolution.x * 0.9) {
        rgb.r = (steps)/2.0/rmMaxSteps;
    }

    RGBA.rgb = rgb;
}

// grimoire bindings
out vec4 fragColor; void main() { mainImage(fragColor, gl_FragCoord.xy); }
