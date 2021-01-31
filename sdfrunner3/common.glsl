/*
 * The SDF is defined here in Common so that it can be accessed
 * from both the buffer using the SDF as input for stateful dynamics
 * and by the main display pass.
 *
 * I originally had the SDF computed in a buffer,
 * but I worried that all the texture-sampling calls were slowing
 * things down compared to just calling into the code again.
 *
 * A huge advantage of not computing the SDF in a buffer is that
 * when it's in a buffer you can't access SDF values which are off-screen.
 *
 * A disadvantage of having the SDF in Common is that it precludes
 * the possibility of a stateful SDF. for example one in which the
 * player of a game is able to modify the terrain.
 *
 */


const float PI        = 3.14159265259;
const float PI2       = (PI * 2.0);

const int numBalls = 13;
const float ballRadMin = 0.03;
const float ballRadMax = 0.07;

#define MYTIME (iTime * 3.14159 * 2.0)

// polynomial smooth min (k = 0.1);
float sminCubic( float a, float b, float k )
{
    float h = max( k-abs(a-b), 0.0 )/k;
    return min( a, b ) - h*h*h*k*(1.0/6.0);
}

const float epsilonGradient = 0.0001;

// https://www.iquilezles.org/www/articles/distfunctions2d/distfunctions2d.htm
float opUnion( float d1, float d2 ) {  return min(d1,d2); }
float opSubtraction( float d1, float d2 ) { return max(-d1,d2); }
float opSubtraction2( float d1, float d2 ) { return max(d1,-d2); }
float opIntersection( float d1, float d2 ) { return max(d1,d2); }

float sdCircle( vec2 p, float r )
{
    return length(p) - r;
}

float sdAnnulus(in vec2 p, in float r1, in float r2) {
    return opSubtraction2(sdCircle(p, r2), sdCircle(p, r1));
}

float sdPentagon( in vec2 p, in float r )
{
    const vec3 k = vec3(0.809016994,0.587785252,0.726542528);
    p.x = abs(p.x);
    p -= 2.0*min(dot(vec2(-k.x,k.y),p),0.0)*vec2(-k.x,k.y);
    p -= 2.0*min(dot(vec2( k.x,k.y),p),0.0)*vec2( k.x,k.y);
    p -= vec2(clamp(p.x,-r*k.z,r*k.z),r);    
    return length(p)*sign(p.y);
}

float sdAnnularPentagon(in vec2 p, in float r1, in float r2) {
    return opSubtraction2(sdPentagon(p, r2), sdPentagon(p, r1));
}

mat2 rot2(float radians) {
    float s = sin(radians);
    float c = cos(radians);
    return mat2(s, c, -c, s);
}

float sdScene(in vec2 p, in float time) {
    return length(p);
}

vec2 gradScene(in vec2 p, in float time, in float d_at_p) {
    float dex = sdScene(p + vec2(epsilonGradient, 0.0), time);
    float dey = sdScene(p + vec2(0.0, epsilonGradient), time);
    return vec2(dex - d_at_p, dey - d_at_p);
}


///////////////////////////////////////////

float ballRad(float t) {
    return mix(ballRadMin, ballRadMax, t);
}


