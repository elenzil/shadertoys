// orion elenzil 20190528
//
// coin-packing puzzle!
//
// you have a bunch of uniform coins
// and a long skinny box.
// the interior of the box is 2 coins wide,
// 1000 coins long, and 1 coin-thickness tall.
// how many whole coins can you fit in the box ?
//
// hold down the mouse button to see one solution.
// i hear there's a better one, tho !
//
// puzzle from mike plotz: https://hyponymo.us


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

// this analytic solution from Gabe Chang.
// it comes out to 5.264 degrees, which is very close to my empirical 5.3 degrees.
const float thetaMax = asin(1.0/sqrt(3.0)) - 30.0 * DEG_TO_RAD;

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

//-----------------------------------------------------------------
// Digit drawing function by P_Malin (https://www.shadertoy.com/view/4sf3RN)

float SampleDigit(const in float n, const in vec2 vUV)
{       
    if(vUV.x  < 0.0) return 0.0;
    if(vUV.y  < 0.0) return 0.0;
    if(vUV.x >= 1.0) return 0.0;
    if(vUV.y >= 1.0) return 0.0;
    
    float data = 0.0;
    
         if(n < 0.5) data = 7.0 + 5.0*16.0 + 5.0*256.0 + 5.0*4096.0 + 7.0*65536.0;
    else if(n < 1.5) data = 2.0 + 2.0*16.0 + 2.0*256.0 + 2.0*4096.0 + 2.0*65536.0;
    else if(n < 2.5) data = 7.0 + 1.0*16.0 + 7.0*256.0 + 4.0*4096.0 + 7.0*65536.0;
    else if(n < 3.5) data = 7.0 + 4.0*16.0 + 7.0*256.0 + 4.0*4096.0 + 7.0*65536.0;
    else if(n < 4.5) data = 4.0 + 7.0*16.0 + 5.0*256.0 + 1.0*4096.0 + 1.0*65536.0;
    else if(n < 5.5) data = 7.0 + 4.0*16.0 + 7.0*256.0 + 1.0*4096.0 + 7.0*65536.0;
    else if(n < 6.5) data = 7.0 + 5.0*16.0 + 7.0*256.0 + 1.0*4096.0 + 7.0*65536.0;
    else if(n < 7.5) data = 4.0 + 4.0*16.0 + 4.0*256.0 + 4.0*4096.0 + 7.0*65536.0;
    else if(n < 8.5) data = 7.0 + 5.0*16.0 + 7.0*256.0 + 5.0*4096.0 + 7.0*65536.0;
    else if(n < 9.5) data = 7.0 + 4.0*16.0 + 7.0*256.0 + 5.0*4096.0 + 7.0*65536.0;
    
    vec2 vPixel = floor(vUV * vec2(4.0, 5.0));
    float fIndex = vPixel.x + (vPixel.y * 4.0);
    
    return mod(floor(data / pow(2.0, fIndex)), 2.0);
}

float PrintInt(const in vec2 uv, const in float value )
{
    float res = 0.0;
    float maxDigits = 1.0+ceil(log2(value + 0.00001)/log2(10.0));
    float digitID = floor(uv.x);
    if( digitID>0.0 && digitID<maxDigits )
    {
        float digitVa = mod( floor( value/pow(10.0,maxDigits-1.0-digitID) ), 10.0 );
        res = SampleDigit( digitVa, vec2(fract(uv.x), uv.y) );
    }

    return res; 
}
// end of number-printing
///////////////////////////////////////////////


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

void drawC(inout vec3 rgb, in vec2 p, in vec2 c, in vec3 col, in float num) {
    float d  = length(p - c);
    float ce = smoothstep( 1.0, -1.0,     (d - 0.5)  / sf);
    float cb = smoothstep( 1.0, -1.0,     (d - 0.5)  / sf + coinBorderPx);
    vec3 tmp = mix(colCoinEdge, col * (d * 0.3 + 0.7), cb);
    rgb      = mix(rgb, tmp, ce * 0.7);
    rgb *= 1.0 - 0.5 * PrintInt((p - c + vec2(0.47, 0.1)) * 6.0, num);
}

void drawC1(inout vec3 rgb, in vec2 p, in mat2 rot, in float dxMod) {
    if (p.x < 0.0 || p.x > 1000.0) {
        return;
    }

    float step = 2.0 + dxMod;
    float num = 1.0 + 4.0 * floor(p.x / step);

    p.x = mod(p.x, step);
    vec2 c = vec2(0.5, -0.5);
    c -= vec2(0.5, -0.5);
    c *= rot;
    c += vec2(0.5, -0.5);
    drawC(rgb, p, c, colCoinBody1, num);
}
void drawC2(inout vec3 rgb, in vec2 p, in mat2 rot, in float dxMod) {
    float dx = clamp(t - 1.0, 0.0, 1.0) * 0.5;
    if (p.x < 0.0 || p.x > 1000.0) {
        return;
    }

    float step = 2.0 + dxMod;
    float num = 2.0 + 4.0 * floor((p.x - dx) / step);

    p.x = mod(p.x, step);
    vec2 c = vec2(0.5, 0.5);
    c.x += dx;
    float dy = 1.0 - sqrt(1.0 - dx * dx);
    c.y -= dy;
    c -= vec2(0.5, -0.5);
    c *= rot;
    c += vec2(0.5, -0.5);

    drawC(rgb, p, c, colCoinBody2, num);
}
void drawC3(inout vec3 rgb, in vec2 p, in mat2 rot, in float dxMod) {
    if (p.x < 0.0 || p.x > 1000.0) {
        return;
    }

    float step = 2.0 + dxMod;
    float num = 3.0 + 4.0 * floor(p.x / step);

    p.x = mod(p.x + dxMod, step) - dxMod;
    vec2 c = vec2(1.5, -0.5);
    c -= vec2(0.5, -0.5);
    c *= rot;
    c += vec2(0.5, -0.5);

    drawC(rgb, p, c, colCoinBody3, num);
}
void drawC4(inout vec3 rgb, in vec2 p, in mat2 rot, in float dxMod) {
    float dx = clamp(t - 1.0, 0.0, 1.0) * 0.5;
    if (p.x < 0.5 || p.x > 1000.0) {
        return;
    }

    float step = 2.0 + dxMod;
    float num = 4.0 + 4.0 * floor((p.x - dx) / step);

    p.x = mod(p.x - dx, step) + dx;
    vec2 c = vec2(1.5, 0.5);
    c.x += dx;
    float dy = 1.0 - sqrt(1.0 - dx * dx);
    c.y -= dy;
    c -= vec2(0.5, -0.5);
    c *= rot;
    c += vec2(0.5, -0.5);

    drawC(rgb, p, c, colCoinBody4, num);
}

void render(out vec4 RGBA, in vec2 XY, bool showLeft) {
    RGBA.a   = 1.0;

    t = 0.0;
    float mouseDownTime = texelFetch(iChannel0, ivec2(0, 0), 0).r;
    if (mouseDownTime > 0.0) {
        t = (iTime - mouseDownTime) / 2.0 + 1.0;
    }

    t = abs(mod(t - tMax, tMax * 2.0) - tMax);

    float vign = 1.0;

    vec2 uv;
    /**/  sf = gViewPort / (iResolution.y * 0.5);
    if (showLeft) {
        float tMe = clamp(t - 4.5, 0.0, 0.5);
     //   tMe=0.5;
        sf    = mix (sf, sf * 0.1, 2.0 * tMe);
        uv    = (XY - iResolution.xy * vec2(0.0, 0.25)) * sf;
        uv.x -= mix(0.25, iResolution.x * sf * 0.5 - 2.0, 2.0 * tMe);
        uv.y -= mix(0.0 , 0.5, 2.0 * tMe);

        vign  = 1.0 - tMe * 2.0 * (0.8 * smoothstep(0.0, 1.0, 4.0 * length(uv - vec2(2.0, -0.5))));
    }
    else {
        uv    = (XY - iResolution.xy * vec2(0.0, 0.25)) * sf;
        uv.x += 1000.5 - iResolution.x * sf;
        vign  = 1.0;
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

    rgb *= vign;

    // fade out
    if (showLeft) {
        rgb = mix(rgb, bg, smoothstep(-3.0, 3.0, XY.x - iResolution.x + 30.0 - sin(XY.y * 50.0 / iResolution.y) * 3.0 * iResolution.x / iResolution.y));
    }
    else {
        rgb = mix(rgb, bg, smoothstep(-3.0, 3.0, -XY.x + 20.0 + sin(XY.y * 50.0 / iResolution.y) * 3.0 * iResolution.x / iResolution.y));
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
