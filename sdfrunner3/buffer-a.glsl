/////////////////////////
// this buffer is the dynamics, based on the SDF

#ifdef GRIMOIRE
#include <common.glsl>
#endif

void mainImage(out vec4 RGBA, in vec2 XY) {
    ivec2 IJ = ivec2(XY);

    RGBA *= 0.0;

    if (IJ.y > 1) {
        return;
    }

    if (IJ.x >= numBalls) {
        return;
    }

    vec4 rgba = texelFetch(iChannel0, IJ, 0);

    ///////////////////////////////////////////////////////////////////////
    // calculate rotation based on ground contact and horizontal speed.
    // lags behind the simulation by one frame, but that's fine.
    // rgba.x = ball theta
    // rgba.y = ball dTheta
    if (IJ.y == 1) {
        if (iFrame == 0 || iMouse.z > 0) {
            RGBA = vec4(0.0);
            return;
        }

        vec4 rgba2 = texelFetch(iChannel0, ivec2(IJ.x, 0), 0);

        float drtLevC = dirtLevel(rgba2.x);
        if (rgba2.y < drtLevC + ballRad + 0.1) {
            float targetDTheta = rgba2.z / ballRad * PI;
            rgba.y = mix(rgba.y,  targetDTheta, 300.0 * iTimeDelta * iTimeDelta);
        }
        else {
            rgba.y *= 0.995;
        }
        rgba.x += rgba.y * iTimeDelta;
        RGBA = rgba;

        return;
    }


    //////////////////////////////////////////////
    // calculate motion
    vec2 pos = rgba.xy;
    vec2 vel = rgba.zw;

    if (iFrame == 0 || iMouse.z > 0) {
        pos = screenToGame(vec2(-0.7, 0.0), MYTIME, scrollSpeed);
        float drtLevC = dirtLevel(pos.x);
        vec2  drtNorm = dirtNormal(pos.x, drtLevC);
        pos.y = drtLevC;
        pos.y += 0.02;
        pos += drtNorm * 0.04;
        vel = drtNorm * ((XY.x + 1.0) / float(numBalls));
    }

    vel += grv * iTimeDelta;
    pos += vel * iTimeDelta;

    vec2 distPast = screenToGame(vec2(0.0, 0.0), MYTIME, scrollSpeed) - pos;
    vel.x += sqrt(max(0.0, distPast.x - 0.9)) * 0.2;
    vel.y +=      max(0.0, distPast.x - 0.9)  * 0.4;
    
  
    float drtLevC = dirtLevel(pos.x);

    if (pos.y < drtLevC + ballRad) {
        vec2  drtNorm = dirtNormal(pos.x, drtLevC);
        vel = reflect(vel, drtNorm);
        // damping the bouncing
        vel.y *= 0.75;
        pos.y = drtLevC + ballRad + 0.002;
    }
    
    RGBA = vec4(pos, vel);
}

#ifdef GRIMOIRE
out vec4 fragColor; void main() { mainImage(fragColor, gl_FragCoord.xy); }
#endif

