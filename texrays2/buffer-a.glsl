/////////////////////////
// this buffer is the dynamics, based on the SDF

#ifdef GRIMOIRE
#include <common.glsl>
#endif

float gMyTime = 0.0;

void mainImage(out vec4 RGBA, in vec2 XY) {
    ivec2 IJ = ivec2(XY);
    
    if (IJ.x > 0 || IJ.y < 0) {
        discard;
    }
    
    vec2 p;
    vec2 v;
    
    if (iFrame < 5) {
        p = vec2(0.0);
        v = vec2(0.0);
    }
    else if (iMouse.z > 0.0) {
        float smallRes = min(iResolution.x, iResolution.y);
        p  = (iMouse.xy - iResolution.xy * 0.5) / smallRes * 2.0;
        v  = vec2(0.0);
    }
    else {
        // fetch last value
        vec4 pv = texelFetch(iChannel0, IJ, 0);

        p = pv.xy;
        v = pv.zw;
        
        float smallRes = min(iResolution.x, iResolution.y);

        // normalize euler integration to at least 60 Hz
        const float fixedDT = 1.0 / 30.0;
        float steps = round(iTimeDelta / fixedDT);

        steps = max(steps, 1.0);

        float dt = iTimeDelta / steps;

        float n = 0;
        while (n < steps) {
            ivec2 pij = ivec2((iResolution.xy + p * smallRes) / 2.0);

            
            // and advance
            vec4 sdfInfo = texelFetch(iChannel1, pij, 0);
            vec2 grd     = sdfInfo.yz;
            vec2 grdNorm = grd/sdfInfo.w;
            vec2 tang    = vec2(-grd.y, grd.x);

            v = tang * 12000.0 * 1.0;
            p += dt  * v;

            p -= (sdfInfo.x - ballRad) * grdNorm;

            n += 1.0;
        }

    }
    
   // p.x = 1.0;
    
    RGBA = vec4(p, v);
}

#ifdef GRIMOIRE
out vec4 fragColor; void main() { mainImage(fragColor, gl_FragCoord.xy); }
#endif
