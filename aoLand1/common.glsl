
// Fork of "boilerplate stuff" by elenzil. https://shadertoy.com/view/7dX3R2
// 2021-04-05 18:18:15

const float PI      = 3.14159265359;
const float TAO     = PI * 2.0;
const float DEG2RAD = TAO / 360.0;

// global time parameter
float gTime;

vec2  gCanvasRes;
float gCanvasSmallRes;
float gZoom;
float gScreenFromWorldFac;
float gWorldFromScreenFac;

const int DEVEL = 0;
const int DEBUG = 1;
const int DRAFT = 2;
const int GOOD1 = 3;
const int GOOD2 = 4;

// to prevent loop-unrolling
#define ZERO (min(0, int(iFrame)))


// set up world coordinates where a unit circle fits
// in the smallest dimension of the canvas, plus a zoom factor.
void setupCoords(in vec2 canvasResolution, in float zoom) {

    gCanvasRes = canvasResolution;

    // the smallest dimension of the canvas
    gCanvasSmallRes = min(canvasResolution.x, canvasResolution.y);
    
    // small = shrink
    gZoom = zoom;
    
    // factor to get from world scale to screen scale
    gScreenFromWorldFac = gZoom * gCanvasSmallRes / 2.0;
    
    // factor to get from screen scale to world scale
    gWorldFromScreenFac = 1.0 / gScreenFromWorldFac;
}

vec2 worldFromScreen(in vec2 screenPt) {
    return (screenPt - gCanvasRes / 2.0) * gWorldFromScreenFac;;
    
}

// in case we want to speed or slow down things from iTime.
// this needs to be called in each pass.
void setupTime(in float time) {
    gTime = time;
}

mat2 rot2(float theta) {
    float c = cos(theta);
    float s = sin(theta);
    return mat2(c, s, -s, c);
}

float maxComponent(vec3 v) {
    return max(max(v.x, v.y), v.z);
}

float minComponent(vec3 v) {
    return min(min(v.x, v.y), v.z);
}
