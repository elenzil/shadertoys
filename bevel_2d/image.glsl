// orion elenzil 20190522

const float PI        =  3.14159265359;
const float TAU       = PI * 2.0;
// const float gViewPrt  =  2.0;
// const vec2  gViewPrtC =  vec2(-2.0, -3.5);
const float gViewPrt  =  6.0;
const vec2  gViewPrtC =  vec2(0.0);
const float gLineW    =  6.0;
const float gEpsGrad  =  0.001;
/***/ float gEpsCurv  =  0.5;

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

    ret = min( sdfRect(p, vec2(2.00, 5.00)), ret);
    ret = min( sdfRect(p, vec2(5.00, 2.00)), ret);
    ret = max(-sdfRect(p, vec2(1.55, 1.55)), ret);

    return ret;
}

vec2 sdfGradient(in vec2 p) {
    vec2 ret = vec2(
        sdfScene(vec2(p.x - gEpsGrad, p.y)) - sdfScene(vec2(p.x + gEpsGrad, p.y)),
        sdfScene(vec2(p.x, p.y - gEpsGrad)) - sdfScene(vec2(p.x, p.y + gEpsGrad))
    );

    ret /= gEpsGrad;

    return ret;
}

void sdfInfo(in vec2 p, out float sdfDist, out vec2 sdfGrad, out float sdfCurv) {
    /**/  sdfDist  = sdfScene   (p);
    /**/  sdfGrad  = sdfGradient(p);
    vec2  sdfNorm  = normalize  (sdfGrad);
    vec2  sdfTngt  = vec2(-sdfNorm.y, sdfNorm.x);

    // for smooth sdfs i think we could just use a single sample point,
    // but for merely continuous we should probably use two.
    float tanDistA = sdfScene(p + sdfTngt * gEpsCurv);
    float tanDistB = sdfScene(p - sdfTngt * gEpsCurv);
    float tanDist  = (tanDistA + tanDistB) / 2.0;

    // to normalize curvature w/r/t gEpsCurv,
    // divide by gEpsCurv ^ 2 here.
    // however, for the purposes of beveling we don't want that.
    // it also makes the math more stable.
    // this was arrived at empirically, not mathematically.
    //    sdfCurv  = (tanDist - sdfDist) / max(0.00001, (gEpsCurv * gEpsCurv));
    /**/  sdfCurv  = (tanDist - sdfDist);
}

void mainImage(out vec4 RGBA, in vec2 XY) {
    RGBA.a   = 1.0;
    float sf = min(iResolution.x, iResolution.y) / gViewPrt;
    vec2  uv = (XY * 2.0 - iResolution.xy)/sf;
    uv += gViewPrtC;
    float t  = iTime * TAU / 5.0;

    gEpsCurv = mix(0.00, 1.5, cos(t + PI) * 0.5 + 0.5);

    float dist;
    vec2  grad;
    float curv;
    sdfInfo(uv, dist, grad, curv);

    float distOrig = dist;

    // bevel is done by backing the surface off
    // by the length of the gradient times the curvature.
    // i'm not sure where the factor of 1/2 belongs:
    // here, curvature, gradient ?
    dist += curv * length(grad) / 2.0;

    float fCrvN  = max(0.0, -curv);
    float fCrvP  = max(0.0,  curv);
    float fSdf   = sin(dist * 10.0) * 0.2 + 0.2;

    vec3 rgb = vec3(fCrvN, fCrvP, fSdf);

    rgb += vec3(1.0) * smoothstep(gLineW, gLineW - 1.5, abs(dist) * sf);

    RGBA.rgb = rgb;
}

// grimoire bindings
out vec4 fragColor; void main() { mainImage(fragColor, gl_FragCoord.xy); }
