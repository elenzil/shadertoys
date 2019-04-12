// common stuff
const vec3 fv3_1  = vec3(1.0, 1.0, 1.0);
const vec3 fv3_0  = vec3(0.0, 0.0, 0.0);
const vec3 fv3_x  = vec3(1.0, 0.0, 0.0);
const vec3 fv3_y  = vec3(0.0, 1.0, 0.0);
const vec3 fv3_z  = vec3(0.0, 0.0, 1.0);
const vec2 fv2_1  = vec2(1.0, 1.0);
const vec2 fv2_0  = vec2(0.0, 0.0);
const vec2 fv2_x  = vec2(1.0, 0.0);
const vec2 fv2_y  = vec2(0.0, 1.0);
const float PI    = 3.14159265359;
const float TWOPI = PI * 2.0;

vec2 complexMul(in vec2 A, in vec2 B) {
  return vec2((A.x * B.x) - (A.y * B.y), (A.x * B.y) + (A.y * B.x));
}

struct POI {
  vec2  center;
  float range;
  float maxIter;
};

float mandelEscapeIters(in vec2 C, in float maxIters) {
  vec2 Z = C;
  for (float n = 0; n < maxIters; n += 1.0) {
    Z  = complexMul(Z, Z) + C;
    if (dot(Z, Z) > 4.0) {
      return n;
    }
  }
  return maxIters;
}

const POI[] pointsOfInterest = POI[] (
    // the main image
    POI(vec2(-0.75    ,  0.0      ), 1.4     ,  200.0),

    // Spirals from Paul Bourke http://paulbourke.net/fractals/mandelbrot
    POI(vec2(-0.761571, -0.084756),  0.000012, 2000.0),

    // nowhere special
    POI(vec2(-1.4076  , -0.1277   ), 0.00014 , 3000.0)
  );

void mainImage(out vec4 outRGBA, in vec2 XY)
{
  float smallWay = min(iResolution.x, iResolution.y);
  vec2 uv = (XY * 2.0 - fv2_1 * iResolution.xy)/smallWay;

  float t = iTime * 0.1;

  POI poi1 = pointsOfInterest[0];
  POI poi2 = pointsOfInterest[int(t) % (3 - 1) + 1];

  float mixAmt = sin(t * TWOPI - PI/2.0) * 0.5 + 0.5;
  mixAmt = pow(mixAmt, 0.3);
  POI poi = POI(
    mix(poi1.center , poi2.center , mixAmt),
    mix(poi1.range  , poi2.range  , mixAmt),
    mix(poi1.maxIter, poi2.maxIter, mixAmt));

  vec2 C = uv * poi.range + poi.center;
  float f = mandelEscapeIters(C, poi.maxIter) / poi.maxIter;
  f = pow(f, 1.0/3.0);
  vec3 rgb = vec3(f);


  rgb *= 1.0 - 0.1 * smoothstep(3.0/smallWay, 0.0, abs(f - 1.0));

  rgb += texture(iChannel0, XY/iResolution.xy).rgb * 0.91;
  rgb /= 1.1;

  outRGBA = vec4(rgb, f);
}


// grimoire bindings
out vec4 fragColor; void main() { mainImage(fragColor, gl_FragCoord.xy); }
