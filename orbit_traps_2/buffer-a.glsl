
void mainImage(out vec4 outRGBA, in vec2 XY)
{
  float f = cos(XY.x / iResolution.x * 3.14159 * 2.0 * 4.0) * 0.5 + 0.5;
  outRGBA = vec4(f, f, 1.0 - f, 1.0);
}


// grimoire bindings
out vec4 fragColor; void main() { mainImage(fragColor, gl_FragCoord.xy); }
