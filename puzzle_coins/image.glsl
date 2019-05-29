// orion elenzil 2019028
//
// puzzle from mike plotz.
//
// you have a bunch of uniform coins
// and a long skinny box.
// the interior of the box is 2 coins wide,
// 1000 coins long, and 1 coin-thickness tall.
// how many whole coins can you fit in the box ?

// comment this line out to see the solution
// #define HIDE_SOLUTION

const float PI         =  3.14159265359;
const float TAU        =  PI * 2.0;
const float gViewPort  =  2.25;
const float DEG_TO_RAD =  TAU / 360.0;

float sf = 1.0;

const float coinBorderPx = 4.0;

const vec3  bg           = vec3(0.5, 0.55, 0.4) * 0.6;
const vec3  colCoinBody1 = vec3(0.8, 0.8, 0.7);
const vec3  colCoinBody2 = vec3(0.8, 0.7, 0.8);
const vec3  colCoinBody3 = vec3(0.7, 0.8, 0.8);
const vec3  colCoinBody4 = vec3(0.7, 0.7, 0.7);
const vec3  colCoinEdge  = vec3(0.2, 0.1, 0.0);
const vec3  colBoxBody   = vec3(0.5, 0.6, 0.8);
const vec3  colBoxEdge   = vec3(0.0, 0.1, 0.3);

// empirically determined:
const float thetaMax = DEG_TO_RAD * 5.3;

float t    = 0.0;
float tMax = 7.0;

// 0     to 1   : intro
// 1     to 2   : move row 2 right 0.5, shifting down.
// 2     to 3   : pause
// 3     to 4   : rotate
// 4     to 4.5 : pause
// 4.5   to 5   : zoom
// 5     to 5.5 : pause
// 5.5   to 6.5 : compact
// 6.5   to 7

// adapted from iq's exact sdfBox()
// https://www.iquilezles.org/www/articles/distfunctions/distfunctions.htm
float sdfRect(in vec2 p, in vec2 r) {
    vec2 d = abs(p) - r;
    return length(max(d, 0.0))
        + min(max(d.x, d.y), 0.0);
}

float theta(float time) {
    return clamp(time - 3.0, 0.0, 1.0) * thetaMax;
}

void drawBox(inout vec3 rgb, in vec2 p) {
    vec2 dim = vec2(500.0, 1.0);
    vec2 cen = vec2(dim.x, 0.0);
    float rd = sdfRect(p - cen, dim);
    rgb = mix(rgb, colBoxEdge, smoothstep(0.0, -1.0, rd / sf - coinBorderPx));
    rgb = mix(rgb, colBoxBody, smoothstep(0.0, -1.0, rd / sf));
    float grid = 0.0;
    grid = max(grid, smoothstep(coinBorderPx, coinBorderPx - 1.0, abs((fract(p.x + coinBorderPx * 0.5 * sf))/ sf)));
    grid = max(grid, smoothstep(coinBorderPx, coinBorderPx - 1.0, abs((fract(p.y + coinBorderPx * 0.5 * sf))/ sf)));
    grid = max(grid, smoothstep(coinBorderPx, coinBorderPx - 1.0, abs((fract(p.x + 0.5 + coinBorderPx * 0.5 * sf))/ sf)));
    grid = max(grid, smoothstep(coinBorderPx, coinBorderPx - 1.0, abs((fract(p.y + 0.5 + coinBorderPx * 0.5 * sf))/ sf)));
    rgb = mix(rgb, vec3(0.0), 0.5 * smoothstep(0.1, -0.1, rd / sf) * grid);
}

void drawC(inout vec3 rgb, in vec2 p, in vec2 c, in vec3 col) {
    float d  = length(p - c);
    float ce = smoothstep( 1.0, -1.0,     (d - 0.5)  / sf);
    float cb = smoothstep( 1.0, -1.0,     (d - 0.5)  / sf + coinBorderPx);
    vec3 tmp = mix(colCoinEdge, col * (d * 0.3 + 0.7), cb);
    rgb      = mix(rgb, tmp, ce * 0.7);
}

void drawC1(inout vec3 rgb, in vec2 p, in mat2 rot, in float dxMod) {
    if (p.x < 0.0 || p.x > 1000.0) {
        return;
    }
    p.x = mod(p.x, 2.0 + dxMod);
    vec2 c = vec2(0.5, -0.5);
    c -= vec2(0.5, -0.5);
    c *= rot;
    c += vec2(0.5, -0.5);
    drawC(rgb, p, c, colCoinBody1);
}
void drawC2(inout vec3 rgb, in vec2 p, in mat2 rot, in float dxMod) {
    float dx = clamp(t - 1.0, 0.0, 1.0) * 0.5;
    if (p.x < 0.0 || p.x > 1000.0) {
        return;
    }
    p.x = mod(p.x, 2.0 + dxMod);
    vec2 c = vec2(0.5, 0.5);
    c.x += dx;
    float dy = 1.0 - sqrt(1.0 - dx * dx);
    c.y -= dy;
    c -= vec2(0.5, -0.5);
    c *= rot;
    c += vec2(0.5, -0.5);

    drawC(rgb, p, c, colCoinBody2);
}
void drawC3(inout vec3 rgb, in vec2 p, in mat2 rot, in float dxMod) {
    if (p.x < 0.0 || p.x > 1000.0) {
        return;
    }
    p.x = mod(p.x + dxMod, 2.0 + dxMod) - dxMod;
    vec2 c = vec2(1.5, -0.5);
    c -= vec2(0.5, -0.5);
    c *= rot;
    c += vec2(0.5, -0.5);

    drawC(rgb, p, c, colCoinBody3);
}
void drawC4(inout vec3 rgb, in vec2 p, in mat2 rot, in float dxMod) {
    float dx = clamp(t - 1.0, 0.0, 1.0) * 0.5;
    if (p.x < 0.5 || p.x > 1000.0) {
        return;
    }
    p.x = mod(p.x - dx, 2.0 + dxMod) + dx;
    vec2 c = vec2(1.5, 0.5);
    c.x += dx;
    float dy = 1.0 - sqrt(1.0 - dx * dx);
    c.y -= dy;
    c -= vec2(0.5, -0.5);
    c *= rot;
    c += vec2(0.5, -0.5);

    drawC(rgb, p, c, colCoinBody4);
}

void render(out vec4 RGBA, in vec2 XY, bool showLeft) {
    RGBA.a   = 1.0;
    t = abs(mod(iTime * 0.5 - tMax, tMax * 2.0) - tMax);
    #ifdef HIDE_SOLUTION
    t = 0.0;
    #endif

    vec2 uv;
    /**/  sf = gViewPort / (iResolution.y * 0.5);
    if (showLeft) {
        sf    = mix (sf, sf * 0.1, 2.0 * clamp(t - 4.5, 0.0, 0.5));
        uv    = (XY - iResolution.xy * vec2(0.0, 0.25)) * sf;
        uv.x -= mix(0.25, iResolution.x * sf * 0.5 - 2.0, 2.0 * clamp(t - 4.5, 0.0, 0.5));
        uv.y -= mix(0.0 , 0.5, 2.0 * clamp(t - 4.5, 0.0, 0.5));
    }
    else {
        uv    = (XY - iResolution.xy * vec2(0.0, 0.25)) * sf;
        uv.x += 1000.5 - iResolution.x * sf;
    }

    vec3 rgb = bg;

    float theta = -theta(t);
    mat2 rot = mat2(cos(theta), sin(theta), -sin(theta), cos(theta));

    vec2 c3 = vec2(1.0, 0.0);
    c3 *= rot;
    const float empiricalFudge = 2.0;    // take into account circularity.
    float dxMod = (c3.x - 1.0) * empiricalFudge * clamp(t - 5.5, 0.0, 1.0);

    drawBox(rgb, uv);
    drawC1 (rgb, uv, rot, dxMod);
    drawC2 (rgb, uv, rot, dxMod);
    drawC3 (rgb, uv, rot, dxMod);
    drawC4 (rgb, uv, rot, dxMod);

    // fade out
    if (showLeft) {
        rgb = mix(rgb, bg, smoothstep(-3.0, 3.0, XY.x - iResolution.x + 50.0 - sin(XY.y * 0.03) * 20.0));
    }
    else {
        rgb = mix(rgb, bg, smoothstep(-3.0, 3.0, -XY.x + 50.0 + sin(XY.y * 0.03) * 20.0));
    }

    RGBA.rgb = pow(rgb, vec3(0.4545));
}

void mainImage(out vec4 RGBA, in vec2 XY) {
    if (XY.y > iResolution.y / 2.0) {
        render(RGBA, XY + vec2(0.0, -iResolution.y / 2.0), true);
    }
    else {
        render(RGBA, XY, false);
    }
}


#ifdef GRIMOIRE
out vec4 fragColor; void main() { mainImage(fragColor, gl_FragCoord.xy); }
#endif
