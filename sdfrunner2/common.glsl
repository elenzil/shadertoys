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
    float width = 0.03;

    float d = 1e9;

    float circRad = 0.8 + sin(time * 0.11) * 0.1;
    d = opUnion(d, -sdCircle(p, circRad));

    mat2 r2   = rot2(sin(time * 0.3211) * 0.2);
    float circRad2 = 0.2;
    d = opSubtraction2(d, sdCircle(abs(r2 * p) - circRad * 0.7 + sin(time * 0.02 + 2.0) * 0.2, circRad2));

    mat2 r1   = rot2(time * -0.1);
    mat2 r3   = rot2(time * -0.1 * 3.0);
    vec2 sep  = vec2(sin(time * 0.121) * 0.5, 0.0);
    vec2 sep2 = vec2(0.0, cos(time * 0.121) * 0.15);

    float pentRad = 0.2;
    float pr;
    float w1 = (sin(time * 0.31) * 0.5 + 0.5) * 0.15;

    pr = pentRad;// - 0.2 * (sin(gMyTime * 0.2) * 0.5 + 0.5);
    float da = sdAnnularPentagon((p + sep + sep2) * r1, pr - 0.001 - w1, pr);

    pr = pentRad ; // - 0.2 * (cos(gMyTime * 0.2) * 0.5 + 0.5);
    float db = sdAnnularPentagon((p - sep - sep2) * r3, pr - 0.001 - w1, pr);
    
    float dc = sminCubic(da, db, 0.1);
  
    d = min(d, dc);
    
    return d;
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


