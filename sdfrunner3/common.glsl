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

const int numBalls = 5;
const float ballRadMin = 0.04;
const float ballRadMax = 0.06;

const float scrollSpeed = 0.02;


const vec2  grv        = vec2(0.0, -1.0);

#define MYTIME (iTime * 3.14159 * 2.0)

float ballRadius(int n) {
    return mix(ballRadMin, ballRadMax, float(n) / float(numBalls - 1));
}

float invBallRad(float r) {
    return (r - ballRadMin) / (ballRadMax - ballRadMin);
}

// polynomial smooth min (k = 0.1);
float sminCubic( float a, float b, float k )
{
    float h = max( k-abs(a-b), 0.0 )/k;
    return min( a, b ) - h*h*h*k*(1.0/6.0);
}

const float epsilonGradient = 0.0001;

float dirtLevel(float gx)
{
    float drtLev = -0.2;
    // high freq
    drtLev += sin(gx * 7.0 - cos(gx * 2.31) * 1.7) * 0.05;
    // low freq
    drtLev += sin(gx * 1.1 + sin(gx * 0.4 ) * 1.4) * 0.3;
    return drtLev;
}

vec2 dirtNormal(float gx, float dirtLevelAtGx) {
    const float eps = 0.001;
    float gxp = gx + eps;
    float dlp = dirtLevel(gxp);
    return normalize(vec2(-(dlp - dirtLevelAtGx), eps));
}

vec2 screenToGame(in vec2 p, in float time, in float scrollSpeed) {
    return vec2(p.x + time * scrollSpeed, p.y);
}




