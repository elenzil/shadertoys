/*
    orion elenzil 2019
    first marcher with shadows.
    https://www.shadertoy.com/view/WtB3RR

    click on the far right to show the marching steps.

    todo:
    * materials!
    * reflections
    * improved shadows
    * worry about efficiency of gradient()
    * fisheye camera
    * AA
    * AO
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

const float rmMaxSteps   = 180.0;
const float rmMaxDistReg =  32.0;       // max distance for marching for surfaces
const float rmMaxDistShd =  10.0;       // max distance for marching for shadows
const float rmEpsilon    =   0.002;
const float grEpsilon    =   0.0001;

const float gutterWidth  =   50.0;


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

float sdfColumn(in vec3 p, in vec3 c, float r) {
    return length(p.xz - c.xz) - r;
}

float sdfScene(in vec3 p) {
    float dist = 1e20;
    float t    = iTime * TAU / 30.0;
    float rad  = 1.2;
    float sep  = (sin(t) * 0.5 + 0.5) + rad;

    // four spheres
    dist = min(dist, sdfSphere(vec3(abs(p.x), p.y, abs(p.z)), vec3(sep, rad, sep), rad));
    
    // minus a wavy plane
    float cutPlaneSize = (sin(t * 0.72 - PI/2.0) * 0.51 + 0.5) * rad * 2.4;
    float cutPlaneDisp = (sin(p.x * 4.0) + sin(p.z * 4.0)) * 0.1;
    cutPlaneDisp += sin(length(p.xz) * 20.0 - t * 20.0) * 0.015;
    float cutPlane = max((p.y + cutPlaneDisp) - rad - cutPlaneSize * 0.5, -(p.y + cutPlaneDisp) + rad - cutPlaneSize * 0.5);    
//  cutPlane = max(-sdfColumn(vec3(abs(p.x), p.y, abs(p.z)), vec3(sep, rad, sep), rad * 0.03), cutPlane);
    dist = max(-cutPlane, dist);

    // ground
    float ground = sdfGround(p, 0.0);
    // dimples
    float dimples = sdfSphere(mod(p + vec3(0.0, 1.0, 0.0), vec3(10.0)), vec3(5.0, 5.0, 5.0), 4.5);
    ground = max(-dimples, ground);
    dist = min(dist, ground);

    return dist;
}

vec3 sdfGradient(in vec3 p) {
    return vec3(sdfScene(p + fv3_x * grEpsilon) - sdfScene(p - fv3_x * grEpsilon),
                sdfScene(p + fv3_y * grEpsilon) - sdfScene(p - fv3_y * grEpsilon),
                sdfScene(p + fv3_z * grEpsilon) - sdfScene(p - fv3_z * grEpsilon));
}

void march(in vec3 ro, in vec3 rd, float stepFactor, float maxDist, out float hitDist, out float steps, out float minDist) {
    
    minDist = 1e20;
    hitDist = 0.0;

    for (steps = 0.0; (steps < rmMaxSteps) && (hitDist < maxDist); ++steps) {
        float dist = sdfScene(ro + rd * hitDist);
        minDist = min(minDist, dist);
        if (dist < rmEpsilon) {
            return;
        }
        hitDist += dist * stepFactor;
    }

    hitDist = maxDist;
}

void mainImage(out vec4 RGBA, in vec2 XY)
{
    RGBA.a   = 1.0;
    vec2  uv = (XY * 2.0 - iResolution.xy)/min(iResolution.x, iResolution.y);
    float t  = iTime * TAU / 100.0;

    float mouseAlt = iMouse.y < 1.0 ? 0.0 : iMouse.y / iResolution.y * 2.0 - 1.0;
    float mouseAng = iMouse.x * TAU / iResolution.x;

    float softShadowWidth = (iMouse.z < 0.5 || iMouse.z > gutterWidth) ? 0.2 :
        max(0.0, iMouse.y / iResolution.y * 1.0);

    vec3  ro = vec3(vec2(cos(t + mouseAng), sin(t + mouseAng)) * 13.0, 7.0 + mouseAlt * -5.0).xzy;
    vec3  lt = vec3(0.0, 1.0, 0.0);
    float zm = 4.0;
    vec3  rd = rayDir(uv, ro, lt, fv3_y, zm);

    float hitDist, steps, minDist;
    march(ro, rd, 1.0, rmMaxDistReg, hitDist, steps, minDist);
    vec3  hitPoint = ro + rd * hitDist;
    vec3  gradient = sdfGradient(hitPoint);
    vec3  normal   = normalize(gradient);

    vec3  lgtDir = vec3(cos(t * 2.0), -(sin(t * 0.2) * 0.5 + 0.6), sin(t * 2.0));
//  lgtDir.y = -0.3;
    lgtDir = normalize(lgtDir);
    float lgtDot = dot(normal, -lgtDir);

    float b = max(0.0, lgtDot);

    if (hitPoint.y < rmEpsilon * 1.1) {
        // floor
        float check = float(fract(hitPoint.x / 5.0) > 0.5 ^^ fract(hitPoint.z / 5.0) > 0.5);
        b *= check * 0.1 + 0.9;
    }

    if (lgtDot > 0.0) {
        // check for shadows
        float hitDist2, steps2, minDist2;
        float backAway = softShadowWidth * 1.01;
        vec3  startPnt = hitPoint + normal * backAway;
        // use finer stepsize when marching for shadows,
        // also reduced horizon distance.
        march(startPnt, -lgtDir, 0.3, rmMaxDistShd, hitDist2, steps2, minDist2);
        float shadowAmt = float(hitDist2 > rmMaxDistShd * 0.9);
        if (true /*softShadows*/) {
            shadowAmt *= smoothstep(0.0, softShadowWidth, minDist2);
        }
        shadowAmt = shadowAmt * 0.9 + 0.1;
        b *= shadowAmt;
        steps += steps2;
    }

    vec3  rgb    = vec3(b);

    // fog
    float fogStart = 6.0;
    float fogAmt = clamp((hitDist - fogStart) / (rmMaxDistReg - fogStart), 0.0, 1.0);
    vec3  fogClr = vec3(0.0, 0.07, 0.2);
    rgb = mix(rgb, fogClr, fogAmt);

    // some UI

    // "heatmap" of number of marching steps
    if (iMouse.z > iResolution.x - gutterWidth) {
        rgb   *= 0.15;
        rgb.r += (steps)/2.0/rmMaxSteps * 0.85;
        if (abs((iResolution.x - gutterWidth) - XY.x) < 1.1) {
            rgb.r += 0.1;
        }
        if (XY.x > iResolution.x - gutterWidth) {
            rgb.rgb *= 0.8;
        }
    }

    // soft shadows.
    if (iMouse.z > 0.0 && iMouse.z < gutterWidth) {
        rgb   *= 0.9;
        if (abs(gutterWidth - XY.x) < 1.1) {
            rgb.gb += vec2(0.05);
        }
        if (XY.x < gutterWidth) {
            rgb.rgb *= 0.8;
        }
    }

    // gamma
    rgb = pow(rgb, vec3(0.4545));



    RGBA.rgb = rgb;
}

// grimoire bindings
out vec4 fragColor; void main() { mainImage(fragColor, gl_FragCoord.xy); }
