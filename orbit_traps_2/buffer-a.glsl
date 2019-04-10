
void mainImage(out vec4 outRGBA, in vec2 XY)
{
  if (XY.y <= 0.5) {
    float f = cos(XY.x / iResolution.x * 3.14159 * 2.0 * 4.0) * 0.5 + 0.5;
    outRGBA = vec4(f, f, 1.0 - f, 1.0);
  }
  else {
    vec2 UV  = XY/iResolution.xy;
    vec3 rgb = texture(iChannel0, UV - vec2(sin(iTime - XY.y / iResolution.y) * sin(XY.y / 20.0), 1.0) / iResolution.xy ).rgb;
    outRGBA = vec4(rgb, 1.0);
  }
}


// grimoire bindings
out vec4 fragColor; void main() { mainImage(fragColor, gl_FragCoord.xy); }
