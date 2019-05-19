

// persistent data.
// (0, 0) = most recent iMouse.
// (1, 0) = the iMouse before that.
// (2, 0) = Point Of Interest. (POI struct)
// (3, 0) = iMouse when the button became pressed.

struct POI {
  vec2  center;
  float range;
  float maxIter;
};

const POI[] pointsOfInterest = POI[] (
  // the main image
  POI(vec2(-0.75    ,  0.0      ), 1.4     ,  200.0),

  // Spirals from Paul Bourke http://paulbourke.net/fractals/mandelbrot
  POI(vec2(-0.761571, -0.084756),  0.000012, 2000.0),

  // nowhere special
  POI(vec2(-1.4076  , -0.1277   ), 0.00014 , 3000.0)
);

vec4 poiToVec4(in POI poi) {return vec4(poi.center, poi.range, poi.maxIter);}
POI vec4ToPOI(in vec4 v) {return POI(v.xy, v.z, v.w);}

void mainImage(out vec4 outRGBA, in vec2 XY)
{
  ivec2 IJ = ivec2(XY);

  if (iFrame == 0) {
    if (IJ.x == 2) {
      outRGBA = poiToVec4(pointsOfInterest[0]);
    }
    else {
      outRGBA = vec4(0.0, 0.0, 0.0, 0.0);
    }
    return;
  }

  if (IJ.y > 0) {
    // don't care
    // discard;
    outRGBA = texelFetch(iChannel0, ivec2(IJ.x, 0), 0);
    return;
  }
  else if (IJ.x == 0) {
    outRGBA = iMouse;
  }
  else if (IJ.x == 1) {
    outRGBA = texelFetch(iChannel0, ivec2(IJ.x - 1, IJ.y), 0);
  }
  else {
    vec4 prevIMouse = texelFetch(iChannel0, ivec2(0, 1), 0);
    bool wasPressed = (prevIMouse.z + prevIMouse.w) > 0.5;
    bool nowPressed = (    iMouse.z +     iMouse.w) > 0.5;
    bool justBecamePressed = nowPressed && !wasPressed;

    if ((IJ.x == 3) && justBecamePressed) {
      outRGBA = iMouse;
    }
    else if (IJ.x == 2) {
      vec2 mouseDelta = iMouse.xy - texelFetch(iChannel0, ivec2(3, 0), 0).xy;
      POI poi = vec4ToPOI(texelFetch(iChannel0, IJ, 0));
      poi.center += mouseDelta;
      outRGBA = poiToVec4(poi);
    }
    else {
      outRGBA = texelFetch(iChannel0, IJ, 0);
    }
  }
}


// grimoire bindings
out vec4 fragColor; void main() { mainImage(fragColor, gl_FragCoord.xy); }
