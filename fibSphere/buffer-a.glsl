
#ifdef GRIMOIRE
#include <common.glsl>
#endif

void mainImage( out vec4 RGBA, in vec2 XY )
{
    ivec2 IJ = ivec2(XY);
    
    if (IJ != ivec2(0)) {
        RGBA = vec4(0.0);
        return;
    }
    
    if (iFrame == 0) {
        RGBA = vec4(0.0, 0.0, -1e9, 0.0);
    }
    
    // data.xy = use this as mouse point, other buffers.
    // data.zw = actual last mouse position, if mouse was down. else -1e9.
 
    vec4 data = texelFetch(iChannel0, IJ, 0);
     
     
    bool prevMouseDown = data.z   > -1.0;
    bool currMouseDown = iMouse.z >  0.0;
     
    vec2 prevMp = prevMouseDown ? data.zw : iMouse.xy;
    data.xy += iMouse.xy - prevMp;
    data.y = clamp(data.y, iResolution.y * -0.25, iResolution.y * 1.25);
    data.zw = currMouseDown ? iMouse.xy : vec2(-1.0);
     
    
    RGBA = data;
}


#ifdef GRIMOIRE
out vec4 fragColor; void main() { mainImage(fragColor, gl_FragCoord.xy); }
#endif



