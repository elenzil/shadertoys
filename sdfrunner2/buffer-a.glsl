/////////////////////////
// this buffer is the dynamics, based on the SDF

#ifdef GRIMOIRE
#include <common.glsl>
#endif

float gMyTime = 0.0;

void mainImage(out vec4 RGBA, in vec2 XY) {
    gMyTime = iTime * 3.14159 * 2.0;
    float smallRes = min(iResolution.x, iResolution.y);

    ivec2 IJ = ivec2(XY);
    
    if (IJ.x >= numBalls || IJ.y > 0) {
        discard;
    }
    
    vec2 p;
    vec2 v;
    
    float ballT = XY.x / float(numBalls);
    
    float offX = (XY.x - float(numBalls) * 0.5) * 100.0 / smallRes;
        
    if (iMouse.z > 0.0) {
        p  = (iMouse.xy - iResolution.xy * 0.5) / smallRes * 2.0;
        p.x += offX;
        v  = vec2(0.0);
    }
    else {
        if (iFrame > 1) {
            // fetch last value
            vec4 pv = texelFetch(iChannel0, IJ, 0);

            p = pv.xy;
            v = pv.zw;
        }
        else {
            p = vec2(offX, 1.0);
            v = vec2(0.0);
        }
        
        float smallRes = min(iResolution.x, iResolution.y);

        // normalize euler integration to at least 60 Hz
        const float fixedDT = 1.0 / 30.0;
        float steps = round(iTimeDelta / fixedDT);

        steps = max(steps, 1.0);

        float dt = iTimeDelta / steps;

        float n = 0.0;
        while (n < steps) {
            ivec2 pij = ivec2((iResolution.xy + p * smallRes) / 2.0);

            
            // and advance
            vec4 sdfInfo = texelFetch(iChannel0, pij, 0);
            float d   = sdScene(p, gMyTime);
            vec2 grd  = gradScene(p, gMyTime, d);
            float gm  = length(grd);
            vec2 grdNorm = grd/gm;
            vec2 tang    = vec2(-grd.y, grd.x);

            v = tang * 12000.0 * 1.0;
            // add in a little physics variation per-particle to keep them separated
            v *= (1.0 + XY.x * -0.03);
            p += dt  * v;

            p -= (d - ballRad(ballT)) * grdNorm;

            n += 1.0;
        }

    }
    
   // p.x = 1.0;
    
    RGBA = vec4(p, v);
}

#ifdef GRIMOIRE
out vec4 fragColor; void main() { mainImage(fragColor, gl_FragCoord.xy); }
#endif
